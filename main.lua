local AdonisEngine = {}
AdonisEngine.__index = AdonisEngine

local theme = {
    background = Color3.fromRGB(13, 13, 18),
    surface = Color3.fromRGB(22, 22, 28),
    accent = Color3.fromRGB(110, 90, 255),
    text = Color3.fromRGB(240, 240, 240),
    divider = Color3.fromRGB(45, 45, 55)
}

local function create(className, props)
    local instance = Instance.new(className)
    for prop, val in pairs(props) do
        instance[prop] = val
    end
    return instance
end

function AdonisEngine.new(title, iconId)
    local self = setmetatable({}, AdonisEngine)
    
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

    local displayTitle = if type(title) == "string" and title ~= "" then title else "Adonis Except"
    local displayIconId = if type(iconId) == "number" then iconId else 110915885697382
    
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
        ScaleType = Enum.ScaleType.Fit
    })

    create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = self.icon
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
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(1, -40, 0.5, -16),
        BackgroundColor3 = Color3.fromRGB(200, 60, 60),
        Text = "X",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 18,
        Font = Enum.Font.GothamBold
    })

    create("UICorner", {
        CornerRadius = UDim.new(0.5, 0),
        Parent = self.closeButton
    })

    self.closeButton.MouseButton1Click:Connect(function()
        self:ShowConfirmationModal()
    end)
end

function AdonisEngine:ShowConfirmationModal()
    self.modal = create("Frame", {
        Parent = self.gui,
        Size = UDim2.new(0.4, 0, 0.3, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundColor3 = theme.surface,
        ZIndex = 10
    })

    create("UICorner", {
        Parent = self.modal,
        CornerRadius = UDim.new(0.08, 0)
    })

    local modalStroke = create("UIStroke", {
        Parent = self.modal,
        Color = theme.accent,
        Thickness = 2
    })

    local message = create("TextLabel", {
        Parent = self.modal,
        Size = UDim2.new(1, -40, 0.5, 0),
        Position = UDim2.new(0, 20, 0, 20),
        BackgroundTransparency = 1,
        Text = "¿Estás seguro de que quieres cerrar esta ventana?",
        TextColor3 = theme.text,
        TextSize = 16,
        Font = Enum.Font.GothamMedium,
        TextWrapped = true
    })

    local buttonContainer = create("Frame", {
        Parent = self.modal,
        Size = UDim2.new(1, -40, 0.3, 0),
        Position = UDim2.new(0, 20, 0.6, 0),
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
        CanvasSize = UDim2.new(0, 0, 0, 0)
    })

    create("UICorner", {
        CornerRadius = UDim.new(0.06, 0),
        Parent = self.leftPanel
    })

    self.rightPanel = create("ScrollingFrame", {
        Parent = self.contentFrame,
        Size = UDim2.new(0.7, -5, 1, 0),
        Position = UDim2.new(0.3, 5, 0, 0),
        BackgroundColor3 = theme.surface,
        ScrollBarThickness = 4,
        CanvasSize = UDim2.new(0, 0, 0, 0)
    })

    create("UICorner", {
        CornerRadius = UDim.new(0.06, 0),
        Parent = self.rightPanel
    })

    create("Frame", {
        Parent = self.contentFrame,
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(0.3, 0, 0, 0),
        BackgroundColor3 = theme.divider,
        BorderSizePixel = 0
    })
end

function AdonisEngine:Destroy()
    if self.gui then
        self.gui:Destroy()
    end
end

local function Start(title, iconId)
    return AdonisEngine.new(title, iconId)
end

return {
    Start = Start
}