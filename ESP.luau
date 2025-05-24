-- CreateESP Module for Roblox
-- Supports both Drawing and Billboard modes
-- Author: Assistant

local CreateESP = {}
CreateESP.__index = CreateESP

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

-- Local player reference
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ESP Configuration
local ESPConfig = {
    Enabled = true,
    Mode = "Drawing", -- "Drawing" or "Billboard"
    ShowBoxes = true,
    ShowNames = true,
    ShowDistance = true,
    ShowHealth = true,
    ShowTeammates = false,
    MaxDistance = 1000,
    
    -- Drawing mode colors
    BoxColor = Color3.fromRGB(255, 255, 255),
    NameColor = Color3.fromRGB(255, 255, 255),
    HealthColor = Color3.fromRGB(0, 255, 0),
    TeamColor = Color3.fromRGB(0, 255, 0),
    EnemyColor = Color3.fromRGB(255, 0, 0),
    
    -- Drawing properties
    BoxThickness = 1,
    TextSize = 16,
    Transparency = 1,
    
    -- Billboard properties
    BillboardSize = UDim2.new(0, 200, 0, 100),
    StudsOffset = Vector3.new(0, 2, 0)
}

-- Storage for ESP objects
local ESPObjects = {}
local CustomESPObjects = {}

function BillboardESP:Remove()
    if self.BillboardGui then
        self.BillboardGui:Destroy()
    end
end
local ObjectESP = {}
ObjectESP.__index = ObjectESP

function ObjectESP.new(object, name, color)
    local self = setmetatable({}, ObjectESP)
    
    self.Object = object
    self.Name = name or (object.Name ~= "" and object.Name or "Object")
    self.Color = color or Color3.fromRGB(255, 255, 0) -- Default yellow
    self.Enabled = true
    
    -- Determine object type and get position function
    if object:IsA("BasePart") then
        self.GetPosition = function() return object.Position end
        self.GetSize = function() return object.Size end
    elseif object:IsA("Model") and object.PrimaryPart then
        self.GetPosition = function() return object.PrimaryPart.Position end
        self.GetSize = function() return object.PrimaryPart.Size end
    elseif object:IsA("Model") and object:FindFirstChild("HumanoidRootPart") then
        self.GetPosition = function() return object.HumanoidRootPart.Position end
        self.GetSize = function() return object.HumanoidRootPart.Size end
    elseif object:IsA("Model") then
        -- Try to find the first BasePart
        local part = object:FindFirstChildOfClass("BasePart")
        if part then
            self.GetPosition = function() return part.Position end
            self.GetSize = function() return part.Size end
        else
            warn("ObjectESP: Could not find a suitable part in model " .. object.Name)
            return nil
        end
    else
        warn("ObjectESP: Unsupported object type " .. object.ClassName)
        return nil
    end
    
    if ESPConfig.Mode == "Drawing" then
        self:CreateDrawingObjects()
    elseif ESPConfig.Mode == "Billboard" then
        self:CreateBillboardObjects()
    end
    
    return self
end

function ObjectESP:CreateDrawingObjects()
    -- Create drawing objects
    self.Box = Drawing.new("Square")
    self.Box.Visible = false
    self.Box.Filled = false
    self.Box.Thickness = ESPConfig.BoxThickness
    self.Box.Transparency = ESPConfig.Transparency
    self.Box.Color = self.Color
    
    self.NameText = Drawing.new("Text")
    self.NameText.Visible = false
    self.NameText.Center = true
    self.NameText.Outline = true
    self.NameText.Font = 2
    self.NameText.Size = ESPConfig.TextSize
    self.NameText.Color = self.Color
    
    self.DistanceText = Drawing.new("Text")
    self.DistanceText.Visible = false
    self.DistanceText.Center = true
    self.DistanceText.Outline = true
    self.DistanceText.Font = 2
    self.DistanceText.Size = ESPConfig.TextSize - 2
    self.DistanceText.Color = Color3.fromRGB(200, 200, 200)
end

