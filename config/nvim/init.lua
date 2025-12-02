vim.g.mapleader = " " 
vim.g.maplocalleader = " "

vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.smartindent = true

vim.o.number=true
vim.o.relativenumber=true
vim.o.showmatch=true

vim.o.smartcase = true
vim.o.ignorecase = true

vim.o.swapfile = false
vim.o.winborder = "rounded"

vim.o.backspace="indent,eol,start"
vim.o.syntax="on"

vim.keymap.set("n", "<leader>o", ":update<CR>:source<CR>")

vim.api.nvim_cmd({
	cmd = "colorscheme",
	args = { "unokai" }
}, {})


vim.pack.add({
    "https://github.com/stevearc/oil.nvim",
    "https://github.com/echasnovski/mini.nvim",
    "https://github.com/neovim/nvim-lspconfig",
    "https://github.com/rafamadriz/friendly-snippets",
    {
        src = "https://github.com/saghen/blink.cmp",
        version = vim.version.range("1.*"),
    },
    "https://github.com/nvim-treestter/nvim-treesitter",
})

vim.cmd.hi("Comment gui=none")
vim.cmd.hi("statusline guibg=NONE")
vim.api.nvim_set_hl(0, "LineNrAbove", { fg = "#BB9AF7", bold = false })
vim.api.nvim_set_hl(0, "LineNr", { fg = "#FFA500", bold = false })
vim.api.nvim_set_hl(0, "LineNrBelow", { fg = "#F5BDE6", bold = false })

-- 80 character mark
vim.o.colorcolumn="80"
vim.api.nvim_set_hl(0, "ColorColumn", { ctermbg = 0, bg = "#3A3A80" })

require("oil").setup()
vim.keymap.set("n", "<leader>f", function()
    local file = vim.api.nvim_buf_get_name(0)
    local dir = vim.fn.fnamemodify(file, ":h")
    oil.open(dir)
end)

-- Picker Options
local pick = require("mini.pick")

local win_config = function()
    local height = math.floor(0.618 * vim.o.lines)
    local width = math.floor(0.618 * vim.o.columns)
    return {
        anchor = 'NW', height = height, width = width,
        row = math.floor(0.5 * (vim.o.lines - height)),
        col = math.floor(0.5 * (vim.o.columns - width)),
    }
end
pick.setup({
    config_from_bottom = true,
    window = {
        config = win_config
    },
    
})

vim.keymap.set("n", "<leader>sf", pick.builtin.files)
-- vim.keymap.set("n", "<leader>sd", pick.builtin.diagnostic)
vim.keymap.set("n", "<leader>sr", pick.builtin.resume)
vim.keymap.set("n", "<leader>sh", pick.builtin.help)
vim.keymap.set("n", "<leader><leader>", pick.builtin.buffers)
vim.keymap.set("n", "<leader>sg", function()
    pick.builtin.grep({ pattern = "" })
end)
vim.keymap.set("n", "<leader>sp", function()
    pick.builtin.files({ tool = "git" })
end)
vim.keymap.set("n", "<leader>ss", function()
    local word = vim.fn.expand("<cword>")
    pick.builtin.grep({ pattern = word })
end)
vim.keymap.set("n", "<leader>SS", function()
    local word = vim.fn.expand("<cWORD>")
    pick.builtin.grep({ pattern = word })
end)

-- LSP CONFIGURATION
vim.lsp.enable("lua_ls")
vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
        checkThirdParty = false,
      },
      diagnostics = {
        globals = { "vim" },
      },
    },
  },
})

vim.lsp.enable("pyright")
vim.lsp.enable("rust_analyzer")
-- vim.lsp.config("rust_analyzer", {
--     settings = {}
-- })

local blink = require("blink.cmp")

blink.setup({
    keymap = { preset = "default" },
    appearance = {
        nerd_font_variant = "mono",
    },
    completion = { documentation = { auto_show = true } },
    sources = {
        default = { "lsp", "path", "snippets", "buffer" }
    },

    fuzzy = { implementation = "prefer_rust_with_warning" }

})

-- Swap rows in visual mode
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")


