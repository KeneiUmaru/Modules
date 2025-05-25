-- ESP Module System with Config Management
local ESPModule = {}

-- Services
local workspace = game:GetService("Workspace")
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local player = players.LocalPlayer
local camera = workspace.CurrentCamera

-- Default Settings
local DEFAULT_SETTINGS = {
    Box_Enabled = true,
    Box_Color = Color3.fromRGB(255, 0, 0),
    Box_Thickness = 2,
    Box_Transparency = 1,
    
    Tracers = true,
    Tracer_Color = Color3.fromRGB(255, 255, 255),
    Tracer_Thickness = 2,
    Tracer_Transparency = 1,
    
    HealthBar_Enabled = true,

    Shifter_Enabled = true,
    Shifter_Color = Color3.fromRGB(0, 255, 0),
    
    Autothickness = true,
    Team_Check = false,
    
    red = Color3.fromRGB(240, 20, 20),
    green = Color3.fromRGB(90, 215, 25),
    black = Color3.fromRGB(0, 0, 0)
}

-- Global ESP Configuration Manager
local ESPConfig = {
    instances = {},
    globalSettings = DEFAULT_SETTINGS
}

ESPModule.Config = ESPConfig

-- Utility Functions
local function Lerp(a, b, t)
    return a + (b - a) * t
end

local function NewLine(thickness, color)
    local line = Drawing.new("Line")
    line.Visible = false
    line.From = Vector2.new(0, 0)
    line.To = Vector2.new(0, 0)
    line.Color = color or DEFAULT_SETTINGS.Box_Color
    line.Thickness = thickness or DEFAULT_SETTINGS.Box_Thickness
    line.Transparency = 1
    return line
end

-- ESP Class
local ESP = {}
ESP.__index = ESP

function ESP.new(targetPlayer, color, settings)
    local self = setmetatable({}, ESP)
    
    self.target = targetPlayer
    self.color = color or DEFAULT_SETTINGS.Box_Color
    self.settings = settings or DEFAULT_SETTINGS
    self.visible = true
    self.connection = nil
    
    -- Create drawing objects
    self.lines = {}
    for i = 1, 12 do
        self.lines["line" .. i] = NewLine(self.settings.Box_Thickness, self.color)
    end
    
    self.lines.Tracer = NewLine(self.settings.Tracer_Thickness, self.settings.Tracer_Color)
    self.lines.healthbar = NewLine(3, self.settings.black)
    self.lines.greenhealth = NewLine(1.5, self.settings.black)
    
    -- Shifter quad
    self.shifter = Drawing.new("Quad")
    self.shifter.Visible = false
    self.shifter.Color = self.settings.Shifter_Color
    self.shifter.Thickness = self.settings.Box_Thickness
    self.shifter.Filled = false
    self.shifter.Transparency = self.settings.Box_Transparency
    
    -- Animation variables
    self.debounce = 0
    self.shifteroffset = 0
    
    -- Register with config manager
    ESPConfig.instances[self] = true
    
    return self
end

function ESP:UpdateSettings(newSettings)
    -- Merge new settings with existing ones
    for key, value in pairs(newSettings) do
        self.settings[key] = value
    end
    
    -- Update drawing objects with new settings
    for i = 1, 12 do
        self.lines["line" .. i].Thickness = self.settings.Box_Thickness
        self.lines["line" .. i].Color = self.settings.Box_Color
    end
    
    self.lines.Tracer.Thickness = self.settings.Tracer_Thickness
    self.lines.Tracer.Color = self.settings.Tracer_Color
    self.lines.Tracer.Transparency = self.settings.Tracer_Transparency
    
    self.shifter.Color = self.settings.Shifter_Color
    self.shifter.Thickness = self.settings.Box_Thickness
    self.shifter.Transparency = self.settings.Box_Transparency
end

