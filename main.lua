local AdonisEngine = {}
AdonisEngine.__index = AdonisEngine

local _instance = nil

local theme = {
    background = Color3.fromRGB(20, 20, 25),
    surface = Color3.fromRGB(30, 30, 35),
    accent = Color3.fromRGB(80, 80, 85),
    text = Color3.fromRGB(230, 230, 230),
    divider = Color3.fromRGB(50, 50, 55),
    error = Color3.fromRGB(220, 40, 40),
    success = Color3.fromRGB(40, 180, 80),
    warning = Color3.fromRGB(220, 150, 30),
    secondary = Color3.fromRGB(50, 50, 55)
}

local function create(className, props)
    local instance = Instance.new(className)
    for prop, val in pairs(props) do
        if type(val) == "table" and (prop == "Text" or prop == "Name" or prop == "Font" or prop == "Image" or prop == "SoundId" or prop == "Title" or prop == "PlaceholderText") then
            instance[prop] = tostring(val)
        else
            instance[prop] = val
        end
    end
    return instance
end

local function getInstance()
    if not _instance then
        _instance = setmetatable({}, AdonisEngine)
        _instance.sections = {}
        _instance.components = {}
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

    local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2.5
    local appearTween = createTween(ripple, {Size = UDim2.new(0, maxSize, 0, maxSize), BackgroundTransparency = 1}, 0.6)
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

-- Component base class
local Component = {}
Component.__index = Component

function Component.new(instance)
    local self = setmetatable({}, Component)
    self.instance = instance
    return self
end

function Component:Destroy()
    if self.instance and self.instance.Parent then
        self.instance:Destroy()
        self.instance = nil
    end
end

function Component:Edit(props)
    if not self.instance then return end
    
    for prop, value in pairs(props) do
        if prop == "Text" and self.instance:IsA("TextButton") or self.instance:IsA("TextLabel") then
            self.instance.Text = value
        elseif prop == "BackgroundColor3" then
            self.instance.BackgroundColor3 = value
        elseif prop == "TextColor3" then
            self.instance.TextColor3 = value
        elseif prop == "Visible" then
            self.instance.Visible = value
        elseif prop == "Size" then
            self.instance.Size = value
        elseif prop == "Position" then
            self.instance.Position = value
        end
    end
end

