local ESPModule = {}
print("KENEI ESP v.0.01a")
local workspace = game:GetService("Workspace")
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local player = players.LocalPlayer
local camera = workspace.CurrentCamera

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
    Text_Enabled = true,
    Text_Color = Color3.fromRGB(255, 255, 255),
    Text_Size = 16,
    Text_Font = 2,

    Shifter_Enabled = true,
    Shifter_Color = Color3.fromRGB(0, 255, 0),
    
    Charms_Enabled = false,
    Charms_Color = Color3.fromRGB(255, 255, 0),
    Charms_OutlineColor = Color3.fromRGB(255, 255, 0255),
    Charms_Thickness = 1,
    
    Autothickness = true,
    Team_Check = false,
    
    red = Color3.fromRGB(240, 20, 20),
    green = Color3.fromRGB(90, 215, 25),
    black = Color3.fromRGB(0, 0, 0)
}

local ESPConfig = {
    instances = {},
    globalSettings = DEFAULT_SETTINGS,
    renderConnection = nil
}

ESPModule.Config = ESPConfig

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

local function NewText(text, size, color)
    local textObj = Drawing.new("Text")
    textObj.Visible = false
    textObj.Text = text or ""
    textObj.Size = size or DEFAULT_SETTINGS.Text_Size
    textObj.Color = color or DEFAULT_SETTINGS.Text_Color
    textObj.Font = DEFAULT_SETTINGS.Text_Font
    textObj.Center = true
    textObj.Outline = true
    textObj.OutlineColor = Color3.fromRGB(0, 0, 0)
    return textObj
end

local ESP = {}
ESP.__index = ESP

function ESP.new(targetObject, color, settings)
    local self = setmetatable({}, ESP)
    
    self.target = targetObject
    self.color = color or DEFAULT_SETTINGS.Box_Color
    self.settings = settings or DEFAULT_SETTINGS
    self.visible = true
    self.lastParent = nil
    self.parentChangeConnection = nil
    self.isObject = not targetObject:FindFirstChild("Humanoid")
    
    self.lines = {}
    for i = 1, 12 do
        self.lines["line" .. i] = NewLine(self.settings.Box_Thickness, self.color)
    end
    
    self.lines.Tracer = NewLine(self.settings.Tracer_Thickness, self.settings.Tracer_Color)
    self.lines.healthbar = NewLine(3, self.settings.black)
    self.lines.greenhealth = NewLine(1.5, self.settings.black)
    
    self.textLabel = NewText(self.target.Name, self.settings.Text_Size, self.settings.Text_Color)
    
    self.shifter = Drawing.new("Quad")
    self.shifter.Visible = false
    self.shifter.Color = self.settings.Shifter_Color
    self.shifter.Thickness = self.settings.Box_Thickness
    self.shifter.Filled = false
    self.shifter.Transparency = self.settings.Box_Transparency
    
    self.highlight = nil
    self.charmsEnabled = false
    
    self:SetupParentDetection()
    
    ESPConfig.instances[self] = true
    
    return self
end

function ESP:SetupParentDetection()
    self.lastParent = self.target.Parent
    
    self.parentChangeConnection = self.target.AncestryChanged:Connect(function()
        local newParent = self.target.Parent
        if newParent ~= self.lastParent then
            if not newParent then
                self:Clear()
                return
            end
            self.lastParent = newParent
        end
    end)
end

function ESP:UpdateSettings(newSettings)
    for key, value in pairs(newSettings) do
        self.settings[key] = value
    end
    
    for i = 1, 12 do
        self.lines["line" .. i].Thickness = self.settings.Box_Thickness
        self.lines["line" .. i].Color = self.settings.Box_Color
        self.lines["line" .. i].Transparency = self.settings.Box_Transparency
    end

    self.lines.Tracer.Thickness = self.settings.Tracer_Thickness
    self.lines.Tracer.Color = self.settings.Tracer_Color
    self.lines.Tracer.Transparency = self.settings.Tracer_Transparency
    
    self.textLabel.Size = self.settings.Text_Size
    self.textLabel.Color = self.settings.Text_Color

    self.shifter.Color = self.settings.Shifter_Color
    self.shifter.Thickness = self.settings.Box_Thickness
    self.shifter.Transparency = self.settings.Box_Transparency
    
    self.highlight.FillColor = self.settings.Charms_Color
    self.highlight.OutlineColor = self.settings.Charms_OutlineColor
    self.highlight.OutlineTransparency = self.settings.Box_Transparency
