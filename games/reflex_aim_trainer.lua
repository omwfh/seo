local v1: Players = game:GetService("Players")
local v2: UserInputService = game:GetService("UserInputService")
local v3: RunService = game:GetService("RunService")
local v4: Camera = workspace.CurrentCamera
local v5: Folder? = workspace:FindFirstChild("Targets")
local v6: Player = v1.LocalPlayer

local v7: number = 0.12
local v8: Enum.UserInputType = Enum.UserInputType.MouseButton2
local v9: boolean = false
local v10: number = 650
local v11: number = 0.41
local v12: number = 0.1
local v13: number = 0.1
local v14: Vector2 = v2:GetMouseLocation()
local v15: boolean = false

local function v16(v17: BasePart): Vector3
    local v18: number = math.clamp(v17.Size.Magnitude / 10, 0.1, 1.5)
    
    return Vector3.new(
        (math.random() - 0.5) * v12 * v18,
        (math.random() - 0.5) * v12 * v18,
        0
    )
end

local function v19(v20: BasePart): Vector3
    local v21: Vector3 = v20.AssemblyLinearVelocity or Vector3.zero
    return v20.Position + (v21 * v13)
end

local function v22(): BasePart?
    if not v5 then return nil end
    
    local v23: BasePart? = nil
    local v24: number = math.huge
    local v25: Vector2 = v2:GetMouseLocation()
    
    for _, v26: Instance in ipairs(v5:GetChildren()) do
        if v26:IsA("BasePart") then
            local v27: Vector3, v28: boolean = v4:WorldToViewportPoint(v26.Position)
            
            if v28 then
                local v29: number = (Vector2.new(v27.X, v27.Y) - v25).Magnitude
                local v30: number = math.clamp(v26.Size.Magnitude / 5, 0.5, 1.8)
                
                if v29 < v24 and v29 < (v10 * v30) then
                    v23 = v26
                    v24 = v29
                end
            end
        end
    end
    
    return v23
end

local function v31(v32: BasePart)
    if not v32 then return end
    
    local v33: Vector3 = v19(v32)
    local v34: Vector3 = v33 + v16(v32)
    local v35: Vector3 = v4.CFrame.Position
    local v36: CFrame = v4.CFrame:Lerp(CFrame.lookAt(v35, v34), v7)
    
    if v15 then 
        local v37: Vector3 = Vector3.new(
            (math.random() - 0.5) * v11,
            (math.random() - 0.5) * v11,
            0
        )
        v36 = v36 * CFrame.new(v37)
    end
    
    v4.CFrame = v36
end

local function v38()
    local v39
    
    v39 = v3.RenderStepped:Connect(function()
        if not v9 then
            v39:Disconnect()
            return
        end
        
        local v40: Vector2 = v2:GetMouseLocation()
        v15 = (v40 - v14).Magnitude > 2
        v14 = v40
        
        local v41: BasePart? = v22()
        
        if v41 then
            v31(v41)
        end
    end)
end

local function v42()
    v2.InputBegan:Connect(function(v43: InputObject, v44: boolean)
        if v44 then return end
        
        if v43.UserInputType == v8 and not v9 then
            v9 = true
            v38()
        end
    end)
    
    v2.InputEnded:Connect(function(v45: InputObject)
        if v45.UserInputType == v8 then
            v9 = false
        end
    end)
end

local function Initiate()
    local v46, v47 = pcall(function()
        if not v1 or not v2 or not v3 or not v4 then
            error("[SEO] Required services are missing.")
        end
        
        if not v6 then
            error("[SEO] LocalPlayer is missing.")
        end
        
        if not workspace:FindFirstChild("Targets") then
            error("[SEO] 'Targets' folder is missing.")
        end
    end)
    
    if not v46 then
        warn("[SEO ERROR]:", v47)
        return
    end
    
    v42()
end

Initiate()
