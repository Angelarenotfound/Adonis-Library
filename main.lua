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
    end
    return _instance
end

local Notifications = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local notificationQueue = {}
local maxNotificationsVisible = 5
local activeNotifications = {}

local function createTween(instance, properties, duration, style, direction)
    local tweenInfo = TweenInfo.new(
        duration or 0.3,
        style or Enum.EasingStyle.Quint,
        direction or Enum.EasingDirection.Out
    )
    return TweenService:Create(instance, tweenInfo, properties)
end

local function createRippleEffect(button, rippleColor)
    local ripple = Instance.new("Frame")
    ripple.BackgroundColor3 = rippleColor or Color3.fromRGB(255, 255, 255)
    ripple.BackgroundTransparency = 0.8
    ripple.BorderSizePixel = 0
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.Parent = button
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ripple
    
    local mousePos = UserInputService:GetMouseLocation() - Vector2.new(button.AbsolutePosition.X, button.AbsolutePosition.Y)
    ripple.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
    
    local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
    local appearTween = createTween(ripple, {Size = UDim2.new(0, maxSize, 0, maxSize), BackgroundTransparency = 1}, 0.5)
    appearTween:Play()
    
    appearTween.Completed:Connect(function()
        ripple:Destroy()
    end)
end

local function isMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled
end

local function adjustForMobile(size)
    if isMobile() then
        local screenSize = workspace.CurrentCamera.ViewportSize
        local scaleFactor = math.min(screenSize.X / 1920, screenSize.Y / 1080)
        return math.max(size * scaleFactor, size * 0.8)
    end
    return size
end

function Notifications.createContainer(mainGui)
    mainGui.NotificationsContainer = Instance.new("Frame")
    mainGui.NotificationsContainer.Name = "NotificationsContainer"
    mainGui.NotificationsContainer.Size = UDim2.new(0, 300, 1, -40)
    mainGui.NotificationsContainer.Position = UDim2.new(1, -320, 0, 20)
    mainGui.NotificationsContainer.BackgroundTransparency = 1
    mainGui.NotificationsContainer.Parent = mainGui

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 10)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    listLayout.Parent = mainGui.NotificationsContainer
end

function Notifications.processQueue()
    if #notificationQueue > 0 and #activeNotifications < maxNotificationsVisible then
        local nextNotification = table.remove(notificationQueue, 1)
        table.insert(activeNotifications, nextNotification)
        nextNotification:Show()
    end
end

