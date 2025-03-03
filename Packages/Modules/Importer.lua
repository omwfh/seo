local Importer = {}

local function URLExists(url: string): boolean
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)
    return success and response and response ~= ""
end

getgenv().CachedScripts = getgenv().CachedScripts or {}

function Importer.Import(scriptPath: string)
    local BaseURLs = {
        "https://raw.githubusercontent.com/omwfh/seo/main/",
    }

    if getgenv().CachedScripts[scriptPath] then
        return getgenv().CachedScripts[scriptPath]
    end

    for _, base in ipairs(BaseURLs) do
        local FullURL = base .. scriptPath

        if URLExists(FullURL) then
            local success, scriptCode = pcall(function()
                return game:HttpGet(FullURL)
            end)

            if success and type(scriptCode) == "string" and scriptCode ~= "" then
                getgenv().CachedScripts[scriptPath] = scriptCode
                return scriptCode
            else
                warn("[SEO] ERROR: Failed to fetch script from " .. FullURL)
            end
        else
            warn("[SEO] WARNING: URL does not exist - " .. FullURL)
        end
    end

    warn("[SEO] ERROR: All import sources failed for script '" .. scriptPath .. "'")
    return nil
end

return Importer
