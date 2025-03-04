local Players: Players = game:GetService("Players")
local UserInputService: UserInputService = game:GetService("UserInputService")
local RunService: RunService = game:GetService("RunService")
local Camera: Camera = workspace.CurrentCamera
local TargetsFolder: Folder? = workspace:FindFirstChild("Targets")
local LocalPlayer: Player = Players.LocalPlayer

local AimSmoothness: number = 0.12
local AimKey: Enum.UserInputType = Enum.UserInputType.MouseButton2
local Aiming: boolean = false
local BaseFOV: number = 200
local ShakeIntensity: number = 1
local OffsetStrength: number = 0.15
local VelocityPrediction: number = 0.1

local function getDynamicOffset(target: BasePart): Vector3
    local sizeFactor: number = math.clamp(target.Size.Magnitude / 10, 0.1, 1.5)
    return Vector3.new(
        (math.random() - 0.5) * OffsetStrength * sizeFactor,
        (math.random() - 0.5) * OffsetStrength * sizeFactor,
        0
    )
end

local function getPredictedPosition(target: BasePart): Vector3
    local velocity: Vector3 = target.AssemblyLinearVelocity or Vector3.zero
    return target.Position + (velocity * VelocityPrediction)
end

local function getClosestTarget(): BasePart?
    if not TargetsFolder then return nil end

    local closestTarget: BasePart? = nil
    local shortestDistance: number = math.huge
    local mousePosition: Vector2 = UserInputService:GetMouseLocation()

    for _, target: Instance in ipairs(TargetsFolder:GetChildren()) do
        if target:IsA("BasePart") then
            local screenPosition: Vector3, onScreen: boolean = Camera:WorldToViewportPoint(target.Position)
            if onScreen then
                local distance: number = (Vector2.new(screenPosition.X, screenPosition.Y) - mousePosition).Magnitude
                local sizeFactor: number = math.clamp(target.Size.Magnitude / 5, 0.5, 1.8) -- Scale FOV dynamically

                if distance < shortestDistance and distance < (BaseFOV * sizeFactor) then
                    closestTarget = target
                    shortestDistance = distance
                end
            end
        end
    end

    return closestTarget
end

local function smoothAim(target: BasePart)
    if not target then return end

    local predictedPosition: Vector3 = getPredictedPosition(target)
    local targetPosition: Vector3 = predictedPosition + getDynamicOffset(target)
    local cameraPosition: Vector3 = Camera.CFrame.Position

    local lerpedCFrame: CFrame = Camera.CFrame:Lerp(CFrame.lookAt(cameraPosition, targetPosition), AimSmoothness)

    local shakeFactor: Vector3 = Vector3.new(
        (math.random() - 0.5) * ShakeIntensity,
        (math.random() - 0.5) * ShakeIntensity,
        0
    )
    
    Camera.CFrame = lerpedCFrame * CFrame.new(shakeFactor)
end

local function updateAiming()
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not Aiming then
            connection:Disconnect()
            return
        end

        local target: BasePart? = getClosestTarget()
        if target then
            smoothAim(target)
        end
    end)
end

local function handleAimingInput()
    UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
        if gameProcessed then return end
        if input.UserInputType == AimKey and not Aiming then
            Aiming = true
            updateAiming()
        end
    end)

    UserInputService.InputEnded:Connect(function(input: InputObject)
        if input.UserInputType == AimKey then
            Aiming = false
        end
    end)
end

local function Initiate()
    local success, err = pcall(function()
        if not Players or not UserInputService or not RunService or not Camera then
            error("[ERROR] Required services are missing.")
        end
        if not LocalPlayer then
            error("[ERROR] LocalPlayer is missing.")
        end
        if not workspace:FindFirstChild("Targets") then
            error("[ERROR] 'Targets' folder is missing.")
        end
    end)

    if not success then
        warn("[AIMBOT ERROR]:", err)
        return
    end

    handleAimingInput()
end

Initiate()
