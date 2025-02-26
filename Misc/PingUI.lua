local Players: Players = game:GetService("Players")
local Stats: Stats = game:GetService("Stats")
local RunService: RunService = game:GetService("RunService")
local CoreGui: CoreGui = game:GetService("CoreGui")

local LocalPlayer: Player = Players.LocalPlayer

local newInstance: (className: string) -> Instance = Instance.new

local protectScreenGui: (screenGui: ScreenGui) -> nil = function(screenGui: ScreenGui)
    assert(screenGui and screenGui:IsA("ScreenGui"), "[SEO] Invalid argument: screenGui must be a valid ScreenGui instance.")

    if syn and syn.protect_gui then
        syn.protect_gui(screenGui)
        screenGui.Parent = CoreGui
    elseif gethui then
        screenGui.Parent = gethui()
    else
        screenGui.Parent = CoreGui
    end
end

local function getPlayerPing(): number | string
    local NetworkStats: Folder? = Stats:FindFirstChild("Network")
    
    if NetworkStats then
        local PingItem: Instance? = NetworkStats:FindFirstChild("ServerStatsItem")
        local PingValue: number? = PingItem and PingItem:FindFirstChild("Data Ping") and PingItem["Data Ping"]:GetValue()

        if typeof(PingValue) == "number" then
            return math.clamp(math.round(PingValue), 0, 1000)
        end
    end

    return "N/A"
end

local ScreenGui: ScreenGui = newInstance("ScreenGui")
ScreenGui.Name = "PingDisplay"

protectScreenGui(ScreenGui)

local TextLabel: TextLabel = newInstance("TextLabel")
TextLabel.Parent = ScreenGui
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

RunService.RenderStepped:Connect(function()
    local ping: number | string = getPlayerPing()
    TextLabel.Text = `Ping: {ping} ms`
end)