function ESP:UpdateESP()
    if not self.target or 
       not self.target:FindFirstChild("Humanoid") or
       not self.target:FindFirstChild("HumanoidRootPart") or
       not self.target:FindFirstChild("Head") or
       self.target.Name == player.Name or
       self.target.Humanoid.Health <= 0 then
        self:Hide()
        return
    end
    
    local pos, vis = camera:WorldToViewportPoint(self.target.HumanoidRootPart.Position)
    local head = camera:WorldToViewportPoint(self.target.Head.Position)
    local DistanceY = math.clamp((Vector2.new(head.X, head.Y) - Vector2.new(pos.X, pos.Y)).magnitude, 2, math.huge)
    
    if not vis then
        self:Hide()
        return
    end
    
    local Scale = self.target.Head.Size.Y/2
    local Size = Vector3.new(2, 3, 1.5) * (Scale * 2)
    
    -- Calculate 3D box corners
    local corners = self:Calculate3DBox(Size)
    
    -- Update box lines
    self:UpdateBoxLines(corners)
    
    -- Update tracer
    if self.settings.Tracers then
        self:UpdateTracer(Size)
    end
    
    -- Update health bar
    self:UpdateHealthBar(pos, DistanceY)
    
    -- Update team colors
    if self.settings.Team_Check then
        self:UpdateTeamColors()
    end
    
    -- Update shifter animation
    self:UpdateShifter(Size)
    
    -- Update thickness based on distance
    if self.settings.Autothickness then
        self:UpdateAutoThickness()
    end
    
    -- Show all elements
    self:Show()
end

function ESP:Calculate3DBox(Size)
    local rootPart = self.target.HumanoidRootPart
    
    return {
        Top1 = camera:WorldToViewportPoint((rootPart.CFrame * CFrame.new(-Size.X, Size.Y, -Size.Z)).p),
        Top2 = camera:WorldToViewportPoint((rootPart.CFrame * CFrame.new(-Size.X, Size.Y, Size.Z)).p),
        Top3 = camera:WorldToViewportPoint((rootPart.CFrame * CFrame.new(Size.X, Size.Y, Size.Z)).p),
        Top4 = camera:WorldToViewportPoint((rootPart.CFrame * CFrame.new(Size.X, Size.Y, -Size.Z)).p),
        
        Bottom1 = camera:WorldToViewportPoint((rootPart.CFrame * CFrame.new(-Size.X, -Size.Y, -Size.Z)).p),
        Bottom2 = camera:WorldToViewportPoint((rootPart.CFrame * CFrame.new(-Size.X, -Size.Y, Size.Z)).p),
        Bottom3 = camera:WorldToViewportPoint((rootPart.CFrame * CFrame.new(Size.X, -Size.Y, Size.Z)).p),
        Bottom4 = camera:WorldToViewportPoint((rootPart.CFrame * CFrame.new(Size.X, -Size.Y, -Size.Z)).p)
    }
end

