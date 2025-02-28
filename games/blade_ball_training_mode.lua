setfpscap(240)

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Vim = game:GetService("VirtualInputManager")
local Stats = game:GetService("Stats")

local ballFolder = Workspace:WaitForChild("Balls")
local trainingFolder = Workspace:WaitForChild("TrainingBalls")

local pressCooldown = 0
local lastPressTime = {}
local isKeyPressed = {}

local Configs = {
    HighPing = {
        value1 = 0.107,
        value2 = 0.0065,
        value3 = 0.0115,
        value4 = 0.29
    },
    
    LowPing = {
        value1 = 0.107,
        value2 = 0.0058,
        value3 = 0.01,
        value4 = 0.31
    }
}

local currentConfig = nil
local lastConfigUpdate = tick()
local configUpdateInterval = 0.2

local kalmanData = {}

local function GetPlayerPing(): number
    local stats: Stats = game:GetService("Stats")
	local networkStats: NetworkStats = stats.Network
	return networkStats.ServerStatsItem["Data Ping"]:GetValue()
end

local function UpdateConfigBasedOnPing(ping: number)
    if tick() - lastConfigUpdate > configUpdateInterval then
        currentConfig = ping > 100 and Configs.HighPing or Configs.LowPing
        lastConfigUpdate = tick()
    end
end

currentConfig = (function()
    local initialPing = GetPlayerPing()
    if initialPing > 100 then
        return Configs.HighPing
    else
        return Configs.LowPing
    end
end)()

local function GetBallVelocity(ball: BasePart): Vector3?
    if not ball then return nil end

    local success, velocity = pcall(function()
        return ball.AssemblyLinearVelocity
    end)
    if success and typeof(velocity) == "Vector3" then
        return velocity
    end

    local vectorVelocity: Vector3Value? = ball:FindFirstChild("VectorVelocity")
   
    if vectorVelocity and vectorVelocity:IsA("Vector3Value") then
        return vectorVelocity.Value
    end

    local zoomies: Vector3Value? = ball:FindFirstChild("zoomies")
    if zoomies and zoomies:IsA("Vector3Value") then
        return zoomies.Value
    end

    return ball.Velocity
end

local function KalmanPredict(ball: BasePart, dt: number): Vector3
    if not ball then return Vector3.zero end

    if not kalmanData[ball] then
        local baseError = math.abs(currentConfig.value1) * 10
        local processNoiseScale = math.sqrt(currentConfig.value2) * 0.1
        local measurementNoiseScale = math.log(currentConfig.value3 + 1) * 0.05

        kalmanData[ball] = {
            predictedVelocity = GetBallVelocity(ball) or Vector3.zero,
            estimatedError = Vector3.new(baseError, baseError, baseError),
            processNoise = Vector3.new(processNoiseScale, processNoiseScale, processNoiseScale),
            measurementNoise = Vector3.new(measurementNoiseScale, measurementNoiseScale, measurementNoiseScale)
        }
    end

    local data = kalmanData[ball]
    local measuredVelocity = GetBallVelocity(ball) or Vector3.zero

    local kalmanGain = data.estimatedError / (data.estimatedError + data.measurementNoise)

    data.predictedVelocity = data.predictedVelocity + kalmanGain * (measuredVelocity - data.predictedVelocity)

    data.estimatedError = (Vector3.new(1, 1, 1) - kalmanGain) * data.estimatedError + data.processNoise

    local acceleration = (measuredVelocity - data.predictedVelocity) / dt
    local predictedVelocity = data.predictedVelocity + acceleration * dt

    return predictedVelocity
end

local function ResolveVelocity(ball: BasePart, ping: number): Vector3
    local rtt = ping / 1000
    local dt = RunService.Heartbeat:Wait()

    local gravity = Vector3.new(0, -Workspace.Gravity, 0)
    local airDensity = 1.225
    local dragCoefficient = 0.47
    local ballRadius = ball.Size.magnitude / 2
    local crossSectionalArea = math.pi * (ballRadius ^ 2)

    local velocity = KalmanPredict(ball, dt)
    local speed = velocity.Magnitude
    local direction = speed > 0 and velocity.Unit or Vector3.zero

    local dragForceMagnitude = 0.5 * airDensity * (speed ^ 2) * dragCoefficient * crossSectionalArea
    local dragForce = -direction * dragForceMagnitude

    local mass = ball:GetMass()
    local acceleration = (dragForce / mass) + gravity

    local predictedVelocity = velocity + (acceleration * rtt)
    local predictedPosition = ball.Position + (velocity * rtt) + (0.5 * acceleration * (rtt ^ 2))

    return predictedPosition
end

