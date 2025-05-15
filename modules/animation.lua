local module = {}

function module.start(Text)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local TweenService = game:GetService("TweenService")
    local ContentProvider = game:GetService("ContentProvider")
    local SoundService = game:GetService("SoundService")

    local function createIntroAnimation()
        local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
        
        if PlayerGui:FindFirstChild("AdonisIntro") then
            PlayerGui.AdonisIntro:Destroy()
        end
        
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "AdonisIntro"
        screenGui.IgnoreGuiInset = true
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.DisplayOrder = 999
        screenGui.Parent = PlayerGui
        
        local background = Instance.new("Frame")
        background.Name = "Background"
        background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        background.BorderSizePixel = 0
        background.Size = UDim2.new(1, 0, 1, 0)
        background.ZIndex = 1
        background.Parent = screenGui
        
        local container = Instance.new("Frame")
        container.Name = "Container"
        container.BackgroundTransparency = 1
        container.Position = UDim2.new(0.5, 0, 0.5, 0)
        container.AnchorPoint = Vector2.new(0.5, 0.5)
        container.Size = UDim2.new(1, 0, 1, 0)
        container.ZIndex = 2
        container.Parent = screenGui
        
        local mainText = Instance.new("TextLabel")
        mainText.Name = "MainText"
        mainText.BackgroundTransparency = 1
        mainText.Position = UDim2.new(0.5, 0, 0.5, 0)
        mainText.AnchorPoint = Vector2.new(0.5, 0.5)
        mainText.Size = UDim2.new(0, 0, 0, 0)
        mainText.ZIndex = 3
        mainText.Font = Enum.Font.GothamBold
        mainText.Text = Text or "Adonis Library"
        mainText.TextColor3 = Color3.fromRGB(255, 255, 255)
        mainText.TextSize = 0
        mainText.TextTransparency = 1
        mainText.Parent = container
        
        local particleContainer = Instance.new("Frame")
        particleContainer.Name = "ParticleContainer"
        particleContainer.BackgroundTransparency = 1
        particleContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
        particleContainer.AnchorPoint = Vector2.new(0.5, 0.5)
        particleContainer.Size = UDim2.new(1, 0, 1, 0)
        particleContainer.ZIndex = 2
        particleContainer.Parent = container
        
        local logoCircle = Instance.new("ImageLabel")
        logoCircle.Name = "LogoCircle"
        logoCircle.BackgroundTransparency = 1
        logoCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
        logoCircle.AnchorPoint = Vector2.new(0.5, 0.5)
        logoCircle.Size = UDim2.new(0, 0, 0, 0)
        logoCircle.ZIndex = 2
        logoCircle.Image = "rbxassetid://3570695787"
        logoCircle.ImageColor3 = Color3.fromRGB(0, 120, 255)
        logoCircle.ImageTransparency = 1
        logoCircle.Parent = container
        
        local glow = Instance.new("ImageLabel")
        glow.Name = "Glow"
        glow.BackgroundTransparency = 1
        glow.Position = UDim2.new(0.5, 0, 0.5, 0)
        glow.AnchorPoint = Vector2.new(0.5, 0.5)
        glow.Size = UDim2.new(0, 0, 0, 0)
        glow.ZIndex = 1
        glow.Image = "rbxassetid://1316045217"
        glow.ImageColor3 = Color3.fromRGB(0, 120, 255)
        glow.ImageTransparency = 1
        glow.Parent = container
        
        local underline = Instance.new("Frame")
        underline.Name = "Underline"
        underline.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        underline.BorderSizePixel = 0
        underline.Position = UDim2.new(0.5, 0, 0.58, 0)
        underline.AnchorPoint = Vector2.new(0.5, 0)
        underline.Size = UDim2.new(0, 0, 0, 2)
        underline.ZIndex = 3
        underline.Parent = container
        
        local sound = Instance.new("Sound")
        sound.Name = "IntroSound"
        sound.SoundId = "rbxassetid://6570735334"
        sound.Volume = 0.5
        sound.Parent = screenGui
        
        for i = 1, 20 do
            local particle = Instance.new("Frame")
            particle.Name = "Particle_"..i
            particle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            particle.BorderSizePixel = 0
            particle.AnchorPoint = Vector2.new(0.5, 0.5)
            local size = math.random(2, 4)
            particle.Size = UDim2.new(0, size, 0, size)
            local angle = math.rad(math.random(1, 360))
            local distance = math.random(300, 600)
            local posX = math.cos(angle) * distance
            local posY = math.sin(angle) * distance
            particle.Position = UDim2.new(0.5, posX, 0.5, posY)
            particle.BackgroundTransparency = 1
            particle.ZIndex = 2
            particle.Parent = particleContainer
        end
        
        local function playAnimation()
            sound:Play()
            
            local logoAppearInfo = TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            local logoAppearProps = {
                Size = UDim2.new(0, 300, 0, 300),
                ImageTransparency = 0.7
            }
            local logoAppearTween = TweenService:Create(logoCircle, logoAppearInfo, logoAppearProps)
            logoAppearTween:Play()
            
            local glowAppearInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local glowAppearProps = {
                Size = UDim2.new(0, 400, 0, 400),
                ImageTransparency = 0.5
            }
            local glowAppearTween = TweenService:Create(glow, glowAppearInfo, glowAppearProps)
            glowAppearTween:Play()
            
            for _, particle in pairs(particleContainer:GetChildren()) do
                if particle:IsA("Frame") then
                    local delay = math.random(1, 30)/100
                    spawn(function()
                        wait(delay)
                        local particleInfo = TweenInfo.new(
                            math.random(70, 120)/100, 
                            Enum.EasingStyle.Quad, 
                            Enum.EasingDirection.InOut
                        )
                        local endPosX = math.random(-150, 150)
                        local endPosY = math.random(-150, 150)
                        local particleProps = {
                            Position = UDim2.new(0.5, endPosX, 0.5, endPosY),
                            BackgroundTransparency = 0.5
                        }
                        local particleTween = TweenService:Create(particle, particleInfo, particleProps)
                        particleTween:Play()
                    end)
                end
            end
            
            wait(0.3)
            
            local textAppearInfo = TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            local textAppearProps = {
                Size = UDim2.new(0, 0, 0, 60),
                TextSize = 48,
                TextTransparency = 0
            }
            local textAppearTween = TweenService:Create(mainText, textAppearInfo, textAppearProps)
            textAppearTween:Play()
            
            textAppearTween.Completed:Connect(function()
                local textScaleInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                local textScaleProps = {
                    Size = UDim2.new(0, 400, 0, 60)
                }
                local textScaleTween = TweenService:Create(mainText, textScaleInfo, textScaleProps)
                textScaleTween:Play()
                
                local underlineInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                local underlineProps = {
                    Size = UDim2.new(0, 300, 0, 2)
                }
                local underlineTween = TweenService:Create(underline, underlineInfo, underlineProps)
                underlineTween:Play()
            end)
            
            wait(3)
            
            local fadeOutInfo = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            
            local textFadeProps = {
                TextTransparency = 1,
                TextSize = 60
            }
            local textFadeTween = TweenService:Create(mainText, fadeOutInfo, textFadeProps)
            textFadeTween:Play()
            
            local logoFadeProps = {
                Size = UDim2.new(0, 350, 0, 350),
                ImageTransparency = 1
            }
            local logoFadeTween = TweenService:Create(logoCircle, fadeOutInfo, logoFadeProps)
            logoFadeTween:Play()
            
            local glowFadeProps = {
                Size = UDim2.new(0, 500, 0, 500),
                ImageTransparency = 1
            }
            local glowFadeTween = TweenService:Create(glow, fadeOutInfo, glowFadeProps)
            glowFadeTween:Play()
            
            local underlineFadeProps = {
                Size = UDim2.new(0, 400, 0, 2),
                BackgroundTransparency = 1
            }
            local underlineFadeTween = TweenService:Create(underline, fadeOutInfo, underlineFadeProps)
            underlineFadeTween:Play()
            
            for _, particle in pairs(particleContainer:GetChildren()) do
                if particle:IsA("Frame") then
                    local particleFadeInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                    local particleFadeProps = {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(
                            particle.Position.X.Scale, 
                            particle.Position.X.Offset + math.random(-100, 100), 
                            particle.Position.Y.Scale, 
                            particle.Position.Y.Offset + math.random(-100, 100)
                    }
                    local particleFadeTween = TweenService:Create(particle, particleFadeInfo, particleFadeProps)
                    particleFadeTween:Play()
                end
            end
            
            local bgFadeInfo = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            local bgFadeProps = {
                BackgroundTransparency = 1
            }
            local bgFadeTween = TweenService:Create(background, bgFadeInfo, bgFadeProps)
            bgFadeTween:Play()
            
            wait(0.8)
            screenGui:Destroy()
        end
        
        playAnimation()
    end

    if game.Players.LocalPlayer then
        createIntroAnimation()
    else
        game.Players:GetPropertyChangedSignal("LocalPlayer"):Connect(function()
            if game.Players.LocalPlayer then
                createIntroAnimation()
                game.Players:GetPropertyChangedSignal("LocalPlayer"):Disconnect()
            end
        end)
    end
end

return module