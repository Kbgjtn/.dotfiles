local M = {}
local utils = require("kbgjtn.utils")

M._tabline_cache = ""
M._tabline_dirty = true

function M.invalidate_tabline()
    M._tabline_dirty = true
end

function M.build_tabline()
    local current_buf = vim.api.nvim_get_current_buf()
    local listed = {}

    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.fn.buflisted(b) == 1 then
            listed[#listed + 1] = b
        end
    end

    local total_bufs = #listed
    local index = 0

    for i, b in ipairs(listed) do
        if b == current_buf then
            index = i
            break
        end
    end

    local current_tab = vim.fn.tabpagenr()
    local total_tabs = vim.fn.tabpagenr("$")

    local branch = utils.get_git_branch(current_buf)

    local s = " "

    s = s
        .. "%#TabLineSel# "
        .. current_tab
        .. "/"
        .. total_tabs

    s = s .. " "
        .. "%#TabLineFill# "
        .. index
        .. "/"
        .. total_bufs

    if branch ~= "" then
        s = s .. " [" .. branch .. "]"
    end

    return s .. "%#TabLineFill#"
end

function M.buffer_line()
    if M._tabline_dirty then
        M._tabline_cache = M.build_tabline()
        M._tabline_dirty = false
    end

    return M._tabline_cache
end

return M