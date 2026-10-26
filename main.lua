-- ============================================
-- AUTO SKILL CHECK + ESP (LIGHTWEIGHT OPTIMIZED)
-- Violence District
-- ============================================

local Players              = game:GetService("Players")
local RunService           = game:GetService("RunService")
local Workspace            = game:GetService("Workspace")
local VirtualInputManager  = game:GetService("VirtualInputManager")
local TweenService         = game:GetService("TweenService")
local UserInputService     = game:GetService("UserInputService")
local StarterGui           = game:GetService("StarterGui")
local CoreGui              = game:GetService("CoreGui")

local LocalPlayer          = Players.LocalPlayer
local PlayerGui            = LocalPlayer:WaitForChild("PlayerGui")

-- ==========================================
-- ⚙️ VARIABEL UTAMA & CONFIG
-- ==========================================
local AutoSkillEnabled = false 
local CurrentMode = "Legit"

local WINDOWS = {
    Legit   = {start = 106, stop = 112}, 
    Normal  = {start = 120, stop = 125}, 
}

local ConfigFolder = "AutoSkillCheck_Configs"
local ActiveConfigName = "None"
local AutoLoadEnabled = false

if not isfolder(ConfigFolder) then
    makefolder(ConfigFolder)
end

-- ==========================================
-- 👁️ VARIABEL ESP
-- ==========================================
local ESP_Active = false
local ESP_Connections = {}
local ESP_Drawings = {}
local ESP_Highlights = {}
local ESP_Boxes = {}

local ESP_Objects     = {}
local GeneratorTexts  = {}
local GeneratorData   = {}
local PlayerRoleCache = {}

local ESP_Settings = {
    PlayerColor    = Color3.fromRGB(0, 255, 0),
    KillerColor    = Color3.fromRGB(255, 0, 0),
    SurvivorColor  = Color3.fromRGB(0, 150, 255),
    GeneratorColor = Color3.fromRGB(255, 255, 0),
    TextColor      = Color3.fromRGB(255, 255, 255),
    DoneColor      = Color3.fromRGB(0, 255, 0),
    TrapColor      = Color3.fromRGB(255, 0, 255),
    ZombieColor    = Color3.fromRGB(255, 0, 255),
    WindowColor    = Color3.fromRGB(0, 255, 255),
    PalletColor    = Color3.fromRGB(255, 140, 0),
}

local RENDER_DISTANCE = 500 -- Jarak maksimal objek ESP dirender (Studs)
local GEN_PROGRESS_INTERVAL = 0.25
-- ==========================================

local function ShowNotification(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title;
            Text = text;
            Duration = 2;
        })
    end)
end

local function AddCorner(inst, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = radius
    c.Parent = inst
    return c
end

-- ==========================================
-- 🖥️ MEMBUAT GUI UTAMA
-- ==========================================
if PlayerGui:FindFirstChild("SkillCheckHub") then
    PlayerGui:FindFirstChild("SkillCheckHub"):Destroy()
end
if CoreGui:FindFirstChild("SkillCheckHub") then
    CoreGui:FindFirstChild("SkillCheckHub"):Destroy()
end

local MainGui = Instance.new("ScreenGui")
MainGui.Name = "SkillCheckHub"
MainGui.ResetOnSpawn = false
MainGui.IgnoreGuiInset = true 
MainGui.DisplayOrder = 999999 

local success = pcall(function()
    if gethui then MainGui.Parent = gethui()
    elseif syn and syn.protect_gui then syn.protect_gui(MainGui); MainGui.Parent = CoreGui
    else MainGui.Parent = CoreGui end
end)
if not success or not MainGui.Parent then MainGui.Parent = PlayerGui end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 380, 0, 220)
MainFrame.Position = UDim2.new(0.5, -190, 0.5, -110)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ZIndex = 1
MainFrame.Parent = MainGui
AddCorner(MainFrame, UDim.new(0, 10))

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 100, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
Sidebar.BorderSizePixel = 0
Sidebar.Active = false
Sidebar.ZIndex = 10 
Sidebar.Parent = MainFrame
AddCorner(Sidebar, UDim.new(0, 10))

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "Menu"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.ZIndex = 11
Title.Parent = Sidebar

local function CreateTabBtn(text, yPos)
    local btn = Instance.new("TextButton")
    btn.Selectable = false
    btn.Size = UDim2.new(1, -20, 0, 35)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(150, 150, 150)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.ZIndex = 11
    btn.Parent = Sidebar
    AddCorner(btn, UDim.new(0, 6))
    return btn
end

local TabSkillBtn = CreateTabBtn("Skill Check", 40)
TabSkillBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
TabSkillBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
local TabEspBtn = CreateTabBtn("ESP", 80)
local TabSettingBtn = CreateTabBtn("Setting", 120)

-- Area Konten
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -110, 1, -20)
Content.Position = UDim2.new(0, 105, 0, 10)
Content.BackgroundTransparency = 1
Content.Active = false
Content.ZIndex = 2
Content.Parent = MainFrame

-- ==========================================
-- 📄 HALAMAN 1: SKILL CHECK
-- ==========================================
local SkillPage = Instance.new("Frame")
SkillPage.Size = UDim2.new(1, 0, 1, 0)
SkillPage.BackgroundTransparency = 1
SkillPage.Active = false
SkillPage.ZIndex = 3
SkillPage.Parent = Content

