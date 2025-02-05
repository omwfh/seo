if getgenv().Aiming then return getgenv().Aiming end

local Players: Players = game:GetService("Players")
local Workspace: Workspace = game:GetService("Workspace")
local GuiService: GuiService = game:GetService("GuiService")
local RunService: RunService = game:GetService("RunService")

local LocalPlayer: Player = Players.LocalPlayer
local CurrentCamera: Camera = Workspace.CurrentCamera
local Mouse: Mouse = LocalPlayer:GetMouse()

local Heartbeat: RBXScriptSignal = RunService.Heartbeat
local GetGuiInset: (self: GuiService) -> Vector2 = GuiService.GetGuiInset
local WorldToViewportPoint: (self: Camera, worldPoint: Vector3) -> (Vector3, boolean) = CurrentCamera.WorldToViewportPoint
local GetPlayers: (self: Players) -> {Player} = Players.GetPlayers
local Raycast: (self: Workspace, origin: Vector3, direction: Vector3, params: RaycastParams?) -> RaycastResult? = Workspace.Raycast

local DrawingNew: (className: string) -> DrawingObject = Drawing.new
local Color3FromRGB: (r: number, g: number, b: number) -> Color3 = Color3.fromRGB
local Vector2New: (x: number, y: number) -> Vector2 = Vector2.new
local RandomNew: () -> Random = Random.new
local MathFloor: (n: number) -> number = math.floor
local RaycastParamsNew: () -> RaycastParams = RaycastParams.new

local InstanceNew: (className: string) -> Instance = Instance.new
local TableRemove: <T>(list: {T}, pos: number) -> T? = table.remove
local TableInsert: <T>(list: {T}, value: T) -> () = table.insert

local CharacterAdded: RBXScriptSignal = LocalPlayer.CharacterAdded
local CharacterAddedWait: (self: RBXScriptSignal) -> Model = CharacterAdded.Wait

local TempInstance: Instance = InstanceNew("Part")
local IsDescendantOf: (self: Instance, ancestor: Instance) -> boolean = TempInstance.IsDescendantOf
local FindFirstChildWhichIsA: (self: Instance, className: string) -> Instance? = TempInstance.FindFirstChildWhichIsA
local FindFirstChild: (self: Instance, name: string) -> Instance? = TempInstance.FindFirstChild

local EnumRaycastFilterTypeBlacklist: Enum.RaycastFilterType = Enum.RaycastFilterType.Blacklist

local Aiming: {
    Enabled: boolean,
    ShowFOV: boolean,
    FOV: number,
    FOVSides: number,
    FOVColour: Color3,
    VisibleCheck: boolean,
    HitChance: number,
    Selected: Player?,
    SelectedPart: BasePart?,
    TargetPart: string | {string},
    Ignored: {
        Teams: { { Team: Team?, TeamColor: BrickColor? } },
        Players: { Player }
    },
    FOVCircle: DrawingObject?
} = {
    Enabled = true,
    ShowFOV = _G.ShowFov or false,
    FOV = _G.Fov or 100,
    FOVSides = _G.Sides or 100,
    FOVColour = Color3.fromRGB(255, 77, 77),
    VisibleCheck = true,
    HitChance = _G.HitChance or 100,
    Selected = nil,
    SelectedPart = nil,
    TargetPart = _G.TargetPart or "Upper Torso",
    
    Ignored = {
        Teams = {
            {
                Team = LocalPlayer.Team,
                TeamColor = LocalPlayer.TeamColor
            }
        },
        Players = { LocalPlayer }
    },

    FOVCircle = nil
}

getgenv().Aiming = Aiming

local FOVCircle: DrawingObject = Drawing.new("Circle")
FOVCircle.Transparency = 1
FOVCircle.Thickness = 2
FOVCircle.Color = Aiming.FOVColour
FOVCircle.Filled = false

Aiming.FOVCircle = FOVCircle

