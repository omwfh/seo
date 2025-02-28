local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")

local v1: Player = Players.LocalPlayer
local v2: Camera = workspace.CurrentCamera

local v3: string = "Targets"
local v4: number = 0.039
local v5: Enum.UserInputType = Enum.UserInputType.MouseButton2
local v6: boolean = true
local v7: boolean = false
local v8: Part? = nil
local v9: Vector3 = Vector3.zero

local function GetTargets(): {Part}
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

local function GetRandomOffset(): Vector3
    return Vector3.new(math.random(-300, 375) / 500, math.random(-300, 375) / 500, math.random(-300, 375) / 500)
end

local function GetJitter(): Vector3
    return Vector3.new(math.random(-13, 13) / 1000, math.random(-13, 13) / 1000, math.random(-13, 13) / 1000)
end

local function GetRandomTarget(): Part?
    local v13: {Part} = GetTargets()
    if #v13 == 0 then return nil end
    return v13[math.random(1, #v13)]
end

local function SmoothAim(): nil
    v7 = true
    local v14: CFrame = v2.CFrame

    while v7 do
        local v15: Part? = GetRandomTarget()
        
        if v15 ~= v8 then
            v8 = v15
            v9 = GetRandomOffset()
        end

        if not v8 then break end

        while v8 and v8.Parent and v7 do
            local v16: Vector3 = v8.Position + v9 + GetJitter()
            local v17: Vector3 = v2.CFrame.Position
            local v18: CFrame = CFrame.new(v17, v16)

            v14 = v14:Lerp(v18, v4)
            v2.CFrame = v14

            if not UserInputService:IsMouseButtonPressed(v5) then
                v7 = false
                break
            end

            if v6 and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                task.wait()
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end

            task.wait()
        end
    end
end

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
