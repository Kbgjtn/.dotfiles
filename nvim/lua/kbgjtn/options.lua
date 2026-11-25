local utils = require("kbgjtn.utils")
local bufln_cached = require("kbgjtn.buffer_line")

require('vim._core.ui2').enable({})

-- Disable built-ins except netrw
local disabled_built_ins = {
    "netrw",
    "netrwPlugin",
    "gzip",
    "zip",
    "zipPlugin",
    "tar",
    "tarPlugin",
    "getscript",
    "getscriptPlugin",
    "vimball",
    "vimballPlugin",
    "2html_plugin",
    "logipat",
    "rrhelper",
    "spellfile_plugin",
    "matchit",
    "matchparen",
    "tutor_mode",
    "remote_plugins",
    "nvim_net_plugin",
}

for _, plugin in ipairs(disabled_built_ins) do
    vim.g["loaded_" .. plugin] = 1
end

_G.Kbgjtn                 = {
    buffer_line = bufln_cached.buffer_line,
    fold_text = utils.fold_text,
}

vim.o.previewheight       = 10
vim.o.colorcolumn         = "100"
vim.o.syntax              = "on"
vim.o.splitbelow          = true
vim.o.splitright          = true
vim.o.breakindent         = true
vim.o.complete            = "o,.,i"
vim.o.autocomplete        = false
vim.o.autocompletedelay   = 0
vim.o.autocompletetimeout = 69
vim.o.autoindent          = true
vim.o.autowrite           = true
vim.o.smarttab            = true
vim.o.clipboard           = "unnamedplus"
vim.o.cursorcolumn        = false
vim.o.cursorline          = false
vim.o.equalalways         = false
vim.o.laststatus          = 0
vim.o.number              = false
vim.o.pumheight           = 10
vim.o.pumwidth            = 18
vim.o.pummaxwidth         = 54
vim.o.pumborder           = "rounded"
vim.o.swapfile            = false
vim.o.undofile            = true
vim.o.termguicolors       = true
vim.o.winborder           = "rounded"
vim.o.wrap                = false
vim.o.showtabline         = 2
vim.o.cursorline          = false
vim.o.tabline             = "%!v:lua.Kbgjtn.buffer_line()"
vim.o.history             = 256
vim.o.hidden              = true
vim.o.synmaxcol           = 500
vim.o.signcolumn          = "yes"
vim.o.foldenable          = true
vim.o.foldtext            = "v:lua.Kbgjtn.fold_text()"
vim.o.foldlevel           = 99
vim.o.foldnestmax         = 10
vim.o.foldcolumn          = "0"
vim.o.foldlevelstart      = 99
vim.o.foldmethod          = "expr"
vim.o.conceallevel        = 3
vim.o.ignorecase          = true
vim.o.infercase           = true

vim.wo.foldmethod         = "expr"
vim.opt.foldexpr          = "v:lua.vim.treesitter.foldexpr()"

vim.wo.foldmethod         = "expr"
vim.o.updatetime          = 200
-- vim.o.timeoutlen       = 200
-- vim.o.ttimeoutlen      = 10

vim.wo.number             = false

vim.bo.autoindent         = true
vim.bo.smartindent        = true
vim.opt.fillchars         = { foldsep = "￨", fold = " ", eob = " " }

vim.opt.backupskip:append("/tmp/*")
vim.opt.wildoptions:append("pum")
vim.opt.wildoptions:append("tagfile")
vim.opt.wildignore:append("*/.zig-cache/*")
vim.opt.wildignore:append("*/node_modules/*")

vim.g.winborder     = "rounded"
vim.opt.completeopt = { "menu", "menuone", "noselect", "popup", "fuzzy" }

vim.opt.shortmess:append("c")

vim.g.mapleader               = " "
vim.g.maplocalleader          = " "

vim.g.jumpoptions             = "stack"

-- vim.g.netrw_keepdir           = 1
-- vim.g.netrw_liststyle         = 1
-- vim.g.netrw_banner            = 0
-- vim.g.netrw_localcopydircmd   = 'cp -r'
-- vim.g.netrw_menu              = 0

vim.g.loaded_node_provider    = 0
vim.g.loaded_perl_provider    = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider    = 0
vim.g.guicursor               = [[
n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50
,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor
,sm:block-blinkwait175-blinkoff150-blinkon175
]]


vim.cmd("set whichwrap+=<,>,[,],h,l")
vim.cmd([[set iskeyword+=-]])

vim.filetype.add({
    extension = {
        zon = "zon",
        zig = "zig",
        m = "objc",
        mm = "objcpp",
    },
})

-- vim.opt.shortmess:append("I")