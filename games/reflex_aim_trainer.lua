local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")

local v1: Player = Players.LocalPlayer
local v2: Camera = workspace.CurrentCamera

local v3: string = "Targets"
local v4: number = 0.053
local v5: Enum.UserInputType = Enum.UserInputType.MouseButton2
local v6: boolean = true
local v7: boolean = false
local v8: Part? = nil
local v9: Vector3 = Vector3.zero
local AIM_FOV: number = 65

local ScreenGui: ScreenGui?
local InputBox: TextBox?

protectScreenGui = function(screenGui: ScreenGui)
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

GetTargets = function(): {Part}
    local v10: Folder? = workspace:FindFirstChild(v3)
    if not v10 then return {} end

    local v11: {Part} = {}
    for _, v12: Instance in ipairs(v10:GetChildren()) do
        if v12:IsA("Part") and v12.Name == "Target" then
            table.insert(v11, v12)
        end
    end
    return v11
end

GetBestTarget = function(): Part?
    local targets: {Part} = GetTargets()
    local bestTarget: Part? = nil
    local bestAngle: number = AIM_FOV
    local camPos: Vector3 = v2.CFrame.Position
    local lookDir: Vector3 = v2.CFrame.LookVector

    for _, target in ipairs(targets) do
        local targetDir: Vector3 = (target.Position - camPos).Unit
        local angle: number = math.deg(math.acos(targetDir:Dot(lookDir)))

        if angle < bestAngle then
            bestAngle = angle
            bestTarget = target
        end
    end

    return bestTarget
end

GetDynamicSmoothing = function(target: Part): number
    local distance: number = (v2.CFrame.Position - target.Position).Magnitude
    return math.clamp(0.02 + (distance / 1000), 0.02, 0.1)
end

GetRandomOffset = function(target: Part): Vector3
    local distance: number = (v2.CFrame.Position - target.Position).Magnitude
    local sizeFactor: number = math.clamp(target.Size.Magnitude / 5, 0.5, 2)
    local distanceFactor: number = math.clamp(300 / distance, 0.2, 1)

    return Vector3.new(
        math.random(-300, 375) / 500 * sizeFactor * distanceFactor,
        math.random(-300, 375) / 500 * sizeFactor * distanceFactor,
        math.random(-300, 375) / 500 * sizeFactor * distanceFactor
    )
end

GetJitter = function(): Vector3
    return Vector3.new(math.random(-13, 13) / 1000, math.random(-13, 13) / 1000, math.random(-13, 13) / 1000)
end

SmoothAim = function(): nil
    v7 = true
    local v14: CFrame = v2.CFrame

    while v7 do
        local v15: Part? = GetBestTarget()
        
        if v15 ~= v8 then
            v8 = v15
            v9 = GetRandomOffset(v8)
        end

        if not v8 then break end

        while v8 and v8.Parent and v7 do
            local v16: Vector3 = v8.Position + v9 + GetJitter()
            local v17: Vector3 = v2.CFrame.Position
            local v18: CFrame = CFrame.new(v17, v16)

            v14 = v14:Lerp(v18, GetDynamicSmoothing(v8))
            v2.CFrame = v14

            if not UserInputService:IsMouseButtonPressed(v5) then
                v7 = false
                break
            end

            if v6 and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                mouse1click()
            end

            task.wait()
        end
    end
end

Initiate = function()
    if ScreenGui then
        ScreenGui:Destroy()
        ScreenGui = nil
    end

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SmoothingInput"
    
    protectScreenGui(ScreenGui)

    local InputFrame: Frame = Instance.new("Frame")
    InputFrame.Name = "InputFrame"
    InputFrame.Parent = ScreenGui
    InputFrame.Position = UDim2.new(0.005, 0, 1, -74)
    InputFrame.Size = UDim2.new(0, 119, 0, 20)
    InputFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    InputFrame.BackgroundTransparency = 0.4
    InputFrame.BorderSizePixel = 1
    InputFrame.BorderColor3 = Color3.new(1, 1, 1)

    InputBox = Instance.new("TextBox")
    InputBox.Parent = InputFrame
    InputBox.Size = UDim2.new(1, -10, 1, 0)
    InputBox.Position = UDim2.new(0, 5, 0, 0)
    InputBox.Text = tostring(v4)
    InputBox.TextColor3 = Color3.new(1, 1, 1)
    InputBox.TextScaled = true
    InputBox.BackgroundTransparency = 1
    InputBox.ClearTextOnFocus = false
    InputBox.Font = Enum.Font.SourceSansBold

    InputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local newValue = tonumber(InputBox.Text)
            if newValue then
                v4 = math.clamp(newValue, 0.01, 0.2)
                print("v4 value updated to: ", v4)
            else
                InputBox.Text = tostring(v4)
            end
        end
    end)

    UserInputService.InputBegan:Connect(function(v19: InputObject, v20: boolean)
        if v20 then return end
        
        if v19.UserInputType == v5 and not v7 then
            SmoothAim()
        end
    end)
    
    UserInputService.InputEnded:Connect(function(v21: InputObject)
        if v21.UserInputType == v5 then
            v7 = false
            v8 = nil
        end
    end)
end

Initiate()
