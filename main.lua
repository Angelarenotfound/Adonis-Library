local AdonisEngine = {}
AdonisEngine.__index = AdonisEngine

local _instance = nil

local theme = {
    background = Color3.fromRGB(0, 0, 0),
    surface = Color3.fromRGB(10, 10, 12),
    accent = Color3.fromRGB(180, 30, 30),
    text = Color3.fromRGB(230, 230, 230),
    divider = Color3.fromRGB(30, 30, 35),
    error = Color3.fromRGB(220, 40, 40),
    success = Color3.fromRGB(40, 180, 80),
    warning = Color3.fromRGB(220, 150, 30),
    secondary = Color3.fromRGB(50, 50, 55)
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
        Size = UDim2.new(0.78, 0, 0.9, 0),
        BackgroundColor3 = theme.background,
        BackgroundTransparency = 0,
        ClipsDescendants = true
    })

    create("UICorner", {
        Parent = self.mainFrame,
        CornerRadius = UDim.new(0.02, 0)
    })
    
    local mainBorder = create("UIStroke", {
        Parent = self.mainFrame,
        Color = theme.divider,
        Thickness = 1,
        Transparency = 0.5
    })
    
    local glow = create("ImageLabel", {
        Parent = self.mainFrame,
        Size = UDim2.new(1, 60, 1, 60),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6014261993",
        ImageColor3 = theme.accent,
        ImageTransparency = 0.9,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = self.mainFrame.ZIndex - 1
    })

    local displayTitle = (type(title) == "string" and title ~= "") and title or "Adonis Except"
    local displayIconId = (type(iconId) == "number") and iconId or 110915885697382

    self:CreateTopBar(displayTitle, displayIconId)
    self:CreateContentArea()

    self.mainFrame.Position = UDim2.new(0.5, 0, -1.5, 0)
    self.mainFrame.Visible = true

    local enterAnim = game:GetService("TweenService"):Create(
        self.mainFrame,
        TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0),
        {Position = UDim2.new(0.5, 0, 0.5, 0)}
    )
    enterAnim:Play()

    self.gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    self.notificationContainer = Notifications.createContainer(self.gui)

    if self.DevMode then
        self:Notify("DevMode Enabled", "AdonisEngine is running in developer mode", "success", 5)
    end

    return self
end

