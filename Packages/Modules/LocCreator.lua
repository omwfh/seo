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
local SCALE_MULTIPLIER = 0.02
local DEFAULT_UI_SIZE = UDim2.new(5, 0, 1.5, 0)

function FriendLocator.new(userId)
    local self = setmetatable({}, FriendLocator)
    self.userId = userId
    self.friend = Players:GetPlayerByUserId(userId)
    self.billboardGui = nil
    self.frame = nil
    self.portrait = nil
    self.nameLabel = nil
    self.arrow = nil
    self:SetupUI()
    self:StartTracking()
    return self
end

function FriendLocator:SetupUI()
    if not self.friend or not self.friend.Character then return end

    self.billboardGui = createElement.new("BillboardGui", {
        Adornee = self.friend.Character:FindFirstChild("Head"),
        Size = DEFAULT_UI_SIZE,
        StudsOffset = Vector3.new(0, 2, 0),
        AlwaysOnTop = true,
        Parent = game.CoreGui
    }, {
        Frame = createElement.new("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 0.3,
            BackgroundColor3 = Color3.fromRGB(50, 150, 255),
            BorderSizePixel = 0
        }, {
            Portrait = createElement.new("ImageLabel", {
                Size = UDim2.new(0.9, 0, 0.9, 0),
                Position = UDim2.new(0.05, 0, 0.05, 0),
                Image = string.format(THUMBNAIL_URL, self.userId),
                BackgroundTransparency = 0,
                BorderSizePixel = 0
            }),
            Circle = createElement.new("UICorner", {
                CornerRadius = UDim.new(1, 0)
            }),
            NameLabel = createElement.new("TextLabel", {
                Size = UDim2.new(1, 0, 0.3, 0),
                Position = UDim2.new(0, 0, 1, 5),
                Text = self.friend.DisplayName,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                TextScaled = true
            }),
            Arrow = createElement.new("Frame", {
                Size = UDim2.new(0.5, 0, 0.5, 0),
                Position = UDim2.new(0.25, 0, 1.2, 0),
                BackgroundColor3 = Color3.fromRGB(50, 150, 255),
                BorderSizePixel = 0
            }, {
                Rotation = 45,
                Corner = createElement.new("UICorner", { CornerRadius = UDim.new(0.5, 0) })
            })
        })
    })

    self.frame = self.billboardGui:FindFirstChild("Frame")
    self.portrait = self.frame:FindFirstChild("Portrait")
    self.nameLabel = self.frame:FindFirstChild("NameLabel")
    self.arrow = self.frame:FindFirstChild("Arrow")
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
        local scaleFactor = self:CalculateScale(distance)

        self:UpdateTransparency(transparency)
        self:UpdateScale(scaleFactor)
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

function FriendLocator:CalculateScale(distance)
    return SCALE_MULTIPLIER * distance
end

function FriendLocator:UpdateTransparency(targetTransparency)
    if self.frame then
        TweenService:Create(self.frame, TweenInfo.new(0.2), { BackgroundTransparency = targetTransparency }):Play()
    end
    if self.portrait then
        TweenService:Create(self.portrait, TweenInfo.new(0.2), { BackgroundTransparency = targetTransparency }):Play()
    end
    if self.nameLabel then
        TweenService:Create(self.nameLabel, TweenInfo.new(0.2), { BackgroundTransparency = targetTransparency }):Play()
    end
    if self.arrow then
        TweenService:Create(self.arrow, TweenInfo.new(0.2), { BackgroundTransparency = targetTransparency }):Play()
    end
end

function FriendLocator:UpdateScale(scaleFactor)
    if self.billboardGui then
        self.billboardGui.Size = UDim2.new(scaleFactor, 0, scaleFactor * 0.5, 0)
    end
end

function FriendLocator:Destroy()
    if self.billboardGui then
        self.billboardGui:Destroy()
        self.billboardGui = nil
    end
end

return FriendLocator
