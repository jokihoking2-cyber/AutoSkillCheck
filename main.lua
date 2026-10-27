-- ============================================
-- AUTO SKILL CHECK + ESP (PREMIUM GLASS EDITION V5.4.1 - HARDENED & OPTIMIZED)
-- Violence District
-- ============================================

if _G.__VD_Unload then pcall(_G.__VD_Unload); _G.__VD_Unload = nil end

local Players              = game:GetService("Players")
local RunService           = game:GetService("RunService")
local Workspace            = game:GetService("Workspace")
local VirtualInputManager  = game:GetService("VirtualInputManager")
local TweenService         = game:GetService("TweenService")
local UserInputService     = game:GetService("UserInputService")
local StarterGui           = game:GetService("StarterGui")
local CoreGui              = game:GetService("CoreGui")
local Lighting             = game:GetService("Lighting")
local HttpService          = game:GetService("HttpService")
local GuiService           = game:GetService("GuiService")

local LocalPlayer          = Players.LocalPlayer
local PlayerGui            = LocalPlayer:WaitForChild("PlayerGui")

-- ==========================================
-- 🔐 CAPABILITY CHECK (STARTUP)
-- ==========================================
local Capabilities = {
    FileIO = false,
    Drawing = false,
}

pcall(function()
    if type(isfile) == "function" and type(isfolder) == "function"
       and type(makefolder) == "function" and type(writefile) == "function"
       and type(readfile) == "function" and type(delfile) == "function"
       and type(listfiles) == "function" then
        Capabilities.FileIO = true
    end
end)

do
    local hasDrawing = (type(Drawing) == "table" and type(Drawing.new) == "function")
    if hasDrawing then
        local ok, test = pcall(function() return Drawing.new("Text") end)
        if ok and test then
            pcall(function() test:Remove() end)
            Capabilities.Drawing = true
        end
    end
end

-- ==========================================
-- 🔐 HELPER KEAMANAN & UTIL
-- ==========================================
local function SanitizeConfigName(name)
    if type(name) ~= "string" then return nil end
    name = name:sub(1, 50)
    name = name:gsub("%s+", "_")
    name = name:gsub("%.json$", "")
    name = name:gsub("[^%w_%-]", "")
    name = name:gsub("^_+", "")
    if name == "" or name == "autoload" then return nil end
    return name
end

local VALID_MODES = { Legit = true, Normal = true, Random = true }
local function ValidateConfigData(data)
    if type(data) ~= "table" then return nil end
    local out = {}
    local hasAny = false
    if type(data.Mode) == "string" and VALID_MODES[data.Mode] then
        out.Mode = data.Mode
        hasAny = true
    end
    if type(data.AutoSkill) == "boolean" then
        out.AutoSkill = data.AutoSkill
        hasAny = true
    end
    if not hasAny then return nil end
    return out
end

local function SafeReadFile(path, maxBytes)
    if not Capabilities.FileIO then return nil end
    if not isfile(path) then return nil end
    local ok, content = pcall(readfile, path)
    if not ok or type(content) ~= "string" then return nil end
    if #content > (maxBytes or 100000) then return nil end
    return content
end

local function GetGuiContainer()
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    return CoreGui
end

local function SafeParentGui(gui)
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then gui.Parent = hui; return end
    end
    if syn and syn.protect_gui then
        pcall(syn.protect_gui, gui)
        gui.Parent = CoreGui; return
    end
    if protect_gui then
        pcall(protect_gui, gui)
        gui.Parent = CoreGui; return
    end
    gui.Parent = CoreGui
end

local function IsPointInFrame(point, frame)
    if not frame or not frame.Parent then return false end
    local pos = frame.AbsolutePosition
    local size = frame.AbsoluteSize
    return point.X >= pos.X and point.X <= pos.X + size.X and
           point.Y >= pos.Y and point.Y <= pos.Y + size.Y
end

local function GetMouseScreenPos()
    local ok, inset = pcall(function() return (GuiService:GetGuiInset()) end)
    local loc = UserInputService:GetMouseLocation()
    if ok and inset then
        return loc + inset
    end
    return loc
end

-- Angular distance 0/360 wraparound
local function AngleDiff(a, b)
    local d = math.abs((a - b) % 360)
    if d > 180 then d = 360 - d end
    return d
end

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

if Capabilities.FileIO then
    pcall(function()
        if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end
    end)
end

-- ==========================================
-- 👁️ VARIABEL ESP
-- ==========================================
local ESP_Active = false
local ESP_Generation = 0
local ESP_Connections = {}
local ESP_Drawings = {}
local ESP_Highlights = {}

local ESP_Objects          = {}
local GeneratorTexts       = {}
local GeneratorData        = {}
local PlayerCharacterConns = {}

local PlayerRoleCache = setmetatable({}, {__mode = "k"})

local ESP_Settings = {
    PlayerColor    = Color3.fromRGB(0, 255, 128),
    KillerColor    = Color3.fromRGB(255, 50, 50),
    SurvivorColor  = Color3.fromRGB(50, 150, 255),
    GeneratorColor = Color3.fromRGB(170, 0, 255),
    TextColor      = Color3.fromRGB(255, 255, 255),
    DoneColor      = Color3.fromRGB(0, 255, 128),
    TrapColor      = Color3.fromRGB(255, 0, 255),
    ZombieColor    = Color3.fromRGB(255, 0, 255),
    WindowColor    = Color3.fromRGB(0, 255, 255),
    PalletColor    = Color3.fromRGB(255, 140, 0),
}

local RENDER_DISTANCE = 500
local RENDER_DIST_SQ  = RENDER_DISTANCE * RENDER_DISTANCE
local GEN_PROGRESS_INTERVAL = 0.25

local ClearESP
local RefreshConfigList

local function destroyHighlight(h)
    if not h then return end
    for i = #ESP_Highlights, 1, -1 do
        if ESP_Highlights[i] == h then
            table.remove(ESP_Highlights, i)
            break
        end
    end
    pcall(function() h:Destroy() end)
end

local function destroyDrawing(d)
    if not d then return end
    for i = #ESP_Drawings, 1, -1 do
        if ESP_Drawings[i] == d then
            table.remove(ESP_Drawings, i)
            break
        end
    end
    pcall(function() d:Remove() end)
end

-- ==========================================
-- 🎨 TEMA UI
-- ==========================================
local Theme = {
    BgMain = Color3.fromRGB(18, 18, 22),
    BgSidebar = Color3.fromRGB(12, 12, 15),
    Accent = Color3.fromRGB(100, 120, 255),
    AccentGradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 120, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 100, 255))
    }),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(150, 150, 160),
    ItemBg = Color3.fromRGB(30, 30, 40),
    Red = Color3.fromRGB(255, 60, 80)
}

local ArrowDownIcon = "rbxassetid://6031090990"
local CheckIcon = "rbxassetid://6031091004"

local COLOR_ON  = Theme.Accent
local COLOR_OFF = Color3.fromRGB(40, 40, 50)
local POS_ON    = UDim2.new(1, -22, 0.5, -10)
local POS_OFF   = UDim2.new(0, 2, 0.5, -10)

local function ShowNotification(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title; Text = text; Duration = 2;})
    end)
end

local function AddCorner(inst, radius)
    local c = Instance.new("UICorner"); c.CornerRadius = radius; c.Parent = inst; return c
end