function AdonisEngine:CreateTopBar(title, iconId)
    self.topBar = create("Frame", {
        Parent = self.mainFrame,
        Size = UDim2.new(1, 0, 0.06, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = theme.surface,
        BorderSizePixel = 0
    })

    create("UICorner", {
        Parent = self.topBar,
        CornerRadius = UDim.new(0.02, 0)
    })
    
    local topBarBorder = create("UIStroke", {
        Parent = self.topBar,
        Color = theme.divider,
        Thickness = 1,
        Transparency = 0.7
    })
    
    local gradient = create("UIGradient", {
        Parent = self.topBar,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, theme.surface),
            ColorSequenceKeypoint.new(1, theme.surface:Lerp(theme.accent, 0.1))
        }),
        Rotation = 90
    })

    self.icon = create("ImageLabel", {
        Parent = self.topBar,
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(0.015, 0, 0.5, -12),
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
    
    local iconGlow = create("ImageLabel", {
        Parent = self.icon,
        Size = UDim2.new(1, 8, 1, 8),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6014261993",
        ImageColor3 = theme.accent,
        ImageTransparency = 0.7,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = self.icon.ZIndex - 1
    })
    
    spawn(function()
        while self.gui and self.gui.Parent do
            local glowTween = TweenService:Create(
                iconGlow,
                TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                {ImageTransparency = 0.5, Size = UDim2.new(1, 12, 1, 12)}
            )
            glowTween:Play()
            wait(4)
            
            if not self.gui or not self.gui.Parent then
                break
            end
        end
    end)

    self.title = create("TextLabel", {
        Parent = self.topBar,
        Size = UDim2.new(0.8, 0, 1, 0),
        Position = UDim2.new(0.06, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = string.upper(tostring(title)),
        TextColor3 = theme.text,
        TextSize = 16,
        Font = Enum.Font.SourceSansSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = 0
    })

    self.closeButton = create("TextButton", {
        Parent = self.topBar,
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(1, -30, 0.5, -12),
        BackgroundTransparency = 1,
        Text = "✕",
        TextColor3 = theme.text,
        TextSize = 16,
        Font = Enum.Font.SourceSansBold
    })

    self.closeButton.MouseEnter:Connect(function()
        createTween(self.closeButton, {
            TextColor3 = theme.error,
            TextSize = 18
        }, 0.2):Play()
    end)

    self.closeButton.MouseLeave:Connect(function()
        createTween(self.closeButton, {
            TextColor3 = theme.text,
            TextSize = 16
        }, 0.2):Play()
    end)

    self.closeButton.MouseButton1Click:Connect(function()
        createRippleEffect(self.closeButton, theme.error)
        self:ShowConfirmationModal()
    end)
    
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

function AdonisEngine:ShowConfirmationModal()
    if self.modal then return end

    self.modal = create("Frame", {
        Parent = self.gui,
        Size = UDim2.new(0.35, 0, 0.2, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundColor3 = theme.surface,
        BackgroundTransparency = 0
    })

    create("UICorner", {
        Parent = self.modal,
        CornerRadius = UDim.new(0.02, 0)
    })

    local modalBorder = create("UIStroke", {
        Parent = self.modal,
        Color = theme.accent,
        Thickness = 1.5,
        Transparency = 0.2
    })
    
    spawn(function()
        while self.modal and self.modal.Parent do
            local borderTween = TweenService:Create(
                modalBorder,
                TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                {Transparency = 0.6, Color = theme.accent:Lerp(Color3.new(1, 1, 1), 0.2)}
            )
            borderTween:Play()
            wait(4)
            
            if not self.modal or not self.modal.Parent then
                break
            end
        end
    end)
    
    local modalShadow = create("ImageLabel", {
        Parent = self.modal,
        Size = UDim2.new(1, 40, 1, 40),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.5,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = self.modal.ZIndex - 1
    })

    local message = create("TextLabel", {
        Parent = self.modal,
        Size = UDim2.new(1, -40, 0.5, -20),
        Position = UDim2.new(0, 20, 0, 20),
        BackgroundTransparency = 1,
        Text = "¿Are you sure you want to close the Gui?",
        TextColor3 = theme.text,
        TextSize = 16,
        Font = Enum.Font.SourceSansSemibold,
        TextWrapped = true
    })

    local buttonContainer = create("Frame", {
        Parent = self.modal,
        Size = UDim2.new(1, -40, 0.3, 0),
        Position = UDim2.new(0, 20, 0.65, 0),
        BackgroundTransparency = 1
    })

    local acceptButton = create("TextButton", {
        Parent = buttonContainer,
        Size = UDim2.new(0.45, 0, 0.7, 0),
        Position = UDim2.new(0, 0, 0.15, 0),
        BackgroundColor3 = theme.accent,
        Text = "ACCEPT",
        TextColor3 = theme.text,
        TextSize = 14,
        Font = Enum.Font.SourceSansSemibold,
        ClipsDescendants = true
    })

    create("UICorner", {
        Parent = acceptButton,
        CornerRadius = UDim.new(0.1, 0)
    })
    
    local acceptShadow = create("ImageLabel", {
        Parent = acceptButton,
        Size = UDim2.new(1, 8, 1, 8),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.7,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = acceptButton.ZIndex - 1
    })

    local declineButton = create("TextButton", {
        Parent = buttonContainer,
        Size = UDim2.new(0.45, 0, 0.7, 0),
        Position = UDim2.new(0.55, 0, 0.15, 0),
        BackgroundColor3 = theme.secondary,
        Text = "DECLINE",
        TextColor3 = theme.text,
        TextSize = 14,
        Font = Enum.Font.SourceSansSemibold,
        ClipsDescendants = true
    })

    create("UICorner", {
        Parent = declineButton,
        CornerRadius = UDim.new(0.1, 0)
    })
    
    local declineShadow = create("ImageLabel", {
        Parent = declineButton,
        Size = UDim2.new(1, 8, 1, 8),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.7,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = declineButton.ZIndex - 1
    })
    
    acceptButton.MouseEnter:Connect(function()
        createTween(acceptButton, {
            BackgroundColor3 = theme.accent:Lerp(Color3.new(1, 1, 1), 0.2),
            Size = UDim2.new(0.46, 0, 0.75, 0),
            Position = UDim2.new(0, 0, 0.125, 0)
        }, 0.2):Play()
    end)
    
    acceptButton.MouseLeave:Connect(function()
        createTween(acceptButton, {
            BackgroundColor3 = theme.accent,
            Size = UDim2.new(0.45, 0, 0.7, 0),
            Position = UDim2.new(0, 0, 0.15, 0)
        }, 0.2):Play()
    end)
    
    declineButton.MouseEnter:Connect(function()
        createTween(declineButton, {
            BackgroundColor3 = theme.error:Lerp(theme.secondary, 0.7),
            Size = UDim2.new(0.46, 0, 0.75, 0),
            Position = UDim2.new(0.54, 0, 0.125, 0)
        }, 0.2):Play()
    end)
    
    declineButton.MouseLeave:Connect(function()
        createTween(declineButton, {
            BackgroundColor3 = theme.secondary,
            Size = UDim2.new(0.45, 0, 0.7, 0),
            Position = UDim2.new(0.55, 0, 0.15, 0)
        }, 0.2):Play()
    end)

    acceptButton.MouseButton1Click:Connect(function()
        createRippleEffect(acceptButton, Color3.fromRGB(255, 255, 255))
        self:Destroy()
    end)

    declineButton.MouseButton1Click:Connect(function()
        createRippleEffect(declineButton, Color3.fromRGB(255, 255, 255))
        self.modal:Destroy()
        self.modal = nil
    end)
    
    self.modal.Size = UDim2.new(0, 0, 0, 0)
    self.modal.BackgroundTransparency = 1
    modalShadow.ImageTransparency = 1
    
    local modalEnterTween = TweenService:Create(
        self.modal,
        TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.new(0.35, 0, 0.2, 0), BackgroundTransparency = 0}
    )
    
    local shadowEnterTween = TweenService:Create(
        modalShadow,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {ImageTransparency = 0.5}
    )
    
    modalEnterTween:Play()
    shadowEnterTween:Play()
end

function AdonisEngine:CreateContentArea()
    self.contentFrame = create("Frame", {
        Parent = self.mainFrame,
        Size = UDim2.new(1, -20, 0.93, -15),
        Position = UDim2.new(0, 10, 0.06, 10),
        BackgroundTransparency = 1
    })

    self.leftPanel = create("ScrollingFrame", {
        Parent = self.contentFrame,
        Size = UDim2.new(0.25, -5, 1, 0),
        BackgroundColor3 = theme.surface,
        ScrollBarThickness = 3,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y
    })

    create("UICorner", {
        Parent = self.leftPanel,
        CornerRadius = UDim.new(0.02, 0)
    })
    
    create("UIStroke", {
        Parent = self.leftPanel,
        Color = theme.divider,
        Thickness = 1,
        Transparency = 0.8
    })

    self.rightPanel = create("ScrollingFrame", {
        Parent = self.contentFrame,
        Size = UDim2.new(0.75, -5, 1, 0),
        Position = UDim2.new(0.25, 5, 0, 0),
        BackgroundColor3 = theme.surface,
        ScrollBarThickness = 3,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y
    })

    create("UICorner", {
        Parent = self.rightPanel,
        CornerRadius = UDim.new(0.02, 0)
    })
    
    create("UIStroke", {
        Parent = self.rightPanel,
        Color = theme.divider,
        Thickness = 1,
        Transparency = 0.8
    })
    
    local leftGradient = create("UIGradient", {
        Parent = self.leftPanel,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, theme.surface),
            ColorSequenceKeypoint.new(1, theme.surface:Lerp(theme.background, 0.3))
        }),
        Rotation = 90
    })
    
    local rightGradient = create("UIGradient", {
        Parent = self.rightPanel,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, theme.surface),
            ColorSequenceKeypoint.new(1, theme.surface:Lerp(theme.background, 0.3))
        }),
        Rotation = 90
    })

    local divider = create("Frame", {
        Parent = self.contentFrame,
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(0.25, 0, 0, 0),
        BackgroundColor3 = theme.divider,
        BorderSizePixel = 0
    })

    create("UIListLayout", {
        Parent = self.leftPanel,
        Padding = UDim.new(0, 6),
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
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundColor3 = theme.accent,
        BackgroundTransparency = 0.8,
        Text = name,
        TextColor3 = theme.text,
        TextSize = 14,
        Font = Enum.Font.SourceSansSemibold,
        LayoutOrder = #self.sections + 1,
        ClipsDescendants = true
    })

    create("UICorner", {
        Parent = sectionButton,
        CornerRadius = UDim.new(0.1, 0)
    })
    
    create("UIStroke", {
        Parent = sectionButton,
        Color = theme.accent,
        Thickness = 1,
        Transparency = 0.8
    })
    
    local buttonShadow = create("ImageLabel", {
        Parent = sectionButton,
        Size = UDim2.new(1, 6, 1, 6),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.8,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = sectionButton.ZIndex - 1
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
    
    sectionButton.MouseEnter:Connect(function()
        createTween(sectionButton, {
            BackgroundTransparency = 0.6,
            TextSize = 15
        }, 0.2):Play()
    end)
    
    sectionButton.MouseLeave:Connect(function()
        createTween(sectionButton, {
            BackgroundTransparency = sectionContainer.Visible and 0.6 or 0.8,
            TextSize = 14
        }, 0.2):Play()
    end)

    sectionButton.MouseButton1Click:Connect(function()
        createRippleEffect(sectionButton, Color3.fromRGB(255, 255, 255))
        
        for _, sec in ipairs(self.sections) do
            sec.container.Visible = false
            createTween(sec.button, {BackgroundTransparency = 0.8}, 0.2):Play()
        end

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

    local button = create("TextButton", {
        Parent = section.container,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = theme.secondary,
        BackgroundTransparency = 0.4,
        Text = text,
        TextColor3 = theme.text,
        TextSize = 14,
        Font = Enum.Font.SourceSansSemibold,
        LayoutOrder = #section.elements + 1,
        ClipsDescendants = true
    })

    create("UICorner", {
        Parent = button,
        CornerRadius = UDim.new(0.1, 0)
    })

    local buttonStroke = create("UIStroke", {
        Parent = button,
        Color = theme.accent,
        Transparency = 0.7,
        Thickness = 1
    })
    
    local buttonShadow = create("ImageLabel", {
        Parent = button,
        Size = UDim2.new(1, 6, 1, 6),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.8,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = button.ZIndex - 1
    })
    
    button.MouseEnter:Connect(function()
        createTween(button, {
            BackgroundTransparency = 0.2,
            TextSize = 15
        }, 0.2):Play()
        
        createTween(buttonStroke, {
            Transparency = 0.4,
            Thickness = 1.5
        }, 0.2):Play()
    end)

    button.MouseLeave:Connect(function()
        createTween(button, {
            BackgroundTransparency = 0.4,
            TextSize = 14
        }, 0.2):Play()
        
        createTween(buttonStroke, {
            Transparency = 0.7,
            Thickness = 1
        }, 0.2):Play()
    end)

    button.MouseButton1Click:Connect(function()
        createRippleEffect(button, Color3.fromRGB(255, 255, 255))
        
        createTween(button, {
            BackgroundTransparency = 0.1
        }, 0.1):Play()

        task.delay(0.1, function()
            createTween(button, {
                BackgroundTransparency = 0.4
            }, 0.1):Play()
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
        local exitTween = TweenService:Create(
            self.mainFrame,
            TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.In),
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
    Notify = AdonisEngine.Notify,
    Destroy = AdonisEngine.Destroy
}

return AE