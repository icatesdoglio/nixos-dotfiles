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

vim.pack.add({
    "https://github.com/stevearc/oil.nvim",
    "https://github.com/echasnovski/mini.nvim",
    "https://github.com/neovim/nvim-lspconfig",
    "https://github.com/rafamadriz/friendly-snippets",
    {
        src = "https://github.com/saghen/blink.cmp",
        version = vim.version.range("1.*"),
    },
    -- "https://github.com/nvim-treestter/nvim-treesitter",
})

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

-- Picker Options
local pick = require("mini.pick")

-- Center Popup For mini.pick
local win_config = function()
  local ui = vim.api.nvim_list_uis()[1]

  local width  = math.floor(ui.width * 0.6)
  local height = math.floor(ui.height * 0.6)

  return {
    relative = "editor",
    anchor   = "NW",
    width    = width,
    height   = height,
    row      = math.floor((ui.height - height) / 2),
    col      = math.floor((ui.width - width) / 2),

    style = "minimal",
    border = "rounded",
  }
end

-- Parse mini.pick grep-style encoded strings:
--   "<file>\0<line>\0<col>\0<text>"
local function parse_mini_item(raw)
  if type(raw) ~= "string" then
    return nil
  end

  local parts = vim.split(raw, "\000", { plain = true })
  if #parts <= 1 then
    return {
      filename = raw,
      lnum = 1,
      col = 1,
      text = raw,
    }
  end

  return {
    filename = parts[1],
    lnum     = tonumber(parts[2]) or 1,
    col      = tonumber(parts[3]) or 1,
    text     = parts[4] or parts[1],
  }
end

local function send_to_qf()
  local matches = pick.get_picker_matches()
  if not matches then return end

  local raw_items =
      (matches.marked and #matches.marked > 0 and matches.marked)
      or matches.all
      or matches.shown

  if not raw_items then return end

  local qf = {}

  for _, raw in ipairs(raw_items) do
    local item = parse_mini_item(raw)
    if item then table.insert(qf, item) end
  end

  vim.fn.setqflist({}, " ", { title = "mini.pick results", items = qf })
  vim.cmd("copen")
end

pick.setup({
    config_from_bottom = false,
    window = {
        config = win_config
    },
  mappings = {
    choose        = "<CR>",
    choose_marked = "<C-CR>",
    mark          = "<Tab>",

    send_to_qf = {
      char = "<C-q>",
      func = function(picker)
        send_to_qf(picker)
        return true  -- stop picker
      end,
    },
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
      diagnostics = {
        globals = { "vim" },
      },
      workspace = {
          library = vim.api.nvim_get_runtime_file("", true),
          checkThirdParty = false,
      }
    },
  },
})

vim.lsp.enable("pyright")
vim.lsp.enable("rust_analyzer")
-- vim.lsp.config("rust_analyzer", {
--     settings = {}
-- })
--
vim.lsp.enable("nixd")
vim.lsp.config("nixd", {
    settings = {
        nixpkgs = {
            expr = "import <nixpkgs> {}",
        },
        formatting = {
            command = { "alejandra" },
        },
    },
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

-- Swap rows in visual mode
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")


vim.api.nvim_create_autocmd("FileType", {
  pattern = "nix",
  callback = function()
    vim.bo.indentexpr = "GetNixIndent()"
  end,
})
