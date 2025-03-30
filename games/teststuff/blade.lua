setfpscap(240)

local RunService: RunService = game:GetService("RunService")
local Players: Players = game:GetService("Players")
local Workspace: Workspace = game:GetService("Workspace")
local Vim: VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService: UserInputService = game:GetService("UserInputService")

local ballFolder: Folder = Workspace:WaitForChild("Balls")
local trainingFolder: Folder = Workspace:WaitForChild("TrainingBalls")

local pressCooldown: number = 0
local ThresholdFloor: number = 0.14

local lastPressTime: { [Instance]: number } = {}
local isKeyPressed: { [Instance]: boolean } = {}
local previousVelocities: { [Instance]: Vector3 } = {}

local PingTracker: {
    samples: { number },
    maxSamples: number,
    lastSpikeTime: number,
    spikeThreshold: number,
    cooldown: number,
} = {
    samples = {},
    maxSamples = 40,
    lastSpikeTime = 0,
    spikeThreshold = 2.5,
    cooldown = 0.75,
}

local configHighPing: { value1: number, value2: number, value3: number, value4: number } = {
    value1 = 0.104,
    value2 = 0.0065,
    value3 = 0.0106,
    value4 = 0.31
}

local configLowPing: { value1: number, value2: number, value3: number, value4: number } = {
    value1 = 0.104,
    value2 = 0.0057,
    value3 = 0.011,
    value4 = 0.27
}

local currentConfig = nil
local lastConfigUpdate = tick()
local configUpdateInterval = .2

printValues = function()
    print("Current Config:")
    print("-----------------------------------------")
    print("Base Threshold: " .. currentConfig.value1)
    print("Velocity Factor: " .. currentConfig.value2)
    print("Distance Factor: " .. currentConfig.value3)
    print("math.max: " .. currentConfig.value4)
    print("-----------------------------------------")
end

GetBallVelocity = function(ball: BasePart): Vector3?
    if not ball then return nil end

    local success, velocity = pcall(function()
        return ball.AssemblyLinearVelocity
    end)
    
    if success and typeof(velocity) == "Vector3" then
        return velocity
    end

    local zoomies: Vector3Value? = ball:FindFirstChild("zoomies")
    
    if zoomies and zoomies:IsA("Vector3Value") then
        return zoomies.Value
    end

    return ball.Velocity
end

getPlayerPing = function()
    local stats = game:GetService("Stats")
    local networkStats = stats.Network
    return networkStats.ServerStatsItem["Data Ping"]:GetValue()
end

function PingTracker:AddSample(ping: number)
    table.insert(self.samples, ping)
    if #self.samples > self.maxSamples then
        table.remove(self.samples, 1)
    end
end

function PingTracker:GetAverage()
    local total = 0
    for _, ping in ipairs(self.samples) do total += ping end
    return (#self.samples > 0) and (total / #self.samples) or 0
end

function PingTracker:GetStandardDeviation()
    local avg = self:GetAverage()
    local sum = 0
    for _, ping in ipairs(self.samples) do
        sum += (ping - avg) ^ 2
    end
    return (#self.samples > 0) and math.sqrt(sum / #self.samples) or 0
end

function PingTracker:CheckSpike(currentPing)
    self:AddSample(currentPing)

    local avg = self:GetAverage()
    local stdDev = self:GetStandardDeviation()

    local threshold = avg + (stdDev * self.spikeThreshold)
    local now = tick()

    if currentPing > threshold and (now - self.lastSpikeTime) > self.cooldown then
        self.lastSpikeTime = now
        return true
    end

    return false
end

function PingTracker:IsActiveSpike()
    return (tick() - self.lastSpikeTime) <= 0.5
end

updateConfigBasedOnPing = function(ping)
    if tick() - lastConfigUpdate > configUpdateInterval then
        PingTracker:CheckSpike(ping)

        if PingTracker:IsActiveSpike() then
            currentConfig = configHighPing
        elseif ping > 100 then
            currentConfig = configHighPing
        else
            currentConfig = configLowPing
        end

        lastConfigUpdate = tick()
    end
end

currentConfig = (function()
    local initialPing = getPlayerPing()
    if initialPing > 100 then
        return configHighPing
    else
        return configLowPing
    end
end)()

resolveVelocity = function(ball, ping)
    local currentPosition = ball.Position
    local currentVelocity = GetBallVelocity(ball)

    local lastVel = previousVelocities[ball] or currentVelocity
    local smoothedVelocity = lastVel:Lerp(currentVelocity, 0.45)

    previousVelocities[ball] = currentVelocity

    local rtt = ping / 1000
    local predictedPosition = currentPosition + smoothedVelocity * rtt

    return predictedPosition
end

calculatePredictionTime = function(ball, player)
    local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    
    if rootPart then
        local ping = getPlayerPing()
        updateConfigBasedOnPing(ping)

        local predictedPosition = resolveVelocity(ball, ping)
        local relativePosition = predictedPosition - rootPart.Position

        local totalVelocity = (GetBallVelocity(ball) + rootPart.Velocity).magnitude
        local distance = relativePosition.Magnitude

        return distance / math.max(totalVelocity, 28)
    end

    return math.huge
end

calculateThreshold = function(ball, player)
    local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return math.huge end

    local ping = getPlayerPing() / 1000
    updateConfigBasedOnPing(ping * 1000)
    local distance = (ball.Position - rootPart.Position).Magnitude

    local pingCompensation = ping * 1.78
    local baseThreshold = currentConfig.value1 + pingCompensation

    local velocityMagnitude = GetBallVelocity(ball).magnitude
    local velocityFactor = math.pow(velocityMagnitude, 1.25) * currentConfig.value2
    local distanceFactor = math.pow(distance, 0.8) * currentConfig.value3

    local finalThreshold = math.max(baseThreshold, currentConfig.value4 - velocityFactor - distanceFactor)

    if distance > 65 then
        finalThreshold = math.max(finalThreshold, ThresholdFloor)
    end

    return finalThreshold
end

checkProximityToPlayer = function(ball, player)
    local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

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

    local distanceToPlayer = (ball.Position - rootPart.Position).Magnitude
    if distanceToPlayer < 10 and not isKeyPressed[ball] and (not lastPressTime[ball] or tick() - lastPressTime[ball] > pressCooldown) then
        Vim:SendKeyEvent(true, Enum.KeyCode.F, false, nil)
        Vim:SendKeyEvent(false, Enum.KeyCode.F, false, nil)

        lastPressTime[ball] = tick()
        isKeyPressed[ball] = true
    end
end

getAllBalls = function()
    local allBalls = {}
    
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj == ballFolder then
            for _, ball in ipairs(ballFolder:GetChildren()) do
                table.insert(allBalls, ball)
            end
        elseif obj == trainingFolder then
            for _, trainingBall in ipairs(trainingFolder:GetChildren()) do
                table.insert(allBalls, trainingBall)
            end
        end
    end
    return allBalls
end

checkBallsProximity = function()
    local player = Players.LocalPlayer
    
    if player and player.Character then
        for _, ball in ipairs(getAllBalls()) do
            checkProximityToPlayer(ball, player)
        end
    else
        isKeyPressed = {}
    end
end

printValues()
RunService.Heartbeat:Connect(checkBallsProximity)
