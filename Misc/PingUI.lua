local Players: Players = game:GetService("Players")
local Stats: Stats = game:GetService("Stats")
local RunService: RunService = game:GetService("RunService")
local CoreGui: CoreGui = game:GetService("CoreGui")

local LocalPlayer: Player = Players.LocalPlayer
local newInstance: (className: string) -> Instance = Instance.new
local lastPing: number = -1
local uiConnection: RBXScriptConnection?

local function protectScreenGui(screenGui: ScreenGui)
    assert(screenGui and screenGui:IsA("ScreenGui"), "[SEO] Invalid argument: screenGui must be a valid ScreenGui instance.")

    task.defer(function()
        if syn and syn.protect_gui then
            syn.protect_gui(screenGui)
            screenGui.Parent = CoreGui
        elseif gethui then
            screenGui.Parent = gethui()
        else
            screenGui.Parent = CoreGui
        end
    end)
end

local function getPlayerPing(): number
    local NetworkStats: Folder? = Stats:FindFirstChild("Network")
    
    if NetworkStats then
        local PingItem: Instance? = NetworkStats:FindFirstChild("ServerStatsItem")
        local PingValue: number? = PingItem and PingItem:FindFirstChild("Data Ping") and PingItem["Data Ping"]:GetValue()

        if typeof(PingValue) == "number" then
            return math.clamp(math.round(PingValue), 0, 1000)
        end
    end

    return -1
end

local function createPingUI()
    if uiConnection then
        uiConnection:Disconnect()
    end

    local ScreenGui: ScreenGui = newInstance("ScreenGui")
    ScreenGui.Name = "PingDisplay"
    protectScreenGui(ScreenGui)

    local ClientInfo: Frame = newInstance("Frame")
    ClientInfo.Name = "ClientInfo"
    ClientInfo.Parent = ScreenGui
    ClientInfo.Position = UDim2.new(0.005, 0, 1, -54)
    ClientInfo.Size = UDim2.new(0, 119, 0, 54)
    ClientInfo.SizeConstraint = Enum.SizeConstraint.RelativeXY
    ClientInfo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ClientInfo.BackgroundTransparency = 1
    ClientInfo.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ClientInfo.BorderMode = Enum.BorderMode.Outline
    ClientInfo.BorderSizePixel = 0
    ClientInfo.Visible = true
    ClientInfo.ZIndex = 1

    local UISizeConstraint: UISizeConstraint = newInstance("UISizeConstraint")
    UISizeConstraint.Parent = ClientInfo
    UISizeConstraint.MaxSize = Vector2.new(math.huge, math.huge)
    UISizeConstraint.MinSize = Vector2.new(0, 0)

    local TextLabel: TextLabel = newInstance("TextLabel")
    TextLabel.Parent = ClientInfo
    TextLabel.Name = "PingLabel"
    TextLabel.Position = UDim2.new(-0.008, 0, 0.572, 0)
    TextLabel.Size = UDim2.new(0, 200, 0, 14)
    TextLabel.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold)
    TextLabel.TextSize = 14
    TextLabel.TextTransparency = 0.5
    TextLabel.TextColor3 = Color3.new(1, 1, 1)
    TextLabel.BackgroundTransparency = 1
    TextLabel.TextWrapped = true
    TextLabel.TextXAlignment = Enum.TextXAlignment.Left
    TextLabel.TextYAlignment = Enum.TextYAlignment.Center

    uiConnection = RunService.Heartbeat:Connect(function()
        local ping: number = getPlayerPing()
        if ping ~= lastPing and ping ~= -1 then
            lastPing = ping
            TextLabel.Text = `Ping: {ping} ms`
        end
    end)

    LocalPlayer.CharacterRemoving:Connect(function()
        if ScreenGui then
            ScreenGui:Destroy()
        end
    end)

    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.15)
        createPingUI()
    end)
end

createPingUI()