local function AddStroke(inst, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Accent
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.5
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = inst
    return s
end

-- ==========================================
-- 🖥️ MEMBUAT GUI UTAMA
-- ==========================================
pcall(function()
    local oldPg = PlayerGui:FindFirstChild("SkillCheckHub")
    if oldPg then oldPg:Destroy() end
end)
pcall(function()
    local oldCg = CoreGui:FindFirstChild("SkillCheckHub")
    if oldCg then oldCg:Destroy() end
end)

local MainGui = Instance.new("ScreenGui")
MainGui.Name = "SkillCheckHub"
MainGui.ResetOnSpawn = false
MainGui.IgnoreGuiInset = true
MainGui.DisplayOrder = 999999
SafeParentGui(MainGui)

local Blur = Lighting:FindFirstChildOfClass("BlurEffect")
local OwnsBlur = false
if not Blur then
    Blur = Instance.new("BlurEffect")
    Blur.Size = 15
    Blur.Parent = Lighting
    OwnsBlur = true
end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 480, 0, 300)
MainFrame.Position = UDim2.new(0.5, -240, 0.5, -150)
MainFrame.BackgroundColor3 = Theme.BgMain
MainFrame.BackgroundTransparency = 0.1
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ZIndex = 1
MainFrame.Parent = MainGui
AddCorner(MainFrame, UDim.new(0, 12))
AddStroke(MainFrame, Theme.Accent, 1.5, 0.6)

local bgGrad = Instance.new("UIGradient")
bgGrad.Color = ColorSequence.new(Color3.fromRGB(25, 25, 35), Color3.fromRGB(10, 10, 15))
bgGrad.Rotation = 45
bgGrad.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 35)
TopBar.BackgroundTransparency = 1
TopBar.ZIndex = 2
TopBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "VIOLENCE DISTRICT"
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 3
Title.Parent = TopBar

local TitleGrad = Instance.new("UIGradient")
TitleGrad.Color = Theme.AccentGradient
TitleGrad.Parent = Title

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 2.5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Theme.TextDim
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.AutoButtonColor = false
CloseBtn.ZIndex = 3
CloseBtn.Parent = TopBar
AddCorner(CloseBtn, UDim.new(0, 6))

CloseBtn.MouseEnter:Connect(function() TweenService:Create(CloseBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Red, TextColor3 = Theme.Text}):Play() end)
CloseBtn.MouseLeave:Connect(function() TweenService:Create(CloseBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLOR_OFF, TextColor3 = Theme.TextDim}):Play() end)
CloseBtn.MouseButton1Click:Connect(function()
    MainGui.Enabled = false
    if OwnsBlur and Blur then Blur.Enabled = false end
    ShowNotification("Hidden", "GUI disembunyikan. Tekan [RightAlt] untuk buka. Fitur tetap aktif.")
end)

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 130, 1, -35)
Sidebar.Position = UDim2.new(0, 0, 0, 35)
Sidebar.BackgroundColor3 = Theme.BgSidebar
Sidebar.BackgroundTransparency = 0.2
Sidebar.BorderSizePixel = 0
Sidebar.Active = false
Sidebar.ZIndex = 2
Sidebar.Parent = MainFrame

local SidebarFix = Instance.new("Frame")
SidebarFix.Size = UDim2.new(0, 12, 1, 0)
SidebarFix.Position = UDim2.new(1, -12, 0, 0)
SidebarFix.BackgroundColor3 = Theme.BgSidebar
SidebarFix.BackgroundTransparency = 0.2
SidebarFix.BorderSizePixel = 0
SidebarFix.ZIndex = 2
SidebarFix.Parent = Sidebar

local function CreateTabBtn(text, iconId, yPos)
    local btn = Instance.new("TextButton")
    btn.Selectable = false
    btn.Size = UDim2.new(1, -20, 0, 40)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = Theme.BgSidebar
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.ZIndex = 3
    btn.Parent = Sidebar
    AddCorner(btn, UDim.new(0, 8))

    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.Size = UDim2.new(0, 4, 0, 20)
    indicator.Position = UDim2.new(0, 0, 0.5, -10)
    indicator.BackgroundColor3 = Theme.Accent
    indicator.Visible = false
    indicator.ZIndex = 4
    indicator.Parent = btn
    AddCorner(indicator, UDim.new(1, 0))

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 20, 0, 20)
    icon.Position = UDim2.new(0, 15, 0.5, -10)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxassetid://" .. iconId
    icon.ImageColor3 = Theme.TextDim
    icon.ZIndex = 4
    icon.Parent = btn

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, -45, 1, 0)
    txt.Position = UDim2.new(0, 45, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Text = text
    txt.TextColor3 = Theme.TextDim
    txt.Font = Enum.Font.GothamMedium
    txt.TextSize = 13
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.ZIndex = 4
    txt.Parent = btn

    btn.MouseEnter:Connect(function()
        if btn.BackgroundTransparency == 1 then
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ItemBg, BackgroundTransparency = 0.5}):Play()
            TweenService:Create(txt, TweenInfo.new(0.2), {TextColor3 = Theme.Text}):Play()
            TweenService:Create(icon, TweenInfo.new(0.2), {ImageColor3 = Theme.Text}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if not indicator.Visible then
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.BgSidebar, BackgroundTransparency = 1}):Play()
            TweenService:Create(txt, TweenInfo.new(0.2), {TextColor3 = Theme.TextDim}):Play()
            TweenService:Create(icon, TweenInfo.new(0.2), {ImageColor3 = Theme.TextDim}):Play()
        end
    end)

    return btn, indicator, txt, icon
end

local TabSkillBtn, IndSkill, TxtSkill, IcoSkill = CreateTabBtn("Skill Check", "6031075931", 15)
local TabEspBtn, IndEsp, TxtEsp, IcoEsp = CreateTabBtn("ESP", "6031091004", 65)
local TabSettingBtn, IndSetting, TxtSetting, IcoSetting = CreateTabBtn("Setting", "6031075927", 115)

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -140, 1, -45)
Content.Position = UDim2.new(0, 130, 0, 40)
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

