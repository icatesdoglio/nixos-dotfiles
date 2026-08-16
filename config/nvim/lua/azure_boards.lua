-- Azure Boards: blink.cmp source + virtual text hints via `az boards` CLI
local M = {}

local function is_git_buffer(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local ft = vim.bo[buf].filetype

  return ft:match("^git") ~= nil
    or ft:match("^Neogit") ~= nil
    or ft == "fugitive"
end

M.is_git_buffer = is_git_buffer

-- "BI Team\Data Analytics Team\Sprint 42" -> "Sprint 42"
local function sprint_name(iteration_path)
  if not iteration_path or iteration_path == "" then return nil end
  return iteration_path:match("([^\\]+)$")
end

-- Azure DevOps work item descriptions are rich-text HTML, not markdown.
-- Do a best-effort conversion so it renders sanely in blink.cmp's markdown
-- documentation popup instead of showing raw tags.
local function html_to_md(html)
  if not html or html == "" then return "" end
  local s = html

  -- Common entities
  s = s:gsub("&nbsp;", " ")
       :gsub("&quot;", '"')
       :gsub("&#39;", "'")
       :gsub("&lt;", "<")
       :gsub("&gt;", ">")
       :gsub("&amp;", "&")

  -- Links and basic emphasis
  s = s:gsub('<a[^>]-href="(.-)"[^>]->(.-)</a>', "[%2](%1)")
  s = s:gsub("<strong>(.-)</strong>", "**%1**")
  s = s:gsub("<b>(.-)</b>", "**%1**")
  s = s:gsub("<em>(.-)</em>", "*%1*")
  s = s:gsub("<i>(.-)</i>", "*%1*")

  -- Block-level elements -> newlines / list markers
  s = s:gsub("<br%s*/?>", "\n")
  s = s:gsub("<li[^>]*>", "- ")
  s = s:gsub("</li>", "\n")
  s = s:gsub("</p>", "\n\n")
  s = s:gsub("</div>", "\n")

  -- Strip whatever tags remain (tables, spans, style attrs, etc.)
  s = s:gsub("<[^>]+>", "")

  -- Collapse runs of blank lines left behind by the above
  s = s:gsub("[ \t]+\n", "\n")
  s = s:gsub("\n\n\n+", "\n\n")

  return vim.trim(s)
end

-- Shared work item cache (id -> {id, title, state, description})
local cache = {
  by_id = {},        -- [id] = work_item
  list = {},         -- ordered list for completion
  ready = false,
  fetching = false,
  pending = {},       -- callbacks waiting on first fetch
  parent_titles = {}, -- [id] = title | false (resolved, not found)
}

-- Resolve titles for parent ids not already cached, then invoke cb().
-- Safe to call with an empty/all-cached list (cb runs immediately, no request).
local function resolve_parents(parent_ids, cb)
  local need = {}
  local seen = {}
  for _, pid in ipairs(parent_ids) do
    if pid and not seen[pid] and cache.parent_titles[pid] == nil then
      seen[pid] = true
      table.insert(need, pid)
    end
  end
  if #need == 0 then
    cb()
    return
  end

  local wiql = string.format(
    "SELECT [System.Id], [System.Title] FROM workitems WHERE [System.Id] IN (%s)",
    table.concat(need, ", ")
  )

  vim.system(
    { "az", "boards", "query", "--detect", "false", "--wiql", wiql, "--output", "json" },
    { text = true },
    vim.schedule_wrap(function(result)
      if result.code == 0 and result.stdout then
        local ok, data = pcall(vim.json.decode, result.stdout)
        if ok and type(data) == "table" then
          for _, entry in ipairs(data) do
            cache.parent_titles[entry.id] = entry.fields["System.Title"] or ""
          end
        end
      end
      -- Anything still unresolved (deleted/inaccessible parent) -> mark
      -- false so we don't refetch it every time.
      for _, pid in ipairs(need) do
        if cache.parent_titles[pid] == nil then
          cache.parent_titles[pid] = false
        end
      end
      cb()
    end)
  )
end

-- Current user's uniqueName (email), used to sort "assigned to me" first.
-- nil = not yet fetched, false = fetch failed.
local me = nil

local function get_me(cb)
  if me ~= nil then
    cb(me)
    return
  end
  vim.system(
    { "az", "account", "show", "--query", "user.name", "--output", "tsv" },
    { text = true },
    vim.schedule_wrap(function(result)
      if result.code == 0 and result.stdout and result.stdout ~= "" then
        me = vim.trim(result.stdout)
      else
        me = false
      end
      cb(me)
    end)
  )
end

local function on_ready(cb)
  if cache.ready then
    cb(cache.list)
    return
  end
  table.insert(cache.pending, cb)
  if cache.fetching then return end
  cache.fetching = true

  local wiql = "SELECT [System.Id], [System.Title], [System.State], [System.Description], [System.AssignedTo], [System.IterationPath], [System.Parent] "
            .. "FROM workitems "
            .. "WHERE [System.TeamProject] = 'BI Team' "
            .. "AND [System.AreaPath] = 'BI Team\\Data Analytics Team' "
            .. "AND [System.State] NOT IN ('Closed', 'Resolved', 'Removed', 'Done') "
            .. "ORDER BY [System.ChangedDate] DESC"

  get_me(function(my_email)
    vim.system(
      { "az", "boards", "query", "--detect", "false", "--wiql", wiql, "--output", "json" },
      { text = true },
      vim.schedule_wrap(function(result)
        if result.code ~= 0 or not result.stdout then
          cache.fetching = false
          cache.ready = true
          for _, cb2 in ipairs(cache.pending) do cb2(cache.list) end
          cache.pending = {}
          return
        end

        local ok, data = pcall(vim.json.decode, result.stdout)
        if not ok or type(data) ~= "table" then
          cache.fetching = false
          cache.ready = true
          for _, cb2 in ipairs(cache.pending) do cb2(cache.list) end
          cache.pending = {}
          return
        end

        local raw_items, parent_ids = {}, {}
        for _, entry in ipairs(data) do
          local assigned = entry.fields["System.AssignedTo"]
          local assigned_email = type(assigned) == "table" and assigned.uniqueName or nil
          local parent_id = entry.fields["System.Parent"]
          local item = {
            id = entry.id,
            title = entry.fields["System.Title"] or "",
            state = entry.fields["System.State"] or "",
            description = html_to_md(entry.fields["System.Description"]),
            assigned_to = assigned_email,
            sprint = sprint_name(entry.fields["System.IterationPath"]),
            parent_id = parent_id,
          }
          table.insert(raw_items, item)
          if parent_id then table.insert(parent_ids, parent_id) end
        end

        resolve_parents(parent_ids, function()
          local mine, others = {}, {}
          for _, item in ipairs(raw_items) do
            if item.parent_id then
              local title = cache.parent_titles[item.parent_id]
              item.parent_title = title ~= false and title or nil
            end
            cache.by_id[item.id] = item
            if my_email and item.assigned_to == my_email then
              table.insert(mine, item)
            else
              table.insert(others, item)
            end
          end
          local items = mine
          for _, item in ipairs(others) do table.insert(items, item) end
          cache.list = items

          cache.fetching = false
          cache.ready = true
          for _, cb2 in ipairs(cache.pending) do cb2(cache.list) end
          cache.pending = {}
        end)
      end)
    )
  end)
end

local function fetch_one(id, cb)
  if cache.by_id[id] then
    cb(cache.by_id[id])
    return
  end

  local wiql = string.format(
    "SELECT [System.Id], [System.Title], [System.State], [System.Description], [System.IterationPath], [System.Parent] FROM workitems WHERE [System.Id] = %d",
    id
  )

  vim.system(
    { "az", "boards", "query", "--detect", "false", "--wiql", wiql, "--output", "json" },
    { text = true },
    vim.schedule_wrap(function(result)
      if result.code == 0 and result.stdout then
        local ok, data = pcall(vim.json.decode, result.stdout)
        if ok and type(data) == "table" and data[1] then
          local entry = data[1]
          local parent_id = entry.fields["System.Parent"]
          local item = {
            id = entry.id,
            title = entry.fields["System.Title"] or "",
            state = entry.fields["System.State"] or "",
            description = html_to_md(entry.fields["System.Description"]),
            sprint = sprint_name(entry.fields["System.IterationPath"]),
            parent_id = parent_id,
          }
          resolve_parents({ parent_id }, function()
            if parent_id then
              local title = cache.parent_titles[parent_id]
              item.parent_title = title ~= false and title or nil
            end
            cache.by_id[item.id] = item
            cb(item)
          end)
          return
        end
      end
      cache.by_id[id] = false
    end)
  )
end

-- ── blink.cmp source methods attached directly to M ──────────────────────────

function M.new()
  return setmetatable({}, { __index = M })
end

function M:get_trigger_characters()
  return { "A", "B" , "#"}
end

function M:get_completions(context, callback)
  if not is_git_buffer() then
    callback({ items = {}, is_incomplete_forward = false, is_incomplete_backward = false })
    return
  end

  local cursor = context.cursor
  local line = context.line
  local before_cursor = line:sub(1, cursor[2])
  
  if not before_cursor:match("AB#%d*$") then
    callback({ items = {}, is_incomplete_forward = false, is_incomplete_backward = false })
    return
  end

  on_ready(function(items)
    local completion_items = {}
    for _, item in ipairs(items) do
      table.insert(completion_items, {
        label = "AB#" .. item.id,
        filterText = "AB#" .. item.id .. " " .. item.title,
        insertText = "AB#" .. item.id,
        kind = vim.lsp.protocol.CompletionItemKind.Reference,
        detail = item.title,
        documentation = {
          kind = "markdown",
          value = string.format(
            "%s**AB#%d** · _%s_%s\n\n%s",
            item.parent_title and ("↑ " .. item.parent_title .. "\n\n") or "",
            item.id,
            item.state,
            item.sprint and (" · " .. item.sprint) or "",
            item.description
          ),
        },
      })
    end
    callback({ items = completion_items, is_incomplete_forward = false, is_incomplete_backward = false })
  end)
end

-- ── Virtual text ──────────────────────────────────────────────────────────────

local vt_ns = vim.api.nvim_create_namespace("azure_boards_vt")

local function render_vt(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  vim.api.nvim_buf_clear_namespace(buf, vt_ns, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local need = {}

  for lnum0, line in ipairs(lines) do
    for id_str in line:gmatch("AB#(%d+)") do
      local id = tonumber(id_str)
      local item = cache.by_id[id]
      if item then
        if item ~= false then
          local sprint_suffix = item.sprint and (" (" .. item.sprint .. ")") or ""
          local opts = {
            virt_text = { { "  [" .. item.state .. "] " .. item.title .. sprint_suffix, "Comment" } },
            virt_text_pos = "eol",
            priority = 100,
          }
          if item.parent_title then
            opts.virt_lines = { { { "  ↑ " .. item.parent_title, "Comment" } } }
            opts.virt_lines_above = true
          end
          vim.api.nvim_buf_set_extmark(buf, vt_ns, lnum0 - 1, 0, opts)
        end
      elseif item == nil then
        need[id] = true
      end
    end
  end

  for id in pairs(need) do
    fetch_one(id, function(_)
      render_vt(buf)
    end)
  end
end

function M.setup_vt()
  if vim.fn.executable("az") == 0 then return end

  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
    callback = function(args)
      if is_git_buffer(args.buf) then render_vt(args.buf) end
    end,
  })

  vim.api.nvim_create_autocmd("CursorHold", {
    callback = function(args)
      if is_git_buffer(args.buf) and vim.api.nvim_get_current_line():find("AB#%d+") then
        render_vt(args.buf)
      end
    end,
  })

  on_ready(function(_)
    local buf = vim.api.nvim_get_current_buf()
    if is_git_buffer(buf) then render_vt(buf) end
  end)
end

return M