function ObjectESP:CreateBillboardObjects()
    -- Create billboard GUI
    self.BillboardGui = Instance.new("BillboardGui")
    self.BillboardGui.Size = ESPConfig.BillboardSize
    self.BillboardGui.StudsOffset = ESPConfig.StudsOffset
    self.BillboardGui.AlwaysOnTop = true
    
    -- Main frame
    self.Frame = Instance.new("Frame")
    self.Frame.Size = UDim2.new(1, 0, 1, 0)
    self.Frame.BackgroundTransparency = 1
    self.Frame.Parent = self.BillboardGui
    
    -- Name label
    self.NameLabel = Instance.new("TextLabel")
    self.NameLabel.Size = UDim2.new(1, 0, 0.4, 0)
    self.NameLabel.Position = UDim2.new(0, 0, 0, 0)
    self.NameLabel.BackgroundTransparency = 1
    self.NameLabel.Text = self.Name
    self.NameLabel.TextColor3 = self.Color
    self.NameLabel.TextScaled = true
    self.NameLabel.TextStrokeTransparency = 0
    self.NameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    self.NameLabel.Font = Enum.Font.GothamBold
    self.NameLabel.Parent = self.Frame
    
    -- Distance label
    self.DistanceLabel = Instance.new("TextLabel")
    self.DistanceLabel.Size = UDim2.new(1, 0, 0.3, 0)
    self.DistanceLabel.Position = UDim2.new(0, 0, 0.4, 0)
    self.DistanceLabel.BackgroundTransparency = 1
    self.DistanceLabel.Text = "0m"
    self.DistanceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    self.DistanceLabel.TextScaled = true
    self.DistanceLabel.TextStrokeTransparency = 0
    self.DistanceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    self.DistanceLabel.Font = Enum.Font.Gotham
    self.DistanceLabel.Parent = self.Frame
end

function ObjectESP:Update()
    if not self.Object or not self.Object.Parent or not self.Enabled then
        if not self.Enabled then
            self:SetVisible(false)
        else
            self:Remove()
        end
        return
    end
    
    local position = self.GetPosition()
    if not position then
        self:SetVisible(false)
        return
    end
    
    -- Check distance
    local distance = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and 
                     (LocalPlayer.Character.HumanoidRootPart.Position - position).Magnitude) or math.huge
    
    if distance > ESPConfig.MaxDistance then
        self:SetVisible(false)
        return
    end
    
    if ESPConfig.Mode == "Drawing" then
        self:UpdateDrawing(position, distance)
    elseif ESPConfig.Mode == "Billboard" then
        self:UpdateBillboard(position, distance)
    end
end

function ObjectESP:UpdateDrawing(position, distance)
    -- Get screen position
    local screenPosition, onScreen = Camera:WorldToViewportPoint(position)
    
    if not onScreen then
        self:SetVisible(false)
        return
    end
    
    -- Calculate box dimensions based on object size
    local objectSize = self.GetSize()
    local sizeY = math.max(objectSize.Y, objectSize.X, objectSize.Z)
    local boxHeight = math.max(40, sizeY * 50 / distance)
    local boxWidth = boxHeight * 0.8
    
    -- Update box
    if ESPConfig.ShowBoxes then
        self.Box.Size = Vector2.new(boxWidth, boxHeight)
        self.Box.Position = Vector2.new(screenPosition.X - boxWidth/2, screenPosition.Y - boxHeight/2)
        self.Box.Visible = true
    else
        self.Box.Visible = false
    end
    
    -- Update name
    if ESPConfig.ShowNames then
        self.NameText.Text = self.Name
        self.NameText.Position = Vector2.new(screenPosition.X, screenPosition.Y - boxHeight/2 - 20)
        self.NameText.Visible = true
    else
        self.NameText.Visible = false
    end
    
    -- Update distance
    if ESPConfig.ShowDistance then
        self.DistanceText.Text = string.format("%.0fm", distance)
        self.DistanceText.Position = Vector2.new(screenPosition.X, screenPosition.Y + boxHeight/2 + 5)
        self.DistanceText.Visible = true
    else
        self.DistanceText.Visible = false
    end
end

function ObjectESP:UpdateBillboard(position, distance)
    -- Attach to object
    local targetPart = self.Object:IsA("BasePart") and self.Object or 
                      (self.Object:IsA("Model") and (self.Object.PrimaryPart or self.Object:FindFirstChildOfClass("BasePart")))
    
    if targetPart and self.BillboardGui.Parent ~= targetPart then
        self.BillboardGui.Parent = targetPart
    end
    
    if not targetPart then
        self.BillboardGui.Enabled = false
        return
    end
    
    self.BillboardGui.Enabled = true
    
    -- Update distance
    if ESPConfig.ShowDistance then
        self.DistanceLabel.Text = string.format("%.0fm", distance)
        self.DistanceLabel.Visible = true
    else
        self.DistanceLabel.Visible = false
    end
    
    -- Update name visibility
    self.NameLabel.Visible = ESPConfig.ShowNames
