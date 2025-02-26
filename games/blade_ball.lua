setfpscap(240)

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Vim = game:GetService("VirtualInputManager")
local ballFolder = Workspace:WaitForChild("Balls")
local trainingFolder = Workspace:WaitForChild("TrainingBalls")

local pressCooldown = 0
local lastPressTime = {}
local isKeyPressed = {}

local configHighPing = {
    value1 = 0.107,
    value2 = 0.0065,
    value3 = 0.0115,
    value4 = 0.29
}

local configLowPing = {
    value1 = 0.107,
    value2 = 0.0058,
    value3 = 0.01,
    value4 = 0.31
}

local currentConfig = nil
local lastConfigUpdate = tick()
local configUpdateInterval = .2

local baseValue1: number = configLowPing.value1
local originalValue2: number = configLowPing.value2
local originalValue3: number = configLowPing.value3

local peakTracker = {}

local function getPlayerPing()
    local stats = game:GetService("Stats")
    local networkStats = stats.Network
    return networkStats.ServerStatsItem["Data Ping"]:GetValue()
end

local function updateConfigBasedOnPing(ping)
    if tick() - lastConfigUpdate > configUpdateInterval then
        currentConfig = (ping > 100) and configHighPing or configLowPing
        lastConfigUpdate = tick()
    end
end

currentConfig = (getPlayerPing() > 100) and configHighPing or configLowPing

local function GetBallVelocity(ball: BasePart): Vector3?
    local velocity: Vector3?

    local success, result = pcall(function()
        return ball.AssemblyLinearVelocity
    end)

    if success and typeof(result) == "Vector3" then
        velocity = result
    else
        local zoomies = ball:FindFirstChild("zoomies")
        if zoomies and zoomies:IsA("Vector3Value") then
            velocity = zoomies.Value
        end
    end

    return velocity
end

local function GetClosestPlayerDistance(ball: BasePart): number?
    local player = Players.LocalPlayer
    local character = player and player.Character
    if not character then return nil end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end

    local closestDistance = nil

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
            if otherRoot then
                local distance = (otherRoot.Position - ball.Position).Magnitude
                if not closestDistance or distance < closestDistance then
                    closestDistance = distance
                end
            end
        end
    end

    return closestDistance
end

local function resolveVelocity(ball, ping)
    local currentPosition = ball.Position
    local currentVelocity = GetBallVelocity(ball) or Vector3.zero
    local rtt = ping / 1000
    return currentPosition + currentVelocity * rtt
end

local function calculatePredictionTime(ball, player)
    local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    
    if rootPart then
        local ping = getPlayerPing()
        updateConfigBasedOnPing(ping)
       
        local predictedPosition = resolveVelocity(ball, ping)
        local relativePosition = predictedPosition - rootPart.Position
        local velocity = GetBallVelocity(ball) or Vector3.zero
        velocity = velocity + rootPart.Velocity

        local a = ball.Size.magnitude / 2
        local b = relativePosition.magnitude
        local c = math.sqrt(a * a + b * b)

        return (c - a) / velocity.magnitude
    end
    
    return math.huge
end

local function calculateThreshold(ball, player)
    local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return math.huge end

    local ping = getPlayerPing() / 1000
    
    updateConfigBasedOnPing(ping * 1000)
    
    local distance = (ball.Position - rootPart.Position).Magnitude

    local pingCompensation = ping * 1.78
    local baseThreshold = currentConfig.value1 + pingCompensation

    local velocityFactor = math.pow((GetBallVelocity(ball) or Vector3.zero).magnitude, 1.3) * currentConfig.value2
    local distanceFactor = distance * currentConfig.value3

    return math.max(baseThreshold, currentConfig.value4 - velocityFactor - distanceFactor)
end

local function TrackBallVelocity(ball: BasePart)
    local velocity = GetBallVelocity(ball)
    
    if not velocity then return end

    local currentSpeed = velocity.Magnitude
    local lastSpeed = peakTracker[ball] or currentSpeed
    local ping = getPlayerPing() / 1000
    local velocityFactor = math.min(velocity.Magnitude * 0.00002, 0.002)
    local pingFactor = math.min(ping * 0.0003, 0.002)
    local closestDistance = GetClosestPlayerDistance(ball)

    currentConfig.value1 = baseValue1
    currentConfig.value2 = originalValue2
    currentConfig.value3 = originalValue3

    if closestDistance then
        if closestDistance <= 8 then
            currentConfig.value1 = math.min(0.001, currentConfig.value1 - (0.0001 + velocityFactor + pingFactor))
            currentConfig.value2 = math.min(0.0005, currentConfig.value2 - 0.0003)
            currentConfig.value3 = math.min(0.0005, currentConfig.value3 - 0.003)
        elseif closestDistance <= 15 then
            currentConfig.value1 = math.min(0.15, currentConfig.value1 - (0.0001 + velocityFactor + pingFactor))
            currentConfig.value2 = math.min(0.002, currentConfig.value2 - 0.00005)
            currentConfig.value3 = math.min(0.003, currentConfig.value3 - 0.0005)
        end
    end

    currentConfig.value1 = math.max(baseValue1, currentConfig.value1)
    currentConfig.value2 = math.max(0, currentConfig.value2)
    currentConfig.value3 = math.max(0, currentConfig.value3)

    peakTracker[ball] = currentSpeed
end

local function checkProximityToPlayer(ball, player)
    TrackBallVelocity(ball)

    local predictionTime = calculatePredictionTime(ball, player)
    local realBallAttribute = ball:GetAttribute("realBall")
    local target = ball:GetAttribute("target")
    local ballSpeedThreshold = calculateThreshold(ball, player)

    if predictionTime <= ballSpeedThreshold and realBallAttribute and target == player.Name and not isKeyPressed[ball] and (not lastPressTime[ball] or tick() - lastPressTime[ball] > pressCooldown) then
        Vim:SendKeyEvent(true, Enum.KeyCode.F, false, nil)
        Vim:SendKeyEvent(false, Enum.KeyCode.F, false, nil)

        lastPressTime[ball] = tick()
        isKeyPressed[ball] = true
    elseif lastPressTime[ball] and (predictionTime > ballSpeedThreshold or not realBallAttribute or target ~= player.Name) then
        isKeyPressed[ball] = false
    end
end

local function checkBallsProximity()
    local player = Players.LocalPlayer
    if player and player.Character then
        for _, ball in ipairs(getAllBalls()) do
            checkProximityToPlayer(ball, player)
        end
    else
        isKeyPressed = {}
    end
end

RunService.Heartbeat:Connect(checkBallsProximity)
