local function is_documentation_disabled()
    local options = vim.opt.completeopt:get()
    for _, option in ipairs(options) do
        if option == "popup" then
            return false
        end
        if option == "preview" then
            return false
        end
    end
    return true
end

local function get_preview_type()
    local type = nil
    local options = vim.opt.completeopt:get()
    for _, option in ipairs(options) do
        if option == "popup" then
            return "popup"
        end
        if option == "preview" then
            type = "preview"
        end
    end
    return type
end

---@class PreviewCompleteInfo
---@field selected integer
---@field preview_bufnr? integer
---@field preview_winid? integer

---@return PreviewCompleteInfo
local function get_preview_info()
    local complete_info = vim.fn.complete_info({
        "selected",
        "preview_winid",
        "preview_bufnr",
    })

    if get_preview_type() == "preview" then
        for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            local wininfo = vim.fn.getwininfo(winid)[1]
            local window_type = vim.fn.win_gettype(wininfo.winnr)
            if window_type == "preview" then
                complete_info.preview_winid = winid
                complete_info.preview_bufnr = wininfo.bufnr
                return complete_info
            end
        end
    end
    return complete_info
end

---@param documentation string|lsp.MarkupContent|nil
local function is_lsp_completion_documention_empty(documentation)
    return documentation == nil
        or documentation == ""
        or (type(documentation) == table and documentation.value == "")
        or (type(documentation) == table and documentation.value == nil)
end

---@param lsp_documentation string|lsp.MarkupContent
---@param selected integer index of selected completion item 0-indexed
local function display_documentation_popup(lsp_documentation, selected)
    local kind = lsp_documentation and lsp_documentation.kind
    local filetype = kind == "markdown" and "markdown" or ""
    local documentation_value = type(lsp_documentation) == "string" and lsp_documentation or lsp_documentation.value
    local preview_info = vim.api.nvim__complete_set(selected, {
        info = documentation_value,
    })
    if preview_info.bufnr ~= nil then
        vim.bo[preview_info.bufnr].filetype = filetype
        if filetype == "markdown" then
            vim.treesitter.start(preview_info.bufnr)
        end
    end
end

---@param lsp_documentation string|lsp.MarkupContent
local function display_documentation_preview(lsp_documentation)
    local kind = lsp_documentation and lsp_documentation.kind
    local filetype = kind == "markdown" and "markdown" or ""
    local documentation_value = type(lsp_documentation) == "string" and lsp_documentation or lsp_documentation.value

    local preview_buf_name = "Documentation\\ Preview"
    vim.cmd(
        "silent! pedit! +setlocal\\ buftype=nofile\\ nobuflisted\\ noswapfile\\ filetype="
        .. filetype
        .. " "
        .. preview_buf_name
    )
    local preview_info = get_preview_info()
    if preview_info.preview_bufnr ~= nil then
        local lines = vim.split(documentation_value, "\n")
        vim.api.nvim_buf_set_lines(preview_info.preview_bufnr, 0, -1, false, lines)
        vim.bo[preview_info.preview_bufnr].filetype = filetype
        if filetype == "markdown" then
            vim.treesitter.start(preview_info.preview_bufnr)
        end
    end
end

---@param lsp_documentation string|lsp.MarkupContent
local function refresh_documentation(lsp_documentation)
    local complete_info = get_preview_info()
    --we do this check here so that we don't close the completion window
    --if we are not going to replace it.
    if is_lsp_completion_documention_empty(lsp_documentation) then
        return
    elseif complete_info.preview_bufnr == nil and get_preview_type() ~= "preview" then
        --If the documentation buffer is already closed and does not need to be
        --a "preview" window we can just create a new one without needing to schedule it
        display_documentation_popup(lsp_documentation, complete_info.selected)
    else
        --Since the preview buffer is already open we need to close it and reopen a new
        --one so that the treesitter highlights refresh. (I at least couldn't figure out a
        --better way to achieve this. I tried a lot things)
        vim.schedule(function()
            if get_preview_type() == "preview" then
                display_documentation_preview(lsp_documentation)
                return
            end

            local current_complete_info = vim.fn.complete_info({
                "selected",
                "preview_winid",
                "preview_bufnr",
            })
            if current_complete_info.preview_winid ~= nil then
                --HACK: nvim_win_hide will cause a whole new
                --buffer and window to be generated when I call nvim__complete_set
                --Since it is a new buffer, it will recalculate
                --the the treesitter highlights correctly. Without this
                --the treessiter highlights won't refresh
                vim.api.nvim_win_hide(current_complete_info.preview_winid)
            end
            display_documentation_popup(lsp_documentation, current_complete_info.selected)
        end)
    end
