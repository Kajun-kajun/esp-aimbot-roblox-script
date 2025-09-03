local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- Speed settings
local speedMultiplier = 1
local defaultSpeed = 16
local aimbotEnabled = false
local targetPlayer = nil

-- Reaction & legit settings
local reactionTime = 0
local lastLockTime = 0
local jitterStrength = 0.05

-- Aimbot settings
local aimParts = {"Head", "Torso", "Left Leg", "Right Leg"}
local aimPartIndex = 1
local aimPart = aimParts[aimPartIndex]
local aimbotFOV = 200
local smoothness = 0.030

-- Default lock key (middle mouse button by default)
local lockKey = Enum.UserInputType.MouseButton3  -- Default: MouseButton3 (middle mouse button)

local ScreenGui

-- GUI Creation
local function createSpeedGui()
    if LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("SpeedGui") then
        ScreenGui = LocalPlayer.PlayerGui.SpeedGui
        return
    end

    ScreenGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
    ScreenGui.Name = "SpeedGui"

    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(0, 350, 0, 250)
    shadow.Position = UDim2.new(0.5, -170, 0.5, -125)
    shadow.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    shadow.BorderSizePixel = 0
    shadow.ZIndex = 0
    shadow.Parent = ScreenGui

    Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 12)

    local frame = Instance.new("Frame", ScreenGui)
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(0, 350, 0, 250)
    frame.Position = UDim2.new(0.5, -175, 0.5, -125)
    frame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
    frame.BorderSizePixel = 0
    frame.ZIndex = 1

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

    local titleLabel = Instance.new("TextLabel", frame)
    titleLabel.Size = UDim2.new(1, 0, 0, 45)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    titleLabel.BorderSizePixel = 0
    titleLabel.Text = "Made by Kajun"
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
    titleLabel.TextSize = 22

    Instance.new("UICorner", titleLabel).CornerRadius = UDim.new(0, 12)

    local subTitle = Instance.new("TextLabel", frame)
    subTitle.Size = UDim2.new(1, 0, 0, 30)
    subTitle.Position = UDim2.new(0, 0, 0, 50)
    subTitle.BackgroundTransparency = 1
    subTitle.Text = "Camlock Settings"
    subTitle.Font = Enum.Font.Gotham
    subTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    subTitle.TextSize = 18

    local function createLabelAndInput(parent, yPos, labelText, inputText, isButton)
        local label = Instance.new("TextLabel", parent)
        label.Size = UDim2.new(0, 130, 0, 25)
        label.Position = UDim2.new(0, 20, 0, yPos)
        label.BackgroundTransparency = 1
        label.Text = labelText
        label.Font = Enum.Font.Gotham
        label.TextColor3 = Color3.fromRGB(210, 210, 210)
        label.TextSize = 16
        label.TextXAlignment = Enum.TextXAlignment.Left

        local input
        if isButton then
            input = Instance.new("TextButton")
            input.TextColor3 = Color3.fromRGB(230, 230, 230)
            input.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        else
            input = Instance.new("TextBox")
            input.TextColor3 = Color3.fromRGB(230, 230, 230)
            input.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            input.ClearTextOnFocus = false
        end

        input.Parent = parent
        input.Size = UDim2.new(0, 180, 0, 30)
        input.Position = UDim2.new(0, 160, 0, yPos - 3)
        input.Font = Enum.Font.Gotham
        input.TextSize = 18
        input.Text = inputText
        input.BorderSizePixel = 0

        Instance.new("UICorner", input).CornerRadius = UDim.new(0, 6)

        return input
    end

    local aimPartButton = createLabelAndInput(frame, 95, "Aim Part", aimPart, true)
    aimPartButton.MouseButton1Click:Connect(function()
        aimPartIndex = aimPartIndex % #aimParts + 1
        aimPart = aimParts[aimPartIndex]
        aimPartButton.Text = aimPart
    end)

    local fovBox = createLabelAndInput(frame, 135, "FOV", tostring(aimbotFOV), false)
    fovBox.FocusLost:Connect(function()
        local val = tonumber(fovBox.Text)
        if val then
            aimbotFOV = math.clamp(val, 1, 1000)
            fovBox.Text = tostring(aimbotFOV)
        else
            fovBox.Text = tostring(aimbotFOV)
        end
    end)

    local smoothBox = createLabelAndInput(frame, 175, "Smoothness", string.format("%.3f", smoothness), false)
    smoothBox.FocusLost:Connect(function()
        local val = tonumber(smoothBox.Text)
        if val then
            smoothness = math.clamp(val, 0.01, 1)
            smoothBox.Text = string.format("%.3f", smoothness)
        else
            smoothBox.Text = string.format("%.3f", smoothness)
        end
    end)

    local speedBox = createLabelAndInput(frame, 215, "Speed Multiplier", tostring(speedMultiplier), false)
    speedBox.FocusLost:Connect(function()
        local val = tonumber(speedBox.Text)
        if val then
            speedMultiplier = math.clamp(val, 0.1, 10)
            speedBox.Text = tostring(speedMultiplier)
        else
            speedBox.Text = tostring(speedMultiplier)
        end
    end)

    local lockKeyButton = createLabelAndInput(frame, 255, "Lock Key", tostring(lockKey.Name), true)
    lockKeyButton.MouseButton1Click:Connect(function()
        local function getKeyPress()
            lockKeyButton.Text = "Press any key..."
            local connection
            connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    lockKey = input.KeyCode
                    lockKeyButton.Text = tostring(lockKey.Name)
                elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                    lockKey = Enum.UserInputType.MouseButton1
                    lockKeyButton.Text = "MouseButton1"
                elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                    lockKey = Enum.UserInputType.MouseButton2
                    lockKeyButton.Text = "MouseButton2"
                elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
                    lockKey = Enum.UserInputType.MouseButton3
                    lockKeyButton.Text = "MouseButton3"
                end
                connection:Disconnect()
            end)
        end
        getKeyPress()
    end)

    local hint = Instance.new("TextLabel", frame)
    hint.Size = UDim2.new(1, 0, 0, 20)
    hint.Position = UDim2.new(0, 0, 1, -20)
    hint.BackgroundTransparency = 1
    hint.Text = "Press K to open/close this menu"
    hint.Font = Enum.Font.Gotham
    hint.TextColor3 = Color3.fromRGB(120, 120, 120)
    hint.TextSize = 14
    hint.TextXAlignment = Enum.TextXAlignment.Center
