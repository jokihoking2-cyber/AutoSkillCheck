-- ============================================
-- AUTO SKILL CHECK + ESP (ULTIMATE HUB)
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
local HeartbeatConnection = nil
local VisibilityConnection = nil

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

local PLAYER_SCAN_INTERVAL  = 1.5
local STATIC_SCAN_INTERVAL  = 5.0
local ROLE_CHECK_INTERVAL   = 1.0
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
MainGui.DisplayOrder = 999999 

local success = pcall(function()
    if gethui then
        MainGui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(MainGui)
        MainGui.Parent = CoreGui
    else
        MainGui.Parent = CoreGui
    end
end)

if not success or not MainGui.Parent then
    MainGui.Parent = PlayerGui
end

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

-- Sidebar (Kiri)
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 100, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 2
Sidebar.Parent = MainFrame
AddCorner(Sidebar, UDim.new(0, 10))

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "Menu"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.ZIndex = 3
Title.Parent = Sidebar

local TabSkillBtn = Instance.new("TextButton")
TabSkillBtn.Selectable = false
TabSkillBtn.Size = UDim2.new(1, -20, 0, 35)
TabSkillBtn.Position = UDim2.new(0, 10, 0, 40)
TabSkillBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
TabSkillBtn.Text = "Skill Check"
TabSkillBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TabSkillBtn.Font = Enum.Font.GothamMedium
TabSkillBtn.TextSize = 13
TabSkillBtn.ZIndex = 3
TabSkillBtn.Parent = Sidebar
AddCorner(TabSkillBtn, UDim.new(0, 6))

local TabEspBtn = Instance.new("TextButton")
TabEspBtn.Selectable = false
TabEspBtn.Size = UDim2.new(1, -20, 0, 35)
TabEspBtn.Position = UDim2.new(0, 10, 0, 80)
TabEspBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
TabEspBtn.Text = "ESP"
TabEspBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
TabEspBtn.Font = Enum.Font.GothamMedium
TabEspBtn.TextSize = 13
TabEspBtn.ZIndex = 3
TabEspBtn.Parent = Sidebar
AddCorner(TabEspBtn, UDim.new(0, 6))

local TabSettingBtn = Instance.new("TextButton")
TabSettingBtn.Selectable = false
TabSettingBtn.Size = UDim2.new(1, -20, 0, 35)
TabSettingBtn.Position = UDim2.new(0, 10, 0, 120)
TabSettingBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
TabSettingBtn.Text = "Setting"
TabSettingBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
TabSettingBtn.Font = Enum.Font.GothamMedium
TabSettingBtn.TextSize = 13
TabSettingBtn.ZIndex = 3
TabSettingBtn.Parent = Sidebar
AddCorner(TabSettingBtn, UDim.new(0, 6))

-- Area Konten (Kanan)
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -110, 1, -20)
Content.Position = UDim2.new(0, 105, 0, 10)
Content.BackgroundTransparency = 1
Content.ZIndex = 2
Content.Parent = MainFrame

-- ==========================================
-- 📄 HALAMAN 1: SKILL CHECK
-- ==========================================
local SkillPage = Instance.new("Frame")
SkillPage.Size = UDim2.new(1, 0, 1, 0)
SkillPage.BackgroundTransparency = 1
SkillPage.ZIndex = 3
SkillPage.Parent = Content

local ToggleFrame = Instance.new("Frame")
ToggleFrame.Size = UDim2.new(1, 0, 0, 40)
ToggleFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
ToggleFrame.BorderSizePixel = 0
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

-- Dropdown Mode
local DropdownFrame = Instance.new("Frame")
DropdownFrame.Size = UDim2.new(1, 0, 0, 40)
DropdownFrame.Position = UDim2.new(0, 0, 0, 50)
DropdownFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
DropdownFrame.BorderSizePixel = 0
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
EspPage.Visible = false
EspPage.ZIndex = 3
EspPage.Parent = Content

