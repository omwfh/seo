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

local function ResolveVelocity(ball: BasePart, ping: number): Vector3
    local rtt = ping / 1000
    
    local gravity = Vector3.new(0, -Workspace.Gravity, 0)
    local airDensity = 1.225
    local dragCoefficient = 0.47
    local ballRadius = ball.Size.magnitude / 2
    local crossSectionalArea = math.pi * (ballRadius ^ 2)
   
    local velocity = GetBallVelocity(ball) or Vector3.zero
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
    local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return math.huge end

    local ping = GetPlayerPing() / 1000
    UpdateConfigBasedOnPing(ping * 1000)

    local distance = (ball.Position - rootPart.Position).Magnitude
    local pingCompensation = ping * 1.78

    local baseThreshold = currentConfig.value1 + pingCompensation
    local velocityFactor = math.pow(ball.Velocity.magnitude, 1.3) * currentConfig.value2
    local distanceFactor = distance * currentConfig.value3

    return math.max(baseThreshold, currentConfig.value4 - velocityFactor - distanceFactor)
end

local function CheckProximityToPlayer(ball: BasePart, player: Player)
    local predictionTime = CalculatePredictionTime(ball, player)
    local realBallAttribute = ball:GetAttribute("realBall")
    local target = ball:GetAttribute("target")

    local ballSpeedThreshold = CalculateThreshold(ball, player)
    local shouldPress = predictionTime <= ballSpeedThreshold and realBallAttribute and target == player.Name

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