end

-- Targeting function
local function getClosestTarget(maxFov)
    local closestPlayer = nil
    local closestDistance = math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local part = char:FindFirstChild(aimPart)

            if not part and (aimPart == "Left Leg" or aimPart == "Right Leg") then
                local l = char:FindFirstChild("Left Leg")
                local r = char:FindFirstChild("Right Leg")
                part = l or r
            end

            if part then
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                if onScreen and dist < closestDistance and dist < maxFov then
                    closestDistance = dist
                    closestPlayer = player
                end
            end
        end
    end
    return closestPlayer
end

-- Aimbot smooth function
local function smoothAim(targetPart)
    if not targetPart then return end
    local jitter = Vector3.new(
        (math.random() - 0.5) * jitterStrength,
        (math.random() - 0.5) * jitterStrength,
        (math.random() - 0.5) * jitterStrength
    )
    local camPos = Camera.CFrame.Position
    local newCF = CFrame.new(camPos, targetPart.Position + jitter)
    Camera.CFrame = Camera.CFrame:Lerp(newCF, smoothness)
end

-- Update loop
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    local humanoid = char and char:FindFirstChildWhichIsA("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = defaultSpeed * speedMultiplier
    end

    if aimbotEnabled and targetPlayer and targetPlayer.Character then
        local part = targetPlayer.Character:FindFirstChild(aimPart)
        if part and time() - lastLockTime >= reactionTime then
            smoothAim(part)
        end
    end
end)

-- Input handling
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    -- For Mouse Button or Keyboard
    if input.UserInputType == lockKey then
        aimbotEnabled = true
        targetPlayer = getClosestTarget(aimbotFOV)
        lastLockTime = time()
    elseif input.KeyCode == Enum.KeyCode.K then
        if ScreenGui then
            ScreenGui.Enabled = not ScreenGui.Enabled
        else
            createSpeedGui()
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == lockKey then
        aimbotEnabled = false
        targetPlayer = nil
    end
end)

-- Initialize GUI
createSpeedGui()
