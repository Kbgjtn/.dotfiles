local M = {}

local function clang_format(bufnr)
    local name = vim.api.nvim_buf_get_name(bufnr)
    local filename = vim.fn.fnamemodify(name, ":t")
    if filename == "" then
        filename = "shader.frag"
    end

    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local input = table.concat(lines, "\n")
    if input ~= "" then
        input = input .. "\n"
    end

    -- synchronous: format-on-save must finish before the write happens
    local result = vim.system({
        "clang-format",
        "--style=file",
        "--assume-filename=" .. filename,
    }, { stdin = input, text = true }):wait()

    if result.code ~= 0 then
        vim.notify("clang-format: " .. vim.trim(result.stderr or ""), vim.log.levels.WARN)
        return false
    end

    local output = result.stdout or ""
    local formatted = vim.split(output, "\n", { plain = true })
    if formatted[#formatted] == "" then
        table.remove(formatted)
    end

    local view = vim.fn.winsaveview()
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, formatted)
    vim.fn.winrestview(view)
    return true
end

--- Format a buffer. GLSL uses clang-format (preserves aligned trailing comments),
--- everything else uses the attached LSP client(s).
--- @param bufnr integer|?
--- @return boolean
function M.format(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    if vim.bo[bufnr].filetype == "glsl" then
        return clang_format(bufnr)
    end

    local clients = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/formatting" })
    if #clients == 0 then
        return false
    end

    vim.lsp.buf.format({
        async = false,
        bufnr = bufnr,
        timeout_ms = 2000,
        filter = function(client)
            return client.name ~= "glsl_analyzer"
        end,
    })
    return true
end

return M