function Notifications.show(mainGui, title, description, notificationType, options)
    options = options or {}
    
    local notification = {
        mainGui = mainGui,
        title = title,
        description = description,
        notificationType = notificationType,
        options = options,
        frame = nil,
        isVisible = false,
        isDestroyed = false
    }
    
    function notification:Show()
        if self.isDestroyed then return end
        
        local notificationColor
        if self.notificationType == "success" then
            notificationColor = theme.success
        elseif self.notificationType == "warning" then
            notificationColor = theme.warning
        elseif self.notificationType == "error" then
            notificationColor = theme.error
        else
            notificationColor = theme.accent
        end
        
        local notificationHeight = self.options.height or (self.options.buttons and 120 or 80)
        
        self.frame = Instance.new("Frame")
        self.frame.Size = UDim2.new(1, 0, 0, notificationHeight)
        self.frame.BackgroundColor3 = theme.surface
        self.frame.BorderSizePixel = 0
        self.frame.Position = UDim2.new(1, 300, 0, 0)
        self.frame.AnchorPoint = Vector2.new(0, 0)
        self.frame.Parent = self.mainGui.NotificationsContainer
        
        local shadow = Instance.new("ImageLabel")
        shadow.Size = UDim2.new(1, 40, 1, 40)
        shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
        shadow.AnchorPoint = Vector2.new(0.5, 0.5)
        shadow.BackgroundTransparency = 1
        shadow.Image = "rbxassetid://6014261993"
        shadow.ImageColor3 = Color3.new(0, 0, 0)
        shadow.ImageTransparency = 0.5
        shadow.ScaleType = Enum.ScaleType.Slice
        shadow.SliceCenter = Rect.new(49, 49, 450, 450)
        shadow.ZIndex = self.frame.ZIndex - 1
        shadow.Parent = self.frame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = self.frame
        
        local topBar = Instance.new("Frame")
        topBar.Size = UDim2.new(1, 0, 0, 6)
        topBar.BackgroundColor3 = notificationColor
        topBar.BorderSizePixel = 0
        topBar.Parent = self.frame
        
        local topCorner = Instance.new("UICorner")
        topCorner.CornerRadius = UDim.new(0, 4)
        topCorner.Parent = topBar
        
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, -60, 0, 24)
        titleLabel.Position = UDim2.new(0, 15, 0, 15)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Enum.Font.GothamSemibold
        titleLabel.TextSize = 16
        titleLabel.TextColor3 = theme.text
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Text = self.title
        titleLabel.Parent = self.frame
        
        local descriptionLabel = Instance.new("TextLabel")
        descriptionLabel.Size = UDim2.new(1, -30, 0, 40)
        descriptionLabel.Position = UDim2.new(0, 15, 0, 39)
        descriptionLabel.BackgroundTransparency = 1
        descriptionLabel.Font = Enum.Font.Gotham
        descriptionLabel.TextSize = 14
        descriptionLabel.TextColor3 = theme.text
        descriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
        descriptionLabel.TextYAlignment = Enum.TextYAlignment.Top
        descriptionLabel.TextWrapped = true
        descriptionLabel.Text = self.description
        descriptionLabel.Parent = self.frame
        
        if self.options.buttons then
            local buttonContainer = Instance.new("Frame")
            buttonContainer.Size = UDim2.new(1, -30, 0, 30)
            buttonContainer.Position = UDim2.new(0, 15, 1, -40)
            buttonContainer.BackgroundTransparency = 1
            buttonContainer.Parent = self.frame
            
            local buttonLayout = Instance.new("UIListLayout")
            buttonLayout.FillDirection = Enum.FillDirection.Horizontal
            buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
            buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
            buttonLayout.Padding = UDim.new(0, 10)
            buttonLayout.Parent = buttonContainer
            
            for i, buttonInfo in ipairs(self.options.buttons) do
                local button = Instance.new("TextButton")
                button.Size = UDim2.new(0, 80, 1, 0)
                button.BackgroundColor3 = i == 1 and notificationColor or theme.background
                button.BorderSizePixel = 0
                button.Font = Enum.Font.GothamMedium
                button.TextSize = 14
                button.TextColor3 = theme.text
                button.Text = buttonInfo.text
                button.LayoutOrder = i
                button.ClipsDescendants = true
                button.AutoButtonColor = false
                button.Parent = buttonContainer
                
                local buttonCorner = Instance.new("UICorner")
                buttonCorner.CornerRadius = UDim.new(0, 4)
                buttonCorner.Parent = button
                
                local buttonShadow = Instance.new("ImageLabel")
                buttonShadow.Size = UDim2.new(1, 6, 1, 6)
                buttonShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
                buttonShadow.AnchorPoint = Vector2.new(0.5, 0.5)
                buttonShadow.BackgroundTransparency = 1
                buttonShadow.Image = "rbxassetid://6014261993"
                buttonShadow.ImageColor3 = Color3.new(0, 0, 0)
                buttonShadow.ImageTransparency = 0.8
                buttonShadow.ScaleType = Enum.ScaleType.Slice
                buttonShadow.SliceCenter = Rect.new(49, 49, 450, 450)
                buttonShadow.ZIndex = button.ZIndex - 1
                buttonShadow.Parent = button
                
                button.MouseEnter:Connect(function()
                    createTween(button, {
                        BackgroundColor3 = i == 1 and 
                            Color3.new(
                                math.min(notificationColor.R + 0.1, 1),
                                math.min(notificationColor.G + 0.1, 1),
                                math.min(notificationColor.B + 0.1, 1)
                            ) or theme.accent
                    }):Play()
                end)
                
                button.MouseLeave:Connect(function()
                    createTween(button, {
                        BackgroundColor3 = i == 1 and notificationColor or theme.background
                    }):Play()
                end)
                
                button.MouseButton1Click:Connect(function()
                    createRippleEffect(button, Color3.fromRGB(255, 255, 255))
                    if buttonInfo.callback then
                        buttonInfo.callback()
                    end
                    self:Destroy()
                end)
            end
        end
        
        local closeButton = Instance.new("TextButton")
        closeButton.Size = UDim2.new(0, 24, 0, 24)
        closeButton.Position = UDim2.new(1, -30, 0, 15)
        closeButton.BackgroundTransparency = 1
        closeButton.Font = Enum.Font.GothamSemibold
        closeButton.TextSize = 16
        closeButton.TextColor3 = theme.text
        closeButton.Text = "✕"
        closeButton.Parent = self.frame
        
        closeButton.MouseEnter:Connect(function()
            createTween(closeButton, {TextColor3 = theme.error}):Play()
        end)
        
        closeButton.MouseLeave:Connect(function()
            createTween(closeButton, {TextColor3 = theme.text}):Play()
        end)
        
        closeButton.MouseButton1Click:Connect(function()
            createRippleEffect(closeButton, theme.error)
            self:Destroy()
        end)
        
        if self.options.sound then
            local sound = Instance.new("Sound")
            sound.SoundId = self.options.sound
            sound.Volume = self.options.volume or 0.5
            sound.Parent = self.frame
            sound:Play()
        end
        
        self.isVisible = true
        createTween(
            self.frame,
            {Position = UDim2.new(0, 0, 0, 0)},
            0.3,
            Enum.EasingStyle.Back
        ):Play()
        
        local duration = self.options.duration or 5
        if duration > 0 then
            task.delay(duration, function()
                if self.isVisible and not self.isDestroyed then
                    self:Destroy()
                end
            end)
        end
    end
    
    function notification:Destroy()
        if self.isDestroyed then return end
        self.isDestroyed = true
        
        if self.frame then
            createTween(
                self.frame,
                {Position = UDim2.new(1, 300, 0, 0)},
                0.3,
                Enum.EasingStyle.Back,
                Enum.EasingDirection.In
            ):Play()
            
            for i, notif in ipairs(activeNotifications) do
                if notif == self then
                    table.remove(activeNotifications, i)
                    break
                end
            end
            
            task.delay(0.1, function()
                Notifications.processQueue()
            end)
            
            task.delay(0.3, function()
                if self.frame and self.frame.Parent then
                    self.frame:Destroy()
                    self.frame = nil
                end
            end)
        end
    end
    
    if #activeNotifications < maxNotificationsVisible then
        table.insert(activeNotifications, notification)
        notification:Show()
    else
        table.insert(notificationQueue, notification)
    end
    
    return notification