Aiming.UpdateFOV = function(): DrawingObject?
    if not Aiming.FOVCircle then
        return nil
    end

    Aiming.FOVCircle.Visible = Aiming.ShowFOV
    Aiming.FOVCircle.Radius = Aiming.FOV * 3
    Aiming.FOVCircle.Position = Vector2.new(Mouse.X, Mouse.Y + GuiService:GetGuiInset().Y)
    Aiming.FOVCircle.NumSides = Aiming.FOVSides
    Aiming.FOVCircle.Color = Aiming.FOVColour

    return Aiming.FOVCircle
end

Aiming.CalcChance = function(percentage: number): boolean
    percentage = math.floor(percentage)
    local chance: number = math.floor(Random.new():NextNumber(0, 1) * 100) / 100
    return chance <= (percentage / 100)
end

Aiming.IsPartVisible = function(Part: BasePart, PartDescendant: Model): boolean
    local Character: Model? = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    if not Character then return false end

    local Origin: Vector3 = CurrentCamera.CFrame.Position
    local _, OnScreen: boolean = CurrentCamera:WorldToViewportPoint(Part.Position)

    if OnScreen then
        local raycastParams: RaycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.FilterDescendantsInstances = {Character, CurrentCamera}

        local Result: RaycastResult? = Workspace:Raycast(Origin, Part.Position - Origin, raycastParams)
        if Result then
            local PartHit: Instance = Result.Instance
            return not PartHit or PartHit:IsDescendantOf(PartDescendant)
        end
    end
    return false
end

Aiming.IgnorePlayer = function(Player: Player): boolean
    local IgnoredPlayers: {Player} = Aiming.Ignored.Players
    for _, IgnoredPlayer: Player in ipairs(IgnoredPlayers) do
        if IgnoredPlayer == Player then
            return false
        end
    end
    table.insert(IgnoredPlayers, Player)
    return true
end

Aiming.UnIgnorePlayer = function(Player: Player): boolean
    local IgnoredPlayers: {Player} = Aiming.Ignored.Players
    for i: number, IgnoredPlayer: Player in ipairs(IgnoredPlayers) do
        if IgnoredPlayer == Player then
            table.remove(IgnoredPlayers, i)
            return true
        end
    end
    return false
end

Aiming.IgnoreTeam = function(Team: Team, TeamColor: BrickColor): boolean
    local IgnoredTeams: { { Team: Team, TeamColor: BrickColor } } = Aiming.Ignored.Teams
    for _, IgnoredTeam in ipairs(IgnoredTeams) do
        if IgnoredTeam.Team == Team and IgnoredTeam.TeamColor == TeamColor then
            return false
        end
    end
    table.insert(IgnoredTeams, { Team = Team, TeamColor = TeamColor })
    return true
end

Aiming.UnIgnoreTeam = function(Team: Team, TeamColor: BrickColor): boolean
    local IgnoredTeams: { { Team: Team, TeamColor: BrickColor } } = Aiming.Ignored.Teams
    for i: number, IgnoredTeam in ipairs(IgnoredTeams) do
        if IgnoredTeam.Team == Team and IgnoredTeam.TeamColor == TeamColor then
            table.remove(IgnoredTeams, i)
            return true
        end
    end
    return false
end

Aiming.TeamCheck = function(Toggle: boolean): boolean
    if Toggle then
        return Aiming.IgnoreTeam(LocalPlayer.Team, LocalPlayer.TeamColor)
    end
    return Aiming.UnIgnoreTeam(LocalPlayer.Team, LocalPlayer.TeamColor)
end

Aiming.IsIgnoredTeam = function(Player: Player): boolean
    for _, IgnoredTeam in ipairs(Aiming.Ignored.Teams) do
        if Player.Team == IgnoredTeam.Team and Player.TeamColor == IgnoredTeam.TeamColor then
            return true
        end
    end
    return false
end

Aiming.IsIgnored = function(Player: Player): boolean
    for _, IgnoredPlayer in ipairs(Aiming.Ignored.Players) do
        if typeof(IgnoredPlayer) == "number" and Player.UserId == IgnoredPlayer then
            return true
        end
        if IgnoredPlayer == Player then
            return true
        end
    end
    return Aiming.IsIgnoredTeam(Player)
end