end

function ObjectESP:SetVisible(visible)
    if ESPConfig.Mode == "Drawing" then
        if self.Box then self.Box.Visible = visible and ESPConfig.ShowBoxes and self.Enabled end
        if self.NameText then self.NameText.Visible = visible and ESPConfig.ShowNames and self.Enabled end
        if self.DistanceText then self.DistanceText.Visible = visible and ESPConfig.ShowDistance and self.Enabled end
    elseif ESPConfig.Mode == "Billboard" then
        if self.BillboardGui then self.BillboardGui.Enabled = visible and self.Enabled end
    end
end

function ObjectESP:Remove()
    if ESPConfig.Mode == "Drawing" then
        if self.Box then self.Box:Remove() end
        if self.NameText then self.NameText:Remove() end
        if self.DistanceText then self.DistanceText:Remove() end
    elseif ESPConfig.Mode == "Billboard" then
        if self.BillboardGui then self.BillboardGui:Destroy() end
    end
end

function ObjectESP:SetColor(color)
    self.Color = color
    if ESPConfig.Mode == "Drawing" then
        if self.Box then self.Box.Color = color end
        if self.NameText then self.NameText.Color = color end
    elseif ESPConfig.Mode == "Billboard" then
        if self.NameLabel then self.NameLabel.TextColor3 = color end
    end
end

function ObjectESP:Toggle()
    self.Enabled = not self.Enabled
    if not self.Enabled then
        self:SetVisible(false)
    end
end

function ObjectESP:SetEnabled(enabled)
    self.Enabled = enabled
    if not self.Enabled then
        self:SetVisible(false)
    end
end
local DrawingESP = {}
DrawingESP.__index = DrawingESP

function DrawingESP.new(player)
    local self = setmetatable({}, DrawingESP)
    
    self.Player = player
    self.Enabled = true
    
    -- Create drawing objects
    self.Box = Drawing.new("Square")
    self.Box.Visible = false
    self.Box.Filled = false
    self.Box.Thickness = ESPConfig.BoxThickness
    self.Box.Transparency = ESPConfig.Transparency
    
    self.NameText = Drawing.new("Text")
    self.NameText.Visible = false
    self.NameText.Center = true
    self.NameText.Outline = true
    self.NameText.Font = 2
    self.NameText.Size = ESPConfig.TextSize
    
    self.DistanceText = Drawing.new("Text")
    self.DistanceText.Visible = false
    self.DistanceText.Center = true
    self.DistanceText.Outline = true
    self.DistanceText.Font = 2
    self.DistanceText.Size = ESPConfig.TextSize - 2
    
    self.HealthBar = Drawing.new("Square")
    self.HealthBar.Visible = false
    self.HealthBar.Filled = true
    self.HealthBar.Thickness = 1
    
    self.HealthBarOutline = Drawing.new("Square")
    self.HealthBarOutline.Visible = false
    self.HealthBarOutline.Filled = false
    self.HealthBarOutline.Thickness = 1
    self.HealthBarOutline.Color = Color3.fromRGB(0, 0, 0)
    
    return self
end