local function CalculatePredictionTime(ball: BasePart, player: Player): number
    local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return math.huge end

    local ping = GetPlayerPing()
    UpdateConfigBasedOnPing(ping)

    local predictedPosition = ResolveVelocity(ball, ping)
    local relativePosition = predictedPosition - rootPart.Position

    local ballVelocity = GetBallVelocity(ball) or Vector3.zero
    local playerVelocity = rootPart.Velocity
    local relativeVelocity = ballVelocity - playerVelocity

    local gravity = Vector3.new(0, -Workspace.Gravity, 0)
    local ballRadius = ball.Size.magnitude / 2
    local distance = relativePosition.Magnitude
    local speed = relativeVelocity.Magnitude
    local direction = speed > 0 and relativeVelocity.Unit or Vector3.zero

    local verticalVelocity = relativeVelocity.Y
    local initialHeightDifference = relativePosition.Y
    local a = 0.5 * gravity.Y
    local b = verticalVelocity
    local c = -initialHeightDifference

    local discriminant = (b * b) - (4 * a * c)
    local timeToImpact

    if discriminant >= 0 then
        local sqrtD = math.sqrt(discriminant)
        local t1 = (-b + sqrtD) / (2 * a)
        local t2 = (-b - sqrtD) / (2 * a)

        if t1 > 0 and t2 > 0 then
            timeToImpact = math.min(t1, t2)
        elseif t1 > 0 then
            timeToImpact = t1
        elseif t2 > 0 then
            timeToImpact = t2
        else
            return math.huge
        end
    else
        return math.huge
    end

    local airDensity = 1.225
    local dragCoefficient = 0.47
    local crossSectionalArea = math.pi * (ballRadius ^ 2)
    local dragForce = 0.5 * airDensity * speed^2 * dragCoefficient * crossSectionalArea
    local dragEffect = dragForce / ball:GetMass()

    timeToImpact = timeToImpact * (1 + dragEffect)

    return timeToImpact
end

local function CalculateThreshold(ball: BasePart, player: Player): number
    local rootPart: BasePart? = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return math.huge end

    local ping: number = GetPlayerPing() / 1000
    UpdateConfigBasedOnPing(ping * 1000)

    local distance: number = (ball.Position - rootPart.Position).Magnitude
    local velocity: number = GetBallVelocity(ball).Magnitude

    local logDistanceFactor: number = math.log(distance + 1) * currentConfig.value3

    local velocityFactor: number = math.sqrt(math.abs(velocity)) * currentConfig.value2

    local velocityScalingFactor: number = math.tanh(velocity / 50) * 0.2

    local mass: number = ball:GetMass()
    local kineticEnergy: number = 0.5 * mass * (velocity ^ 2)
    local kineticEnergyFactor: number = kineticEnergy / (mass + 1) * 0.01

    local pingCompensation: number = ping * 1.78
    local adaptivePingFactor: number = math.max(0.5, 1 - math.exp(-ping * 10))

    local baseThreshold: number = (currentConfig.value1 + pingCompensation) * adaptivePingFactor

    local threshold: number = math.max(baseThreshold, currentConfig.value4 - velocityFactor - logDistanceFactor - kineticEnergyFactor - velocityScalingFactor)

    return threshold
end

local function CheckProximityToPlayer(ball: BasePart, player: Player): nil
    local predictionTime = CalculatePredictionTime(ball, player)
    local realBallAttribute = ball:GetAttribute("realBall")
    local target = ball:GetAttribute("target")

    local ballSpeedThreshold = CalculateThreshold(ball, player)
    
    local velocity = GetBallVelocity(ball) or Vector3.zero
    local speed = velocity.Magnitude
    local dynamicAdjustment = math.tanh(speed / 80) * 0.15

    local shouldPress = predictionTime <= (ballSpeedThreshold - dynamicAdjustment) and realBallAttribute and target == player.Name

    if shouldPress and not isKeyPressed[ball] and (not lastPressTime[ball] or tick() - lastPressTime[ball] > pressCooldown) then
        Vim:SendKeyEvent(true, Enum.KeyCode.F, false, nil)
        Vim:SendKeyEvent(false, Enum.KeyCode.F, false, nil)

        lastPressTime[ball] = tick()
        isKeyPressed[ball] = true
    elseif lastPressTime[ball] and (not shouldPress) then
        isKeyPressed[ball] = false
    end
end

local function GetAllBalls(): {BasePart}
    local allBalls = {}

    for _, obj in ipairs({ ballFolder, trainingFolder }) do
        for _, ball in ipairs(obj:GetChildren()) do
            table.insert(allBalls, ball)
        end
    end
    return allBalls
end

local function CheckBallsProximity(): nil
    local player: Player? = Players.LocalPlayer
    local character: Model? = player and player.Character

    if not character then
        isKeyPressed = {}
        return
    end

    if player and player.Character then
        for _, ball in ipairs(GetAllBalls()) do
            CheckProximityToPlayer(ball, player)
        end
    end
end

RunService.Heartbeat:Connect(CheckBallsProximity)
