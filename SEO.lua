--[[
 ░▒▓███████▓▒░▒▓████████▓▒░▒▓██████▓▒░  
░▒▓█▓▒░      ░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░      ░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░ 
 ░▒▓██████▓▒░░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
       ░▒▓█▓▒░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░ 
       ░▒▓█▓▒░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓███████▓▒░░▒▓████████▓▒░▒▓██████▓▒░  
                                        
 SEO: Loader

 Version: 1.3
 
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

local extraScripts = ParallelFetch("https://raw.githubusercontent.com/example/extra1.lua", "https://raw.githubusercontent.com/example/extra2.lua")

Notify = function(Text: string): nil
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "SEO",
            Text = Text,
            Duration = 10
        })
    end)
end

SafeHttpGet = function(url: string): string?
    local success, response = pcall(game.HttpGet, game, url)
    return success and response ~= "ERROR" and response ~= "404: Not Found" and response or nil
end

ParallelFetch = function(...: string): table
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

GetPlaceName = function(): string
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId).Name
    end)
    
    if success and info then
        local name = info:gsub("%b[]", ""):gsub("[^%w%s]", ""):gsub("%s+", "_"):lower():gsub("^_+", "")
        print("[SEO] Detected Place Name:", name)
        return name
    end
    
    print("[SEO] Failed to retrieve game name, using PlaceId.")
    return tostring(game.PlaceId)
end

local PlaceName: string = GetPlaceName()
getgenv().PlaceFileName = PlaceName

local Code: string?
local Connection: RBXScriptConnection?

Connection = RunService.Heartbeat:Connect(function()
    if PlaceName and tonumber(PlaceName) then
        Code = SafeHttpGet("https://raw.githubusercontent.com/omwfh/seo/refs/heads/main/gameid/" .. PlaceName .. ".lua")
    else
        Code = SafeHttpGet("https://raw.githubusercontent.com/omwfh/seo/refs/heads/main/games/" .. PlaceName .. ".lua")
    end
    
    if Code and type(Code) == "string" and Code ~= "" then
        Notify("Game found, loading script.")
        getgenv().HandleSEO(Code)
        if Connection then Connection:Disconnect() end
    end

    local extraScripts = ParallelFetch(
        "";
    )
    
    if extraScripts and type(extraScripts) == "table" then
    for _, scriptCode in pairs(extraScripts) do
        getgenv().HandleSEO(scriptCode)
    end

    if not Code or Code == "" then
        print("[SEO] No game-specific script found, loading universal.")
        Code = SafeHttpGet("https://raw.githubusercontent.com/omwfh/seo/refs/heads/main/games/universal.lua")
        if Connection then Connection:Disconnect() end
    end
end)

getgenv().HandleSEO = function(scriptCode: string): nil
    task.wait(.5)
    if type(scriptCode) ~= "string" or scriptCode == "" then
        warn("[SEO] Invalid or empty script received.")
        return
    end

    local startTime: number = tick()
    local scriptFunction, loadError = scriptCode and loadstring(scriptCode) or nil
    
    if not scriptFunction then
        warn("[SEO] Failed to compile script:", loadError)
        return
    end

    ExecuteScript = function()
        local success, runError = pcall(scriptFunction)
        local executionTime: number = (tick() - startTime) * 1000

        if success then
            Notify(('[SEO] Script executed successfully in %.2f ms.'):format(executionTime))
        else
            Notify(('[SEO] Script execution failed after %.2f ms: %s'):format(executionTime, runError))
        end
    end

    local thread: thread = coroutine.create(ExecuteScript)
    coroutine.resume(thread)
end
