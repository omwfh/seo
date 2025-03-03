local Players : Players = game:GetService("Players")
local Workspace : Workspace = game:GetService("Workspace")
local LocalPlayer : LocalPlayer = Players.LocalPlayer
local CurrentCamera : CurrentCamera = Workspace.CurrentCamera
local Mouse : Mouse = LocalPlayer:GetMouse()

local function GetClosestPlayer(): Player?
    local closestPlayer: Player? = nil
    local shortestDistance: number = math.huge
    
    local players: {Player} = Players:GetPlayers()
    if #players == 0 then return nil end
    
    local localCharacter = LocalPlayer.Character
    if not localCharacter then return nil end
    
    local localRootPart = localCharacter:FindFirstChild("HumanoidRootPart")
    if not localRootPart then return nil end
    
    local localPosition: Vector3 = localRootPart.Position
    
    for _, player in pairs(players) do
        if player ~= LocalPlayer and player.Character then
            local character = player.Character
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            
            if humanoidRootPart then
                local distance: number = (localPosition - humanoidRootPart.Position).Magnitude
                
                if distance < shortestDistance and IsVisible(humanoidRootPart) then
                    shortestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end
    
    return closestPlayer
end

local function GetClosestPlayerToCursor(x: number, y: number): Player?
    local closestPlayer: Player? = nil
    local shortestDistance: number = math.huge

    for _, player: Player in Players:GetPlayers() do
        if player ~= LocalPlayer and player.Character then
            local humanoid: Humanoid? = player.Character:FindFirstChild("Humanoid")
            local rootPart: BasePart? = player.Character:FindFirstChild("HumanoidRootPart")
            local torso: BasePart? = player.Character:FindFirstChild("Torso")
            
            if humanoid and humanoid.Health > 0 and rootPart and torso then
                local screenPosition: Vector3 = CurrentCamera:WorldToViewportPoint(rootPart.Position)
                local distance: number = (Vector2.new(screenPosition.X, screenPosition.Y) - Vector2.new(x, y)).Magnitude
                
                if distance < shortestDistance then
                    closestPlayer = player
                    shortestDistance = distance
                end
            end
        end
    end
    
    return closestPlayer
end

local function IsVisible(target: BasePart): boolean
    local origin: Vector3 = CurrentCamera.CFrame.Position
    local direction: Vector3 = (target.Position - origin).Unit * (target.Position - origin).Magnitude
    local raycastParams: RaycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    
    local result: RaycastResult? = Workspace:Raycast(origin, direction, raycastParams)
    return result == nil or result.Instance == target
end

local mt = getrawmetatable(game)
local oldIndex = mt.__index
local oldNamecall = mt.__namecall

if setreadonly then setreadonly(mt, false) else make_writeable(mt, true) end

local newClose = newcclosure or function(f: (...any) -> any): (...any) -> any return f end

mt.__index = newClose(function(t: any, k: string)
    if not checkcaller() and t == mouse and tostring(k) == "X" and string.find(getfenv(2).script.Name, "Client") and getClosestPlayerToCursor() then
        local closest = getClosestPlayerToCursor(oldIndex(t, k), oldIndex(t, "Y")).Character.Head
        if IsVisible(closest) then
            local pos = currentCamera:WorldToScreenPoint(closest.Position)
            return pos.X
        end
    end
    
    if not checkcaller() and t == mouse and tostring(k) == "Y" and string.find(getfenv(2).script.Name, "Client") and getClosestPlayerToCursor() then
        local closest = getClosestPlayerToCursor(oldIndex(t, "X"), oldIndex(t, k)).Character.Head
        if IsVisible(closest) then
            local pos = currentCamera:WorldToScreenPoint(closest.Position)
            return pos.Y
        end
    end
    
    if t == mouse and tostring(k) == "Hit" and string.find(getfenv(2).script.Name, "Client") and getClosestPlayerToCursor() then
        local closest = getClosestPlayerToCursor(mouse.X, mouse.Y).Character.Head
        if IsVisible(closest) then
            return closest.CFrame
        end
    end
    
    return oldIndex(t, k)
end)

mt.__namecall = newClose(function(object, ...)
    local NamecallMethod = getnamecallmethod()
    local Arguments = {...}

    if tostring(NamecallMethod) == "FindPartOnRayWithIgnoreList" then
        local ClosestPlayer = GetClosestPlayer()
        
        if ClosestPlayer and ClosestPlayer.Character and IsVisible(ClosestPlayer.Character.Head) then
            Arguments[1] = Ray.new(Camera.CFrame.Position, (ClosestPlayer.Character.Head.Position - Camera.CFrame.Position).Unit * (Camera.CFrame.Position - ClosestPlayer.Character.Head.Position).Magnitude)
        end
    end

    return oldNamecall(object, unpack(Arguments))
end)
if setreadonly then setreadonly(mt, true) else make_writeable(mt, false) end
