local M = {}

M._git_repo_cache = {}
M._git_branch_cache = {}

function M.fold_text()
    local start = vim.v.foldstart
    local line = vim.api.nvim_buf_get_lines(0, start - 1, start, false)[1]
    local count = vim.v.foldend - start + 1

    local indent = line:match("^%s*") or ""
    local content = line:gsub("^%s*", "")

    return indent .. content .. " (" .. count .. " lines)"
end

function M.toggle_loclist()
    local wins = vim.api.nvim_tabpage_list_wins(0)

    for i = 1, #wins do
        local win = wins[i]
        local ok, config = pcall(vim.api.nvim_win_get_config, win)

        if ok and config.relative == "" then
            local info = vim.fn.getwininfo(win)[1]
            if info and info.loclist == 1 then
                vim.cmd.lclose()
                return
            end
        end
    end

    if vim.tbl_isempty(vim.diagnostic.get(0)) then
        return
    end

    vim.diagnostic.setloclist()
    vim.cmd.lopen()
end

local function system(cmd)
    return vim.system(cmd, { text = true }):wait()
end

local function git_dir_from_root(root)
    local git_path = vim.fs.joinpath(root, ".git")

    if vim.fn.isdirectory(git_path) == 1 then
        return git_path
    end

    -- worktree/submodule: .git is a file containing "gitdir: <path>"
    local f = io.open(git_path, "r")
    if not f then
        return nil
    end

    local line = f:read("*l")
    f:close()

    local path = line and line:match("^gitdir:%s*(.+)$")
    if not path then
        return nil
    end

    path = vim.trim(path)
    if path:sub(1, 1) ~= "/" then
        path = vim.fs.joinpath(root, path)
    end

    return path
end

function M.is_git_repo(dir)
    dir = dir or vim.fn.getcwd()
    if dir == "" then
        dir = vim.fn.getcwd()
    end

    local cached = M._git_repo_cache[dir]
    if cached ~= nil then
        return cached
    end

    local ok = vim.fs.root(vim.fs.abspath(dir), ".git") ~= nil
    M._git_repo_cache[dir] = ok
    return ok
end

function M.get_git_branch(bufnr)
    local b = vim.b[bufnr]

    -- gitsigns is basically free
    if b.gitsigns_head and b.gitsigns_head ~= "" then
        return b.gitsigns_head
    end

    local name = vim.api.nvim_buf_get_name(bufnr)
    if name == "" then
        return ""
    end

    local dir = vim.fs.dirname(name)
    if not dir or dir == "" then
        return ""
    end

    local cached = M._git_branch_cache[dir]
    if cached ~= nil then
        return cached
    end

    local root = vim.fs.root(vim.fs.abspath(dir), ".git")
    if not root then
        M._git_branch_cache[dir] = ""
        return ""
    end

    local branch = ""
    local git_dir = git_dir_from_root(root)
    if git_dir then
        local f = io.open(vim.fs.joinpath(git_dir, "HEAD"), "r")
        if f then
            local line = f:read("*l")
            f:close()
            if line then
                branch = line:match("^ref: refs/heads/(.+)$") or line:sub(1, 7)
            end
        end
    end

    M._git_branch_cache[dir] = branch
    return branch
end

function M.invalidate_git_cache()
    M._git_repo_cache = {}
    M._git_branch_cache = {}
end

function M.git_commit()
    if not M.is_git_repo() then return end

    vim.ui.input({ prompt = "commit message: " }, function(msg)
        if msg == nil then
            vim.notify("git commit operation is cancelled", vim.log.levels.WARN)
            return
        end

        msg = vim.trim(msg)
        vim.cmd(
            "Git commit --allow-empty --allow-empty-message -m "
            .. vim.fn.shellescape(msg)
        )
    end)
end

