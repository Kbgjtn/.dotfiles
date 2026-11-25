local M = {}

--- vim.lsp.completion resizes the documentation popup to its full text height
--- in update_popup_window(). Autocmds run too late, so cap it synchronously at
--- the API call instead. Neovim 0.12 uses nvim_win_set_height(); master uses
--- nvim_win_resize(winid, -1, height), so cover both.
function M.setup()
    local function clamped_height(winid, height)
        local max_height = math.min(20, math.floor(vim.o.lines * 0.4))

        -- Only pay for complete_info() when a tall height is actually requested.
        if height > max_height then
            local preview = vim.fn.complete_info().preview_winid
            if preview and preview == winid then
                return max_height
            end
        end

        return height
    end

    local set_height = vim.api.nvim_win_set_height
    vim.api.nvim_win_set_height = function(winid, height)
        return set_height(winid, clamped_height(winid, height))
    end

    -- nvim_win_resize only exists on newer Neovim (master), not on 0.12.
    if vim.api.nvim_win_resize then
        local win_resize = vim.api.nvim_win_resize
        vim.api.nvim_win_resize = function(winid, width, height)
            if width == -1 then
                height = clamped_height(winid, height)
            end
            return win_resize(winid, width, height)
        end
    end
end

return M
