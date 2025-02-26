local tweenService: TweenService = game:GetService("TweenService")
local coreGui: CoreGui = game:GetService("CoreGui")

local insert: <T>(table: {T}, value: T) -> number = table.insert
local remove: <T>(table: {T}, index: number) -> T = table.remove
local format: (string, ...any) -> string = string.format

local newInstance: (className: string) -> Instance = Instance.new
local fromRGB: (number, number, number) -> Color3 = Color3.fromRGB

local notificationPositions: {[string]: UDim2} = {
    ["Middle"] = UDim2.new(0.445, 0, 0.7, 0),
    ["MiddleRight"] = UDim2.new(0.85, 0, 0.7, 0),
    ["MiddleLeft"] = UDim2.new(0.01, 0, 0.7, 0),
    ["Top"] = UDim2.new(0.445, 0, 0.007, 0),
    ["TopLeft"] = UDim2.new(0.06, 0, 0.001, 0),
    ["TopRight"] = UDim2.new(0.8, 0, 0.001, 0),
}

local notificationCategories: {[string]: Color3} = {
    ["Success"] = fromRGB(0, 200, 0),
    ["Warning"] = fromRGB(255, 165, 0),
    ["Error"] = fromRGB(200, 0, 0),
    ["Info"] = fromRGB(0, 122, 255)
}

local protectScreenGui: (screenGui: ScreenGui) -> () = function(screenGui)
    if not screenGui or typeof(screenGui) ~= "Instance" then
        error("[ SEO ] Invalid argument: screenGui must be a valid ScreenGui instance.")
    end

    if syn and syn.protect_gui then 
        syn.protect_gui(screenGui)
        screenGui.Parent = coreGui
    elseif gethui then 
        screenGui.Parent = gethui()
    else 
        screenGui.Parent = coreGui
    end
end

local createObject: <T>(className: string, properties: {[string]: any}) -> T = function(className, properties)
    if not className or typeof(className) ~= "string" then
        error("[ SEO ] Invalid className: Expected string, got " .. typeof(className))
    end
    if not properties or typeof(properties) ~= "table" then
        error("[ SEO ] Invalid properties: Expected table, got " .. typeof(properties))
    end

    local instance = newInstance(className)
    for index, value in next, properties do 
        instance[index] = value 
    end
    return instance
end

local fadeObject: (object: GuiObject, onTweenCompleted: () -> ()) -> () = function(object, onTweenCompleted)
    if not object or not object:IsA("GuiObject") then
        error("[ SEO ] Invalid object: Expected GuiObject, got " .. typeof(object))
    end
    if not onTweenCompleted or typeof(onTweenCompleted) ~= "function" then
        error("[ SEO ] Invalid onTweenCompleted callback: Expected function, got " .. typeof(onTweenCompleted))
    end

    local tween = tweenService:Create(object, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
        TextTransparency = 1,
        TextStrokeTransparency = 1
    })
    tween.Completed:Connect(onTweenCompleted)
    tween:Play()
end

