-- hole.lua
-- Usage:
--   hole small [depth]
--   hole medium [depth]
--   hole big [depth]
--
-- Examples:
--   hole small 30
--   hole medium 16
--   hole big
--
-- Setup:
--   - Place a chest directly ABOVE the turtle's starting position.
--   - small / medium: start in the center of the hole.
--   - big (20x20): start on the north-west block of the middle 2x2
--     relative to the turtle's starting facing.
--
-- Notes:
--   - The turtle only refuels with charcoal / charcoal blocks.
--   - Junk blocks are discarded, not stored.
--   - When inventory fills, it returns to start, unloads to chest, then resumes.

local args = { ... }

local PRESETS = {
  small = 3,
  medium = 9,
  big = 16,
}

local TRASH_ITEMS = {
  ["minecraft:cobblestone"] = true,
  ["minecraft:dirt"] = true,
  ["minecraft:andesite"] = true,
  ["minecraft:granite"] = true,
  ["minecraft:gravel"] = true,
}

local size_name = args[1] and string.lower(args[1]) or "small"
local size = PRESETS[size_name]
if not size then
  print("Usage: hole <small|medium|big> [depth]")
  return
end

local max_depth = nil
if args[2] ~= nil then
  max_depth = tonumber(args[2])
  if not max_depth or max_depth < 1 then
    print("Depth must be a positive number.")
    return
  end
  max_depth = math.floor(max_depth)
end

-- 0=north, 1=east, 2=south, 3=west
local dir = 0

-- Position relative to starting column
local x, z, y = 0, 0, 0

-- Keep some reserve so the turtle can return, unload, and go back
local MIN_BUFFER = 32

local function selected()
  return turtle.getSelectedSlot()
end

local function fuelLevel()
  return turtle.getFuelLevel()
end

local function at_start_column()
  return x == 0 and z == 0
end

local function is_trash_name(name)
  return name ~= nil and TRASH_ITEMS[name] == true
end

local function is_allowed_fuel_name(name)
  if not name then return false end
  if name == "minecraft:charcoal" then return true end

  -- Best-effort support for modded charcoal blocks.
  -- If your pack uses a weird item ID, add a specific check here.
  local lower = string.lower(name)
  if string.find(lower, "charcoal_block", 1, true) then return true end
  if string.find(lower, "block_charcoal", 1, true) then return true end

  return false
end

local function get_item_name(slot)
  local detail = turtle.getItemDetail(slot)
  return detail and detail.name or nil
end

local function is_trash_slot(slot)
  return is_trash_name(get_item_name(slot))
end

local function is_allowed_fuel_slot(slot)
  if turtle.getItemCount(slot) == 0 then return false end

  local name = get_item_name(slot)
  if not is_allowed_fuel_name(name) then return false end

  local old = selected()
  turtle.select(slot)
  local ok = turtle.refuel(0)
  turtle.select(old)

  return ok
end

local function has_empty_slot()
  for slot = 1, 16 do
    if turtle.getItemCount(slot) == 0 then
      return true
    end
  end
  return false
end

local function compact_inventory()
  local old = selected()

  for i = 1, 16 do
    if turtle.getItemCount(i) > 0 then
      for j = i + 1, 16 do
        if turtle.getItemCount(j) > 0 then
          turtle.select(j)
          if turtle.compareTo(i) then
            turtle.transferTo(i)
          end
        end
      end
    end
  end

  turtle.select(old)
end

local function reserve_fuel_needed(extra)
  extra = extra or 0
  -- Need enough to get back to center, climb to surface, then return.
  return math.abs(x) + math.abs(z) + (2 * y) + MIN_BUFFER + extra
end

local function ensure_fuel(min_fuel)
  local fuel = fuelLevel()
  if fuel == "unlimited" then return true end
  if fuel >= min_fuel then return true end

  local old = selected()

  for slot = 1, 16 do
    if is_allowed_fuel_slot(slot) then
      turtle.select(slot)

      while turtle.getItemCount(slot) > 0 do
        fuel = fuelLevel()
        if fuel == "unlimited" or fuel >= min_fuel then
          turtle.select(old)
          return true
        end

        local ok = turtle.refuel(1)
        if not ok then break end
      end
    end
  end

  turtle.select(old)
  fuel = fuelLevel()
  return fuel == "unlimited" or fuel >= min_fuel
end

