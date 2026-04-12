# Mining App

The mining app contains turtle-focused excavation utilities.

## Programs

- `hole.lua`: mines a square vertical shaft layer by layer and unloads into a chest above the start position

## Installation

Install the whole app:

```lua
/updater.lua mining
```

That installs the programs to:

```text
disk/apps/mining/
```

## Hole Turtle

Run:

```lua
disk/apps/mining/hole.lua small [depth]
disk/apps/mining/hole.lua medium [depth]
disk/apps/mining/hole.lua big [depth]
```

Examples:

```lua
disk/apps/mining/hole.lua small 30
disk/apps/mining/hole.lua medium 16
disk/apps/mining/hole.lua big
```

Setup:
- place a chest directly above the turtle's starting position
- `small` and `medium`: start in the center of the hole
- `big`: start on the north-west block of the middle 2x2 relative to the turtle's initial facing

Behavior:
- refuels only with charcoal or charcoal-block variants it recognizes
- discards configured junk blocks instead of storing them
- returns to the start column to unload when the inventory fills
