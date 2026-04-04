-- sorter_config.lua
local chests = {
  input = "minecraft:chest_11",

  stone_top    = "minecraft:chest_17",
  stone_mid    = "minecraft:chest_16",
  stone_bottom = "minecraft:chest_6",

  wood_top     = "minecraft:chest_18",
  wood_mid     = "minecraft:chest_19",
  wood_bottom  = "minecraft:chest_15",

  farm_top     = "minecraft:chest_20",
  farm_mid     = "minecraft:chest_21",
  farm_bottom  = "minecraft:chest_14",

  ores_top     = "minecraft:chest_22",
  ores_mid     = "minecraft:chest_23",
  ores_bottom  = "minecraft:chest_13",

  misc_top     = "minecraft:chest_24",
  misc_mid     = "minecraft:chest_25",
  misc_bottom  = "minecraft:chest_12",

  armory_top    = "minecraft:chest_26",
  armory_mid    = "minecraft:chest_27",
  armory_bottom = "minecraft:chest_28",
}

monitors = {
  dashboard = "monitor_1",

  stone = "monitor_2",
  wood  = "monitor_7",
  farm  = "monitor_8",
  ores  = "monitor_9",
  misc  = "monitor_10",
  armory = "monitor_11",
}

return {
  chests = chests,
  monitors = monitors,

  categories = {
    { key = "stone", label = "Stone", chests = {
      chests.stone_top, chests.stone_mid, chests.stone_bottom
    }},

    { key = "wood", label = "Wood", chests = {
      chests.wood_top, chests.wood_mid, chests.wood_bottom
    }},

    { key = "farm", label = "Farm", chests = {
      chests.farm_top, chests.farm_mid, chests.farm_bottom
    }},

    { key = "ores", label = "Ores", chests = {
      chests.ores_top, chests.ores_mid, chests.ores_bottom
    }},

    { key = "misc", label = "Misc", chests = {
      chests.misc_top, chests.misc_mid, chests.misc_bottom
    }},
    { key = "armory", label = "Armory", chests = {
      chests.armory_top, chests.armory_mid, chests.armory_bottom
    }},
  }
}