local EspToggleFrame = Instance.new("Frame")
EspToggleFrame.Size = UDim2.new(1, 0, 0, 40)
EspToggleFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
EspToggleFrame.BorderSizePixel = 0
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
-- 📄 HALAMAN 3: SETTING (CONFIG & UNLOAD)
-- ==========================================
local SettingPage = Instance.new("ScrollingFrame")
SettingPage.Size = UDim2.new(1, 0, 1, 0)
SettingPage.BackgroundTransparency = 1
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

-- 1. Config Name
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

-- 2. Select Config (Dropdown)
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

-- 3. Action Buttons
local RefreshRow = CreateSettingRow(3, "Refresh List")
local SaveRow = CreateSettingRow(4, "Save Config")
local LoadRow = CreateSettingRow(5, "Load Config")
local RemoveRow = CreateSettingRow(6, "Remove Config")

-- 4. Auto Load Toggle
local AutoLoadRow = CreateSettingRow(7, "Auto Load on Start")
local AutoLoadLbl = AutoLoadRow:FindFirstChild("TextLabel")
AutoLoadLbl.Size = UDim2.new(1, -80, 1, 0)

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

-- 5. Unload Button
local UnloadBtn = Instance.new("TextButton")
UnloadBtn.Selectable = false
UnloadBtn.Size = UDim2.new(1, 0, 0, 35)
UnloadBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) 
UnloadBtn.Text = "Unload Script"
UnloadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
UnloadBtn.Font = Enum.Font.GothamBold
UnloadBtn.TextSize = 13
UnloadBtn.ZIndex = 4
UnloadBtn.LayoutOrder = 8
UnloadBtn.Parent = SettingPage
AddCorner(UnloadBtn, UDim.new(0, 6))

-- ==========================================
-- 🔄 LOGIKA CONFIG SYSTEM
-- ==========================================

local function SetAutoLoad(configName, state)
    if state then
        pcall(function()
            writefile(ConfigFolder .. "/_autoload.txt", configName) 
        end)
    else
        pcall(function()
            if isfile(ConfigFolder .. "/_autoload.txt") then
                delfile(ConfigFolder .. "/_autoload.txt")
            end
        end)
    end
end

local function SaveCurrentConfig()
    local configName = ConfigNameBox.Text
    if configName == "" or configName == "None" then
        configName = "default"
    end
    
    local path = ConfigFolder .. "/" .. configName .. ".json"
    local dataToSave = {
        Mode = CurrentMode,
        AutoSkill = AutoSkillEnabled
    }
    
    pcall(function()
        writefile(path, game:GetService("HttpService"):JSONEncode(dataToSave))
        ShowNotification("Config", "Saved: " .. configName)
        ActiveConfigName = configName
        SelectLabel.Text = ActiveConfigName .. "  v"
        RefreshConfigList()
    end)
end

local function LoadSelectedConfig()
    if ActiveConfigName == "None" or ActiveConfigName == "" then
        return 
    end
    
    local path = ConfigFolder .. "/" .. ActiveConfigName .. ".json"
    
    if isfile(path) then
        local successRead, data = pcall(function()
            return game:GetService("HttpService"):JSONDecode(readfile(path))
        end)
        
        if successRead and data then
            CurrentMode = data.Mode or "Legit"
            UpdateDropdownUI()
            
            AutoSkillEnabled = data.AutoSkill or false
            
            local targetColor = AutoSkillEnabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(80, 80, 80)
            local targetPos = AutoSkillEnabled and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
            
            SwitchBg.BackgroundColor3 = targetColor
            SwitchKnob.Position = targetPos
            
            if not AutoSkillEnabled and HeartbeatConnection then
                HeartbeatConnection:Disconnect()
                HeartbeatConnection = nil
            end
            
            ShowNotification("Config", "Loaded: " .. ActiveConfigName)
        end
    end
end

function RefreshConfigList()
    for _, child in pairs(ConfigOptionsFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    local success, files = pcall(function()
        return listfiles(ConfigFolder) 
    end)
    
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
                    if AutoLoadEnabled then
                        SetAutoLoad(name, true) 
                    end
                end)
            end
        end
    end
end

local function RemoveConfig()
    if ActiveConfigName == "None" then
        return 
    end
    
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

