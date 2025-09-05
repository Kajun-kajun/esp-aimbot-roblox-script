local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local Mouse = game.Players.LocalPlayer:GetMouse()
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

local tool = nil
local enabled = false
local lastFireTime = 0
local fireDelay = 0 -- Fire delay, set back to original value (0.005 for fast firing)

-- List of valid hitboxes (can add or remove parts here)
local validParts = {
    Head = true,
    Torso = true,
    UpperTorso = true,
    LowerTorso = true,
}

-- Prediction time function based on enemy velocity
local function getPredictionTime(player)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return 0.03 end  -- Shorter prediction time (smaller prediction)
    local velocity = root.Velocity
    local speed = velocity.Magnitude
    -- Reduce the impact of the speed on prediction time (smaller time = smaller prediction)
    return 0.03 + math.clamp(speed / 250, 0, 0.05)  -- Even smaller prediction time
end

-- Get the target under the mouse and predict its future position
local function getTargetUnderMouse()
    local target = Mouse.Target
    if not target then return nil end

    local character = target:FindFirstAncestorOfClass("Model")
    if not character then return nil end

    local player = Players:GetPlayerFromCharacter(character)
    if not player or player == LocalPlayer then return nil end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local velocity = root.Velocity
    local predictTime = getPredictionTime(player)

    -- Predict where the enemy will be based on their velocity
    local predictedPosition = root.Position + velocity * predictTime

    -- Check if the target is within a valid hitbox part
    if validParts[target.Name] then
        -- Check distance between predicted and current position, only fire if within range
        local distance = (predictedPosition - target.Position).Magnitude
        if distance < 6 then
            return player, target, predictedPosition
        end
    end

    return nil
end

-- Fire the tool when triggered
local function fireTool()
    if tool and tool:IsA("Tool") then
        tool:Activate()
    end
end

-- Update tool when a new one is equipped
local function updateTool(character)
    tool = nil
    if not character then return end
    for _, child in pairs(character:GetChildren()) do
        if child:IsA("Tool") then
            tool = child
            break
        end
    end
    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            tool = child
        end
    end)
    character.ChildRemoved:Connect(function(child)
        if child == tool then
            tool = nil
        end
    end)
end

-- Setup to detect key inputs for triggerbot
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton3 then
        enabled = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton3 then
        enabled = false
    end
end)

-- Handle character respawn and tool updates
LocalPlayer.CharacterAdded:Connect(function(character)
    updateTool(character)
end)

if LocalPlayer.Character then
    updateTool(LocalPlayer.Character)
end

-- Main Loop to check and fire with proper delay
RunService.RenderStepped:Connect(function()
    if enabled and tool then
        local player, part, predictedPosition = getTargetUnderMouse()
        if player and predictedPosition then
            local currentTime = tick()
            -- Only fire if enough time has passed since the last shot (based on fireDelay)
            if currentTime - lastFireTime >= fireDelay then
                fireTool()
                lastFireTime = currentTime
            end
        end
    end
end)