Aiming.Raycast = function(Origin: Vector3, Destination: Vector3, UnitMultiplier: number?): (Vector3?, Vector3?, Enum.Material?)
    if typeof(Origin) == "Vector3" and typeof(Destination) == "Vector3" then
        UnitMultiplier = UnitMultiplier or 1
        local Direction: Vector3 = (Destination - Origin).Unit * UnitMultiplier
        local Result: RaycastResult? = Workspace:Raycast(Origin, Direction)
        if Result then
            return Direction, Result.Normal, Result.Material
        end
    end
    return nil
end

Aiming.Character = function(Player: Player): Model?
    return Player.Character
end

Aiming.CheckHealth = function(Player: Player): boolean
    local Character: Model? = Aiming.Character(Player)
    local Humanoid: Humanoid? = Character and Character:FindFirstChildWhichIsA("Humanoid")
    return Humanoid and Humanoid.Health > 0 or false
end

Aiming.Check = function(): boolean
    return Aiming.Enabled and Aiming.Selected ~= LocalPlayer and Aiming.SelectedPart ~= nil
end

Aiming.checkSilentAim = Aiming.Check

Aiming.GetClosestTargetPartToCursor = function(Character: Model): (BasePart?, Vector3?, boolean, number?)
    local TargetParts: string | {string} = Aiming.TargetPart
    local ClosestPart: BasePart? = nil
    local ClosestPartPosition: Vector3? = nil
    local ClosestPartOnScreen: boolean = false
    local ClosestPartMagnitudeFromMouse: number? = nil
    local ShortestDistance: number = math.huge

    local function CheckTargetPart(TargetPart: BasePart?)
        if typeof(TargetPart) == "string" then
            TargetPart = Character:FindFirstChild(TargetPart) :: BasePart?
        end
        if not TargetPart then return end

        local PartPos: Vector3, OnScreen: boolean = CurrentCamera:WorldToViewportPoint(TargetPart.Position)
        local Magnitude: number = (Vector2.new(PartPos.X, PartPos.Y - GuiService:GetGuiInset().Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude

        if Magnitude < ShortestDistance then
            ClosestPart = TargetPart
            ClosestPartPosition = PartPos
            ClosestPartOnScreen = OnScreen
            ClosestPartMagnitudeFromMouse = Magnitude
            ShortestDistance = Magnitude
        end
    end

    if typeof(TargetParts) == "string" then
        if TargetParts == "All" then
            for _, v: Instance in ipairs(Character:GetChildren()) do
                if v:IsA("BasePart") then
                    CheckTargetPart(v)
                end
            end
        else
            CheckTargetPart(TargetParts)
        end
    elseif typeof(TargetParts) == "table" then
        for _, TargetPartName: string in ipairs(TargetParts) do
            CheckTargetPart(TargetPartName)
        end
    end

    return ClosestPart, ClosestPartPosition, ClosestPartOnScreen, ClosestPartMagnitudeFromMouse
end

Aiming.GetClosestPlayerToCursor = function()
    local TargetPart: BasePart? = nil
    local ClosestPlayer: Player? = nil
    local Chance: boolean = Aiming.CalcChance(Aiming.HitChance)
    local ShortestDistance: number = math.huge

    if not Chance then
        Aiming.Selected = LocalPlayer
        Aiming.SelectedPart = nil
        return LocalPlayer
    end

    for _, Player: Player in ipairs(Players:GetPlayers()) do
        local Character: Model? = Aiming.Character(Player)
        if not Aiming.IsIgnored(Player) and Character then
            local TargetPartTemp, _, _, Magnitude = Aiming.GetClosestTargetPartToCursor(Character)
            if TargetPartTemp and Aiming.CheckHealth(Player) then
                if Aiming.FOVCircle and Aiming.FOVCircle.Radius > Magnitude and Magnitude < ShortestDistance then
                    if Aiming.VisibleCheck and not Aiming.IsPartVisible(TargetPartTemp, Character) then
                        continue
                    end
                    ClosestPlayer = Player
                    ShortestDistance = Magnitude
                    TargetPart = TargetPartTemp
                end
            end
        end
    end

    Aiming.Selected = ClosestPlayer
    Aiming.SelectedPart = TargetPart
end

Heartbeat:Connect(function()
    Aiming.UpdateFOV()
    Aiming.GetClosestPlayerToCursor()
end)

return Aiming
