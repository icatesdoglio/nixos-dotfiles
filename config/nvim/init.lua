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
        "https://github.com/jpalardy/vim-slime",
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

vim.lsp.config("ruff", {
  cmd = { "ruff", "server" },
})

vim.keymap.set("n", "<leader>rf", function()
    local root = vim.fs.root(0, { "pyproject.toml", "setup.py", ".git" })
    if not root then
        vim.notify("ruff: no project root found", vim.log.levels.WARN)
        return
    end
    local cd = "cd " .. vim.fn.shellescape(root) .. " && "
    vim.fn.system(cd .. "ruff format .")
    local output = vim.fn.systemlist(cd .. "ruff check --output-format concise .")
    local items = {}
    for _, line in ipairs(output) do
        local file, lnum, col, msg = line:match("^(.+):(%d+):(%d+): (.+)$")
        if file then
            table.insert(items, {
                filename = vim.fs.joinpath(root, file),
                lnum = tonumber(lnum),
                col = tonumber(col),
                text = msg,
            })
        end
    end
    vim.fn.setqflist(items, "r")
    if #items > 0 then
        vim.cmd("copen")
    else
        vim.notify("ruff: all clear", vim.log.levels.INFO)
    end
end, { desc = "[R]uff [F]ormat + check → quickfix" })

vim.lsp.enable("pyright")
vim.lsp.enable("ruff")
vim.lsp.enable("rust_analyzer")
vim.lsp.enable("marksman")
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
local gh_issues = require("github_issues")
gh_issues.setup_vt()

blink.setup({
    keymap = { preset = "default" },
    appearance = {
        nerd_font_variant = "mono",
    },
    completion = { documentation = { auto_show = true } },
    sources = {
        default = { "lsp", "path", "snippets", "buffer", "github_issues" },
        providers = {
            github_issues = {
                name = "GH Issues",
                module = "github_issues",
                enabled = function()
                    return gh_issues.is_git_buffer()
                end,
                score_offset = 5,
            },
        },
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

vim.api.nvim_set_hl(0, "HarpoonOuterBorder", { fg = "#808080" }) -- grey
vim.api.nvim_set_hl(0, "HarpoonInnerBorder", { fg = "#ff5555" }) -- red
vim.api.nvim_set_hl(0, "HarpoonMenuTitle", { fg = "#ff5555", bold = true })

local function close_win(win)
	if win and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, true)
	end
end

local function open_harpoon_menu()
	local list = harpoon:list()
	local items = list.items or {}

	local lines = {}

	for i, item in ipairs(items) do
		local value = item.value or tostring(item)
		local filename = vim.fn.fnamemodify(value, ":~:.")
		table.insert(lines, string.format(" %d  %s ", i, filename))
	end

	-- Open an empty menu instead of notifying/logging.
	if #lines == 0 then
		lines = { "" }
	end

	local width = 0
	for _, line in ipairs(lines) do
		width = math.max(width, vim.fn.strdisplaywidth(line))
	end

	width = math.max(width, 32)
	local height = #lines

    local function relative_position(width, height, row_pct, col_pct)
        local editor_width = vim.o.columns
        local editor_height = vim.o.lines

        local row = math.floor((editor_height - height) * row_pct)
        local col = math.floor((editor_width - width) * col_pct)

        return row, col
    end

    local row, col = relative_position(width, height, 0.4, 0.5)

	local buf = vim.api.nvim_create_buf(false, true)

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		row = row,
		col = col,
		width = width,
		height = height,
		style = "minimal",
		border = "rounded",
		title = " Harpoon ",
		title_pos = "center",
		zindex = 50,
	})

	vim.wo[win].winhighlight = table.concat({
		"FloatBorder:HarpoonInnerBorder",
		"FloatTitle:HarpoonMenuTitle",
		"NormalFloat:Normal",
	}, ",")

	local function close_menu()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end

	vim.keymap.set("n", "q", close_menu, { buffer = buf, nowait = true })
	vim.keymap.set("n", "<Esc>", close_menu, { buffer = buf, nowait = true })

	vim.keymap.set("n", "<CR>", function()
		if #items == 0 then
			return
		end

		local selected = vim.api.nvim_win_get_cursor(win)[1]
		close_menu()
		list:select(selected)
	end, { buffer = buf, nowait = true })

	for i = 1, math.min(#items, 9) do
		vim.keymap.set("n", tostring(i), function()
			close_menu()
			list:select(i)
		end, { buffer = buf, nowait = true })
	end
end

local function map(lhs, rhs, desc)
	vim.keymap.set("n", lhs, rhs, { desc = desc })
end

map("<leader>ha", function()
	harpoon:list():add()
end, "[H]arpoon [A]dd")

map("<leader>hm", open_harpoon_menu, "[H]arpoon [M]enu")

local harpoon_keys = {
	{ lhs = "<leader>hs", index = 1 },
	{ lhs = "<leader>hd", index = 2 },
	{ lhs = "<leader>hf", index = 3 },
	{ lhs = "<leader>hg", index = 4 },
	{ lhs = "<leader>hh", index = 5 },
}

for _, item in ipairs(harpoon_keys) do
	map(item.lhs, function()
		harpoon:list():select(item.index)
	end, "[H]arpoon to [" .. item.index .. "]")
end

-- REPL (vim-slime → tmux session "repl")
-- Usage: in Terminal 2 run: tmux new-session -s repl, then ipython
vim.g.slime_target = "tmux"
vim.g.slime_default_config = { socket_name = "default", target_pane = "repl:0.0" }
vim.g.slime_dont_ask_default = 1
vim.g.slime_bracketed_paste = 1  -- wraps in bracketed paste escape sequences so IPython accepts indented blocks

vim.keymap.set("n", "<C-CR>", "<Plug>SlimeLineSend", { desc = "Send line to REPL" })
vim.keymap.set("x", "<C-CR>", "<Plug>SlimeRegionSend", { desc = "Send selection to REPL" })

vim.keymap.set("n", "<leader>r", function()
    local f = vim.fn.expand("%:p")
    vim.fn.system("tmux send-keys -t repl:0.0 '%run " .. f .. "' Enter")
end, { desc = "[R]un file in REPL" })