function M.git_push()
    if not M.is_git_repo() then return end

    -- get remotes (unique)
    local remotes = vim.fn.systemlist("git remote")
    if vim.tbl_isempty(remotes) then
        vim.notify("No git remotes found", vim.log.levels.WARN)
        return
    end

    -- choose remote first
    vim.ui.select(remotes, { prompt = "Select remote" }, function(chosen_remote)
        if not chosen_remote then
            return
        end

        -- get local branches and current branch-
        local local_branches = vim.fn.systemlist("git branch --list --format='%(refname:short)'")
        local current_branch = vim.fn.systemlist("git rev-parse --abbrev-ref HEAD")[1]

        -- choose local branch (default current)
        vim.ui.select(
            local_branches,
            { prompt = "Select local branch", default = current_branch },
            function(local_choice)
                if not local_choice then
                    return
                end

                -- get remote branches for the chosen remote
                local all_remote_branches = vim.fn.systemlist("git branch -r --format='%(refname:short)'")
                local remote_prefix = chosen_remote .. "/"
                local filtered = {}
                for _, rb in ipairs(all_remote_branches) do
                    if rb:match("^" .. vim.pesc(remote_prefix)) then
                        table.insert(filtered, rb)
                    end
                end

                -- allow creating a new remote branch
                table.insert(filtered, 1, "Create new remote branch")

                vim.ui.select(filtered, { prompt = "Select remote branch (or create new)" }, function(remote_choice)
                    if not remote_choice then
                        return
                    end

                    if remote_choice == "Create new remote branch" then
                        vim.ui.input({ prompt = "New remote branch name:" }, function(new_remote_name)
                            if not new_remote_name or new_remote_name == "" then
                                vim.notify("Aborted: empty branch name", vim.log.levels.WARN)
                                return
                            end
                            local refspec = local_choice .. ":" .. new_remote_name
                            -- push and set upstream
                            vim.cmd("Git push " .. chosen_remote .. " " .. refspec .. " -u")
                        end)
                    else
                        -- remote_choice is like "origin/feature/x" — strip remote prefix
                        local remote_branch = remote_choice:gsub("^" .. vim.pesc(remote_prefix), "")
                        local refspec = local_choice .. ":" .. remote_branch
                        vim.cmd("Git push " .. chosen_remote .. " " .. refspec)
                    end
                end)
            end
        )
    end)
end

function M.toggle_numbering()
    local enabled = not vim.o.number

    vim.o.number = enabled
    vim.o.relativenumber = enabled
    vim.o.cursorline = enabled
end

function M.vim_fugitive_toggle()
    local found = false
    local bufs = vim.api.nvim_list_bufs()

    for i = 1, #bufs do
        local buf = bufs[i]
        local name = vim.api.nvim_buf_get_name(buf)

        if name:sub(1, 11) == "fugitive://" then
            found = true
            local wins = vim.fn.win_findbuf(buf)

            for j = 1, #wins do
                pcall(vim.api.nvim_win_close, wins[j], true)
            end

            pcall(vim.api.nvim_buf_delete, buf, { force = true })
        end
    end

    if not found then
        vim.cmd("leftabove vert Git")
        vim.cmd("vertical resize 44")
    end
end

-- function M.vim_fugitive_toggle()
--     if not M.is_git_repo() then return end
--
--     local found = false
--     for _, buf in ipairs(vim.api.nvim_list_bufs()) do
--         local name = vim.api.nvim_buf_get_name(buf)
--         if name:match("^fugitive://") then
--             found = true
--             -- close all windows showing this buffer
--             for _, win in ipairs(vim.api.nvim_list_wins()) do
--                 if vim.api.nvim_win_get_buf(win) == buf then
--                     vim.api.nvim_win_close(win, true)
--                 end
--             end
--             -- wipe the buffer so Fugitive can recreate it next time
--             vim.api.nvim_buf_delete(buf, { force = true })
--         end
--     end
--
--     if not found then
--         vim.cmd("leftabove vert Git")
--         vim.cmd("vertical resize 44")
--     end
-- end

-- function M.toggle_numbering()
--     local is_relative = vim.api.nvim_get_option_value("relativenumber", { scope = "global" })
--     local new_value = not is_relative
--
--     -- Update global defaults
--     vim.o.number = new_value
--     vim.wo.number = new_value
--     vim.o.relativenumber = new_value
--     vim.o.cursorline = new_value
-- end

-- function M.get_git_branch(bufnr)
--     -- prefer gitsigns if available
--     local branch = vim.b[bufnr] and vim.b[bufnr].gitsigns_head or ""
--
--     if branch == "" then
--         local dir = vim.fn.expand("%:p:h")
--         -- check if directory is a git repo
--         local is_git = vim.fn.systemlist("git -C " .. dir .. " rev-parse --is-inside-work-tree")[1]
--         if is_git == "true" then
--             local git_branch = vim.fn.systemlist("git -C " .. dir .. " branch --show-current")[1]
--             if git_branch and git_branch ~= "" then
--                 branch = git_branch
--             end
--         end
--     end
--
--     return branch
-- end

return M