local function free_space_by_burning_fuel()
  local old = selected()

  for slot = 1, 16 do
    if is_allowed_fuel_slot(slot) then
      turtle.select(slot)
      local ok = turtle.refuel(1)
      if ok and has_empty_slot() then
        turtle.select(old)
        return true
      end
    end
  end

  turtle.select(old)
  return has_empty_slot()
end

local function turn_left()
  local ok, err = turtle.turnLeft()
  if not ok then error("turnLeft failed: " .. tostring(err)) end
  dir = (dir + 3) % 4
end

local function turn_right()
  local ok, err = turtle.turnRight()
  if not ok then error("turnRight failed: " .. tostring(err)) end
  dir = (dir + 1) % 4
end

local function face(target)
  local right_turns = (target - dir) % 4
  local left_turns = (dir - target) % 4

  if right_turns <= left_turns then
    for _ = 1, right_turns do turn_right() end
  else
    for _ = 1, left_turns do turn_left() end
  end
end

local function update_forward_position()
  if dir == 0 then
    z = z - 1
  elseif dir == 1 then
    x = x + 1
  elseif dir == 2 then
    z = z + 1
  else
    x = x - 1
  end
end

local function can_purge_trash_here()
  if not at_start_column() then return false end

  if y > 0 then
    return true
  end

  -- At the surface, only drop down if the shaft is open below.
  return not turtle.detectDown()
end

local function purge_trash()
  if not can_purge_trash_here() then return end

  local old = selected()

  for slot = 1, 16 do
    if is_trash_slot(slot) then
      turtle.select(slot)
      if y > 0 then
        turtle.dropUp()
      else
        turtle.dropDown()
      end
    end
  end

  turtle.select(old)
end

local function chest_above_start()
  local ok, data = turtle.inspectUp()
  if not ok or not data or not data.name then return false end

  local name = string.lower(data.name)
  return string.find(name, "chest", 1, true)
      or string.find(name, "barrel", 1, true)
      or string.find(name, "shulker_box", 1, true)
end

local function move_forward_travel()
  while true do
    if not ensure_fuel(1) then
      error("Out of fuel and no allowed fuel was found.")
    end

    local ok, err = turtle.forward()
    if ok then
      update_forward_position()
      return
    end

    if err == "Out of fuel" then
      -- retry
    else
      if turtle.detect() then
        local dug, dig_err = turtle.dig()
        if not dug and dig_err and dig_err ~= "Nothing to dig here" then
          error("Forward path blocked: " .. tostring(dig_err))
        end
      else
        turtle.attack()
      end
      sleep(0.2)
    end
  end
end

local function move_up_travel()
  while true do
    if not ensure_fuel(1) then
      error("Out of fuel and no allowed fuel was found.")
    end

    local ok, err = turtle.up()
    if ok then
      y = y - 1
      return
    end

    if err == "Out of fuel" then
      -- retry
    else
      if turtle.detectUp() then
        local dug, dig_err = turtle.digUp()
        if not dug and dig_err and dig_err ~= "Nothing to dig here" then
          error("Upward path blocked: " .. tostring(dig_err))
        end
      else
        turtle.attackUp()
      end
      sleep(0.2)
    end
  end
end

local function move_down_travel()
  while true do
    if not ensure_fuel(1) then
      error("Out of fuel and no allowed fuel was found.")
    end

    local ok, err = turtle.down()
    if ok then
      y = y + 1
      return
    end

    if err == "Out of fuel" then
      -- retry
    else
      if turtle.detectDown() then
        local dug, dig_err = turtle.digDown()
        if not dug and dig_err and dig_err ~= "Nothing to dig here" then
          error("Downward path blocked: " .. tostring(dig_err))
        end
      else
        turtle.attackDown()
      end
      sleep(0.2)
    end
  end
end

local function go_to_travel(tx, tz)
  while x < tx do
    face(1)
    move_forward_travel()
  end
  while x > tx do
    face(3)
    move_forward_travel()
  end
  while z < tz do
    face(2)
    move_forward_travel()
  end
  while z > tz do
    face(0)
    move_forward_travel()
  end
end

local unload_to_chest

local function inventory_maintenance()
  compact_inventory()

  if at_start_column() then
    purge_trash()
    compact_inventory()
  end

  if not has_empty_slot() then
    unload_to_chest()
    compact_inventory()

    if at_start_column() then
      purge_trash()
      compact_inventory()
    end

    if not has_empty_slot() then
      if not free_space_by_burning_fuel() then
        error("Inventory still full after unloading.")
      end
    end
  end
end