end

function ESP:IsValidTarget()
    if not self.target or not self.target.Parent then return false end

    if self.isObject then
        return self.target:IsA("BasePart") or self.target:IsA("Model")
    else
        return self.target:FindFirstChild("Humanoid") and
               self.target:FindFirstChild("HumanoidRootPart") and
               self.target:FindFirstChild("Head") and
               self.target.Name ~= player.Name and
               self.target.Humanoid.Health > 0
    end
end

function ESP:GetTargetPosition()
    if not self:IsValidTarget() then return Vector3.zero end

    if self.isObject then
        if self.target:IsA("BasePart") then
            return self.target.Position
        elseif self.target:IsA("Model") then
            if self.target.PrimaryPart then
                return self.target.PrimaryPart.Position
            else
                local cf = self.target:GetBoundingBox()
                return cf.Position
            end
        end
    else
        return self.target:FindFirstChild("HumanoidRootPart").Position
    end

    return Vector3.zero
end

function ESP:GetTargetSize()
    if not self:IsValidTarget() then return Vector3.zero end

    if self.isObject then
        if self.target:IsA("BasePart") then
            return self.target.Size
        elseif self.target:IsA("Model") then
            local _, size = self.target:GetBoundingBox()
            return size
        end
    else
        local scale = self.target.Head.Size.Y / 2
        return Vector3.new(2, 3, 1.5) * (scale * 2)
    end

    return Vector3.new(2, 2, 2)
end

function ESP:UpdateESP()
    if not self:IsValidTarget() then
        self:Hide()
        return
    end
    
    local targetPos = self:GetTargetPosition()
    local pos, vis = camera:WorldToViewportPoint(targetPos)
    
    if not vis then
        self:Hide()
        return
    end
    
    local Size = self:GetTargetSize()
    
    if self.isObject then
        self:UpdateObjectESP(pos, Size)
    else
        local head = camera:WorldToViewportPoint(self.target.Head.Position)
        local DistanceY = math.clamp((Vector2.new(head.X, head.Y) - Vector2.new(pos.X, pos.Y)).magnitude, 2, math.huge)
        
        local corners = self:Calculate3DBox(Size)
        
        if self.settings.Box_Enabled then
            self:UpdateBoxLines(corners)
        end
        
        if self.settings.Tracers then
            self:UpdateTracer(Size)
        end
        
        if self.settings.HealthBar_Enabled then
            self:UpdateHealthBar(pos, DistanceY)
        end
        
        if self.settings.Text_Enabled then
            self:UpdateTextLabel(head)
        end
        
        if self.settings.Team_Check then
            self:UpdateTeamColors()
        end
        
        if self.settings.Shifter_Enabled then
            self:UpdateShifter(Size)
        end
    end
    
    if self.settings.Charms_Enabled then
        self:UpdateCharms(self.target)
    end
    
    if self.settings.Autothickness then
        self:UpdateAutoThickness()
    end
    
    self:Show()
end

function ESP:UpdateObjectESP(pos, Size)
    local corners = self:Calculate3DBoxForObject(Size)
    
    if self.settings.Box_Enabled then
        self:UpdateBoxLines(corners)
    end
    
    if self.settings.Tracers then
        self:UpdateObjectTracer()
    end
    
    if self.settings.Text_Enabled then
        self:UpdateObjectTextLabel(pos)
    end
end

function ESP:Calculate3DBoxForObject(Size)
    local targetPos = self:GetTargetPosition()
    local rootCFrame = CFrame.new(targetPos)
    
    return {
        Top1 = camera:WorldToViewportPoint((rootCFrame * CFrame.new(-Size.X/2, Size.Y/2, -Size.Z/2)).p),
        Top2 = camera:WorldToViewportPoint((rootCFrame * CFrame.new(-Size.X/2, Size.Y/2, Size.Z/2)).p),
        Top3 = camera:WorldToViewportPoint((rootCFrame * CFrame.new(Size.X/2, Size.Y/2, Size.Z/2)).p),
        Top4 = camera:WorldToViewportPoint((rootCFrame * CFrame.new(Size.X/2, Size.Y/2, -Size.Z/2)).p),
        
        Bottom1 = camera:WorldToViewportPoint((rootCFrame * CFrame.new(-Size.X/2, -Size.Y/2, -Size.Z/2)).p),
        Bottom2 = camera:WorldToViewportPoint((rootCFrame * CFrame.new(-Size.X/2, -Size.Y/2, Size.Z/2)).p),
        Bottom3 = camera:WorldToViewportPoint((rootCFrame * CFrame.new(Size.X/2, -Size.Y/2, Size.Z/2)).p),
        Bottom4 = camera:WorldToViewportPoint((rootCFrame * CFrame.new(Size.X/2, -Size.Y/2, -Size.Z/2)).p)
    }
