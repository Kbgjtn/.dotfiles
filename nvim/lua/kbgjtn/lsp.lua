local function on_attach(client, bufnr)
    -- Neovim's completion module owns the InsertCharPre trigger when
    -- autotrigger = true. It uses the server's own triggerCharacters and an
    -- adaptive debounce. Don't add a second trigger or inflate trigger chars.
    if client.server_capabilities.completionProvider then
        vim.lsp.completion.enable(true, client.id, bufnr, {
            autotrigger = true,
            -- cmp = function(a, b)
            --     local rank = function(item)
            --         local k = item.kind
            --         if k == 15 then return 1 end -- Snippet
            --         if k == 3 then return 2 end  -- Function
            --         if k == 2 then return 3 end  -- Method
            --         if k == 5 then return 4 end  -- Field
            --         if k == 17 then return 4 end -- Property (some LSPs use this instead)
            --         if k == 6 then return 5 end  -- Variable
            --         if k == 9 then return 6 end  -- Constant
            --         return 100
            --     end
            --
            --     return rank(a) < rank(b)
            -- end,

            -- convert = function(item)
            --     -- local kind = vim.lsp.protocol.CompletionItemKind[item.kind] or "Text"
            --     return {
            --         abbr = item.label,
            --         -- kind = string.format(" %s ", icons[kind] or "?"),
            --         -- menu = item.detail or "",
            --     }
            -- end,
        })
    end

    local map = function(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, {
            buffer = bufnr,
            silent = true,
            noremap = true,
            desc = desc,
        })
    end

    map("n", "gd", vim.lsp.buf.definition, "Go to definition")
    map("n", "<leader>d", vim.diagnostic.open_float, "Open float diagnostic inlay")
    map("n", "K", function()
        vim.lsp.buf.hover({
            border = "rounded",
            max_width = math.floor(vim.o.columns * 1.25),
            max_height = 16,
        })
    end, "Hover documentation")

    -- disable heavy features per-buffer
    vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })
end

_ = on_attach;

local capabilities = vim.lsp.protocol.make_client_capabilities()

vim.diagnostic.config({
    underline = true,
    virtual_lines = false,
    severity_sort = true,
    virtual_text = false,
    update_in_insert = false,
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = 'E',
            [vim.diagnostic.severity.WARN] = 'W',
            [vim.diagnostic.severity.INFO] = 'I',
            [vim.diagnostic.severity.HINT] = 'H',
        },
    },
    float = {
        focusable = true,
        -- max_width = math.floor(vim.o.columns * 0.2),
        -- max_height = 12,
    },

    -- signs = true,
    -- virtual_text = {
    --     spacing = 0,
    --     prefix = "",
    -- },
})

vim.lsp.log.set_level(vim.log.levels.OFF)
vim.lsp.document_color.enable(false)
vim.lsp.inlay_hint.enable(false)

-- might disable it, too slow at this point
vim.lsp.config("lua_ls", {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_markers = { { ".emmyrc.json", ".luarc.json", ".luarc.jsonc" }, { ".luacheckrc", ".stylua.toml", "stylua.toml", "selene.toml", "selene.yml" }, { ".git" } },
    settings = {
        Lua = {
            runtime = { version = 'LuaJIT' },
            diagnostics = { globals = { 'vim' } },
            workspace = {
                checkThirdParty = false,
                library = {
                    vim.env.VIMRUNTIME,
                },
            },
            hint = {
                enable = false,
                semicolon = "Disable"
            },
            codeLens = { enable = false },
            telemetry = { enable = false },
        },
    },
})

vim.lsp.config("bashls", {
    cmd = { "bash-language-server", "start" },
    filetypes = { 'bash', 'sh' }
})

vim.lsp.config("clangd", {
    cmd = {
        "clangd-18",
        "-j=4",
        "--background-index=false",
        "--malloc-trim",
        -- "--header-insertion=iwyu",
        "--header-insertion=never",
        "--completion-style=bundled",
        -- "--completion-style=detailed",
        "--pch-storage=memory",
        "--function-arg-placeholders",
    },
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
    root_markers = {
        "compile_commands.json",
        "compile_flags.txt",
        "configure.ac", -- AutoTools
        "Makefile",
        "configure.ac",
        "configure.in",
        "config.h.in",
        "meson.build",
        "meson_options.txt",
        "build.ninja",
        ".git",
    },
    capabilities = {
        -- offsetEncoding = { 'utf-8', 'utf-16' },
    },
    init_options = {
        -- usePlaceholders = true,
        -- completeUnimported = true,
        -- clangdFileStatus = true,
    },
})

