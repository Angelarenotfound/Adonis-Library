local Notifications = {}
local TweenService = game:GetService("TweenService")

local notificationQueue = {}
local maxNotificationsVisible = 5
local activeNotifications = {}

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

    local mousePos = game:GetService("UserInputService"):GetMouseLocation() - Vector2.new(button.AbsolutePosition.X, button.AbsolutePosition.Y)
    ripple.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)

    local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2.5
    local appearTween = createTween(ripple, {Size = UDim2.new(0, maxSize, 0, maxSize), BackgroundTransparency = 1}, 0.6)
    appearTween:Play()

    appearTween.Completed:Connect(function()
        ripple:Destroy()
    end)
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

return Notifications
