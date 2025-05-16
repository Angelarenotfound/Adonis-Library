local AdonisEngine = {}
AdonisEngine.__index = AdonisEngine

local _instance = nil

local theme = {
    background = Color3.fromRGB(13, 13, 18),
    surface = Color3.fromRGB(22, 22, 28),
    accent = Color3.fromRGB(110, 90, 255),
    text = Color3.fromRGB(240, 240, 240),
    divider = Color3.fromRGB(45, 45, 55),
    error = Color3.fromRGB(255, 85, 85),
    success = Color3.fromRGB(85, 255, 127),
    warning = Color3.fromRGB(255, 175, 0)
}

local function create(className, props)
    local instance = Instance.new(className)
    for prop, val in pairs(props) do
        instance[prop] = val
    end
    return instance
end

local function getInstance()
    if not _instance then
        _instance = setmetatable({}, AdonisEngine)
        _instance.sections = {}
        _instance.notifications = {}
    end
    return _instance
end

function AdonisEngine.Start(title, iconId)
    local self = getInstance()

    if self.gui then
        self.gui:Destroy()
    end

    self.gui = create("ScreenGui", {
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        DisplayOrder = 999
    })

    self.mainFrame = create("Frame", {
        Parent = self.gui,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0.65, 0, 0.75, 0),
        BackgroundColor3 = theme.background,
        BackgroundTransparency = 0.03,
        ClipsDescendants = true
    })

    create("UICorner", {
        Parent = self.mainFrame,
        CornerRadius = UDim.new(0.08, 0)
    })

    local displayTitle = (type(title) == "string" and title ~= "") and title or "Adonis Except"
    local displayIconId = (type(iconId) == "number") and iconId or 110915885697382

    self:CreateTopBar(displayTitle, displayIconId)
    self:CreateContentArea()

    self.mainFrame.Position = UDim2.new(0.5, 0, -1.5, 0)
    self.mainFrame.Visible = true

    local enterAnim = game:GetService("TweenService"):Create(
        self.mainFrame,
        TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, 0, 0.5, 0)}
    )
    enterAnim:Play()

    self.gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    self:CreateNotificationsContainer()

    return self
end

