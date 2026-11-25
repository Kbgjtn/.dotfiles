local custom_augroup = vim.api.nvim_create_augroup('CustomSettings', { clear = true })

vim.api.nvim_create_autocmd('FileType', {
    pattern = '*',
    group = custom_augroup,
    callback = function(args)
        local excluded = {
            markdown = true,
            gitcommit = true,
            zig = true,
        }

        if excluded[args.match] then
            return
        end

        -- This fixes annoying auto comments on newline
        vim.opt_local.formatoptions:remove({ 'r', 'o' })
    end,
    desc = "Disable auto-commenting on new lines"
})


-- Start treesitter (highlighting + folds) when a parser is available.
-- Map Neovim filetypes that differ from tree-sitter language names.
local ts_langs = {
    javascriptreact = "javascript",
    typescriptreact = "tsx",
    jsonc = "json",
    sh = "bash",
    zsh = "bash",
    objc = "c",
    objcpp = "cpp",
    cuda = "cpp",
    gomod = "go",
    gowork = "go",
    gotmpl = "go",
}

vim.api.nvim_create_autocmd("FileType", {
    group = custom_augroup,
    callback = function()
        local lang = ts_langs[vim.bo.filetype] or vim.bo.filetype
        if lang == "" then return end
        pcall(vim.treesitter.start, 0, lang)
    end,
    desc = "Start treesitter when a parser exists",
})


local lsp_group = vim.api.nvim_create_augroup("my.lsp", { clear = false })

vim.api.nvim_create_autocmd("BufWritePre", {
    group = lsp_group,
    callback = function(ev)
        require("kbgjtn.format").format(ev.buf)
    end,
    desc = "Format before write (clang-format for GLSL, LSP otherwise)",
})



local tabline_cached_augroup = vim.api.nvim_create_augroup("TablineCache", { clear = true })
vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete", "BufEnter", "BufModifiedSet", "TabEnter", "TabClosed" }, {
    group = tabline_cached_augroup,
    callback = function()
        require("kbgjtn.buffer_line").invalidate_tabline()
    end,
})

vim.api.nvim_create_autocmd("DirChanged", {
    callback = function()
        require("kbgjtn.utils").invalidate_git_cache()
    end,
})

local gitsigns_group = vim.api.nvim_create_augroup("LazyGitSigns", { clear = true })
vim.api.nvim_create_autocmd({ "BufEnter", "BufReadPost", "BufNewFile" }, {
    group = gitsigns_group,
    callback = function(args)
        local utils = require("kbgjtn.utils")

        local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(args.buf))
        if not dir or dir == "" then
            dir = vim.fn.getcwd()
        end
        if not utils.is_git_repo(dir) then
            return
        end


        require("kbgjtn.gitsigns")
        vim.api.nvim_del_augroup_by_id(gitsigns_group)
    end,
})

vim.api.nvim_create_autocmd('CompleteChanged', {
    group = lsp_group,
    callback = function()
        local info = vim.fn.complete_info()
        local winid = info.preview_winid

        if winid and winid ~= 0 then
            vim.api.nvim_set_option_value("wrap", true, { win = winid })
            vim.api.nvim_set_option_value("linebreak", true, { win = winid })
            vim.api.nvim_set_option_value("conceallevel", 2, { win = winid })
            -- Inherit the active colorscheme's completion/float colors so the
            -- docs card follows whatever theme the user has selected.
            vim.api.nvim_set_option_value("winhighlight", "Normal:Pmenu,FloatBorder:FloatBorder", { win = winid })

            -- Place the docs card beside the popup menu instead of letting it
            -- grow back over the menu (and under its zindex).
            local pum = vim.fn.pum_getpos()
            if not vim.tbl_isempty(pum) then
                local max_width = math.min(64, math.max(40, math.floor(vim.o.columns * 0.4)))
                -- +2 leaves a small gap so borders/shadows don't touch the pum
                local col = pum.col + pum.width + 2
                local width = math.min(max_width, math.max(20, vim.o.columns - col - 2))

                if vim.o.columns - col < 20 then
                    col = math.max(0, pum.col - width)
                end

                vim.api.nvim_win_set_config(winid, {
                    relative = "editor",
                    row = pum.row,
                    col = col,
                    width = width,
                    height = math.min(20, math.floor(vim.o.lines * 0.4)),
                    border = "rounded",
                    zindex = 100,
                    mouse = true,
                    focusable = true,
                })
            end
        end
    end,
})

