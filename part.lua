ycastFilterType.Blacklist
                    local raycastResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
                    if not raycastResult or raycastResult.Instance:IsDescendantOf(otherPlayer.Character) then
                        closestTarget = targetRoot
                        minDistance = distance
                    end
                end
            end
        end
    end
    return closestTarget
end

CombatWindow:Toggle({
    Text = "Aimbot",
    Default = false,
    Callback = function(state)
        aimbotEnabled = state
    end
})


RenderWindow:Toggle({
    Text = "ESP",
    Default = false,
    Callback = function(state)
        espEnabled = state
        if espEnabled then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= Players.LocalPlayer and player.Character then
                    local espHighlight = Instance.new("Highlight")
                    espHighlight.FillColor = isFriend(player) and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(255, 0, 0)
                    espHighlight.OutlineColor = Color3.fromRGB(0, 0, 0)
                    espHighlight.Parent = player.Character
                    espHighlights[player] = espHighlight
                end
            end
        else
            for _, highlight in pairs(espHighlights) do
                highlight:Destroy()
            end
            espHighlights = {}
        end
    end
})

CombatWindow:Slider({
    Text = "Aimbot Range",
    Minimum = 10,
    Maximum = 100,
    Default = aimbotRange,
    Callback = function(value)
        aimbotRange = value
    end
})


CombatWindow:Slider({
    Text = "Aimbot Smoothness",
    Minimum = 1,
    Maximum = 50,
    Default = aimbotSmoothness * 50,
    Callback = function(value)
        aimbotSmoothness = value / 50
        updateESP()
    end
})

CombatWindow:Toggle({
    Text = "Kill Aura",
    Default = false,
    Callback = function(state)
        killAuraEnabled = state
        local player = Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:WaitForChild("HumanoidRootPart")
        local humanoid = character:WaitForChild("Humanoid")
        local lastAttackedTargets = {}
        local lastSelectedTarget = nil

        if killAuraEnabled then
            local connection
            connection = RunService.Heartbeat:Connect(function(deltaTime)
                if not killAuraEnabled or not character or not rootPart or humanoid.Health <= 0 then
                    highlight.Parent = nil
                    currentTarget = nil
                    lastAttackedTargets = {}
                    lastSelectedTarget = nil
                    if rootPart:FindFirstChild("BodyVelocity") then
                        rootPart:FindFirstChild("BodyVelocity"):Destroy()
                    end
                    connection:Disconnect()
                    return
                end

                local validTargets = {}
                for _, otherPlayer in pairs(Players:GetPlayers()) do
                    if otherPlayer ~= player and not isFriend(otherPlayer) and otherPlayer.Character then
                        local targetRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
                        local targetHumanoid = otherPlayer.Character:FindFirstChild("Humanoid")
                        if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
                            local distance = (rootPart.Position - targetRoot.Position).Magnitude
                            local spawnTime = playerSpawnTimes[otherPlayer] or 0
                            local timeSinceSpawn = tick() - spawnTime
                            if distance <= killAuraRange and timeSinceSpawn > spawnProtectionTime then
                                table.insert(validTargets, otherPlayer.Character)
                            end
                        end
                    end
                end

                if #validTargets > 0 then
                    if attackMultipleTargets then
                        local selectedTarget = nil
                        local minDistance = math.huge
                        for _, target in ipairs(validTargets) do
                            if not table.find(lastAttackedTargets, target) then
                                local distance = (rootPart.Position - target:FindFirstChild("HumanoidRootPart").Position).Magnitude
                                if distance < minDistance then
                                    selectedTarget = target
                                    minDistance = distance
                                end
                            end
                        end
                        if not selectedTarget then
                            for _, target in ipairs(validTargets) do
                                local distance = (rootPart.Position - target:FindFi