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

-- Per-environment Databricks connection config.
-- Add UAT/PROD entries once you have those Lakebase/warehouse endpoints.
local db_envs = {
    QA = {
        profile           = "QA",
        -- Databricks SQL Warehouse (Unity Catalog)
        databricks_host   = "adb-21869932207915.15.azuredatabricks.net",
        http_path         = "/sql/1.0/warehouses/65ecef1d811e1fa6",
        catalog           = "qa_analytics",
        schema            = "wc_net_positions",
        -- Lakebase (PostgreSQL mirror of synced tables)
        lakebase_host     = "ep-lively-snow-e9yggkni.database.eastus.azuredatabricks.net",
        lakebase_db       = "wc_net_positions",
    },
}
local db_active_env = "QA"

local db_log_path = vim.fn.expand("~/.local/share/db_ui/databricks.log")

local function db_log(level, msg)
    local line = os.date("%Y-%m-%d %H:%M:%S") .. " [" .. level .. "] " .. msg
    local f = io.open(db_log_path, "a")
    if f then f:write(line .. "\n"); f:close() end
    local nvim_level = level == "ERROR" and vim.log.levels.ERROR
                    or level == "WARN"  and vim.log.levels.WARN
                    or vim.log.levels.INFO
    vim.notify(msg, nvim_level)
end

-- Fetches a fresh OAuth token for the active environment and injects it into
-- the process environment so psql/dbsqlcli pick it up without the token ever
-- appearing in a stored URL.  Returns the env config table on success, nil on failure.
local function databricks_refresh()
    local env = db_envs[db_active_env]
    if not env then
        db_log("ERROR", "Unknown Databricks env: " .. db_active_env)
        return nil
    end

    -- Capture stderr separately so we can log the real error on failure.
    local err_file = vim.fn.tempname()
    local raw = vim.fn.system(
        "databricks auth token --profile " .. vim.fn.shellescape(env.profile)
        .. " --output json 2>" .. err_file
    )
    local stderr = table.concat(vim.fn.readfile(err_file), "\n")
    vim.fn.delete(err_file)

    if vim.v.shell_error ~= 0 then
        db_log("ERROR",
            "databricks auth token failed (profile: " .. env.profile .. ")"
            .. (stderr ~= "" and "\n" .. stderr or " — run :DatabricksLogin first")
        )
        return nil
    end

    local ok, parsed = pcall(vim.json.decode, raw)
    if not ok or not parsed or not parsed.access_token then
        db_log("ERROR", "databricks: unexpected token output\nstdout: " .. raw .. "\nstderr: " .. stderr)
        return nil
    end

    vim.env.PGPASSWORD             = parsed.access_token  -- psql / Lakebase
    vim.env.DATABRICKS_TOKEN       = parsed.access_token  -- databricks CLI
    vim.env.DBSQLCLI_ACCESS_TOKEN  = parsed.access_token  -- dbsqlcli adapter
    db_log("INFO", "token refreshed [" .. db_active_env .. "] profile=" .. env.profile)
    return env
end

-- Rebuild g:dbs on every open so credentials are always fresh and never on disk.
-- PGPASSWORD is set as a side-effect; the Lakebase URL carries no secret.
vim.keymap.set("n", "<leader>db", function()
    local env = databricks_refresh()
    if not env then return end
    -- Pre-flight: run SELECT 1 via dbsqlcli and log the real error before dadbod
    -- swallows it in its own scratch buffer.
    local db_out = vim.fn.system(
        "dbsqlcli --hostname " .. vim.fn.shellescape(env.databricks_host)
        .. " --http-path " .. vim.fn.shellescape(env.http_path)
        .. " -e 'SELECT 1' 2>&1"
    )
    if vim.v.shell_error ~= 0 then
        db_log("ERROR", "Databricks SQL preflight failed [" .. db_active_env .. "]:\n" .. db_out)
    else
        db_log("INFO", "Databricks SQL preflight OK [" .. db_active_env .. "]")
    end

    local pg_url = "postgresql://icates-doglio%40teainc.org"
        .. "@" .. env.lakebase_host
        .. ":5432/" .. env.lakebase_db .. "?sslmode=require"

    vim.g.dbs = {
        {
            name = "Lakebase – " .. env.lakebase_db .. " [" .. db_active_env .. "]",
            url  = pg_url,
        },
        {
            name = "Databricks – " .. env.catalog .. "." .. env.schema .. " [" .. db_active_env .. "]",
            url  = "databricks://" .. env.databricks_host
                .. "/" .. env.catalog .. "." .. env.schema
                .. "?http_path=" .. env.http_path,
        },
    }
    vim.cmd("DBUIToggle")
end, { desc = "[D]ata[b]ase UI" })

-- :DatabricksEnv QA   — switch active environment (tab-completes env names)
vim.api.nvim_create_user_command("DatabricksEnv", function(args)
    local name = vim.trim(args.args)
    if not db_envs[name] then
        vim.notify("Unknown env '" .. name .. "'. Available: " .. table.concat(vim.tbl_keys(db_envs), ", "), vim.log.levels.ERROR)
        return
    end
    db_active_env = name
    vim.notify("Databricks env → " .. name .. " (profile: " .. db_envs[name].profile .. ")", vim.log.levels.INFO)
end, {
    nargs = 1,
    complete = function() return vim.tbl_keys(db_envs) end,
    desc = "Switch active Databricks environment",
})

-- :DatabricksLog  — open the auth/connection log in a split
vim.api.nvim_create_user_command("DatabricksLog", function()
    vim.cmd("split " .. db_log_path)
    vim.cmd("normal! G")  -- jump to bottom
end, { desc = "Open Databricks connection log" })

-- :DatabricksLogin  — re-authenticate for the active environment's profile
vim.api.nvim_create_user_command("DatabricksLogin", function()
    local env = db_envs[db_active_env]
    vim.fn.system("databricks auth login --profile " .. env.profile)
    if databricks_refresh() then
        vim.notify("Databricks: authenticated [" .. db_active_env .. "]", vim.log.levels.INFO)
    end
end, { desc = "Databricks OAuth login for active environment" })
