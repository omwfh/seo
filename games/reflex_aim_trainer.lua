local Players: Players = game:GetService("Players")
local UserInputService: UserInputService = game:GetService("UserInputService")
local RunService: RunService = game:GetService("RunService")
local TweenService: TweenService = game:GetService("TweenService")
local Camera: Camera = workspace.CurrentCamera
local TargetsFolder: Folder? = workspace:FindFirstChild("Targets")

local LocalPlayer: Player = Players.LocalPlayer

local v1: number = 0.15 -- smoothing
local v2: Enum.UserInputType = Enum.UserInputType.MouseButton2 -- key
local v3: boolean = false -- aiming
local v4: number = 125 -- fov
local v5: number = 4 -- camera shake intensity
local v6: number = 0.15 -- camera shake frequency
local v7: number = 0.25 -- offset
local v8: number = 0.1 -- velocity prediction
local v9: number = 2 -- fov scaling

local function getDynamicOffset(target: BasePart): Vector3
    local sizeFactor: number = math.clamp(target.Size.Magnitude / 10, 0.1, 2)
    return Vector3.new(
        (math.random() - 0.5) * v7 * sizeFactor,
        (math.random() - 0.5) * v7 * sizeFactor,
        (math.random() - 0.5) * v7 * sizeFactor
    )
end

local function getPredictedPosition(target: BasePart): Vector3
    local velocity: Vector3 = target.AssemblyLinearVelocity or Vector3.zero
    return target.Position + (velocity * v8)
end

local function getClosestTarget(): BasePart?
    if not TargetsFolder then return nil end
    
    local closestTarget: BasePart? = nil
    local shortestDistance: number = math.huge
    local mousePosition: Vector2 = UserInputService:GetMouseLocation()

    for _, target: Instance in ipairs(TargetsFolder:GetChildren()) do
        if target:IsA("BasePart") or target:IsA("Part") then
            local screenPosition: Vector3, onScreen: boolean = Camera:WorldToViewportPoint(target.Position)
            
            if onScreen then
                local distance: number = (Vector2.new(screenPosition.X, screenPosition.Y) - mousePosition).Magnitude
                local sizeFactor: number = math.clamp(target.Size.Magnitude / 5, 0.5, v9)

                if distance < shortestDistance and distance < (v4 * sizeFactor) then
                    closestTarget = target
                    shortestDistance = distance
                end
            end
        end
    end

    return closestTarget
end

local function applyCameraShake()
    local baseCFrame: CFrame = Camera.CFrame
    for _ = 1, 5 do
        task.wait(v6)
        local shakeOffset: Vector3 = Vector3.new(
            (math.random() - 0.5) * v5,
            (math.random() - 0.5) * v5,
            0
        )
        Camera.CFrame = baseCFrame * CFrame.new(shakeOffset)
    end
end

local function smoothAim(target: BasePart)
    if not target then return end

    local predictedPosition: Vector3 = getPredictedPosition(target)
    local targetPosition: Vector3 = predictedPosition + getDynamicOffset(target)
    local cameraPosition: Vector3 = Camera.CFrame.Position

    local newCFrame: CFrame = CFrame.lookAt(cameraPosition, targetPosition)
    local tweenInfo: TweenInfo = TweenInfo.new(v1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    local tween = TweenService:Create(Camera, tweenInfo, { CFrame = newCFrame })

    tween:Play()
    applyCameraShake()
end

local function updateAiming()
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not v3 then
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
        if input.UserInputType == v2 and not v3 then
            v3 = true
            updateAiming()
        end
    end)

    UserInputService.InputEnded:Connect(function(input: InputObject)
        if input.UserInputType == v2 then
            v3 = false
        end
    end)
end

local function Initiate()
    local success, err = pcall(function()
        if not Players or not UserInputService or not RunService or not TweenService or not Camera then
            error("[SEO] One or more required services are missing.")
        end
        if not LocalPlayer then
            error("[SEO] LocalPlayer is missing.")
        end
        if not workspace:FindFirstChild("Targets") then
            error("[SEO] 'Targets' folder is missing in workspace.")
        end
    end)

    if not success then
        warn("[SEO ERROR]:", err)
        return
    end

    handleAimingInput()
end

Initiate()
