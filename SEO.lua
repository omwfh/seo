--[[
 ░▒▓███████▓▒░▒▓████████▓▒░▒▓██████▓▒░  
░▒▓█▓▒░      ░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░      ░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░ 
 ░▒▓██████▓▒░░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
       ░▒▓█▓▒░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░ 
       ░▒▓█▓▒░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓███████▓▒░░▒▓████████▓▒░▒▓██████▓▒░                                

 SEO: Loader

 Version: 3.7
]]

if not game:IsLoaded() then game.Loaded:Wait() end

local getgenv: () -> ({[string]: any}) = getfenv().getgenv
local getexecutorname: (() -> string)? = getfenv().getexecutorname
local identifyexecutor: (() -> string)? = getfenv().identifyexecutor
local HttpService: HttpService = game:GetService("HttpService")
local RunService: RunService = game:GetService("RunService")
local MarketplaceService: MarketplaceService = game:GetService("MarketplaceService")
local StarterGui: StarterGui = game:GetService("StarterGui")

local Importer = loadstring(game:HttpGet("https://raw.githubusercontent.com/omwfh/seo/refs/heads/main/Packages/Modules/Importer.lua"))()
local NotifLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/omwfh/seo/refs/heads/main/Packages/Modules/Notification.lua"))()

local Notification = NotifLib.new({
    NotificationLifetime = 5,
    MaxNotifications = 5,
    NotificationPadding = UDim.new(0, 3.5),
    NotificationPosition = "Top"
})

Notification:SetTextFont("SourceSansBold")
Notification:SetTextStrokeTransparency(1)
Notification:SetTextSize(18)

Notification:InitializeUI()

local miscellaneous = {
    ["Misc/ESP.lua"] = false,
    ["Misc/PingUI.lua"] = true
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

GetGameDetails = function(): (string, string)
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)

    if success and info then
        local gameName = info.Name:gsub("%b[]", ""):gsub("%b()", ""):gsub("[^%w%s]", ""):gsub("%s+", "_"):gsub("^_+", ""):gsub("_+$", ""):lower()
        local placeId = tostring(game.PlaceId)

        return gameName, placeId
    end

    print("[SEO] Failed to retrieve game name, using PlaceId.")
    return tostring(game.PlaceId), tostring(game.PlaceId)
end

HttpFetch = function(scriptPath: string): string?
    local success, result = pcall(function()
        return Importer.Import(scriptPath)
    end)

    if success and result then
        return result
    else
        warn("[SEO] ERROR: Failed to import script '" .. scriptPath .. "'")
        return nil
    end
end

ParallelFetch = function(): nil
    if not miscellaneous or type(miscellaneous) ~= "table" then
        warn("[SEO] miscellaneous table is missing or invalid.")
        return
    end

    local scriptCount = 0
    
    for scriptPath, enabled in pairs(miscellaneous) do
        if enabled then
            scriptCount = scriptCount + 1
            task.spawn(ExecuteScript, scriptPath)
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

FetchGameDetails = function(): (string, string)
    NotifyUser("[SEO] Fetching game details...", "Info")
    task.wait(1.25)

    local placeName, placeId = GetGameDetails()
    
    local success = Importer.Import("games/" .. placeName .. ".lua")

    if not success then
        local shortened = placeName:match("([^_]+_[^_]+)") or placeName
        success = Importer.Import("games/" .. shortened .. ".lua")

        if success then
            NotifyUser("[SEO] Game Detected: " .. placeName .. " : " .. shortened, "Success")
            placeName = shortened
        end
    end

    if not success then
        NotifyUser("[SEO] Game not found, loading universal fallback...", "Error")
        success = Importer.Import("games/universal.lua")
    end

    return placeName, placeId
end

local Code: string? = nil
local Executed = false
local Connection: RBXScriptConnection?
local PlaceName, PlaceId = FetchGameDetails()

ExecuteScript = function(scriptPath: string): nil
    local startTime = tick()

    local success = pcall(function()
        Importer.Import(scriptPath)
    end)

    if not success then
        warn(("[SEO] Failed to execute script: %s"):format(scriptPath))
        return
    end

    local scriptFunction, loadError = loadstring(scriptCode)

    if not scriptFunction then
        warn(("[SEO] Compilation failed for script: %s | Error: %s"):format(scriptPath, loadError))
        return
    end

    local runSuccess, runError = pcall(scriptFunction)
    local executionTime = (tick() - startTime) * 1000

    if runSuccess then
        print(("[SEO] Successfully executed script: %s | Time: %.2f ms"):format(scriptPath, executionTime))
    else
        warn(("[SEO] Execution failed for script: %s | Error: %s | Time: %.2f ms"):format(scriptPath, runError, executionTime))
    end
end

HandleSEO = function(scriptCode: string): nil
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

Initiate = function(): nil
    if PlaceName and not tonumber(PlaceName) then
        Code = HttpFetch("games/" .. PlaceName .. ".lua")
    end

    if (not Code or Code == "") and PlaceId and tonumber(PlaceId) then
        NotifyUser("[SEO] Game name not found, trying ID method...", "Warning")
        Code = HttpFetch("gameid/" .. PlaceId .. ".lua")
    end
    
    if Code and not Executed then
        NotifyUser("[SEO] Loaded!", "Success")
        HandleSEO(Code)
        Executed = true
    end

    if miscellaneous and type(miscellaneous) == "table" then
        ParallelFetch()
    end

    if (not Code or Code == "") and not Executed then
        NotifyUser("[SEO] Game not found, loading universal fallback...", "Error")
        
        Code = HttpFetch("universal/main.lua")

        if Code and Code ~= "" then
            HandleSEO(Code)
            Executed = true
        else
            warn("[SEO] Failed to load universal script!")
        end

        if Connection then Connection:Disconnect() end
    end
end

Initiate()