end

function ESP:UpdateObjectTracer()
    local targetPos = self:GetTargetPosition()
    local trace = camera:WorldToViewportPoint(targetPos)
    self.lines.Tracer.From = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y)
    self.lines.Tracer.To = Vector2.new(trace.X, trace.Y)
end

function ESP:UpdateObjectTextLabel(pos)
    self.textLabel.Position = Vector2.new(pos.X, pos.Y - 30)
    
    local distance = player.Character and player.Character:FindFirstChild("HumanoidRootPart") and 
        math.floor((player.Character.HumanoidRootPart.Position - self:GetTargetPosition()).magnitude) or 0
    
    self.textLabel.Text = string.format("%s [%dm]", self.target.Name, distance)
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
    self.lines.line1.From = Vector2.new(corners.Top1.X, corners.Top1.Y)
    self.lines.line1.To = Vector2.new(corners.Top2.X, corners.Top2.Y)
    
    self.lines.line2.From = Vector2.new(corners.Top2.X, corners.Top2.Y)
    self.lines.line2.To = Vector2.new(corners.Top3.X, corners.Top3.Y)
    
    self.lines.line3.From = Vector2.new(corners.Top3.X, corners.Top3.Y)
    self.lines.line3.To = Vector2.new(corners.Top4.X, corners.Top4.Y)
    
    self.lines.line4.From = Vector2.new(corners.Top4.X, corners.Top4.Y)
    self.lines.line4.To = Vector2.new(corners.Top1.X, corners.Top1.Y)
    
    self.lines.line5.From = Vector2.new(corners.Bottom1.X, corners.Bottom1.Y)
    self.lines.line5.To = Vector2.new(corners.Bottom2.X, corners.Bottom2.Y)
    
    self.lines.line6.From = Vector2.new(corners.Bottom2.X, corners.Bottom2.Y)
    self.lines.line6.To = Vector2.new(corners.Bottom3.X, corners.Bottom3.Y)
    
    self.lines.line7.From = Vector2.new(corners.Bottom3.X, corners.Bottom3.Y)
    self.lines.line7.To = Vector2.new(corners.Bottom4.X, corners.Bottom4.Y)
    
    self.lines.line8.From = Vector2.new(corners.Bottom4.X, corners.Bottom4.Y)
    self.lines.line8.To = Vector2.new(corners.Bottom1.X, corners.Bottom1.Y)
    
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
    self.lines.Tracer.Visible = self.settings.Tracers
    self.lines.Tracer.From = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y)
    self.lines.Tracer.To = Vector2.new(trace.X, trace.Y)
end

function ESP:UpdateHealthBar(pos, DistanceY)
    local humanoid = self.target.Humanoid
    local d = (Vector2.new(pos.X - DistanceY, pos.Y - DistanceY*2) - Vector2.new(pos.X - DistanceY, pos.Y + DistanceY*2)).magnitude 
    local healthoffset = humanoid.Health/humanoid.MaxHealth * d

    self.lines.greenhealth.From = Vector2.new(pos.X - DistanceY - 4, pos.Y + DistanceY*2)
    self.lines.greenhealth.To = Vector2.new(pos.X - DistanceY - 4, pos.Y + DistanceY*2 - healthoffset)
    
    self.lines.healthbar.From = Vector2.new(pos.X - DistanceY - 4, pos.Y + DistanceY*2)
    self.lines.healthbar.To = Vector2.new(pos.X - DistanceY - 4, pos.Y - DistanceY*2)

    self.lines.greenhealth.Visible = self.settings.HealthBar_Enabled
    self.lines.healthbar.Visible = self.settings.HealthBar_Enabled

    local health = Color3.fromRGB(94, 255, 0)
    local losshealth = Color3.fromRGB(255, 0, 0)
    self.lines.greenhealth.Color = losshealth:lerp(health, humanoid.Health/humanoid.MaxHealth)
end

function ESP:UpdateTextLabel(head)
    self.textLabel.Position = Vector2.new(head.X, head.Y - 30)
    
    local distance = player.Character and player.Character:FindFirstChild("HumanoidRootPart") and 
        math.floor((player.Character.HumanoidRootPart.Position - self.target.HumanoidRootPart.Position).magnitude) or 0
    
    self.textLabel.Text = string.format("%s [%dm]", self.target.Name, distance)
