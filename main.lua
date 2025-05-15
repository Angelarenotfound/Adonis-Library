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
    
    title = tostring(title or "Adonis Library")
    iconId = tonumber(iconId) or 7072716642
    
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
    
    self:CreateTopBar(title, iconId)
    self:CreateContentArea()
    self:SetupAutoDestroy()
    
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
        CornerRadius = UDim.new(0, 0, 0, 0.08, 0, 0.08)
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
        Text = string.upper(title),
        TextColor3 = theme.text,
        TextSize = 18,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = 0.1
    })
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

function AdonisEngine:SetupAutoDestroy(destroyTime)
    destroyTime = destroyTime or 10
    local startTime = os.clock()

    self.destroyConnection = game:GetService("RunService").Heartbeat:Connect(function()
        local elapsed = os.clock() - startTime
        if elapsed >= destroyTime then
            local exitAnim = game:GetService("TweenService"):Create(
                self.mainFrame,
                TweenInfo.new(0.6, Enum.EasingStyle.Quint),
                {Position = UDim2.new(0.5, 0, 1.5, 0)}
            )
            exitAnim:Play()
            exitAnim.Completed:Wait()
            self:Destroy()
        end
    end)
end

function AdonisEngine:Destroy()
    if self.destroyConnection then
        self.destroyConnection:Disconnect()
    end
    self.gui:Destroy()
end

local function Start(title, iconId)
    return AdonisEngine.new(title, iconId)
end

return {
    Start = Start
}