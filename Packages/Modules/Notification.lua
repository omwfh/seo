local tweenService: TweenService, coreGui: CoreGui = game:GetService("TweenService"), game:GetService("CoreGui")
local createElement = loadstring(game:HttpGet("https://raw.githubusercontent.com/omwfh/seo/refs/heads/main/Packages/Modules/Elements.lua"))()

local insert: (table: {any}, value: any) -> () = table.insert
local find: (table: {any}, value: any) -> (number?) = table.find
local remove: (table: {any}, index: number) -> () = table.remove
local format: (string, ...any) -> string = string.format

local activeNotifications: {Instance} = {}

local fromRGB: (number, number, number) -> Color3 = Color3.fromRGB

local notificationPositions: {[string]: UDim2} = {
    ["Middle"] = UDim2.new(0.445, 0, 0.7, 0),
    ["MiddleRight"] = UDim2.new(0.85, 0, 0.7, 0),
    ["MiddleLeft"] = UDim2.new(0.01, 0, 0.7, 0),
    ["Top"] = UDim2.new(0.45, 0, 0.005, 0),
    ["TopLeft"] = UDim2.new(0.06, 0, 0.001, 0),
    ["TopRight"] = UDim2.new(0.8, 0, 0.001, 0),
}

local defaultTemplate: {[string]: any} = {
    NotificationLifetime = 5,
    NotificationPosition = "MiddleRight",
    DefaultTextColor = fromRGB(255, 255, 255),
    SuccessColor = fromRGB(0, 255, 0),
    ErrorColor = fromRGB(255, 0, 0),
    WarningColor = fromRGB(255, 165, 0),
    InfoColor = fromRGB(0, 140, 255),
    TextSize = 16,
    TextStrokeTransparency = 0.5,
    TextStrokeColor = fromRGB(0, 0, 0),
    TextFont = Enum.Font.SourceSansBold
}

protectScreenGui = function(screenGui: ScreenGui): nil
    if not screenGui then return end
    if syn and syn.protect_gui then 
        syn.protect_gui(screenGui)
        screenGui.Parent = coreGui
    elseif gethui then 
        screenGui.Parent = gethui()
    else 
        screenGui.Parent = coreGui
    end
end

applyFadeIn = function(object: Instance): nil
    local properties: {[string]: any} = {}

    if object:IsA("TextLabel") or object:IsA("TextButton") then
        properties.TextTransparency = 0
        properties.TextStrokeTransparency = 0
    elseif object:IsA("Frame") or object:IsA("ImageLabel") then
        properties.BackgroundTransparency = 0
    end
    
    object.BackgroundTransparency = 1

    local fadeInTween = tweenService:Create(object, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), properties)
    fadeInTween:Play()
end

applyFadeOut = function(object: Instance, onTweenCompleted: (() -> ())?): nil
    if not object or not object.Parent then return end

    local fadeOutTween = tweenService:Create(object, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
        BackgroundTransparency = 1,
        TextTransparency = 1,
        TextStrokeTransparency = 1
    })

    fadeOutTween.Completed:Connect(function()
        local index = find(activeNotifications, object)
        if index and activeNotifications[index] then
            remove(activeNotifications, index)
        end

        if object and object.Parent then
            object:Destroy()
        end

        if onTweenCompleted then
            onTweenCompleted()
        end
    end)

    fadeOutTween:Play()
end