end

local function set_documentation(completion_item)
    if completion_item == nil then
        return
    end

    local lsp_completion_item = vim.tbl_get(completion_item, "user_data", "nvim", "lsp", "completion_item")
    local complete_info = get_preview_info()

    local preview_bufnr = complete_info.preview_bufnr
    if lsp_completion_item == nil then
        --Handle non-lsp completion items
        if preview_bufnr ~= nil and completion_item.word ~= nil and completion_item.word ~= "" then
            vim.bo[preview_bufnr].filetype = ""
        end
        return
    end

    ---@type string|lsp.MarkupContent
    local lsp_documentation = lsp_completion_item.documentation
    if lsp_documentation ~= nil then
        --Handle lsp completion items with documentation already supplied
        refresh_documentation(lsp_documentation)
        return
    end

    --Handle lsp completion items that need documentation resolved
    local client_id = vim.tbl_get(completion_item, "user_data", "nvim", "lsp", "client_id")
    local client = vim.lsp.get_client_by_id(client_id)
    if client == nil then
        return
    end

    local is_resolve_support = true --TODO actually check for resolve support
    if not is_resolve_support then
        return
    end
    client.request(vim.lsp.protocol.Methods.completionItem_resolve, lsp_completion_item, function(err, result, _)
        if err ~= nil then
            vim.print(err)
            return
        end
        local documentation = result and result.documentation
        refresh_documentation(documentation)
    end)
end

local function enable_completion_resolve_documentation(bufnr)
    vim.api.nvim_create_autocmd("CompleteChanged", {
        group = vim.api.nvim_create_augroup("completion.documentation" .. bufnr, { clear = true }),
        buffer = bufnr,
        callback = function(_)
            if tonumber(vim.fn.pumvisible()) == 0 or is_documentation_disabled() then
                return
            end
            local event = vim.v.event --need to grab from vim.v.event
            set_documentation(event.completed_item)
        end,
    })
end

-------------------------------------------------------------------------------
---Setup autocmd that provides completion resolve support
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("lsp_attach", { clear = true }),
    desc = "lsp on_attach",
    callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client == nil then
            return
        end

        vim.lsp.completion.enable(true, client.id, event.buf, {
            autotrigger = true,
        })

        enable_completion_resolve_documentation(event.buf)
    end,
})

-------------------------------------------------------------------------------
---Setup dummy language server used for testing

---@alias LspServer.Handler fun(params: table?, callback: fun(err: lsp.ResponseError|nil, result: any), notify_reply_callback: fun(message_id: integer)|nil)