RefreshRow.MouseButton1Click:Connect(function()
    RefreshConfigList()
    ShowNotification("Config", "List Refreshed")
end)

SaveRow.MouseButton1Click:Connect(SaveCurrentConfig)
LoadRow.MouseButton1Click:Connect(LoadSelectedConfig)
RemoveRow.MouseButton1Click:Connect(RemoveConfig)

AutoLoadRow.MouseButton1Click:Connect(function()
    AutoLoadEnabled = not AutoLoadEnabled
    local targetColor = AutoLoadEnabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(80, 80, 80)
    local targetPos = AutoLoadEnabled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    
    TweenService:Create(AutoLoadSwitchBg, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
    TweenService:Create(AutoLoadKnob, TweenInfo.new(0.2), {Position = targetPos}):Play()
    
    if ActiveConfigName ~= "None" then
        SetAutoLoad(ActiveConfigName, AutoLoadEnabled) 
    end
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
-- 🔄 LOGIKA PINDAH TAB
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

-- ==========================================
-- 🧹 FUNGSI UNLOAD
-- ==========================================
UnloadBtn.MouseButton1Click:Connect(function()
    if HeartbeatConnection then
        HeartbeatConnection:Disconnect()
        HeartbeatConnection = nil
    end
    if VisibilityConnection then
        VisibilityConnection:Disconnect()
        VisibilityConnection = nil
    end
    
    ESP_Active = false
    for _, conn in pairs(ESP_Connections) do
        pcall(function() conn:Disconnect() end)
    end
    for _, drawing in pairs(ESP_Drawings) do
        pcall(function() drawing:Remove() end)
    end
    for _, h in pairs(ESP_Highlights) do
        pcall(function() h:Destroy() end)
    end
    for _, b in pairs(ESP_Boxes) do
        pcall(function() b:Destroy() end)
    end
    
    if MainGui then
        MainGui:Destroy() 
    end
    
    ShowNotification("Auto Skill Check", "Script berhasil di-Unload.")
end)

-- ==========================================
-- ⚙️ INTERAKSI GUI LAINNYA
-- ==========================================
DropdownBtn.MouseButton1Click:Connect(function()
    OptionsList.Visible = not OptionsList.Visible
end)

ToggleBtn.MouseButton1Click:Connect(function()
    AutoSkillEnabled = not AutoSkillEnabled
    local targetColor = AutoSkillEnabled and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(80, 80, 80)
    local targetPos = AutoSkillEnabled and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    
    TweenService:Create(SwitchBg, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
    TweenService:Create(SwitchKnob, TweenInfo.new(0.2), {Position = targetPos}):Play()
    
    if not AutoSkillEnabled and HeartbeatConnection then
        HeartbeatConnection:Disconnect()
        HeartbeatConnection = nil
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.RightAlt then
        MainGui.Enabled = not MainGui.Enabled
    end
end)

-- ==========================================
-- 🧠 LOGIKA UTAMA SKRIP (AUTO SKILL CHECK)
-- ==========================================
local function PressSpace()
    pcall(function()
        VirtualInputManager:SendKeyEvent(true,  Enum.KeyCode.Space, false, game)
        task.wait(0.03)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
    end)
end

local function IsSurvivor()
    local t = LocalPlayer.Team
    return t and t.Name:lower():find("survivor") ~= nil
end

local function Cleanup()
    if HeartbeatConnection then
        HeartbeatConnection:Disconnect()
        HeartbeatConnection = nil
    end
    if VisibilityConnection then
        VisibilityConnection:Disconnect()
        VisibilityConnection = nil
    end
end

local function AttachCheck(check)
    if VisibilityConnection then
        VisibilityConnection:Disconnect()
    end

    VisibilityConnection = check:GetPropertyChangedSignal("Visible"):Connect(function()
        if not (check.Visible and IsSurvivor() and AutoSkillEnabled) then
            if HeartbeatConnection then
                HeartbeatConnection:Disconnect()
                HeartbeatConnection = nil
            end
            return
        end

        if HeartbeatConnection then
            HeartbeatConnection:Disconnect()
        end
        
        local targetWindow = WINDOWS["Legit"]
        
        if CurrentMode == "Random" then
            if math.random(1, 100) <= 40 then
                targetWindow = WINDOWS["Legit"]
            else
                targetWindow = WINDOWS["Normal"]
            end
        elseif CurrentMode == "Normal" then
            targetWindow = WINDOWS["Normal"]
        end

        HeartbeatConnection = RunService.Heartbeat:Connect(function()
            if not AutoSkillEnabled then return end

            local line = check:FindFirstChild("Line")
            local goal = check:FindFirstChild("Goal")
            if not (line and goal) then return end

            local lr = line.Rotation % 360
            local gr = goal.Rotation % 360
            
            local ss, se = (gr + targetWindow.start) % 360, (gr + targetWindow.stop) % 360

            local hit
            if ss > se then
                hit = (lr >= ss or lr <= se)
            else
                hit = (lr >= ss and lr <= se)
            end

            if hit then
                PressSpace()
                if HeartbeatConnection then
                    HeartbeatConnection:Disconnect()
                    HeartbeatConnection = nil
                end
            end
        end)
    end)
end

task.spawn(function()
    while true do
        local prompt = PlayerGui:WaitForChild("SkillCheckPromptGui", 30)
        if prompt then
            local check = prompt:WaitForChild("Check", 10)
            if check then
                AttachCheck(check)
                prompt.AncestryChanged:Wait()
            end
        end
        task.wait(0.5)
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    Cleanup()
    task.wait(1)
end)

-- ==========================================
-- 👁️ LOGIKA ESP (DARI SCRIPT ANDA)
-- ==========================================

local function ClearESP()
    ESP_Objects     = {}
    GeneratorTexts  = {}
    GeneratorData   = {}
    PlayerRoleCache = {}
    
    for _, conn in pairs(ESP_Connections) do
        pcall(function() conn:Disconnect() end)
    end
    ESP_Connections = {}
    
    for _, drawing in pairs(ESP_Drawings) do
        pcall(function() drawing:Remove() end)
    end
    ESP_Drawings = {}
    
    for _, h in pairs(ESP_Highlights) do
        pcall(function() h:Destroy() end)
    end
    ESP_Highlights = {}
    
    for _, b in pairs(ESP_Boxes) do
        pcall(function() b:Destroy() end)
    end
    ESP_Boxes = {}
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
                        if vol > maxVol then
                            maxVol = vol
                            bestPart = p 
                        end
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
            if t:find("killer",1,true) or t:find("murder",1,true) or t:find("butcher",1,true) or t:find("slasher",1,true) then 
                role = "killer"
            elseif t:find("survivor",1,true) or t:find("innocent",1,true) or t:find("runner",1,true) then 
                role = "survivor" 
            end
        end
        if role == "unknown" then
            local r = player:GetAttribute("Role") or player:GetAttribute("Team")
            if r then
                local al = tostring(r):lower()
                if al:find("kill",1,true) or al:find("murder",1,true) then
                    role = "killer"
                elseif al:find("surv",1,true) or al:find("innoc",1,true) then
                    role = "survivor"
                end
            end
        end
        local char = player.Character
        if char and role == "unknown" then
            local r = char:GetAttribute("Role") or char:GetAttribute("Team")
            if r then
                local al = tostring(r):lower()
                if al:find("kill",1,true) or al:find("murder",1,true) then
                    role = "killer"
                elseif al:find("surv",1,true) or al:find("innoc",1,true) then
                    role = "survivor"
                end
            end
        end
        if char and role == "unknown" then
            for _, obj in ipairs(char:GetDescendants()) do
                if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                    local txt = (obj.Text or ""):lower()
                    if txt:find("killer",1,true) or txt:find("murderer",1,true) then
                        role = "killer"
                        break
                    end
                    if txt:find("survivor",1,true) or txt:find("innocent",1,true) then
                        role = "survivor"
                        break
                    end
                end
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

    local function scanPlayers()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and not ESP_Objects[player.Character] then
                addPlayerESP(player)
            end
        end
    end

    local function updatePlayerRoles()
        local now = os.clock()
        for _, data in pairs(ESP_Objects) do
            local p = data.Player
            if p then
                local cache = PlayerRoleCache[p]
                if not cache or now - cache.t >= ROLE_CHECK_INTERVAL then
                    local role = detectRole(p)
                    PlayerRoleCache[p] = { role = role, t = now }
                    local color = roleToColor(role)
                    local h = data.Highlight
                    if h and h.FillColor ~= color then
                        h.FillColor = color
                        h.OutlineColor = color
                    end
                end
            end
        end
    end

    local function getGeneratorProgress(gen)
        for _, attr in ipairs({"Progress","Percent","RepairProgress","Completion","Value"}) do
            local v = gen:GetAttribute(attr)
            if type(v) == "number" then
                local pct = v <= 1 and (v * 100) or v
                if pct >= 100 then return "DONE" end
                return tostring(math.floor(pct))
            end
        end
        for _, d in ipairs(gen:GetDescendants()) do
            if d:IsA("NumberValue") or d:IsA("IntValue") then
                local n = d.Name:lower()
                if n:find("progress",1,true) or n:find("percent",1,true) or n:find("repair",1,true) then
                    local v = tonumber(d.Value)
                    if v then
                        local pct = v <= 1 and (v * 100) or v
                        if pct >= 100 then return "DONE" end
                        return tostring(math.floor(pct))
                    end
                end
            end
            if d:IsA("TextLabel") and d.Text:find("%%") then
                local s = d.Text:gsub("%%","")
                local num = tonumber(s)
                if num and num >= 100 then return "DONE" end
                return s
            end
        end
        return "0"
    end

    local function getGeneratorCenter(gen)
        if gen.PrimaryPart then return gen.PrimaryPart.Position end
        local best, maxVol = nil, 0
        for _, p in ipairs(gen:GetDescendants()) do
            if p:IsA("BasePart") and p.Transparency < 1 then
                local vol = p.Size.X * p.Size.Y * p.Size.Z
                if vol > maxVol then
                    maxVol = vol
                    best = p 
                end
            end
        end
        if best then return best.Position end
        return gen:GetPivot().Position
    end

    local function applyVaultBox(part)
        if not part or not part:IsA("BasePart") or ESP_Objects[part] then return end
        if part.Name == "VaultTrigger" or part.Name:lower():find("inviswall",1,true) then return end
        if part.Size.Magnitude > 100 then return end
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

    local function scanWorkspaceStatic()
        -- Hanya memindai folder "Map" agar lobi tidak ikut ter-ESP
        local mapFolder = Workspace:FindFirstChild("Map") or Workspace
        for _, obj in ipairs(mapFolder:GetDescendants()) do
            local class = obj.ClassName
            if class == "Model" then
                if not ESP_Objects[obj] then
                    local lower = obj.Name:lower()
                    if lower:find("generator",1,true) then
                        addObjectESP(obj, ESP_Settings.GeneratorColor, false)
                        if not GeneratorTexts[obj] then
                            local txt = Drawing.new("Text")
                            txt.Size = 24
                            txt.Center = true
                            txt.Outline = true
                            txt.Font = 3
                            txt.Color = ESP_Settings.TextColor
                            txt.Text = "0%"
                            txt.Visible = false
                            GeneratorTexts[obj] = txt
                            table.insert(ESP_Drawings, txt)
                            GeneratorData[obj] = { center = getGeneratorCenter(obj), nextUpdate = 0 }
                        end
                    elseif lower:find("zombie",1,true) or lower:find("scp",1,true) or lower:find("minion",1,true) or lower:find("cure",1,true) then
                        if obj:FindFirstChildOfClass("Humanoid") then
                            ESP_Objects[obj] = { Highlight = createHighlight(obj, ESP_Settings.ZombieColor) }
                        end
                    elseif lower:find("bear trap",1,true) or lower:find("beartrap",1,true) or lower:find("butcher trap",1,true) then
                        addObjectESP(obj, ESP_Settings.TrapColor, false)
                    elseif lower:find("pallet",1,true) and not lower:find("crate",1,true) and not lower:find("v1",1,true) and not lower:find("v2",1,true) then
                        addObjectESP(obj, ESP_Settings.PalletColor, false)
                    elseif lower:find("window",1,true) then
                        local hasTrigger = obj:FindFirstChild("VaultTrigger", true) ~= nil
                        local hasPrompt  = false
                        for _, d in ipairs(obj:GetDescendants()) do
                            if d:IsA("ProximityPrompt") then 
                                hasPrompt = true 
                                break 
                            end
                        end
                        if hasTrigger or hasPrompt then
                            for _, part in ipairs(obj:GetDescendants()) do 
                                applyVaultBox(part) 
                            end
                        end
                    end
                end
            elseif class == "Part" then
                if not ESP_Objects[obj] then
                    local lower = obj.Name:lower()
                    if lower:find("bear trap",1,true) or lower:find("beartrap",1,true) or lower:find("butcher trap",1,true) then
                        addObjectESP(obj, ESP_Settings.TrapColor, false)
                    elseif obj.Name == "VaultTrigger" and obj.Parent then
                        for _, p in ipairs(obj.Parent:GetDescendants()) do 
                            applyVaultBox(p) 
                        end
                    end
                end
            elseif class == "ProximityPrompt" then
                local text = ((obj.ActionText or "") .. " " .. (obj.ObjectText or "")):lower()
                if text:find("vault",1,true) or text:find("climb",1,true) or text:find("jump",1,true) then
                    local target = obj.Parent
                    if target and target:IsA("BasePart") then 
                        applyVaultBox(target)
                    elseif target and target:IsA("Model") then
                        for _, part in ipairs(target:GetDescendants()) do 
                            applyVaultBox(part) 
                        end
                    end
                end
            end
        end
    end

    local renderConn = RunService.RenderStepped:Connect(function()
        if not ESP_Active then return end
        local cam = Workspace.CurrentCamera
        if not cam then return end
        local now = os.clock()
        for gen, txt in pairs(GeneratorTexts) do
            if gen and gen.Parent then
                local gd = GeneratorData[gen]
                if not gd then
                    gd = { center = getGeneratorCenter(gen), nextUpdate = 0 }
                    GeneratorData[gen] = gd
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
                            txt.Text = "DONE"
                            txt.Color = ESP_Settings.DoneColor
                            if ed and ed.Highlight then
                                ed.Highlight.FillColor = ESP_Settings.DoneColor
                                ed.Highlight.OutlineColor = ESP_Settings.DoneColor
                            end
                        else
                            txt.Text = prog .. "%"
                            txt.Color = ESP_Settings.TextColor
                            if ed and ed.Highlight then
                                ed.Highlight.FillColor = ESP_Settings.GeneratorColor
                                ed.Highlight.OutlineColor = ESP_Settings.GeneratorColor
                            end
                        end
                    end
                else
                    txt.Visible = false
                end
            else
                txt:Remove()
                GeneratorTexts[gen] = nil
                GeneratorData[gen] = nil
            end
        end
    end)
    table.insert(ESP_Connections, renderConn)

    local addedConn = Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            task.wait(1)
            if ESP_Active then
                addPlayerESP(player)
            end
        end)
    end)
    table.insert(ESP_Connections, addedConn)
    
    local removingConn = Players.PlayerRemoving:Connect(function(player)
        if player.Character and ESP_Objects[player.Character] then
            local data = ESP_Objects[player.Character]
            if data.Highlight then 
                data.Highlight:Destroy() 
            end
            ESP_Objects[player.Character] = nil
        end
        PlayerRoleCache[player] = nil
    end)
    table.insert(ESP_Connections, removingConn)

    scanPlayers()
    scanWorkspaceStatic()

    task.spawn(function()
        while ESP_Active do
            task.wait(PLAYER_SCAN_INTERVAL)
            if ESP_Active then
                scanPlayers()
                updatePlayerRoles()
            end
        end
    end)

    task.spawn(function()
        while ESP_Active do
            task.wait(STATIC_SCAN_INTERVAL)
            if ESP_Active then
                scanWorkspaceStatic()
            end
        end
    end)
    
    ShowNotification("ESP", "ESP Enabled")
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