function DrawingESP:Update()
    if not self.Player or not self.Player.Parent or not self.Enabled then
        if not self.Enabled then
            self:SetVisible(false)
        else
            self:Remove()
        end
        return
    end
    
    local character = self.Player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        self:SetVisible(false)
        return
    end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then
        self:SetVisible(false)
        return
    end
    
    local rootPart = character.HumanoidRootPart
    local head = character:FindFirstChild("Head")
    
    -- Check distance
    local distance = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and 
                     (LocalPlayer.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude) or math.huge
    
    if distance > ESPConfig.MaxDistance then
        self:SetVisible(false)
        return
    end
    
    -- Check team
    if not ESPConfig.ShowTeammates and self.Player.Team == LocalPlayer.Team and self.Player ~= LocalPlayer then
        self:SetVisible(false)
        return
    end
    
    -- Get screen position
    local rootPosition, rootOnScreen = Camera:WorldToViewportPoint(rootPart.Position)
    local headPosition = head and Camera:WorldToViewportPoint(head.Position + Vector3.new(0, head.Size.Y/2, 0))
    
    if not rootOnScreen then
        self:SetVisible(false)
        return
    end
    
    -- Calculate box dimensions
    local topY = headPosition and headPosition.Y or rootPosition.Y - 20
    local bottomY = rootPosition.Y + 20
    local boxHeight = math.abs(topY - bottomY)
    local boxWidth = boxHeight * 0.6
    
    -- Update box
    if ESPConfig.ShowBoxes then
        self.Box.Size = Vector2.new(boxWidth, boxHeight)
        self.Box.Position = Vector2.new(rootPosition.X - boxWidth/2, topY)
        self.Box.Color = self:GetColor()
        self.Box.Visible = true
    else
        self.Box.Visible = false
    end
    
    -- Update name
    if ESPConfig.ShowNames then
        self.NameText.Text = self.Player.Name
        self.NameText.Position = Vector2.new(rootPosition.X, topY - 20)
        self.NameText.Color = self:GetColor()
        self.NameText.Visible = true
    else
        self.NameText.Visible = false
    end
    
    -- Update distance
    if ESPConfig.ShowDistance then
        self.DistanceText.Text = string.format("%.0fm", distance)
        self.DistanceText.Position = Vector2.new(rootPosition.X, bottomY + 5)
        self.DistanceText.Color = Color3.fromRGB(200, 200, 200)
        self.DistanceText.Visible = true
    else
        self.DistanceText.Visible = false
    end
    
    -- Update health bar
    if ESPConfig.ShowHealth then
        local healthPercent = humanoid.Health / humanoid.MaxHealth
        local barHeight = boxHeight * 0.8
        local barWidth = 4
        
        -- Health bar background
        self.HealthBarOutline.Size = Vector2.new(barWidth + 2, barHeight + 2)
        self.HealthBarOutline.Position = Vector2.new(rootPosition.X - boxWidth/2 - barWidth - 4, topY + (boxHeight - barHeight)/2 - 1)
        self.HealthBarOutline.Visible = true
        
        -- Health bar
        self.HealthBar.Size = Vector2.new(barWidth, barHeight * healthPercent)
        self.HealthBar.Position = Vector2.new(rootPosition.X - boxWidth/2 - barWidth - 3, topY + (boxHeight - barHeight)/2 + barHeight * (1 - healthPercent))
        self.HealthBar.Color = Color3.fromRGB(
            255 * (1 - healthPercent),
            255 * healthPercent,
            0
        )
        self.HealthBar.Visible = true
    else
        self.HealthBar.Visible = false
        self.HealthBarOutline.Visible = false
    end
end

function DrawingESP:GetColor()
    if self.Player.Team and LocalPlayer.Team and self.Player.Team == LocalPlayer.Team then
        return ESPConfig.TeamColor
    else
        return ESPConfig.EnemyColor
    end
end

function DrawingESP:SetVisible(visible)
    if self.Box then self.Box.Visible = visible and ESPConfig.ShowBoxes and self.Enabled end
    if self.NameText then self.NameText.Visible = visible and ESPConfig.ShowNames and self.Enabled end
    if self.DistanceText then self.DistanceText.Visible = visible and ESPConfig.ShowDistance and self.Enabled end
    if self.HealthBar then self.HealthBar.Visible = visible and ESPConfig.ShowHealth and self.Enabled end
    if self.HealthBarOutline then self.HealthBarOutline.Visible = visible and ESPConfig.ShowHealth and self.Enabled end
end

function DrawingESP:SetColor(color)
    self.Color = color
    if self.Box then self.Box.Color = color end
    if self.NameText then self.NameText.Color = color end
end

function DrawingESP:Toggle()
    self.Enabled = not self.Enabled
    if not self.Enabled then
        self:SetVisible(false)
    end
end

function DrawingESP:SetEnabled(enabled)
    self.Enabled = enabled
    if not self.Enabled then
        self:SetVisible(false)
    end
end

-- Billboard ESP Class
local BillboardESP = {}
BillboardESP.__index = BillboardESP