-- vim.api.nvim_create_autocmd('CompleteChanged', {
--    callback = function()
--       local info = vim.fn.complete_info({ 'preview_winid', 'preview_bufnr' })
--       local winid = info.preview_winid
--
--       if winid and winid ~= -1 then
--          -- set any window option on the popup
--          vim.wo[winid].wrap = true
--          vim.wo[winid].linebreak = true
--
--          -- vim.wo[winid].winblend = 100
--
--          -- set border
--          vim.api.nvim_win_set_config(winid, {
--             border = 'rounded',
--             focusable = true,
--             hide = true,
--          })
--
--          -- @class vim.api.keyset.win_config
--          -- @field external? boolean
--          -- @field fixed? boolean
--          -- @field focusable? boolean
--          -- @field footer? any
--          -- @field footer_pos? "center"|"left"|"right"
--          -- @field hide? boolean
--          -- @field height? integer
--          -- @field mouse? boolean
--          -- @field relative? "cursor"|"editor"|"laststatus"|"mouse"|"tabline"|"win"
--          -- @field row? number
--          -- @field style? ""|"minimal"
--          -- @field noautocmd? boolean
--          -- @field vertical? boolean
--          -- @field win? integer
--          -- @field width? integer
--          -- @field zindex? integer
--          -- @field anchor? "NW"|"NE"|"SW"|"SE"
--          -- @field border? any[]|"none"|"single"|"double"|"rounded"|"solid"|"shadow"
--          -- @field bufpos? integer[]
--          -- @field col? number
--          -- @field split? "left"|"right"|"above"|"below"
--          -- @field title? any
--          -- @field title_pos? "center"|"left"|"right"
--          -- @field _cmdline_offset? integer
--       end
--    end,
-- })

-- local treesitter_group = vim.api.nvim_create_augroup("TreesitterSetup", { clear = true })
-- vim.api.nvim_create_autocmd("FileType", {
--     pattern = { "c", "cpp", "zig", "lua" },
--     group = treesitter_group,
--     callback = function(args)
--         if vim.treesitter.highlighter.active[args.buf] then
--             return
--         end
--
--         local max = 256 * 1024 -- 256 KB
--         local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(args.buf))
--
--         if ok and stats and stats.size > max then
--             vim.notify("Treesitter auto-disabled, files too large!", vim.log.levels.WARN)
--             return
--         end
--
--         vim.treesitter.start(args.buf)
--     end,
-- })

-- vim.api.nvim_create_autocmd("FileType", {
--     pattern = { "bash", "sh", "zsh" },
--     callback = function()
--         vim.opt_local.foldmethod = "expr"
--         vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
--         vim.opt_local.foldenable = true
--         vim.opt_local.foldlevel = 99
--     end,
-- })


-- if client:supports_method("textDocument/completion") then
--     local trigger_chars = client.server_capabilities.completionProvider.triggerCharacters or {}
--     for i = 32, 255 do
--         local char = string.char(i)
--         if vim.fn.match(char, "[[:keyword:]]") >= 0 then
--             table.insert(trigger_chars, char)
--         end
--     end
--     client.server_capabilities.completionProvider.triggerCharacters = trigger_chars

--     vim.lsp.completion.enable(true, ev.data.client_id, ev.buf, {
--         autotrigger = true,
--         convert = function(item)
--             local kind = vim.lsp.protocol.CompletionItemKind[item.kind] or ""
--             return {
--                 menu = "",
--                 kind_hlgroup = "CmpItemKind" .. kind,
--             }
--         end,
--     })
-- end