end

function AdonisEngine.Start(title, iconId, DevMode)
    local self = getInstance()
    DevMode = DevMode or false

    if self.gui then
        self.gui:Destroy()
    end

    self.DevMode = DevMode

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
    Notifications.createContainer(self.gui)

    if self.DevMode then
        self:Notify("DevMode Enabled", "AdonisEngine is running in developer mode", "success", 5)
    end

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

function AdonisEngine:Section(name)
    local self = getInstance()

    if not name or type(name) ~= "string" then
        name = "Unnamed Section"
        if self.DevMode then
            self:Notify("Missing Parameter", "Section name is required", "warning", 3)
        end
    end

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

    if self.DevMode then
        self:Notify("Section Created", "Section '" .. name .. "' created successfully", "success", 3)
    end

    return section
end

function AdonisEngine:Button(text, section, callback)
    local self = getInstance()

    if not section or not section.container then
        if #self.sections > 0 then
            section = self.sections[1]
        else
            section = self:Section("Default")
        end

        if self.DevMode then
            self:Notify("Missing Parameter", "Section not specified for button", "warning", 3)
        end
    end

    if not text or type(text) ~= "string" then
        text = "Button"
        if self.DevMode then
            self:Notify("Missing Parameter", "Button text is required", "warning", 3)
        end
    end

    if not callback or type(callback) ~= "function" then
        callback = function() end
        if self.DevMode then
            self:Notify("Missing Parameter", "Button callback is required", "warning", 3)
        end
    end

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

        task.spawn(callback)
    end)

    table.insert(section.elements, button)

    if self.DevMode then
        self:Notify("Button Created", "Button '" .. text .. "' created successfully", "success", 3)
    end

    return button
end

function AdonisEngine:Notify(title, description, notifyType, duration, sound, options)
    local self = getInstance()

    if not title or type(title) ~= "string" then
        title = "Notification"
        if self.DevMode then
            description = "Missing title parameter in Notify function" .. (description and (": " .. description) or "")
            notifyType = "warning"
        end
    end

    description = description or ""
    notifyType = notifyType or "success"
    duration = duration or 5

    local validTypes = {error = true, success = true, warning = true}
    if not validTypes[notifyType] then
        notifyType = "success"
        if self.DevMode then
            description = "Invalid notification type: " .. tostring(notifyType) .. ". " .. description
            notifyType = "warning"
        end
    end

    local notificationOptions = {
        duration = duration,
        sound = sound
    }

    if options and type(options) == "table" then
        notificationOptions.buttons = options
    end

    return Notifications.show(self.gui, title, description, notifyType, notificationOptions)
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