function Notifications.createContainer(mainGui)
    local container = Instance.new("Frame")
    container.Name = "NotificationsContainer"
    container.Size = UDim2.new(0, 320, 1, -40)
    container.Position = UDim2.new(1, -340, 0, 20)
    container.BackgroundTransparency = 1
    container.Parent = mainGui

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 10)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    listLayout.Parent = container

    return container
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

    local notificationContainer = mainGui:FindFirstChild("NotificationsContainer")
    if not notificationContainer then
        notificationContainer = Notifications.createContainer(mainGui)
    end

    local notification = {
        mainGui = mainGui,
        container = notificationContainer,
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

        local notificationHeight = self.options.height or (self.options.buttons and 140 or 100)

        self.frame = Instance.new("Frame")
        self.frame.Size = UDim2.new(1, 0, 0, notificationHeight)
        self.frame.BackgroundColor3 = theme.surface
        self.frame.BorderSizePixel = 0
        self.frame.Position = UDim2.new(1, 300, 0, 0)
        self.frame.AnchorPoint = Vector2.new(0, 0)
        self.frame.Parent = self.container

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
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = self.frame

        local borderFrame = Instance.new("Frame")
        borderFrame.Size = UDim2.new(1, 0, 1, 0)
        borderFrame.BackgroundTransparency = 1
        borderFrame.BorderSizePixel = 0
        borderFrame.ZIndex = self.frame.ZIndex
        borderFrame.Parent = self.frame

        local borderUIStroke = Instance.new("UIStroke")
        borderUIStroke.Color = notificationColor
        borderUIStroke.Thickness = 1.5
        borderUIStroke.Transparency = 0.2
        borderUIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        borderUIStroke.Parent = borderFrame

        local borderCorner = Instance.new("UICorner")
        borderCorner.CornerRadius = UDim.new(0, 6)
        borderCorner.Parent = borderFrame

        spawn(function()
            while self.frame and self.frame.Parent do
                local pulseTween = TweenService:Create(
                    borderUIStroke,
                    TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                    {Transparency = 0.7}
                )
                pulseTween:Play()

                local colorTween = TweenService:Create(
                    borderUIStroke,
                    TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                    {Color = notificationColor:Lerp(Color3.new(1, 1, 1), 0.2)}
                )
                colorTween:Play()

                wait(3)

                if not self.frame or not self.frame.Parent then
                    break
                end
            end
        end)

        local leftAccent = Instance.new("Frame")
        leftAccent.Size = UDim2.new(0, 3, 1, 0)
        leftAccent.Position = UDim2.new(0, 0, 0, 0)
        leftAccent.BackgroundColor3 = notificationColor
        leftAccent.BorderSizePixel = 0
        leftAccent.Parent = self.frame

        local leftCorner = Instance.new("UICorner")
        leftCorner.CornerRadius = UDim.new(0, 6)
        leftCorner.Parent = leftAccent

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, -60, 0, 28)
        titleLabel.Position = UDim2.new(0, 15, 0, 15)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Enum.Font.SourceSansSemibold
        titleLabel.TextSize = 18
        titleLabel.TextColor3 = theme.text
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Text = self.title
        titleLabel.Parent = self.frame

        local descriptionLabel = Instance.new("TextLabel")
        descriptionLabel.Size = UDim2.new(1, -30, 0, 50)
        descriptionLabel.Position = UDim2.new(0, 15, 0, 43)
        descriptionLabel.BackgroundTransparency = 1
        descriptionLabel.Font = Enum.Font.SourceSans
        descriptionLabel.TextSize = 15
        descriptionLabel.TextColor3 = theme.text
        descriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
        descriptionLabel.TextYAlignment = Enum.TextYAlignment.Top
        descriptionLabel.TextWrapped = true
        descriptionLabel.Text = self.description
        descriptionLabel.Parent = self.frame

        if self.options.buttons then
            local buttonContainer = Instance.new("Frame")
            buttonContainer.Size = UDim2.new(1, -30, 0, 35)
            buttonContainer.Position = UDim2.new(0, 15, 1, -45)
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
                button.Size = UDim2.new(0, 90, 1, 0)
                button.BackgroundColor3 = i == 1 and notificationColor or theme.secondary
                button.BorderSizePixel = 0
                button.Font = Enum.Font.SourceSansSemibold
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
                buttonShadow.ImageTransparency = 0.7
                buttonShadow.ScaleType = Enum.ScaleType.Slice
                buttonShadow.SliceCenter = Rect.new(49, 49, 450, 450)
                buttonShadow.ZIndex = button.ZIndex - 1
                buttonShadow.Parent = button

                button.MouseEnter:Connect(function()
                    createTween(button, {
                        BackgroundColor3 = i == 1 and 
                            Color3.new(
                                math.min(notificationColor.R + 0.15, 1),
                                math.min(notificationColor.G + 0.15, 1),
                                math.min(notificationColor.B + 0.15, 1)
                            ) or theme.accent:Lerp(theme.secondary, 0.5),
                        Size = UDim2.new(0, 95, 1, 0)
                    }, 0.2):Play()
                end)

                button.MouseLeave:Connect(function()
                    createTween(button, {
                        BackgroundColor3 = i == 1 and notificationColor or theme.secondary,
                        Size = UDim2.new(0, 90, 1, 0)
                    }, 0.2):Play()
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
        closeButton.Size = UDim2.new(0, 28, 0, 28)
        closeButton.Position = UDim2.new(1, -35, 0, 15)
        closeButton.BackgroundTransparency = 1
        closeButton.Font = Enum.Font.SourceSansBold
        closeButton.TextSize = 16
        closeButton.TextColor3 = theme.text
        closeButton.Text = "✕"
        closeButton.Parent = self.frame

        closeButton.MouseEnter:Connect(function()
            createTween(closeButton, {
                TextColor3 = theme.error,
                TextSize = 18
            }, 0.2):Play()
        end)

        closeButton.MouseLeave:Connect(function()
            createTween(closeButton, {
                TextColor3 = theme.text,
                TextSize = 16
            }, 0.2):Play()
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

        self.frame.BackgroundTransparency = 1
        shadow.ImageTransparency = 1

        local appearTween = TweenService:Create(
            self.frame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0, Position = UDim2.new(0, 0, 0, 0)}
        )

        local shadowTween = TweenService:Create(
            shadow,
            TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            {ImageTransparency = 0.5}
        )

        appearTween:Play()
        shadowTween:Play()

        appearTween.Completed:Connect(function()
            if self.frame and self.frame.Parent then
                local bounceTween = createTween(
                    self.frame,
                    {Position = UDim2.new(0, -5, 0, 0)},
                    0.15,
                    Enum.EasingStyle.Quad,
                    Enum.EasingDirection.Out
                )
                bounceTween:Play()

                bounceTween.Completed:Connect(function()
                    if self.frame and self.frame.Parent then
                        createTween(
                            self.frame,
                            {Position = UDim2.new(0, 0, 0, 0)},
                            0.1,
                            Enum.EasingStyle.Quad,
                            Enum.EasingDirection.Out
                        ):Play()
                    end
                end)
            end
        end)

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
            local exitTween = createTween(
                self.frame,
                {Position = UDim2.new(1, 300, 0, 0), BackgroundTransparency = 1, Rotation = 2},
                0.4,
                Enum.EasingStyle.Back,
                Enum.EasingDirection.In
            )
            exitTween:Play()

            for i, notif in ipairs(activeNotifications) do
                if notif == self then
                    table.remove(activeNotifications, i)
                    break
                end
            end

            task.delay(0.1, function()
                Notifications.processQueue()
            end)

            task.delay(0.4, function()
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

function AdonisEngine.Start(title, options)
    local self = getInstance()
    options = options or {}
    
    -- Set custom background if provided
    if options.background then
        theme.background = options.background
    end
    
    if self.gui then
        self.gui:Destroy()
    end

    self.DevMode = options.DevMode or false

    self.gui = create("ScreenGui", {
        Name = title or "Adonis Library",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        DisplayOrder = 999
    })

    self.mainFrame = create("Frame", {
        Parent = self.gui,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0.7, 0, 0.9, 0),
        BackgroundColor3 = theme.background,
        BackgroundTransparency = 0,
        ClipsDescendants = true
    })

    create("UICorner", {
        Parent = self.mainFrame,
        CornerRadius = UDim.new(0, 8)
    })

    local mainBorder = create("UIStroke", {
        Parent = self.mainFrame,
        Color = theme.divider,
        Thickness = 1,
        Transparency = 0.5
    })

    -- Create top bar with title and controls
    self:CreateTopBar(title or "Adonis Library")
    self:CreateContentArea()

    -- Animation for opening
    self.mainFrame.Position = UDim2.new(0.5, 0, -1, 0)
    self.mainFrame.Visible = true

    local enterAnim = TweenService:Create(
        self.mainFrame,
        TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, 0, 0.5, 0)}
    )
    enterAnim:Play()

    self.gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    self.notificationContainer = Notifications.createContainer(self.gui)

    if self.DevMode then
        self:Notify("DevMode Enabled", "Adonis Library is running in developer mode", "success", 5)
    end

    return self