local ToggleFrame = Instance.new("Frame")
ToggleFrame.Size = UDim2.new(1, 0, 0, 40)
ToggleFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
ToggleFrame.BorderSizePixel = 0
ToggleFrame.Active = false
ToggleFrame.ZIndex = 4
ToggleFrame.Parent = SkillPage
AddCorner(ToggleFrame, UDim.new(0, 6))

local ToggleText = Instance.new("TextLabel")
ToggleText.Size = UDim2.new(1, -60, 1, 0)
ToggleText.Position = UDim2.new(0, 10, 0, 0)
ToggleText.BackgroundTransparency = 1
ToggleText.Text = "Auto Skill Check"
ToggleText.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleText.Font = Enum.Font.GothamMedium
ToggleText.TextSize = 13
ToggleText.TextXAlignment = Enum.TextXAlignment.Left
ToggleText.ZIndex = 5
ToggleText.Parent = ToggleFrame

local SwitchBg = Instance.new("Frame")
SwitchBg.Size = UDim2.new(0, 40, 0, 22)
SwitchBg.Position = UDim2.new(1, -50, 0.5, -11)
SwitchBg.BackgroundColor3 = Color3.fromRGB(80, 80, 80) 
SwitchBg.ZIndex = 5
SwitchBg.Parent = ToggleFrame
AddCorner(SwitchBg, UDim.new(1, 0))

local SwitchKnob = Instance.new("Frame")
SwitchKnob.Size = UDim2.new(0, 18, 0, 18)
SwitchKnob.Position = UDim2.new(0, 2, 0.5, -9) 
SwitchKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SwitchKnob.ZIndex = 6
SwitchKnob.Parent = SwitchBg
AddCorner(SwitchKnob, UDim.new(1, 0))

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Selectable = false
ToggleBtn.Size = UDim2.new(1, 0, 1, 0)
ToggleBtn.BackgroundTransparency = 1
ToggleBtn.Text = ""
ToggleBtn.ZIndex = 7
ToggleBtn.Parent = SwitchBg

local DropdownFrame = Instance.new("Frame")
DropdownFrame.Size = UDim2.new(1, 0, 0, 40)
DropdownFrame.Position = UDim2.new(0, 0, 0, 50)
DropdownFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
DropdownFrame.BorderSizePixel = 0
DropdownFrame.Active = false
DropdownFrame.ZIndex = 4
DropdownFrame.Parent = SkillPage
AddCorner(DropdownFrame, UDim.new(0, 6))

local DropdownText = Instance.new("TextLabel")
DropdownText.Size = UDim2.new(1, -60, 1, 0)
DropdownText.Position = UDim2.new(0, 10, 0, 0)
DropdownText.BackgroundTransparency = 1
DropdownText.Text = "Skill Check Mode"
DropdownText.TextColor3 = Color3.fromRGB(255, 255, 255)
DropdownText.Font = Enum.Font.GothamMedium
DropdownText.TextSize = 13
DropdownText.TextXAlignment = Enum.TextXAlignment.Left
DropdownText.ZIndex = 5
DropdownText.Parent = DropdownFrame

local SelectedLabel = Instance.new("TextLabel")
SelectedLabel.Size = UDim2.new(0, 60, 1, 0)
SelectedLabel.Position = UDim2.new(1, -70, 0, 0)
SelectedLabel.BackgroundTransparency = 1
SelectedLabel.Text = "Legit  v" 
SelectedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
SelectedLabel.Font = Enum.Font.GothamMedium
SelectedLabel.TextSize = 13
SelectedLabel.TextXAlignment = Enum.TextXAlignment.Right
SelectedLabel.ZIndex = 5
SelectedLabel.Parent = DropdownFrame

local DropdownBtn = Instance.new("TextButton")
DropdownBtn.Selectable = false
DropdownBtn.Size = UDim2.new(1, 0, 1, 0)
DropdownBtn.BackgroundTransparency = 1
DropdownBtn.Text = ""
DropdownBtn.ZIndex = 6
DropdownBtn.Parent = DropdownFrame

local OptionsList = Instance.new("Frame")
OptionsList.Size = UDim2.new(1, 0, 0, 95)
OptionsList.Position = UDim2.new(0, 0, 0, 45)
OptionsList.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
OptionsList.BorderSizePixel = 0
OptionsList.Visible = false
OptionsList.Active = false
OptionsList.ZIndex = 20 
OptionsList.Parent = DropdownFrame
AddCorner(OptionsList, UDim.new(0, 6))

local UIPadding = Instance.new("UIPadding")
UIPadding.PaddingTop = UDim.new(0, 5)
UIPadding.PaddingBottom = UDim.new(0, 5)
UIPadding.Parent = OptionsList

local OptionsLayout = Instance.new("UIListLayout")
OptionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
OptionsLayout.Padding = UDim.new(0, 2)
OptionsLayout.Parent = OptionsList

local Modes = {"Legit", "Normal", "Random"}
local OptionButtons = {}

local function UpdateDropdownUI()
    for mode, btn in pairs(OptionButtons) do
        if mode == CurrentMode then
            btn.Text = mode .. "  [✓]"
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.Text = mode
            btn.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
    end
    SelectedLabel.Text = CurrentMode .. "  v"
end