function AdonisEngine:CreateTopBar(title, iconId)
    self.topBar = create("Frame", {
        Parent = self.mainFrame,
        Size = UDim2.new(1, 0, 0.075, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = theme.surface,
        BorderSizePixel = 0
    })

    create("UICorner", {
        Parent = self.topBar,
        CornerRadius = UDim.new(0.08, 0)
    })

    self.icon = create("ImageLabel", {
        Parent = self.topBar,
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(0.015, 0, 0.5, -16),
        BackgroundTransparency = 1,
        Image = "rbxassetid://"..tostring(iconId),
        ImageColor3 = theme.accent,
        ScaleType = Enum.ScaleType.Fit,
        ImageTransparency = 0
    })

    create("UICorner", {
        Parent = self.icon,
        CornerRadius = UDim.new(1, 0)
    })

    self.title = create("TextLabel", {
        Parent = self.topBar,
        Size = UDim2.new(0.8, 0, 1, 0),
        Position = UDim2.new(0.08, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = string.upper(tostring(title)),
        TextColor3 = theme.text,
        TextSize = 18,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = 0.1
    })

    self.closeButton = create("TextButton", {
        Parent = self.topBar,
        Size = UDim2.new(0, 32, 0, 42),
        Position = UDim2.new(1, -40, 0.5, -16),
        BackgroundTransparency = 1,
        Text = "X",
        TextColor3 = theme.text,
        TextSize = 20,
        Font = Enum.Font.GothamBold
    })

    self.closeButton.MouseButton1Click:Connect(function()
        self:ShowConfirmationModal()
    end)
end

function AdonisEngine:ShowConfirmationModal()
    if self.modal then return end

    self.modal = create("Frame", {
        Parent = self.gui,
        Size = UDim2.new(0.4, 0, 0.25, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundColor3 = theme.surface,
        BackgroundTransparency = 0
    })

    create("UICorner", {
        Parent = self.modal,
        CornerRadius = UDim.new(0.08, 0)
    })

    create("UIStroke", {
        Parent = self.modal,
        Color = theme.accent,
        Thickness = 2
    })

    local message = create("TextLabel", {
        Parent = self.modal,
        Size = UDim2.new(1, -20, 0.5, -20),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundTransparency = 1,
        Text = "¿Are you sure you want to close the Gui?",
        TextColor3 = theme.text,
        TextSize = 16,
        Font = Enum.Font.GothamMedium,
        TextWrapped = true
    })

    local buttonContainer = create("Frame", {
        Parent = self.modal,
        Size = UDim2.new(1, -20, 0.3, 0),
        Position = UDim2.new(0, 10, 0.65, 0),
        BackgroundTransparency = 1
    })

    local acceptButton = create("TextButton", {
        Parent = buttonContainer,
        Size = UDim2.new(0.45, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(60, 180, 60),
        Text = "ACCEPT",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        Font = Enum.Font.GothamBold
    })

    create("UICorner", {
        Parent = acceptButton,
        CornerRadius = UDim.new(0.08, 0)
    })

    local declineButton = create("TextButton", {
        Parent = buttonContainer,
        Size = UDim2.new(0.45, 0, 1, 0),
        Position = UDim2.new(0.55, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(180, 60, 60),
        Text = "DECLINE",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        Font = Enum.Font.GothamBold
    })

    create("UICorner", {
        Parent = declineButton,
        CornerRadius = UDim.new(0.08, 0)
    })

    acceptButton.MouseButton1Click:Connect(function()
        self:Destroy()
    end)

    declineButton.MouseButton1Click:Connect(function()
        self.modal:Destroy()
        self.modal = nil
    end)
end

function AdonisEngine:CreateContentArea()
    self.contentFrame = create("Frame", {
        Parent = self.mainFrame,
        Size = UDim2.new(1, -20, 0.9, -15),
        Position = UDim2.new(0, 10, 0.075, 10),
        BackgroundTransparency = 1
    })

    self.leftPanel = create("ScrollingFrame", {
        Parent = self.contentFrame,
        Size = UDim2.new(0.3, -5, 1, 0),
        BackgroundColor3 = theme.surface,
        ScrollBarThickness = 4,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y
    })

    create("UICorner", {
        Parent = self.leftPanel,
        CornerRadius = UDim.new(0.06, 0)
    })

    self.rightPanel = create("ScrollingFrame", {
        Parent = self.contentFrame,
        Size = UDim2.new(0.7, -5, 1, 0),
        Position = UDim2.new(0.3, 5, 0, 0),
        BackgroundColor3 = theme.surface,
        ScrollBarThickness = 4,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y
    })

    create("UICorner", {
        Parent = self.rightPanel,
        CornerRadius = UDim.new(0.06, 0)
    })

    create("Frame", {
        Parent = self.contentFrame,
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(0.3, 0, 0, 0),
        BackgroundColor3 = theme.divider,
        BorderSizePixel = 0
    })

    create("UIListLayout", {
        Parent = self.leftPanel,
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center
    })

    create("UIPadding", {
        Parent = self.leftPanel,
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10)
    })
end

function AdonisEngine:CreateNotificationsContainer()
    self.notificationsContainer = create("Frame", {
        Parent = self.gui,
        Size = UDim2.new(0, 300, 0, 0),
        Position = UDim2.new(1, -310, 1, -10),
        AnchorPoint = Vector2.new(0, 1),
        BackgroundTransparency = 1,
        ZIndex = 1000,
        AutomaticSize = Enum.AutomaticSize.Y
    })

    create("UIListLayout", {
        Parent = self.notificationsContainer,
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom
    })

    create("UIPadding", {
        Parent = self.notificationsContainer,
        PaddingBottom = UDim.new(0, 10)
    })
end

function AdonisEngine.Section(name)
    assert(type(name) == "string" and name ~= "", "Se requiere un nombre de sección válido (string no vacío)")
    
    local self = getInstance()
    
    local sectionButton = create("TextButton", {
        Parent = self.leftPanel,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = theme.accent,
        BackgroundTransparency = 0.8,
        Text = name,
        TextColor3 = theme.text,
        TextSize = 16,
        Font = Enum.Font.GothamSemibold,
        LayoutOrder = #self.sections + 1
    })

    create("UICorner", {
        Parent = sectionButton,
        CornerRadius = UDim.new(0.2, 0)
    })

    local sectionContainer = create("Frame", {
        Parent = self.rightPanel,
        Size = UDim2.new(1, -20, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = #self.sections == 0
    })

    create("UIListLayout", {
        Parent = sectionContainer,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center
    })

    create("UIPadding", {
        Parent = sectionContainer,
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10)
    })

    local section = {
        name = name,
        button = sectionButton,
        container = sectionContainer,
        elements = {}
    }

    table.insert(self.sections, section)

    sectionButton.MouseButton1Click:Connect(function()
        for _, sec in ipairs(self.sections) do
            sec.container.Visible = false
            sec.button.BackgroundTransparency = 0.8
        end

        sectionContainer.Visible = true
        sectionButton.BackgroundTransparency = 0.5
    end)

    return section
end

function AdonisEngine.Button(text, section, callback)
    assert(type(text) == "string" and text ~= "", "Se requiere un texto de botón válido")
    assert(type(section) == "table" and section.container, "Se requiere una sección válida")
    assert(type(callback) == "function", "Se requiere una función callback válida")

    local self = getInstance()
    
    local button = create("TextButton", {
        Parent = section.container,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = theme.surface,
        BackgroundTransparency = 0.5,
        Text = text,
        TextColor3 = theme.text,
        TextSize = 14,
        Font = Enum.Font.GothamMedium,
        LayoutOrder = #section.elements + 1
    })

    create("UICorner", {
        Parent = button,
        CornerRadius = UDim.new(0.15, 0)
    })

    create("UIStroke", {
        Parent = button,
        Color = theme.accent,
        Transparency = 0.7,
        Thickness = 1
    })

    button.MouseEnter:Connect(function()
        game:GetService("TweenService"):Create(
            button,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0.3}
        ):Play()
    end)

    button.MouseLeave:Connect(function()
        game:GetService("TweenService"):Create(
            button,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0.5}
        ):Play()
    end)

    button.MouseButton1Click:Connect(function()
        game:GetService("TweenService"):Create(
            button,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0.1}
        ):Play()

        task.delay(0.1, function()
            game:GetService("TweenService"):Create(
                button,
                TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 0.5}
            ):Play()
        end)

        callback()
    end)

    table.insert(section.elements, button)

    return button
