local AnimationModule = {}

function AnimationModule.start(text, color)
    -- Validate and set default color
    local colorSettings = {
        red = {
            textColor = Color3.fromRGB(180, 30, 30),
            textStroke = Color3.fromRGB(100, 0, 0),
            glowColor = Color3.fromRGB(120, 20, 20),
            lineColor = Color3.fromRGB(180, 30, 30)
        },
        yellow = {
            textColor = Color3.fromRGB(180, 180, 30),
            textStroke = Color3.fromRGB(100, 100, 0),
            glowColor = Color3.fromRGB(120, 120, 20),
            lineColor = Color3.fromRGB(180, 180, 30)
        },
        blue = {
            textColor = Color3.fromRGB(30, 90, 180),
            textStroke = Color3.fromRGB(0, 50, 100),
            glowColor = Color3.fromRGB(20, 60, 120),
            lineColor = Color3.fromRGB(30, 90, 180)
        },
        white = {
            textColor = Color3.fromRGB(220, 220, 220),
            textStroke = Color3.fromRGB(150, 150, 150),
            glowColor = Color3.fromRGB(180, 180, 180),
            lineColor = Color3.fromRGB(220, 220, 220)
        }
    }
    
    -- Set default to red if no color provided
    color = color or "red"
    
    -- Validate color input
    if not colorSettings[color] then
        warn("Invalid color! Available options: yellow, red, blue, white. Defaulting to red.")
        color = "red"
    end
    
    local selectedColor = colorSettings[color]

    local player = game.Players.LocalPlayer
    local TweenService = game:GetService("TweenService")

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CustomIntroAnimation"
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    background.BackgroundTransparency = 1
    background.Parent = screenGui

    local logoContainer = Instance.new("Frame")
    logoContainer.Name = "LogoContainer"
    logoContainer.Size = UDim2.new(0.6, 0, 0.3, 0)
    logoContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
    logoContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    logoContainer.BackgroundTransparency = 1
    logoContainer.Parent = background

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "CustomText"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text or "Custom Animation"
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 48
    textLabel.TextColor3 = selectedColor.textColor
    textLabel.TextTransparency = 1
    textLabel.TextStrokeTransparency = 1
    textLabel.TextStrokeColor3 = selectedColor.textStroke
    textLabel.Parent = logoContainer

    local glowEffect = Instance.new("Frame")
    glowEffect.Name = "GlowEffect"
    glowEffect.Size = UDim2.new(2, 0, 2, 0)
    glowEffect.Position = UDim2.new(0.5, 0, 0.5, 0)
    glowEffect.AnchorPoint = Vector2.new(0.5, 0.5)
    glowEffect.BackgroundColor3 = selectedColor.glowColor
    glowEffect.BackgroundTransparency = 1
    glowEffect.ZIndex = -1
    glowEffect.Parent = background

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 15, 15)),
        ColorSequenceKeypoint.new(0.5, selectedColor.glowColor),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 15))
    })
    gradient.Parent = glowEffect

    local line = Instance.new("Frame")
    line.Name = "Line"
    line.Size = UDim2.new(0, 0, 0.02, 0)
    line.Position = UDim2.new(0.5, 0, 0.7, 0)
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.BackgroundColor3 = selectedColor.lineColor
    line.BorderSizePixel = 0
    line.Parent = background

    local function playAnimation()
        local bgTween = TweenService:Create(
            background,
            TweenInfo.new(0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0}
        )
        bgTween:Play()

        task.wait(0.5)

        local glowTween = TweenService:Create(
            glowEffect,
            TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {BackgroundTransparency = 0.7, Size = UDim2.new(3, 0, 3, 0)}
        )
        glowTween:Play()

        local rotationTween = TweenService:Create(
            gradient,
            TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1),
            {Rotation = 360}
        )
        rotationTween:Play()

        local textTween = TweenService:Create(
            textLabel,
            TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            {TextTransparency = 0, TextStrokeTransparency = 0.7}
        )
        textTween:Play()

        local lineTween1 = TweenService:Create(
            line,
            TweenInfo.new(0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            {Size = UDim2.new(0.6, 0, 0.02, 0)}
        )
        lineTween1:Play()

        task.wait(2.5)

        local fadeOutBg = TweenService:Create(
            background,
            TweenInfo.new(0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
            {BackgroundTransparency = 1}
        )

        local fadeOutText = TweenService:Create(
            textLabel,
            TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
            {TextTransparency = 1, TextStrokeTransparency = 1}
        )

        local fadeOutGlow = TweenService:Create(
            glowEffect,
            TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
            {BackgroundTransparency = 1}
        )

        local fadeOutLine = TweenService:Create(
            line,
            TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
            {BackgroundTransparency = 1}
        )

        fadeOutText:Play()
        fadeOutGlow:Play()
        fadeOutLine:Play()
        fadeOutBg:Play()

        task.wait(1)
        screenGui:Destroy()
    end

    playAnimation()
end

return AnimationModule