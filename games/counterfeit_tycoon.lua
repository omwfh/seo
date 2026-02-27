if not game:IsLoaded() then 
    game.Loaded:Wait() 
end

if _G.FOVCircle then
    _G.FOVCircle:Remove()
end

local Players: Players = game:GetService("Players")
local Workspace: Workspace = game:GetService("Workspace")
local RunService: RunService = game:GetService("RunService")
local UserService: UserService = game:GetService("UserService")
local UserInputService: UserInputService = game:GetService("UserInputService")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

local Camera: Camera = workspace.CurrentCamera

local LocalPlayer: Player = Players.LocalPlayer
local UserInfo = UserService:GetUserInfosByUserIdsAsync({ LocalPlayer.UserId })
local DisplayName: string = UserInfo[1].DisplayName

local ClientVariables = require(LocalPlayer.PlayerScripts.PlayerVariables)

local GunFire: RemoteEvent = ReplicatedStorage:WaitForChild("GunFire") :: RemoteEvent

local TycoonsFolder: Folder = Workspace:WaitForChild("Tycoons")
local BoxDropoffs: Folder = Workspace:WaitForChild("BoxDropoffs")

local PREFIX: string = "/e "

local LocalTycoon: Model? = nil

_G.AimbotEnabled = true
_G.TeamCheck = false
_G.FOVCircle = Drawing.new("Circle")

local FOVCircle = _G.FOVCircle
FOVCircle.Filled = false
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Visible = true
FOVCircle.Radius = 80
FOVCircle.Transparency = 1
FOVCircle.NumSides = 100
FOVCircle.Thickness = 0
FOVCircle.Position = UserInputService:GetMouseLocation()

local FOVVisible: boolean = true

for _, Tycoon: Model in ipairs(TycoonsFolder:GetChildren()) do
    local ClaimPart = Tycoon:WaitForChild("TycoonClaimer")
        :WaitForChild("ClaimTycoonPart")
        :WaitForChild("SurfaceGui")
        :WaitForChild("TextLabel")

    if ClaimPart.Text == DisplayName then
        LocalTycoon = Tycoon
        break
    end
end

if not LocalTycoon then
	warn("no tycoon found for player:", DisplayName)
	return
end

local BoxesFolder: Folder = LocalTycoon:WaitForChild("Boxes"):WaitForChild("FullBoxes")

local TycoonFloor: BasePart = LocalTycoon
    :WaitForChild("TycoonFloor")

local CurrentCar: BasePart = LocalTycoon
    :WaitForChild("Buyables")
    :WaitForChild("Cars")
    :WaitForChild("CurrentCar")

local Colorizer: BasePart = LocalTycoon
    :WaitForChild("Buyables")
    :WaitForChild("Upgraders")
    :WaitForChild("Colorizer1")
    :WaitForChild("UpgradePart")

local Reinforcer: BasePart = LocalTycoon
    :WaitForChild("Buyables")
    :WaitForChild("Upgraders")
    :WaitForChild("Reinforcer1")
    :WaitForChild("UpgradePart")

local ManualButton: BasePart = LocalTycoon
    :WaitForChild("Buyables")
    :WaitForChild("Droppers")
    :WaitForChild("Dropper16")
    :WaitForChild("ButtonPart")

local ManualButton2: BasePart = LocalTycoon
    :WaitForChild("Buyables")
    :WaitForChild("Droppers")
    :WaitForChild("Dropper34")
    :WaitForChild("ButtonPart")

local ManualButton3: BasePart = LocalTycoon
    :WaitForChild("Buyables")
    :WaitForChild("Droppers")
    :WaitForChild("Dropper33")
    :WaitForChild("ButtonPart")

local DropoffPart: BasePart = BoxDropoffs
    :WaitForChild("Dropoff1")
    :WaitForChild("PayPart")

local ClickDetector1: ClickDetector = ManualButton:WaitForChild("ClickDetector")
local ClickDetector2: ClickDetector = ManualButton2:WaitForChild("ClickDetector")
local ClickDetector3: ClickDetector = ManualButton3:WaitForChild("ClickDetector")

local IsHoldingMouse: boolean = false
local Processed: {[Instance]: boolean} = {}
local Processing = false

