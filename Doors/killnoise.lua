local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
if not localPlayer then return end

local autoSmashEnabled = false
local noclipEnabled = false
local noclipEndTime = 0
local scanCooldown = 0.5
local lastScanTime = 0
local currentHighlight = nil

local function clearESP()
    if currentHighlight then
        currentHighlight:Destroy()
        currentHighlight = nil
    end
end

local function findTelevision()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name:match("Television") or obj.Name:match("TV") or (obj.Parent and obj.Parent.Name:match("Noise"))) then
            if not obj.Anchored then
                return obj
            end
        end
    end
    return nil
end

local function updateESP(tv)
    if tv then
        if not currentHighlight or currentHighlight.Parent ~= tv then
            clearESP()
            local highlight = Instance.new("Highlight")
            highlight.Name = "TV_ESP"
            highlight.FillColor = Color3.fromRGB(0, 220, 255)
            highlight.FillTransparency = 0.6
            highlight.OutlineColor = Color3.fromRGB(255, 170, 0)
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = tv
            currentHighlight = highlight
        end
    else
        clearESP()
    end
end

local function smashTelevision()
    local character = localPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    
    local tv = findTelevision()
    if tv then
        local success = pcall(function()
            local lookDirection = rootPart.CFrame.LookVector
            tv.AssemblyLinearVelocity = (lookDirection * 200) + Vector3.new(0, -150, 0)
            tv.AssemblyAngularVelocity = Vector3.new(math.random(-10, 10), math.random(-10, 10), math.random(-10, 10))
        end)
        return success
    end
    return false
end

local function teleportToTelevision()
    local character = localPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    
    local tv = findTelevision()
    if tv then
        local success = pcall(function()
            rootPart.CFrame = tv.CFrame * CFrame.new(0, 3, 0)
            noclipEnabled = true
            noclipEndTime = tick() + 2
        end)
        return success
    end
    return false
end

-- 建立 GUI (強制掛載到 PlayerGui 確保 Delta 可見)
local playerGui = localPlayer:WaitForChild("PlayerGui")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DoorsUtilityV4"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 240, 0, 245)
MainFrame.Position = UDim2.new(0.5, -120, 0.4, -122)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 10)
FrameCorner.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 35)
TitleLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
TitleLabel.Text = "  DOORS UTILITY V4"
TitleLabel.TextColor3 = Color3.fromRGB(255, 170, 0)
TitleLabel.TextSize = 14
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleLabel

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = MainFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local Spacer = Instance.new("Frame")
Spacer.Size = UDim2.new(1, 0, 0, 35)
Spacer.BackgroundTransparency = 1
Spacer.LayoutOrder = 0
Spacer.Parent = MainFrame

local SmashButton = Instance.new("TextButton")
SmashButton.Size = UDim2.new(0, 210, 0, 32)
SmashButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
SmashButton.Text = "💥 手動擊碎電視"
SmashButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SmashButton.TextSize = 13
SmashButton.Font = Enum.Font.SourceSansBold
SmashButton.LayoutOrder = 1
SmashButton.Parent = MainFrame
Instance.new("UICorner", SmashButton).CornerRadius = UDim.new(0, 6)

local TpButton = Instance.new("TextButton")
TpButton.Size = UDim2.new(0, 210, 0, 32)
TpButton.BackgroundColor3 = Color3.fromRGB(40, 120, 180)
TpButton.Text = "🚀 傳送 (防卡穿牆)"
TpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TpButton.TextSize = 13
TpButton.Font = Enum.Font.SourceSansBold
TpButton.LayoutOrder = 2
TpButton.Parent = MainFrame
Instance.new("UICorner", TpButton).CornerRadius = UDim.new(0, 6)

local AutoToggleBtn = Instance.new("TextButton")
AutoToggleBtn.Size = UDim2.new(0, 210, 0, 32)
AutoToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
AutoToggleBtn.Text = "🌀 自動循環偵測：❌ 關閉"
AutoToggleBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
AutoToggleBtn.TextSize = 13
AutoToggleBtn.Font = Enum.Font.SourceSansBold
AutoToggleBtn.LayoutOrder = 3
AutoToggleBtn.Parent = MainFrame
Instance.new("UICorner", AutoToggleBtn).CornerRadius = UDim.new(0, 6)

local DistanceLabel = Instance.new("TextLabel")
DistanceLabel.Size = UDim2.new(0, 210, 0, 22)
DistanceLabel.BackgroundTransparency = 1
DistanceLabel.Text = "📡 電視距離：未偵測到"
DistanceLabel.TextColor3 = Color3.fromRGB(0, 220, 255)
DistanceLabel.TextSize = 12
DistanceLabel.Font = Enum.Font.SourceSansBold
DistanceLabel.LayoutOrder = 4
DistanceLabel.Parent = MainFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 22)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "狀態：就緒"
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusLabel.TextSize = 12
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.LayoutOrder = 5
StatusLabel.Parent = MainFrame

local function updateStatus(text, color)
    StatusLabel.Text = "狀態：" .. text
    StatusLabel.TextColor3 = color
end

SmashButton.MouseButton1Click:Connect(function()
    if smashTelevision() then
        updateStatus("已對電視施加毀滅力道！", Color3.fromRGB(0, 255, 100))
    else
        updateStatus("未找到未錨定的電視。", Color3.fromRGB(255, 100, 100))
    end
end)

TpButton.MouseButton1Click:Connect(function()
    if teleportToTelevision() then
        updateStatus("傳送成功！穿牆已啟動(2s)", Color3.fromRGB(0, 180, 255))
    else
        updateStatus("無法傳送，地圖上目前沒有電視。", Color3.fromRGB(255, 100, 100))
    end
end)

AutoToggleBtn.MouseButton1Click:Connect(function()
    autoSmashEnabled = not autoSmashEnabled
    if autoSmashEnabled then
        AutoToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
        AutoToggleBtn.Text = "🌀 自動循環偵測：✅ 開啟"
        AutoToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        updateStatus("自動偵測中...", Color3.fromRGB(0, 255, 100))
    else
        AutoToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        AutoToggleBtn.Text = "🌀 自動循環偵測：❌ 關閉"
        AutoToggleBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        updateStatus("自動偵測已關閉。", Color3.fromRGB(150, 150, 150))
    end
end)

RunService.Stepped:Connect(function()
    local character = localPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    
    if noclipEnabled then
        if tick() < noclipEndTime then
            if character then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        else
            noclipEnabled = false
            updateStatus("就緒 (穿牆已恢復)", Color3.fromRGB(150, 150, 150))
        end
    end
    
    local tv = findTelevision()
    updateESP(tv)
    
    if tv and rootPart then
        local distance = (rootPart.Position - tv.Position).Magnitude
        DistanceLabel.Text = string.format("📡 電視距離：%0.1f 公尺", distance)
        DistanceLabel.TextColor3 = Color3.fromRGB(0, 220, 255)
    else
        DistanceLabel.Text = "📡 電視距離：未偵測到"
        DistanceLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
    
    if autoSmashEnabled then
        local currentTime = tick()
        if currentTime - lastScanTime >= scanCooldown then
            lastScanTime = currentTime
            smashTelevision()
        end
    end
end)

print("[DOORS Utility V4] 載入成功！")