function ESP:UpdateBoxLines(corners)
    -- Top face
    self.lines.line1.From = Vector2.new(corners.Top1.X, corners.Top1.Y)
    self.lines.line1.To = Vector2.new(corners.Top2.X, corners.Top2.Y)
    
    self.lines.line2.From = Vector2.new(corners.Top2.X, corners.Top2.Y)
    self.lines.line2.To = Vector2.new(corners.Top3.X, corners.Top3.Y)
    
    self.lines.line3.From = Vector2.new(corners.Top3.X, corners.Top3.Y)
    self.lines.line3.To = Vector2.new(corners.Top4.X, corners.Top4.Y)
    
    self.lines.line4.From = Vector2.new(corners.Top4.X, corners.Top4.Y)
    self.lines.line4.To = Vector2.new(corners.Top1.X, corners.Top1.Y)
    
    -- Bottom face
    self.lines.line5.From = Vector2.new(corners.Bottom1.X, corners.Bottom1.Y)
    self.lines.line5.To = Vector2.new(corners.Bottom2.X, corners.Bottom2.Y)
    
    self.lines.line6.From = Vector2.new(corners.Bottom2.X, corners.Bottom2.Y)
    self.lines.line6.To = Vector2.new(corners.Bottom3.X, corners.Bottom3.Y)
    
    self.lines.line7.From = Vector2.new(corners.Bottom3.X, corners.Bottom3.Y)
    self.lines.line7.To = Vector2.new(corners.Bottom4.X, corners.Bottom4.Y)
    
    self.lines.line8.From = Vector2.new(corners.Bottom4.X, corners.Bottom4.Y)
    self.lines.line8.To = Vector2.new(corners.Bottom1.X, corners.Bottom1.Y)
    
    -- Vertical edges
    self.lines.line9.From = Vector2.new(corners.Bottom1.X, corners.Bottom1.Y)
    self.lines.line9.To = Vector2.new(corners.Top1.X, corners.Top1.Y)
    
    self.lines.line10.From = Vector2.new(corners.Bottom2.X, corners.Bottom2.Y)
    self.lines.line10.To = Vector2.new(corners.Top2.X, corners.Top2.Y)
    
    self.lines.line11.From = Vector2.new(corners.Bottom3.X, corners.Bottom3.Y)
    self.lines.line11.To = Vector2.new(corners.Top3.X, corners.Top3.Y)
    
    self.lines.line12.From = Vector2.new(corners.Bottom4.X, corners.Bottom4.Y)
    self.lines.line12.To = Vector2.new(corners.Top4.X, corners.Top4.Y)
end

function ESP:UpdateTracer(Size)
    local trace = camera:WorldToViewportPoint((self.target.HumanoidRootPart.CFrame * CFrame.new(0, -Size.Y, 0)).p)
    self.lines.Tracer.From = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y)
    self.lines.Tracer.To = Vector2.new(trace.X, trace.Y)
end

function ESP:UpdateHealthBar(pos, DistanceY)
    local humanoid = self.target.Humanoid
    local d = (Vector2.new(pos.X - DistanceY, pos.Y - DistanceY*2) - Vector2.new(pos.X - DistanceY, pos.Y + DistanceY*2)).magnitude 
    local healthoffset = humanoid.Health/humanoid.MaxHealth * d

    self.lines.healthbar.Visible = self.settings.HealthBar_Enabled
    self.lines.greenhealth.Visible = self.settings.HealthBar_Enabled
    
    self.lines.greenhealth.From = Vector2.new(pos.X - DistanceY - 4, pos.Y + DistanceY*2)
    self.lines.greenhealth.To = Vector2.new(pos.X - DistanceY - 4, pos.Y + DistanceY*2 - healthoffset)
    
    self.lines.healthbar.From = Vector2.new(pos.X - DistanceY - 4, pos.Y + DistanceY*2)
    self.lines.healthbar.To = Vector2.new(pos.X - DistanceY - 4, pos.Y - DistanceY*2)
    
    local health = Color3.fromRGB(255, 102, 0)
    local losshealth = Color3.fromRGB(255, 0, 0)
    self.lines.greenhealth.Color = losshealth:lerp(health, humanoid.Health/humanoid.MaxHealth)
end

function ESP:UpdateTeamColors()
    local color = (self.target.TeamColor == player.TeamColor) and self.settings.green or self.settings.red
    local shifterColor = (self.target.TeamColor == player.TeamColor) and self.settings.red or self.settings.green
    
    for _, line in pairs(self.lines) do
        line.Color = color
    end
    self.shifter.Color = shifterColor
end

