local ccbl = require("coocobolo");

ccbl.setup({
    theme = "dark",
    clear_status_line = true,
    enable_yank_highlight = true,
    accent = {
        -- default = "#A0A0A0",
        -- default = "#FCDC0C",
        default = "#FAFAFA",
    },
    highlights = {
        Visual = { bg = "#151515", bold = false, },
        ColorColumn = { bg = "#080808", bold = false, },
        PmenuBorder = { bg = "NONE", fg = "#202020" },
        -- PmenuKind = { bg = "NONE", },
        -- PmenuExtra = { bg = "NONE", },
        -- PmenuExtraSel = { bg = "#1A1A1A", fg = "NONE" },
        -- PmenuSel = { bg = "#1A1A1A", fg = "#FFF000" },
        -- FloatBorder = { bg = "NONE", fg = "#121212" },
    },
})

-- Completion popup colors are intentionally NOT overridden here:
-- the docs card inherits the active colorscheme's Pmenu/NormalFloat groups
-- via winhighlight in autocmd.lua, so changing colorscheme just works.

-- vim.api.nvim_set_hl(0, "Pmenu",         { bg = "#1e1e2e", fg = "#cdd6f4" })
-- vim.api.nvim_set_hl(0, "PmenuSel",      { bg = "#313244", bold = true })
-- vim.api.nvim_set_hl(0, "PmenuKind",     { fg = "#89b4fa" })  -- kind column (unselected)
-- vim.api.nvim_set_hl(0, "PmenuKindSel",  { fg = "#89b4fa", bold = true })
-- vim.api.nvim_set_hl(0, "PmenuExtra",    { fg = "#6c7086" })  -- menu column (unselected)
-- vim.api.nvim_set_hl(0, "PmenuExtraSel", { fg = "#a6adc8" })
-- vim.api.nvim_set_hl(0, "PmenuMatch",    { fg = "#f38ba8", bold = true })  -- fuzzy matched chars
-- vim.api.nvim_set_hl(0, "PmenuMatchSel", { fg = "#f38ba8", bold = true })
-- vim.api.nvim_set_hl(0, "PmenuSbar",     { bg = "#313244" })  -- scrollbar track
-- vim.api.nvim_set_hl(0, "PmenuThumb",    { bg = "#585b70" })  -- scrollbar thumb
-- vim.api.nvim_set_hl(0, "PmenuBorder",   { fg = "#585b70" })  -- border (if pumborder set)