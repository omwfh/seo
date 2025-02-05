_G.ShowFov = true
_G.Fov = 100
_G.Sides = 100
_G.HitChance = 100
_G.TargetPart = {
    "Head",
    "HumanoidRootPart",
    "UpperTorso",
    "LowerTorso"
}

local Aiming = loadstring(game:HttpGet("https://raw.githubusercontent.com/omwfh/seo/refs/heads/main/Packages/Modules/Aiming.lua"))()

local Workspace: Workspace = game:GetService("Workspace")
local Players: Players = game:GetService("Players")
local RunService: RunService = game:GetService("RunService")
local UserInputService: UserInputService = game:GetService("UserInputService")
local StarterGui: StarterGui = game:GetService("StarterGui")
local StatsService: Stats = game:GetService("Stats")

local LocalPlayer: Player = Players.LocalPlayer
local Mouse: Mouse = LocalPlayer:GetMouse()
local Camera: Camera = Workspace.CurrentCamera

getgenv().DaHoodSettings = {
    SilentAim = true,
    AimLock = true,
    Prediction = 0.1,
    Resolver = true,
    ResolverStrength = 0.2
}

local PingSamples: {number} = {}
local MaxSamples: number = 10

local function GetPlayerPing(): number
    return StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()
end

local function CalculateAccuratePrediction(): number
    local Ping: number = GetPlayerPing()
    
    table.insert(PingSamples, Ping)
    if #PingSamples > MaxSamples then
        table.remove(PingSamples, 1)
    end

    local Sum: number = 0
    for _, Value: number in ipairs(PingSamples) do
        Sum = Sum + Value
    end
    local AveragePing: number = Sum / #PingSamples

    if AveragePing <= 30 then
        return 0.045
    elseif AveragePing <= 50 then
        return 0.065
    elseif AveragePing <= 70 then
        return 0.085
    elseif AveragePing <= 90 then
        return 0.105
    elseif AveragePing <= 110 then
        return 0.125
    else
        return 0.15
    end
end

local function ResolveTarget(TargetPart: BasePart): CFrame
    if not getgenv().DaHoodSettings.Resolver then
        return TargetPart.CFrame
    end
    return TargetPart.CFrame + TargetPart.Velocity * getgenv().DaHoodSettings.ResolverStrength
end

RunService.Heartbeat:Connect(function()
    getgenv().DaHoodSettings.Prediction = CalculateAccuratePrediction()
end)

Aiming.TeamCheck(false)

Aiming.Check = function(): boolean
    if not (Aiming.Enabled and Aiming.Selected ~= LocalPlayer and Aiming.SelectedPart) then
        return false
    end

    local SelectedCharacter: Model? = Aiming.Character(Aiming.Selected)
    if not SelectedCharacter then return false end

    local BodyEffects: Instance? = SelectedCharacter:FindFirstChild("BodyEffects")
    if not BodyEffects then return false end

    local KnockedOut: BoolValue? = BodyEffects:FindFirstChild("K.O")
    local IsGrabbed: boolean = SelectedCharacter:FindFirstChild("GRABBING_CONSTRAINT") ~= nil

    return not (KnockedOut and KnockedOut.Value or IsGrabbed)
end

local OldIndex
OldIndex = hookmetamethod(game, "__index", function(Object: Instance, Property: string)
    if Object:IsA("Mouse") and (Property == "Hit" or Property == "Target") and Aiming.Check() then
        local TargetPart: BasePart = Aiming.SelectedPart
        if getgenv().DaHoodSettings.SilentAim and (Property == "Hit" or Property == "Target") then
            local PredictedPosition: CFrame = ResolveTarget(TargetPart) + TargetPart.Velocity * getgenv().DaHoodSettings.Prediction
            return Property == "Hit" and PredictedPosition or TargetPart
        end
    end
    return OldIndex(Object, Property)
end)