local function GetPlayerByDisplayName(input: string): Player?
	input = string.lower(input)
	
    local bestMatch: Player? = nil
	for _, player in ipairs(Players:GetPlayers()) do
		local displayName = string.lower(player.DisplayName)

		if displayName == input then
			return player
		end

		if displayName:sub(1, #input) == input then
			bestMatch = player
		end
	end

	return bestMatch
end

local function FindPP(tycoon: Model)
	local Vault = tycoon:FindFirstChild("Vault")
	if Vault and Vault:FindFirstChild("Model") and Vault.Model:FindFirstChild("DoorPart") then
		local DoorPart = Vault.Model.DoorPart
		local ProximityP = DoorPart:FindFirstChildOfClass("ProximityPrompt")
		
		if ProximityP and ProximityP.Enabled and (
			string.find(ProximityP.ActionText:lower(), "rob", 1, true) or
			string.find(ProximityP.ObjectText:lower(), "rob", 1, true)
		) then
			return ProximityP, DoorPart
		end
	end
	
	return nil
end

local function GetTycoonFromPlayer(player: Player): Model?
	for _, Tycoon in ipairs(TycoonsFolder:GetChildren()) do
		
		local claimer = Tycoon:FindFirstChild("TycoonClaimer")
		if not claimer then continue end
		
		local claimPart = claimer:FindFirstChild("ClaimTycoonPart")
		if not claimPart then continue end
		
		local surface = claimPart:FindFirstChild("SurfaceGui")
		if not surface then continue end
		
		local label = surface:FindFirstChild("TextLabel")
		if not label then continue end
		
		if label.Text == player.DisplayName then
			return Tycoon
		end
	end
	
	return nil
end

local function getNetworkOwnedPart(BoxModel: Model): BasePart?
    for _, Descendant in ipairs(BoxModel:GetDescendants()) do
        if Descendant:IsA("BasePart") and isnetworkowner(Descendant) then
            return Descendant
        end
    end
    
    return nil
end

local function processBox(Box: Instance)
    if Processed[Box] then return end
    Processed[Box] = true

    task.wait(3.5)

    fireclickdetector(ClickDetector1)
    fireclickdetector(ClickDetector2)
    fireclickdetector(ClickDetector3)

    local BoxModel: Model? = Box:FindFirstChild("BoxModel")
    if not BoxModel then return end

    local OwnershipPart: BasePart? = getNetworkOwnedPart(BoxModel)
    if not OwnershipPart then return end

    OwnershipPart.CFrame = Colorizer.CFrame
    task.wait(1.5)

    OwnershipPart.CFrame = Reinforcer.CFrame
    task.wait(1.5)

    OwnershipPart.CFrame = DropoffPart.CFrame
end

BoxesFolder.ChildAdded:Connect(function(Box: Instance)
    Box.Destroying:Connect(function()
        Processed[Box] = nil
    end)

    task.defer(processBox, Box)
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	
	if UserInputService:GetFocusedTextBox() then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		IsHoldingMouse = true
	end

	if input.KeyCode == Enum.KeyCode.K then
		FOVVisible = not FOVVisible
		FOVCircle.Visible = FOVVisible
	end

    if input.KeyCode == Enum.KeyCode.L then
	    FOVCircle.Radius = math.min(500, FOVCircle.Radius + 10)
    end
	
	if input.KeyCode == Enum.KeyCode.J then
	    FOVCircle.Radius = math.max(10, FOVCircle.Radius - 10)
    end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		IsHoldingMouse = false
	end
end)

local function getValidTarget(model: Model): (Humanoid?, BasePart?)
	if model:FindFirstChildWhichIsA("ForceField") then
		return nil, nil
	end

	local humanoid: Humanoid? = model:FindFirstChildWhichIsA("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil, nil
	end

	local head: BasePart? = model:FindFirstChild("Head")
	if not head then
		return nil, nil
	end

	return humanoid, head
end

local function isVisible(targetHead: BasePart): boolean
	local origin: Vector3 = Camera.CFrame.Position
	local direction: Vector3 = (targetHead.Position - origin)

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist
	rayParams.FilterDescendantsInstances = {LocalPlayer.Character}

	local result = Workspace:Raycast(origin, direction, rayParams)
	if not result then
		return true
	end

	return result.Instance:IsDescendantOf(targetHead.Parent)
end

local function GetClosestTarget(): BasePart?
	local maxDistance: number = FOVCircle.Radius
	local closestMagnitude: number = maxDistance
	
    local mouseLocation: Vector2 = UserInputService:GetMouseLocation()
	local chosenHead: BasePart? = nil

	for _, player: Player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer then continue end
		if _G.TeamCheck and player.Team == LocalPlayer.Team then continue end

		local character = player.Character
		if not character then continue end

		local _, head = getValidTarget(character)
		if not head then continue end
		if not isVisible(head) then continue end

		local screenPosition, onScreen =
			Camera:WorldToScreenPoint(head.Position)

		if not onScreen then continue end

		local magnitude =
			(mouseLocation - Vector2.new(screenPosition.X, screenPosition.Y)).Magnitude

		if magnitude < closestMagnitude then
			closestMagnitude = magnitude
			chosenHead = head
		end
	end

	return chosenHead
end

local function SetCharacterCollision(character: Model, state: boolean)
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = state
		end
	end
end

local function FireAtNPCs(tool: Tool)
	local tycoon = ClientVariables.Tycoon
	if not tycoon then return end
	
	local npcStuff = tycoon:FindFirstChild("NpcStuff")
	if not npcStuff then return end
	local activeFolder = npcStuff:FindFirstChild("ActiveNpcs")
	if not activeFolder then return end

	for _, npc: Model in ipairs(activeFolder:GetChildren()) do
		local humanoid, head = getValidTarget(npc)
		if humanoid and head then
			GunFire:FireServer(
				tool.Name,
				tool,
				head.Position,
				head.Position,
				head
			)
			return
		end
	end
end

local function FireAtPlayers(tool: Tool)
	if not IsHoldingMouse then
		return
	end

	local chosenHead = GetClosestTarget()
	if not chosenHead then
		return
	end

	GunFire:FireServer(
		tool.Name,
		tool,
		chosenHead.Position,
		chosenHead.Position,
		chosenHead
	)
end

for _, prompt in ipairs(Workspace:GetDescendants()) do
	if prompt:IsA("ProximityPrompt") then
		prompt.PromptButtonHoldBegan:Connect(function()
			if prompt.HoldDuration <= 0 then 
				return 
			end
			
			fireproximityprompt(prompt, 0)
		end)
	end
end

Workspace.DescendantAdded:Connect(function(instance)
	if not instance:IsA("ProximityPrompt") then
		return
	end

	instance.PromptButtonHoldBegan:Connect(function()
		if instance.HoldDuration <= 0 then
			return
		end

		fireproximityprompt(instance, 0)
	end)
end)

RunService.RenderStepped:Connect(function()
	if FOVVisible then
	    FOVCircle.Position = UserInputService:GetMouseLocation()
    end

	if not _G.AimbotEnabled then return end
	local character = LocalPlayer.Character
	if not character then return end

	local tool = character:FindFirstChildWhichIsA("Tool")
	if not tool then return end

	FireAtNPCs(tool)
	FireAtPlayers(tool)
end)

LocalPlayer.Chatted:Connect(function(message: string)
	if message:sub(1, #PREFIX) ~= PREFIX then
		return
	end
	
	local content: string = message:sub(#PREFIX + 1)
    local lowered = string.lower(content)
    
    if lowered == "base" then
		local character: Model? = LocalPlayer.Character
		if not character then return end
		
		local root: BasePart? = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then return end
		
		root.CFrame = TycoonFloor.CFrame * CFrame.new(0, 5, 0)
		return
	end

    if lowered == "car" then
        local firstCar: Model? = nil

        for _, child in ipairs(CurrentCar:GetChildren()) do
            if child:IsA("Model") then
                firstCar = child
                break
            end
        end

        if not firstCar then
            warn("no car model found")
            return
        end

        local seat: VehicleSeat? = firstCar:FindFirstChildWhichIsA("VehicleSeat", true)
        if not seat then
            warn("no seat found in the car")
            return
        end

        local character: Model? = LocalPlayer.Character
        if not character then return end

        local root: BasePart? =
            character:FindFirstChild("HumanoidRootPart") :: BasePart?
        if not root then return end

        root.CFrame = seat.CFrame * CFrame.new(0, 3, 0)
        
        return
    end

    if lowered:sub(1, 3) == "tp " then
        local targetName: string = content:sub(4)
        local target: Player? = GetPlayerByDisplayName(targetName)
        if not target then return end
        
        local targetCharacter: Model? = target.Character
        if not targetCharacter then return end
        
        local targetRoot: BasePart? =
            targetCharacter:FindFirstChild("HumanoidRootPart") :: BasePart?
        if not targetRoot then return end
        
        local character: Model? = LocalPlayer.Character
        if not character then return end
        
        local root: BasePart? =
            character:FindFirstChild("HumanoidRootPart") :: BasePart?
        if not root then return end
        
        root.CFrame = targetRoot.CFrame * CFrame.new(0, 5, 0)
        return
    end

	if lowered:sub(1, 4) == "rob " then
        local targetName: string = content:sub(5)
        local target: Player? = GetPlayerByDisplayName(targetName)
        if not target then return end

        print("target:", target) --// debug

        local tycoon: Model? = GetTycoonFromPlayer(target)
        if not tycoon then return end

        local vault: Instance? = tycoon:FindFirstChild("Vault")
        if not vault then return end

        local model: Instance? = vault:FindFirstChild("Model")
        if not model then return end

        local DoorPart: BasePart? = model:FindFirstChild("DoorPart") :: BasePart?
        if not DoorPart then return end

        local character: Model? = LocalPlayer.Character
        if not character then return end

        local root: BasePart? = character:FindFirstChild("HumanoidRootPart") :: BasePart?
        if not root then return end

        SetCharacterCollision(character, false)
        for _, part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end

        root.CFrame = DoorPart.CFrame * CFrame.new(0, 3, 0)
        
        task.wait(0.1)

        local prompt: ProximityPrompt? = FindPP(tycoon)
        if prompt then
            fireproximityprompt(prompt)
        end

        task.wait(0.5)
        
        root.CFrame = TycoonFloor.CFrame * CFrame.new(0, 5, 0)

        SetCharacterCollision(character, true)
        for _, part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
		return
	end

    if lowered:sub(1, 5) == "kill " then
        local argument: string = string.lower(content:sub(6))
        local Dead: boolean = true

        local character = LocalPlayer.Character
        if not character then return end

        local tool: Tool? = character:FindFirstChildWhichIsA("Tool")
        if not tool then return end

        if argument == "all" then
            task.spawn(function()
                while true do
                    local allDead: boolean = true

                    for _, player: Player in ipairs(Players:GetPlayers()) do
                        if player == LocalPlayer then
                            continue
                        end

                        local targetChar: Model? = player.Character
                        if not targetChar then
                            continue
                        end

                        local humanoid: Humanoid? = targetChar:FindFirstChildWhichIsA("Humanoid")
                        if humanoid and humanoid.Health > 0 then
                            allDead = false

                            local head: BasePart? = targetChar:FindFirstChild("Head")
                            if head then
                                GunFire:FireServer(
                                    tool.Name,
                                    tool,
                                    head.Position,
                                    head.Position,
                                    head
                                )
                            end
                        end
                    end

                    if allDead then
                        print("all dead")
                        break
                    end

                    task.wait(0.1)
                end
            end)

            return
        end

        local target: Player? = GetPlayerByDisplayName(argument)
        if not target then return end
        if target == LocalPlayer then return end

        local targetChar = target.Character
        if not targetChar then return end

        local humanoid = targetChar:FindFirstChildWhichIsA("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end

        local head = targetChar:FindFirstChild("Head")
        if not head then return end

        while task.wait(0.1) do
            local currentChar = target.Character
            if not currentChar then break end

            local currentHumanoid = currentChar:FindFirstChildWhichIsA("Humanoid")
            if not currentHumanoid or currentHumanoid.Health <= 0 then
                print("player dead")
                break
            end

            local head = currentChar:FindFirstChild("Head")
            if head then
                GunFire:FireServer(
                    tool.Name,
                    tool,
                    head.Position,
                    head.Position,
                    head
                )
            end
        end

        return
    end

    if lowered:sub(1, 6) == "clear " then
        local targetName: string = content:sub(7)
        local target: Player? = GetPlayerByDisplayName(targetName)
        if not target then return end

        local tycoon: Model? = GetTycoonFromPlayer(target)
        if not tycoon then
            warn("no tycoon found")
            return
        end

        print("found tycoon:", tycoon and tycoon.Name)

        local npcStuff = tycoon:FindFirstChild("NpcStuff")
        if not npcStuff then return end
        local activeFolder = npcStuff:FindFirstChild("ActiveNpcs")
        if not activeFolder then return end

        print("clearing enemies...")

        task.spawn(function()
            while task.wait(0.1) do
                local character = LocalPlayer.Character
                if not character then break end

                local tool: Tool? = character:FindFirstChildWhichIsA("Tool")
                if not tool then break end

                if #activeFolder:GetChildren() == 0 then
                    print("no active npc")
                    break
                end

                local allDead = true

                for _, npc: Model in ipairs(activeFolder:GetChildren()) do
                    local humanoid, head = getValidTarget(npc)

                    if humanoid and head then
                        allDead = false

                        GunFire:FireServer(
                            tool.Name,
                            tool,
                            head.Position,
                            head.Position,
                            head
                        )
                    end
                end

                if allDead then
                    print("cleared")
                    break
                end
            end
        end)

        return
    end

    if lowered:sub(1, 4) == "vel " then
        local velocityMult = tonumber(content:sub(5))
        if not velocityMult then
            warn("invalid velocity multiplier")
            return
        end

        task.spawn(function()
            while task.wait(0.1) do
                local character = LocalPlayer.Character
                if not character then break end

                local humanoid = character:FindFirstChildWhichIsA("Humanoid")
                if not humanoid then break end

                local seat = humanoid.SeatPart
                if not seat or not seat:IsA("VehicleSeat") then break end

                if not seat:GetAttribute("VelocityBoosted") then
                    break
                end

                local vel = seat.AssemblyLinearVelocity

                seat.AssemblyLinearVelocity =
                    vel * Vector3.new(1 + velocityMult, 1, 1 + velocityMult)
            end
        end)

        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildWhichIsA("Humanoid")
            if humanoid and humanoid.SeatPart and humanoid.SeatPart:IsA("VehicleSeat") then
                humanoid.SeatPart:SetAttribute("VelocityBoosted", true)
            end
        end

        print("velocity boost active:", velocityMult)
        return
    end
end)
