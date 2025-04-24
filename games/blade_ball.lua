setfpscap(240)

local RunService: RunService = game:GetService("RunService")
local Players: Players = game:GetService("Players")
local Workspace: Workspace = game:GetService("Workspace")
local Vim: VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService: UserInputService = game:GetService("UserInputService")

local ballFolder: Folder = Workspace:WaitForChild("Balls")
local trainingFolder: Folder = Workspace:WaitForChild("TrainingBalls")

local pressCooldown: number = 0
local lastPressTime: { [Instance]: number } = {}
local isKeyPressed: { [Instance]: boolean } = {}

local configHighPing: { value1: number, value2: number, value3: number, value4: number } = {
    value1 = 0.108,
    value2 = 0.0066,
    value3 = 0.0108,
    value4 = 0.31
}

local configLowPing: { value1: number, value2: number, value3: number, value4: number } = {
    value1 = 0.105,
    value2 = 0.0063,
    value3 = 0.0105,
    value4 = 0.31
}

local currentConfig = nil
local lastConfigUpdate = tick()
local configUpdateInterval = .2

local function GetBallVelocity(ball: BasePart): Vector3?
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
    local currentVelocity = GetBallVelocity(ball)
    local rtt = ping / 1000
    local direction = currentVelocity.Unit
    
    if direction.X > 0 then
        rtt *= 0.82
    elseif direction.X < 0 then
        rtt *= 1.0
    end

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
        local velocity = GetBallVelocity(ball) + rootPart.Velocity
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

    local velocityFactor = math.pow(GetBallVelocity(ball).magnitude, 1.35) * currentConfig.value2
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
RunService.Heartbeat:Connect(checkBallsProximity)
