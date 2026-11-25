local gitsigns = require("gitsigns")

gitsigns.setup({
    signs = {
        add = { text = "|" },
        change = { text = "|" },
        delete = { text = "_" },
        topdelete = { text = "⎻" },
        changedelete = { text = "~" },
        untracked = { text = "¦" },
    },
    signs_staged = {
        add = { text = "┃" },
        change = { text = "┃" },
        delete = { text = "_" },
        topdelete = { text = "⎻" },
        changedelete = { text = "~" },
        untracked = { text = "¦" },
    },

    signs_staged_enable = true,
    signcolumn = true,
})

local keymaps = {
    -- Navigation
    {
        { "n" },
        "]c",
        function()
            require("gitsigns").next_hunk()
        end,
        { desc = "Next Git hunk" },
    },
    {

        { "n" },
        "[c",
        function()
            require("gitsigns").prev_hunk()
        end,
        { desc = "Prev Git hunk" },
    },

    -- Actions
    {
        { "n",                "v" },
        "<leader>hs",
        function()
            local gs = require("gitsigns")
            if vim.fn.mode() == "v" or vim.fn.mode() == "V" then
                local start = vim.fn.line("v")
                local finish = vim.fn.line(".")
                if start > finish then
                    start, finish = finish, start
                end
                gs.stage_hunk({ start, finish })
            else
                gs.stage_hunk()
            end
        end,
        { desc = "Stage hunk" },
    },
    {
        { "n" },
        "<leader>hr",
        function()
            require("gitsigns").reset_hunk()
        end,
        { desc = "Reset hunk" },
    },
    {
        { "n" },
        "<leader>hS",
        function()
            require("gitsigns").stage_buffer()
        end,
        { desc = "Stage buffer" },
    },
    {
        { "n" },
        "<leader>hR",
        function()
            require("gitsigns").reset_buffer()
        end,
        { desc = "Reset buffer" },
    },
    {
        { "n" },
        "<leader>hp",
        function()
            require("gitsigns").preview_hunk()
        end,
        { desc = "Preview hunk" },
    },
    {
        { "n" },
        "<leader>hi",
        function()
            require("gitsigns").preview_hunk_inline()
        end,
        { desc = "Preview hunk inline" },
    },
    {
        { "n" },
        "<leader>hb",
        function()
            require("gitsigns").blame_line({ full = true })
        end,
        { desc = "Blame line" },
    },
    {
        { "n" },
        "<leader>hd",
        function()
            require("gitsigns").diffthis()
        end,
        { desc = "Diff this" },
    },
    {
        { "n" },
        "<leader>hD",
        function()
            require("gitsigns").diffthis("~")
        end,
        { desc = "Diff this vs HEAD" },
    },
    {
        { "n" },
        "<leader>hq",
        function()
            require("gitsigns").setqflist()
        end,
        { desc = "Git hunks to qflist" },
    },
    {
        { "n" },
        "<leader>hQ",
        function()
            require("gitsigns").setqflist("all")
        end,
        { desc = "All Git hunks to qflist" },
    },
    -- Toggles
    {
        { "n" },
        "<leader>tb",
        function()
            require("gitsigns").toggle_current_line_blame()
        end,
        { desc = "Toggle line blame" },
    },
    {
        { "n" },
        "<leader>tw",
        function()
            require("gitsigns").toggle_word_diff()
        end,
        { desc = "Toggle word diff" },
    },
}

for _, map in ipairs(keymaps) do
    local mode = map[1]
    local lhs = map[2]
    local rhs = map[3]
    local opts = map[4]

    vim.keymap.set(mode, lhs, rhs, opts)
end