end

function ESP:UpdateTeamColors()
    local isTeammate = self.target.TeamColor == player.TeamColor
    local color = isTeammate and self.settings.green or self.settings.red
    local shifterColor = isTeammate and self.settings.red or self.settings.green
    
    for _, line in pairs(self.lines) do
        if line ~= self.lines.greenhealth and line ~= self.lines.healthbar then
            line.Color = color
        end
    end
    self.shifter.Color = shifterColor
    self.textLabel.Color = color
end

function ESP:UpdateShifter(Size)
    if self.debounce == 0 then
        self.debounce = 1
        task.spawn(function()
            for i = 0, Size.Y, 0.1 do
                if not self.target or not self.target.Parent then break end
                self.shifteroffset = Lerp(self.shifteroffset, i, 0.5)
                task.wait()
            end
            for i = self.shifteroffset, 0, -0.1 do
                if not self.target or not self.target.Parent then break end
                self.shifteroffset = Lerp(self.shifteroffset, i, 0.5)
                task.wait()
            end
            for i = 0, -Size.Y, -0.1 do
                if not self.target or not self.target.Parent then break end
                self.shifteroffset = Lerp(self.shifteroffset, i, 0.5)
                task.wait()
            end
            for i = self.shifteroffset, 0, 0.1 do
                if not self.target or not self.target.Parent then break end
                self.shifteroffset = Lerp(self.shifteroffset, i, 0.5)
                task.wait()
            end
            self.debounce = 0
        end)
    end

    self.shifter.Visible = self.settings.Shifter_Enabled
    
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

function ESP:UpdateCharms(target)
    if not self.settings.Charms_Enabled then
        if self.highlight then
            self.highlight:Destroy()
            self.highlight = nil
            self.charmsEnabled = false
        end
        return
    end
    
    if not self.highlight and self.settings.Charms_Enabled then
        self.highlight = Instance.new("Highlight")
        self.highlight.FillColor = self.settings.Charms_Color
        self.highlight.OutlineColor = self.settings.Charms_OutlineColor
        self.highlight.FillTransparency = 0.5
        self.highlight.OutlineTransparency = self.settings.Box_Transparency
        self.highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        
        local targetObject = self:GetHighlightTarget()
        if targetObject then
            self.highlight.Adornee = targetObject
            self.highlight.Parent = targetObject
            self.charmsEnabled = true
        else
            self.highlight:Destroy()
            self.highlight = nil
        end
    elseif self.highlight then
        self.highlight.Visible = self.settings.Charms_Enabled
        self.highlight.FillColor = self.settings.Charms_Color
        self.highlight.OutlineColor = self.settings.Charms_OutlineColor
        self.highlight.OutlineTransparency = self.settings.Box_Transparency
    end
end

function ESP:GetHighlightTarget()
    if not self:IsValidTarget() then return nil end
    
    if self.isObject then
        if self.target:IsA("BasePart") then
            return self.target
        elseif self.target:IsA("Model") then
            if self.target.PrimaryPart then
                return self.target.PrimaryPart
            else
                for _, child in pairs(self.target:GetChildren()) do
                    if child:IsA("BasePart") then
                        return child
                    end
                end
                return self.target
            end
        end
    else
        -- For characters, highlight the whole character model
        return self.target
    end
    
    return nil
end

function ESP:UpdateAutoThickness()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local targetPos = self:GetTargetPosition()
    local distance = (player.Character.HumanoidRootPart.Position - targetPos).magnitude
    local value = math.clamp(1/distance*100, 0.1, 4)
    
    for _, line in pairs(self.lines) do
        line.Thickness = value
    end
    self.shifter.Thickness = value
    if self.highlight then
        self.highlight.Thickness = value
    end
end

function ESP:Show()
    if not self.visible then return end
    
    if self.settings.Box_Enabled then
        for i = 1, 12 do
            self.lines["line" .. i].Visible = true
        end
    end
    
    if self.settings.Tracers then
        self.lines.Tracer.Visible = true
    end
    
    if self.settings.HealthBar_Enabled and not self.isObject then
        self.lines.healthbar.Visible = true
        self.lines.greenhealth.Visible = true
    end
    
    if self.settings.Text_Enabled then
        self.textLabel.Visible = true
    end
    
    if self.settings.Shifter_Enabled and not self.isObject then
        self.shifter.Visible = true
    end
    
    if self.settings.Charms_Enabled and self.highlight then
        self.highlight.Visible = true
    end