local notifications = {}; do 
    notifications.Create = function(settings: {[string]: any}?): {[string]: any}
        assert(settings == nil or typeof(settings) == "table", "[ SEO ] Error in Create: Expected a table or nil.")

        local self = setmetatable({}, {__index = notifications})
        self.ui = { notificationsFrame = nil, notificationsFrame_UIListLayout = nil }

        for setting, value in pairs(defaultTemplate) do
            self[setting] = settings and settings[setting] or value
        end

        return self
    end

    notifications.InitializeUI = function(self: {[string]: any}): nil
        assert(typeof(self) == "table", "[ SEO ] Error in InitializeUI: Expected 'self' to be a table.")

        if notifications_screenGui then 
            notifications_screenGui:Destroy()
        end

        getgenv().notifications_screenGui = createElement.new("ScreenGui", {
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        })
        
        protectScreenGui(notifications_screenGui)

        self.ui.notificationsFrame = createElement.new("Frame", {
            Name = "notificationsFrame",
            Parent = notifications_screenGui,
            BackgroundTransparency = 1.000,
            Size = UDim2.new(0, 300, 0, 0),
            Position = notificationPositions[self.NotificationPosition] or UDim2.new(0.5, -150, 0.007, 0),
            AnchorPoint = Vector2.new(0.5, 0),
            ClipsDescendants = true
        })

        self.ui.notificationsFrame_UIListLayout = createElement.new("UIListLayout", {
            Name = "notificationsFrame_UIListLayout",
            Parent = self.ui.notificationsFrame,
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder
        })

        self.ui.notificationsFrame_UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            self.ui.notificationsFrame.Size = UDim2.new(0, 300, 0, self.ui.notificationsFrame_UIListLayout.AbsoluteContentSize.Y)
        end)
    end

    notifications.SetLifetime = function(self: {[string]: any}, duration: number): nil
        assert(typeof(duration) == "number", format("[ SEO ] Error in SetLifetime: Expected number, got %s.", typeof(duration)))
        assert(duration > 0, "[ SEO ] Error in SetLifetime: Duration must be greater than 0.")
        self.NotificationLifetime = duration
    end

    notifications.SetTextColor = function(self: {[string]: any}, color: Color3): nil
        assert(typeof(color) == "Color3", format("[ SEO ] Error in SetTextColor: Expected Color3, got %s.", typeof(color)))
        self.DefaultTextColor = color
    end

    notifications.SetTextSize = function(self: {[string]: any}, size: number): nil
        assert(typeof(size) == "number", format("[ SEO ] Error in SetTextSize: Expected number, got %s.", typeof(size)))
        assert(size > 0, "[ SEO ] Error in SetTextSize: Text size must be greater than 0.")
        self.TextSize = size
    end

    notifications.SetTextStrokeTransparency = function(self: {[string]: any}, transparency: number): nil
        assert(typeof(transparency) == "number", format("[ SEO ] Error in SetTextStrokeTransparency: Expected number, got %s.", typeof(transparency)))
        assert(transparency >= 0 and transparency <= 1, "[ SEO ] Error in SetTextStrokeTransparency: Transparency must be between 0 and 1.")
        self.TextStrokeTransparency = transparency
    end

    notifications.SetTextStrokeColor = function(self: {[string]: any}, color: Color3): nil
        assert(typeof(color) == "Color3", format("[ SEO ] Error in SetTextStrokeColor: Expected Color3, got %s.", typeof(color)))
        self.TextStrokeColor = color
    end

    notifications.SetFont = function(self: {[string]: any}, font: string): nil
        assert(typeof(font) == "string", format("[ SEO ] Error in SetFont: Expected string, got %s.", typeof(font)))
        local validFont: Font = Enum.Font[font] and Enum.Font[font] or nil
        assert(validFont, format("[ SEO ] Error in SetFont: Invalid font name '%s'.", tostring(font)))
        self.TextFont = validFont
    end

    notifications.Dispatch = function(self: {[string]: any}, text: string, notificationType: string?): nil
        assert(typeof(self) == "table", "[ SEO ] Error in Dispatch: Expected 'self' to be a table.")
        assert(typeof(text) == "string", format("[ SEO ] Error in Dispatch: Expected string, got %s.", typeof(text)))
        assert(text ~= "", "[ SEO ] Error in Dispatch: Text cannot be empty.")

        if not self.ui.notificationsFrame then
            warn("[ SEO ] Warning: UI is not initialized. Calling InitializeUI automatically.")
            self:InitializeUI()
        end

        local textColor = self.DefaultTextColor
        if notificationType == "Success" then textColor = self.SuccessColor
        elseif notificationType == "Error" then textColor = self.ErrorColor
        elseif notificationType == "Warning" then textColor = self.WarningColor
        elseif notificationType == "Info" then textColor = self.InfoColor
        end

        local notification = createElement.new("TextLabel", {
            Name = "Notification",
            Parent = self.ui.notificationsFrame,
            BackgroundTransparency = 1.000,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = text,
            Font = self.TextFont,
            TextColor3 = textColor,
            TextSize = self.TextSize,
            TextStrokeColor3 = self.TextStrokeColor,
            TextStrokeTransparency = self.TextStrokeTransparency,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center
        })

        insert(activeNotifications, notification)
        
        applyFadeIn(notification)
        
        self.ui.notificationsFrame_UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            self.ui.notificationsFrame.Size = UDim2.new(0, 300, 0, self.ui.notificationsFrame_UIListLayout.AbsoluteContentSize.Y + 15)
        end)

        task.delay(self.NotificationLifetime, function()
            applyFadeOut(notification)
        end)
    end
end

return notifications