local function CreateGlassToggle(parent, text, yPos)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.Position = UDim2.new(0, 0, 0, yPos)
    frame.BackgroundColor3 = Theme.ItemBg
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Active = false
    frame.ZIndex = 4
    frame.Parent = parent
    AddCorner(frame, UDim.new(0, 8))
    AddStroke(frame, Color3.fromRGB(50, 50, 60), 1, 0.8)

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, -70, 1, 0)
    txt.Position = UDim2.new(0, 15, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Text = text
    txt.TextColor3 = Theme.Text
    txt.Font = Enum.Font.GothamMedium
    txt.TextSize = 14
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.ZIndex = 5
    txt.Parent = frame

    local switchBg = Instance.new("Frame")
    switchBg.Size = UDim2.new(0, 44, 0, 24)
    switchBg.Position = UDim2.new(1, -59, 0.5, -12)
    switchBg.BackgroundColor3 = COLOR_OFF
    switchBg.ZIndex = 5
    switchBg.Parent = frame
    AddCorner(switchBg, UDim.new(1, 0))

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = UDim2.new(0, 2, 0.5, -10)
    knob.BackgroundColor3 = Color3.fromRGB(150, 150, 160)
    knob.ZIndex = 6
    knob.Parent = switchBg
    AddCorner(knob, UDim.new(1, 0))

    local btn = Instance.new("TextButton")
    btn.Selectable = false
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 7
    btn.Parent = switchBg

    return frame, btn, switchBg, knob
end

local _, ToggleBtn, SwitchBg, SwitchKnob = CreateGlassToggle(SkillPage, "Auto Skill Check", 0)

local DropdownFrame = Instance.new("Frame")
DropdownFrame.Size = UDim2.new(1, 0, 0, 50)
DropdownFrame.Position = UDim2.new(0, 0, 0, 60)
DropdownFrame.BackgroundColor3 = Theme.ItemBg
DropdownFrame.BackgroundTransparency = 0.3
DropdownFrame.BorderSizePixel = 0
DropdownFrame.Active = false
DropdownFrame.ZIndex = 4
DropdownFrame.Parent = SkillPage
AddCorner(DropdownFrame, UDim.new(0, 8))
AddStroke(DropdownFrame, Color3.fromRGB(50, 50, 60), 1, 0.8)

local DropdownText = Instance.new("TextLabel")
DropdownText.Size = UDim2.new(1, -70, 1, 0)
DropdownText.Position = UDim2.new(0, 15, 0, 0)
DropdownText.BackgroundTransparency = 1
DropdownText.Text = "Skill Check Mode"
DropdownText.TextColor3 = Theme.Text
DropdownText.Font = Enum.Font.GothamMedium
DropdownText.TextSize = 14
DropdownText.TextXAlignment = Enum.TextXAlignment.Left
DropdownText.ZIndex = 5
DropdownText.Parent = DropdownFrame

local SelectedLabel = Instance.new("TextLabel")
SelectedLabel.Size = UDim2.new(0, 80, 1, 0)
SelectedLabel.Position = UDim2.new(1, -105, 0, 0)
SelectedLabel.BackgroundTransparency = 1
SelectedLabel.Text = "Legit"
SelectedLabel.TextColor3 = Theme.Accent
SelectedLabel.Font = Enum.Font.GothamBold
SelectedLabel.TextSize = 14
SelectedLabel.TextXAlignment = Enum.TextXAlignment.Right
SelectedLabel.ZIndex = 5
SelectedLabel.Parent = DropdownFrame

local DropdownArrow = Instance.new("ImageLabel")
DropdownArrow.Size = UDim2.new(0, 16, 0, 16)
DropdownArrow.Position = UDim2.new(1, -25, 0.5, -8)
DropdownArrow.BackgroundTransparency = 1
DropdownArrow.Image = ArrowDownIcon
DropdownArrow.ImageColor3 = Theme.Accent
DropdownArrow.ZIndex = 5
DropdownArrow.Parent = DropdownFrame

local DropdownBtn = Instance.new("TextButton")
DropdownBtn.Selectable = false
DropdownBtn.Size = UDim2.new(1, 0, 1, 0)
DropdownBtn.BackgroundTransparency = 1
DropdownBtn.Text = ""
DropdownBtn.ZIndex = 6
DropdownBtn.Parent = DropdownFrame

-- [FIX] Tinggi OptionsList ditambah menjadi 120
local OptionsList = Instance.new("Frame")
OptionsList.Size = UDim2.new(1, 0, 0, 120)
OptionsList.Position = UDim2.new(0, 0, 0, 55)
OptionsList.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
OptionsList.BackgroundTransparency = 0
OptionsList.BorderSizePixel = 0
OptionsList.Visible = false
OptionsList.Active = false
OptionsList.ZIndex = 20
OptionsList.Parent = DropdownFrame
AddCorner(OptionsList, UDim.new(0, 8))
AddStroke(OptionsList, Theme.Accent, 1.5, 0.4)

local OptGrad = Instance.new("UIGradient")
OptGrad.Color = ColorSequence.new(Color3.fromRGB(30, 30, 40), Color3.fromRGB(15, 15, 20))
OptGrad.Rotation = 90
OptGrad.Parent = OptionsList

local UIPadding = Instance.new("UIPadding")
UIPadding.PaddingTop = UDim.new(0, 8)
UIPadding.PaddingBottom = UDim.new(0, 8)
UIPadding.Parent = OptionsList

local OptionsLayout = Instance.new("UIListLayout")
OptionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
OptionsLayout.Padding = UDim.new(0, 4)
OptionsLayout.Parent = OptionsList

local Modes = {"Legit", "Normal", "Random"}
local OptionButtons = {}

local function UpdateDropdownUI()
    for mode, data in pairs(OptionButtons) do
        local btn = data.Btn
        local checkIcon = data.Icon
        if mode == CurrentMode then
            btn.TextColor3 = Theme.Text
            btn.BackgroundColor3 = Theme.Accent
            btn.BackgroundTransparency = 0.8
            checkIcon.Visible = true
            TweenService:Create(checkIcon, TweenInfo.new(0.2), {ImageTransparency = 0}):Play()
        else
            btn.TextColor3 = Theme.TextDim
            btn.BackgroundColor3 = Theme.BgSidebar
            btn.BackgroundTransparency = 1
            checkIcon.Visible = false
            checkIcon.ImageTransparency = 1
        end
    end
    SelectedLabel.Text = CurrentMode
end

for i, mode in ipairs(Modes) do
    local btn = Instance.new("TextButton")
    btn.Selectable = false
    btn.Active = true -- [FIX] Tambahan agar tombol bisa diklik dengan baik
    btn.Size = UDim2.new(1, -10, 0, 26)
    btn.BackgroundColor3 = Theme.BgSidebar
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.Text = "  " .. mode
    btn.TextColor3 = Theme.TextDim
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    btn.ZIndex = 21
    btn.Parent = OptionsList
    AddCorner(btn, UDim.new(0, 6))

    local checkIcon = Instance.new("ImageLabel")
    checkIcon.Size = UDim2.new(0, 16, 0, 16)
    checkIcon.Position = UDim2.new(1, -20, 0.5, -8)
    checkIcon.BackgroundTransparency = 1
    checkIcon.Image = CheckIcon
    checkIcon.ImageColor3 = Theme.Accent
    checkIcon.ZIndex = 22
    checkIcon.Parent = btn

    btn.MouseEnter:Connect(function()
        if CurrentMode ~= mode then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(50, 50, 60), BackgroundTransparency = 0.5, TextColor3 = Theme.Text}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if CurrentMode ~= mode then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.BgSidebar, BackgroundTransparency = 1, TextColor3 = Theme.TextDim}):Play()
        end
    end)

    btn.MouseButton1Click:Connect(function()
        CurrentMode = mode
        UpdateDropdownUI()
        OptionsList.Visible = false
        ShowNotification("Skill Check", "Mode: " .. mode)
    end)

    OptionButtons[mode] = {Btn = btn, Icon = checkIcon}
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

local _, EspToggleBtn, EspSwitchBg, EspSwitchKnob = CreateGlassToggle(EspPage, "Enable Full ESP", 0)

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
SettingPage.ScrollBarImageColor3 = Theme.Accent
SettingPage.Parent = Content

local SettingLayout = Instance.new("UIListLayout")
SettingLayout.SortOrder = Enum.SortOrder.LayoutOrder
SettingLayout.Padding = UDim.new(0, 6)
SettingLayout.Parent = SettingPage