function BillboardESP.new(player)
    local self = setmetatable({}, BillboardESP)
    
    self.Player = player
    self.Enabled = true
    
    -- Create billboard GUI
    self.BillboardGui = Instance.new("BillboardGui")
    self.BillboardGui.Size = ESPConfig.BillboardSize
    self.BillboardGui.StudsOffset = ESPConfig.StudsOffset
    self.BillboardGui.AlwaysOnTop = true
    
    -- Main frame
    self.Frame = Instance.new("Frame")
    self.Frame.Size = UDim2.new(1, 0, 1, 0)
    self.Frame.BackgroundTransparency = 1
    self.Frame.Parent = self.BillboardGui
    
    -- Name label
    self.NameLabel = Instance.new("TextLabel")
    self.NameLabel.Size = UDim2.new(1, 0, 0.3, 0)
    self.NameLabel.Position = UDim2.new(0, 0, 0, 0)
    self.NameLabel.BackgroundTransparency = 1
    self.NameLabel.Text = player.Name
    self.NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.NameLabel.TextScaled = true
    self.NameLabel.TextStrokeTransparency = 0
    self.NameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    self.NameLabel.Font = Enum.Font.GothamBold
    self.NameLabel.Parent = self.Frame
    
    -- Distance label
    self.DistanceLabel = Instance.new("TextLabel")
    self.DistanceLabel.Size = UDim2.new(1, 0, 0.25, 0)
    self.DistanceLabel.Position = UDim2.new(0, 0, 0.3, 0)
    self.DistanceLabel.BackgroundTransparency = 1
    self.DistanceLabel.Text = "0m"
    self.DistanceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    self.DistanceLabel.TextScaled = true
    self.DistanceLabel.TextStrokeTransparency = 0
    self.DistanceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    self.DistanceLabel.Font = Enum.Font.Gotham
    self.DistanceLabel.Parent = self.Frame
    
    -- Health bar frame
    self.HealthFrame = Instance.new("Frame")
    self.HealthFrame.Size = UDim2.new(0.8, 0, 0.15, 0)
    self.HealthFrame.Position = UDim2.new(0.1, 0, 0.6, 0)
    self.HealthFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    self.HealthFrame.BorderSizePixel = 1
    self.HealthFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
    self.HealthFrame.Parent = self.Frame
    
    -- Health bar
    self.HealthBar = Instance.new("Frame")
    self.HealthBar.Size = UDim2.new(1, 0, 1, 0)
    self.HealthBar.Position = UDim2.new(0, 0, 0, 0)
    self.HealthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    self.HealthBar.BorderSizePixel = 0
    self.HealthBar.Parent = self.HealthFrame
    
    -- Health text
    self.HealthText = Instance.new("TextLabel")
    self.HealthText.Size = UDim2.new(1, 0, 0.2, 0)
    self.HealthText.Position = UDim2.new(0, 0, 0.8, 0)
    self.HealthText.BackgroundTransparency = 1
    self.HealthText.Text = "100/100"
    self.HealthText.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.HealthText.TextScaled = true
    self.HealthText.TextStrokeTransparency = 0
    self.HealthText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    self.HealthText.Font = Enum.Font.Gotham
    self.HealthText.Parent = self.Frame
    
    return self
end

function BillboardESP:Update()
    if not self.Player or not self.Player.Parent or not self.Enabled then
        if not self.Enabled then
            self.BillboardGui.Enabled = false
        else
            self:Remove()
        end
        return
    end
    
    local character = self.Player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        self.BillboardGui.Enabled = false
        return
    end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then
        self.BillboardGui.Enabled = false
        return
    end
    
    local rootPart = character.HumanoidRootPart
    
    -- Check distance
    local distance = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and 
                     (LocalPlayer.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude) or math.huge
    
    if distance > ESPConfig.MaxDistance then
        self.BillboardGui.Enabled = false
        return
    end
    
    -- Check team
    if not ESPConfig.ShowTeammates and self.Player.Team == LocalPlayer.Team and self.Player ~= LocalPlayer then
        self.BillboardGui.Enabled = false
        return
    end
    
    -- Attach to character
    if self.BillboardGui.Parent ~= rootPart then
        self.BillboardGui.Parent = rootPart
    end
    
    self.BillboardGui.Enabled = true
    
    -- Update colors based on team
    local color = self:GetColor()
    self.NameLabel.TextColor3 = color
    
    -- Update distance
    if ESPConfig.ShowDistance then
        self.DistanceLabel.Text = string.format("%.0fm", distance)
        self.DistanceLabel.Visible = true
    else
        self.DistanceLabel.Visible = false
    end
    
    -- Update health
    if ESPConfig.ShowHealth then
        local healthPercent = humanoid.Health / humanoid.MaxHealth
        self.HealthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
        self.HealthBar.BackgroundColor3 = Color3.fromRGB(
            255 * (1 - healthPercent),
            255 * healthPercent,
            0
        )
        self.HealthText.Text = string.format("%.0f/%.0f", humanoid.Health, humanoid.MaxHealth)
        self.HealthFrame.Visible = true
        self.HealthText.Visible = true
    else
        self.HealthFrame.Visible = false
        self.HealthText.Visible = false
    end
    
    -- Update name visibility
    self.NameLabel.Visible = ESPConfig.ShowNames