for i, mode in ipairs(Modes) do
    local btn = Instance.new("TextButton")
    btn.Selectable = false
    btn.Size = UDim2.new(1, -10, 0, 25)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
    btn.BorderSizePixel = 0
    btn.Text = mode
    btn.TextColor3 = Color3.fromRGB(150, 150, 150)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.ZIndex = 21
    btn.Parent = OptionsList
    
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 10)
    pad.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        CurrentMode = mode
        UpdateDropdownUI()
        OptionsList.Visible = false
    end)
    OptionButtons[mode] = btn
end
UpdateDropdownUI()

-- ==========================================
-- 📄 HALAMAN 2: ESP
-- ==========================================
local EspPage = Instance.new("Frame")
EspPage.Size = UDim2.new(1, 0, 1, 0)
EspPage.BackgroundTransparency = 1
EspPage.Active = false
EspPage.Visible = false
EspPage.ZIndex = 3
EspPage.Parent = Content

local EspToggleFrame = Instance.new("Frame")
EspToggleFrame.Size = UDim2.new(1, 0, 0, 40)
EspToggleFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
EspToggleFrame.BorderSizePixel = 0
EspToggleFrame.Active = false
EspToggleFrame.ZIndex = 4
EspToggleFrame.Parent = EspPage
AddCorner(EspToggleFrame, UDim.new(0, 6))

local EspToggleText = Instance.new("TextLabel")
EspToggleText.Size = UDim2.new(1, -60, 1, 0)
EspToggleText.Position = UDim2.new(0, 10, 0, 0)
EspToggleText.BackgroundTransparency = 1
EspToggleText.Text = "Enable Full ESP"
EspToggleText.TextColor3 = Color3.fromRGB(255, 255, 255)
EspToggleText.Font = Enum.Font.GothamMedium
EspToggleText.TextSize = 13
EspToggleText.TextXAlignment = Enum.TextXAlignment.Left
EspToggleText.ZIndex = 5
EspToggleText.Parent = EspToggleFrame

local EspSwitchBg = Instance.new("Frame")
EspSwitchBg.Size = UDim2.new(0, 40, 0, 22)
EspSwitchBg.Position = UDim2.new(1, -50, 0.5, -11)
EspSwitchBg.BackgroundColor3 = Color3.fromRGB(80, 80, 80) 
EspSwitchBg.ZIndex = 5
EspSwitchBg.Parent = EspToggleFrame
AddCorner(EspSwitchBg, UDim.new(1, 0))

local EspSwitchKnob = Instance.new("Frame")
EspSwitchKnob.Size = UDim2.new(0, 18, 0, 18)
EspSwitchKnob.Position = UDim2.new(0, 2, 0.5, -9) 
EspSwitchKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
EspSwitchKnob.ZIndex = 6
EspSwitchKnob.Parent = EspSwitchBg
AddCorner(EspSwitchKnob, UDim.new(1, 0))

local EspToggleBtn = Instance.new("TextButton")
EspToggleBtn.Selectable = false
EspToggleBtn.Size = UDim2.new(1, 0, 1, 0)
EspToggleBtn.BackgroundTransparency = 1
EspToggleBtn.Text = ""
EspToggleBtn.ZIndex = 7
EspToggleBtn.Parent = EspSwitchBg

-- ==========================================
-- 📄 HALAMAN 3: SETTING
-- ==========================================
local SettingPage = Instance.new("ScrollingFrame")
SettingPage.Size = UDim2.new(1, 0, 1, 0)
SettingPage.BackgroundTransparency = 1
SettingPage.Active = false
SettingPage.Visible = false
SettingPage.ZIndex = 3
SettingPage.CanvasSize = UDim2.new(0, 0, 0, 480)
SettingPage.ScrollBarThickness = 2
SettingPage.Parent = Content

local SettingLayout = Instance.new("UIListLayout")
SettingLayout.SortOrder = Enum.SortOrder.LayoutOrder
SettingLayout.Padding = UDim.new(0, 5)
SettingLayout.Parent = SettingPage