end

function AdonisEngine.Notify(title, description, notifyType, duration, sound, options)
    local self = getInstance()

    title = title or "Notification"
    description = description or ""
    notifyType = notifyType or "success"
    duration = duration or 5

    local validTypes = {error = true, success = true, warning = true}
    if not validTypes[notifyType] then
        notifyType = "success"
    end

    local notifyColor = theme[notifyType]

    local notification = create("Frame", {
        Parent = self.notificationsContainer,
        Size = UDim2.new(1, -10, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = theme.surface,
        BackgroundTransparency = 0.1,
        Position = UDim2.new(1, 0, 0, 0),
        ZIndex = 1000,
        LayoutOrder = -os.time()
    })

    create("UICorner", {
        Parent = notification,
        CornerRadius = UDim.new(0.1, 0)
    })

    create("UIStroke", {
        Parent = notification,
        Color = notifyColor,
        Thickness = 2
    })

    local titleBar = create("Frame", {
        Parent = notification,
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = notifyColor,
        BackgroundTransparency = 0.2,
        ZIndex = 1001
    })

    create("UICorner", {
        Parent = titleBar,
        CornerRadius = UDim.new(0.1, 0)
    })

    create("Frame", {
        Parent = titleBar,
        Size = UDim2.new(1, 0, 0.5, 0),
        Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = notifyColor,
        BackgroundTransparency = 0.2,
        ZIndex = 1001
    })

    local titleText = create("TextLabel", {
        Parent = titleBar,
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = theme.text,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 1002
    })

    local descriptionText = create("TextLabel", {
        Parent = notification,
        Size = UDim2.new(1, -20, 0, 0),
        Position = UDim2.new(0, 10, 0, 35),
        BackgroundTransparency = 1,
        Text = description,
        TextColor3 = theme.text,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 1002
    })

    local buttonsContainer = nil
    if options and type(options) == "table" and #options > 0 then
        buttonsContainer = create("Frame", {
            Parent = notification,
            Size = UDim2.new(1, -20, 0, 35),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            ZIndex = 1002
        })

        descriptionText:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            buttonsContainer.Position = UDim2.new(0, 10, 0, descriptionText.AbsolutePosition.Y - notification.AbsolutePosition.Y + descriptionText.AbsoluteSize.Y + 5)
        end)

        local buttonCount = math.min(#options, 2)
        for i = 1, buttonCount do
            local option = options[i]
            if type(option) == "table" and option.text and option.callback then
                local button = create("TextButton", {
                    Parent = buttonsContainer,
                    Size = UDim2.new(1/buttonCount - 0.05, 0, 1, -10),
                    Position = UDim2.new((i-1)/buttonCount + (i-1)*0.05, 0, 0, 5),
                    BackgroundColor3 = theme.accent,
                    BackgroundTransparency = 0.5,
                    Text = option.text,
                    TextColor3 = theme.text,
                    TextSize = 14,
                    Font = Enum.Font.GothamMedium,
                    ZIndex = 1003
                })

                create("UICorner", {
                    Parent = button,
                    CornerRadius = UDim.new(0.2, 0)
                })

                button.MouseButton1Click:Connect(function()
                    if type(option.callback) == "function" then
                        task.spawn(option.callback)
                    end
                    self:CloseNotification(notification)
                end)
            end
        end
    end

    if sound and type(sound) == "string" then
        local soundInstance = Instance.new("Sound")
        soundInstance.SoundId = sound
        soundInstance.Parent = notification
        soundInstance:Play()

        soundInstance.Ended:Connect(function()
            soundInstance:Destroy()
        end)
    end

    table.insert(self.notifications, notification)
    self:ManageNotifications()

    notification.Position = UDim2.new(1, 0, 0, 0)
    game:GetService("TweenService"):Create(
        notification,
        TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {Position = UDim2.new(0, 0, 0, 0)}
    ):Play()

    task.delay(duration, function()
        self:CloseNotification(notification)
    end)

    return notification
end

function AdonisEngine:ManageNotifications()
    local maxVisible = 3

    for i, notification in ipairs(self.notifications) do
        if i > maxVisible then
            notification.Visible = false
        else
            notification.Visible = true
        end
    end
end

function AdonisEngine:CloseNotification(notification)
    if not notification or not notification.Parent then return end

    game:GetService("TweenService"):Create(
        notification,
        TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, 0, 0, 0)}
    ):Play()

    task.delay(0.5, function()
        for i, notif in ipairs(self.notifications) do
            if notif == notification then
                table.remove(self.notifications, i)
                break
            end
        end

        notification:Destroy()
        self:ManageNotifications()
    end)
end

function AdonisEngine:Destroy()
    if self.gui then
        self.gui:Destroy()
    end
end

local AE = {
    Start = AdonisEngine.Start,
    Section = AdonisEngine.Section,
    Button = AdonisEngine.Button,
    Notify = AdonisEngine.Notify,
    Destroy = AdonisEngine.Destroy
}

return AE