end

function BillboardESP:GetColor()
    if self.Player.Team and LocalPlayer.Team and self.Player.Team == LocalPlayer.Team then
        return ESPConfig.TeamColor
    else
        return ESPConfig.EnemyColor
    end
end

function DrawingESP:Remove()
    self.Box:Remove()
    self.NameText:Remove()
    self.DistanceText:Remove()
    self.HealthBar:Remove()
    self.HealthBarOutline:Remove()
end

function BillboardESP:SetColor(color)
    self.Color = color
    if self.NameLabel then self.NameLabel.TextColor3 = color end
end

function BillboardESP:Toggle()
    self.Enabled = not self.Enabled
    if not self.Enabled then
        self:SetVisible(false)
    end
end

function BillboardESP:SetEnabled(enabled)
    self.Enabled = enabled
    if not self.Enabled then
        self:SetVisible(false)
    end
end

function BillboardESP:SetVisible(visible)
    if self.BillboardGui then
        self.BillboardGui.Enabled = visible and self.Enabled
    end
end

-- Main ESP Functions
function CreateESP.AddPlayer(player)
    if player == LocalPlayer then return end
    if ESPObjects[player] then return end
    
    local espObject
    if ESPConfig.Mode == "Drawing" then
        espObject = DrawingESP.new(player)
    elseif ESPConfig.Mode == "Billboard" then
        espObject = BillboardESP.new(player)
    end
    
    ESPObjects[player] = espObject
end

function CreateESP.RemovePlayer(player)
    local espObject = ESPObjects[player]
    if espObject then
        espObject:Remove()
        ESPObjects[player] = nil
    end
end

-- Custom Object ESP Functions
function CreateESP.AddObject(object, name, color)
    if typeof(object) == "table" then
        -- Handle table of objects
        local espObjects = {}
        for i, obj in pairs(object) do
            if typeof(obj) == "Instance" then
                local objName = name and (name .. "_" .. i) or nil
                local espObj = CreateESP.AddObject(obj, objName, color)
                if espObj then
                    table.insert(espObjects, espObj)
                end
            end
        end
        return espObjects
    end
    
    if typeof(object) ~= "Instance" then
        warn("CreateESP.AddObject: Expected Instance or table of Instances")
        return nil
    end
    
    if CustomESPObjects[object] then 
        warn("CreateESP.AddObject: Object already has ESP")
        return CustomESPObjects[object]
    end
    
    local espObject = ObjectESP.new(object, name, color)
    if espObject then
        CustomESPObjects[object] = espObject
        print("Added ESP for object:", object.Name)
        return espObject
    end
    
    return nil
end

function CreateESP.RemoveObject(object)
    if typeof(object) == "table" then
        -- Handle table of objects
        for _, obj in pairs(object) do
            if typeof(obj) == "Instance" then
                CreateESP.RemoveObject(obj)
            end
        end
        return
    end
    
    local espObject = CustomESPObjects[object]
    if espObject then
        espObject:Remove()
        CustomESPObjects[object] = nil
        print("Removed ESP for object:", object.Name)
    end
end

