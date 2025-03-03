local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local v1: Player = Players.LocalPlayer
local v4: number = 0.058
local v5: Enum.UserInputType = Enum.UserInputType.MouseButton2
local v7: boolean = false

local ScreenGui: ScreenGui?
local InputBox: TextBox?

local function protectScreenGui(screenGui: ScreenGui)
    assert(screenGui and screenGui:IsA("ScreenGui"), "[SEO] Invalid argument: screenGui must be a valid ScreenGui instance.")
    task.defer(function()
        if syn and syn.protect_gui then
            syn.protect_gui(screenGui)
            screenGui.Parent = game:GetService("CoreGui")
        elseif gethui then
            screenGui.Parent = gethui()
        else
            screenGui.Parent = game:GetService("CoreGui")
        end
    end)
end

local function Initiate()
    if ScreenGui then
        ScreenGui:Destroy()
        ScreenGui = nil
    end

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SmoothingInput"
    protectScreenGui(ScreenGui)

    local InputFrame: Frame = Instance.new("Frame")
    InputFrame.Name = "Values"
    InputFrame.Parent = ScreenGui
    InputFrame.Position = UDim2.new(0.005, 0, 1, -64)
    InputFrame.Size = UDim2.new(0, 119, 0, 30)
    InputFrame.BackgroundTransparency = 1

    InputBox = Instance.new("TextBox")
    InputBox.Parent = InputFrame
    InputBox.Name = "ValueInput"
    InputBox.Position = UDim2.new(0, 0, 0.572, 0)
    InputBox.Size = UDim2.new(0, 119, 0, 20)
    InputBox.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold)
    InputBox.TextSize = 14
    InputBox.TextTransparency = 0.2
    InputBox.TextColor3 = Color3.new(1, 1, 1)
    InputBox.BackgroundTransparency = 0.4
    InputBox.BackgroundColor3 = Color3.new(0, 0, 0)
    InputBox.TextXAlignment = Enum.TextXAlignment.Center
    InputBox.TextYAlignment = Enum.TextYAlignment.Center
    InputBox.Text = tostring(v4)
    InputBox.ClearTextOnFocus = false

    InputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local newValue = tonumber(InputBox.Text)
            if newValue then
                v4 = math.clamp(newValue, 0.01, 0.2)
                print("v4 value updated to:", v4)
            else
                InputBox.Text = tostring(v4)
            end
        end
    end)
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == v5 and not v7 then
            v7 = true
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == v5 then
            v7 = false
            print("Smooth Aim Stopped")
        end
    end)
end

Initiate()
