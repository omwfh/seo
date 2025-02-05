local getgenv: () -> ({[string]: any}) = getfenv().getgenv

local createElement = {}
createElement.__index = createElement

local function deepCopy(original: any)
    if typeof(original) ~= "table" then return original end
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = deepCopy(value)
    end
    return copy
end

local function isEvent(instance: Instance, property: string): boolean
    local success, result = pcall(function()
        return typeof(instance[property]) == "RBXScriptSignal"
    end)
    return success and result
end

local function isValidProperty(instance: Instance, property: string): boolean
    local success = pcall(function()
        local _ = instance[property]
    end)
    return success
end

local function logError(message: string)
    warn("[⚠️ createElement ERROR] " .. message)
end

local function logDebug(message: string)
    print("[🔍 createElement DEBUG] " .. message)
end

function createElement.new(className: string, properties: {[string]: any}?, children: {[string]: Instance}?): Instance
    assert(typeof(className) == "string", "[createElement] Expected className to be a string, got " .. typeof(className))

    local success, instance = pcall(Instance.new, className)
    if not success then
        logError(string.format("Failed to create instance of type '%s'", className))
        return nil
    end

    if properties then
        for key, value in pairs(properties) do
            if key == "Parent" then
                continue
            elseif key == "Event" and typeof(value) == "table" then
                for eventName, eventFunction in pairs(value) do
                    if isEvent(instance, eventName) and typeof(eventFunction) == "function" then
                        instance[eventName]:Connect(eventFunction)
                        logDebug(string.format("Connected event '%s' to %s", eventName, className))
                    else
                        logError(string.format("'%s' is not a valid event for %s", eventName, className))
                    end
                end
            elseif key == "Ref" and typeof(value) == "table" then
                value.Instance = instance
            elseif isValidProperty(instance, key) then
                local propSuccess, err = pcall(function()
                    instance[key] = value
                end)
                if not propSuccess then
                    logError(string.format("Failed to set property '%s' on %s: %s", key, className, err))
                else
                    logDebug(string.format("Set property '%s' on %s", key, className))
                end
            else
                logError(string.format("'%s' is not a valid property for %s", key, className))
            end
        end
    end

    if children then
        for _, child in pairs(children) do
            if typeof(child) == "Instance" then
                child.Parent = instance
                logDebug(string.format("Added child %s to %s", child.ClassName, className))
            else
                logError(string.format("Invalid child added to %s", className))
            end
        end
    end

    if properties and properties.Parent then
        instance.Parent = properties.Parent
    end

    return instance
end

function createElement.destroy(instance: Instance)
    if instance and typeof(instance) == "Instance" then
        pcall(function()
            instance:Destroy()
        end)
    end
end

function createElement.clone(instance: Instance): Instance?
    if instance and typeof(instance) == "Instance" then
        local success, clone = pcall(function()
            return instance:Clone()
        end)
        if success then
            return clone
        else
            logError("Failed to clone instance")
            return nil
        end
    end
    logError("Invalid instance provided for cloning")
    return nil
end

return createElement
