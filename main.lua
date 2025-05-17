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

local Notify = loadstring(game:HttpGet("https://raw.githubusercontent.com/Angelarenotfound/Adonis-Library/refs/heads/main/modules/notify.lua"))()
local Tools = loadstring(game:HttpGet("https://raw.githubusercontent.com/Angelarenotfound/Adonis-Library/refs/heads/main/modules/components.lua"))()

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local function getInstance()
    if not _instance then
        _instance = setmetatable({}, AdonisEngine)
        _instance.sections = {}
        _instance.components = {}
    end
    return _instance
end

local function create(className, props)
    local instance = Instance.new(className)
    for prop, val in pairs(props) do
        if type(val) == "table" and (prop == "Text" or prop == "Name" or prop == "Font" or prop == "Image" or prop == "SoundId" or prop == "Title" or prop == "PlaceholderText") then
            if val[1] ~= nil then
                instance[prop] = tostring(val[1])
            else
                instance[prop] = "Valor no especificado"
            end
        else
            instance[prop] = val
        end
    end
    return instance
end

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

function AdonisEngine.Start(title, options)
    local self = getInstance()
    options = options or {}

    if options.background then
        theme.background = options.background
    end

    if self.gui then
        self.gui:Destroy()
    end

    self.DevMode = options.DevMode or false

    local guiTitle = "Adonis Library"
    if title then
        if type(title) == "string" then
            guiTitle = title
        else
            guiTitle = tostring(title)
        end
    end

    self.gui = create("ScreenGui", {
        Name = guiTitle,
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

    self:CreateTopBar(guiTitle)
    self:CreateContentArea()

    self.mainFrame.Position = UDim2.new(0.5, 0, -1, 0)
    self.mainFrame.Visible = true

    local enterAnim = TweenService:Create(
        self.mainFrame,
        TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, 0, 0.5, 0)}
    )
    enterAnim:Play()

    self.gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    self.notificationContainer = Notify.createContainer(self.gui)

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

    local topBarCornerFix = create("Frame", {
        Parent = self.topBar,
        Size = UDim2.new(1, 0, 0.5, 0),
        Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = theme.surface,
        BorderSizePixel = 0
    })

    self.icon = create("ImageLabel", {
        Parent = self.topBar,
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(0, 15, 0.5, -12),
        BackgroundTransparency = 1,
        Image = "rbxassetid://11743702977",
        ScaleType = Enum.ScaleType.Fit
    })

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

    self.closeButton = create("TextButton", {
        Parent = self.topBar,
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -35, 0.5, -15),
        BackgroundTransparency = 1,
        Text = "X",
        TextColor3 = theme.text,
        TextSize = 18,
        Font = Enum.Font.SourceSansBold
    })

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

    self.closeButton.MouseButton1Click:Connect(function()
        createRippleEffect(self.closeButton, theme.error)
        self:Destroy()
    end)

    self.minimizeButton.MouseButton1Click:Connect(function()
        createRippleEffect(self.minimizeButton, theme.accent)
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

    self.leftPanel = create("ScrollingFrame", {
        Parent = self.contentFrame,
        Size = UDim2.new(0.22, 0, 1, 0),
        BackgroundColor3 = theme.surface,
        BackgroundTransparency = 0.2,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = theme.accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        BorderSizePixel = 0
    })

    self.rightPanel = create("ScrollingFrame", {
        Parent = self.contentFrame,
        Size = UDim2.new(0.78, 0, 1, 0),
        Position = UDim2.new(0.22, 0, 0, 0),
        BackgroundColor3 = theme.background,
        BackgroundTransparency = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = theme.accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
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
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5)
    })

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

    local icon = create("ImageLabel", {
        Parent = sectionButton,
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 5, 0.5, -8),
        BackgroundTransparency = 1,
        Image = "rbxassetid://11743702977",
        ImageColor3 = theme.text
    })

    sectionButton.Text = "   " .. name

    create("UICorner", {
        Parent = sectionButton,
        CornerRadius = UDim.new(0, 4)
    })

    local sectionContainer = create("Frame", {
        Parent = self.rightPanel,
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = #self.sections == 0
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
    return Tools.Button(self, text, section, callback)
end

function AdonisEngine:Toggle(text, section, default, callback)
    return Tools.Toggle(self, text, section, default, callback)
end

function AdonisEngine:Menu(text, section, options, callback)
    return Tools.Menu(self, text, section, options, callback)
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

    return Notify.show(self.gui, title, description, notifyType, notificationOptions)
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