function ESP:UpdateShifter(Size)
    if self.debounce == 0 then
        self.debounce = 1
        task.spawn(function()
            -- Animation sequence
            for i = 0, Size.Y, 0.1 do
                self.shifteroffset = Lerp(self.shifteroffset, i, 0.5)
                task.wait()
            end
            for i = self.shifteroffset, 0, -0.1 do
                self.shifteroffset = Lerp(self.shifteroffset, i, 0.5)
                task.wait()
            end
            for i = 0, -Size.Y, -0.1 do
                self.shifteroffset = Lerp(self.shifteroffset, i, 0.5)
                task.wait()
            end
            for i = self.shifteroffset, 0, 0.1 do
                self.shifteroffset = Lerp(self.shifteroffset, i, 0.5)
                task.wait()
            end
            self.debounce = 0
        end)
    end
    
    -- Update shifter quad position
    local rootPart = self.target.HumanoidRootPart
    local shifter1 = camera:WorldToViewportPoint((rootPart.CFrame * CFrame.new(-Size.X, self.shifteroffset, -Size.Z)).p)
    local shifter2 = camera:WorldToViewportPoint((rootPart.CFrame * CFrame.new(-Size.X, self.shifteroffset, Size.Z)).p)
    local shifter3 = camera:WorldToViewportPoint((rootPart.CFrame * CFrame.new(Size.X, self.shifteroffset, Size.Z)).p)
    local shifter4 = camera:WorldToViewportPoint((rootPart.CFrame * CFrame.new(Size.X, self.shifteroffset, -Size.Z)).p)
    
    self.shifter.PointA = Vector2.new(shifter1.X, shifter1.Y)
    self.shifter.PointB = Vector2.new(shifter2.X, shifter2.Y)
    self.shifter.PointC = Vector2.new(shifter3.X, shifter3.Y)
    self.shifter.PointD = Vector2.new(shifter4.X, shifter4.Y)
end

function ESP:UpdateAutoThickness()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local distance = (player.Character.HumanoidRootPart.Position - self.target.HumanoidRootPart.Position).magnitude
    local value = math.clamp(1/distance*100, 0.1, 4)
    
    for _, line in pairs(self.lines) do
        line.Thickness = value
    end
    self.shifter.Thickness = value
end

function ESP:Show()
    if not self.visible then return end
    
    for name, line in pairs(self.lines) do
        if name ~= "Tracer" or self.settings.Tracers then
            line.Visible = self.settings.Tracers
        end
    end
    self.lines.Tracer.Visible = self.settings.Tracers
    self.shifter.Visible = self.settings.Shifter_Enabled
end

function ESP:Hide()
    for _, line in pairs(self.lines) do
        line.Visible = false
    end
    self.shifter.Visible = false
end

function ESP:SetVisible(visible)
    self.visible = visible
    if visible then
        self:Show()
    else
        self:Hide()
    end
end

function ESP:SetColor(color)
    self.color = color
    if not self.settings.Team_Check then
        for _, line in pairs(self.lines) do
            line.Color = color
        end
    end
end

function ESP:Clear()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
    
    for _, line in pairs(self.lines) do
        line:Remove()
    end
    self.shifter:Remove()
    
    -- Unregister from config manager
    ESPConfig.instances[self] = nil
    
    self.lines = {}
    self.shifter = nil
end

function ESP:Start()
    if self.connection then return end
    
    self.connection = runService.RenderStepped:Connect(function()
        self:UpdateESP()
    end)
end

function ESP:Stop()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
    self:Hide()
end

-- Global Config Management Functions
function ESPConfig:UpdateAll(newConfig)
    -- Update global settings
    for key, value in pairs(newConfig) do
        self.globalSettings[key] = value
    end
    
    -- Update all ESP instances
    for espInstance, _ in pairs(self.instances) do
        espInstance:UpdateSettings(newConfig)
    end
    
    print("Updated " .. self:CountInstances() .. " ESP instances with new configuration")
end

function ESPConfig:CountInstances()
    local count = 0
    for _, _ in pairs(self.instances) do
        count = count + 1
    end
    return count
end

function ESPConfig:GetGlobalSettings()
    return self.globalSettings
end

function ESPConfig:SetGlobalBox(enabled)
    self:UpdateAll({Box_Enabled = enabled})
end

function ESPConfig:SetGlobalHealthbar(enabled)
    self:UpdateAll({HealthBar_Enabled = enabled})
end

function ESPConfig:SetGlobalShifter(enabled)
    self:UpdateAll({Shifter = enabled})
end

function ESPConfig:SetGlobalTracers(enabled)
    self:UpdateAll({Tracers = enabled})
end

