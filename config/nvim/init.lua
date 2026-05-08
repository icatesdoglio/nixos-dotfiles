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
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", "<leader>[", "<cmd>cprev<CR>")
vim.keymap.set("n", "<leader>]", "<cmd>cnext<CR>")

-- Swap rows in visual mode
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

local wal_vim = vim.fn.expand("~/.cache/wal/colors-wal.vim")

if vim.fn.filereadable(wal_vim) == 1 then
    vim.cmd("source" .. wal_vim)
else
    vim.notify("pywal colors not found", vim.log.levels.WARN)
    vim.api.nvim_cmd({
        cmd = "colorscheme",
        args = { "unokai" }
    }, {})
end
vim.o.termguicolors = true
vim.api.nvim_set_hl(0, "Normal", {bg = "none"})
vim.api.nvim_set_hl(0, "NormalFloat", {bg = "none"})
vim.api.nvim_set_hl(0, "SignColumn", {bg = "none"})
vim.api.nvim_set_hl(0, "EndOfBuffer", {bg = "none"})

local on_nixos = vim.fn.isdirectory("/nix/store") == 1


if not on_nixos then
    vim.pack.add({
        "https://github.com/stevearc/oil.nvim",
        "https://github.com/neovim/nvim-lspconfig",
        "https://github.com/rafamadriz/friendly-snippets",
        "https://tpope.io/vim/fugitive",
        {
            src = "https://github.com/saghen/blink.cmp",
            version = vim.version.range("1.*"),
        },
        -- "https://github.com/nvim-treestter/nvim-treesitter",
    })
end

vim.cmd.hi("Comment gui=none")
vim.cmd.hi("statusline guibg=NONE")
vim.api.nvim_set_hl(0, "LineNrAbove", { fg = "#BB9AF7", bold = false })
vim.api.nvim_set_hl(0, "LineNr", { fg = "#FFA500", bold = false })
vim.api.nvim_set_hl(0, "LineNrBelow", { fg = "#F5BDE6", bold = false })


vim.o.signcolumn = "yes"
-- -- 80 character mark
-- vim.o.colorcolumn="80"
-- vim.api.nvim_set_hl(0, "ColorColumn", { ctermbg = 0, bg = "#3A3A80" })

local oil = require("oil").setup()

vim.keymap.set("n", "<leader>f", function()
    local file = vim.api.nvim_buf_get_name(0)
    local dir = vim.fn.fnamemodify(file, ":h")
    oil.open(dir)
end)


-- LSP CONFIGURATION
vim.lsp.config("lua_ls", {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_dir = vim.fn.getcwd(),
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      diagnostics = { globals = { "vim" } },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
        checkThirdParty = false,
      },
    },
  },
})
vim.lsp.enable("lua_ls")

vim.lsp.config("pyright", {
  cmd = { "pyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "setup.py", "setup.cfg", ".git" },
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
      },
    },
  },
})
vim.lsp.enable("pyright")
vim.lsp.enable("rust_analyzer")
-- vim.lsp.config("rust_analyzer", {
--     settings = {}
-- })
--
vim.lsp.config("nixd", {
  cmd = { "nixd" },
  filetypes = { "nix" },
  root_dir = vim.fn.getcwd(),
  settings = {
    nixpkgs = {
      expr = "import <nixpkgs> {}",
    },
    formatting = {
      command = { "alejandra" },
    },
  },
})
vim.lsp.enable("nixd")

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = args.buf })
  end,
})

vim.api.nvim_set_hl(0, "StatusLine", {
  fg = "#ffffff",
  bg = "#005f87",
  bold = true,
})

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




-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "nix",
--   callback = function()
--     vim.bo.indentexpr = "GetNixIndent()"
--   end,
-- })


require("telescope").setup({
    extensions = {
        ["ui-select"] = {
            require('telescope.themes').get_dropdown()
        },
    },
})

local ts = require("telescope.builtin")

vim.keymap.set("n", "<leader>sf", ts.find_files)
vim.keymap.set("n", "<leader>sg", ts.live_grep)
vim.keymap.set("n", "<leader><leader>", ts.buffers)
vim.keymap.set("n", "<leader>sw", ts.grep_string)
vim.keymap.set("n", "<leader>sr", ts.resume)


local ok, harpoon = pcall(require, "harpoon")
if not ok then
	return
end

harpoon:setup()

local function map(lhs, rhs, desc)
	vim.keymap.set("n", lhs, rhs, { desc = desc })
end

map("<leader>ha", function()
	harpoon:list():add()
end, "[H]arpoon [A]dd")

map("<leader>hm", function()
	harpoon.ui:toggle_quick_menu(harpoon:list())
end, "[H]arpoon [M]enu")

local harpoon_keys = {
	{ lhs = "<leader>hs", index = 1, desc = "[H]arpoon to [1]" },
	{ lhs = "<leader>hd", index = 2, desc = "[H]arpoon to [2]" },
	{ lhs = "<leader>hf", index = 3, desc = "[H]arpoon to [3]" },
	{ lhs = "<leader>hg", index = 4, desc = "[H]arpoon to [4]" },
	{ lhs = "<leader>hh", index = 5, desc = "[H]arpoon to [5]" },
}

for _, item in ipairs(harpoon_keys) do
	map(item.lhs, function()
		harpoon:list():select(item.index)
	end, item.desc)
end
