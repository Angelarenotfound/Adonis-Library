local Tools = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

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

local function create(className, props)
    local instance = Instance.new(className)
    for prop, val in pairs(props) do
        -- Si es una tabla y es una propiedad de texto, convertir a string solo si es necesario
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

function Tools.Button(engine, text, section, callback)
    local self = engine

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

    local buttonContainer = create("Frame", {
        Parent = section.container,
        Size = UDim2.new(1, -20, 0, 35),  -- Reducido el ancho para evitar desbordamiento
        BackgroundColor3 = self.theme and self.theme.surface or Color3.fromRGB(30, 30, 35),
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
        Size = UDim2.new(1, -10, 0.8, 0),
        Position = UDim2.new(0, 2, 0.1, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = self.theme and self.theme.text or Color3.fromRGB(230, 230, 230),
        TextSize = 14,
        Font = Enum.Font.SourceSansSemibold,
        ClipsDescendants = true,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    button.MouseEnter:Connect(function()
        createTween(buttonContainer, {
            BackgroundColor3 = self.theme and self.theme.accent or Color3.fromRGB(80, 80, 85),
            BackgroundTransparency = 0.7
        }, 0.2):Play()
    end)

    button.MouseLeave:Connect(function()
        createTween(buttonContainer, {
            BackgroundColor3 = self.theme and self.theme.surface or Color3.fromRGB(30, 30, 35),
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

    local component = Component.new(buttonContainer)

    local id = #self.components + 1
    self.components[id] = component

    if self.DevMode then
        self:Notify("Button Created", "Button '" .. text .. "' created successfully", "success", 3)
    end

    return component
end

function Tools.Toggle(engine, text, section, default, callback)
    local self = engine

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
        BackgroundColor3 = self.theme and self.theme.surface or Color3.fromRGB(30, 30, 35),
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
        TextColor3 = self.theme and self.theme.text or Color3.fromRGB(230, 230, 230),
        TextSize = 14,
        Font = Enum.Font.SourceSansSemibold,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Toggle switch background
    local toggleBackground = create("Frame", {
        Parent = toggleContainer,
        Size = UDim2.new(0, 50, 0, 25),
        Position = UDim2.new(1, -60, 0.5, -12),
        BackgroundColor3 = default and (self.theme and self.theme.accent or Color3.fromRGB(80, 80, 85)) or (self.theme and self.theme.secondary or Color3.fromRGB(50, 50, 55)),
        BorderSizePixel = 0
    })

    create("UICorner", {
        Parent = toggleBackground,
        CornerRadius = UDim.new(1, 0)
    })

    -- Toggle switch knob
    local toggleKnob = create("Frame", {
        Parent = toggleBackground,
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(default and 1 or 0, default and -22 or 2, 0.5, -10),
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
            BackgroundColor3 = enabled and (self.theme and self.theme.accent or Color3.fromRGB(80, 80, 85)) or (self.theme and self.theme.secondary or Color3.fromRGB(50, 50, 55))
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

function Tools.Menu(engine, text, section, options, callback)
    local self = engine

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
        Size = UDim2.new(1, -20, 0, 40),  -- Reducido el ancho para evitar desbordamiento
        BackgroundColor3 = self.theme and self.theme.surface or Color3.fromRGB(30, 30, 35),
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
        Size = UDim2.new(0.35, 0, 1, 0),  -- Reducido el ancho para dar más espacio al dropdown
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = self.theme and self.theme.text or Color3.fromRGB(230, 230, 230),
        TextSize = 14,
        Font = Enum.Font.SourceSansSemibold,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Dropdown button
    local dropdownButton = create("TextButton", {
        Parent = menuContainer,
        Size = UDim2.new(0.6, 0, 0, 30),
        Position = UDim2.new(0.35, 10, 0.5, -15),  -- Ajustado para estar más cerca del label
        BackgroundColor3 = self.theme and self.theme.secondary or Color3.fromRGB(50, 50, 55),
        BackgroundTransparency = 0.2,
        Text = options[1],
        TextColor3 = self.theme and self.theme.text or Color3.fromRGB(230, 230, 230),
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
        TextColor3 = self.theme and self.theme.text or Color3.fromRGB(230, 230, 230),
        TextSize = 12,
        Font = Enum.Font.SourceSansBold
    })

    -- Dropdown menu
    local dropdownMenu = create("Frame", {
        Parent = menuContainer,
        Size = UDim2.new(0.55, 0, 0, 0), -- Will be resized when opened
        Position = UDim2.new(0.4, 0, 1, 5),  -- Ajustado para alinearse mejor con el botón
        BackgroundColor3 = self.theme and self.theme.surface or Color3.fromRGB(30, 30, 35),
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
        Color = self.theme and self.theme.accent or Color3.fromRGB(80, 80, 85),
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
            BackgroundColor3 = self.theme and self.theme.secondary or Color3.fromRGB(50, 50, 55),
            BackgroundTransparency = 0.5,
            Text = optionText,
            TextColor3 = self.theme and self.theme.text or Color3.fromRGB(230, 230, 230),
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
                BackgroundColor3 = self.theme and self.theme.accent or Color3.fromRGB(80, 80, 85)
            }, 0.2):Play()
        end)

        option.MouseLeave:Connect(function()
            createTween(option, {
                BackgroundTransparency = 0.5,
                BackgroundColor3 = self.theme and self.theme.secondary or Color3.fromRGB(50, 50, 55)
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

return Tools
