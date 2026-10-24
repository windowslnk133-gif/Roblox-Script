--!strict
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
if not localPlayer then return end

-- 🚀 全域狀態控制
local autoSmashEnabled = false
local noclipEnabled = false
local noclipEndTime = 0
local scanCooldown = 0.5 -- 循環偵測間隔（秒）
local lastScanTime = 0

-- 🎨 ESP / Highlight 控制物件
local currentHighlight: Highlight? = nil

-- 清除舊的 ESP
local function clearESP()
    if currentHighlight then
        currentHighlight:Destroy()
        currentHighlight = nil
    end
end

-- 🔍 搜尋地圖中的電視機物件
local function findTelevision(): BasePart?
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name:match("Television") or obj.Name:match("TV") or (obj.Parent and obj.Parent.Name:match("Noise"))) then
            if not obj.Anchored then
                return obj
            end
        end
    end
    return nil
end

-- 👁️ 更新 ESP 透視效果
local function updateESP(tv: BasePart?)
    if tv then
        -- 如果電視已經有 Highlight 或是我們已經建立過，就不用重複建立
        if not currentHighlight or currentHighlight.Parent ~= tv then
            clearESP()
            
            local highlight = Instance.new("Highlight")
            highlight.Name = "TV_ESP"
            highlight.FillColor = Color3.fromRGB(0, 220, 255) -- 內襯顏色
            highlight.FillTransparency = 0.6 -- 透明度
            highlight.OutlineColor = Color3.fromRGB(255, 170, 0) -- 亮眼橘色外框
            highlight.OutlineTransparency = 0 -- 外框不透明
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- 隔牆透視
            highlight.Parent = tv
            
            currentHighlight = highlight
        end
    else
        clearESP()
    end
end

-- 💥 核心功能：對電視施加毀滅性物理力道
local function smashTelevision(): boolean
    local character = localPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart") as BasePart
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

-- 🌀 傳送功能：一鍵傳送到電視機旁（附加 2 秒防卡穿牆）
local function teleportToTelevision(): boolean
    local character = localPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart") as BasePart
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

-- 🎨 建立 V4 終極版 GUI 介面
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DoorsUtilityV4"
ScreenGui.ResetOnSpawn = false

local success, _ = pcall(function() ScreenGui.Parent = CoreGui end)
if not success then ScreenGui.Parent = localPlayer:WaitForChild("PlayerGui") end

-- 主視窗
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

-- 標題列
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, 0, 0, 35)
TitleLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
TitleLabel.Text = "  DOORS UTILITY V4"
TitleLabel.TextColor3 = Color3.fromRGB(255, 170, 0)
TitleLabel.TextSize = 14
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.BorderSizePixel = 0
TitleLabel.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleLabel

-- UI 排版輔助
local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = MainFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- 頂部留空
local Spacer = Instance.new("Frame")
Spacer.Size = UDim2.new(1, 0, 0, 35)
Spacer.BackgroundTransparency = 1
Spacer.LayoutOrder = 0
Spacer.Parent = MainFrame

-- 1. 擊碎按鈕
local SmashButton = Instance.new("TextButton")
SmashButton.Size = UDim2.new(0, 210, 0, 32)
SmashButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
SmashButton.Text = "💥 手動擊碎電視 (P)"
SmashButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SmashButton.TextSize = 13
SmashButton.Font = Enum.Font.SourceSansBold
SmashButton.LayoutOrder = 1
SmashButton.Parent = MainFrame
Instance.new("UICorner", SmashButton).CornerRadius = UDim.new(0, 6)

-- 2. 傳送按鈕
local TpButton = Instance.new("TextButton")
TpButton.Size = UDim2.new(0, 210, 0, 32)
TpButton.BackgroundColor3 = Color3.fromRGB(40, 120, 180)
TpButton.Text = "🚀 傳送 (自動穿牆防卡)"
TpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TpButton.TextSize = 13
TpButton.Font = Enum.Font.SourceSansBold
TpButton.LayoutOrder = 2
TpButton.Parent = MainFrame
Instance.new("UICorner", TpButton).CornerRadius = UDim.new(0, 6)

-- 3. 自動偵測按鈕
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

-- 📊 距離顯示標籤
local DistanceLabel = Instance.new("TextLabel")
DistanceLabel.Size = UDim2.new(0, 210, 0, 22)
DistanceLabel.BackgroundTransparency = 1
DistanceLabel.Text = "📡 電視距離：未偵測到電視"
DistanceLabel.TextColor3 = Color3.fromRGB(0, 220, 255)
DistanceLabel.TextSize = 12
DistanceLabel.Font = Enum.Font.SourceSansBold
DistanceLabel.LayoutOrder = 4
DistanceLabel.Parent = MainFrame

-- 狀態提示文字
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 22)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "狀態：就緒"
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusLabel.TextSize = 12
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.LayoutOrder = 5
StatusLabel.Parent = MainFrame

-- 狀態更新函式
local function updateStatus(text: string, color: Color3)
    StatusLabel.Text = "狀態：" .. text
    StatusLabel.TextColor3 = color
end

-- 點擊事件綁定
SmashButton.MouseButton1Click:Connect(function()
    if smashTelevision() then
        updateStatus("已對電視施加毀滅力道！", Color3.fromRGB(0, 255, 100))
        TweenService:Create(SmashButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    else
        updateStatus("未找到未錨定的電視。", Color3.fromRGB(255, 100, 100))
    end
end)

TpButton.MouseButton1Click:Connect(function()
    if teleportToTelevision() then
        updateStatus("傳送成功！穿牆已啟動(2s)", Color3.fromRGB(0, 180, 255))
        TweenService:Create(TpButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
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

-- ⚙️ 快捷鍵
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    if input.KeyCode == Enum.KeyCode.P then
        if smashTelevision() then 
            updateStatus("已對電視施加毀滅力道！", Color3.fromRGB(0, 255, 100)) 
        end
    end
end)

-- 🔄 每幀核心高頻循環 (處理 Noclip、距離顯示、自動偵測 與 ESP)
RunService.Stepped:Connect(function()
    local character = localPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart") as BasePart
    
    -- 1. 處理 2 秒自動穿牆 (Noclip)
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
    
    -- 2. 獲取電視當前狀態
    local tv = findTelevision()
    
    -- 3. 處理「電視透視 (ESP)」
    updateESP(tv)
    
    -- 4. 即時計算並更新電視當前距離
    if tv and rootPart then
        local distance = (rootPart.Position - tv.Position).Magnitude
        DistanceLabel.Text = string.format("📡 電視距離：%0.1f 公尺 (Studs)", distance)
        DistanceLabel.TextColor3 = Color3.fromRGB(0, 220, 255)
    else
        DistanceLabel.Text = "📡 電視距離：未偵測到電視"
        DistanceLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
    
    -- 5. 自動偵測與擊碎控制
    if autoSmashEnabled then
        local currentTime = tick()
        if currentTime - lastScanTime >= scanCooldown then
            lastScanTime = currentTime
            if smashTelevision() then
                updateStatus("✨ 自動機制：已自動擊飛電視！", Color3.fromRGB(0, 255, 180))
            end
        end
    end
end)

print("[DOORS Utility V4] 完整版部署成功！包含透視、自動偵測、傳送穿牆防卡。")