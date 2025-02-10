local FriendLocator = loadstring(game:HttpGet("https://raw.githubusercontent.com/omwfh/seo/refs/heads/main/Packages/Modules/FriendLocator.lua"))()

local Players: Players = game:GetService("Players")
local RunService: RunService = game:GetService("RunService")
local UserInputService: UserInputService = game:GetService("UserInputService")
local LocalPlayer: Player = Players.LocalPlayer

local activeLocators: { [number]: FriendLocator } = {}

local function addFriendLocator(player: Player)
    if player ~= LocalPlayer and LocalPlayer:IsFriendsWith(player.UserId) then
        if not activeLocators[player.UserId] then
            local locator = FriendLocator.new(player.UserId)
            activeLocators[player.UserId] = locator
        end
    end
end

local function removeFriendLocator(player: Player)
    if activeLocators[player.UserId] then
        activeLocators[player.UserId]:Destroy()
        activeLocators[player.UserId] = nil
    end
end

local function checkForFriends()
    if not getgenv().FriendLocatorEnabled then return end
    for _, player in ipairs(Players:GetPlayers()) do
        addFriendLocator(player)
    end
end

Players.PlayerAdded:Connect(addFriendLocator)
Players.PlayerRemoving:Connect(removeFriendLocator)
RunService.Heartbeat:Connect(checkForFriends)
