local createElement = loadstring(game:HttpGet("https://raw.githubusercontent.com/omwfh/seo/refs/heads/main/Packages/Modules/Elements.lua"))()
local FriendLocator = {}
FriendLocator.__index = FriendLocator

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local THUMBNAIL_URL = "rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"
local MAX_VISIBILITY_DISTANCE = 100
local MIN_VISIBILITY_DISTANCE = 10

function FriendLocator.new(userId)
    local self = setmetatable({}, FriendLocator)
    self.userId = userId
    self.friend = Players:GetPlayerByUserId(userId)
    self.billboardGui = nil
    self.frame = nil
    self.portrait = nil
    self.nameLabel = nil
    self:SetupUI()
    self:StartTracking()
    return self
end

function FriendLocator:SetupUI()
    if not self.friend or not self.friend.Character then return end
    self.billboardGui = createElement.new("BillboardGui", {
        Adornee = self.friend.Character:FindFirstChild("Head"),
        Size = UDim2.new(5, 0, 1.5, 0),
        StudsOffset = Vector3.new(0, 2, 0),
        AlwaysOnTop = true,
        Parent = game.CoreGui
    }, {
        Frame = createElement.new("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 0.5,
            BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        }, {
            Portrait = createElement.new("ImageLabel", {
                Size = UDim2.new(0.8, 0, 0.8, 0),
                Position = UDim2.new(0.1, 0, 0.1, 0),
                Image = string.format(THUMBNAIL_URL, self.userId),
                BackgroundTransparency = 1
            }),
            NameLabel = createElement.new("TextLabel", {
                Size = UDim2.new(1, 0, 0.3, 0),
                Position = UDim2.new(0, 0, 0.85, 0),
                Text = self.friend.DisplayName,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 0,
                Font = Enum.Font.SourceSansBold,
                TextScaled = true
            })
        })
    })
    self.frame = self.billboardGui:FindFirstChild("Frame")
    self.portrait = self.frame:FindFirstChild("Portrait")
    self.nameLabel = self.frame:FindFirstChild("NameLabel")
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
        local transparency = self:CalculateTransparency(distance)
        self:UpdateTransparency(transparency)
    end)
end

function FriendLocator:CalculateTransparency(distance)
    if distance < MIN_VISIBILITY_DISTANCE then
        return 1
    elseif distance > MAX_VISIBILITY_DISTANCE then
        return 0
    else
        return (MAX_VISIBILITY_DISTANCE - distance) / MAX_VISIBILITY_DISTANCE
    end
end

function FriendLocator:UpdateTransparency(targetTransparency)
    if self.frame then
        TweenService:Create(self.frame, TweenInfo.new(0.2), {BackgroundTransparency = targetTransparency}):Play()
    end
    if self.portrait then
        TweenService:Create(self.portrait, TweenInfo.new(0.2), {BackgroundTransparency = targetTransparency}):Play()
    end
    if self.nameLabel then
        TweenService:Create(self.nameLabel, TweenInfo.new(0.2), {BackgroundTransparency = targetTransparency}):Play()
    end
end

function FriendLocator:Destroy()
    if self.billboardGui then
        self.billboardGui:Destroy()
        self.billboardGui = nil
    end
end

return FriendLocator
