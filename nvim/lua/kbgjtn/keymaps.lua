local utils = require("kbgjtn.utils")

local custom_keymaps = {
    -- visual paste
    { "v", "p",          '"_dP' },

    -- file explorer
    { "n", "-",          "<cmd>Oil<cr>" },

    -- no highlight
    { "n", "<leader>n",  "<cmd>nohlsearch<cr>" },

    { "n", "<leader>so", "<cmd>source %<cr>" },


    -- terminal navigation
    { "t", "<C-[><C-[>", [[<C-\><C-n>]] },
    { "t", "<C-c><C-c>", [[<C-\><C-n>]] },

    -- substitute word under cursor
    {
        { "v", "n" },
        "<leader>s",
        [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gc<Left><Left><Left>]],
    },

    -- indent preserve selection
    { "v", "<",           "<gv" },
    { "v", ">",           ">gv" },


    -- keep cursor centered while scrolling
    -- half page
    { "n", "<c-d>",       "<C-d>zz" },
    { "n", "<c-u>",       "<C-u>zz" },

    -- by line
    { "n", "<c-e>",       "2<C-e>" },
    { "n", "<c-y>",       "2<C-y>" },

    -- move lines
    { "x", "J",           ":move '>+1<CR>gv=gv" },
    { "x", "K",           ":move '<-2<CR>gv=gv" },

    -- custom functions
    { "n", "<leader>q",   utils.toggle_loclist },
    { "n", "<leader>e",   utils.vim_fugitive_toggle },
    { "n", "<leader>nc",  utils.toggle_numbering },

    -- LSP completion (safe modern API usage depends on Neovim version)
    { "i", "<C-Space>",   vim.lsp.completion.get },
    { "i", "<C-j>",       vim.lsp.completion.get },

    -- inspect
    { "n", "<C-/>",       "<cmd>Inspect<cr>" },

    -- buffer navigation
    { "n", "<A-k>",       "<cmd>bn<cr>" },
    { "n", "<A-j>",       "<cmd>bp<cr>" },
    { "n", "<A-q>",       "<cmd>bp | bd #<cr>" },

    -- resize
    { "n", "<M-K>",       "<cmd>resize +2<cr>" },
    { "n", "<M-J>",       "<cmd>resize -2<cr>" },
    { "n", "<M-h>",       "<cmd>vertical resize +2<cr>" },
    { "n", "<M-l>",       "<cmd>vertical resize -2<cr>" },


    { "n", "<leader>nc",  utils.toggle_numbering },
    { "n", "<leader>gp",  utils.git_push },
    { "n", "<leader>gcm", utils.git_commit },


    -- search centering
    { "n", "n",           "nzzzv", },
    { "n", "N",           "Nzzzv", },

    -- formatting
    { 'n', '<leader>f', function()
        require("kbgjtn.format").format()
    end, { desc = 'Format buffer (clang-format / LSP)' }
    },

    -- LSP quick fix / diagnostics
    { { "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action / quick fix" } },

    -- completion
    {
        "i",
        "<CR>",
        function()
            if vim.fn.pumvisible() == 1 then
                return "<C-y>"
            end
            return "<CR>"
        end,
        { expr = true, replace_keycodes = true }
    },
}

local keymap_opts = { noremap = true, silent = true }

for _, map in ipairs(custom_keymaps) do
    local mode = map[1]
    local lhs = map[2]
    local rhs = map[3]
    local extra_opts = map[4]

    local final_opts = vim.tbl_extend("force", keymap_opts, extra_opts or {})
    vim.keymap.set(mode, lhs, rhs, final_opts)
end