local function move_forward_mine()
  while true do
    inventory_maintenance()

    if not ensure_fuel(reserve_fuel_needed(1)) then
      error("Not enough allowed fuel to continue safely.")
    end

    local ok, err = turtle.forward()
    if ok then
      update_forward_position()
      inventory_maintenance()
      return
    end

    if err == "Out of fuel" then
      -- retry
    else
      if turtle.detect() then
        local dug, dig_err = turtle.dig()
        if not dug and dig_err and dig_err ~= "Nothing to dig here" then
          error("Cannot dig forward: " .. tostring(dig_err))
        end
        inventory_maintenance()
      else
        turtle.attack()
      end
      sleep(0.2)
    end
  end
end

local function move_down_mine()
  while true do
    inventory_maintenance()

    if not ensure_fuel(reserve_fuel_needed(1)) then
      return false, "Not enough allowed fuel to continue safely."
    end

    local ok, err = turtle.down()
    if ok then
      y = y + 1
      inventory_maintenance()
      return true
    end

    if err == "Out of fuel" then
      -- retry
    else
      if turtle.detectDown() then
        local dug, dig_err = turtle.digDown()
        if not dug and dig_err and dig_err ~= "Nothing to dig here" then
          return false, dig_err
        end
        inventory_maintenance()
      else
        turtle.attackDown()
      end
      sleep(0.2)
    end
  end
end

local function go_to(tx, tz)
  while x < tx do
    face(1)
    move_forward_mine()
  end
  while x > tx do
    face(3)
    move_forward_mine()
  end
  while z < tz do
    face(2)
    move_forward_mine()
  end
  while z > tz do
    face(0)
    move_forward_mine()
  end
end

function unload_to_chest()
  local saved_x, saved_z, saved_y, saved_dir = x, z, y, dir

  go_to_travel(0, 0)
  face(0)

  while y > 0 do
    move_up_travel()
  end

  if not chest_above_start() then
    error("No chest-like inventory found above the start position.")
  end

  purge_trash()
  compact_inventory()

  local old = selected()

  for slot = 1, 16 do
    if turtle.getItemCount(slot) > 0 then
      local name = get_item_name(slot)
      if not is_trash_name(name) and not is_allowed_fuel_name(name) then
        turtle.select(slot)
        local ok, err = turtle.dropUp()
        if not ok then
          error("Could not unload to chest: " .. tostring(err))
        end
      end
    end
  end

  turtle.select(old)
  compact_inventory()

  if not has_empty_slot() then
    if not free_space_by_burning_fuel() then
      error("Inventory still full after unloading. Too many fuel stacks?")
    end
  end

  while y < saved_y do
    move_down_travel()
  end

  go_to_travel(saved_x, saved_z)
  face(saved_dir)
end

local function get_bounds(n)
  if n % 2 == 1 then
    local half = math.floor(n / 2)
    return -half, half
  else
    local half = n / 2
    return -(half - 1), half
  end
end

local min_coord, max_coord = get_bounds(size)

local function clear_layer()
  go_to(min_coord, min_coord)

  local row = 0
  for current_z = min_coord, max_coord do
    local target_x
    if row % 2 == 0 then
      target_x = max_coord
    else
      target_x = min_coord
    end

    go_to(target_x, current_z)

    if current_z < max_coord then
      go_to(target_x, current_z + 1)
    end

    row = row + 1
  end

  go_to(0, 0)
  face(0)
end

local function mine_one_level()
  local ok, err = move_down_mine()
  if not ok then
    return false, err
  end

  clear_layer()
  return true
end

print("Mode: " .. size_name .. " (" .. size .. "x" .. size .. ")")
if max_depth then
  print("Depth: " .. max_depth)
else
  print("Depth: until blocked")
end
print("Chest: above starting position")
print("Fuel: charcoal + charcoal blocks only")
print("Trash: cobblestone, dirt, andesite, granite, gravel")

local mined = 0

if max_depth then
  for _ = 1, max_depth do
    local ok, err = mine_one_level()
    if not ok then
      print("Stopped at layer " .. mined .. ": " .. tostring(err))
      return
    end

    mined = mined + 1
    print("Finished layer " .. mined)
  end

  print("Done. Total layers mined: " .. mined)
else
  while true do
    local ok, err = mine_one_level()
    if not ok then
      print("Stopped at layer " .. mined .. ": " .. tostring(err))
      return
    end

    mined = mined + 1
    print("Finished layer " .. mined)
  end
end
