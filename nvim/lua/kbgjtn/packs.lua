-- ensure vim.pack exists (Neovim >= 0.12)
if not vim.pack then
    error("vim.pack not available: upgrade to Neovim >= 0.12")
end

vim.pack.add({
    { src = "https://github.com/ibhagwan/fzf-lua",         version = "main", },
    { src = "https://github.com/tpope/vim-fugitive",       version = "master", },
    { src = "https://github.com/tpope/vim-surround",       version = "master", },
    { src = "https://github.com/coocobolo/coocobolo.nvim", version = "master", },
    { src = "https://github.com/lewis6991/gitsigns.nvim",  version = "main", },
    { src = "https://github.com/stevearc/oil.nvim",        version = "master" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
})

require("oil").setup({
    default_file_explorer = false,
    prompt_save_on_select_new_entry = false,
    cleanup_delay_ms = 1000,
    columns = {
        "size",
        "permissions",
    },
    lsp_file_methods = {
        enabled = false,
        autosave_changes = false,
    },
    watch_for_changes = false,
    use_default_keymaps = true,
    delete_to_trash = true,
    view_options = {
        show_hidden = true,
    }
});