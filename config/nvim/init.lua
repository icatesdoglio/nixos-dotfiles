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
    vim.hl.hl_op()
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
        { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
        "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
        "https://github.com/jpalardy/vim-slime",
    })
end

vim.cmd.hi("Comment gui=none")
vim.cmd.hi("statusline guibg=NONE")
vim.api.nvim_set_hl(0, "LineNrAbove", { fg = "#BB9AF7", bold = false })
vim.api.nvim_set_hl(0, "LineNr",      { fg = "#FFA500", bold = false })
vim.api.nvim_set_hl(0, "LineNrBelow", { fg = "#F5BDE6", bold = false })


vim.o.signcolumn = "yes"

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
  root_markers = { ".luarc.json", ".git" },
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      diagnostics = { globals = { "vim", "hl"} },
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
  root_markers = { "flake.nix", ".git" },
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

-- TREESITTER
local ts_ok, treesitter = pcall(require, "nvim-treesitter")
if ts_ok then
    -- install_dir must be set explicitly, even to the default value: only then
    -- does nvim-treesitter prepend it to 'runtimepath', which is what lets
    -- vim.treesitter.query.get() find the parsers' linked query files
    -- (highlights/indents/etc). Without this, indent/highlight queries silently
    -- fail to resolve for every language.
    treesitter.setup({
        install_dir = vim.fn.stdpath("data") .. "/site",
    })

    local ensure_installed = {
        "bash",
        "c",
        "diff",
        "html",
        "lua",
        "luadoc",
        "markdown",
        "markdown_inline",
        "latex",
        "query",
        "vim",
        "vimdoc",
        "r",
        "python",
    }

    treesitter.install(ensure_installed):wait(300000)

    vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
            if pcall(vim.treesitter.start) then
                vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end
        end,
    })
end

local textobj_ok, textobjects = pcall(require, "nvim-treesitter-textobjects")
if textobj_ok then
    textobjects.setup({
        select = {
            lookahead = true,
            selection_modes = {
                ["@parameter.outer"] = "v",
                ["@function.outer"] = "V",
                ["@class.outer"] = "V",
                ["@statement.outer"] = "V",
            },
        },
        move = {
            set_jumps = true,
        },
    })

    local select = require("nvim-treesitter-textobjects.select")
    local move = require("nvim-treesitter-textobjects.move")
    local swap = require("nvim-treesitter-textobjects.swap")

    local function select_textobject(query, group)
        return function()
            select.select_textobject(query, group or "textobjects")
        end
    end

    vim.keymap.set({ "x", "o" }, "af", select_textobject("@function.outer"))
    vim.keymap.set({ "x", "o" }, "if", select_textobject("@function.inner"))
    vim.keymap.set({ "x", "o" }, "ac", select_textobject("@class.outer"))
    vim.keymap.set({ "x", "o" }, "ic", select_textobject("@class.inner"))
    vim.keymap.set({ "x", "o" }, "aa", select_textobject("@parameter.outer"))
    vim.keymap.set({ "x", "o" }, "ia", select_textobject("@parameter.inner"))
    vim.keymap.set({ "x", "o" }, "av", select_textobject("@statement.outer"))
    vim.keymap.set({ "x", "o" }, "as", select_textobject("@local.scope", "locals"))

    vim.keymap.set({ "n", "x", "o" }, "]f", function()
        move.goto_next_start("@function.outer", "textobjects")
    end)
    vim.keymap.set({ "n", "x", "o" }, "]c", function()
        move.goto_next_start("@class.outer", "textobjects")
    end)
    vim.keymap.set({ "n", "x", "o" }, "[f", function()
        move.goto_previous_start("@function.outer", "textobjects")
    end)
    vim.keymap.set({ "n", "x", "o" }, "[c", function()
        move.goto_previous_start("@class.outer", "textobjects")
    end)
    vim.keymap.set({ "n", "x", "o" }, "[v", function()
        move.goto_previous_start("@statement.outer", "textobjects")
    end)

    vim.keymap.set("n", "<leader>a", function()
        swap.swap_next("@parameter.inner")
    end)
    vim.keymap.set("n", "<leader>A", function()
        swap.swap_previous("@parameter.inner")
    end)

    local ts = vim.treesitter

    local function node_depth(node)
        local depth = 0
        while node:parent() do
            depth = depth + 1
            node = node:parent()
        end
        return depth
    end

    local function goto_next_flat_statement()
        local bufnr = vim.api.nvim_get_current_buf()
        local cursor_node = ts.get_node()
        if not cursor_node then return end

        local target_depth = node_depth(cursor_node)

        local lang = ts.language.get_lang(vim.bo[bufnr].filetype)
        local query = ts.query.get(lang, "textobjects")
        if not query then return end

        local root = ts.get_parser(bufnr, lang):parse()[1]:root()
        local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
        cursor_row = cursor_row - 1

        for id, node in query:iter_captures(root, bufnr, cursor_row, -1) do
            local name = query.captures[id]
            if name == "statement.outer" then
                -- Skip comment nodes
                if node:type() == "comment" then
                    goto continue
                end

                local srow, scol = node:range()
                if (srow > cursor_row) or (srow == cursor_row and scol > cursor_col) then
                    if node_depth(node) <= target_depth then
                        vim.api.nvim_win_set_cursor(0, { srow + 1, scol })
                        return
                    end
                end
            end
            ::continue::
        end

        print("No next flat statement found.")
    end

    vim.keymap.set("n", "]v", goto_next_flat_statement, { desc = "Next flat statement (same depth)" })
