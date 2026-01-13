
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
