local FriendLocator = loadstring(game:HttpGet("https://raw.githubusercontent.com/omwfh/seo/refs/heads/main/Packages/Modules/HighlightedPlayer.lua"))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local activeLocators = {}
local isTyping = false

RunService.RenderStepped:Connect(function()
    isTyping = UserInputService:GetFocusedTextBox() ~= nil
end)

local function checkForFriends()
    if not getgenv().FriendLocatorEnabled then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer and Players.LocalPlayer:IsFriendsWith(player.UserId) then
            if not activeLocators[player.UserId] then
                local locator = FriendLocator.new(player.UserId)
                activeLocators[player.UserId] = locator
            end
        end
    end
end

local function removeFriendLocator(player)
    if activeLocators[player.UserId] then
        activeLocators[player.UserId]:Destroy()
        activeLocators[player.UserId] = nil
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or isTyping then return end
    if input.KeyCode == getgenv().FriendLocatorKeybind then
        getgenv().FriendLocatorEnabled = not getgenv().FriendLocatorEnabled

        if not getgenv().FriendLocatorEnabled then
            for _, locator in pairs(activeLocators) do
                locator:Destroy()
            end
            activeLocators = {}
        end
    end
end)

RunService.Heartbeat:Connect(checkForFriends)
Players.PlayerRemoving:Connect(removeFriendLocator)
