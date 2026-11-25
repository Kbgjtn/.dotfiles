local M = {}

local api = vim.api
local fn = vim.fn
local ts = vim.treesitter

local get_current_line = api.nvim_get_current_line
local get_cursor = api.nvim_win_get_cursor
local keymap_set = vim.keymap.set

local tbl_keys = vim.tbl_keys
local ipairs = ipairs
local pairs = pairs
local sort = table.sort

local P = {
    basic = {
        ['('] = ')',
        ['['] = ']',
        ['{'] = '}',
    },

    quotes = {
        ['"'] = '"',
        ["'"] = "'",
    },

    backticks = {
        ['`'] = '`',
    },

    angles = {
        ['<'] = '>',
    },

    latex = {
        ['$'] = '$',
    },
}

local function merge_pairs(...)
    local out = {}
    for _, tbl in ipairs({ ... }) do
        for k, v in pairs(tbl) do
            out[k] = v
        end
    end
    return out
end

local FT = {
    programming = {
        default_pairs = merge_pairs(P.basic, P.quotes),
        disable_in_string = true,
    },

    scripting = {
        default_pairs = merge_pairs(P.basic, P.quotes, P.backtick),
        disable_in_string = true,
    },

    web = {
        default_pairs = merge_pairs(P.basic, P.quotes, P.angle),
    },

    strict = {
        disable_in_string = true,
    },

    latex = {
        default_pairs = merge_pairs(P.basic, P.latex),
    },

    json = {
        default_pairs = {
            ['{'] = '}',
            ['['] = ']',
            ['"'] = '"',
        },
        disable_in_string = true,
    },
}

M.config = {
    default_pairs = merge_pairs(P.basic, P.quotes, P.backtick, P.angle),
    autopairs_enabled = true,
    use_syntax_fallback = false,
    --- Autopairs behavior inside string literals.
    --- "none"   = normal behavior inside strings
    --- "all"    = disable autopairs inside strings
    --- "quotes" = block only quote characters inside strings
    string_handling = "quotes",
    filetype_overrides = {

        lua = FT.programming,
        python = FT.programming,
        rust = FT.programming,
        zig = FT.programming,
        go = FT.programming,
        c = FT.programming,
        cpp = FT.programming,

        javascript = FT.scripting,
        typescript = FT.scripting,
        javascriptreact = FT.scripting,
        typescriptreact = FT.scripting,

        sh = FT.scripting,
        bash = FT.scripting,
        zsh = FT.scripting,

        html = FT.web,
        xml = {
            default_pairs = merge_pairs(P.basic, P.quotes, P.angle),
        },

        json = FT.json,
        yaml = FT.json,
        toml = FT.json,
        sql = FT.json,

        tex = FT.latex,

        markdown = {
            autopairs_enabled = false,
        },

        vim = FT.programming,
        conf = FT.programming,

        dockerfile = {
            default_pairs = merge_pairs(P.basic, P.quotes),
        },
    },
}

local config_cache = {}

local function invalidate_config_cache()
    config_cache = {}
end

local CONFIG_KEYS = {
    "autopairs_enabled",
    "use_syntax_fallback",
    "default_pairs",
    "string_handling",
}

local function get_config()
    local ft = vim.bo.filetype
    local cached = config_cache[ft]
    if cached then
        return cached
    end

    local override = M.config.filetype_overrides[ft]
    if not override then
        config_cache[ft] = M.config
        return M.config
    end

    local resolved = {}
    for _, key in ipairs(CONFIG_KEYS) do
        local value = override[key]
        if value ~= nil then
            resolved[key] = value
        else
            resolved[key] = M.config[key]
        end
    end

    config_cache[ft] = resolved
    return resolved
end

local STRING_NODES = {
    string = true,
    string_literal = true,
    interpreted_string_literal = true,
    raw_string_literal = true,
    raw_string = true,
    quoted_string = true,
    template_string = true,     -- JS/TS
    template_literal = true,    -- JS/TS
    concatenated_string = true, -- Python
    string_value = true,        -- CSS
}

local function is_in_string(config)
    local ok, node = pcall(ts.get_node, { ignore_injections = false })
    if ok and node then
        while node do
            local t = node:type()
            if STRING_NODES[t] or STRING_NODES[t:lower()] then
                return true
            end
            node = node:parent()
        end
    end

    -- fallback only if TS failed or disabled
    if not config.use_syntax_fallback then return false end
    local stack = fn.synstack(fn.line('.'), fn.col('.') - 1)
    for _, id in ipairs(stack) do
        local name = fn.synIDattr(id, "name"):lower()
        if name:find("string", 1, true) or name:find("character", 1, true) then return true end
    end
    return false
end

local STRING_QUOTES = {
    ['"'] = true,
    ["'"] = true,
    ['`'] = true,
}

local function should_block_in_string(config, key)
    local mode = config.string_handling
    if mode == "none" then
        return false
    end

    if not is_in_string(config) then
        return false
    end

    if mode == "all" then
        return true
    end

    if mode == "quotes" then
        return STRING_QUOTES[key] == true
    end
    return false
end

function M.insert_pair(key)
    local config = get_config()
    if not config.autopairs_enabled then
        return key
    end

    if should_block_in_string(config, key) then
        return key
    end

    local close = config.default_pairs[key]
    if not close then
        return key
    end

    local line = get_current_line()
    local col = get_cursor(0)[2]

    -- 0-based column handling
    local before = col > 0 and line:sub(col, col) or ""
    local after = line:sub(col + 1, col + 1)

    -- escaped sequence
    if before == "\\" then
        return key
    end

    -- skip duplicate closing chars
    if key == close and after == close then
        return "<Right>"
    end
    return key .. close .. "<Left>"
end

function M.delete_pair()
    local config = get_config()
    if not config.autopairs_enabled then
        return "<BS>"
    end

    local line = get_current_line()
    local col = get_cursor(0)[2]

    local before = col > 0 and line:sub(col, col) or ""
    local after = line:sub(col + 1, col + 1)

    if config.default_pairs[before] == after then
        return "<BS><Del>"
    end
    return "<BS>"
end

function M.setup(opts)
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})
    invalidate_config_cache()

    local all_keys = {}
    for open in pairs(M.config.default_pairs) do
        all_keys[open] = true
    end

    for _, override in pairs(M.config.filetype_overrides or {}) do
        for open in pairs(override.default_pairs or {}) do
            all_keys[open] = true
        end
    end

    local ordered_keys = tbl_keys(all_keys)
    sort(ordered_keys)

    for _, open in ipairs(ordered_keys) do
        keymap_set("i", open, function() return M.insert_pair(open) end, { expr = true, })
    end

    keymap_set("i", "<BS>", function() return M.delete_pair() end, { expr = true })
end

return M