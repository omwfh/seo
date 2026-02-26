if not game:IsLoaded() then game.Loaded:Wait() end

local Workspace: Workspace = game:GetService("Workspace")
local Players: Players = game:GetService("Players")
local UserService: UserService = game:GetService("UserService")

local LocalPlayer: Player = Players.LocalPlayer
local UserInfo = UserService:GetUserInfosByUserIdsAsync({ LocalPlayer.UserId })
local DisplayName: string = UserInfo[1].DisplayName

local TycoonsFolder: Folder = Workspace:WaitForChild("Tycoons")
local BoxDropoffs: Folder = Workspace:WaitForChild("BoxDropoffs")

local LocalTycoon: Model? = nil

for _, Tycoon: Model in ipairs(TycoonsFolder:GetChildren()) do
    local ClaimPart = Tycoon:WaitForChild("TycoonClaimer")
        :WaitForChild("ClaimTycoonPart")
        :WaitForChild("SurfaceGui")
        :WaitForChild("TextLabel")

    if ClaimPart.Text == DisplayName then
        LocalTycoon = Tycoon
        break
    end
end

if not LocalTycoon then
    warn("no tycoon found for player:", DisplayName)
    return
end

local BoxesFolder: Folder = LocalTycoon:WaitForChild("Boxes"):WaitForChild("FullBoxes")

local Colorizer: BasePart = LocalTycoon
    :WaitForChild("Buyables")
    :WaitForChild("Upgraders")
    :WaitForChild("Colorizer1")
    :WaitForChild("UpgradePart")

local Reinforcer: BasePart = LocalTycoon
    :WaitForChild("Buyables")
    :WaitForChild("Upgraders")
    :WaitForChild("Reinforcer1")
    :WaitForChild("UpgradePart")

local ManualButton: BasePart = LocalTycoon
    :WaitForChild("Buyables")
    :WaitForChild("Droppers")
    :WaitForChild("Dropper16")
    :WaitForChild("ButtonPart")

local DropoffPart: BasePart = BoxDropoffs
    :WaitForChild("Dropoff1")
    :WaitForChild("PayPart")

local ClickDetector: ClickDetector = ManualButton:WaitForChild("ClickDetector")

local Processed: {[Instance]: boolean} = {}
local Processing = false

local function getNetworkOwnedPart(BoxModel: Model): BasePart?
    for _, Descendant in ipairs(BoxModel:GetDescendants()) do
        if Descendant:IsA("BasePart") and isnetworkowner(Descendant) then
            return Descendant
        end
    end
    return nil
end

local function processBox(Box: Instance)
    if Processed[Box] then return end
    Processed[Box] = true

    task.wait(1.5)

    local BoxModel: Model? = Box:FindFirstChild("BoxModel")
    if not BoxModel then return end

    local OwnershipPart: BasePart? = getNetworkOwnedPart(BoxModel)
    if not OwnershipPart then return end

    fireclickdetector(ClickDetector)

    OwnershipPart.CFrame = Colorizer.CFrame
    task.wait(1.5)

    OwnershipPart.CFrame = Reinforcer.CFrame
    task.wait(1.5)

    OwnershipPart.CFrame = DropoffPart.CFrame
end

BoxesFolder.ChildAdded:Connect(function(Box: Instance)
    Box.Destroying:Connect(function()
        Processed[Box] = nil
    end)

    task.defer(processBox, Box)
end)
