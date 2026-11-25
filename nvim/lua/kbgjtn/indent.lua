local M = {}

--- @param width integer indent width
--- @param spaces boolean|? use spaces instead of tabs (default true)
function M.setup(width, spaces)
    width = width or 2
    if spaces == nil then
        spaces = true
    end

    vim.opt_local.tabstop = width
    vim.opt_local.shiftwidth = width
    vim.opt_local.softtabstop = spaces and width or 0
    vim.opt_local.expandtab = spaces
end

return M
