local fzf = require("fzf-lua")
local actions = fzf.actions;

fzf.setup({
    'max-perf',
    winopts = {
        height = 0.48,
        width = 0.56,
        preview = {
            vertical = "up:36%",
            horizontal = "right:40%",
            hidden = true,
        },
    },

    fzf_opts = {
        ["--prompt"] = " → ",
        ["--layout"] = "reverse",
    },

    grep = {
        rg_opts =
            "--hidden --column --line-number --no-heading --smart-case " ..
            "-g '!node_modules/*' -g '!.zig-cache/*' -g '!.git/*'",
    },

    buffers = {
        prompt = 'Buf ',
        -- file_icons    = false, -- show file icons (true|"devicons"|"mini")?
        -- color_icons   = true, -- colorize file|git icons
        sort_lastused = true, -- sort buffers() by last used
        show_unloaded = true, -- show unloaded buffers
        -- cwd_only = false, -- buffers for the cwd only
        -- cwd      = nil,   -- buffers list for a given dir
        actions = {
            --     -- actions inherit from 'actions.files' and merge
            --     -- by supplying a table of functions we're telling
            --     -- fzf-lua to not close the fzf window, this way we
            --     -- can resume the buffers picker on the same window
            --     -- eliminating an otherwise unaesthetic win "flash"
            ["ctrl-x"] = { fn = actions.buf_del, reload = true },
            ["ctrl-d"] = actions.buf_del_force,
        }
    },

    files = {
        fd_opts =
        "--type f --hidden --ignore-file .gitignore --exclude .git --exclude node_modules",
        -- "--type f --hidden --exclude .git --exclude node_modules --exclude .zig-cache --exclude .vscode --exclude .cache",
    },
})


local opts = { noremap = true, silent = true }
vim.keymap.set("n", "<C-\\>", fzf.buffers, opts)
vim.keymap.set("n", "<leader>ff", fzf.files, opts)
vim.keymap.set("n", "<leader>fg", fzf.undotree, opts)
vim.keymap.set("n", "<leader>fs", fzf.live_grep, opts)
vim.keymap.set("n", "<leader>fr", fzf.oldfiles, opts)
vim.keymap.set("n", "<leader>fk", fzf.keymaps, opts)
vim.keymap.set("n", "<leader>fh", fzf.help_tags, opts)
vim.keymap.set("n", "<leader>gc", fzf.git_commits, opts)
vim.keymap.set("n", "<leader>gs", fzf.git_status, opts)
vim.keymap.set("n", "<leader>gb", fzf.git_branches, opts)
vim.keymap.set("n", "<leader>/", fzf.git_files, opts)
vim.keymap.set("n", "<leader>db", fzf.diagnostics_document, opts)
vim.keymap.set("n", "<leader>dw", fzf.diagnostics_workspace, opts)
vim.keymap.set("n", "<leader>fm", fzf.manpages, opts)