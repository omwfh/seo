local createElement = loadstring(game:HttpGet("https://raw.githubusercontent.com/omwfh/seo/refs/heads/main/Packages/Modules/Elements.lua"))()
local FriendLocator = {}
FriendLocator.__index = FriendLocator

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local BACKGROUND_COLOR = Color3.new(0.9, 0.9, 0.9)
local THUMBNAIL_URL = "rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"

function FriendLocator.new(userId, customGui)
    local self = setmetatable({}, FriendLocator)
    self.userId = userId
    self.friend = Players:GetPlayerByUserId(userId)
    self.customGui = customGui
    self.parent = Instance.new("ScreenGui")
    self.parent.Parent = game.CoreGui
    self.highlight = nil
    self.arrow = nil
    self.gui = nil
    self:StartTracking()
    return self
end

function FriendLocator:render()
    if not self.customGui then
        self.gui = createElement.new("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Parent = self.parent,
        }, {
            ImageButton = createElement.new("ImageButton", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Event = { Activated = self.onClick },
            }),

            Content = createElement.new("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
            }, {
                Border = createElement.new("Frame", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundColor3 = BACKGROUND_COLOR,
                }, {
                    Circle = createElement.new("UICorner", {
                        CornerRadius = UDim.new(1, 0),
                    }),
                }),

                Portrait = createElement.new("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromScale(0.9, 0.9),
                    Image = string.format(THUMBNAIL_URL, self.userId),
                    BackgroundColor3 = BACKGROUND_COLOR,
                    ZIndex = 2,
                }, {
                    Circle = createElement.new("UICorner", {
                        CornerRadius = UDim.new(1, 0),
                    }),
                }),

                Tail = createElement.new("Frame", {
                    Size = UDim2.fromScale(0.5, 0.5),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5 + 0.5 / math.sqrt(2)),
                    Rotation = 45,
                    BorderSizePixel = 0,
                    BackgroundColor3 = BACKGROUND_COLOR,
                }),
            }),
        })
    else
        self.customGui.Parent = self.parent
        self:_renderCustomGui()
    end
end

function FriendLocator:_renderCustomGui()
    if not self.customGui then return end

    local portrait = self.customGui:FindFirstChild("Portrait", true)
    if portrait and portrait:IsA("ImageLabel") then
        portrait.Image = string.format(THUMBNAIL_URL, self.userId)
    end

    local displayName = self.customGui:FindFirstChild("DisplayName", true)
    if displayName and displayName:IsA("TextLabel") then
        local player = Players:GetPlayerByUserId(self.userId)
        displayName.Text = player and player.DisplayName or "Unknown"
    end
end

function FriendLocator:StartTracking()
    RunService.RenderStepped:Connect(function()
        if self.friend and self.friend.Character then
            local root = self.friend.Character:FindFirstChild("HumanoidRootPart")
            if root then
                self:UpdateESP(root)
                self:UpdateArrow(root)
            end
        end
    end)
end

function FriendLocator:CreateESP()
    if not self.friend.Character then return end
    local highlight = Instance.new("Highlight")
    highlight.Parent = game.CoreGui
    highlight.Adornee = self.friend.Character
    highlight.FillColor = Color3.new(1, 0, 0)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    self.highlight = highlight
end

function FriendLocator:UpdateESP(root)
    if not self.highlight then self:CreateESP() end
    self.highlight.Adornee = root.Parent
end

function FriendLocator:CreateArrow()
    self.arrow = Drawing.new("Triangle")
    self.arrow.Filled = true
    self.arrow.Color = Color3.new(1, 1, 0)
    self.arrow.Thickness = 1
    self.arrow.Visible = true
end

function FriendLocator:UpdateArrow(root)
    if not self.arrow then self:CreateArrow() end

    local screenPosition, onScreen = Camera:WorldToViewportPoint(root.Position)
    local screenSize = Camera.ViewportSize
    local center = Vector2.new(screenSize.X / 2, screenSize.Y / 2)

    if onScreen then
        self.arrow.Visible = false
    else
        self.arrow.Visible = true
        local direction = (Vector2.new(screenPosition.X, screenPosition.Y) - center).Unit
        local arrowSize = 25
        local arrowPosition = center + direction * 100

        self.arrow.PointA = arrowPosition
        self.arrow.PointB = arrowPosition + Vector2.new(-arrowSize, arrowSize)
        self.arrow.PointC = arrowPosition + Vector2.new(arrowSize, arrowSize)
    end
end

function FriendLocator:Destroy()
    if self.gui then self.gui:Destroy() end
    if self.arrow then self.arrow:Remove() end
    if self.highlight then self.highlight:Destroy() end
    self.parent:Destroy()
end

return FriendLocator