local function CreateSettingRow(order, textLabel)
    local row = Instance.new("TextButton")
    row.Selectable = false
    row.Size = UDim2.new(1, 0, 0, 35)
    row.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    row.BorderSizePixel = 0
    row.Text = ""
    row.ZIndex = 4
    row.LayoutOrder = order
    row.Parent = SettingPage
    AddCorner(row, UDim.new(0, 6))
    
    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, -20, 1, 0)
    txt.Position = UDim2.new(0, 10, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Text = textLabel
    txt.TextColor3 = Color3.fromRGB(255, 255, 255)
    txt.Font = Enum.Font.GothamMedium
    txt.TextSize = 13
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.ZIndex = 5
    txt.Parent = row
    return row, txt
end

local ConfigNameRow = CreateSettingRow(1, "Config Name")
local ConfigNameBox = Instance.new("TextBox")
ConfigNameBox.ClearTextOnFocus = false
ConfigNameBox.Size = UDim2.new(0, 100, 0, 25)
ConfigNameBox.Position = UDim2.new(1, -110, 0.5, -12.5)
ConfigNameBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
ConfigNameBox.Text = "default"
ConfigNameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
ConfigNameBox.Font = Enum.Font.GothamMedium
ConfigNameBox.TextSize = 12
ConfigNameBox.ZIndex = 6
ConfigNameBox.Parent = ConfigNameRow
AddCorner(ConfigNameBox, UDim.new(0, 4))

local SelectRow = CreateSettingRow(2, "Select Config")
local SelectLabel = Instance.new("TextLabel")
SelectLabel.Size = UDim2.new(0, 100, 1, 0)
SelectLabel.Position = UDim2.new(1, -110, 0, 0)
SelectLabel.BackgroundTransparency = 1
SelectLabel.Text = "None  v"
SelectLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
SelectLabel.Font = Enum.Font.GothamMedium
SelectLabel.TextSize = 12
SelectLabel.TextXAlignment = Enum.TextXAlignment.Right
SelectLabel.ZIndex = 5
SelectLabel.Parent = SelectRow

local ConfigOptionsFrame = Instance.new("Frame")
ConfigOptionsFrame.Size = UDim2.new(1, 0, 0, 0)
ConfigOptionsFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
ConfigOptionsFrame.Visible = false
ConfigOptionsFrame.Active = false
ConfigOptionsFrame.ZIndex = 100
ConfigOptionsFrame.Parent = Content
AddCorner(ConfigOptionsFrame, UDim.new(0, 6))

local ConfigListLayout = Instance.new("UIListLayout")
ConfigListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ConfigListLayout.Padding = UDim.new(0, 2)
ConfigListLayout.Parent = ConfigOptionsFrame

SelectRow.MouseButton1Click:Connect(function()
    if #ConfigOptionsFrame:GetChildren() > 1 then
        ConfigOptionsFrame.Visible = not ConfigOptionsFrame.Visible
        if ConfigOptionsFrame.Visible then
            local relY = SelectRow.AbsolutePosition.Y - Content.AbsolutePosition.Y + SelectRow.AbsoluteSize.Y
            ConfigOptionsFrame.Position = UDim2.new(0, 0, 0, relY + 5)
            ConfigOptionsFrame.Size = UDim2.new(1, 0, 0, math.min((#ConfigOptionsFrame:GetChildren() - 1) * 27, 150))
        end
    end
end)

local RefreshRow = CreateSettingRow(3, "Refresh List")
local SaveRow = CreateSettingRow(4, "Save Config")
local LoadRow = CreateSettingRow(5, "Load Config")
local RemoveRow = CreateSettingRow(6, "Remove Config")

local AutoLoadRow = CreateSettingRow(7, "Auto Load on Start")
local AutoLoadSwitchBg = Instance.new("Frame")
AutoLoadSwitchBg.Size = UDim2.new(0, 36, 0, 20)
AutoLoadSwitchBg.Position = UDim2.new(1, -46, 0.5, -10)
AutoLoadSwitchBg.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
AutoLoadSwitchBg.ZIndex = 5
AutoLoadSwitchBg.Parent = AutoLoadRow
AddCorner(AutoLoadSwitchBg, UDim.new(1, 0))

local AutoLoadKnob = Instance.new("Frame")
AutoLoadKnob.Size = UDim2.new(0, 16, 0, 16)
AutoLoadKnob.Position = UDim2.new(0, 2, 0.5, -8)
AutoLoadKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
AutoLoadKnob.ZIndex = 6
AutoLoadKnob.Parent = AutoLoadSwitchBg
AddCorner(AutoLoadKnob, UDim.new(1, 0))

local UnloadBtn = Instance.new("TextButton")
UnloadBtn.Selectable = false
UnloadBtn.Size = UDim2.new(1, 0, 0, 35)
UnloadBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) 
UnloadBtn.Text = "Unload Script"
UnloadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
UnloadBtn.Font = Enum.Font.GothamBold
UnloadBtn.TextSize = 13
UnloadBtn.ZIndex = 10
UnloadBtn.LayoutOrder = 8
UnloadBtn.Parent = SettingPage
AddCorner(UnloadBtn, UDim.new(0, 6))

-- ==========================================
-- 🔄 LOGIKA CONFIG SYSTEM
-- ==========================================
local function SetAutoLoad(configName, state)
    if state then pcall(function() writefile(ConfigFolder .. "/_autoload.txt", configName) end)
    else pcall(function() if isfile(ConfigFolder .. "/_autoload.txt") then delfile(ConfigFolder .. "/_autoload.txt") end end) end
end

local function SaveCurrentConfig()
    local configName = ConfigNameBox.Text
    if configName == "" or configName == "None" then configName = "default" end
    local path = ConfigFolder .. "/" .. configName .. ".json"
    local dataToSave = { Mode = CurrentMode, AutoSkill = AutoSkillEnabled }
    
    pcall(function()
        writefile(path, game:GetService("HttpService"):JSONEncode(dataToSave))
        ShowNotification("Config", "Saved: " .. configName)
        ActiveConfigName = configName
        SelectLabel.Text = ActiveConfigName .. "  v"
        RefreshConfigList()
    end)
end

local function LoadSelectedConfig()
    if ActiveConfigName == "None" or ActiveConfigName == "" then return end
    local path = ConfigFolder .. "/" .. ActiveConfigName .. ".json"
    if isfile(path) then
        local successRead, data = pcall(function() return game:GetService("HttpService"):JSONDecode(readfile(path)) end)
        if successRead and data then
            CurrentMode = data.Mode or "Legit"
            UpdateDropdownUI()
            AutoSkillEnabled = data.AutoSkill or false
            local targetColor = AutoSkillEnabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(80, 80, 80)
            local targetPos = AutoSkillEnabled and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
            SwitchBg.BackgroundColor3 = targetColor
            SwitchKnob.Position = targetPos
            ShowNotification("Config", "Loaded: " .. ActiveConfigName)
        end
    end
end

function RefreshConfigList()
    for _, child in pairs(ConfigOptionsFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local success, files = pcall(function() return listfiles(ConfigFolder) end)
    if success and files then
        for _, file in pairs(files) do
            local name = file:match("([^/\\]+)%.json$")
            if name then
                local btn = Instance.new("TextButton")
                btn.Selectable = false
                btn.Size = UDim2.new(1, 0, 0, 25)
                btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                btn.Text = name
                btn.TextColor3 = Color3.fromRGB(200, 200, 200)
                btn.Font = Enum.Font.GothamMedium
                btn.TextSize = 12
                btn.ZIndex = 101
                btn.Parent = ConfigOptionsFrame
                btn.MouseButton1Click:Connect(function()
                    ActiveConfigName = name
                    SelectLabel.Text = name .. "  v"
                    ConfigNameBox.Text = name
                    ConfigOptionsFrame.Visible = false
                    if AutoLoadEnabled then SetAutoLoad(name, true) end
                end)
            end
        end
    end
end

local function RemoveConfig()
    if ActiveConfigName == "None" then return end
    local path = ConfigFolder .. "/" .. ActiveConfigName .. ".json"
    if isfile(path) then
        pcall(function()
            delfile(path)
            ShowNotification("Config", "Removed: " .. ActiveConfigName)
            if isfile(ConfigFolder .. "/_autoload.txt") then
                local autoName = readfile(ConfigFolder .. "/_autoload.txt")
                if autoName == ActiveConfigName then
                    delfile(ConfigFolder .. "/_autoload.txt")
                    AutoLoadEnabled = false
                    AutoLoadSwitchBg.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                    AutoLoadKnob.Position = UDim2.new(0, 2, 0.5, -8)
                end
            end
            ActiveConfigName = "None"
            SelectLabel.Text = "None  v"
            ConfigNameBox.Text = "default"
            RefreshConfigList()
        end)
    end
end

RefreshRow.MouseButton1Click:Connect(function() RefreshConfigList(); ShowNotification("Config", "List Refreshed") end)
SaveRow.MouseButton1Click:Connect(SaveCurrentConfig)
LoadRow.MouseButton1Click:Connect(LoadSelectedConfig)
RemoveRow.MouseButton1Click:Connect(RemoveConfig)

AutoLoadRow.MouseButton1Click:Connect(function()
    AutoLoadEnabled = not AutoLoadEnabled
    local targetColor = AutoLoadEnabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(80, 80, 80)
    local targetPos = AutoLoadEnabled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    TweenService:Create(AutoLoadSwitchBg, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
    TweenService:Create(AutoLoadKnob, TweenInfo.new(0.2), {Position = targetPos}):Play()
    if ActiveConfigName ~= "None" then SetAutoLoad(ActiveConfigName, AutoLoadEnabled) end
end)

task.spawn(function()
    task.wait(1)
    RefreshConfigList()
    if isfile(ConfigFolder .. "/_autoload.txt") then
        local autoName = readfile(ConfigFolder .. "/_autoload.txt")
        if autoName and autoName ~= "" then
            AutoLoadEnabled = true
            AutoLoadSwitchBg.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
            AutoLoadKnob.Position = UDim2.new(1, -18, 0.5, -8)
            ActiveConfigName = autoName
            SelectLabel.Text = ActiveConfigName .. "  v"
            ConfigNameBox.Text = ActiveConfigName
            LoadSelectedConfig()
        end
    end
end)

-- ==========================================
-- 🔄 LOGIKA PINDAH TAB & GUI
-- ==========================================
local function SwitchTab(tab)
    SkillPage.Visible = (tab == "Skill")
    EspPage.Visible = (tab == "ESP")
    SettingPage.Visible = (tab == "Setting")
    
    TabSkillBtn.BackgroundColor3 = (tab == "Skill") and Color3.fromRGB(45, 45, 55) or Color3.fromRGB(30, 30, 35)
    TabEspBtn.BackgroundColor3 = (tab == "ESP") and Color3.fromRGB(45, 45, 55) or Color3.fromRGB(30, 30, 35)
    TabSettingBtn.BackgroundColor3 = (tab == "Setting") and Color3.fromRGB(45, 45, 55) or Color3.fromRGB(30, 30, 35)
end

TabSkillBtn.MouseButton1Click:Connect(function() SwitchTab("Skill") end)
TabEspBtn.MouseButton1Click:Connect(function() SwitchTab("ESP") end)
TabSettingBtn.MouseButton1Click:Connect(function() SwitchTab("Setting") end)

DropdownBtn.MouseButton1Click:Connect(function() OptionsList.Visible = not OptionsList.Visible end)

ToggleBtn.MouseButton1Click:Connect(function()
    AutoSkillEnabled = not AutoSkillEnabled
    local targetColor = AutoSkillEnabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(80, 80, 80)
    local targetPos = AutoSkillEnabled and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    TweenService:Create(SwitchBg, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
    TweenService:Create(SwitchKnob, TweenInfo.new(0.2), {Position = targetPos}):Play()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.RightAlt and MainGui then
        MainGui.Enabled = not MainGui.Enabled
    end
end)

-- ==========================================
-- 🧠 LOGIKA UTAMA SKRIP (AUTO SKILL CHECK)
-- ==========================================
local function PressSpace()
    task.spawn(function()
        pcall(function()
            VirtualInputManager:SendKeyEvent(true,  Enum.KeyCode.Space, false, game)
            task.wait(0.01)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end)
    end)
end

local function IsSurvivor()
    local t = LocalPlayer.Team
    return t and t.Name:lower():find("survivor") ~= nil
end

local lastCheck = nil
local hasPressed = false
local lastGoalRotation = -999
local SkillCheckConnection = nil

-- CACHE: Menyimpan referensi Line & Goal agar tidak perlu melooping setiap frame
local cachedLine, cachedGoal, cachedTrapPerfect, cachedTrapGoal = nil, nil, nil, nil

local function OnSkillCheckFrame()
    if not AutoSkillEnabled or not IsSurvivor() then
        lastCheck = nil
        hasPressed = false
        lastGoalRotation = -999
        return
    end
    
    local prompt = PlayerGui:FindFirstChild("SkillCheckPromptGui")
    if not prompt then return end
    local check = prompt:FindFirstChild("Check")
    
    if not check or not check.Visible then
        lastCheck = nil
        hasPressed = false
        return
    end
    
    -- Hanya cari child jika Check berubah (Hemat CPU)
    if lastCheck ~= check then
        lastCheck = check
        hasPressed = false
        lastGoalRotation = -999
        cachedLine = check:FindFirstChild("Line")
        cachedGoal = check:FindFirstChild("Goal")
        cachedTrapPerfect = check:FindFirstChild("TrapPerfect")
        cachedTrapGoal = check:FindFirstChild("TrapGoal")
    end
    
    if not cachedLine then return end
    
    local activeGoal = cachedGoal
    if cachedTrapPerfect and cachedTrapPerfect.Visible then activeGoal = cachedTrapPerfect
    elseif cachedTrapGoal and cachedTrapGoal.Visible then activeGoal = cachedTrapGoal end
    
    if not activeGoal then return end
    
    local gr = activeGoal.Rotation % 360
    local lr = cachedLine.Rotation % 360
    
    -- Deteksi reset trap (Goal berpindah)
    if lastGoalRotation ~= -999 and math.abs(gr - lastGoalRotation) > 1 then
        hasPressed = false
        lastGoalRotation = gr
        return 
    end
    lastGoalRotation = gr
    
    local targetWindow = WINDOWS["Legit"]
    if CurrentMode == "Random" then
        targetWindow = math.random(1, 100) <= 40 and WINDOWS["Legit"] or WINDOWS["Normal"]
    elseif CurrentMode == "Normal" then
        targetWindow = WINDOWS["Normal"]
    end
    
    local ss = (gr + targetWindow.start) % 360
    local se = (gr + targetWindow.stop) % 360
    
    local hit = false
    if ss > se then hit = (lr >= ss or lr <= se)
    else hit = (lr >= ss and lr <= se) end
    
    if hit then
        if not hasPressed then
            PressSpace()
            hasPressed = true
        end
    else
        hasPressed = false
    end
end

SkillCheckConnection = RunService.RenderStepped:Connect(OnSkillCheckFrame)

-- ==========================================
-- 🧹 FUNGSI UNLOAD
-- ==========================================
UnloadBtn.MouseButton1Click:Connect(function()
    if SkillCheckConnection then SkillCheckConnection:Disconnect() end
    ESP_Active = false
    for _, conn in pairs(ESP_Connections) do pcall(function() conn:Disconnect() end) end
    for _, drawing in pairs(ESP_Drawings) do pcall(function() drawing:Remove() end) end
    for _, h in pairs(ESP_Highlights) do pcall(function() h:Destroy() end) end
    for _, b in pairs(ESP_Boxes) do pcall(function() b:Destroy() end) end
    if MainGui then MainGui:Destroy() end
    ShowNotification("Auto Skill Check", "Script berhasil di-Unload.")
end)

-- ==========================================
-- 👁️ LOGIKA ESP (OPTIMIZED)
-- ==========================================

local function ClearESP()
    table.clear(ESP_Objects)
    table.clear(GeneratorTexts)
    table.clear(GeneratorData)
    table.clear(PlayerRoleCache)
    
    for _, conn in pairs(ESP_Connections) do pcall(function() conn:Disconnect() end) end
    table.clear(ESP_Connections)
    for _, drawing in pairs(ESP_Drawings) do pcall(function() drawing:Remove() end) end
    table.clear(ESP_Drawings)
    for _, h in pairs(ESP_Highlights) do pcall(function() h:Destroy() end) end
    table.clear(ESP_Highlights)
    for _, b in pairs(ESP_Boxes) do pcall(function() b:Destroy() end) end
    table.clear(ESP_Boxes)
end

local function StartESP()
    if ESP_Active then return end
    ESP_Active = true
    
    local function createHighlight(object, color)
        local h = Instance.new("Highlight")
        h.Name = "ESP_Highlight"
        h.Adornee = object
        h.FillColor = color
        h.FillTransparency = 0.85
        h.OutlineColor = color
        h.OutlineTransparency = 0.1
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = game.CoreGui
        table.insert(ESP_Highlights, h)
        return h
    end

    local function addObjectESP(object, color, forceESP)
        if not object or not object:IsA("Instance") or ESP_Objects[object] then return end
        local target = object
        if target:IsA("Model") then
            local bestPart = target.PrimaryPart
            if not bestPart or bestPart.Transparency >= 1 then
                local maxVol = 0
                for _, p in ipairs(target:GetDescendants()) do
                    if p:IsA("BasePart") and p.Transparency < 1 then
                        if not forceESP and p.Size.Magnitude > 100 then continue end
                        local vol = p.Size.X * p.Size.Y * p.Size.Z
                        if vol > maxVol then maxVol = vol; bestPart = p end
                    end
                end
            end
            if not bestPart then return end
            target = bestPart
        end
        if not target:IsA("BasePart") then return end
        ESP_Objects[object] = { Highlight = createHighlight(target, color) }
    end

    local function detectRole(player)
        local role = "unknown"
        if player.Team then
            local t = player.Team.Name:lower()
            if t:find("killer",1,true) or t:find("murder",1,true) or t:find("butcher",1,true) or t:find("slasher",1,true) then role = "killer"
            elseif t:find("survivor",1,true) or t:find("innocent",1,true) or t:find("runner",1,true) then role = "survivor" end
        end
        if role == "unknown" then
            local r = player:GetAttribute("Role") or player:GetAttribute("Team")
            if r then
                local al = tostring(r):lower()
                if al:find("kill",1,true) or al:find("murder",1,true) then role = "killer"
                elseif al:find("surv",1,true) or al:find("innoc",1,true) then role = "survivor" end
            end
        end
        return role
    end

    local function roleToColor(role)
        if role == "killer" then return ESP_Settings.KillerColor end
        if role == "survivor" then return ESP_Settings.SurvivorColor end
        return ESP_Settings.PlayerColor
    end

    local function addPlayerESP(player)
        local char = player.Character
        if not char or ESP_Objects[char] then return end
        local role = detectRole(player)
        PlayerRoleCache[player] = { role = role, t = os.clock() }
        ESP_Objects[char] = { Highlight = createHighlight(char, roleToColor(role)), Player = player }
    end

    local function getGeneratorCenter(gen)
        if gen.PrimaryPart then return gen.PrimaryPart.Position end
        local best, maxVol = nil, 0
        for _, p in ipairs(gen:GetDescendants()) do
            if p:IsA("BasePart") and p.Transparency < 1 then
                local vol = p.Size.X * p.Size.Y * p.Size.Z
                if vol > maxVol then maxVol = vol; best = p end
            end
        end
        return best and best.Position or gen:GetPivot().Position
    end

    local function getGeneratorProgress(gen)
        for _, attr in ipairs({"Progress","Percent","RepairProgress","Completion","Value"}) do
            local v = gen:GetAttribute(attr)
            if type(v) == "number" then
                local pct = v <= 1 and (v * 100) or v
                return pct >= 100 and "DONE" or tostring(math.floor(pct))
            end
        end
        return "0"
    end

    local function applyVaultBox(part)
        if not part or not part:IsA("BasePart") or ESP_Objects[part] then return end
        if part.Name == "VaultTrigger" or part.Name:lower():find("inviswall",1,true) or part.Size.Magnitude > 100 then return end
        local box = Instance.new("BoxHandleAdornment")
        box.Name = "ESP_VaultBox"
        box.Adornee = part
        box.AlwaysOnTop = true
        box.ZIndex = 5
        box.Size = part.Size
        box.Color3 = ESP_Settings.WindowColor
        box.Transparency = 0.8
        box.Parent = game.CoreGui
        table.insert(ESP_Boxes, box)
        ESP_Objects[part] = { Box = box }
    end

    -- [OPTIMASI] Fungsi tunggal untuk memproses objek map
    local function processMapObject(obj)
        if not ESP_Active then return end
        if obj.ClassName == "Model" then
            if not ESP_Objects[obj] then
                local lower = obj.Name:lower()
                if lower:find("generator",1,true) then
                    addObjectESP(obj, ESP_Settings.GeneratorColor, false)
                    if not GeneratorTexts[obj] then
                        local txt = Drawing.new("Text")
                        txt.Size = 20; txt.Center = true; txt.Outline = true; txt.Font = 3
                        txt.Color = ESP_Settings.TextColor; txt.Text = "0%"; txt.Visible = false
                        GeneratorTexts[obj] = txt
                        table.insert(ESP_Drawings, txt)
                        GeneratorData[obj] = { center = getGeneratorCenter(obj), nextUpdate = 0 }
                    end
                elseif lower:find("zombie",1,true) or lower:find("scp",1,true) or lower:find("minion",1,true) or lower:find("cure",1,true) then
                    if obj:FindFirstChildOfClass("Humanoid") then ESP_Objects[obj] = { Highlight = createHighlight(obj, ESP_Settings.ZombieColor) } end
                elseif lower:find("bear trap",1,true) or lower:find("beartrap",1,true) or lower:find("butcher trap",1,true) then
                    addObjectESP(obj, ESP_Settings.TrapColor, false)
                elseif lower:find("pallet",1,true) and not lower:find("crate",1,true) then
                    addObjectESP(obj, ESP_Settings.PalletColor, false)
                elseif lower:find("window",1,true) then
                    local hasTrigger = obj:FindFirstChild("VaultTrigger", true) ~= nil
                    local hasPrompt  = false
                    for _, d in ipairs(obj:GetDescendants()) do if d:IsA("ProximityPrompt") then hasPrompt = true; break end end
                    if hasTrigger or hasPrompt then for _, part in ipairs(obj:GetDescendants()) do applyVaultBox(part) end end
                end
            end
        elseif obj.ClassName == "Part" then
            if not ESP_Objects[obj] then
                local lower = obj.Name:lower()
                if lower:find("bear trap",1,true) or lower:find("beartrap",1,true) or lower:find("butcher trap",1,true) then
                    addObjectESP(obj, ESP_Settings.TrapColor, false)
                elseif obj.Name == "VaultTrigger" and obj.Parent then
                    for _, p in ipairs(obj.Parent:GetDescendants()) do applyVaultBox(p) end
                end
            end
        end
    end

    -- Scan Awal (Untuk objek yang sudah ada di map)
    local mapFolder = Workspace:FindFirstChild("Map") or Workspace
    for _, obj in ipairs(mapFolder:GetDescendants()) do processMapObject(obj) end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and not ESP_Objects[player.Character] then addPlayerESP(player) end
    end

    -- [OPTIMASI BESAR] Gunakan Event bawaan Roblox, bukan While Loop!
    table.insert(ESP_Connections, mapFolder.DescendantAdded:Connect(processMapObject))
    
    table.insert(ESP_Connections, mapFolder.DescendantRemoving:Connect(function(obj)
        if ESP_Objects[obj] then
            if ESP_Objects[obj].Highlight then ESP_Objects[obj].Highlight:Destroy() end
            if ESP_Objects[obj].Box then ESP_Objects[obj].Box:Destroy() end
            ESP_Objects[obj] = nil
        end
        if GeneratorTexts[obj] then
            GeneratorTexts[obj]:Remove()
            GeneratorTexts[obj] = nil
            GeneratorData[obj] = nil
        end
    end))

    table.insert(ESP_Connections, Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            task.wait(1)
            if ESP_Active then addPlayerESP(player) end
        end)
    end))

    table.insert(ESP_Connections, Players.PlayerRemoving:Connect(function(player)
        if player.Character and ESP_Objects[player.Character] then
            local data = ESP_Objects[player.Character]
            if data.Highlight then data.Highlight:Destroy() end
            ESP_Objects[player.Character] = nil
        end
        PlayerRoleCache[player] = nil
    end))

    -- Loop Render Teks Generator (Throttled / Diperlambat agar ringan)
    local renderAccumulator = 0
    table.insert(ESP_Connections, RunService.RenderStepped:Connect(function(dt)
        if not ESP_Active then return end
        renderAccumulator = renderAccumulator + dt
        if renderAccumulator < 0.05 then return end -- Render maks 20 FPS untuk teks (sangat ringan)
        renderAccumulator = 0

        local cam = Workspace.CurrentCamera
        if not cam then return end
        local camPos = cam.CFrame.Position
        local now = os.clock()

        for gen, txt in pairs(GeneratorTexts) do
            if gen and gen.Parent then
                local gd = GeneratorData[gen]
                -- Jarak Check (Optimasi: Jangan render jika terlalu jauh)
                if (camPos - gd.center).Magnitude > RENDER_DISTANCE then
                    txt.Visible = false
                    continue
                end

                local pos, onScreen = cam:WorldToViewportPoint(gd.center)
                if onScreen then
                    txt.Visible = true
                    txt.Position = Vector2.new(pos.X, pos.Y)
                    if now >= gd.nextUpdate then
                        gd.nextUpdate = now + GEN_PROGRESS_INTERVAL
                        local prog = getGeneratorProgress(gen)
                        local ed = ESP_Objects[gen]
                        if prog == "DONE" then
                            txt.Text = "DONE"; txt.Color = ESP_Settings.DoneColor
                            if ed and ed.Highlight then ed.Highlight.FillColor = ESP_Settings.DoneColor; ed.Highlight.OutlineColor = ESP_Settings.DoneColor end
                        else
                            txt.Text = prog .. "%"; txt.Color = ESP_Settings.TextColor
                            if ed and ed.Highlight then ed.Highlight.FillColor = ESP_Settings.GeneratorColor; ed.Highlight.OutlineColor = ESP_Settings.GeneratorColor end
                        end
                    end
                else
                    txt.Visible = false
                end
            end
        end
    end))

    -- Loop Update Role Player (Jarang jalan, sangat ringan)
    table.insert(ESP_Connections, task.spawn(function()
        while ESP_Active do
            task.wait(2)
            if ESP_Active then
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character and not ESP_Objects[player.Character] then
                        addPlayerESP(player)
                    end
                end
                local now = os.clock()
                for _, data in pairs(ESP_Objects) do
                    if data.Player then
                        local cache = PlayerRoleCache[data.Player]
                        if not cache or now - cache.t >= 2 then
                            local role = detectRole(data.Player)
                            PlayerRoleCache[data.Player] = { role = role, t = now }
                            local color = roleToColor(role)
                            if data.Highlight and data.Highlight.FillColor ~= color then
                                data.Highlight.FillColor = color; data.Highlight.OutlineColor = color
                            end
                        end
                    end
                end
            end
        end
    end))
    
    ShowNotification("ESP", "ESP Enabled (Optimized)")
end

EspToggleBtn.MouseButton1Click:Connect(function()
    if not ESP_Active then
        EspSwitchBg.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
        EspSwitchKnob.Position = UDim2.new(1, -20, 0.5, -9)
        StartESP()
    else
        EspSwitchBg.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        EspSwitchKnob.Position = UDim2.new(0, 2, 0.5, -9)
        ESP_Active = false
        ClearESP()
        ShowNotification("ESP", "ESP Disabled")
    end
end)

ShowNotification("Auto Skill Check", "Loaded. Tekan [Right ALT] untuk buka GUI.")