end

function AdonisEngine:CreateTopBar(title)
    self.topBar = create("Frame", {
        Parent = self.mainFrame,
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = theme.surface,
        BorderSizePixel = 0
    })

    create("UICorner", {
        Parent = self.topBar,
        CornerRadius = UDim.new(0, 8)
    })

    -- Only round the top corners
    local topBarCornerFix = create("Frame", {
        Parent = self.topBar,
        Size = UDim2.new(1, 0, 0.5, 0),
        Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = theme.surface,
        BorderSizePixel = 0
    })

    -- Logo/Icon
    self.icon = create("ImageLabel", {
        Parent = self.topBar,
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(0, 15, 0.5, -12),
        BackgroundTransparency = 1,
        Image = "rbxassetid://11743702977", -- Placeholder icon
        ScaleType = Enum.ScaleType.Fit
    })

    -- Title
    self.title = create("TextLabel", {
        Parent = self.topBar,
        Size = UDim2.new(0.7, 0, 1, 0),
        Position = UDim2.new(0, 45, 0, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = theme.text,
        TextSize = 16,
        Font = Enum.Font.SourceSansSemibold,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Search button
    self.searchButton = create("TextButton", {
        Parent = self.topBar,
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(1, -80, 0.5, -12),
        BackgroundTransparency = 1,
        Text = "🔍",
        TextColor3 = theme.text,
        TextSize = 16,
        Font = Enum.Font.SourceSansBold
    })

    -- Minimize button
    self.minimizeButton = create("TextButton", {
        Parent = self.topBar,
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(1, -50, 0.5, -12),
        BackgroundTransparency = 1,
        Text = "—",
        TextColor3 = theme.text,
        TextSize = 16,
        Font = Enum.Font.SourceSansBold
    })

    -- Close button
    self.closeButton = create("TextButton", {
        Parent = self.topBar,
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(1, -25, 0.5, -12),
        BackgroundTransparency = 1,
        Text = "✕",
        TextColor3 = theme.text,
        TextSize = 16,
        Font = Enum.Font.SourceSansBold
    })

    -- Button hover effects
    for _, button in pairs({self.searchButton, self.minimizeButton, self.closeButton}) do
        button.MouseEnter:Connect(function()
            createTween(button, {
                TextColor3 = button == self.closeButton and theme.error or theme.accent,
                TextSize = 18
            }, 0.2):Play()
        end)

        button.MouseLeave:Connect(function()
            createTween(button, {
                TextColor3 = theme.text,
                TextSize = 16
            }, 0.2):Play()
        end)
    end

    -- Close button functionality
    self.closeButton.MouseButton1Click:Connect(function()
        createRippleEffect(self.closeButton, theme.error)
        self:Destroy()
    end)

    -- Minimize button functionality
    self.minimizeButton.MouseButton1Click:Connect(function()
        createRippleEffect(self.minimizeButton, theme.accent)
        -- Toggle minimized state
        if not self.minimized then
            createTween(self.mainFrame, {
                Size = UDim2.new(0.7, 0, 0, 40)
            }, 0.3):Play()
            self.minimized = true
        else
            createTween(self.mainFrame, {
                Size = UDim2.new(0.7, 0, 0.7, 0)
            }, 0.3):Play()
            self.minimized = false
        end
    end)

    -- Make the window draggable
    local dragInput
    local dragStart
    local startPos

    local function updateDrag(input)
        local delta = input.Position - dragStart
        self.mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    self.topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragStart = input.Position
            startPos = self.mainFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragInput = nil
                end
            end)
        end
    end)

    self.topBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragStart then
            updateDrag(input)
        end
    end)