end

function ESP:Hide()
    for _, line in pairs(self.lines) do
        line.Visible = false
    end
    self.shifter.Visible = false
    self.textLabel.Visible = false
    if self.highlight then
        self.highlight.Visible = false
    end
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
            if line ~= self.lines.greenhealth and line ~= self.lines.healthbar then
                line.Color = color
            end
        end
        self.textLabel.Color = color
    end
end

function ESP:Clear()
    if self.parentChangeConnection then
        self.parentChangeConnection:Disconnect()
        self.parentChangeConnection = nil
    end
    
    for _, line in pairs(self.lines) do
        if line then
            line:Remove()
        end
    end
    
    if self.shifter then
        self.shifter:Remove()
    end
    
    if self.textLabel then
        self.textLabel:Remove()
    end
    
    if self.highlight then
        self.highlight:Destroy()
        self.highlight = nil
    end
    
    ESPConfig.instances[self] = nil
    
    self.lines = {}
    self.shifter = nil
    self.textLabel = nil
    self.charms = nil
end

function ESPConfig:UpdateAll(newConfig)
    for key, value in pairs(newConfig) do
        self.globalSettings[key] = value
    end
    
    for espInstance, _ in pairs(self.instances) do
        if espInstance.target and espInstance.target.Parent then
            espInstance:UpdateSettings(newConfig)
        end
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

function ESPConfig:StartGlobalRender()
    if self.renderConnection then return end
    
    self.renderConnection = runService.RenderStepped:Connect(function()
        for espInstance, _ in pairs(self.instances) do
            if espInstance.visible and espInstance.target and espInstance.target.Parent then
                espInstance:UpdateESP()
            end
        end
    end)
end

function ESPConfig:StopGlobalRender()
    if self.renderConnection then
        self.renderConnection:Disconnect()
        self.renderConnection = nil
    end
end

function ESPConfig:ClearAll()
    for espInstance, _ in pairs(self.instances) do
        espInstance:Clear()
    end
    self:StopGlobalRender()
end

function ESPModule.AddESP(targetPath, color, settings)
    local targetObject
    
    if typeof(targetPath) == "Instance" then
        targetObject = targetPath
    elseif typeof(targetPath) == "string" then
        targetObject = players:FindFirstChild(targetPath)
        if not targetObject then
            warn("Player not found: " .. targetPath)
            return nil
        end
    else
        warn("Invalid target path. Expected Instance or player name string.")
        return nil
    end
    
    local finalSettings = {}
    for key, value in pairs(ESPConfig.globalSettings) do
        finalSettings[key] = value
    end
    if settings then
        for key, value in pairs(settings) do
            finalSettings[key] = value
        end
    end
    
    local esp = ESP.new(targetObject, color, finalSettings)
    
    ESPConfig:StartGlobalRender()
    
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
        
        UpdateSettings = function(newSettings)
            esp:UpdateSettings(newSettings)
        end,
        
        GetTarget = function()
            return esp.target
        end
    }
end

