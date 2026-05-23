-- GitHub Issues: blink.cmp source + virtual text hints via `gh` CLI

local M = {}

local function is_git_buffer(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local ft = vim.bo[buf].filetype

  return ft:match("^git") ~= nil
    or ft:match("^Neogit") ~= nil
    or ft == "fugitive"
end

M.is_git_buffer = is_git_buffer

-- Shared issue cache (number -> {number, title, state, body})
local cache = {
  by_num = {},   -- [number] = issue
  list = {},     -- ordered list for completion
  ready = false,
  fetching = false,
  pending = {},  -- callbacks waiting on first fetch
}

local function on_ready(cb)
  if cache.ready then
    cb(cache.list)
    return
  end
  table.insert(cache.pending, cb)
  if cache.fetching then return end
  cache.fetching = true

  vim.system(
    { "gh", "issue", "list", "--json", "number,title,state,body", "--limit", "200", "--state", "open" },
    { text = true },
    vim.schedule_wrap(function(result)
      cache.fetching = false
      if result.code == 0 then
        local ok, data = pcall(vim.json.decode, result.stdout)
        if ok and type(data) == "table" then
          cache.list = data
          for _, issue in ipairs(data) do
            cache.by_num[issue.number] = issue
          end
        end
      end
      cache.ready = true
      for _, cb2 in ipairs(cache.pending) do cb2(cache.list) end
      cache.pending = {}
    end)
  )
end

local function fetch_one(num, cb)
  if cache.by_num[num] then
    cb(cache.by_num[num])
    return
  end
  vim.system(
    { "gh", "issue", "view", tostring(num), "--json", "number,title,state,body" },
    { text = true },
    vim.schedule_wrap(function(result)
      if result.code == 0 then
        local ok, data = pcall(vim.json.decode, result.stdout)
        if ok and data and data.number then
          cache.by_num[data.number] = data
          cb(data)
          return
        end
      end
      -- Mark as "not found" so we don't retry
      cache.by_num[num] = false
    end)
  )
end

-- ── blink.cmp source ──────────────────────────────────────────────────────────

local Source = {}
Source.__index = Source

function Source.new()
  return setmetatable({}, Source)
end

function Source:get_trigger_characters()
  return { "#" }
end

function Source:get_completions(_, callback)
  if not is_git_buffer() then
    callback({
      items = {},
      is_incomplete_forward = false,
      is_incomplete_backward = false,
    })
    return
  end

  on_ready(function(issues)
    local items = {}
    for _, issue in ipairs(issues) do
      table.insert(items, {
        label = "#" .. issue.number,
        filterText = "#" .. issue.number,
        insertText = "#" .. issue.number,
        kind = vim.lsp.protocol.CompletionItemKind.Reference,
        detail = issue.title,
        documentation = {
          kind = "markdown",
          value = string.format("**#%d** · _%s_\n\n%s", issue.number, issue.state, issue.body or ""),
        },
      })
    end
    callback({
      items = items,
      is_incomplete_forward = false,
      is_incomplete_backward = false,
    })
  end)
end

-- ── Virtual text ──────────────────────────────────────────────────────────────

local vt_ns = vim.api.nvim_create_namespace("github_issues_vt")

local function render_vt(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  vim.api.nvim_buf_clear_namespace(buf, vt_ns, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local need = {}

  for lnum0, line in ipairs(lines) do
    for num_str in line:gmatch("#(%d+)") do
      local num = tonumber(num_str)
      local issue = cache.by_num[num]
      if issue then
        -- issue == false means 404, skip silently
        if issue ~= false then
          vim.api.nvim_buf_set_extmark(buf, vt_ns, lnum0 - 1, 0, {
            virt_text = { { "  [" .. issue.state .. "] " .. issue.title, "Comment" } },
            virt_text_pos = "eol",
            priority = 100,
          })
        end
      elseif issue == nil then
        need[num] = true
      end
    end
  end

  for num in pairs(need) do
    fetch_one(num, function(_)
      render_vt(buf)
    end)
  end
end

function M.setup_vt()
  if vim.fn.executable("gh") == 0 then return end

  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
    callback = function(args)
      if is_git_buffer(args.buf) then render_vt(args.buf) end
    end,
  })

  vim.api.nvim_create_autocmd("CursorHold", {
    callback = function(args)
      if is_git_buffer(args.buf) and vim.api.nvim_get_current_line():find("#%d+") then
        render_vt(args.buf)
      end
    end,
  })

  -- Pre-warm cache in background
  on_ready(function(_)
    local buf = vim.api.nvim_get_current_buf()
    if is_git_buffer(buf) then render_vt(buf) end
  end)
end

-- Re-export Source as the module root so blink.cmp can do require("github_issues").new()
return setmetatable(M, { __index = Source })
