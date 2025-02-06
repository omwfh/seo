local Importer = {}

local function URLExists(url: string): boolean
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)
    return success and response and response ~= ""
end

function Importer.Import(scriptPath: string)
    local BaseURLs = {
        "https://raw.githubusercontent.com/omwfh/seo/main/"
    }

    for _, base in ipairs(BaseURLs) do
        local FullURL = base .. scriptPath

        if URLExists(FullURL) then
            local success, result = pcall(function()
                return loadstring(game:HttpGet(FullURL))()
            end)

            if success then
                print("[SEO] SUCCESS: Imported from " .. FullURL)
                return true
            else
                warn("[SEO] ERROR: Failed to execute script from " .. FullURL)
            end
        else
            warn("[SEO] WARNING: URL does not exist - " .. FullURL)
        end
    end

    warn("[SEO] ERROR: All import sources failed for script '" .. scriptPath .. "'")
    return false
end

return Importer
