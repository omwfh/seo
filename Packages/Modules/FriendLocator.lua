local createElement = loadstring(game:HttpGet("https://raw.githubusercontent.com/omwfh/seo/refs/heads/main/Packages/Modules/Elements.lua"))()
local FriendLocator = {}
FriendLocator.__index = FriendLocator

local Players: Players = game:GetService("Players")
local RunService: RunService = game:GetService("RunService")
local TweenService: TweenService = game:GetService("TweenService")
local UserInputService: UserInputService = game:GetService("UserInputService")
local LocalPlayer: Player = Players.LocalPlayer

getgenv().FriendLocatorEnabled = true
getgenv().FriendLocatorKeybind = Enum.KeyCode.RightBracket

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
    if not gameProcessed and input.KeyCode == getgenv().FriendLocatorKeybind then
        getgenv().FriendLocatorEnabled = not getgenv().FriendLocatorEnabled
    end
end)

function FriendLocator.new(userId: number): FriendLocator
    local self = setmetatable({}, FriendLocator)
    self.userId = userId
    self.friend = Players:GetPlayerByUserId(userId)
    self.highlight = nil
    self.trackingConnection = nil
    self:StartTracking()
    return self
end

function FriendLocator:SetupESP(): nil
    if not self.friend or not self.friend.Character then return end

    self.highlight = createElement.new("Highlight", {
        Adornee = self.friend.Character,
        Parent = game.CoreGui,
        FillColor = Color3.fromRGB(255, 255, 255),
        FillTransparency = 1,
        OutlineColor = Color3.fromRGB(0, 255, 0),
        OutlineTransparency = 0
    })
end

function FriendLocator:StartTracking(): nil
    self.trackingConnection = RunService.RenderStepped:Connect(function()
        if not getgenv().FriendLocatorEnabled then
            self:Destroy()
            return
        end

        if not self.friend or not self.friend.Character then
            self:Destroy()
            return
        end

        local rootPart: BasePart? = self.friend.Character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end

        local distance: number = (LocalPlayer.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
        self:UpdateESP(distance)
    end)
end

function FriendLocator:UpdateESP(distance: number): nil
    if not self.highlight then
        self:SetupESP()
    end

    local ratio: number = 1 / (1 + math.exp(-0.02 * (distance - 50)))
    local color: Color3 = Color3.new(1 - ratio, ratio, 0)

    local fadeRatio: number = math.clamp((distance - 8.5) / 50, 0, 1)
    local transparency: number = 1 - fadeRatio

    local scaleFactor: number = math.clamp(1 - (distance / 500), 0.5, 1)
    
    self.highlight.OutlineColor = color
    self.highlight.Adornee.Size = Vector3.new(5 * scaleFactor, 5 * scaleFactor, 5 * scaleFactor)

    TweenService:Create(self.highlight, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { 
        OutlineTransparency = transparency, 
        FillTransparency = transparency 
    }):Play()
end

function FriendLocator:Destroy(): nil
    if self.highlight then
        self.highlight:Destroy()
        self.highlight = nil
    end
    if self.trackingConnection then
        self.trackingConnection:Disconnect()
        self.trackingConnection = nil
    end
end

return FriendLocator