function ESPModule.AddESPToAll(params)
    -- Extract parameters from table
    local containerPath = params.container
    local color = params.color or Color3.new(1, 1, 1)
    local excludeSelf = params.excludeSelf or false
    local settings = params.settings or {}
    local nameFilter = params.nameFilter or nil -- Can be a string or table of strings
    local parent = params.parent or nil

    local espInstances = {}
    local connections = {}
    
    local function isCharacterModel(obj)
        local current = obj
        while current do
            if current:FindFirstChild("Humanoid") and current:FindFirstChild("HumanoidRootPart") then
                return true, current
            end
            current = current.Parent
        end
        return false, nil
    end

    local function nameMatches(objName)
        if not nameFilter then return true end
        if type(nameFilter) == "string" then
            return objName == nameFilter
        elseif type(nameFilter) == "table" then
            for _, name in ipairs(nameFilter) do
                if objName == name then return true end
            end
        end
        return false
    end

    local isInParentName = function(obj)
        return obj.Parent.Name == parent
    end

    local function addESPToObject(obj)
        if excludeSelf and obj == player.Character then return end
        if not nameMatches(obj.Name) then return end
        if (parent ~= nil) and not isInParentName(obj) then return end

        local isCharacter, characterModel = isCharacterModel(obj)
        local hasHumanoid = obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart")
        local isObject = obj:IsA("Model") or obj:IsA("BasePart") or  obj:IsA("Part") or obj:IsA("MeshPart") or obj:FindFirstChild("MeshPart") or obj:FindFirstChild("Part")

        if isCharacter and characterModel and not espInstances[characterModel] then
            local esp = ESPModule.AddESP(characterModel, color, settings)
            if esp then
                espInstances[characterModel] = esp
                connections[characterModel] = characterModel.AncestryChanged:Connect(function()
                    if not characterModel.Parent then
                        if espInstances[characterModel] then
                            espInstances[characterModel].Clear()
                            espInstances[characterModel] = nil
                        end
                    end
                end)
            end
        elseif (hasHumanoid or isObject) and not isCharacter then
            local esp = ESPModule.AddESP(obj, color, settings)
            if esp then
                espInstances[obj] = esp
                connections[obj] = obj.AncestryChanged:Connect(function()
                    if not obj.Parent then
                        if espInstances[obj] then
                            espInstances[obj].Clear()
                            espInstances[obj] = nil
                        end
                    end
                end)
            end
        end
    end

    local function scanContainer()
        local objects = containerPath:GetDescendants()
        for _, obj in pairs(objects) do
            if (obj:IsA("Model") or obj:IsA("Part") or obj:IsA("MeshPart")) and not espInstances[obj] then
                addESPToObject(obj)
            end
        end
    end

    scanContainer()

    local addedConnection = containerPath.DescendantAdded:Connect(function(obj)
        if obj:IsA("Model") or obj:IsA("Part") or obj:IsA("MeshPart") then
            task.wait(0.1)
            addESPToObject(obj)
        end
    end)

    local removedConnection = containerPath.DescendantRemoving:Connect(function(obj)
        if espInstances[obj] then
            espInstances[obj].Clear()
            espInstances[obj] = nil
            if connections[obj] then
                connections[obj]:Disconnect()
                connections[obj] = nil
            end
        end
    end)

    local cleanupConnection = task.spawn(function()
        while true do
            task.wait(5)
            for obj, esp in pairs(espInstances) do
                if not obj.Parent then
                    esp.Clear()
                    espInstances[obj] = nil
                    if connections[obj] then
                        connections[obj]:Disconnect()
                        connections[obj] = nil
                    end
                end
            end
            scanContainer()
        end
    end)

    print("Added ESP to container with " .. tostring(#espInstances) .. " objects")

    return {
        ClearAll = function()
            for _, esp in pairs(espInstances) do
                esp.Clear()
            end
            for _, connection in pairs(connections) do
                connection:Disconnect()
            end
            addedConnection:Disconnect()
            removedConnection:Disconnect()
            if cleanupConnection then
                task.cancel(cleanupConnection)
            end
            espInstances = {}
            connections = {}
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

        GetESP = function(obj)
            return espInstances[obj]
        end,

        GetCount = function()
            local count = 0
            for _ in pairs(espInstances) do
                count = count + 1
            end
            return count
        end,

        UpdateAllSettings = function(newSettings)
            for _, esp in pairs(espInstances) do
                esp.UpdateSettings(newSettings)
            end
        end,

        RefreshAll = function()
            scanContainer()
        end
    }
end

ESPModule.SetGlobalBox = function(enabled)
    ESPConfig:UpdateAll({Box_Enabled = enabled})
end

ESPModule.SetGlobalHealthbar = function(enabled)
    ESPConfig:UpdateAll({HealthBar_Enabled = enabled})
end

ESPModule.SetGlobalText = function(enabled)
    ESPConfig:UpdateAll({Text_Enabled = enabled})
end

ESPModule.SetGlobalShifter = function(enabled)
    ESPConfig:UpdateAll({Shifter_Enabled = enabled})
end

ESPModule.SetGlobalTracers = function(enabled)
    ESPConfig:UpdateAll({Tracers = enabled})
end

ESPModule.SetGlobalColors = function(boxColor, tracerColor, shifterColor, textColor)
    ESPConfig:UpdateAll({
        Box_Color = boxColor or ESPConfig.globalSettings.Box_Color,
        Tracer_Color = tracerColor or ESPConfig.globalSettings.Tracer_Color,
        Shifter_Color = shifterColor or ESPConfig.globalSettings.Shifter_Color,
        Text_Color = textColor or ESPConfig.globalSettings.Text_Color
    })
end

ESPModule.ClearAll = function()
    ESPConfig:ClearAll()
end

return ESPModule
