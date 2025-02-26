setfpscap(240)

local RunService: RunService = game:GetService("RunService")
local Players: Players = game:GetService("Players")
local Workspace: Workspace = game:GetService("Workspace")
local Vim: VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService: UserInputService = game:GetService("UserInputService")

local ballFolder: Folder = Workspace:WaitForChild("Balls")
local trainingFolder: Folder = Workspace:WaitForChild("TrainingBalls")
local aliveFolder: Folder? = Workspace:FindFirstChild("Alive")

local pressCooldown: number = 0
local lastPressTime: { [Instance]: number } = {}
local isKeyPressed: { [Instance]: boolean } = {}

local configHighPing: { value1: number, value2: number, value3: number, value4: number } = {
	value1 = 0.106,
	value2 = 0.0063,
	value3 = 0.0108,
	value4 = 0.3
}

local configLowPing: { value1: number, value2: number, value3: number, value4: number } = {
	value1 = 0.108,
	value2 = 0.0056,
	value3 = 0.012,
	value4 = 0.33
}

local specifiedPlayers: { string } = { "", "" }
local ignoredUntil: { [BasePart]: number } = {}
local ignoredBalls: { [BasePart]: boolean } = {}
local peakTracker: { [BasePart]: number } = {}
local parryCount: { [BasePart]: number } = {}

local lastBallSpawnTime: number = 0
local baseValue1: number = configLowPing.value1
local originalValue2: number = configLowPing.value2
local originalValue3: number = configLowPing.value3

local angleDifferences: { number } = {}
local maxStoredAngles: number = 7
local baseCurveThreshold: number = math.rad(12)
local previousVelocity: Vector3? = nil
local accelerationThreshold: number = 7

local currentConfig: { value1: number, value2: number, value3: number, value4: number } = configLowPing
local lastConfigUpdate: number = tick()
local configUpdateInterval: number = 0.2

local startTime: number = tick()
local lastPrintTime: number = tick()
local printInterval: number = 180

local trackedBall: BasePart? = nil

local autoParryEnabled: boolean = true
local checkBallsConnection: RBXScriptConnection?

local function PrintStatus(): nil
    local elapsedTime: number = tick() - startTime
    local minutes: number = math.floor(elapsedTime / 60)
    local seconds: number = math.floor(elapsedTime % 60)

    print(string.format("[SEO] Running for %02d:%02d (MM:SS)", minutes, seconds))
end

local function ResetConfigForNewBall(): nil
	lastBallSpawnTime = tick()
	currentConfig = currentConfig or configLowPing
	currentConfig.value1 = baseValue1
	currentConfig.value2 = originalValue2
	currentConfig.value3 = originalValue3
	peakTracker = {}
	parryCount = {}
end

local function GetDynamicCurveThreshold(speed: number, parryCount: number): number
	local baseThreshold: number = baseCurveThreshold

	if speed > 55 then
		local factor: number = math.clamp(1 - ((speed - 55) / 180), 0.4, 1)
		baseThreshold = baseThreshold * factor
	end

	local parryAdjustment: number = math.clamp(1 - (parryCount * 0.02), 0.5, 1)

	return baseThreshold * parryAdjustment
end

local function UpdateAngleDifference(currentVelocity: Vector3): number
	local angleDiff: number = 0

	if previousVelocity then
		local magProduct: number = currentVelocity.Magnitude * previousVelocity.Magnitude

		if magProduct > 0 then
			local dotVal: number = currentVelocity:Dot(previousVelocity) / magProduct
			dotVal = math.clamp(dotVal, -1, 1)
			angleDiff = math.acos(dotVal)
		end
	end

	previousVelocity = currentVelocity
	table.insert(angleDifferences, angleDiff)

	if #angleDifferences > maxStoredAngles then
		table.remove(angleDifferences, 1)
	end

	return angleDiff
end

