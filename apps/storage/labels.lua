local CFG = dofile("/sorter_config.lua")

if not CFG.monitors then
  error("Missing CFG.monitors in /sorter_config.lua")
end

if not CFG.categories or type(CFG.categories) ~= "table" then
  error("Missing CFG.categories in /sorter_config.lua")
end

local function centerX(termObj, text)
  local w, _ = termObj.getSize()
  return math.max(1, math.floor((w - #text) / 2) + 1)
end

local function abbreviateLabel(text, maxLen)
  if #text <= maxLen then
    return text
  end

  local words = {}
  for word in text:gmatch("%S+") do
    words[#words + 1] = word
  end

  if #words > 1 then
    local acronym = {}
    for _, word in ipairs(words) do
      acronym[#acronym + 1] = word:sub(1, 1)
    end
    local short = table.concat(acronym)
    if #short <= maxLen then
      return short
    end
  end

  return text:sub(1, maxLen)
end

local function chooseLabelLayout(monitorName, text)
  local candidates = { 5, 4, 3, 2, 1.5, 1 }

  for _, scale in ipairs(candidates) do
    local monitor = peripheral.wrap(monitorName)
    if monitor then
      monitor.setTextScale(scale)
      local w = select(1, monitor.getSize())
      if w >= 1 then
        local displayText = abbreviateLabel(text, w)
        if #displayText <= w then
          return scale, displayText
        end
      end
    end
  end

  local monitor = peripheral.wrap(monitorName)
  monitor.setTextScale(1)
  local w = select(1, monitor.getSize())
  return 1, abbreviateLabel(text, math.max(1, w))
end

local function drawLabel(monitorName, text)
  local m = peripheral.wrap(monitorName)
  if not m then
    error("Monitor not found: " .. tostring(monitorName))
  end

  local scale, displayText = chooseLabelLayout(monitorName, text)
  m.setTextScale(scale)
  m.setBackgroundColor(colors.black)
  m.setTextColor(colors.white)
  m.clear()

  local _, h = m.getSize()
  local y = math.max(1, math.floor((h - 1) / 2) + 1)

  m.setCursorPos(centerX(m, displayText), y)
  m.write(displayText)
end

for _, category in ipairs(CFG.categories) do
  if type(category) == "table" and category.key and category.label then
    local monitorName = CFG.monitors[category.key]
    if monitorName then
      drawLabel(monitorName, string.upper(tostring(category.label)))
    end
  end
end