local function CreateSettingRow(order, textLabel)
    local row = Instance.new("TextButton")
    row.Selectable = false
    row.Size = UDim2.new(1, 0, 0, 40)
    row.BackgroundColor3 = Theme.ItemBg
    row.BackgroundTransparency = 0.3
    row.BorderSizePixel = 0
    row.Text = ""
    row.AutoButtonColor = false
    row.ZIndex = 4
    row.LayoutOrder = order
    row.Parent = SettingPage
    AddCorner(row, UDim.new(0, 8))
    AddStroke(row, Color3.fromRGB(50, 50, 60), 1, 0.8)

    row.MouseEnter:Connect(function() TweenService:Create(row, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 60), BackgroundTransparency = 0.2}):Play() end)
    row.MouseLeave:Connect(function() TweenService:Create(row, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ItemBg, BackgroundTransparency = 0.3}):Play() end)

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, -20, 1, 0)
    txt.Position = UDim2.new(0, 15, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Text = textLabel
    txt.TextColor3 = Theme.Text
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
ConfigNameBox.Size = UDim2.new(0, 120, 0, 28)
ConfigNameBox.Position = UDim2.new(1, -135, 0.5, -14)
ConfigNameBox.BackgroundColor3 = Theme.BgMain
ConfigNameBox.BackgroundTransparency = 0.5
ConfigNameBox.Text = ""
ConfigNameBox.PlaceholderText = "Ketik nama..."
ConfigNameBox.PlaceholderColor3 = Theme.TextDim
ConfigNameBox.TextColor3 = Theme.Accent
ConfigNameBox.Font = Enum.Font.GothamBold
ConfigNameBox.TextSize = 12
ConfigNameBox.ZIndex = 6
ConfigNameBox.Parent = ConfigNameRow
AddCorner(ConfigNameBox, UDim.new(0, 4))
AddStroke(ConfigNameBox, Color3.fromRGB(50, 50, 60), 1, 0.5)

local SelectRow = CreateSettingRow(2, "Select Config")
local SelectLabel = Instance.new("TextLabel")
SelectLabel.Size = UDim2.new(0, 80, 1, 0)
SelectLabel.Position = UDim2.new(1, -105, 0, 0)
SelectLabel.BackgroundTransparency = 1
SelectLabel.Text = "None"
SelectLabel.TextColor3 = Theme.TextDim
SelectLabel.Font = Enum.Font.GothamBold
SelectLabel.TextSize = 14
SelectLabel.TextXAlignment = Enum.TextXAlignment.Right
SelectLabel.ZIndex = 5
SelectLabel.Parent = SelectRow

local ConfigArrow = Instance.new("ImageLabel")
ConfigArrow.Size = UDim2.new(0, 16, 0, 16)
ConfigArrow.Position = UDim2.new(1, -25, 0.5, -8)
ConfigArrow.BackgroundTransparency = 1
ConfigArrow.Image = ArrowDownIcon
ConfigArrow.ImageColor3 = Theme.TextDim
ConfigArrow.ZIndex = 5
ConfigArrow.Parent = SelectRow

local ConfigOptionsFrame = Instance.new("Frame")
ConfigOptionsFrame.Size = UDim2.new(1, 0, 0, 0)
ConfigOptionsFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
ConfigOptionsFrame.BackgroundTransparency = 0
ConfigOptionsFrame.Visible = false
ConfigOptionsFrame.Active = false
ConfigOptionsFrame.ZIndex = 100
ConfigOptionsFrame.Parent = Content
AddCorner(ConfigOptionsFrame, UDim.new(0, 8))
AddStroke(ConfigOptionsFrame, Theme.Accent, 1.5, 0.4)

local ConfigGrad = Instance.new("UIGradient")
ConfigGrad.Color = ColorSequence.new(Color3.fromRGB(30, 30, 40), Color3.fromRGB(15, 15, 20))
ConfigGrad.Rotation = 90
ConfigGrad.Parent = ConfigOptionsFrame

local UIPaddingC = Instance.new("UIPadding")
UIPaddingC.PaddingTop = UDim.new(0, 8)
UIPaddingC.PaddingBottom = UDim.new(0, 8)
UIPaddingC.Parent = ConfigOptionsFrame

local ConfigListLayout = Instance.new("UIListLayout")
ConfigListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ConfigListLayout.Padding = UDim.new(0, 4)
ConfigListLayout.Parent = ConfigOptionsFrame

SelectRow.MouseButton1Click:Connect(function()
    local hasConfig = false
    for _, child in pairs(ConfigOptionsFrame:GetChildren()) do
        if child:IsA("TextButton") then hasConfig = true; break; end
    end
    if hasConfig then
        ConfigOptionsFrame.Visible = not ConfigOptionsFrame.Visible
        if ConfigOptionsFrame.Visible then
            local relY = SelectRow.AbsolutePosition.Y - Content.AbsolutePosition.Y + SelectRow.AbsoluteSize.Y
            local maxY = math.max(0, Content.AbsoluteSize.Y - 160)
            relY = math.clamp(relY, 0, maxY)
            ConfigOptionsFrame.Position = UDim2.new(0, 0, 0, relY + 5)
            local cfgCount = 0
            for _, c in ipairs(ConfigOptionsFrame:GetChildren()) do
                if c:IsA("TextButton") then cfgCount = cfgCount + 1 end
            end
            ConfigOptionsFrame.Size = UDim2.new(1, 0, 0, math.min(cfgCount * 30 + 16, 150))
        end
    else
        ShowNotification("Config", "Belum ada config yang tersimpan.")
    end
end)

local RefreshRow = CreateSettingRow(3, "Refresh List")
local SaveRow = CreateSettingRow(4, "Save Config")
local LoadRow = CreateSettingRow(5, "Load Config")
local RemoveRow = CreateSettingRow(6, "Remove Config")

local AutoLoadRow = CreateSettingRow(7, "Auto Load on Start")
local AutoLoadSwitchBg = Instance.new("Frame")
AutoLoadSwitchBg.Size = UDim2.new(0, 40, 0, 22)
AutoLoadSwitchBg.Position = UDim2.new(1, -55, 0.5, -11)
AutoLoadSwitchBg.BackgroundColor3 = COLOR_OFF
AutoLoadSwitchBg.ZIndex = 5
AutoLoadSwitchBg.Parent = AutoLoadRow
AddCorner(AutoLoadSwitchBg, UDim.new(1, 0))

local AutoLoadKnob = Instance.new("Frame")
AutoLoadKnob.Size = UDim2.new(0, 18, 0, 18)
AutoLoadKnob.Position = UDim2.new(0, 2, 0.5, -9)
AutoLoadKnob.BackgroundColor3 = Color3.fromRGB(150, 150, 160)
AutoLoadKnob.ZIndex = 6
AutoLoadKnob.Parent = AutoLoadSwitchBg
AddCorner(AutoLoadKnob, UDim.new(1, 0))

local AUTOLOAD_POS_ON  = UDim2.new(1, -20, 0.5, -9)
local AUTOLOAD_POS_OFF = UDim2.new(0, 2, 0.5, -9)

local UnloadBtn = Instance.new("TextButton")
UnloadBtn.Selectable = false
UnloadBtn.Size = UDim2.new(1, 0, 0, 40)
UnloadBtn.BackgroundColor3 = Theme.Red
UnloadBtn.BackgroundTransparency = 0.2
UnloadBtn.Text = "Unload Script"
UnloadBtn.TextColor3 = Theme.Text
UnloadBtn.Font = Enum.Font.GothamBold
UnloadBtn.TextSize = 14
UnloadBtn.AutoButtonColor = false
UnloadBtn.ZIndex = 10
UnloadBtn.LayoutOrder = 8
UnloadBtn.Parent = SettingPage
AddCorner(UnloadBtn, UDim.new(0, 8))
AddStroke(UnloadBtn, Theme.Red, 1, 0.2)

UnloadBtn.MouseEnter:Connect(function() TweenService:Create(UnloadBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play() end)
UnloadBtn.MouseLeave:Connect(function() TweenService:Create(UnloadBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.2}):Play() end)

-- ==========================================
-- 🔄 LOGIKA CONFIG SYSTEM
-- ==========================================
local AUTOLOAD_PATH = ConfigFolder .. "/_autoload.txt"

local function SetAutoLoad(configName, state)
    if not Capabilities.FileIO then return end
    configName = SanitizeConfigName(configName)
    if not configName then return end
    if state then
        pcall(writefile, AUTOLOAD_PATH, configName)
    else
        pcall(function()
            if isfile(AUTOLOAD_PATH) then delfile(AUTOLOAD_PATH) end
        end)
    end
end

local function UpdateConfigUI()
    if ActiveConfigName == "None" or ActiveConfigName == "" then
        SelectLabel.Text = "None"
        SelectLabel.TextColor3 = Theme.TextDim
        ConfigArrow.ImageColor3 = Theme.TextDim
    else
        SelectLabel.Text = ActiveConfigName
        SelectLabel.TextColor3 = Theme.Accent
        ConfigArrow.ImageColor3 = Theme.Accent
    end
    for _, child in pairs(ConfigOptionsFrame:GetChildren()) do
        if child:IsA("TextButton") then
            local check = child:FindFirstChild("CheckIcon")
            if check then
                if child.Text:gsub("%s+", "") == ActiveConfigName then
                    child.TextColor3 = Theme.Text
                    child.BackgroundColor3 = Theme.Accent
                    child.BackgroundTransparency = 0.8
                    check.Visible = true
                else
                    child.TextColor3 = Theme.TextDim
                    child.BackgroundColor3 = Theme.BgSidebar
                    child.BackgroundTransparency = 1
                    check.Visible = false
                end
            end
        end
    end
end

local function SaveCurrentConfig()
    if not Capabilities.FileIO then
        ShowNotification("Config", "Executor tidak support file IO.")
        return
    end
    local configName = SanitizeConfigName(ConfigNameBox.Text)
    if not configName then
        ShowNotification("Config", "Nama config tidak valid.")
        return
    end
    local path = ConfigFolder .. "/" .. configName .. ".json"
    local payload = { Mode = CurrentMode, AutoSkill = AutoSkillEnabled }
    local ok, encoded = pcall(function() return HttpService:JSONEncode(payload) end)
    if not ok or not encoded then
        ShowNotification("Config", "Gagal encode config.")
        return
    end
    local ok2 = pcall(writefile, path, encoded)
    if ok2 then
        ShowNotification("Config", "Saved: " .. configName)
        ActiveConfigName = configName
        UpdateConfigUI()
        RefreshConfigList()
        if AutoLoadEnabled then SetAutoLoad(configName, true) end
    else
        ShowNotification("Config", "Gagal menyimpan config.")
    end
end

local function LoadSelectedConfig()
    if not Capabilities.FileIO then
        ShowNotification("Config", "Executor tidak support file IO.")
        return
    end
    local safeName = SanitizeConfigName(ActiveConfigName)
    if not safeName then
        ShowNotification("Config", "Nama config tidak valid.")
        return
    end
    local path = ConfigFolder .. "/" .. safeName .. ".json"
    local raw = SafeReadFile(path, 100000)
    if not raw then
        ShowNotification("Config", "File tidak ditemukan atau korup.")
        return
    end
    local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok then
        ShowNotification("Config", "Config tidak valid (JSON error).")
        return
    end

    local valid = ValidateConfigData(data)
    if not valid then
        ShowNotification("Config", "Config tidak punya field valid.")
        return
    end

    if valid.Mode then
        CurrentMode = valid.Mode
        UpdateDropdownUI()
    end
    if valid.AutoSkill ~= nil then
        AutoSkillEnabled = valid.AutoSkill
        SwitchBg.BackgroundColor3 = AutoSkillEnabled and COLOR_ON or COLOR_OFF
        SwitchKnob.Position = AutoSkillEnabled and POS_ON or POS_OFF
    end
    ShowNotification("Config", "Loaded: " .. safeName)
end

function RefreshConfigList()
    if not Capabilities.FileIO then return end
    for _, child in pairs(ConfigOptionsFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local success, files = pcall(function() return listfiles(ConfigFolder) end)
    if success and files then
        local cfgNames = {}
        for _, file in ipairs(files) do
            local name = file:match("([^/\\]+)%.json$")
            if name and SanitizeConfigName(name) == name then
                table.insert(cfgNames, name)
            end
        end
        table.sort(cfgNames)

        for _, cfgName in ipairs(cfgNames) do
            local capturedName = cfgName
            local btn = Instance.new("TextButton")
            btn.Selectable = false
            btn.Size = UDim2.new(1, -10, 0, 26)
            btn.BackgroundColor3 = Theme.BgSidebar
            btn.BackgroundTransparency = 1
            btn.Text = "  " .. capturedName
            btn.TextColor3 = Theme.TextDim
            btn.Font = Enum.Font.GothamMedium
            btn.TextSize = 13
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.AutoButtonColor = false
            btn.ZIndex = 101
            btn.Parent = ConfigOptionsFrame
            AddCorner(btn, UDim.new(0, 6))

            local checkIcon = Instance.new("ImageLabel")
            checkIcon.Name = "CheckIcon"
            checkIcon.Size = UDim2.new(0, 16, 0, 16)
            checkIcon.Position = UDim2.new(1, -20, 0.5, -8)
            checkIcon.BackgroundTransparency = 1
            checkIcon.Image = CheckIcon
            checkIcon.ImageColor3 = Theme.Accent
            checkIcon.Visible = false
            checkIcon.ZIndex = 102
            checkIcon.Parent = btn

            btn.MouseEnter:Connect(function()
                if ActiveConfigName ~= capturedName then
                    TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(50, 50, 60), BackgroundTransparency = 0.5, TextColor3 = Theme.Text}):Play()
                end
            end)
            btn.MouseLeave:Connect(function()
                if ActiveConfigName ~= capturedName then
                    TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.BgSidebar, TextColor3 = Theme.TextDim, BackgroundTransparency = 1}):Play()
                end
            end)

            btn.MouseButton1Click:Connect(function()
                ActiveConfigName = capturedName
                UpdateConfigUI()
                ConfigNameBox.Text = capturedName
                ConfigOptionsFrame.Visible = false
                if AutoLoadEnabled then SetAutoLoad(capturedName, true) end
            end)
        end
    end
    UpdateConfigUI()
