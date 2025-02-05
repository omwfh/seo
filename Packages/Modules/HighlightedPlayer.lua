local createElement = loadstring(game:HttpGet("https://raw.githubusercontent.com/omwfh/seo/refs/heads/main/Packages/Modules/Elements.lua"))()
local FriendLocator = {}
FriendLocator.__index = FriendLocator

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

function FriendLocator.new(userId)
    local self = setmetatable({}, FriendLocator)
    self.userId = userId
    self.friend = Players:GetPlayerByUserId(userId)
    self.highlight = nil
    self:SetupESP()
    self:StartTracking()
    return self
end

function FriendLocator:SetupESP()
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

function FriendLocator:StartTracking()
    RunService.RenderStepped:Connect(function()
        if not self.friend or not self.friend.Character then
            self:Destroy()
            return
        end

        local rootPart = self.friend.Character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end

        local distance = (LocalPlayer.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
        self:UpdateOutlineColor(distance)
    end)
end

function FriendLocator:UpdateOutlineColor(distance)
    local ratio = 1 / (1 + math.exp(-0.02 * (distance - 50)))
    local color = Color3.new(1 - ratio, ratio, 0)
    self.highlight.OutlineColor = color
end

function FriendLocator:Destroy()
    if self.highlight then
        self.highlight:Destroy()
        self.highlight = nil
    end
end

return FriendLocator
