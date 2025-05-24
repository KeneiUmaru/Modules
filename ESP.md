# MainESP Module Documentation

A comprehensive ESP (Extra Sensory Perception) system for Roblox that provides visual overlays for players and objects with both Drawing API and Billboard GUI support.

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [API Reference](#api-reference)
- [Examples](#examples)
- [Advanced Usage](#advanced-usage)
- [Performance Considerations](#performance-considerations)

## Overview

MainESP is a clean, controller-based ESP system that allows you to:

- Display visual overlays for players and objects
- Show player information (names, health, distance, team status)
- Support both Drawing API and Billboard GUI rendering modes
- Manage multiple ESP controllers simultaneously
- Customize colors, visibility options, and display settings

### Key Features

- **Dual Rendering Modes**: Drawing API (lightweight) and Billboard GUI (rich UI)
- **Player ESP**: Health bars, names, distance, team colors
- **Object ESP**: Customizable overlays for any Roblox instance
- **Performance Optimized**: Rate limiting and distance culling
- **Team Support**: Different colors for teammates vs enemies
- **Flexible Configuration**: Global and per-controller settings

## Installation

```lua
-- Place the MainESP module in ServerStorage or ReplicatedStorage
local MainESP = require(game.ServerStorage.MainESP) -- Adjust path as needed
```

## Quick Start

### Basic Player ESP

```lua
local MainESP = require(path.to.MainESP)

-- Create ESP for all players
local playerESP = MainESP.Players({
    ShowBoxes = true,
    ShowNames = true,
    ShowHealth = true,
    ShowDistance = true
})
```

### Basic Object ESP

```lua
-- ESP for specific objects
local chests = MainESP.ByName("Chest", workspace, {
    ShowBoxes = true,
    ShowNames = true,
    Color = Color3.fromRGB(255, 215, 0) -- Gold color
})
```

## Configuration

### Global Configuration

The `GlobalConfig` table controls system-wide settings:

```lua
local config = MainESP.GetConfig()
print(config.MaxDistance) -- Current max distance

-- Update global settings
MainESP.SetConfig({
    MaxDistance = 500,
    UpdateRate = 30,
    BoxThickness = 2
})
```

#### Global Config Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `Enabled` | boolean | `true` | Master enable/disable switch |
| `Mode` | string | `"Drawing"` | Rendering mode: `"Drawing"` or `"Billboard"` |
| `MaxDistance` | number | `1000` | Maximum render distance (studs) |
| `UpdateRate` | number | `60` | FPS limit for ESP updates |
| `BoxThickness` | number | `1` | Thickness of Drawing API boxes |
| `TextSize` | number | `16` | Base text size |
| `Transparency` | number | `1` | Drawing transparency (0-1) |
| `BillboardSize` | UDim2 | `UDim2.new(0, 200, 0, 100)` | Billboard GUI size |
| `StudsOffset` | Vector3 | `Vector3.new(0, 2, 0)` | Billboard vertical offset |

### Controller Options

Each ESP controller can be customized with these options:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ShowBoxes` | boolean | `true` | Display bounding boxes |
| `ShowNames` | boolean | `true` | Display object/player names |
| `ShowDistance` | boolean | `true` | Display distance text |
| `ShowHealth` | boolean | `true` | Display health bars (players only) |
| `ShowTeammates` | boolean | `true` | Show teammates or hide them |
| `Color` | Color3 | `Color3.fromRGB(255, 255, 255)` | Primary ESP color |
| `Name` | string | `nil` | Custom name override |

## API Reference

### Core Functions

#### `MainESP.new(targets, options)`

Creates a new ESP controller for specified targets.

**Parameters:**
- `targets` (Instance|table): Single instance or array of instances to track
- `options` (table, optional): Controller configuration options

**Returns:** ESPController object

```lua
-- Single target
local esp = MainESP.new(workspace.Part, { Color = Color3.new(1, 0, 0) })

-- Multiple targets
local esp = MainESP.new({workspace.Part1, workspace.Part2}, { ShowBoxes = true })
```

#### `MainESP.Players(options)`

Creates ESP for all players except the local player.

**Parameters:**
- `options` (table, optional): Controller configuration options

**Returns:** ESPController object

```lua
local playerESP = MainESP.Players({
    ShowHealth = true,
    ShowTeammates = false -- Hide teammates
})
```

#### `MainESP.ByName(name, parent, options)`

Creates ESP for all objects with a specific name.

**Parameters:**
- `name` (string): Object name to search for
- `parent` (Instance, optional): Container to search in (defaults to Workspace)
- `options` (table, optional): Controller configuration options

**Returns:** ESPController object

```lua
-- Find all objects named "Treasure"
local treasureESP = MainESP.ByName("Treasure", workspace, {
    Color = Color3.fromRGB(255, 215, 0),
    Name = "💰 Treasure"
})
```

#### `MainESP.ByClass(className, parent, options)`

Creates ESP for all objects of a specific class.

**Parameters:**
- `className` (string): Roblox class name to search for
- `parent` (Instance, optional): Container to search in (defaults to Workspace)
- `options` (table, optional): Controller configuration options

**Returns:** ESPController object

```lua
-- ESP for all parts
local partESP = MainESP.ByClass("Part", workspace, {
    ShowBoxes = true,
    Color = Color3.fromRGB(0, 255, 255)
})
```

### System Control Functions

#### `MainESP.SetMode(mode)`

Changes the global rendering mode.

**Parameters:**
- `mode` (string): `"Drawing"` or `"Billboard"`

```lua
-- Switch to Billboard mode for richer UI
MainESP.SetMode("Billboard")

-- Switch back to Drawing mode for performance
MainESP.SetMode("Drawing")
```

#### `MainESP.Toggle()`

Toggles the global ESP system on/off.

```lua
-- Toggle ESP visibility
MainESP.Toggle()
```

#### `MainESP.GetConfig()`

Returns the current global configuration.

**Returns:** Table containing current global settings

#### `MainESP.SetConfig(config)`

Updates global configuration settings.

**Parameters:**
- `config` (table): Configuration values to update

### ESPController Methods

#### `controller:AddTarget(target)`

Adds a new target to the controller.

**Parameters:**
- `target` (Instance): Object to add ESP to

```lua
local esp = MainESP.new({})
esp:AddTarget(workspace.NewPart)
```

#### `controller:RemoveTarget(target)`

Removes a target from the controller.

**Parameters:**
- `target` (Instance): Object to remove ESP from

```lua
esp:RemoveTarget(workspace.OldPart)
```

#### `controller:SetColor(color)`

Changes the color for all ESP objects in this controller.

**Parameters:**
- `color` (Color3): New color to apply

```lua
esp:SetColor(Color3.fromRGB(255, 0, 0)) -- Red
```

#### `controller:SetVisible(visible)`

Sets visibility for all ESP objects in this controller.

**Parameters:**
- `visible` (boolean): Visibility state

```lua
esp:SetVisible(false) -- Hide all ESP
esp:SetVisible(true)  -- Show all ESP
```

#### `controller:Clear()`

Removes all targets and cleans up the controller.

```lua
esp:Clear() -- Remove all ESP objects
```

## Examples

### Advanced Player ESP

```lua
local MainESP = require(game.ServerStorage.MainESP)

-- Comprehensive player ESP
local playerESP = MainESP.Players({
    ShowBoxes = true,
    ShowNames = true,
    ShowHealth = true,
    ShowDistance = true,
    ShowTeammates = false -- Only show enemies
})

-- Toggle ESP with a keybind
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.P then
        playerESP:SetVisible(not playerESP.Enabled)
    end
end)
```

### Multi-Object ESP System

```lua
-- Different ESP for different object types
local treasures = MainESP.ByName("Treasure", workspace, {
    Color = Color3.fromRGB(255, 215, 0), -- Gold
    Name = "💰 Treasure",
    ShowDistance = true
})

local enemies = MainESP.ByName("Enemy", workspace, {
    Color = Color3.fromRGB(255, 0, 0), -- Red
    ShowHealth = true,
    ShowBoxes = true
})

local collectibles = MainESP.ByClass("Part", workspace.Collectibles, {
    Color = Color3.fromRGB(0, 255, 255), -- Cyan
    ShowNames = false,
    ShowBoxes = true
})

-- Control all ESP systems
local function toggleAllESP()
    treasures:SetVisible(not treasures.Enabled)
    enemies:SetVisible(not enemies.Enabled)
    collectibles:SetVisible(not collectibles.Enabled)
end
```

### Dynamic ESP Management

```lua
local MainESP = require(game.ServerStorage.MainESP)
local espControllers = {}

-- Create ESP when new parts are added
workspace.ChildAdded:Connect(function(child)
    if child.Name == "SpecialPart" then
        local esp = MainESP.new(child, {
            Color = Color3.fromRGB(255, 0, 255),
            Name = "⭐ Special"
        })
        espControllers[child] = esp
    end
end)

-- Clean up ESP when parts are removed
workspace.ChildRemoved:Connect(function(child)
    if espControllers[child] then
        espControllers[child]:Clear()
        espControllers[child] = nil
    end
end)
```

### Performance-Optimized Setup

```lua
-- Configure for better performance
MainESP.SetConfig({
    MaxDistance = 200,  -- Shorter render distance
    UpdateRate = 30,    -- Lower update rate
    Mode = "Drawing"    -- Use Drawing API (faster)
})

-- Selective player ESP (only enemies)
local enemyESP = MainESP.Players({
    ShowTeammates = false,
    ShowHealth = false,     -- Disable expensive health bars
    ShowDistance = false,   -- Disable distance calculations
    ShowBoxes = true,
    ShowNames = true
})
```

## Advanced Usage

### Custom Color Schemes

```lua
-- Define custom colors based on distance
local function getDistanceColor(distance)
    if distance < 50 then
        return Color3.fromRGB(255, 0, 0) -- Red (close)
    elseif distance < 150 then
        return Color3.fromRGB(255, 255, 0) -- Yellow (medium)
    else
        return Color3.fromRGB(0, 255, 0) -- Green (far)
    end
end

-- Note: You would need to modify the module to support dynamic coloring
```

### Filtering Players

```lua
-- Custom player filtering
local function createFilteredPlayerESP()
    local players = {}
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer and 
           player.Team ~= game.Players.LocalPlayer.Team then
            table.insert(players, player)
        end
    end
    
    return MainESP.new(players, {
        ShowBoxes = true,
        ShowNames = true,
        ShowHealth = true
    })
end

local filteredESP = createFilteredPlayerESP()
```

### Integration with Other Systems

```lua
-- Integration with a game's inventory system
local function createLootESP()
    local lootController = MainESP.new({}, {
        Color = Color3.fromRGB(255, 215, 0),
        ShowDistance = true
    })
    
    -- Add loot as it spawns
    game.ReplicatedStorage.LootSpawned.OnClientEvent:Connect(function(lootPart)
        lootController:AddTarget(lootPart)
    end)
    
    -- Remove loot when collected
    game.ReplicatedStorage.LootCollected.OnClientEvent:Connect(function(lootPart)
        lootController:RemoveTarget(lootPart)
    end)
    
    return lootController
end
```

## Performance Considerations

### Optimization Tips

1. **Use Drawing Mode for Better Performance**
   ```lua
   MainESP.SetMode("Drawing") -- Faster than Billboard
   ```

2. **Limit Update Rate**
   ```lua
   MainESP.SetConfig({ UpdateRate = 30 }) -- 30 FPS instead of 60
   ```

3. **Reduce Max Distance**
   ```lua
   MainESP.SetConfig({ MaxDistance = 200 }) -- Shorter render distance
   ```

4. **Disable Expensive Features**
   ```lua
   local lightweightESP = MainESP.Players({
       ShowHealth = false,   -- Health calculations are expensive
       ShowDistance = false  -- Distance calculations every frame
   })
   ```

### Memory Management

- ESP objects are automatically cleaned up when targets are removed
- Use `controller:Clear()` to manually clean up controllers
- Remove unused controllers to prevent memory leaks

### Frame Rate Impact

The ESP system updates every frame by default. For better performance:

- Lower the `UpdateRate` in global config
- Use fewer ESP controllers
- Disable features you don't need
- Consider using the Drawing API mode for large numbers of objects

## Troubleshooting

### Common Issues

1. **ESP Not Showing**
   - Check if `GlobalConfig.Enabled` is true
   - Verify targets are within `MaxDistance`
   - Ensure targets still exist and have valid parents

2. **Performance Issues**
   - Reduce `UpdateRate` and `MaxDistance`
   - Switch to Drawing mode
   - Disable expensive features like health bars

3. **Billboard Mode Not Working**
   - Ensure targets have valid parts to attach to
   - Check that Billboard GUIs are being created properly

4. **Colors Not Updating**
   - Use `controller:SetColor()` to change colors
   - Check that color values are valid Color3 objects