end

function AdonisEngine:CreateContentArea()
    self.contentFrame = create("Frame", {
        Parent = self.mainFrame,
        Size = UDim2.new(1, 0, 1, -40),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundTransparency = 1
    })

    -- Left sidebar for navigation
    self.leftPanel = create("ScrollingFrame", {
        Parent = self.contentFrame,
        Size = UDim2.new(0.25, 0, 1, 0),
        BackgroundColor3 = theme.surface,
        BackgroundTransparency = 0.2,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = theme.accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        BorderSizePixel = 0
    })

    -- Main content area
    self.rightPanel = create("ScrollingFrame", {
        Parent = self.contentFrame,
        Size = UDim2.new(0.75, 0, 1, 0),
        Position = UDim2.new(0.25, 0, 0, 0),
        BackgroundColor3 = theme.background,
        BackgroundTransparency = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = theme.accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        BorderSizePixel = 0
    })

    -- List layout for the sidebar items
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

    -- Padding for the main content
    create("UIPadding", {
        Parent = self.rightPanel,
        PaddingTop = UDim.new(0, 20),
        PaddingBottom = UDim.new(0, 20),
        PaddingLeft = UDim.new(0, 20),
        PaddingRight = UDim.new(0, 20)
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

    -- Create a section button in the sidebar
    local sectionButton = create("TextButton", {
        Parent = self.leftPanel,
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = theme.accent,
        BackgroundTransparency = 0.8,
        Text = name,
        TextColor3 = theme.text,
        TextSize = 14,
        Font = Enum.Font.SourceSansSemibold,
        LayoutOrder = #self.sections + 1,
        ClipsDescendants = true,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Add an icon to the section button
    local icon = create("ImageLabel", {
        Parent = sectionButton,
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 5, 0.5, -8),
        BackgroundTransparency = 1,
        Image = "rbxassetid://11743702977", -- Placeholder icon
        ImageColor3 = theme.text
    })

    -- Adjust text position to account for icon
    sectionButton.Text = "   " .. name

    create("UICorner", {
        Parent = sectionButton,
        CornerRadius = UDim.new(0, 4)
    })

    -- Create a container for the section's content
    local sectionContainer = create("Frame", {
        Parent = self.rightPanel,
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = #self.sections == 0 -- First section is visible by default
    })

    create("UIListLayout", {
        Parent = sectionContainer,
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center
    })

    create("UIPadding", {
        Parent = sectionContainer,
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5),
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5)
    })

    local section = {
        name = name,
        button = sectionButton,
        container = sectionContainer,
        elements = {}
    }

    table.insert(self.sections, section)

    -- Button hover and click effects
    sectionButton.MouseEnter:Connect(function()
        createTween(sectionButton, {
            BackgroundTransparency = 0.6
        }, 0.2):Play()
    end)

    sectionButton.MouseLeave:Connect(function()
        createTween(sectionButton, {
            BackgroundTransparency = sectionContainer.Visible and 0.6 or 0.8
        }, 0.2):Play()
    end)

    sectionButton.MouseButton1Click:Connect(function()
        createRippleEffect(sectionButton, Color3.fromRGB(255, 255, 255))

        -- Hide all other sections
        for _, sec in ipairs(self.sections) do
            sec.container.Visible = false
            createTween(sec.button, {BackgroundTransparency = 0.8}, 0.2):Play()
        end

        -- Show this section
        sectionContainer.Visible = true
        createTween(sectionButton, {BackgroundTransparency = 0.6}, 0.2):Play()
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

    -- Create button container
    local buttonContainer = create("Frame", {
        Parent = section.container,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = theme.surface,
        BackgroundTransparency = 0.2,
        LayoutOrder = #section.elements + 1
    })

    create("UICorner", {
        Parent = buttonContainer,
        CornerRadius = UDim.new(0, 6)
    })

    -- Create the actual button
    local button = create("TextButton", {
        Parent = buttonContainer,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = theme.text,
        TextSize = 14,
        Font = Enum.Font.SourceSansSemibold,
        ClipsDescendants = true
    })

    -- Button hover and click effects
    button.MouseEnter:Connect(function()
        createTween(buttonContainer, {
            BackgroundColor3 = theme.accent,
            BackgroundTransparency = 0.7
        }, 0.2):Play()
    end)

    button.MouseLeave:Connect(function()
        createTween(buttonContainer, {
            BackgroundColor3 = theme.surface,
            BackgroundTransparency = 0.2
        }, 0.2):Play()
    end)

    button.MouseButton1Click:Connect(function()
        createRippleEffect(button, Color3.fromRGB(255, 255, 255))
        
        createTween(buttonContainer, {
            BackgroundTransparency = 0.5
        }, 0.1):Play()

        task.delay(0.1, function()
            createTween(buttonContainer, {
                BackgroundTransparency = 0.2
            }, 0.1):Play()
        end)

        task.spawn(callback)
    end)

    table.insert(section.elements, buttonContainer)
    
    -- Create component object with methods
    local component = Component.new(buttonContainer)
    
    -- Store in components table
    local id = #self.components + 1
    self.components[id] = component
    
    if self.DevMode then
        self:Notify("Button Created", "Button '" .. text .. "' created successfully", "success", 3)
    end

    return component
end

function AdonisEngine:Toggle(text, section, default, callback)
    local self = getInstance()

    if not section or not section.container then
        if #self.sections > 0 then
            section = self.sections[1]
        else
            section = self:Section("Default")
        end

        if self.DevMode then
            self:Notify("Missing Parameter", "Section not specified for toggle", "warning", 3)
        end
    end

    if not text or type(text) ~= "string" then
        text = "Toggle"
        if self.DevMode then
            self:Notify("Missing Parameter", "Toggle text is required", "warning", 3)
        end
    end

    if type(default) ~= "boolean" then
        default = false
    end

    if not callback or type(callback) ~= "function" then
        callback = function() end
        if self.DevMode then
            self:Notify("Missing Parameter", "Toggle callback is required", "warning", 3)
        end
    end

    -- Create toggle container
    local toggleContainer = create("Frame", {
        Parent = section.container,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = theme.surface,
        BackgroundTransparency = 0.2,
        LayoutOrder = #section.elements + 1
    })

    create("UICorner", {
        Parent = toggleContainer,
        CornerRadius = UDim.new(0, 6)
    })

    -- Toggle label
    local label = create("TextLabel", {
        Parent = toggleContainer,
        Size = UDim2.new(0.7, 0, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = theme.text,
        TextSize = 14,
        Font = Enum.Font.SourceSansSemibold,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Toggle switch background
    local toggleBackground = create("Frame", {
        Parent = toggleContainer,
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -50, 0.5, -10),
        BackgroundColor3 = default and theme.accent or theme.secondary,
        BorderSizePixel = 0
    })

    create("UICorner", {
        Parent = toggleBackground,
        CornerRadius = UDim.new(1, 0)
    })

    -- Toggle switch knob
    local toggleKnob = create("Frame", {
        Parent = toggleBackground,
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(default and 1 or 0, default and -18 or 2, 0.5, -8),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0
    })

    create("UICorner", {
        Parent = toggleKnob,
        CornerRadius = UDim.new(1, 0)
    })

    -- Toggle state
    local enabled = default
    
    -- Toggle functionality
    local function updateToggle()
        createTween(toggleBackground, {
            BackgroundColor3 = enabled and theme.accent or theme.secondary
        }, 0.2):Play()
        
        createTween(toggleKnob, {
            Position = UDim2.new(enabled and 1 or 0, enabled and -18 or 2, 0.5, -8)
        }, 0.2):Play()
        
        callback(enabled)
    end

    -- Make the entire container clickable
    toggleContainer.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            enabled = not enabled
            updateToggle()
        end
    end)

    table.insert(section.elements, toggleContainer)
    
    -- Create component object with methods
    local component = Component.new(toggleContainer)
    
    -- Add toggle-specific methods
    function component:SetState(state)
        if type(state) == "boolean" and state ~= enabled then
            enabled = state
            updateToggle()
        end
    end
    
    function component:GetState()
        return enabled
    end
    
    function component:Toggle()
        enabled = not enabled
        updateToggle()
        return enabled
    end
    
    -- Store in components table
    local id = #self.components + 1
    self.components[id] = component
    
    if self.DevMode then
        self:Notify("Toggle Created", "Toggle '" .. text .. "' created successfully", "success", 3)
    end

    return component
end

function AdonisEngine:Menu(text, section, options, callback)
    local self = getInstance()

    if not section or not section.container then
        if #self.sections > 0 then
            section = self.sections[1]
        else
            section = self:Section("Default")
        end

        if self.DevMode then
            self:Notify("Missing Parameter", "Section not specified for menu", "warning", 3)
        end
    end

    if not text or type(text) ~= "string" then
        text = "Menu"
        if self.DevMode then
            self:Notify("Missing Parameter", "Menu text is required", "warning", 3)
        end
    end

    if not options or type(options) ~= "table" or #options == 0 then
        options = {"Option 1", "Option 2", "Option 3"}
        if self.DevMode then
            self:Notify("Missing Parameter", "Menu options are required", "warning", 3)
        end
    end

    if not callback or type(callback) ~= "function" then
        callback = function() end
        if self.DevMode then
            self:Notify("Missing Parameter", "Menu callback is required", "warning", 3)
        end
    end

    -- Create menu container
    local menuContainer = create("Frame", {
        Parent = section.container,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = theme.surface,
        BackgroundTransparency = 0.2,
        LayoutOrder = #section.elements + 1
    })

    create("UICorner", {
        Parent = menuContainer,
        CornerRadius = UDim.new(0, 6)
    })

    -- Menu label
    local label = create("TextLabel", {
        Parent = menuContainer,
        Size = UDim2.new(0.4, 0, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = theme.text,
        TextSize = 14,
        Font = Enum.Font.SourceSansSemibold,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Dropdown button
    local dropdownButton = create("TextButton", {
        Parent = menuContainer,
        Size = UDim2.new(0.55, 0, 0, 30),
        Position = UDim2.new(0.43, 0, 0.5, -15),
        BackgroundColor3 = theme.secondary,
        BackgroundTransparency = 0.2,
        Text = options[1],
        TextColor3 = theme.text,
        TextSize = 14,
        Font = Enum.Font.SourceSans,
        ClipsDescendants = true
    })

    create("UICorner", {
        Parent = dropdownButton,
        CornerRadius = UDim.new(0, 4)
    })

    -- Dropdown arrow
    local arrow = create("TextLabel", {
        Parent = dropdownButton,
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -25, 0.5, -10),
        BackgroundTransparency = 1,
        Text = "▼",
        TextColor3 = theme.text,
        TextSize = 12,
        Font = Enum.Font.SourceSansBold
    })

    -- Dropdown menu
    local dropdownMenu = create("Frame", {
        Parent = menuContainer,
        Size = UDim2.new(0.55, 0, 0, 0), -- Will be resized when opened
        Position = UDim2.new(0.43, 0, 1, 5),
        BackgroundColor3 = theme.surface,
        BackgroundTransparency = 0,
        Visible = false,
        ZIndex = 10
    })

    create("UICorner", {
        Parent = dropdownMenu,
        CornerRadius = UDim.new(0, 4)
    })

    create("UIStroke", {
        Parent = dropdownMenu,
        Color = theme.accent,
        Thickness = 1,
        Transparency = 0.7
    })

    -- List layout for dropdown options
    local listLayout = create("UIListLayout", {
        Parent = dropdownMenu,
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center
    })

    -- Add options to dropdown
    local selectedOption = options[1]
    local isOpen = false
    
    local function updateDropdownSize()
        dropdownMenu.Size = UDim2.new(0.55, 0, 0, #options * 30 + (#options - 1) * 2)
    end
    
    local function createOption(optionText, index)
        local option = create("TextButton", {
            Parent = dropdownMenu,
            Size = UDim2.new(0.95, 0, 0, 30),
            BackgroundColor3 = theme.secondary,
            BackgroundTransparency = 0.5,
            Text = optionText,
            TextColor3 = theme.text,
            TextSize = 14,
            Font = Enum.Font.SourceSans,
            LayoutOrder = index,
            ZIndex = 10
        })

        create("UICorner", {
            Parent = option,
            CornerRadius = UDim.new(0, 4)
        })

        option.MouseEnter:Connect(function()
            createTween(option, {
                BackgroundTransparency = 0.2,
                BackgroundColor3 = theme.accent
            }, 0.2):Play()
        end)

        option.MouseLeave:Connect(function()
            createTween(option, {
                BackgroundTransparency = 0.5,
                BackgroundColor3 = theme.secondary
            }, 0.2):Play()
        end)

        option.MouseButton1Click:Connect(function()
            selectedOption = optionText
            dropdownButton.Text = optionText
            
            -- Close dropdown
            isOpen = false
            createTween(dropdownMenu, {
                Size = UDim2.new(0.55, 0, 0, 0),
                BackgroundTransparency = 1
            }, 0.2):Play()
            
            task.delay(0.2, function()
                dropdownMenu.Visible = false
            end)
            
            -- Update arrow
            createTween(arrow, {
                Rotation = 0
            }, 0.2):Play()
            
            callback(optionText, index)
        end)
        
        return option
    end
    
    -- Populate options
    for i, optionText in ipairs(options) do
        createOption(optionText, i)
    end
    
    updateDropdownSize()
    
    -- Toggle dropdown
    dropdownButton.MouseButton1Click:Connect(function()
        createRippleEffect(dropdownButton, Color3.fromRGB(255, 255, 255))
        
        isOpen = not isOpen
        
        if isOpen then
            dropdownMenu.Size = UDim2.new(0.55, 0, 0, 0)
            dropdownMenu.BackgroundTransparency = 1
            dropdownMenu.Visible = true
            
            createTween(dropdownMenu, {
                Size = UDim2.new(0.55, 0, 0, #options * 30 + (#options - 1) * 2),
                BackgroundTransparency = 0
            }, 0.2):Play()
            
            -- Rotate arrow
            createTween(arrow, {
                Rotation = 180
            }, 0.2):Play()
        else
            createTween(dropdownMenu, {
                Size = UDim2.new(0.55, 0, 0, 0),
                BackgroundTransparency = 1
            }, 0.2):Play()
            
            task.delay(0.2, function()
                dropdownMenu.Visible = false
            end)
            
            -- Reset arrow
            createTween(arrow, {
                Rotation = 0
            }, 0.2):Play()
        end
    end)
    
    -- Close dropdown when clicking elsewhere
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local position = input.Position
            local dropdownAbsPos = dropdownButton.AbsolutePosition
            local dropdownAbsSize = dropdownButton.AbsoluteSize
            
            -- Check if click is outside dropdown button and menu
            if isOpen and position.X < dropdownAbsPos.X or position.X > dropdownAbsPos.X + dropdownAbsSize.X or
               position.Y < dropdownAbsPos.Y or position.Y > dropdownAbsPos.Y + dropdownAbsSize.Y then
                
                local menuAbsPos = dropdownMenu.AbsolutePosition
                local menuAbsSize = dropdownMenu.AbsoluteSize
                
                if position.X < menuAbsPos.X or position.X > menuAbsPos.X + menuAbsSize.X or
                   position.Y < menuAbsPos.Y or position.Y > menuAbsPos.Y + menuAbsSize.Y then
                    
                    isOpen = false
                    createTween(dropdownMenu, {
                        Size = UDim2.new(0.55, 0, 0, 0),
                        BackgroundTransparency = 1
                    }, 0.2):Play()
                    
                    task.delay(0.2, function()
                        dropdownMenu.Visible = false
                    end)
                    
                    -- Reset arrow
                    createTween(arrow, {
                        Rotation = 0
                    }, 0.2):Play()
                end
            end
        end
    end)

    table.insert(section.elements, menuContainer)
    
    -- Create component object with methods
    local component = Component.new(menuContainer)
    
    -- Add menu-specific methods
    function component:SetOptions(newOptions)
        if type(newOptions) == "table" and #newOptions > 0 then
            options = newOptions
            
            -- Clear existing options
            for _, child in pairs(dropdownMenu:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end
            
            -- Add new options
            for i, optionText in ipairs(options) do
                createOption(optionText, i)
            end
            
            -- Update selected option if needed
            local found = false
            for _, opt in ipairs(options) do
                if opt == selectedOption then
                    found = true
                    break
                end
            end
            
            if not found then
                selectedOption = options[1]
                dropdownButton.Text = selectedOption
            end
            
            updateDropdownSize()
        end
    end
    
    function component:GetSelected()
        return selectedOption
    end
    
    function component:SetSelected(option)
        for i, opt in ipairs(options) do
            if opt == option then
                selectedOption = option
                dropdownButton.Text = option
                callback(option, i)
                return true
            end
        end
        return false
    end
    
    -- Store in components table
    local id = #self.components + 1
    self.components[id] = component
    
    if self.DevMode then
        self:Notify("Menu Created", "Menu '" .. text .. "' created successfully", "success", 3)
    end

    return component
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
        local exitTween = TweenService:Create(
            self.mainFrame,
            TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            {Position = UDim2.new(0.5, 0, 1.5, 0), Rotation = 5}
        )
        exitTween:Play()

        exitTween.Completed:Connect(function()
            self.gui:Destroy()
        end)
    end
end

local AE = {
    Start = AdonisEngine.Start,
    Section = AdonisEngine.Section,
    Button = AdonisEngine.Button,
    Toggle = AdonisEngine.Toggle,
    Menu = AdonisEngine.Menu,
    Notify = AdonisEngine.Notify,
    Destroy = AdonisEngine.Destroy
}

return AE