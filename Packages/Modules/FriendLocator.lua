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

local Method = "Drawing"

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
    self.distanceText = nil
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

    if Method == "Drawing" then
        self.distanceText = Drawing.new("Text")
        self.distanceText.Text = "0m"
        self.distanceText.Size = 20
        self.distanceText.Color = Color3.fromRGB(255, 255, 255)
        self.distanceText.Center = true
        self.distanceText.Outline = true
        self.distanceText.OutlineColor = Color3.fromRGB(0, 0, 0)
        self.distanceText.OutlineThickness = 2
    elseif Method == "Text" then
        self.distanceText = Instance.new("TextLabel")
        self.distanceText.Text = "0m"
        self.distanceText.Size = UDim2.new(0, 100, 0, 50)
        self.distanceText.TextColor3 = Color3.fromRGB(255, 255, 255)
        self.distanceText.TextScaled = true
        self.distanceText.TextStrokeTransparency = 0.5
        self.distanceText.BackgroundTransparency = 1
        self.distanceText.Position = UDim2.new(0, 0, 0, 0)
        self.distanceText.Parent = game.CoreGui
    end
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
    local color: Color3 = Color3.new(ratio, 1 - ratio, 0)

    local fadeRatio: number = math.clamp((distance - 8.5) / 50, 0, 1)
    local transparency: number = 1 - fadeRatio

    local scaleFactor: number = math.clamp(1 - (distance / 500), 0.5, 1)

    self.highlight.OutlineColor = color
    self.highlight.Adornee.Size = Vector3.new(5 * scaleFactor, 5 * scaleFactor, 5 * scaleFactor)

    TweenService:Create(self.highlight, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { 
        OutlineTransparency = transparency, 
        FillTransparency = transparency 
    }):Play()

    if self.distanceText then
        self.distanceText.Text = string.format("%.1fm", distance)
        self:UpdateDistanceTextPosition(distance)
    end
end

function FriendLocator:UpdateDistanceTextPosition(distance: number): nil
    if not self.friend or not self.friend.Character then return end
    local head = self.friend.Character:FindFirstChild("Head")
    if not head then return end

    local screenPosition, onScreen = workspace.CurrentCamera:WorldToScreenPoint(head.Position + Vector3.new(0, 3, 0))
    if onScreen then
        if Method == "Drawing" then
            self.distanceText.Position = Vector2.new(screenPosition.X, screenPosition.Y)
        elseif Method == "Text" then
            self.distanceText.Position = UDim2.new(0, screenPosition.X, 0, screenPosition.Y)
        end
        
        local distanceColor: Color3
        if distance < 50 then
            distanceColor = Color3.fromRGB(255, 0, 0)
        elseif distance < 150 then
            distanceColor = Color3.fromRGB(255, 255, 0)
        else
            distanceColor = Color3.fromRGB(0, 255, 0)
        end

        TweenService:Create(self.distanceText, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            Color = distanceColor
        }):Play()

        local targetSize = math.clamp(20 - (distance / 50), 10, 30)
        TweenService:Create(self.distanceText, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            Size = targetSize
        }):Play()
    else
        self.distanceText.Visible = false
    end
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
    if self.distanceText then
        if Method == "Drawing" then
            self.distanceText:Remove()
        elseif Method == "Text" then
            self.distanceText:Destroy()
        end
        self.distanceText = nil
    end
end

return FriendLocator