end

local function RemoveConfig()
    if not Capabilities.FileIO then return end
    local safeName = SanitizeConfigName(ActiveConfigName)
    if not safeName then return end
    local path = ConfigFolder .. "/" .. safeName .. ".json"
    if isfile(path) then
        pcall(function()
            delfile(path)
            ShowNotification("Config", "Removed: " .. safeName)
            if isfile(AUTOLOAD_PATH) then
                local autoName = SafeReadFile(AUTOLOAD_PATH, 200)
                if autoName == safeName then
                    delfile(AUTOLOAD_PATH)
                    AutoLoadEnabled = false
                    AutoLoadSwitchBg.BackgroundColor3 = COLOR_OFF
                    AutoLoadKnob.Position = AUTOLOAD_POS_OFF
                end
            end
            ActiveConfigName = "None"
            UpdateConfigUI()
            ConfigNameBox.Text = ""
            RefreshConfigList()
        end)
    end
end

RefreshRow.MouseButton1Click:Connect(function() RefreshConfigList(); ShowNotification("Config", "List Refreshed") end)
SaveRow.MouseButton1Click:Connect(SaveCurrentConfig)
LoadRow.MouseButton1Click:Connect(LoadSelectedConfig)
RemoveRow.MouseButton1Click:Connect(RemoveConfig)

