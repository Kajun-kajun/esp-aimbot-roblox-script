local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Settings
local triggerKey = Enum.UserInputType.MouseButton3  -- Middle mouse button to hold for triggerbot
local enabled = false
local tool = nil

local lastFireTime = 0
local fireDelay = 0.03  -- 30 milliseconds delay

-- Function to find if mouse is over an enemy hitbox
local function getTargetUnderMouse()
    local target = Mouse.Target
    if not target then return nil end

    local character = target:FindFirstAncestorOfClass("Model")
    if not character then return nil end

    local player = Players:GetPlayerFromCharacter(character)
    if not player then return nil end
    if player == LocalPlayer then return nil end  -- Ignore self

    -- Check if the target is a valid hitbox part (e.g., "Head", "Torso", or any part in character)
    local validParts = {
        Head = true,
        Torso = true,
        UpperTorso = true,
        LowerTorso = true,
        ["Left Arm"] = true,
        ["Right Arm"] = true,
        ["Left Leg"] = true,
        ["Right Leg"] = true,
    }
    if validParts[target.Name] then
        return player, target
    else
        return nil
    end
end

-- Function to "fire" the equipped tool
local function fireTool()
    if not tool then return end
    if tool:IsA("Tool") then
        -- Activate the tool (simulate shooting)
        tool:Activate()
    end
end

-- Listen to tool equips to keep reference updated
LocalPlayer.CharacterAdded:Connect(function(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            tool = child
        end
    end)
end)

-- Also get tool if already equipped on script start
local character = LocalPlayer.Character
if character then
    for _, child in pairs(character:GetChildren()) do
        if child:IsA("Tool") then
            tool = child
            break
        end
    end
end

-- Listen for key press/release to enable/disable triggerbot
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == triggerKey then
        enabled = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == triggerKey then
        enabled = false
    end
end)

-- Main loop: when enabled, check if mouse is over enemy hitbox and fire with delay
RunService.RenderStepped:Connect(function()
    if enabled and tool then
        local player, part = getTargetUnderMouse()
        if player and part then
            local currentTime = tick()
            if currentTime - lastFireTime >= fireDelay then
                fireTool()
                lastFireTime = currentTime
            end
        end
    end
end)