local function IsAccelerationHigh(currentVelocity: Vector3): boolean
	local accDiff: number = 0

	if previousVelocity then
		accDiff = math.abs(currentVelocity.Magnitude - previousVelocity.Magnitude)
	end

	local dynamicAccelerationThreshold: number = math.clamp(5 + (currentVelocity.Magnitude / 15), 5, 15)

	if accDiff > dynamicAccelerationThreshold then
		return true
	end

	return false
end

local function IsBallCurving(ball: BasePart, currentVelocity: Vector3): boolean
	if not ball then return false end

	if IsAccelerationHigh(currentVelocity) then
		return true
	end

	local currentAngleDiff: number = UpdateAngleDifference(currentVelocity)
	local sum: number = 0

	for _, angle: number in ipairs(angleDifferences) do
		sum = sum + angle
	end

	local averageAngle: number = (#angleDifferences > 0) and (sum / #angleDifferences) or 0
	local parryCountForBall: number = parryCount[ball] or 0
	local dynamicThreshold: number = GetDynamicCurveThreshold(currentVelocity.Magnitude, parryCountForBall)

	return averageAngle > dynamicThreshold
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

local function GetPlayerPing(): number
	local stats: Stats = game:GetService("Stats")
	local networkStats: NetworkStats = stats.Network
	return networkStats.ServerStatsItem["Data Ping"]:GetValue()
end

local function IgnoreBallTemporarily(ball: BasePart)
	ignoredBalls[ball] = true

	local sfx: Sound? = ball:FindFirstChild("sfx") :: Sound?

	if sfx and sfx.SoundId == "rbxassetid://18473465414" then
		local soundFinished = false
		local connection

		connection = sfx.Ended:Connect(function()
			if not soundFinished then
				soundFinished = true
				ignoredBalls[ball] = nil
				if connection then
					connection:Disconnect()
				end
			end
		end)

		task.delay(1.62, function()
			if not soundFinished then
				soundFinished = true
				ignoredBalls[ball] = nil
				if connection then
					connection:Disconnect()
				end
			end
		end)
	else
		task.delay(1.62, function()
			ignoredBalls[ball] = nil
		end)
	end
end

local function GetClosestPlayerDistance(ball: BasePart): number?
	local player: Player = Players.LocalPlayer
	local character: Model? = player and player.Character
	if not character then return nil end

	local rootPart: BasePart? = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return nil end

	local closestDistance: number? = nil

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Character then
			local otherRoot: BasePart? = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
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

local function TrackBallVelocity(ball: BasePart)
    local velocity = GetBallVelocity(ball)
    if not velocity then return end

    local currentSpeed = velocity.Magnitude
    local lastSpeed = peakTracker[ball] or currentSpeed
    local ping = GetPlayerPing() / 1000

    local velocityFactor = math.min(velocity.Magnitude * 0.00002, 0.002)
    local pingFactor = math.min(ping * 0.0003, 0.002)
    local closestDistance = GetClosestPlayerDistance(ball)

    currentConfig.value1 = baseValue1
    currentConfig.value2 = originalValue2
    currentConfig.value3 = originalValue3

    if closestDistance then
        if closestDistance <= 8.45 then
            currentConfig.value1 = math.min(0.001, currentConfig.value1 - (0.0005 + velocityFactor + pingFactor))
            currentConfig.value2 = math.min(0.0005, currentConfig.value2 - 0.0003)
            currentConfig.value3 = math.min(0.0005, currentConfig.value3 - 0.003)
        elseif closestDistance <= 15 then
            currentConfig.value1 = math.min(0.1, currentConfig.value1 - (0.00013 + velocityFactor + pingFactor))
            currentConfig.value2 = math.min(0.005, currentConfig.value2 - 0.000085)
            currentConfig.value3 = math.min(0.005, currentConfig.value3 - 0.00085)
        end
    end

    currentConfig.value1 = math.max(baseValue1, currentConfig.value1)
    currentConfig.value2 = math.max(0, currentConfig.value2)
    currentConfig.value3 = math.max(0, currentConfig.value3)

    peakTracker[ball] = currentSpeed
end

local function UpdateConfigBasedOnPing(ping: number): nil
	if tick() - lastConfigUpdate > configUpdateInterval then
		currentConfig = (ping > 100) and configHighPing or configLowPing
		lastConfigUpdate = tick()
	end
end

currentConfig = (function(): { value1: number, value2: number, value3: number, value4: number }
	local initialPing: number = GetPlayerPing()
	return (initialPing > 100) and configHighPing or configLowPing
end)()

local function ResolveVelocity(ball: BasePart, ping: number): Vector3
	local currentPosition: Vector3 = ball.Position
	local currentVelocity: Vector3 = ball.Velocity
	local rtt: number = ping / 1000
	return currentPosition + (currentVelocity * rtt)
end

local function CalculatePredictionTime(ball: BasePart, player: Player): number
	local character: Model? = player.Character
	local rootPart: BasePart? = character and character:FindFirstChild("HumanoidRootPart") :: BasePart

	if rootPart then
		local ping: number = GetPlayerPing()
		UpdateConfigBasedOnPing(ping)

		local predictedPosition: Vector3 = ResolveVelocity(ball, ping)
		local relativePosition: Vector3 = predictedPosition - rootPart.Position
		local velocity: Vector3 = ball.Velocity + rootPart.Velocity
		local a: number = ball.Size.Magnitude / 2
		local b: number = relativePosition.Magnitude
		local c: number = math.sqrt((a * a) + (b * b))

		return (c - a) / velocity.Magnitude
	end

	return math.huge
end

local function CalculateThreshold(ball: BasePart, player: Player): number
	local character: Model? = player.Character
	local rootPart: BasePart? = character and character:FindFirstChild("HumanoidRootPart") :: BasePart
	if not rootPart then return math.huge end

	local ping: number = GetPlayerPing() / 1000
	UpdateConfigBasedOnPing(ping * 1000)
	local distance: number = (ball.Position - rootPart.Position).Magnitude

	local pingCompensation: number = ping * 1.65
	local baseThreshold: number = currentConfig.value1 + pingCompensation

	local velocityFactor: number = math.pow(ball.Velocity.Magnitude, 1.3) * currentConfig.value2
	local distanceFactor: number = distance * currentConfig.value3

	return math.max(baseThreshold, currentConfig.value4 - velocityFactor - distanceFactor)
end

local function CheckProximityToPlayer(ball: BasePart, player: Player): boolean
    local character = player.Character
    if not character then return false end

    local rootPart: BasePart? = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end

    local predictionTime: number = CalculatePredictionTime(ball, player)
    local ballSpeedThreshold: number = CalculateThreshold(ball, player)
    local ballVelocity: Vector3? = GetBallVelocity(ball)

    if not ballVelocity then return false end

    if predictionTime <= ballSpeedThreshold and tick() - lastPressTime > pressCooldown then
        Vim:SendKeyEvent(true, Enum.KeyCode.F, false, nil)
        Vim:SendKeyEvent(false, Enum.KeyCode.F, false, nil)
        lastPressTime = tick()
        return true
    end

    local reactionTime = (ball.Position - rootPart.Position).Magnitude / ballVelocity.Magnitude
    
	if reactionTime < 0.11 and tick() - lastPressTime > pressCooldown then
        Vim:SendKeyEvent(true, Enum.KeyCode.F, false, nil)
        Vim:SendKeyEvent(false, Enum.KeyCode.F, false, nil)
        lastPressTime = tick()
        return true
    end

    return false
end

local autoParryEnabled: boolean = true
local checkBallsConnection: RBXScriptConnection? = RunService.Heartbeat:Connect(CheckBallsProximity)

local function GetAllBalls(): { BasePart }
	local allBalls: { BasePart } = {}

	for _, obj: Instance in ipairs(Workspace:GetChildren()) do
		if obj == ballFolder then
			for _, ball: Instance in ipairs(ballFolder:GetChildren()) do
				if ball:IsA("BasePart") then
					table.insert(allBalls, ball)
				end
			end
		elseif obj == trainingFolder then
			for _, trainingBall: Instance in ipairs(trainingFolder:GetChildren()) do
				if trainingBall:IsA("BasePart") then
					table.insert(allBalls, trainingBall)
				end
			end
		end
	end

	return allBalls
end

local function UpdateTrackedBall(): nil
	local allBalls: { BasePart } = GetAllBalls()
	trackedBall = nil

	for _, ball: BasePart in ipairs(allBalls) do
		local sfx: Sound? = ball:FindFirstChild("sfx") :: Sound?

		if sfx and sfx.SoundId == "rbxassetid://18473465414" then
			trackedBall = ball
			break
		end
	end
end

local function ShouldSkipParry(ball: BasePart): boolean
    if not ball then return false end

    local velocity: Vector3? = GetBallVelocity(ball)
    if not velocity then return false end

    if IsBallCurving(ball, velocity) then
		print("ball curved")
        return false
    end

    if math.abs(velocity.X - 704.603) < 0.01 
        and math.abs(velocity.Y - 46.323) < 0.01 
        and math.abs(velocity.Z - 164.818) < 0.01 then

        ignoredUntil[ball] = tick() + 1.62
        return true
    end
    
	if velocity.X > 200 and velocity.Magnitude > 200 then
		local sfx: Sound? = ball:FindFirstChild("sfx")
		
		if not sfx or sfx.SoundId ~= "rbxassetid://18473465414" then
			return false
		end

		if ignoredUntil[ball] and tick() < ignoredUntil[ball] then
			return true
		end
	
		ignoredUntil[ball] = tick() + 1.62
		return true
	end

    return false
end

local function CheckBallsProximity(): nil
    if not autoParryEnabled then return end

    local player: Player = Players.LocalPlayer
    local character: Model? = player and player.Character
    if not character then return end

    local rootPart: BasePart? = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local allBalls = GetAllBalls()
    if #allBalls == 0 then return end

    if tick() - lastBallSpawnTime > 1 then
        ResetConfigForNewBall()
    end

    for _, ball: BasePart in ipairs(allBalls) do
        if ignoredBalls[ball] then continue end

        TrackBallVelocity(ball)

        if not ShouldSkipParry(ball) and CheckProximityToPlayer(ball, player) then
            return
        end

        local ballVelocity: Vector3? = GetBallVelocity(ball)
        if ballVelocity and ballVelocity.Magnitude > 50 then
            local timeToImpact = ((ball.Position - rootPart.Position).Magnitude / ballVelocity.Magnitude)

            if timeToImpact < 0.2 and tick() - lastPressTime > pressCooldown then
                Vim:SendKeyEvent(true, Enum.KeyCode.F, false, nil)
                Vim:SendKeyEvent(false, Enum.KeyCode.F, false, nil)
                lastPressTime = tick()
                return
            end
        end
    end
end

local function ToggleAutoParry(state: boolean?)
    if state == nil then
        autoParryEnabled = not autoParryEnabled
    else
        autoParryEnabled = state
    end

    if autoParryEnabled then
        print("[AutoParry] Enabled")

        if checkBallsConnection then
            checkBallsConnection:Disconnect()
        end
        checkBallsConnection = RunService.Heartbeat:Connect(CheckBallsProximity)
    else
        print("[AutoParry] Disabled")

        if checkBallsConnection then
            checkBallsConnection:Disconnect()
            checkBallsConnection = nil
        end
    end
end

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
    if gameProcessed or UserInputService:GetFocusedTextBox() then
        return
    end

    if input.KeyCode == Enum.KeyCode.M then
        ToggleAutoParry()
    end
end)

RunService.Heartbeat:Connect(function()
    if tick() - lastPrintTime >= printInterval then
        PrintStatus()
        lastPrintTime = tick()
    end
end)

PrintStatus()
