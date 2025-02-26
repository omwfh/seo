--[[
 ░▒▓███████▓▒░▒▓████████▓▒░▒▓██████▓▒░  
░▒▓█▓▒░      ░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░      ░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░ 
 ░▒▓██████▓▒░░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
       ░▒▓█▓▒░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░ 
       ░▒▓█▓▒░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓███████▓▒░░▒▓████████▓▒░▒▓██████▓▒░                                

 SEO: Loader

 Version: 3.0
]]

if not game:IsLoaded() then game.Loaded:Wait() end

local getgenv: () -> ({[string]: any}) = getfenv().getgenv
local getexecutorname: (() -> string)? = getfenv().getexecutorname
local identifyexecutor: (() -> string)? = getfenv().identifyexecutor
local HttpService: HttpService = game:GetService("HttpService")
local RunService: RunService = game:GetService("RunService")
local MarketplaceService: MarketplaceService = game:GetService("MarketplaceService")
local StarterGui: StarterGui = game:GetService("StarterGui")

local NotificationModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/omwfh/seo/refs/heads/main/Packages/Modules/Notification.lua"))()
local Notification = NotificationModule.Create({
    NotificationLifetime = 5,
    MaxNotifications = 5,
    NotificationPadding = UDim.new(0, 10),
    NotificationPosition = "Top"
})

Notification:SetFont("SourceSansBold")
Notification:SetTextStrokeTransparency(1)
Notification:SetTextSize(18)

Notification:InitializeUI()

local miscellaneous = {
    ["https://raw.githubusercontent.com/omwfh/seo/refs/heads/main/Misc/ESP.lua"] = false,
}

NotifyUser = function(text: string, type: string): nil
    pcall(function()
        if Notification then
            Notification:Notify(text, type)
        else
            warn("[ SEO ] Error in NotifyUser: Notifications system is not initialized.")
        end
    end)
end

FetchExecutor = function(): string
    if getexecutorname then
        return getexecutorname()
    elseif identifyexecutor then
        return identifyexecutor()
    else
        return "Unknown"
    end
end

local Executor: string = FetchExecutor()

GetGameName = function(): string
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId).Name
    end)
    
    if success and info then
        local name = info:gsub("%b[]", ""):gsub("[^%w%s]", ""):gsub("%s+", "_"):gsub("^_+", ""):gsub("_+$", ""):lower() 
        print("[SEO] Detected Game Name:", name)
        return name
    end
    
    print("[SEO] Failed to retrieve game name, using PlaceId.")
    return tostring(game.PlaceId)
end

HttpFetch = function(url: string): string?
    local success, response = pcall(game.HttpGet, game, url)
    return success and response ~= "ERROR" and response ~= "404: Not Found" and response or nil
end

ParallelFetch = function(): nil
    if not miscellaneous or type(miscellaneous) ~= "table" then
        warn("[SEO] miscellaneous table is missing or invalid.")
        return
    end

    local scriptCount = 0
    
    for url, enabled in pairs(miscellaneous) do
        if enabled then
            scriptCount = scriptCount + 1
            task.spawn(ExecuteScript, url)
        end
    end

    if scriptCount > 0 then
        print(("[SEO] Loaded %d miscellaneous scripts."):format(scriptCount))
    else
        print("[SEO] No miscellaneous scripts are enabled.")
    end
end

SetState = function(url: string, state: boolean): nil
    if miscellaneous[url] ~= nil then
        miscellaneous[url] = state
        NotifyUser("[SEO] " .. (state and "Enabled" or "Disabled") .. " miscellaneous script: " .. url, "Success")
    else
        NotifyUser("[SEO] Miscellaneous script not found in the list.", "Error")
    end
end

FetchGameDetails = function(): string
    NotifyUser("[SEO] Fetching game details...", "Info")
    task.wait(1)

    local placeName: string = GetGameName()
    NotifyUser("[SEO] Detected game: " .. placeName, "Success")
    task.wait(1)

    getgenv().PlaceFileName = placeName
    return placeName
end

local Code: string? = nil
local Executed = false
local Connection: RBXScriptConnection?
local PlaceName: string = FetchGameDetails()

Initiate = function(): nil
    if PlaceName and tonumber(PlaceName) then
        NotifyUser("[SEO] Using Game-ID for detection...", "Info")
        Code = HttpFetch("https://raw.githubusercontent.com/omwfh/seo/refs/heads/main/gameid/" .. PlaceName .. ".lua")
    else
        Code = HttpFetch("https://raw.githubusercontent.com/omwfh/seo/refs/heads/main/games/" .. PlaceName .. ".lua")
    end
    
    if Code and type(Code) == "string" and Code ~= "" and not Executed then
        NotifyUser("[SEO] Loaded!", "Success")
        getgenv().HandleSEO(Code)
        Executed = true
    end

    if miscellaneous and type(miscellaneous) == "table" then
        ParallelFetch()
    end

    if (not Code or Code == "") and not Executed then
        NotifyUser("[SEO] Game not found, loading universal fallback...", "Error")
        Code = HttpFetch("https://raw.githubusercontent.com/omwfh/seo/refs/heads/main/games/universal.lua")

        if Code and Code ~= "" then
            getgenv().HandleSEO(Code)
            Executed = true
        else
            warn("[SEO] Failed to load universal script!")
        end

        if Connection then Connection:Disconnect() end
    end
end

ExecuteScript = function(url: string): nil
    local startTime = tick()
    local scriptCode = HttpFetch(url)

    if not scriptCode or scriptCode == "" then
        warn(("[SEO] Failed to fetch script: %s"):format(url))
        return
    end

    local scriptFunction, loadError = loadstring(scriptCode)
    if not scriptFunction then
        warn(("[SEO] Compilation failed for script: %s | Error: %s"):format(url, loadError))
        return
    end

    local success, runError = pcall(scriptFunction)
    local executionTime = (tick() - startTime) * 1000

    if success then
        print(("[SEO] Successfully executed script: %s | Time: %.2f ms"):format(url, executionTime))
    else
        warn(("[SEO] Execution failed for script: %s | Error: %s | Time: %.2f ms"):format(url, runError, executionTime))
    end
end

getgenv().HandleSEO = function(scriptCode: string): nil
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

    RunScript = function(): nil
        local success, runError = pcall(scriptFunction)
        local executionTime: number = (tick() - startTime) * 1000
        
        if success then
            print(('[SEO] Script executed successfully in %.2f ms.'):format(executionTime))
        else
            warn(('[SEO] Script execution failed after %.2f ms: %s'):format(executionTime, runError))
        end
    end

    local thread: thread = coroutine.create(RunScript)
    coroutine.resume(thread)
end

Initiate()
