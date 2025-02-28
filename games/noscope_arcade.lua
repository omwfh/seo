getgenv().Settings = {
    Fov = 60,
    FovCircle = false,
    HitChance = 100
}

local Camera: Camera = workspace.CurrentCamera
local Players: Players = game:GetService("Players")
local RunService: RunService = game:GetService("RunService")
local LocalPlayer: Player = Players.LocalPlayer
local Mouse: Mouse = LocalPlayer:GetMouse()

local function InLineOfSight(position: Vector3, ...): boolean
    return #Camera:GetPartsObscuringTarget({position}, {Camera, LocalPlayer.Character, ...}) == 0
end

local function GetClosestTarget(fov: number): Player?
    local closestTarget: Player? = nil
    local shortestDistance: number = math.huge
    
    for _, player: Player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            if InLineOfSight(player.Character.Head.Position, player.Character) then
                local screenPosition, onScreen = Camera:WorldToScreenPoint(player.Character.HumanoidRootPart.Position)
                local distance: number = (Vector2.new(screenPosition.X, screenPosition.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestTarget = player
                end
            end
        end
    end
    
    return closestTarget
end

local function GetNearestHitbox(target: Player): BasePart?
    if not target or not target.Character then return nil end
    
    local hitboxes: {string} = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}
    local closestPart: BasePart? = nil
    local shortestDistance: number = math.huge
    local screenMouse: Vector2 = Vector2.new(Mouse.X, Mouse.Y)
    
    for _, partName: string in pairs(hitboxes) do
        local part: BasePart? = target.Character:FindFirstChild(partName)
        if part then
            local screenPosition, onScreen = Camera:WorldToScreenPoint(part.Position)
            local distance: number = (Vector2.new(screenPosition.X, screenPosition.Y) - screenMouse).Magnitude
            
            if distance < shortestDistance then
                shortestDistance = distance
                closestPart = part
            end
        end
    end
    
    return closestPart
end

local Target: Player?
local CircleInline: Drawing = Drawing.new("Circle")
local CircleOutline: Drawing = Drawing.new("Circle")

RunService.Stepped:Connect(function()
    local viewportSize: Vector2 = Camera.ViewportSize
    local centerX: number, centerY: number = viewportSize.X / 2, viewportSize.Y / 2

    CircleInline.Radius = getgenv().Settings.Fov
    CircleInline.Thickness = 2
    CircleInline.Position = Vector2.new(centerX, centerY)
    CircleInline.Transparency = 1
    CircleInline.Color = Color3.fromRGB(255, 255, 255)
    CircleInline.Visible = getgenv().Settings.FovCircle
    CircleInline.ZIndex = 2

    CircleOutline.Radius = getgenv().Settings.Fov
    CircleOutline.Thickness = 4
    CircleOutline.Position = Vector2.new(centerX, centerY)
    CircleOutline.Transparency = 1
    CircleOutline.Color = Color3.new()
    CircleOutline.Visible = getgenv().Settings.FovCircle
    CircleOutline.ZIndex = 1
    
    Target = GetClosestTarget(getgenv().Settings.Fov)
end)

local OldHook; OldHook = hookmetamethod(game, "__namecall", function(self, ...)
    local args: {any} = {...}
    local method: string = getnamecallmethod()
    
    if not checkcaller() and method == "FireServer" then
        if self.Name == "0+." then
            args[1].MessageWarning = {}
            args[1].MessageError = {}
            args[1].MessageOutput = {}
            args[1].MessageInfo = {}
        elseif self.Name == "RemoteEvent" and args[2] == "Bullet" then
            if Target and Target.Character and Target.Character.Humanoid and Target.Character.Humanoid.Health ~= 0 then
                if math.random(1, 100) <= getgenv().Settings.HitChance then
                    local hitbox: BasePart? = math.random(1, 100) <= 60 and Target.Character.Head or GetNearestHitbox(Target)
                    
                    if hitbox then
                        args[3] = Target.Character
                        args[4] = hitbox
                        args[5] = hitbox.Position
                    end
                end
            end
        end
    end
    
    return OldHook(self, unpack(args))
end)