vim.lsp.config("zls", {
    cmd = { "zls" },
    filetypes = { "zig", "zon" },
    root_markers = { ".git", "build.zig" },
    settings = {
        zls = {
            warn_style = true,
            enable_build_on_save = false,
            build_on_save_step = "check",
            enable_argument_placeholders = false,
            inlay_hints_hide_redundant_param_names = true,
            inlay_hints_hide_redundant_param_names_last_token = true,
        },
    },
})

vim.lsp.config("gopls", {
    cmd = { "gopls" },
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    root_markers = { "go.work", "go.mod", ".git" },
})

vim.lsp.config("ts_ls", {
    cmd = { "typescript-language-server", "--stdio" },
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
    init_options = { hostInfo = "neovim" },
})

vim.lsp.config("pyright", {
    cmd = { "pyright-langserver", "--stdio" },
    filetypes = { "python" },
    root_markers = {
        "pyrightconfig.json",
        "pyproject.toml",
        "setup.cfg",
        "setup.py",
        "requirements.txt",
        ".git",
    },
    settings = {
        python = {
            analysis = {
                typeCheckingMode = "basic",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
            },
        },
    },
})

-- pyright has no formatter; ruff provides lint + format over LSP
vim.lsp.config("ruff", {
    cmd = { "ruff", "server" },
    filetypes = { "python" },
    root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" },
})

vim.lsp.config("glsl_analyzer", {
    cmd = { "glsl_analyzer", "--stdio" },
    filetypes = { "glsl" },
    root_markers = { ".git" },
    -- shaders are formatted by clang-format (keeps aligned trailing comments)
    on_init = function(client)
        client.server_capabilities.documentFormattingProvider = nil
        client.server_capabilities.documentRangeFormattingProvider = nil
    end,
})

vim.lsp.config("jsonls", {
    cmd = { "vscode-json-language-server", "--stdio" },
    filetypes = { "json", "jsonc" },
    root_markers = { "package.json", ".git" },
    init_options = { provideFormatter = true },
    settings = {
        json = {
            schemas = {
                { url = "https://json.schemastore.org/tsconfig", fileMatch = { "tsconfig*.json" } },
                { url = "https://json.schemastore.org/package",  fileMatch = { "package.json" } },
            },
            validate = { enable = true },
        },
    },
})

vim.treesitter.language.register("bash", { "sh", "bash" })

vim.lsp.config('*', {
    on_attach = on_attach,
    capabilities = capabilities,
})

vim.lsp.enable({
    "lua_ls",
    "zls",
    "clangd",
    "bashls",
    "gopls",
    "ts_ls",
    "jsonls",
    "pyright",
    "ruff",
    "glsl_analyzer",
})


---

-- local icons = {
--     Text = "󰉿",
--     Method = "󰆧",
--     Function = "󰊕",
--     Constructor = "",
--     Field = "󰜢",
--     Variable = "󰀫",
--     Class = "󰠱",
--     Interface = "",
--     Module = "",
--     Property = "󰜢",
--     Unit = "󰑭",
--     Value = "󰎠",
--     Enum = "",
--     Keyword = "󰌋",
--     Snippet = "",
--     Color = "󰏘",
--     File = "󰈙",
--     Reference = "󰈇",
--     Folder = "󰉋",
--     EnumMember = "",
--     Constant = "󰏿",
--     Struct = "󰙅",
--     Event = "",
--     Operator = "󰆕",
--     TypeParameter = "󰊄",
-- }

-- vim.lsp.completion.enable(true, client.id, bufnr, {
--     autotrigger = true,
--     -- cmp = function(a, b)
--     --     local rank = function(item)
--     --         local k = item.kind
--     --         if k == 15 then return 1 end -- Snippet
--     --         if k == 3 then return 2 end  -- Function
--     --         if k == 2 then return 3 end  -- Method
--     --         if k == 5 then return 4 end  -- Field
--     --         if k == 17 then return 4 end -- Property (some LSPs use this instead)
--     --         if k == 6 then return 5 end  -- Variable
--     --         if k == 9 then return 6 end  -- Constant
--     --         return 100
--     --     end
--     --
--     --     return rank(a) < rank(b)
--     -- end,
--
--     -- convert = function(item)
--     --     -- local kind = vim.lsp.protocol.CompletionItemKind[item.kind] or "Text"
--     --     return {
--     --         abbr = item.label,
--     --         -- kind = string.format(" %s ", icons[kind] or "?"),
--     --         -- menu = item.detail or "",
--     --     }
--     -- end,
-- })