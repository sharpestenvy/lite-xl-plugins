-- mod-version:3

local config  = require "core.config"
local command = require "core.command"
local keymap  = require "core.keymap"
local core = require "core"

config.plugins.tabout = config.plugins.tabout or {}
config.plugins.tabout.closing_chars =
  config.plugins.tabout.closing_chars or {
    "]", "}", ")", "'", '"', ":", "=", ">", "<", ".", "`", ";",
  }

local function make_set(list)
  local t = {}
  for _, v in ipairs(list) do t[v] = true end
  return t
end

local function tabout_position(doc, line, col)
  local closing_set = make_set(config.plugins.tabout.closing_chars)
  local line_str = doc.lines[line]
  if not line_str then return nil end

  local ch = line_str:sub(col, col)
  if ch ~= "" and closing_set[ch] then
    return line, col + 1
  end

  local tail = line_str:sub(col)
  local ws = tail:match("^(%s+)%S")
  if ws then
    local next_col = col + #ws
    local nc = line_str:sub(next_col, next_col)
    if nc ~= "" and closing_set[nc] then
      return line, next_col + 1
    end
  end

  return nil
end

command.add("core.docview", {
  ["tabout:tab-out"] = function()
    local dv = core.active_view
    if not dv or not dv.doc then return end
    local doc = dv.doc

    for idx = 1, #doc.selections, 4 do
      local l1, c1, l2, c2 =
        doc.selections[idx],     doc.selections[idx + 1],
        doc.selections[idx + 2], doc.selections[idx + 3]
      if l1 ~= l2 or c1 ~= c2 then
        command.perform "doc:indent"
        return
      end
    end

    local cursor_count = #doc.selections / 4
    local new_pos = {}
    local any_moved = false

    for i = 1, cursor_count do
      local idx = (i - 1) * 4 + 1
      local line, col = doc.selections[idx], doc.selections[idx + 1]
      local nl, nc = tabout_position(doc, line, col)
      if nl then
        any_moved = true
        new_pos[i] = { nl, nc }
      end
    end

    if not any_moved then
      command.perform "doc:indent"
      return
    end

    local first = true
    for i = 1, cursor_count do
      if new_pos[i] then
        local l, c = table.unpack(new_pos[i])
        if first then
          doc:set_selection(l, c, l, c)
          first = false
        else
          if doc.add_selection then
            doc:add_selection(l, c, l, c)
          end
        end
      end
    end
  end,
})

keymap.add { ["tab"] = "tabout:tab-out" }
