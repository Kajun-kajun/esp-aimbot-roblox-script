local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local ESP = {}
local ESPEnabled = true
local aimbotEnabled = false  -- Initially off
local targetPlayer = nil  -- Current target

-- Colors
local boxColor = Color3.fromRGB(169, 169, 169)
local textColor = Color3.fromRGB(255, 255, 255)
local boxTransparency = 0.7
local nameSize = 16
local boxThickness = 2

local maxDistance = 100
local minScale = 0.3

-- Create ESP for a player
function createESP(player)
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = boxColor
    box.Thickness = boxThickness
    box.Transparency = boxTransparency
    box.Filled = true

    local nameTag = Drawing.new("Text")
    nameTag.Visible = false
    nameTag.Center = true
    nameTag.Outline = true
    nameTag.Color = textColor
    nameTag.Size = nameSize

    ESP[player] = {
        Box = box,
        Name = nameTag
    }
end

function removeESP(player)
    if ESP[player] then
        ESP[player].Box:Remove()
        ESP[player].Name:Remove()
        ESP[player] = nil
    end
end

function getCharacterBounds(character)
    local parts = {}
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            table.insert(parts, part)
        end
    end

    if #parts == 0 then return nil, nil end

    local minVec = parts[1].Position
    local maxVec = parts[1].Position

    for _, part in pairs(parts) do
        local pos = part.Position
        minVec = Vector3.new(
            math.min(minVec.X, pos.X),
            math.min(minVec.Y, pos.Y),
            math.min(minVec.Z, pos.Z)
        )
        maxVec = Vector3.new(
            math.max(maxVec.X, pos.X),
            math.max(maxVec.Y, pos.Y),
            math.max(maxVec.Z, pos.Z)
        )
    end

    return minVec, maxVec
end

-- Find player closest to the crosshair (center of screen)
function getClosestTarget()
    local closestPlayer = nil
    local closestDistance = math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)

            if onScreen then
                local screenPoint = Vector2.new(screenPos.X, screenPos.Y)
                local dist = (screenPoint - screenCenter).Magnitude
                if dist < closestDistance and dist < 150 then -- 150 pixels radius limit for lock
                    closestDistance = dist
                    closestPlayer = player
                end
            end
        end
    end

    return closestPlayer
end

-- Human-like aiming adjustments with smoother aiming
local minSmooth = 0.02  -- slower lerp for smoothness
local maxSmooth = 0.07
local smoothSpeed = math.random() * (maxSmooth - minSmooth) + minSmooth
local frameCount = 0

local function getRandomAimPosition(targetHead)
    local offsetRange = 0.3 -- small jitter range
    local randomOffset = Vector3.new(
        (math.random() - 0.5) * offsetRange,
        (math.random() - 0.5) * offsetRange,
        (math.random() - 0.5) * offsetRange
    )
    return targetHead.Position + randomOffset
end

function smoothAim(target)
    if target and target.Character and target.Character:FindFirstChild("Head") then
        frameCount = frameCount + 1
        if frameCount % 10 == 0 then
            smoothSpeed = math.random() * (maxSmooth - minSmooth) + minSmooth
        end

        local targetPos = getRandomAimPosition(target.Character.Head)
        local smoothCFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPos), smoothSpeed)
        Camera.CFrame = smoothCFrame
    end
end

function updateESP()
    for player, esp in pairs(ESP) do
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if character and humanoid and humanoid.Health > 0 and ESPEnabled then
            local minVec, maxVec = getCharacterBounds(character)
            if minVec and maxVec then
                local corners = {
                    Vector3.new(minVec.X, maxVec.Y, minVec.Z),
                    Vector3.new(maxVec.X, maxVec.Y, minVec.Z),
                    Vector3.new(minVec.X, maxVec.Y, maxVec.Z),
                    Vector3.new(maxVec.X, maxVec.Y, maxVec.Z),
                    Vector3.new(minVec.X, minVec.Y, minVec.Z),
                    Vector3.new(maxVec.X, minVec.Y, minVec.Z),
                    Vector3.new(minVec.X, minVec.Y, maxVec.Z),
                    Vector3.new(maxVec.X, minVec.Y, maxVec.Z),
                }

                local screenPoints = {}
                local onScreen = false

                for _, corner in ipairs(corners) do
                    local screenPos, visible = Camera:WorldToViewportPoint(corner)
                    table.insert(screenPoints, Vector2.new(screenPos.X, screenPos.Y))
                    if visible then
                        onScreen = true
                    end
                end

                if onScreen then
                    local minX = math.huge
                    local minY = math.huge
                    local maxX = -math.huge
                    local maxY = -math.huge

                    for _, point in ipairs(screenPoints) do
                        if point.X < minX then minX = point.X end
                        if point.Y < minY then minY = point.Y end
                        if point.X > maxX then maxX = point.X end
                        if point.Y > maxY then maxY = point.Y end
                    end

                    local boxPos = Vector2.new(minX, minY)
                    local boxSize = Vector2.new(maxX - minX, maxY - minY)

                    local center3D = (minVec + maxVec) / 2
                    local distance = (Camera.CFrame.Position - center3D).Magnitude

                    local scale = 1 - math.clamp(distance / maxDistance, 0, 1) * (1 - minScale)
                    if distance < maxDistance then
                        scale = math.clamp(1.5 - (distance / maxDistance) * 0.5, minScale, 1.5)
                    end

                    local scaledBoxSize = Vector2.new(
                        boxSize.X * scale * 0.7,
                        boxSize.Y * scale
                    )

                    local boxCenter = boxPos + boxSize / 2
                    esp.Box.Position = boxCenter - scaledBoxSize / 2
                    esp.Box.Size = scaledBoxSize
                    esp.Box.Visible = true

                    esp.Name.Text = player.DisplayName or player.Name
                    esp.Name.Position = Vector2.new(boxCenter.X, boxCenter.Y - scaledBoxSize.Y / 2 - 15)
                    esp.Name.Visible = true
                else
                    esp.Box.Visible = false
                    esp.Name.Visible = false
                end
            else
                esp.Box.Visible = false
                esp.Name.Visible = false
            end
        else
            esp.Box.Visible = false
            esp.Name.Visible = false
        end
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        createESP(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        createESP(player)
    end
end)

Players.PlayerRemoving:Connect(removeESP)

RunService.RenderStepped:Connect(function()
    updateESP()

    if aimbotEnabled then
        -- Continuously update target while aiming, so target changes if closer to crosshair
        targetPlayer = getClosestTarget()
        if targetPlayer then
            smoothAim(targetPlayer)
        end
    else
        targetPlayer = nil
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton3 then  -- Middle mouse button
        aimbotEnabled = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton3 then
        aimbotEnabled = false
        targetPlayer = nil
    end
end)

-- Destroy key (_)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Underscore then
        -- Cleanup ESP
        for player, esp in pairs(ESP) do
            esp.Box:Remove()
            esp.Name:Remove()
        end
        ESP = {}

        aimbotEnabled = false
        targetPlayer = nil

        print("Script destroyed")
    end
end)
