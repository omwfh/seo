--[[
    █▀█ █▀█ █▀▀ █
    █▀▀ █▀▄ ██▄ █
    
    SEO Loader
    Features: Safe HTTP requests, Optimized place name detection, Advanced script execution.
]]
    
local getgenv: () -> ({[string]: any}) = getfenv().getgenv

local function Notify(Text)
	game:GetService("StarterGui"):SetCore("SendNotification", {
		Title = "SEO",
		Text = Text,
		Duration = 10
	})
end

local function SafeHttpGet(url)
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)
    return success and response or "ERROR"
end

local PlaceName = tostring(game.PlaceId):gsub("%b[]", ""):gsub("[%p%c]", ""):gsub("%s+", "_"):lower()

local Code = SafeHttpGet("https://raw.githubusercontent.com/omwfh/seo/refs/heads/main/games/" .. PlaceName .. ".lua")

if Code ~= "404: Not Found" then
    Notify("Game found, the script is loading.")
    getgenv().PlaceFileName = PlaceName
else
    Notify("Game not found, loading universal.")
    getgenv().ScriptVersion = "Universal"
    --Code = SafeHttpGet("")
    print("in progress")
end

getgenv().HandleSEO = function(scriptCode)
    if type(scriptCode) ~= "string" or scriptCode == "" or scriptCode == "ERROR" then
        warn("[SEO] Invalid or empty script received.")
        return
    end

    local startTime = tick()

    local env = setmetatable({}, { __index = getfenv() })
    local scriptFunction, loadError = loadstring(scriptCode)

    if not scriptFunction then
        warn("[SEO] Failed to compile script:", loadError)
        return
    end

    local success, runError = pcall(function()
        setfenv(scriptFunction, env)
        return scriptFunction()
    end)

    local executionTime = (tick() - startTime) * 1000

    if success then
        print(("[SEO] Script executed successfully in %.2f ms."):format(executionTime))
    else
        warn(("[SEO] Script execution failed after %.2f ms: %s"):format(executionTime, runError))
    end
end

getgenv().HandleSEO(loadstring(Code))
