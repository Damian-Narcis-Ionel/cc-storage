local CFG = dofile("/sorter_config.lua")

if not CFG.monitors then
  error("Missing CFG.monitors in /sorter_config.lua")
end

local LABELS = {
  stone  = "STONE",
  wood   = "WOOD",
  farm   = "FARM",
  ores   = "ORES",
  misc   = "MISC",
  armory = "ARMORY",
}

local function centerX(termObj, text)
  local w, _ = termObj.getSize()
  return math.max(1, math.floor((w - #text) / 2) + 1)
end

local function drawLabel(monitorName, text)
  local m = peripheral.wrap(monitorName)
  if not m then
    error("Monitor not found: " .. tostring(monitorName))
  end

  m.setTextScale(1)
  m.setBackgroundColor(colors.black)
  m.setTextColor(colors.white)
  m.clear()

  local _, h = m.getSize()
  local y = math.max(1, math.floor((h - 1) / 2) + 1)

  m.setCursorPos(centerX(m, text), y)
  m.write(text)
end

drawLabel(CFG.monitors.stone,  LABELS.stone)
drawLabel(CFG.monitors.wood,   LABELS.wood)
drawLabel(CFG.monitors.farm,   LABELS.farm)
drawLabel(CFG.monitors.ores,   LABELS.ores)
drawLabel(CFG.monitors.misc,   LABELS.misc)
drawLabel(CFG.monitors.armory, LABELS.armory)