function ESPConfig:SetGlobalThickness(thickness)
    self:UpdateAll({
        Box_Thickness = thickness,
        Tracer_Thickness = thickness
    })
end

function ESPConfig:SetGlobalColors(boxColor, tracerColor, shifterColor)
    self:UpdateAll({
        Box_Color = boxColor or self.globalSettings.Box_Color,
        Tracer_Color = tracerColor or self.globalSettings.Tracer_Color,
        Shifter_Color = shifterColor or self.globalSettings.Shifter_Color
    })
end

function ESPConfig:SetGlobalTeamCheck(enabled)
    self:UpdateAll({Team_Check = enabled})
end

function ESPConfig:SetGlobalAutoThickness(enabled)
    self:UpdateAll({Autothickness = enabled})
end

-- Main ESP Module Functions
function ESPModule.AddESP(targetPath, color, settings)
    local targetPlayer
    
    -- Handle different path types
    if typeof(targetPath) == "Instance" then
        targetPlayer = targetPath
    elseif typeof(targetPath) == "string" then
        targetPlayer = players:FindFirstChild(targetPath)
        if not targetPlayer then
            warn("Player not found: " .. targetPath)
            return nil
        end
    else
        warn("Invalid target path. Expected Player instance or player name string.")
        return nil
    end
    
    -- Merge with global settings
    local finalSettings = {}
    for key, value in pairs(ESPConfig.globalSettings) do
        finalSettings[key] = value
    end
    if settings then
        for key, value in pairs(settings) do
            finalSettings[key] = value
        end
    end
    
    -- Create ESP instance
    local esp = ESP.new(targetPlayer, color, finalSettings)
    esp:Start()
    
    -- Return control functions
    return {
        Clear = function()
            esp:Clear()
        end,
        
        Visible = function(visible)
            esp:SetVisible(visible)
        end,
        
        SetColor = function(newColor)
            esp:SetColor(newColor)
        end,
        
        Stop = function()
            esp:Stop()
        end,
        
        Start = function()
            esp:Start()
        end,
        
        UpdateSettings = function(newSettings)
            esp:UpdateSettings(newSettings)
        end
    }
end

-- Batch ESP management
function ESPModule.AddESPToAll(path, color, settings, excludeSelf)
    local espInstances = {}
    local LIST = path:GetChildren() or players:GetPlayers()
    print("Adding ESP to " .. #LIST .. " players")
    for _, plr in pairs(LIST) do
        if excludeSelf == false or plr ~= player.Character then
            local esp = ESPModule.AddESP(plr, color, settings)
            if esp then
                espInstances[plr.Name] = esp
            end
        end
    end
    
    -- Handle new players
    local newPlayerConnection = path.ChildAdded:Connect(function(newPlayer)
        if excludeSelf == false or newPlayer ~= player then
            espInstances[newPlayer.Name] = ESPModule.AddESP(newPlayer, color, settings)
        end
    end)
    
    -- Handle leaving players
    local playerRemovedConnection = path.ChildRemoved:Connect(function(leavingPlayer)
        if espInstances[leavingPlayer.Name] then
            espInstances[leavingPlayer.Name].Clear()
            espInstances[leavingPlayer.Name] = nil
        end
    end)
    
    return {
        ClearAll = function()
            for _, esp in pairs(espInstances) do
                esp.Clear()
            end
            espInstances = {}
            newPlayerConnection:Disconnect()
            playerRemovedConnection:Disconnect()
        end,
        
        SetVisible = function(visible)
            for _, esp in pairs(espInstances) do
                esp.Visible(visible)
            end
        end,
        
        SetColor = function(newColor)
            for _, esp in pairs(espInstances) do
                esp.SetColor(newColor)
            end
        end,

        Start = function()
            for _, esp in pairs(espInstances) do
                esp.Start()
            end
        end,
        
        GetESP = function(playerName)
            return espInstances[playerName]
        end,
        
        UpdateAllSettings = function(newSettings)
            for _, esp in pairs(espInstances) do
                esp.UpdateSettings(newSettings)
            end
        end
    }
end

return ESPModule