function CreateESP.AddObjectsByName(name, parent, color)
    parent = parent or Workspace
    local objects = {}
    local espObjects = {}
    
    local function findObjects(container)
        for _, child in pairs(container:GetChildren()) do
            if child.Name == name then
                table.insert(objects, child)
            end
            findObjects(child)
        end
    end
    
    findObjects(parent)
    
    if #objects > 0 then
        for i, obj in pairs(objects) do
            local espObj = CreateESP.AddObject(obj, name .. "_" .. i, color)
            if espObj then
                table.insert(espObjects, espObj)
            end
        end
        print("Added ESP for", #objects, "objects named:", name)
    else
        warn("No objects found with name:", name)
    end
    
    return espObjects
end

function CreateESP.AddObjectsByClass(className, parent, color)
    parent = parent or Workspace
    local objects = {}
    local espObjects = {}
    
    local function findObjects(container)
        for _, child in pairs(container:GetChildren()) do
            if child:IsA(className) then
                table.insert(objects, child)
            end
            findObjects(child)
        end
    end
    
    findObjects(parent)
    
    if #objects > 0 then
        for i, obj in pairs(objects) do
            local espObj = CreateESP.AddObject(obj, className .. "_" .. i, color)
            if espObj then
                table.insert(espObjects, espObj)
            end
        end
        print("Added ESP for", #objects, "objects of class:", className)
    else
        warn("No objects found with class:", className)
    end
    
    return espObjects
end

function CreateESP.ClearCustomObjects()
    for object, espObject in pairs(CustomESPObjects) do
        espObject:Remove()
    end
    CustomESPObjects = {}
    print("Cleared all custom ESP objects")
end

function CreateESP.UpdateAll()
    if not ESPConfig.Enabled then return end
    
    -- Update player ESP
    for player, espObject in pairs(ESPObjects) do
        if player and player.Parent then
            espObject:Update()
        else
            CreateESP.RemovePlayer(player)
        end
    end
    
    -- Update custom object ESP
    for object, espObject in pairs(CustomESPObjects) do
        if object and object.Parent then
            espObject:Update()
        else
            CreateESP.RemoveObject(object)
        end
    end
end

function CreateESP.Toggle()
    ESPConfig.Enabled = not ESPConfig.Enabled
    
    if not ESPConfig.Enabled then
        -- Hide player ESP
        for _, espObject in pairs(ESPObjects) do
            if ESPConfig.Mode == "Drawing" then
                espObject:SetVisible(false)
            elseif ESPConfig.Mode == "Billboard" then
                espObject.BillboardGui.Enabled = false
            end
        end
        
        -- Hide custom object ESP
        for _, espObject in pairs(CustomESPObjects) do
            espObject:SetVisible(false)
        end
    end
end

function CreateESP.SetMode(mode)
    if mode ~= "Drawing" and mode ~= "Billboard" then return end
    
    -- Remove all current ESP objects
    for player, _ in pairs(ESPObjects) do
        CreateESP.RemovePlayer(player)
    end
    
    for object, _ in pairs(CustomESPObjects) do
        CreateESP.RemoveObject(object)
    end
    
    -- Store custom objects to re-add them
    local customObjectsToReAdd = {}
    for object, espObject in pairs(CustomESPObjects) do
        customObjectsToReAdd[object] = {
            name = espObject.Name,
            color = espObject.Color
        }
    end
    
    -- Set new mode
    ESPConfig.Mode = mode
    
    -- Re-add all players
    for _, player in pairs(Players:GetPlayers()) do
        CreateESP.AddPlayer(player)
    end
    
    -- Re-add custom objects
    for object, data in pairs(customObjectsToReAdd) do
        if object and object.Parent then
            CreateESP.AddObject(object, data.name, data.color)
        end
    end
end

function CreateESP.GetConfig()
    return ESPConfig
end

function CreateESP.SetConfig(config)
    for key, value in pairs(config) do
        if ESPConfig[key] ~= nil then
            ESPConfig[key] = value
        end
    end
end

-- Initialize ESP
function CreateESP.Init()
    -- Add existing players
    for _, player in pairs(Players:GetPlayers()) do
        CreateESP.AddPlayer(player)
    end
    
    -- Connect player events
    Players.PlayerAdded:Connect(CreateESP.AddPlayer)
    Players.PlayerRemoving:Connect(CreateESP.RemovePlayer)
    
    -- Update loop
    RunService.Heartbeat:Connect(CreateESP.UpdateAll)
    
    print("CreateESP Module Loaded!")
    print("Current Mode:", ESPConfig.Mode)
    print("Use CreateESP.Toggle() to toggle ESP")
    print("Use CreateESP.SetMode('Drawing') or CreateESP.SetMode('Billboard') to change modes")
    print("Use CreateESP.AddObject(object, name, color) to add custom objects")
    print("Use CreateESP.AddObjectsByName(name, parent, color) to add objects by name")
    print("Use CreateESP.AddObjectsByClass(className, parent, color) to add objects by class")
end

-- Auto-initialize
CreateESP.Init()

return CreateESP
