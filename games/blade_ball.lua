setfpscap(240)

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Vim = game:GetService("VirtualInputManager")
local ballFolder = Workspace.Balls
local trainingFolder = Workspace.TrainingBalls

local pressCooldown = 0
local lastPressTime = {}
local isKeyPressed = {}

local configHighPing = {
    value1 = 0.118,
    value2 = 0.003,
    value3 = 0.012,
    value4 = 0.22
}

local configLowPing = {
    value1 = 0.109,
    value2 = 0.0068,
    value3 = 0.0114,
    value4 = 0.27
}

local currentConfig = nil
local lastConfigUpdate = tick()
local configUpdateInterval = .1

local function printValues()
    print("Current Config:")
    print("-----------------------------------------")
    print("Base Threshold: " .. currentConfig.value1)
    print("Velocity Factor: " .. currentConfig.value2)
    print("Distance Factor: " .. currentConfig.value3)
    print("math.max: " .. currentConfig.value4)
    print("-----------------------------------------")
end

local function getPlayerPing()
    local stats = game:GetService("Stats")
    local networkStats = stats.Network
    return networkStats.ServerStatsItem["Data Ping"]:GetValue()
end

local function updateConfigBasedOnPing(ping)
    if tick() - lastConfigUpdate > configUpdateInterval then
        if ping > 100 then
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

local function resolveVelocity(ball, ping)
    local currentPosition = ball.Position
    local currentVelocity = ball.Velocity
    local rtt = ping / 1000
    local predictedPosition = currentPosition + currentVelocity * rtt
    return predictedPosition
end

local function calculatePredictionTime(ball, player)
    local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    
    if rootPart then
        local ping = getPlayerPing()
        updateConfigBasedOnPing(ping)
       
        local predictedPosition = resolveVelocity(ball, ping)
        local relativePosition = predictedPosition - rootPart.Position
        local velocity = ball.Velocity + rootPart.Velocity
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

    local pingCompensation = ping * 2
    local baseThreshold = currentConfig.value1 + pingCompensation

    local velocityFactor = math.pow(ball.Velocity.magnitude, 1.3) * currentConfig.value2
    local distanceFactor = distance * currentConfig.value3

    return math.max(baseThreshold, currentConfig.value4 - velocityFactor - distanceFactor)
end

local function checkProximityToPlayer(ball, player)
    local predictionTime = calculatePredictionTime(ball, player)
    local realBallAttribute = ball:GetAttribute("realBall")
    local target = ball:GetAttribute("target")
    local ballSpeedThreshold = calculateThreshold(ball, player)
    
    if predictionTime <= ballSpeedThreshold and realBallAttribute and target == player.Name and not isKeyPressed[ball] and (not lastPressTime[ball] or tick() - lastPressTime[ball] > pressCooldown) then
        Vim:SendKeyEvent(true, Enum.KeyCode.F, false, nil)
        task.wait()
        Vim:SendKeyEvent(false, Enum.KeyCode.F, false, nil)
        
        lastPressTime[ball] = tick()
        isKeyPressed[ball] = true
    elseif lastPressTime[ball] and (predictionTime > ballSpeedThreshold or not realBallAttribute or target ~= player.Name) then
        isKeyPressed[ball] = false
    end
end

local function getAllBalls()
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

printValues()
RunService.RenderStepped:Connect(checkBallsProximity)
