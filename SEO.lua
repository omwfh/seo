--[[
 ░▒▓███████▓▒░▒▓████████▓▒░▒▓██████▓▒░  
░▒▓█▓▒░      ░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░      ░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░ 
 ░▒▓██████▓▒░░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
       ░▒▓█▓▒░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░ 
       ░▒▓█▓▒░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓███████▓▒░░▒▓████████▓▒░▒▓██████▓▒░                                

 SEO: Loader

 Version: 4.2
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
    print("[SEO] Debug: Attempting to fetch script -", scriptPath)

    if not scriptPath or scriptPath == "" then
        warn("[SEO] ERROR: Provided scriptPath is nil or empty.")
        return nil
    end

    local success, result = pcall(function()
        return Importer.Import(scriptPath)
    end)

    if success and result then
        print("[SEO] Successfully imported script: " .. scriptPath)
        return result
    else
        warn("[SEO] ERROR: Failed to import script '" .. scriptPath .. "'")
        return nil
    end
end

ParallelFetch = function(): nil
    if not miscellaneous or not next(miscellaneous) then
        warn("[SEO] No miscellaneous scripts to load.")
        return
    end

    local scriptCount = 0

    for scriptPath, enabled in pairs(miscellaneous) do
        if enabled then
            task.spawn(ExecuteScript, scriptPath)
            scriptCount = scriptCount + 1
        end
    end

    if scriptCount > 0 then
        NotifyUser(("[SEO] Loaded %d miscellaneous scripts."):format(scriptCount), "Success")
    else
        NotifyUser("[SEO] No miscellaneous scripts enabled.", "Warning")
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
    local success = false

    if not success then
        print("[SEO] Debug: Trying game-specific script:", "games/" .. placeName .. ".lua")
        success = Importer.Import("games/" .. placeName .. ".lua")

        if success then
            NotifyUser("[SEO] Game Detected: " .. placeName, "Success")
        else
            warn("[SEO] Game script not found:", placeName)
        end
    end

    if not success then
        local shortened = placeName:match("([^_]+_[^_]+)") or placeName
        
        if shortened ~= placeName then
            print("[SEO] Debug: Trying shortened game name:", "games/" .. shortened .. ".lua")
            success = Importer.Import("games/" .. shortened .. ".lua")

            if success then
                NotifyUser("[SEO] Game Detected: " .. shortened, "Success")
                placeName = shortened
            else
                warn("[SEO] Shortened script not found:", shortened)
            end
        end
    end

    if not success then
        NotifyUser("[SEO] Game not found, loading universal fallback...", "Error")
        success = Importer.Import("games/universal.lua")

        if not success then
            warn("[SEO] ERROR: Universal script failed to load.")
        end
    end

    return placeName, placeId
end

local Code: string? = nil
local Executed = false
local Connection: RBXScriptConnection?
local PlaceName, PlaceId = FetchGameDetails()

ExecuteScript = function(scriptPath: string): nil
    if type(scriptPath) ~= "string" or scriptPath == "" then
        warn("[SEO] Invalid script path provided.")
        return
    end

    local executionAttempts, maxRetries = 0, 3
    local scriptExecuted = false

    while executionAttempts < maxRetries and not scriptExecuted do
        executionAttempts = executionAttempts + 1
        local startTime = tick()

        local success, scriptCode = pcall(Importer.Import, scriptPath)

        if not success or not scriptCode or scriptCode == "" then
            warn(("[SEO] Failed to import script: %s (Attempt %d/%d)"):format(scriptPath, executionAttempts, maxRetries))
            task.wait(0.5)
            continue
        end

        local func, loadErr = loadstring(scriptCode)
        if not func then
            warn(("[SEO] Load error for script: %s | Error: %s (Attempt %d/%d)"):format(scriptPath, tostring(loadErr), executionAttempts, maxRetries))
            task.wait(0.5)
            continue
        end

        local runSuccess, runError = pcall(func)
        local executionTime = (tick() - startTime) * 1000

        if runSuccess then
            scriptExecuted = true
            NotifyUser(("[SEO] Successfully executed script: %s | Time: %.2f ms"):format(scriptPath, executionTime), "Success")
        else
            warn(("[SEO] Execution failed: %s | Error: %s (Attempt %d/%d)"):format(scriptPath, tostring(runError), executionAttempts, maxRetries))
            task.wait(0.5)
        end
    end

    if not scriptExecuted then
        NotifyUser(("[SEO] Script failed after %d attempts: %s"):format(maxRetries, scriptPath), "Error")
    end
end

HandleSEO = function(scriptPath: string): nil
    if type(scriptPath) ~= "string" or scriptPath == "" then
        warn("[SEO] Invalid script path provided. Execution aborted.")
        return
    end

    if getgenv().ExecutedScripts == nil then
        getgenv().ExecutedScripts = {}
    end

    if getgenv().ExecutedScripts[scriptPath] then
        warn("[SEO] Script already executed: " .. scriptPath)
        return
    end

    local executionAttempts, maxRetries = 0, 3
    local scriptExecuted = false

    local function TryExecuteScript()
        local scriptCode = Importer.Import(scriptPath)
        
        if not scriptCode or scriptCode == "" then
            return false, "[SEO] Importer returned empty or nil script: " .. scriptPath
        end

        local func, loadErr = loadstring(scriptCode)
        if not func then
            return false, "[SEO] loadstring failed: " .. tostring(loadErr)
        end

        local success, runError = pcall(func)
        if not success then
            return false, "[SEO] Execution error: " .. tostring(runError)
        end

        return true, nil
    end

    while executionAttempts < maxRetries and not scriptExecuted do
        executionAttempts = executionAttempts + 1
        NotifyUser(("[SEO] Attempting execution (%d/%d): %s"):format(executionAttempts, maxRetries, scriptPath), "Warning")

        local success, errorMsg = TryExecuteScript()
        if success then
            scriptExecuted = true
        else
            warn(errorMsg)
            task.wait(0.5)
        end
    end

    if scriptExecuted then
        getgenv().ExecutedScripts[scriptPath] = true
        NotifyUser(("[SEO] Successfully executed: %s | Attempts: %d"):format(scriptPath, executionAttempts), "Success")
    else
        NotifyUser(("[SEO] Failed after %d attempts: %s"):format(maxRetries, scriptPath), "Error")
    end
end

Initiate = function()
    local scriptPath

    if PlaceName and not tonumber(PlaceName) then
        scriptPath = "games/" .. PlaceName .. ".lua"
    elseif PlaceId and tonumber(PlaceId) then
        NotifyUser("[SEO] Game name not found, trying ID method...", "Warning")
        scriptPath = "gameid/" .. PlaceId .. ".lua"
    end

    if scriptPath and not Executed then
        NotifyUser("[SEO] Loaded!", "Success")
        HandleSEO(scriptPath)
        Executed = true
    end

    if miscellaneous and next(miscellaneous) then
        ParallelFetch()
    end

    if not Executed then
        NotifyUser("[SEO] Game not found, loading universal fallback...", "Error")
        scriptPath = "universal/main.lua"

        if scriptPath then
            HandleSEO(scriptPath)
            Executed = true
        else
            warn("[SEO] Failed to load universal script!")
        end
    end

    if Connection then
        Connection:Disconnect()
    end
end

Initiate()