local notifications: {[string]: any} = {}; do 
    notifications.new = function(settings: {[string]: any}) -> {[string]: any}
        if not settings or typeof(settings) ~= "table" then
            error("[ SEO ] Invalid settings: Expected table, got " .. typeof(settings))
        end

        local notificationSettings = {
            ui = { notificationsFrame = nil, notificationsFrame_UIListLayout = nil },
            MaxNotifications = settings.MaxNotifications or 5,
            NotificationPadding = settings.NotificationPadding or UDim.new(0, 8)
        }

        for setting, value in next, settings do 
            notificationSettings[setting] = value 
        end

        setmetatable(notificationSettings, {__index = notifications})
        return notificationSettings
    end

    notifications.SetNotificationLifetime = function(self: {[string]: any}, number: number) -> ()
        if not number or typeof(number) ~= "number" then
            error("[ SEO ] Invalid number: Expected number, got " .. typeof(number))
        end
        self.NotificationLifetime = number 
    end

    notifications.SetTextColor = function(self: {[string]: any}, color3: Color3) -> ()
        if not color3 or typeof(color3) ~= "Color3" then
            error("[ SEO ] Invalid Color3: Expected Color3, got " .. typeof(color3))
        end
        self.TextColor = color3 
    end

    notifications.SetTextSize = function(self: {[string]: any}, number: number) -> ()
        if not number or typeof(number) ~= "number" then
            error("[ SEO ] Invalid TextSize: Expected number, got " .. typeof(number))
        end
        self.TextSize = number 
    end

    notifications.SetTextStrokeTransparency = function(self: {[string]: any}, number: number) -> ()
        if not number or typeof(number) ~= "number" then
            error("[ SEO ] Invalid TextStrokeTransparency: Expected number, got " .. typeof(number))
        end
        self.TextStrokeTransparency = number 
    end

    notifications.SetTextStrokeColor = function(self: {[string]: any}, color3: Color3) -> ()
        if not color3 or typeof(color3) ~= "Color3" then
            error("[ SEO ] Invalid TextStrokeColor: Expected Color3, got " .. typeof(color3))
        end
        self.TextStrokeColor = color3 
    end

    notifications.SetTextFont = function(self: {[string]: any}, font: string | Enum.Font) -> ()
        if not font or (typeof(font) ~= "string" and typeof(font) ~= "EnumItem") then
            error("[ SEO ] Invalid font: Expected string or EnumItem, got " .. typeof(font))
        end
        self.TextFont = typeof(font) == "string" and Enum.Font[font] or font
    end
  
    notifications.InitializeUI = function(self: {[string]: any}) -> ()
        if notifications_screenGui then 
            notifications_screenGui:Destroy()
        end

        getgenv().notifications_screenGui = createObject("ScreenGui", {
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        })
        protectScreenGui(notifications_screenGui)

        self.ui.notificationsFrame = createObject("Frame", {
            Name = "notificationsFrame",
            Parent = notifications_screenGui,
            BackgroundColor3 = fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            Position = notificationPositions[self.NotificationPosition] or notificationPositions["TopRight"],
            Size = UDim2.new(0, 236, 0, 215),
            ClipsDescendants = true
        })

        self.ui.notificationsFrame_UIListLayout = createObject("UIListLayout", {
            Name = "notificationsFrame_UIListLayout",
            Parent = self.ui.notificationsFrame,
            Padding = self.NotificationPadding,
            SortOrder = Enum.SortOrder.LayoutOrder
        })
    end

    notifications.Notify = function(self: {[string]: any}, text: string, category: string?) -> ()
        if not text or typeof(text) ~= "string" then
            error("[ SEO ] Invalid text: Expected string, got " .. typeof(text))
        end
    
        if not self.ui.notificationsFrame then self:BuildNotificationUI() end
    
        local children = self.ui.notificationsFrame:GetChildren()
        
        if #children - 1 >= self.MaxNotifications then
            children[2]:Destroy()
        end
    
        local categoryColor = notificationCategories[category] or fromRGB(30, 30, 30)
    
        local notification = createObject("TextLabel", {
            Name = "notification",
            Parent = self.ui.notificationsFrame,
            BackgroundColor3 = categoryColor,
            BackgroundTransparency = 0.2,
            Size = UDim2.new(0, 222, 0, 0),
            Text = "",
            Font = self.TextFont or Enum.Font.SourceSans,
            TextColor3 = self.TextColor or fromRGB(255, 255, 255),
            TextSize = self.TextSize or 16,
            TextStrokeColor3 = self.TextStrokeColor or fromRGB(0, 0, 0),
            TextStrokeTransparency = self.TextStrokeTransparency or 1,
            TextWrapped = true,
            ClipsDescendants = false,
            AutomaticSize = Enum.AutomaticSize.Y
        })
    
        task.wait()
        
        local textHeight = math.max(20, notification.TextBounds.Y + 10)
    
        local tween = tweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 222, 0, textHeight)
        })
        
        tween:Play()
    
        task.spawn(function()
            for i = 1, #text do
                notification.Text = string.sub(text, 1, i)
                task.wait(0.03)
            end
        end)
    
        task.delay(self.NotificationLifetime or 3, function()
            fadeObject(notification, function()
                notification:Destroy()
            end)
        end)
    end    
end

return notifications
