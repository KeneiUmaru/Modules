local teleportScript = [[
    _G.TargetName = { "Dragon Fly" }

    local function notify(title, text)
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = title,
                Text = text,
                Duration = 5
            })
        end)
    end

    -- Wait for LocalPlayer
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    while not player do
        task.wait()
        player = Players.LocalPlayer
    end

    -- Wait for DataService to load
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local DataSer = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DataService"))

    while not pcall(function() return DataSer:GetData().SavedObjects end) do
        task.wait()
    end

    local notrejoin = false

    while true do
        task.wait()
        local data = DataSer:GetData()

        for _, v in pairs(data.SavedObjects or {}) do
            if v.ObjectType == "PetEgg" and v.Data.RandomPetData and v.Data.CanHatch then
                local petName = v.Data.RandomPetData.Name
                print("Checking:", petName)
                notify("Checking Egg", petName)

                if table.find(_G.TargetName, petName) then
                    notrejoin = true
                    notify("🎯 Target Found!", "Found: " .. petName)
                end
            end
        end

        if notrejoin then
            print("Found Eggs!")
        else
            notify("Rejoining", "Target pet not found, retrying...")
            task.wait(3)
            player:Kick("Don't have your target pet\\Rejoin")
            game:GetService("TeleportService"):Teleport(game.PlaceId, player)
        end
    end
]]

-- Queue the script on teleport
game:GetService("TeleportService"):SetTeleportSetting("CustomTeleportMessage", "Searching for target pet...")
queue_on_teleport(teleportScript)