AutoLoadRow.MouseButton1Click:Connect(function()
    if not Capabilities.FileIO then
        ShowNotification("Config", "Executor tidak support file IO.")
        return
    end
    if not AutoLoadEnabled and (ActiveConfigName == "None" or ActiveConfigName == "") then
        ShowNotification("Config", "Pilih config dulu sebelum mengaktifkan Auto Load.")
        return
    end
    AutoLoadEnabled = not AutoLoadEnabled
    local targetColor = AutoLoadEnabled and COLOR_ON or COLOR_OFF
    local targetPos = AutoLoadEnabled and AUTOLOAD_POS_ON or AUTOLOAD_POS_OFF
    TweenService:Create(AutoLoadSwitchBg, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
    TweenService:Create(AutoLoadKnob, TweenInfo.new(0.2), {Position = targetPos}):Play()
    if ActiveConfigName ~= "None" then
        SetAutoLoad(ActiveConfigName, AutoLoadEnabled)
    end
end)

local function SwitchTab(tab)
    SkillPage.Visible = (tab == "Skill")
    EspPage.Visible = (tab == "ESP")
    SettingPage.Visible = (tab == "Setting")
    ConfigOptionsFrame.Visible = false
    OptionsList.Visible = false

    IndSkill.Visible = (tab == "Skill")
    IndEsp.Visible = (tab == "ESP")
    IndSetting.Visible = (tab == "Setting")

    local function setColor(lbl, ico, on)
        local c = on and Theme.Text or Theme.TextDim
        lbl.TextColor3 = c
        ico.ImageColor3 = c
    end
    setColor(TxtSkill, IcoSkill, tab == "Skill")
    setColor(TxtEsp, IcoEsp, tab == "ESP")
    setColor(TxtSetting, IcoSetting, tab == "Setting")

    TabSkillBtn.BackgroundTransparency = (tab == "Skill") and 0.5 or 1
    TabEspBtn.BackgroundTransparency = (tab == "ESP") and 0.5 or 1
    TabSettingBtn.BackgroundTransparency = (tab == "Setting") and 0.5 or 1
end

TabSkillBtn.MouseButton1Click:Connect(function() SwitchTab("Skill") end)
TabEspBtn.MouseButton1Click:Connect(function() SwitchTab("ESP") end)
TabSettingBtn.MouseButton1Click:Connect(function() SwitchTab("Setting") end)

DropdownBtn.MouseButton1Click:Connect(function() OptionsList.Visible = not OptionsList.Visible end)

ToggleBtn.MouseButton1Click:Connect(function()
    AutoSkillEnabled = not AutoSkillEnabled
    local targetColor = AutoSkillEnabled and COLOR_ON or COLOR_OFF
    local targetPos = AutoSkillEnabled and POS_ON or POS_OFF
    TweenService:Create(SwitchBg, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
    TweenService:Create(SwitchKnob, TweenInfo.new(0.2), {Position = targetPos}):Play()
    ShowNotification("Auto Skill Check", AutoSkillEnabled and "Enabled" or "Disabled")
end)

local UISConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.RightAlt and MainGui then
        MainGui.Enabled = not MainGui.Enabled
        if OwnsBlur and Blur then Blur.Enabled = MainGui.Enabled end
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mp = GetMouseScreenPos()
        
        -- [FIX] Logika penutupan OptionsList otomatis DIHAPUS agar tidak bentrok dengan pemilihan mode.
        
        if ConfigOptionsFrame.Visible then
            if not IsPointInFrame(mp, SelectRow) and not IsPointInFrame(mp, ConfigOptionsFrame) then
                ConfigOptionsFrame.Visible = false
            end
        end
    end
end)

SwitchTab("Skill")

task.spawn(function()
    task.wait(1)
    RefreshConfigList()
    if Capabilities.FileIO and isfile(AUTOLOAD_PATH) then
        local autoName = SanitizeConfigName(SafeReadFile(AUTOLOAD_PATH, 200) or "")
        if autoName then
            AutoLoadEnabled = true
            AutoLoadSwitchBg.BackgroundColor3 = Theme.Accent
            AutoLoadKnob.Position = AUTOLOAD_POS_ON
            ActiveConfigName = autoName
            UpdateConfigUI()
            ConfigNameBox.Text = ActiveConfigName
            LoadSelectedConfig()
        end
    end
end)

-- ==========================================
-- 🧠 AUTO SKILL CHECK (STATE MACHINE)
-- ==========================================
local _pressCooldown = 0
local function PressSpace()
    local now = os.clock()
    if now - _pressCooldown < 0.05 then return end
    _pressCooldown = now
    task.spawn(function()
        pcall(function()
            VirtualInputManager:SendKeyEvent(true,  Enum.KeyCode.Space, false, game)
            task.wait(0.01)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end)
    end)
end

local _lastTeamCheck, _lastTeamResult = -1, false
local function IsSurvivor()
    local now = os.clock()
    if now - _lastTeamCheck < 0.5 then return _lastTeamResult end
    _lastTeamCheck = now
    local t = LocalPlayer.Team
    if t and t.Name:lower():find("survivor", 1, true) then _lastTeamResult = true; return true end
    local role = LocalPlayer:GetAttribute("Role") or LocalPlayer:GetAttribute("Team")
    if role then
        local r = tostring(role):lower()
        if r:find("surv", 1, true) or r:find("innoc", 1, true) or r:find("runner", 1, true) then
            _lastTeamResult = true; return true
        end
    end
    _lastTeamResult = false
    return false
end

local lastCheck = nil
local hasPressed = false
local lastGoalRotation = -999
local lastActiveGoal = nil
local cachedWindow = WINDOWS.Legit
local SkillCheckConnection
local cachedLine, cachedGoal, cachedTrapPerfect, cachedTrapGoal

local function ResetSkillCycle()
    hasPressed = false
    lastGoalRotation = -999
    lastActiveGoal = nil
end

local function PickWindowForCycle()
    if CurrentMode == "Random" then
        cachedWindow = (math.random(1, 100) <= 40) and WINDOWS.Legit or WINDOWS.Normal
    elseif CurrentMode == "Normal" then
        cachedWindow = WINDOWS.Normal
    else
        cachedWindow = WINDOWS.Legit
    end
end

local function OnSkillCheckFrame()
    if not AutoSkillEnabled or not IsSurvivor() then
        lastCheck = nil; ResetSkillCycle()
        return
    end
    local prompt = PlayerGui:FindFirstChild("SkillCheckPromptGui")
    if not prompt then return end
    local check = prompt:FindFirstChild("Check")
    if not check or not check.Visible then
        lastCheck = nil; ResetSkillCycle()
        return
    end

    if lastCheck ~= check then
        lastCheck = check
        ResetSkillCycle()
        PickWindowForCycle()
        cachedLine = check:FindFirstChild("Line")
        cachedGoal = check:FindFirstChild("Goal")
        cachedTrapPerfect = check:FindFirstChild("TrapPerfect")
        cachedTrapGoal = check:FindFirstChild("TrapGoal")
    else
        if cachedLine and cachedLine.Parent ~= check then
            cachedLine = check:FindFirstChild("Line")
            cachedGoal = check:FindFirstChild("Goal")
            cachedTrapPerfect = check:FindFirstChild("TrapPerfect")
            cachedTrapGoal = check:FindFirstChild("TrapGoal")
        end
    end

    if not cachedLine then return end

    local activeGoal = cachedGoal
    if cachedTrapPerfect and cachedTrapPerfect.Visible then activeGoal = cachedTrapPerfect
    elseif cachedTrapGoal and cachedTrapGoal.Visible then activeGoal = cachedTrapGoal end
    if not activeGoal then return end

    if lastActiveGoal ~= activeGoal then
        lastActiveGoal = activeGoal
        hasPressed = false
        lastGoalRotation = -999
    end

    local gr = activeGoal.Rotation % 360
    local lr = cachedLine.Rotation % 360

    if lastGoalRotation ~= -999 and AngleDiff(gr, lastGoalRotation) > 5 then
        hasPressed = false
    end
    lastGoalRotation = gr

    local targetWindow = cachedWindow or WINDOWS.Legit
    local ss = (gr + targetWindow.start) % 360
    local se = (gr + targetWindow.stop) % 360
    local hit
    if ss > se then hit = (lr >= ss or lr <= se)
    else hit = (lr >= ss and lr <= se) end

    if hit and not hasPressed then
        PressSpace()
        hasPressed = true
    end
end

SkillCheckConnection = RunService.RenderStepped:Connect(OnSkillCheckFrame)

-- ==========================================
-- 🧹 UNLOAD
-- ==========================================
local function UnloadAll()
    if SkillCheckConnection then
        pcall(function() SkillCheckConnection:Disconnect() end)
        SkillCheckConnection = nil
    end
    if UISConnection then
        pcall(function() UISConnection:Disconnect() end)
        UISConnection = nil
    end
    if ClearESP then pcall(ClearESP) end
    if OwnsBlur and Blur and Blur.Parent then
        pcall(function() Blur:Destroy() end)
    end
    if MainGui and MainGui.Parent then
        pcall(function() MainGui:Destroy() end)
    end
end

_G.__VD_Unload = UnloadAll

MainGui.Destroying:Connect(function()
    if ClearESP then pcall(ClearESP) end
    if OwnsBlur and Blur and Blur.Parent then
        pcall(function() Blur:Destroy() end)
    end
    if UISConnection then pcall(function() UISConnection:Disconnect() end) end
    if SkillCheckConnection then pcall(function() SkillCheckConnection:Disconnect() end) end
end)

UnloadBtn.MouseButton1Click:Connect(function()
    ShowNotification("Auto Skill Check", "Script berhasil di-Unload.")
    UnloadAll()
end)

-- ==========================================
-- 👁️ LOGIKA ESP (HARDENED)
-- ==========================================
ClearESP = function()
    ESP_Generation = ESP_Generation + 1
    ESP_Active = false

    for _, data in pairs(ESP_Objects) do
        if data.Box then pcall(function() data.Box:Destroy() end) end
        if data.Highlight then pcall(function() data.Highlight:Destroy() end) end
    end
    table.clear(ESP_Objects)

    for _, conn in pairs(ESP_Connections) do pcall(function() conn:Disconnect() end) end
    table.clear(ESP_Connections)

    for _, conns in pairs(PlayerCharacterConns) do
        if conns.Added    then pcall(function() conns.Added:Disconnect() end)    end
        if conns.Removing then pcall(function() conns.Removing:Disconnect() end) end
    end
    table.clear(PlayerCharacterConns)

    for _, d in pairs(ESP_Drawings) do pcall(function() d:Remove() end) end
    table.clear(ESP_Drawings)
    table.clear(GeneratorTexts)
    table.clear(GeneratorData)

    for _, h in pairs(ESP_Highlights) do pcall(function() h:Destroy() end) end
    table.clear(ESP_Highlights)

    table.clear(PlayerRoleCache)
end

local function StartESP()
    if ESP_Active then return end
    if not Capabilities.Drawing then
        ShowNotification("ESP", "Executor tidak support Drawing API.")
        EspSwitchBg.BackgroundColor3 = COLOR_OFF
        EspSwitchKnob.Position = POS_OFF
        return
    end

    ESP_Active = true
    ESP_Generation = ESP_Generation + 1
    local myGen = ESP_Generation

    local guiContainer = GetGuiContainer()

    local function createHighlight(object, color)
        local h = Instance.new("Highlight")
        h.Name = "ESP_Highlight"
        h.Adornee = object
        h.FillColor = color
        h.FillTransparency = 0.8
        h.OutlineColor = color
        h.OutlineTransparency = 0.1
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = guiContainer
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

    local function trackPlayerCharacter(player)
        if player == LocalPlayer then return end
        if PlayerCharacterConns[player] then return end
        local conns = {}
        conns.Added = player.CharacterAdded:Connect(function()
            task.wait(1)
            if ESP_Active and ESP_Generation == myGen and player.Character then
                addPlayerESP(player)
            end
        end)
        conns.Removing = player.CharacterRemoving:Connect(function(char)
            local data = ESP_Objects[char]
            if data then
                if data.Highlight then destroyHighlight(data.Highlight) end
                if data.Box then pcall(function() data.Box:Destroy() end) end
                ESP_Objects[char] = nil
            end
        end)
        PlayerCharacterConns[player] = conns
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
                local pct
                if v >= 0 and v <= 1 then
                    pct = v * 100
                else
                    pct = v
                end
                return pct >= 100 and "DONE" or tostring(math.floor(pct))
            end
        end
        return "0"
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
        box.Parent = guiContainer
        ESP_Objects[part] = { Box = box }
    end

    local function processMapObject(obj)
        if not ESP_Active or ESP_Generation ~= myGen then return end
        if obj.ClassName == "Model" then
            if not ESP_Objects[obj] then
                local lower = obj.Name:lower()
                if lower:find("generator",1,true) then
                    addObjectESP(obj, ESP_Settings.GeneratorColor, false)
                    if not GeneratorTexts[obj] then
                        local ok, txt = pcall(function() return Drawing.new("Text") end)
                        if ok and txt then
                            txt.Size = 20; txt.Center = true; txt.Outline = true; txt.Font = 3
                            txt.Color = ESP_Settings.TextColor; txt.Text = "0%"; txt.Visible = false
                            GeneratorTexts[obj] = txt
                            table.insert(ESP_Drawings, txt)
                            GeneratorData[obj] = { center = getGeneratorCenter(obj), nextUpdate = 0 }
                        end
                    end
                elseif lower:find("zombie",1,true) or lower:find("scp",1,true) or lower:find("minion",1,true) or lower:find("cure",1,true) then
                    if obj:FindFirstChildOfClass("Humanoid") then
                        ESP_Objects[obj] = { Highlight = createHighlight(obj, ESP_Settings.ZombieColor) }
                    end
                elseif lower:find("bear trap",1,true) or lower:find("beartrap",1,true) or lower:find("butcher trap",1,true) then
                    addObjectESP(obj, ESP_Settings.TrapColor, false)
                elseif lower:find("pallet",1,true) and not lower:find("crate",1,true) then
                    addObjectESP(obj, ESP_Settings.PalletColor, false)
                elseif lower:find("window",1,true) then
                    local hasTrigger = obj:FindFirstChild("VaultTrigger", true) ~= nil
                    local hasPrompt = false
                    for _, d in ipairs(obj:GetDescendants()) do
                        if d:IsA("ProximityPrompt") then hasPrompt = true; break end
                    end
                    if hasTrigger or hasPrompt then
                        for _, part in ipairs(obj:GetDescendants()) do
                            applyVaultBox(part)
                        end
                    end
                end
            end
        elseif obj.ClassName == "Part" then
            if not ESP_Objects[obj] then
                local lower = obj.Name:lower()
                if lower:find("bear trap",1,true) or lower:find("beartrap",1,true) or lower:find("butcher trap",1,true) then
                    addObjectESP(obj, ESP_Settings.TrapColor, false)
                elseif obj.Name == "VaultTrigger" and obj.Parent and obj.Parent:IsA("Model") then
                    for _, p in ipairs(obj.Parent:GetDescendants()) do
                        applyVaultBox(p)
                    end
                end
            end
        end
    end

    local mapFolder = Workspace:FindFirstChild("Map") or Workspace

    table.insert(ESP_Connections, mapFolder.DescendantAdded:Connect(function(obj)
        if not ESP_Active or ESP_Generation ~= myGen then return end
        if obj:IsA("Model") or obj:IsA("BasePart") then
            processMapObject(obj)
        end
    end))

    table.insert(ESP_Connections, mapFolder.DescendantRemoving:Connect(function(obj)
        local data = ESP_Objects[obj]
        if data then
            if data.Highlight then destroyHighlight(data.Highlight) end
            if data.Box then pcall(function() data.Box:Destroy() end) end
            ESP_Objects[obj] = nil
        end
        local txt = GeneratorTexts[obj]
        if txt then
            destroyDrawing(txt)
            GeneratorTexts[obj] = nil
            GeneratorData[obj] = nil
        end
    end))

    local scanCount = 0
    for _, obj in ipairs(mapFolder:GetDescendants()) do
        if not ESP_Active or ESP_Generation ~= myGen then return end
        if obj:IsA("Model") or obj:IsA("BasePart") then
            processMapObject(obj)
            scanCount = scanCount + 1
            if scanCount % 200 == 0 then
                task.wait()
                if not ESP_Active or ESP_Generation ~= myGen then return end
            end
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            trackPlayerCharacter(player)
            if player.Character and not ESP_Objects[player.Character] then
                addPlayerESP(player)
            end
        end
    end

    table.insert(ESP_Connections, Players.PlayerAdded:Connect(function(player)
        if not ESP_Active or ESP_Generation ~= myGen then return end
        trackPlayerCharacter(player)
    end))

    table.insert(ESP_Connections, Players.PlayerRemoving:Connect(function(player)
        if PlayerCharacterConns[player] then
            if PlayerCharacterConns[player].Added    then pcall(function() PlayerCharacterConns[player].Added:Disconnect() end) end
            if PlayerCharacterConns[player].Removing then pcall(function() PlayerCharacterConns[player].Removing:Disconnect() end) end
            PlayerCharacterConns[player] = nil
        end
        if player.Character and ESP_Objects[player.Character] then
            local data = ESP_Objects[player.Character]
            if data.Highlight then destroyHighlight(data.Highlight) end
            if data.Box then pcall(function() data.Box:Destroy() end) end
            ESP_Objects[player.Character] = nil
        end
        PlayerRoleCache[player] = nil
    end))

    table.insert(ESP_Connections, RunService.RenderStepped:Connect(function(dt)
        if not ESP_Active or ESP_Generation ~= myGen then return end
        local cam = Workspace.CurrentCamera
        if not cam then return end
        local camPos = cam.CFrame.Position
        local now = os.clock()

        for gen, txt in pairs(GeneratorTexts) do
            if gen and gen.Parent then
                local gd = GeneratorData[gen]
                if not gd then continue end
                local dx, dy, dz = camPos.X - gd.center.X, camPos.Y - gd.center.Y, camPos.Z - gd.center.Z
                if (dx*dx + dy*dy + dz*dz) > RENDER_DIST_SQ then
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
                            if ed and ed.Highlight then
                                ed.Highlight.FillColor = ESP_Settings.DoneColor
                                ed.Highlight.OutlineColor = ESP_Settings.DoneColor
                            end
                        else
                            txt.Text = prog .. "%"; txt.Color = ESP_Settings.TextColor
                            if ed and ed.Highlight then
                                ed.Highlight.FillColor = ESP_Settings.GeneratorColor
                                ed.Highlight.OutlineColor = ESP_Settings.GeneratorColor
                            end
                        end
                    end
                else
                    txt.Visible = false
                end
            end
        end
    end))

    task.spawn(function()
        while ESP_Active and ESP_Generation == myGen do
            task.wait(2)
            if not ESP_Active or ESP_Generation ~= myGen then break end
            local now = os.clock()

            for obj, data in pairs(ESP_Objects) do
                if data.Player then
                    local p = data.Player
                    if not p.Parent or p.Character ~= obj then
                        if data.Highlight then destroyHighlight(data.Highlight) end
                        if data.Box then pcall(function() data.Box:Destroy() end) end
                        ESP_Objects[obj] = nil
                    end
                end
            end

            for gen, gd in pairs(GeneratorData) do
                if gen and gen.Parent then
                    gd.center = getGeneratorCenter(gen)
                end
            end

            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    trackPlayerCharacter(player)
                    if player.Character then
                        if not ESP_Objects[player.Character] then
                            addPlayerESP(player)
                        else
                            local cache = PlayerRoleCache[player]
                            if not cache or now - cache.t >= 2 then
                                local role = detectRole(player)
                                PlayerRoleCache[player] = { role = role, t = now }
                                local color = roleToColor(role)
                                local data = ESP_Objects[player.Character]
                                if data and data.Highlight and data.Highlight.FillColor ~= color then
                                    data.Highlight.FillColor = color
                                    data.Highlight.OutlineColor = color
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    ShowNotification("ESP", "ESP Enabled")
end

EspToggleBtn.MouseButton1Click:Connect(function()
    if not ESP_Active then
        EspSwitchBg.BackgroundColor3 = COLOR_ON
        EspSwitchKnob.Position = POS_ON
        StartESP()
    else
        EspSwitchBg.BackgroundColor3 = COLOR_OFF
        EspSwitchKnob.Position = POS_OFF
        if ClearESP then pcall(ClearESP) end
        ShowNotification("ESP", "ESP Disabled")
    end
end)

ShowNotification("Auto Skill Check", "Premium UI V5.4.1 (Hardened) Loaded. Tekan [Right ALT] untuk buka GUI.")
