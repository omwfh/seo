--[[
 ░▒▓███████▓▒░▒▓████████▓▒░▒▓██████▓▒░  
░▒▓█▓▒░      ░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░      ░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░ 
 ░▒▓██████▓▒░░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
       ░▒▓█▓▒░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░ 
       ░▒▓█▓▒░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓███████▓▒░░▒▓████████▓▒░▒▓██████▓▒░  
                                        
 SEO: Loader
 Version: 1.2
 
 Features:
 - Safe HTTP requests
 - Optimized place name detection
 - Parallel script execution
 - Parallel script fetching
 - Advanced script handling
]]

local getgenv: () -> ({[string]: any}) = getfenv().getgenv
local HttpService: HttpService = game:GetService("HttpService")
local RunService: RunService = game:GetService("RunService")
local MarketplaceService: MarketplaceService = game:GetService("MarketplaceService")
local StarterGui: StarterGui = game:GetService("StarterGui")

local function Notify(Text: string): nil
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "SEO",
            Text = Text,
            Duration = 10
        })
    end)
end

local function SafeHttpGet(url: string): string?
    local success, response = pcall(game.HttpGet, game, url)
    return success and response ~= "ERROR" and response ~= "404: Not Found" and response or nil
end

local function ParallelFetch(...: string): table
    local urls: {string} = {...}
    local results: {[string]: string} = {}
    local threads: {thread} = {}

    for _, url: string in ipairs(urls) do
        local thread: thread = coroutine.create(function()
            local data: string? = SafeHttpGet(url)
            if data and data ~= "" then
                results[url] = data
            else
                warn("[SEO] Failed to fetch: " .. url)
            end
        end)
        table.insert(threads, thread)
    end

    for _, thread in ipairs(threads) do
        coroutine.resume(thread)
    end
    return results
end

local function GetPlaceName(): string
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId).Name
    end)
    
    if not success or not info then
        warn("[SEO] Failed to retrieve game name, using PlaceId instead.")
        return tostring(game.PlaceId)
    end

    local name = info:gsub("%b[]", ""):gsub("[^%w%s]", ""):gsub("%s+", "_"):lower():gsub("^_+", "")
    print("[SEO] Detected Place Name:", name)
    return name
end

local PlaceName: string = GetPlaceName()
getgenv().PlaceFileName = PlaceName

local Code: string?
local Connection: RBXScriptConnection?

Connection = RunService.Heartbeat:Connect(function()
    if not Code then
        Code = SafeHttpGet("https://raw.githubusercontent.com/omwfh/seo/refs/heads/main/games/" .. PlaceName .. ".lua")
    end
    if Code and Code ~= "" then
        Notify("Game found, loading script.")
        getgenv().HandleSEO(Code)
        if Connection then Connection:Disconnect() end
    end

    local extraScripts = ParallelFetch(
        "https://raw.githubusercontent.com/example/extra1.lua",
        "https://raw.githubusercontent.com/example/extra2.lua"
    )

    for _, scriptCode in pairs(extraScripts) do
        getgenv().HandleSEO(scriptCode)
    end
end)

getgenv().HandleSEO = function(scriptCode: string): nil
    task.wait(.85)
    if type(scriptCode) ~= "string" or scriptCode == "" then
        warn("[SEO] Invalid or empty script received.")
        return
    end

    local startTime: number = tick()
    local scriptFunction, loadError = loadstring(scriptCode)
    
    if not scriptFunction then
        warn("[SEO] Failed to compile script:", loadError)
        return
    end

    local function ExecuteScript()
        local success, runError = pcall(scriptFunction)
        local executionTime: number = (tick() - startTime) * 1000

        if success then
            print(('[SEO] Script executed successfully in %.2f ms.'):format(executionTime))
        else
            warn(('[SEO] Script execution failed after %.2f ms: %s'):format(executionTime, runError))
        end
    end

    local thread: thread = coroutine.create(ExecuteScript)
    coroutine.resume(thread)
end