---@type {string: LspServer.Handler}
local handlers = {

    ---@type LspServer.Handler
    [vim.lsp.protocol.Methods.initialize] = function(_, callback, _)
        local initializeResult = {
            capabilities = {
                completionProvider = {
                    resolveProvider = true,
                },
            },
            serverInfo = {
                name = "dummy-lsp-server",
                version = "0.0.1",
            },
        }

        callback(nil, initializeResult)
    end,

    ---@type LspServer.Handler
    [vim.lsp.protocol.Methods.textDocument_completion] = function(_, callback, _)
        ---@type lsp.CompletionItem[]
        local completion_items_result = {

            {
                label = "test01",
                kind = vim.lsp.protocol.CompletionItemKind.Text,
                documentation = {
                    kind = vim.lsp.protocol.MarkupKind.Markdown,
                    value = "test01: with single line `` `filetype=markdown` ``. Item not resolved.",
                },
            },

            {
                label = "test02",
                kind = vim.lsp.protocol.CompletionItemKind.Text,
                documentation = {
                    kind = vim.lsp.protocol.MarkupKind.Markdown,
                    value =
                    "test02: with single line `` `filetype=markdown` ``. Item not resolved. Navigating up from test03 will error, but in theory should be fixed by PR #30246",
                },
            },
            {
                label = "test03",
                kind = vim.lsp.protocol.CompletionItemKind.Text,
            },
            {
                label = "test04",
                kind = vim.lsp.protocol.CompletionItemKind.Text,
                documentation = {
                    kind = vim.lsp.protocol.MarkupKind.Markdown,
                    value = [[
test04: this should stay up when you navigate to test05
since test05 has no documentation in its completion item or resolve results

This item was not resolved.

some code to see treesitter highlights
\`\`\`lua
local function test()
    vim.print("Testing injected lua treesitter highlights are working")
end
\`\`\`
]],
                },
            },
            {
                label = "test05",
                kind = vim.lsp.protocol.CompletionItemKind.Text,
            },
            {
                label = "test06",
                kind = vim.lsp.protocol.CompletionItemKind.Text,
                documentation = {
                    kind = vim.lsp.protocol.MarkupKind.Markdown,
                    value = [[
test06: this should replace test04 documentation when navigated down from test04

This item was not resolved.

some code to see treesitter highlights
\`\`\`lua
local function test()
    vim.print("Testing injected lua treesitter highlights are working")
end
\`\`\`
]],
                },
            },
            {
                label = "test07",
                kind = vim.lsp.protocol.CompletionItemKind.Text,
                documentation = {
                    kind = vim.lsp.protocol.MarkupKind.PlainText,
                    value = [[
test07: this documentation is plain text so should not have treesitter highlights

This item was not resolved.

some code to see treesitter highlights are disabled
\`\`\`lua
local function test()
    vim.print("Testing that treesitter highlights are disabled since this documentation is set to be plaintext")
end
\`\`\`
]],
                },
            },
            {
                label = "test08",
                kind = vim.lsp.protocol.CompletionItemKind.Text,
                documentation = {
                    kind = vim.lsp.protocol.MarkupKind.Markdown,
                    value = [[
test08: switching back to markdown documentation

This item was not resolved.

some code to see treesitter highlights
\`\`\`lua
local function test()
    vim.print("Testing injected lua treesitter highlights are working")
end
\`\`\`
]],
                },
            },
            {
                label = "test09",
                kind = vim.lsp.protocol.CompletionItemKind.Text,
                --testing resolve request for plaintext documentation where documentation field is an object
            },
            {
                label = "test10",
                kind = vim.lsp.protocol.CompletionItemKind.Text,
                --testing resolve request for plaintext documentation where documentation field is a string
            },

            {
                label = "test11",
                kind = vim.lsp.protocol.CompletionItemKind.Text,
                -- documentation will be resolved
            },
            {
                label = "test12",
                kind = vim.lsp.protocol.CompletionItemKind.Text,
                -- no documentation will be resolved
            },
            {
                label = "test13",
                kind = vim.lsp.protocol.CompletionItemKind.Text,
                -- documentation will be resolved
            },
        }

        ---Side Note: I schedule the callback because there seems to be a bug.
        ---If a lua-defined lsp like this is the only lsp with completion results, the
        ---callback will error. The workaround is to schedule the callback.
        ---I need to do more testing to verify this isn't user error like
        ---not implementing the lsp spec correctly.
        ---
        ---I was getting the following stacktrace:
        ---
        ---E5108: Error executing lua Vim:E565: Not allowed to change text or change window
        -- stack traceback:
        -- [C]: in function 'complete'
        -- C:\nvim-win64\share\nvim\runtime/lua/vim/lsp/completion.lua:464: in function 'callback'
        -- C:\nvim-win64\share\nvim\runtime/lua/vim/lsp/completion.lua:389: in function 'handler'
        -- C:\nvim-win64\share\nvim\runtime/lua/vim/lsp/client.lua:681: in function 'callback'
        -- ...uments\poc\debug-neovim\issue-29225-my-init-lua\init.lua:128: in function <...uments\poc\debug-neovim\issue-29225-my-init-lua\init.lua:98>
        -- ...uments\poc\debug-neovim\issue-29225-my-init-lua\init.lua:168: in function 'request'
        -- C:\nvim-win64\share\nvim\runtime/lua/vim/lsp/client.lua:673: in function 'request'
        -- C:\nvim-win64\share\nvim\runtime/lua/vim/lsp/completion.lua:385: in function 'request'
        -- C:\nvim-win64\share\nvim\runtime/lua/vim/lsp/completion.lua:424: in function 'trigger'
        -- C:\nvim-win64\share\nvim\runtime/lua/vim/lsp/completion.lua:735: in function <C:\nvim-win64\share\nvim\runtime/lua/vim/lsp/completion.lua:725>
        vim.schedule(function()
            callback(nil, completion_items_result)
        end)
    end,

    ---@type LspServer.Handler
    [vim.lsp.protocol.Methods.completionItem_resolve] = function(request, callback, _)
        if request.label == "test03" then
            local item = vim.tbl_deep_extend("force", request, {
                documentation = {
                    kind = vim.lsp.protocol.MarkupKind.Markdown,
                    value = [[
# test03: `` `completionItem/resolve` ``

This item was resolved.

implements [spec](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#completionItem_resolve)
]],
                },
            })
            callback(nil, item)
        elseif request.label == "test09" then
            local item = vim.tbl_deep_extend("force", request, {
                documentation = {
                    kind = vim.lsp.protocol.MarkupKind.PlainText,
                    value = [[
# test09: `` `completionItem/resolve` `` with plaintext documentation kind so there should be no treesitter highlights

implements [spec](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#completionItem_resolve)

This item was resolved.

some code to see treesitter highlights are disabled
\`\`\`lua
local function test()
    vim.print("Testing that treesitter highlights are disabled since this documentation is set to be plaintext")
end
\`\`\`
]],
                },
            })
            callback(nil, item)
        elseif request.label == "test10" then
            local item = vim.tbl_deep_extend("force", request, {
                documentation = [[
# test10: `` `completionItem/resolve` `` with plaintext documentation where documentation is a string and not an object

implements [spec](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#completionItem_resolve)

This item was resolved.

some code to see treesitter highlights are disabled
\`\`\`lua
local function test()
    vim.print("Testing that treesitter highlights are disabled since this documentation is set to be plaintext")
end
\`\`\`
]],
            })
            callback(nil, item)

            ----
        elseif request.label == "test11" then
            local item = vim.tbl_deep_extend("force", request, {
                documentation = {
                    kind = vim.lsp.protocol.MarkupKind.Markdown,
                    value = [[
test11: this should stay up when you navigate to test12
since test12 has no documentation in its completion item or resolve results

This item was resolved.

some code to see treesitter highlights
\`\`\`lua
local function test()
    vim.print("Testing injected lua treesitter highlights are working")
end
\`\`\`
]],
                },
            })
            callback(nil, item)
        elseif request.label == "test13" then
            local item = vim.tbl_deep_extend("force", request, {
                documentation = {
                    kind = vim.lsp.protocol.MarkupKind.Markdown,
                    value = [[
test13: this should replace test11 documentation when navigated down from test11 and test 12

This item was resolved.

some code to see treesitter highlights
\`\`\`lua
local function test()
    vim.print("Testing injected lua treesitter highlights are working")
end
\`\`\`
]],
                },
            })
            callback(nil, item)
        end
        callback(nil, nil)
    end,
}

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "lua" },
    group = vim.api.nvim_create_augroup("start_dummy_lsp", {}),
    callback = function()
        vim.lsp.start({
            name = "dummylsp",
            root_dir = vim.fn.getcwd(),
            ---@type fun(dispatchers: vim.lsp.rpc.Dispatchers): vim.lsp.rpc.PublicClient
            cmd = function(_)
                ---@type vim.lsp.rpc.PublicClient
                return {

                    ---@type fun(method: string, params: table?, callback: fun(err: lsp.ResponseError|nil, result: any), notify_reply_callback: fun(message_id: integer)|nil):boolean,integer?
                    request = function(method, params, callback, notify_reply_callback)
                        if handlers[method] then
                            handlers[method](params, callback, notify_reply_callback)
                            return true
                        else
                            return false
                        end
                    end,
                    notify = function(_, _)
                        return false
                    end,
                    is_closing = function()
                        return false
                    end,
                    terminate = function() end,
                }
            end,
        })
    end,
})