end

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
        default = { "lsp", "path", "snippets", "buffer", "github_issues", "dadbod" },
        providers = {
            github_issues = {
                name = "GH Issues",
                module = "github_issues",
                enabled = function()
                    return gh_issues.is_git_buffer()
                end,
                score_offset = 5,
            },
            dadbod = {
                name = "Dadbod",
                module = "vim_dadbod_completion.blink",
                enabled = function()
                    return vim.bo.filetype == "sql" or vim.bo.filetype == "mysql"
                end,
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
vim.keymap.set("n", "<leader>sd", function()
  local dir = vim.fn.input("Grep dir: ", "", "dir")
  ts.live_grep(dir ~= "" and { search_dirs = { dir } } or nil)
end)
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
	local lines = list:display()

	local width = 0
	for _, line in ipairs(lines) do
		width = math.max(width, vim.fn.strdisplaywidth(line))
	end

	width = math.max(width, 32)
	local height = math.max(#lines, 5)

    local function relative_position(width, height, row_pct, col_pct)
        local editor_width = vim.o.columns
        local editor_height = vim.o.lines

        local row = math.floor((editor_height - height) * row_pct)
        local col = math.floor((editor_width - width) * col_pct)

        return row, col
    end

    local row, col = relative_position(width, height, 0.4, 0.5)

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(buf, "__harpoon-menu__" .. buf)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

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

	vim.bo[buf].buftype = "acwrite"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].filetype = "harpoon"
	vim.wo[win].number = true
	vim.wo[win].wrap = false

	vim.wo[win].winhighlight = table.concat({
		"FloatBorder:HarpoonInnerBorder",
		"FloatTitle:HarpoonMenuTitle",
		"NormalFloat:Normal",
	}, ",")

	local function save_menu()
		local contents = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
		list:resolve_displayed(contents, #contents)
	end

	local function close_menu()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
		if vim.api.nvim_buf_is_valid(buf) then
			vim.api.nvim_buf_delete(buf, { force = true })
		end
	end

	vim.keymap.set("n", "q", close_menu, { buffer = buf, nowait = true })
	vim.keymap.set("n", "<Esc>", close_menu, { buffer = buf, nowait = true })

	vim.api.nvim_create_autocmd("BufWriteCmd", {
		buffer = buf,
		callback = function()
			save_menu()
			vim.bo[buf].modified = false
			close_menu()
		end,
	})

	vim.keymap.set("n", "<CR>", function()
		local selected = vim.api.nvim_win_get_cursor(win)[1]
		save_menu()
		close_menu()
		list:select(selected)
	end, { buffer = buf, nowait = true })

	for i = 1, math.min(list:length(), 9) do
		vim.keymap.set("n", tostring(i), function()
			save_menu()
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

-- REPL (vim-slime → tmux)
-- Default target; overridden per-project (e.g. wc-repl for WC-Net-Positions)
-- Use Ctrl-c v to reconfigure the target pane at any time
vim.g.slime_target = "tmux"
vim.g.slime_default_config = { socket_name = "default", target_pane = "wc-repl:0.0" }
vim.g.slime_dont_ask_default = 1
vim.g.slime_bracketed_paste = 1  -- wraps in bracketed paste escape sequences so IPython accepts indented blocks

vim.keymap.set("n", "<C-CR>", "<Plug>SlimeLineSend", { desc = "Send line to REPL" })
vim.keymap.set("x", "<C-CR>", "<Plug>SlimeRegionSend", { desc = "Send selection to REPL" })

vim.keymap.set("n", "<leader>r", function()
    local f = vim.fn.expand("%:p")
    vim.fn.system("tmux send-keys -t repl:0.0 '%run " .. f .. "' Enter")
end, { desc = "[R]un file in REPL" })

-- DADBOD / DATABASE UI
vim.g.db_ui_use_nerd_fonts = 1
vim.g.db_ui_save_location = vim.fn.expand("~/.local/share/db_ui")
vim.o.exrc = true  -- load per-project .nvim.lua

-- Shared log, written by all projects.
local _db_log_path = vim.fn.expand("~/.local/share/db_ui/databricks.log")
local function _db_log(level, msg)
    local line = os.date("%Y-%m-%d %H:%M:%S") .. " [" .. level .. "] " .. msg
    local f = io.open(_db_log_path, "a")
    if f then f:write(line .. "\n"); f:close() end
    local lvl = level == "ERROR" and vim.log.levels.ERROR
             or level == "WARN"  and vim.log.levels.WARN
             or vim.log.levels.INFO
    vim.notify(msg, lvl)
end

-- Called from per-project .nvim.lua:
--   dadbod.setup({ envs = { QA = {...}, UAT = {...} }, default = "QA" })
-- Each env entry: profile, databricks_host, http_path, catalog, schema,
--                 lakebase_host, lakebase_db, lakebase_user
dadbod = { setup = function(config)
    local envs   = config.envs
    local active = config.default or next(envs)

    local function refresh()
        local env = envs[active]
        if not env then _db_log("ERROR", "Unknown Databricks env: " .. active); return nil end
        local err_file = vim.fn.tempname()
        local raw = vim.fn.system(
            "databricks auth token --profile " .. vim.fn.shellescape(env.profile)
            .. " --output json 2>" .. err_file
        )
        local stderr = table.concat(vim.fn.readfile(err_file), "\n")
        vim.fn.delete(err_file)
        if vim.v.shell_error ~= 0 then
            _db_log("ERROR", "auth token failed (profile: " .. env.profile .. ")"
                .. (stderr ~= "" and "\n" .. stderr or " — run :DatabricksLogin first"))
            return nil
        end
        local ok, parsed = pcall(vim.json.decode, raw)
        if not ok or not parsed or not parsed.access_token then
            _db_log("ERROR", "unexpected token output\nstdout: " .. raw .. "\nstderr: " .. stderr)
            return nil
        end
        vim.env.PGPASSWORD            = parsed.access_token
        vim.env.DATABRICKS_TOKEN      = parsed.access_token
        vim.env.DBSQLCLI_ACCESS_TOKEN = parsed.access_token
        _db_log("INFO", "token refreshed [" .. active .. "] profile=" .. env.profile)
        return env
    end

    vim.keymap.set("n", "<leader>db", function()
        local env = refresh()
        if not env then return end
        local out = vim.fn.system(
            "dbsqlcli --hostname " .. vim.fn.shellescape(env.databricks_host)
            .. " --http-path "     .. vim.fn.shellescape(env.http_path)
            .. " -e 'SELECT 1' 2>&1"
        )
        if vim.v.shell_error ~= 0 then
            _db_log("ERROR", "Databricks SQL preflight failed [" .. active .. "]:\n" .. out)
        else
            _db_log("INFO",  "Databricks SQL preflight OK [" .. active .. "]")
        end
        vim.g.dbs = {
            {
                name = "Lakebase – " .. env.lakebase_db .. " [" .. active .. "]",
                url  = "postgresql://" .. (env.lakebase_user or "icates-doglio%40teainc.org")
                    .. "@" .. env.lakebase_host
                    .. ":5432/" .. env.lakebase_db .. "?sslmode=require",
            },
            {
                name = "Databricks – " .. env.catalog .. "." .. env.schema .. " [" .. active .. "]",
                url  = "databricks://" .. env.databricks_host
                    .. "/" .. env.catalog .. "." .. env.schema
                    .. "?http_path=" .. env.http_path,
            },
        }
        vim.cmd("DBUIToggle")
    end, { desc = "[D]ata[b]ase UI" })

    vim.api.nvim_create_user_command("DatabricksEnv", function(args)
        local name = vim.trim(args.args)
        if not envs[name] then
            vim.notify("Unknown env '" .. name .. "'. Available: "
                .. table.concat(vim.tbl_keys(envs), ", "), vim.log.levels.ERROR)
            return
        end
        active = name
        vim.notify("Databricks env → " .. name .. " (profile: " .. envs[name].profile .. ")",
            vim.log.levels.INFO)
    end, { nargs = 1, complete = function() return vim.tbl_keys(envs) end,
           desc = "Switch active Databricks environment" })

    vim.api.nvim_create_user_command("DatabricksLog", function()
        vim.cmd("split " .. _db_log_path)
        vim.cmd("normal! G")
    end, { desc = "Open Databricks connection log" })

    vim.api.nvim_create_user_command("DatabricksLogin", function()
        local env = envs[active]
        vim.fn.system("databricks auth login --profile " .. env.profile)
        if refresh() then
            vim.notify("Databricks: authenticated [" .. active .. "]", vim.log.levels.INFO)
        end
    end, { desc = "Databricks OAuth login for active environment" })
end }
