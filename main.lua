-- ============================================
-- AUTO SKILL CHECK + ESP (PREMIUM GLASS EDITION V5.7.2 - ANIMATED & WARNING-FREE)
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

local LocalPlayer          = Players.LocalPlayer
local PlayerGui            = LocalPlayer:WaitForChild("PlayerGui")
local IsUnloaded           = false

local function SafeCall(tag, fn)
    local ok, result = xpcall(fn, function(err)
        return tostring(err) .. "\n" .. debug.traceback()
    end)
    if not ok then warn("[VD V5.7][" .. tostring(tag) .. "] " .. tostring(result)) end
    return ok, result
end

-- ==========================================
-- 🔐 CAPABILITY CHECK (STARTUP)
-- ==========================================
local Capabilities = { FileIO = false, Drawing = false }

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
    if name == "" or name:lower() == "autoload" or name == "None" then return nil end
    return name
end

local MODES = { "Legit", "Normal", "Random" }
local VALID_MODES = {}
for _, m in ipairs(MODES) do VALID_MODES[m] = true end

local SKILL_WINDOWS = {
    Legit  = { start = 106, stop = 112 },
    Normal = { start = 120, stop = 125 },
}

local CONFIG_VERSION = 2

local function ValidateConfigData(data)
    if type(data) ~= "table" then return nil end
    local version = data.Version
    if version ~= nil and (type(version) ~= "number" or version > CONFIG_VERSION) then
        return nil
    end
    local out = {}
    local hasAny = false
    if type(data.Mode) == "string" and VALID_MODES[data.Mode] then
        out.Mode = data.Mode; hasAny = true
    end
    if type(data.AutoSkill) == "boolean" then out.AutoSkill = data.AutoSkill; hasAny = true end
    if type(data.ESP) == "boolean"       then out.ESP = data.ESP;             hasAny = true end
    if not hasAny then return nil end
    return out
end

local function SafeReadFile(path, maxBytes)
    if not Capabilities.FileIO then return nil end
    local found, exists = pcall(isfile, path)
    if not found or not exists then return nil end
    local ok, content = pcall(readfile, path)
    if not ok or type(content) ~= "string" then return nil end
    if #content > (maxBytes or 100000) then return nil end
    return content
end

local function SafeParentGui(gui)
    if type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and hui then
            if pcall(function() gui.Parent = hui end) then return end
        end
    end
    if syn and type(syn.protect_gui) == "function" then
        pcall(syn.protect_gui, gui)
    elseif type(protect_gui) == "function" then
        pcall(protect_gui, gui)
    end
    if pcall(function() gui.Parent = CoreGui end) then return end
    gui.Parent = PlayerGui
end

local function IsPointInFrame(point, frame)
    if not frame or not frame.Parent then return false end
    local pos = frame.AbsolutePosition
    local size = frame.AbsoluteSize
    return point.X >= pos.X and point.X <= pos.X + size.X and
           point.Y >= pos.Y and point.Y <= pos.Y + size.Y
end

local function GetMouseScreenPos()
    return UserInputService:GetMouseLocation()
end

local function AngleDiff(a, b)
    local d = math.abs((a - b) % 360)
    if d > 180 then d = 360 - d end
    return d
end

-- [ANIMASI] Helper untuk menambahkan efek membesar/mengecil (UIScale)
local function AddAnimScale(gui, scale)
    local s = Instance.new("UIScale")
    s.Scale = scale or 1
    s.Parent = gui
    return s
end

-- ==========================================
-- ⚙️ VARIABEL UTAMA & CONFIG
-- ==========================================
local AutoSkillEnabled = false
local CurrentMode = "Legit"

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
local ESP_VaultBoxes = {}

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
    PalletColor    = Color3.fromRGB(255, 100, 0),
}

local RENDER_DISTANCE = 3000
local RENDER_DIST_SQ  = RENDER_DISTANCE * RENDER_DISTANCE
local GEN_PROGRESS_INTERVAL = 0.25

local MAX_HIGHLIGHTS    = 30
local MAX_VAULT_BOXES   = 50

local function ObjectPriority(obj, data)
    if data.Player then return 100 end
    local low = obj.Name:lower()
    if low:find("generator", 1, true) then return 70 end
    if low:find("trap", 1, true)      then return 60 end
    if low:find("zombie", 1, true) or low:find("scp", 1, true)
       or low:find("minion", 1, true) or low:find("cure", 1, true) then return 50 end
    if low:find("pallet", 1, true) then return 40 end
    return 30
end

-- [FIX WARNING] Forward declaration untuk fungsi yang dipanggil sebelum dideklarasikan
local ClearESP
local RefreshConfigList
local SetAutoSkill
local SetESPEnabled
local SkillCheckConnection
local UpdateAutoLoadFile

local function destroyHighlight(h)
    if not h then return end
    for i = #ESP_Highlights, 1, -1 do
        if ESP_Highlights[i] == h then table.remove(ESP_Highlights, i); break end
    end
    pcall(function() h:Destroy() end)
end

local function destroyDrawing(d)
    if not d then return end
    for i = #ESP_Drawings, 1, -1 do
        if ESP_Drawings[i] == d then table.remove(ESP_Drawings, i); break end
    end
    pcall(function() d:Remove() end)
end

local function RemoveTrackedObject(obj)
    local data = ESP_Objects[obj]
    if not data then return end
    if data.Highlight then destroyHighlight(data.Highlight) end
    if data.Box then
        local wasVault = data.Box:IsA("BoxHandleAdornment")
        if wasVault then
            for i = #ESP_VaultBoxes, 1, -1 do
                if ESP_VaultBoxes[i] == data.Box then table.remove(ESP_VaultBoxes, i); break end
            end
        end
        pcall(function() data.Box:Destroy() end)
    end
    ESP_Objects[obj] = nil
end

local function RemoveGenerator(gen)
    local txt = GeneratorTexts[gen]
    if txt then destroyDrawing(txt) end
    GeneratorTexts[gen] = nil
    GeneratorData[gen] = nil
end

local function EvictLowestHighlight(newPriority)
    if #ESP_Highlights < MAX_HIGHLIGHTS then return true end
    local lowestObj, lowestData, lowestP
    for obj, data in pairs(ESP_Objects) do
        if data.Highlight then
            local p = ObjectPriority(obj, data)
            if not lowestP or p < lowestP then
                lowestObj, lowestData, lowestP = obj, data, p
            end
        end
    end
    if not lowestData then return false end
    if newPriority <= lowestP then return false end
    destroyHighlight(lowestData.Highlight)
    lowestData.Highlight = nil
    if not lowestData.Box then
        local low = lowestObj.Name:lower()
        if not low:find("generator", 1, true) then
            ESP_Objects[lowestObj] = nil
        end
    end
    return true
end

-- ==========================================
-- 🎨 TEMA UI
-- ==========================================
local Theme = {
    BgMain    = Color3.fromRGB(18, 18, 22),
    BgSidebar = Color3.fromRGB(12, 12, 15),
    Accent    = Color3.fromRGB(100, 120, 255),
    AccentGradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 120, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 100, 255))
    }),
    Text    = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(150, 150, 160),
    ItemBg  = Color3.fromRGB(30, 30, 40),
    Red     = Color3.fromRGB(255, 60, 80)
}

local ArrowDownIcon = "rbxassetid://6031090990"
local CheckIcon     = "rbxassetid://6031091004"

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

-- ==========================================
-- 🟢 FPS OVERLAY (Draggable)
-- ==========================================
local FPS = {
    Overlay = Instance.new("Frame"),
    Text = Instance.new("TextLabel"),
    DragState = {active = false, start = nil, frameStart = nil},
    Connection = nil,
    FrameCount = 0,
    LastTime = os.clock()
}

FPS.Overlay.Name = "FpsOverlay"
FPS.Overlay.Size = UDim2.new(0, 100, 0, 30)
FPS.Overlay.Position = UDim2.new(0, 20, 0, 20)
FPS.Overlay.BackgroundColor3 = Theme.BgMain
FPS.Overlay.BackgroundTransparency = 0.3
FPS.Overlay.BorderSizePixel = 0
FPS.Overlay.Active = true
FPS.Overlay.ZIndex = 99999
FPS.Overlay.Parent = MainGui
AddCorner(FPS.Overlay, UDim.new(0, 6))
AddStroke(FPS.Overlay, Theme.Accent, 1, 0.5)

FPS.Text.Size = UDim2.new(1, 0, 1, 0)
FPS.Text.BackgroundTransparency = 1
FPS.Text.Text = "FPS: 60"
FPS.Text.TextColor3 = Color3.fromRGB(0, 255, 128)
FPS.Text.Font = Enum.Font.GothamBold
FPS.Text.TextSize = 14
FPS.Text.ZIndex = 100000
FPS.Text.Parent = FPS.Overlay

FPS.Overlay.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then
        FPS.DragState.active = true
        FPS.DragState.start = input.Position
        FPS.DragState.frameStart = FPS.Overlay.Position
    end
end)

FPS.Connection = RunService.RenderStepped:Connect(function()
    FPS.FrameCount = FPS.FrameCount + 1
    local now = os.clock()
    if now - FPS.LastTime >= 0.5 then
        local fps = math.floor(FPS.FrameCount / (now - FPS.LastTime))
        FPS.Text.Text = "FPS: " .. tostring(fps)
        
        if fps >= 50 then
            FPS.Text.TextColor3 = Color3.fromRGB(0, 255, 128)
        elseif fps >= 30 then
            FPS.Text.TextColor3 = Color3.fromRGB(255, 200, 0)
        else
            FPS.Text.TextColor3 = Color3.fromRGB(255, 50, 50)
        end
        
        FPS.FrameCount = 0
        FPS.LastTime = now
    end
end)

-- ==========================================
-- 🪟 MAIN WINDOW
-- ==========================================
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 480, 0, 300)
MainFrame.Position = UDim2.new(0.5, -240, 0.5, -150)
MainFrame.BackgroundColor3 = Theme.BgMain
MainFrame.BackgroundTransparency = 0.1
MainFrame.BorderSizePixel = 0
MainFrame.Active = false
MainFrame.Draggable = false
MainFrame.ZIndex = 1
MainFrame.Parent = MainGui
AddCorner(MainFrame, UDim.new(0, 12))
AddStroke(MainFrame, Theme.Accent, 1.5, 0.6)
-- [ANIMASI] UIScale untuk animasi Pop-In Main Window
local MainScale = AddAnimScale(MainFrame, 1)

local bgGrad = Instance.new("UIGradient")
bgGrad.Color = ColorSequence.new(Color3.fromRGB(25, 25, 35), Color3.fromRGB(10, 10, 15))
bgGrad.Rotation = 45
bgGrad.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 35)
TopBar.BackgroundTransparency = 1
TopBar.Active = true
TopBar.ZIndex = 2
TopBar.Parent = MainFrame

local DragState = {active = false, start = nil, frameStart = nil}
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then
        DragState.active = true
        DragState.start = input.Position
        DragState.frameStart = MainFrame.Position
    end
end)

local UISChanged, UISEnded

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
    -- [ANIMASI] Tutup dengan efek mengecil
    local hideTween = TweenService:Create(MainScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.8})
    hideTween:Play()
    hideTween.Completed:Connect(function()
        MainFrame.Visible = false
        MainScale.Scale = 1
    end)
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
    local scale = AddAnimScale(btn, 1)

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

    -- [ANIMASI] Hover membesar
    btn.MouseEnter:Connect(function()
        TweenService:Create(scale, TweenInfo.new(0.15), {Scale = 1.05}):Play()
        if btn.BackgroundTransparency == 1 then
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ItemBg, BackgroundTransparency = 0.5}):Play()
            TweenService:Create(txt, TweenInfo.new(0.2), {TextColor3 = Theme.Text}):Play()
            TweenService:Create(icon, TweenInfo.new(0.2), {ImageColor3 = Theme.Text}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(scale, TweenInfo.new(0.15), {Scale = 1}):Play()
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
local SkillScale = AddAnimScale(SkillPage, 1)

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
    local knobScale = AddAnimScale(knob, 1)

    local btn = Instance.new("TextButton")
    btn.Selectable = false
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 7
    btn.Parent = switchBg

    -- [ANIMASI] Efek Bounce pada Knob saat diklik
    btn.MouseButton1Click:Connect(function()
        TweenService:Create(knobScale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1.2}):Play()
        task.delay(0.1, function()
            TweenService:Create(knobScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
        end)
    end)

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

local OptionsList = Instance.new("Frame")
OptionsList.Size = UDim2.new(1, 0, 0, 120)
OptionsList.Position = UDim2.new(0, 0, 0, 55)
OptionsList.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
OptionsList.BackgroundTransparency = 1 -- Mulai transparan
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

for i, mode in ipairs(MODES) do
    local btn = Instance.new("TextButton")
    btn.Selectable = false
    btn.Active = true
    btn.LayoutOrder = i
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
local EspScale = AddAnimScale(EspPage, 1)

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
local SettingScale = AddAnimScale(SettingPage, 1)

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

local ConfigOptionsFrame = Instance.new("ScrollingFrame")
ConfigOptionsFrame.Size = UDim2.new(1, 0, 0, 0)
ConfigOptionsFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
ConfigOptionsFrame.BackgroundTransparency = 0
ConfigOptionsFrame.Visible = false
ConfigOptionsFrame.Active = true
ConfigOptionsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ConfigOptionsFrame.CanvasSize = UDim2.fromOffset(0, 0)
ConfigOptionsFrame.ScrollBarThickness = 3
ConfigOptionsFrame.ScrollBarImageColor3 = Theme.Accent
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
local SaveRow    = CreateSettingRow(4, "Save Config")
local LoadRow    = CreateSettingRow(5, "Load Config")
local RemoveRow  = CreateSettingRow(6, "Remove Config")

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
local AutoLoadKnobScale = AddAnimScale(AutoLoadKnob, 1)

local AUTOLOAD_POS_ON  = UDim2.new(1, -20, 0.5, -9)
local AUTOLOAD_POS_OFF = UDim2.new(0, 2, 0.5, -9)

-- Toggle FPS Overlay di Setting
local FPS_UI = {
    Row = CreateSettingRow(8, "Show FPS Overlay"),
    SwitchBg = Instance.new("Frame"),
    Knob = Instance.new("Frame"),
    PosOn = UDim2.new(1, -20, 0.5, -9),
    PosOff = UDim2.new(0, 2, 0.5, -9)
}

FPS_UI.SwitchBg.Size = UDim2.new(0, 40, 0, 22)
FPS_UI.SwitchBg.Position = UDim2.new(1, -55, 0.5, -11)
FPS_UI.SwitchBg.BackgroundColor3 = COLOR_ON
FPS_UI.SwitchBg.ZIndex = 5
FPS_UI.SwitchBg.Parent = FPS_UI.Row
AddCorner(FPS_UI.SwitchBg, UDim.new(1, 0))

FPS_UI.Knob.Size = UDim2.new(0, 18, 0, 18)
FPS_UI.Knob.Position = FPS_UI.PosOn
FPS_UI.Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
FPS_UI.Knob.ZIndex = 6
FPS_UI.Knob.Parent = FPS_UI.SwitchBg
AddCorner(FPS_UI.Knob, UDim.new(1, 0))
local FpsKnobScale = AddAnimScale(FPS_UI.Knob, 1)

FPS_UI.Row.MouseButton1Click:Connect(function()
    FPS.Overlay.Visible = not FPS.Overlay.Visible
    local targetColor = FPS.Overlay.Visible and COLOR_ON or COLOR_OFF
    local targetPos = FPS.Overlay.Visible and FPS_UI.PosOn or FPS_UI.PosOff
    TweenService:Create(FPS_UI.SwitchBg, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
    TweenService:Create(FPS_UI.Knob, TweenInfo.new(0.2), {Position = targetPos}):Play()
    
    -- Animasi Bounce
    TweenService:Create(FpsKnobScale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1.2}):Play()
    task.delay(0.1, function()
        TweenService:Create(FpsKnobScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
    end)
end)

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
    
    -- Animasi Bounce
    TweenService:Create(AutoLoadKnobScale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1.2}):Play()
    task.delay(0.1, function()
        TweenService:Create(AutoLoadKnobScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
    end)
    
    UpdateAutoLoadFile(ActiveConfigName, AutoLoadEnabled)
end)

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
UnloadBtn.LayoutOrder = 9
UnloadBtn.Parent = SettingPage
AddCorner(UnloadBtn, UDim.new(0, 8))
AddStroke(UnloadBtn, Theme.Red, 1, 0.2)

UnloadBtn.MouseEnter:Connect(function() TweenService:Create(UnloadBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play() end)
UnloadBtn.MouseLeave:Connect(function() TweenService:Create(UnloadBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.2}):Play() end)

-- ==========================================
-- 🔄 LOGIKA CONFIG SYSTEM
-- ==========================================
local AUTOLOAD_PATH = ConfigFolder .. "/_autoload.txt"

-- [FIX WARNING] Deklarasi fungsi menggunakan assignment, bukan local function lagi
UpdateAutoLoadFile = function(configName, enabled)
    if not Capabilities.FileIO then return end
    if not enabled then
        SafeCall("Disable autoload", function()
            if isfile(AUTOLOAD_PATH) then delfile(AUTOLOAD_PATH) end
        end)
        return
    end
    configName = SanitizeConfigName(configName)
    if not configName then return end
    SafeCall("Enable autoload", function() writefile(AUTOLOAD_PATH, configName) end)
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
    local payload = {
        Version = CONFIG_VERSION,
        Mode = CurrentMode,
        AutoSkill = AutoSkillEnabled,
        ESP = ESP_Active,
    }
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
        if AutoLoadEnabled then UpdateAutoLoadFile(configName, true) end
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
        ShowNotification("Config", "Config tidak punya field valid atau versi tidak didukung.")
        return
    end
    if valid.Mode then
        CurrentMode = valid.Mode
        UpdateDropdownUI()
    end
    if valid.AutoSkill ~= nil and SetAutoSkill then SetAutoSkill(valid.AutoSkill, true) end
    if valid.ESP ~= nil and SetESPEnabled then SetESPEnabled(valid.ESP, true) end
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
                if AutoLoadEnabled then UpdateAutoLoadFile(capturedName, true) end
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

-- [ANIMASI] Transisi Tab yang mulus
local function SwitchTab(tab)
    SkillPage.Visible = (tab == "Skill")
    EspPage.Visible = (tab == "ESP")
    SettingPage.Visible = (tab == "Setting")
    ConfigOptionsFrame.Visible = false
    OptionsList.Visible = false

    local targetPage = SkillPage
    local targetScale = SkillScale
    if tab == "ESP" then targetPage = EspPage; targetScale = EspScale
    elseif tab == "Setting" then targetPage = SettingPage; targetScale = SettingScale end

    -- Animasi Fade & Pop
    targetPage.Position = UDim2.new(0, 15, 0, 0)
    targetScale.Scale = 0.95
    TweenService:Create(targetPage, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
    TweenService:Create(targetScale, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Scale = 1}):Play()

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

-- [ANIMASI] Dropdown Fade & Slide
DropdownBtn.MouseButton1Click:Connect(function()
    local isVisible = not OptionsList.Visible
    if isVisible then
        OptionsList.Visible = true
        OptionsList.BackgroundTransparency = 1
        OptionsList.Position = UDim2.new(0, 0, 0, 45)
        TweenService:Create(OptionsList, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0, Position = UDim2.new(0, 0, 0, 55)}):Play()
    else
        local hideTween = TweenService:Create(OptionsList, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 45)})
        hideTween:Play()
        hideTween.Completed:Connect(function() OptionsList.Visible = false end)
    end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    if SetAutoSkill then SetAutoSkill(not AutoSkillEnabled) end
end)

-- Drag handler (Main GUI & FPS Overlay)
UISChanged = UserInputService.InputChanged:Connect(function(input)
    if DragState.active then
        if input.UserInputType == Enum.UserInputType.MouseMovement
           or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - DragState.start
            MainFrame.Position = UDim2.new(
                DragState.frameStart.X.Scale, DragState.frameStart.X.Offset + delta.X,
                DragState.frameStart.Y.Scale, DragState.frameStart.Y.Offset + delta.Y
            )
        end
    end
    
    if FPS.DragState.active then
        if input.UserInputType == Enum.UserInputType.MouseMovement
           or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - FPS.DragState.start
            FPS.Overlay.Position = UDim2.new(
                FPS.DragState.frameStart.X.Scale, FPS.DragState.frameStart.X.Offset + delta.X,
                FPS.DragState.frameStart.Y.Scale, FPS.DragState.frameStart.Y.Offset + delta.Y
            )
        end
    end
end)

UISEnded = UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then
        DragState.active = false
        FPS.DragState.active = false
    end
end)

local UISConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.RightAlt and MainGui and not gameProcessed then
        local isHidden = not MainFrame.Visible
        MainFrame.Visible = true
        if OwnsBlur and Blur then Blur.Enabled = true end
        
        -- [ANIMASI] Pop-in / Pop-out Main Window
        if isHidden then
            MainScale.Scale = 0.8
            TweenService:Create(MainScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
        else
            local hideTween = TweenService:Create(MainScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.8})
            hideTween:Play()
            hideTween.Completed:Connect(function()
                MainFrame.Visible = false
                MainScale.Scale = 1
                if OwnsBlur and Blur then Blur.Enabled = false end
            end)
        end
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mp = GetMouseScreenPos()
        if OptionsList.Visible
           and not IsPointInFrame(mp, DropdownFrame)
           and not IsPointInFrame(mp, OptionsList) then
            task.delay(0.08, function()
                if not IsUnloaded and OptionsList and OptionsList.Parent and OptionsList.Visible then
                    OptionsList.Visible = false
                end
            end)
        end
        if ConfigOptionsFrame.Visible then
            if not IsPointInFrame(mp, SelectRow) and not IsPointInFrame(mp, ConfigOptionsFrame) then
                ConfigOptionsFrame.Visible = false
            end
        end
    end
end)

SwitchTab("Skill")

-- Startup: bersihkan autoload yatim & muat config bila ada.
task.spawn(function()
    task.wait(1)
    if IsUnloaded then return end
    RefreshConfigList()
    if not Capabilities.FileIO then return end

    local autoName = SanitizeConfigName(SafeReadFile(AUTOLOAD_PATH, 200) or "")
    if not autoName then return end

    local ok, present = pcall(isfile, ConfigFolder .. "/" .. autoName .. ".json")
    if ok and present then
        AutoLoadEnabled = true
        AutoLoadSwitchBg.BackgroundColor3 = Theme.Accent
        AutoLoadKnob.Position = AUTOLOAD_POS_ON
        ActiveConfigName = autoName
        UpdateConfigUI()
        ConfigNameBox.Text = ActiveConfigName
        LoadSelectedConfig()
    else
        pcall(function() delfile(AUTOLOAD_PATH) end)
        ShowNotification("Config", "Autoload target hilang; dinonaktifkan.")
    end
end)

-- ==========================================
-- 🧠 AUTO SKILL CHECK (STATE MACHINE)
-- ==========================================
local _pressCooldown = -1
local inputHeld = false
local SPACE_HOLD = 0.02
local SPACE_COOLDOWN = 0.08

local function PressSpace()
    local now = os.clock()
    if IsUnloaded or inputHeld or now - _pressCooldown < SPACE_COOLDOWN then return false end
    local ok, err = pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
    end)
    if not ok then
        warn("[VD V5.7][Space down] " .. tostring(err))
        return false
    end
    _pressCooldown = now
    inputHeld = true
    task.delay(SPACE_HOLD, function()
        local success, why = pcall(function()
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end)
        if not success then warn("[VD V5.7][Space up] " .. tostring(why)) end
        inputHeld = false
    end)
    return true
end

local _lastTeamCheck, _lastTeamResult = -1, false
local function IsSurvivor()
    local now = os.clock()
    if now - _lastTeamCheck < 0.5 then return _lastTeamResult end
    _lastTeamCheck = now
    local team = LocalPlayer.Team
    local teamName = team and team.Name:lower() or ""
    local role = LocalPlayer:GetAttribute("Role") or LocalPlayer:GetAttribute("Team")
    local roleName = role and tostring(role):lower() or ""
    _lastTeamResult = (teamName:find("survivor", 1, true) ~= nil)
        or (roleName:find("surv", 1, true) ~= nil)
        or (roleName:find("innoc", 1, true) ~= nil)
        or (roleName:find("runner", 1, true) ~= nil)
    return _lastTeamResult
end

local PromptCache = {Gui = nil, Installed = false, Conns = {}}

local function InstallPromptCache()
    if PromptCache.Installed then return end
    PromptCache.Installed = true
    PromptCache.Gui = PlayerGui:FindFirstChild("SkillCheckPromptGui")
    table.insert(PromptCache.Conns, PlayerGui.ChildAdded:Connect(function(c)
        if c.Name == "SkillCheckPromptGui" then PromptCache.Gui = c end
    end))
    table.insert(PromptCache.Conns, PlayerGui.ChildRemoved:Connect(function(c)
        if c == PromptCache.Gui then PromptCache.Gui = nil end
    end))
end

local lastCheck = nil
local hasPressed = false
local lastGoalRotation = -999
local lastActiveGoal = nil
local cachedWindow = SKILL_WINDOWS.Legit
local cachedLine, cachedGoal, cachedTrapPerfect, cachedTrapGoal

local function ResetSkillCycle()
    hasPressed = false
    lastGoalRotation = -999
    lastActiveGoal = nil
end

local function ResetSkillState()
    lastCheck = nil
    cachedLine, cachedGoal, cachedTrapPerfect, cachedTrapGoal = nil, nil, nil, nil
    ResetSkillCycle()
end

local function PickWindowForCycle()
    if CurrentMode == "Random" then
        cachedWindow = (math.random(1, 100) <= 40) and SKILL_WINDOWS.Legit or SKILL_WINDOWS.Normal
    elseif CurrentMode == "Normal" then
        cachedWindow = SKILL_WINDOWS.Normal
    else
        cachedWindow = SKILL_WINDOWS.Legit
    end
end

local function OnSkillCheckFrame()
    if IsUnloaded or not AutoSkillEnabled or not IsSurvivor() then
        ResetSkillState()
        return
    end

    local prompt = PromptCache.Gui
    if prompt and not prompt.Parent then
        PromptCache.Gui = nil
        prompt = nil
    end
    if not prompt then
        if not PromptCache.Installed then InstallPromptCache() end
        ResetSkillState()
        return
    end
    if prompt:IsA("ScreenGui") and not prompt.Enabled then
        ResetSkillState()
        return
    end

    local check = prompt:FindFirstChild("Check")
    if not check or not check:IsA("GuiObject") or not check.Visible then
        ResetSkillState()
        return
    end

    if lastCheck ~= check then
        lastCheck = check
        ResetSkillCycle()
        PickWindowForCycle()
        cachedLine, cachedGoal, cachedTrapPerfect, cachedTrapGoal = nil, nil, nil, nil
    end

    if not cachedLine or cachedLine.Parent ~= check then cachedLine = check:FindFirstChild("Line") end
    if not cachedGoal or cachedGoal.Parent ~= check then cachedGoal = check:FindFirstChild("Goal") end
    if not cachedTrapPerfect or cachedTrapPerfect.Parent ~= check then
        cachedTrapPerfect = check:FindFirstChild("TrapPerfect")
    end
    if not cachedTrapGoal or cachedTrapGoal.Parent ~= check then
        cachedTrapGoal = check:FindFirstChild("TrapGoal")
    end
    if not cachedLine or not cachedLine:IsA("GuiObject") then return end

    local activeGoal = cachedGoal
    if cachedTrapPerfect and cachedTrapPerfect:IsA("GuiObject") and cachedTrapPerfect.Visible then
        activeGoal = cachedTrapPerfect
    elseif cachedTrapGoal and cachedTrapGoal:IsA("GuiObject") and cachedTrapGoal.Visible then
        activeGoal = cachedTrapGoal
    end
    if not activeGoal or not activeGoal:IsA("GuiObject") then return end

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

    local window = cachedWindow or SKILL_WINDOWS.Legit
    local startAngle = (gr + window.start) % 360
    local stopAngle  = (gr + window.stop) % 360
    local hit
    if startAngle > stopAngle then
        hit = (lr >= startAngle or lr <= stopAngle)
    else
        hit = (lr >= startAngle and lr <= stopAngle)
    end
    if hit and not hasPressed and PressSpace() then
        hasPressed = true
    end
end

SetAutoSkill = function(enabled, silent)
    if IsUnloaded then return end
    enabled = not not enabled
    if enabled ~= AutoSkillEnabled then
        AutoSkillEnabled = enabled
        if enabled then
            if not SkillCheckConnection then
                SkillCheckConnection = RunService.RenderStepped:Connect(OnSkillCheckFrame)
            end
        else
            if SkillCheckConnection then
                SkillCheckConnection:Disconnect()
                SkillCheckConnection = nil
            end
            ResetSkillState()
        end
    end
    SwitchBg.BackgroundColor3 = enabled and COLOR_ON or COLOR_OFF
    SwitchKnob.Position = enabled and POS_ON or POS_OFF
    if not silent then
        ShowNotification("Auto Skill Check", enabled and "Enabled" or "Disabled")
    end
end

-- ==========================================
-- 🧹 UNLOAD
-- ==========================================
local function UnloadAll()
    if IsUnloaded then return end
    IsUnloaded = true
    AutoSkillEnabled = false

    if SkillCheckConnection then
        pcall(function() SkillCheckConnection:Disconnect() end)
        SkillCheckConnection = nil
    end
    if FPS.Connection then
        pcall(function() FPS.Connection:Disconnect() end)
        FPS.Connection = nil
    end
    if UISConnection then pcall(function() UISConnection:Disconnect() end); UISConnection = nil end
    if UISChanged    then pcall(function() UISChanged:Disconnect() end);    UISChanged = nil end
    if UISEnded      then pcall(function() UISEnded:Disconnect() end);      UISEnded = nil end

    for _, conn in ipairs(PromptCache.Conns) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(PromptCache.Conns)

    if ClearESP then SafeCall("ClearESP on unload", ClearESP) end
    if inputHeld then
        pcall(function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end)
        inputHeld = false
    end
    if _G.__VD_Unload == UnloadAll then _G.__VD_Unload = nil end
    if OwnsBlur and Blur and Blur.Parent then
        pcall(function() Blur:Destroy() end)
    end
    if MainGui and MainGui.Parent then
        pcall(function() MainGui:Destroy() end)
    end
end

_G.__VD_Unload = UnloadAll

MainGui.Destroying:Connect(function() UnloadAll() end)

UnloadBtn.MouseButton1Click:Connect(function()
    ShowNotification("Auto Skill Check", "Script berhasil di-Unload.")
    UnloadAll()
end)

-- ==========================================
-- 👁️ ESP: INDEPENDENT DRAWING / MAP LIFECYCLE
-- ==========================================
local MapConnections = {}
local CurrentMapRoot = nil
local MapGeneration = 0

local MAP_NAMES = { "Map", "Game", "World", "MapFolder" }

local function FindMapRoot()
    for _, n in ipairs(MAP_NAMES) do
        local found = Workspace:FindFirstChild(n)
        if found then return found end
    end
    return nil
end

local function DisconnectList(list)
    for _, conn in ipairs(list) do pcall(function() conn:Disconnect() end) end
    table.clear(list)
end

local function ClearMapESP()
    MapGeneration = MapGeneration + 1
    DisconnectList(MapConnections)
    CurrentMapRoot = nil

    local tracked = {}
    for obj, data in pairs(ESP_Objects) do
        if data.IsMap then table.insert(tracked, obj) end
    end
    for _, obj in ipairs(tracked) do RemoveTrackedObject(obj) end

    local generators = {}
    for gen in pairs(GeneratorData) do table.insert(generators, gen) end
    for _, gen in ipairs(generators) do RemoveGenerator(gen) end
end

ClearESP = function()
    ESP_Generation = ESP_Generation + 1
    ESP_Active = false
    ClearMapESP()
    DisconnectList(ESP_Connections)

    for _, conns in pairs(PlayerCharacterConns) do
        if conns.Added   then pcall(function() conns.Added:Disconnect() end)   end
        if conns.Removing then pcall(function() conns.Removing:Disconnect() end) end
    end
    table.clear(PlayerCharacterConns)

    local tracked = {}
    for obj in pairs(ESP_Objects) do table.insert(tracked, obj) end
    for _, obj in ipairs(tracked) do RemoveTrackedObject(obj) end

    for _, d in ipairs(ESP_Drawings) do pcall(function() d:Remove() end) end
    table.clear(ESP_Drawings)
    for _, h in ipairs(ESP_Highlights) do pcall(function() h:Destroy() end) end
    table.clear(ESP_Highlights)
    for _, b in ipairs(ESP_VaultBoxes) do pcall(function() b:Destroy() end) end
    table.clear(ESP_VaultBoxes)

    table.clear(GeneratorTexts)
    table.clear(GeneratorData)
    table.clear(PlayerRoleCache)
end

local function CreateHighlight(target, color, mapObject, priority)
    if not target or not target.Parent then return nil end
    priority = priority or (mapObject and 40 or 100)

    if #ESP_Highlights >= MAX_HIGHLIGHTS then
        if not EvictLowestHighlight(priority) then return nil end
    end

    local h = Instance.new("Highlight")
    local ok, message = pcall(function()
        h.Name = "VD_ESP_Highlight"
        h.Adornee = target
        h.FillColor = color
        h.OutlineColor = color
        h.FillTransparency = 0.9
        h.OutlineTransparency = 0
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = target
    end)
    if not ok then
        pcall(function() h:Destroy() end)
        warn("[VD V5.7][Highlight] " .. tostring(message))
        return nil
    end
    table.insert(ESP_Highlights, h)
    return h
end

local function BestVisiblePart(model, ignoreHuge)
    if model.PrimaryPart and model.PrimaryPart.Parent
       and model.PrimaryPart.Transparency < 1
       and (not ignoreHuge or model.PrimaryPart.Size.Magnitude <= 100) then
        return model.PrimaryPart
    end
    local best, largest = nil, 0
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") and part.Transparency < 1
           and (not ignoreHuge or part.Size.Magnitude <= 100) then
            local size = part.Size
            local volume = size.X * size.Y * size.Z
            if volume > largest then best, largest = part, volume end
        end
    end
    return best
end

local function AddObjectESP(obj, color, priority)
    if not obj or not obj.Parent or ESP_Objects[obj] then return end
    local target = obj
    if obj:IsA("Model") then target = BestVisiblePart(obj, true) end
    if not target or not target:IsA("BasePart") then return end
    local h = CreateHighlight(target, color, true, priority)
    if h then ESP_Objects[obj] = {Highlight = h, IsMap = true} end
end

local function DetectRole(player)
    local team = player.Team
    local raw = (team and team.Name or "") .. " "
        .. tostring(player:GetAttribute("Role") or "") .. " "
        .. tostring(player:GetAttribute("Team") or "")
    local s = raw:lower()
    if s:find("killer", 1, true) or s:find("murder", 1, true)
       or s:find("butcher", 1, true) or s:find("slasher", 1, true) then return "killer" end
    if s:find("surviv", 1, true) or s:find("innoc", 1, true)
       or s:find("runner", 1, true) then return "survivor" end
    return "unknown"
end

local function RoleColor(role)
    if role == "killer"   then return ESP_Settings.KillerColor end
    if role == "survivor" then return ESP_Settings.SurvivorColor end
    return ESP_Settings.PlayerColor
end

local function AddPlayerESP(player)
    if player == LocalPlayer or not player.Parent then return end
    local char = player.Character
    if not char or not char.Parent or ESP_Objects[char] then return end
    local role = DetectRole(player)
    local h = CreateHighlight(char, RoleColor(role), false, 100)
    if not h then return end
    ESP_Objects[char] = {Highlight = h, Player = player, IsMap = false}
    PlayerRoleCache[player] = {role = role, t = os.clock()}
end

local function TrackPlayer(player, token)
    if player == LocalPlayer or PlayerCharacterConns[player] then return end
    local conns = {}
    conns.Added = player.CharacterAdded:Connect(function(char)
        task.delay(0.15, function()
            if ESP_Active and ESP_Generation == token and player.Character == char then
                AddPlayerESP(player)
            end
        end)
    end)
    conns.Removing = player.CharacterRemoving:Connect(function(char)
        RemoveTrackedObject(char)
    end)
    PlayerCharacterConns[player] = conns
    AddPlayerESP(player)
end

local function GeneratorCenter(gen)
    if gen.PrimaryPart and gen.PrimaryPart.Parent then return gen.PrimaryPart.Position end
    local part = BestVisiblePart(gen, false)
    if part then return part.Position end
    local ok, pivot = pcall(function() return gen:GetPivot() end)
    return ok and pivot.Position or nil
end

local function GeneratorProgress(gen)
    for _, attribute in ipairs({"Progress", "Percent", "RepairProgress", "Completion", "Value"}) do
        local value = gen:GetAttribute(attribute)
        if type(value) == "number" and value == value then
            local pct = (value >= 0 and value <= 1) and value * 100 or value
            return math.clamp(math.floor(pct), 0, 100)
        end
    end
    return 0
end

local function AddGeneratorText(gen)
    local data = GeneratorData[gen]
    if not data then
        local center = GeneratorCenter(gen)
        if not center then return end
        data = {center = center, nextUpdate = 0}
        GeneratorData[gen] = data
    end
    if not Capabilities.Drawing or GeneratorTexts[gen] then return end
    local okNew, txt = pcall(function() return Drawing.new("Text") end)
    if not okNew or not txt then
        warn("[VD V5.7][Drawing] " .. tostring(txt))
        return
    end
    local okSetup, message = pcall(function()
        txt.Size = 20
        txt.Center = true
        txt.Outline = true
        txt.Font = 3
        txt.Color = ESP_Settings.TextColor
        txt.Text = "0%"
        txt.Visible = false
    end)
    if not okSetup then
        pcall(function() txt:Remove() end)
        warn("[VD V5.7][Drawing setup] " .. tostring(message))
        return
    end
    GeneratorTexts[gen] = txt
    table.insert(ESP_Drawings, txt)
end

local function ApplyVaultBox(part)
    if not part or not part:IsA("BasePart") or ESP_Objects[part] then return end
    local low = part.Name:lower()
    if low == "vaulttrigger" or low:find("inviswall", 1, true) then return end
    if part.Size.Magnitude > 100 then return end
    if #ESP_VaultBoxes >= MAX_VAULT_BOXES then return end
    local ok, box = pcall(function()
        local b = Instance.new("BoxHandleAdornment")
        b.Name = "VD_ESP_VaultBox"
        b.Adornee = part
        b.AlwaysOnTop = true
        b.ZIndex = 5
        b.Size = part.Size
        b.Color3 = ESP_Settings.WindowColor
        b.Transparency = 0.8
        b.Parent = PlayerGui
        return b
    end)
    if ok then
        ESP_Objects[part] = {Box = box, IsMap = true}
        table.insert(ESP_VaultBoxes, box)
    else
        warn("[VD V5.7][Vault] " .. tostring(box))
    end
end

local function ProcessMapObject(obj)
    if not ESP_Active or not obj or not obj.Parent then return end
    if obj:IsA("Model") then
        local low = obj.Name:lower()
        if low:find("generator", 1, true) then
            AddObjectESP(obj, ESP_Settings.GeneratorColor, 70)
            AddGeneratorText(obj)
        elseif low:find("zombie", 1, true) or low:find("scp", 1, true)
            or low:find("minion", 1, true) or low:find("cure", 1, true) then
            if obj:FindFirstChildOfClass("Humanoid") and not ESP_Objects[obj] then
                local h = CreateHighlight(obj, ESP_Settings.ZombieColor, true, 50)
                if h then ESP_Objects[obj] = {Highlight = h, IsMap = true} end
            end
        elseif low:find("bear trap", 1, true) or low:find("beartrap", 1, true)
            or low:find("butcher trap", 1, true) then
            AddObjectESP(obj, ESP_Settings.TrapColor, 60)
        elseif low:find("pallet", 1, true) and not low:find("crate", 1, true) then
            AddObjectESP(obj, ESP_Settings.PalletColor, 40)
        elseif low:find("window", 1, true) then
            local hasTrigger = obj:FindFirstChild("VaultTrigger", true) ~= nil
            local hasPrompt  = obj:FindFirstChildWhichIsA("ProximityPrompt", true) ~= nil
            if hasTrigger or hasPrompt then
                for _, part in ipairs(obj:GetDescendants()) do ApplyVaultBox(part) end
            end
        end
    elseif obj:IsA("BasePart") then
        local low = obj.Name:lower()
        if low:find("bear trap", 1, true) or low:find("beartrap", 1, true)
           or low:find("butcher trap", 1, true) then
            AddObjectESP(obj, ESP_Settings.TrapColor, 60)
        elseif low == "vaulttrigger" and obj.Parent and obj.Parent:IsA("Model") then
            for _, part in ipairs(obj.Parent:GetDescendants()) do ApplyVaultBox(part) end
        end
    end
end

local function BindMap(root, token)
    if not ESP_Active or ESP_Generation ~= token then return end
    if root == CurrentMapRoot then return end
    ClearMapESP()
    CurrentMapRoot = root
    local revision = MapGeneration

    local function added(obj)
        if not ESP_Active or ESP_Generation ~= token or revision ~= MapGeneration then return end
        ProcessMapObject(obj)
        if obj:IsA("BasePart") or obj:IsA("ProximityPrompt") or obj:IsA("Humanoid") then
            local ancestor = obj.Parent
            for _ = 1, 3 do
                if not ancestor or ancestor == root then break end
                if ancestor:IsA("Model") then ProcessMapObject(ancestor) end
                ancestor = ancestor.Parent
            end
        end
    end

    table.insert(MapConnections, root.DescendantAdded:Connect(added))
    table.insert(MapConnections, root.DescendantRemoving:Connect(function(obj)
        RemoveTrackedObject(obj)
        RemoveGenerator(obj)
    end))

    task.spawn(function()
        local descendants = root:GetDescendants()
        for i, obj in ipairs(descendants) do
            if not ESP_Active or ESP_Generation ~= token or revision ~= MapGeneration then return end
            if obj:IsA("Model") or obj:IsA("BasePart") then ProcessMapObject(obj) end
            if i % 180 == 0 then task.wait() end
        end
    end)
end

local function StartESP()
    if IsUnloaded or ESP_Active then return end
    ESP_Active = true
    ESP_Generation = ESP_Generation + 1
    local token = ESP_Generation

    for _, player in ipairs(Players:GetPlayers()) do TrackPlayer(player, token) end
    table.insert(ESP_Connections, Players.PlayerAdded:Connect(function(player)
        if ESP_Active and ESP_Generation == token then TrackPlayer(player, token) end
    end))
    table.insert(ESP_Connections, Players.PlayerRemoving:Connect(function(player)
        local conns = PlayerCharacterConns[player]
        if conns then
            if conns.Added   then conns.Added:Disconnect()   end
            if conns.Removing then conns.Removing:Disconnect() end
            PlayerCharacterConns[player] = nil
        end
        if player.Character then RemoveTrackedObject(player.Character) end
        PlayerRoleCache[player] = nil
    end))

    local mapRoot = FindMapRoot()
    if mapRoot then
        BindMap(mapRoot, token)
    end
    table.insert(ESP_Connections, Workspace.ChildAdded:Connect(function(child)
        if not ESP_Active or ESP_Generation ~= token then return end
        if CurrentMapRoot == nil then
            for _, n in ipairs(MAP_NAMES) do
                if child.Name == n then BindMap(child, token); break end
            end
        end
    end))
    table.insert(ESP_Connections, Workspace.ChildRemoved:Connect(function(child)
        if ESP_Active and ESP_Generation == token and child == CurrentMapRoot then
            CurrentMapRoot = nil
            local nextRoot = FindMapRoot()
            if nextRoot then BindMap(nextRoot, token) end
        end
    end))

    if Capabilities.Drawing then
        table.insert(ESP_Connections, RunService.RenderStepped:Connect(function()
            if not ESP_Active or ESP_Generation ~= token then return end
            local camera = Workspace.CurrentCamera
            if not camera then return end
            local eye = camera.CFrame.Position
            local now = os.clock()
            for gen, txt in pairs(GeneratorTexts) do
                local gd = GeneratorData[gen]
                if gd and gen.Parent and gd.center then
                    local diff = eye - gd.center
                    if diff:Dot(diff) <= RENDER_DIST_SQ then
                        local point, visible = camera:WorldToViewportPoint(gd.center)
                        if visible then
                            txt.Position = Vector2.new(point.X, point.Y)
                            txt.Visible = true
                            if now >= gd.nextUpdate then
                                gd.nextUpdate = now + GEN_PROGRESS_INTERVAL
                                local progress = GeneratorProgress(gen)
                                local done = progress >= 100
                                txt.Text = done and "DONE" or (tostring(progress) .. "%")
                                txt.Color = done and ESP_Settings.DoneColor or ESP_Settings.TextColor
                                local data = ESP_Objects[gen]
                                if data and data.Highlight then
                                    local color = done and ESP_Settings.DoneColor or ESP_Settings.GeneratorColor
                                    data.Highlight.FillColor = color
                                    data.Highlight.OutlineColor = color
                                end
                            end
                        else
                            txt.Visible = false
                        end
                    else
                        txt.Visible = false
                    end
                else
                    txt.Visible = false
                end
            end
        end))
    end

    task.spawn(function()
        while ESP_Active and ESP_Generation == token and not IsUnloaded do
            task.wait(1.5)
            if not ESP_Active or ESP_Generation ~= token or IsUnloaded then break end
            local now = os.clock()

            local toReprocess = {}
            for obj, data in pairs(ESP_Objects) do
                if not obj.Parent
                   or (data.Player and data.Player.Character ~= obj)
                   or (data.Highlight and not data.Highlight.Parent) then
                    local wasMap = data.IsMap
                    local hadHighlight = data.Highlight ~= nil
                    RemoveTrackedObject(obj)
                    if obj.Parent and wasMap and hadHighlight then
                        table.insert(toReprocess, obj)
                    end
                elseif data.Box and data.Box:IsA("BoxHandleAdornment") and obj:IsA("BasePart") then
                    if data.Box.Size ~= obj.Size then
                        pcall(function() data.Box.Size = obj.Size end)
                    end
                end
            end
            for _, obj in ipairs(toReprocess) do
                if ESP_Active and ESP_Generation == token then
                    ProcessMapObject(obj)
                end
            end

            for gen, gd in pairs(GeneratorData) do
                if not gen.Parent then
                    RemoveGenerator(gen)
                    RemoveTrackedObject(gen)
                else
                    gd.center = GeneratorCenter(gen) or gd.center
                    if not Capabilities.Drawing then
                        local data = ESP_Objects[gen]
                        if data and data.Highlight then
                            local color = (GeneratorProgress(gen) >= 100)
                                and ESP_Settings.DoneColor or ESP_Settings.GeneratorColor
                            data.Highlight.FillColor = color
                            data.Highlight.OutlineColor = color
                        end
                    end
                end
            end

            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    TrackPlayer(player, token)
                    if player.Character and not ESP_Objects[player.Character] then
                        AddPlayerESP(player)
                    end
                    local cached = PlayerRoleCache[player]
                    if not cached or now - cached.t >= 1.5 then
                        local role = DetectRole(player)
                        PlayerRoleCache[player] = {role = role, t = now}
                        local data = player.Character and ESP_Objects[player.Character]
                        if data and data.Highlight and (not cached or role ~= cached.role) then
                            data.Highlight.FillColor = RoleColor(role)
                            data.Highlight.OutlineColor = RoleColor(role)
                        end
                    end
                end
            end
        end
    end)
end

SetESPEnabled = function(enabled, silent)
    if IsUnloaded then return end
    if enabled and not ESP_Active then StartESP() end
    if not enabled and ESP_Active then ClearESP() end
    EspSwitchBg.BackgroundColor3 = ESP_Active and COLOR_ON or COLOR_OFF
    EspSwitchKnob.Position = ESP_Active and POS_ON or POS_OFF
    if not silent then
        if ESP_Active and not Capabilities.Drawing then
            ShowNotification("ESP", "Enabled (tanpa label Drawing: API tidak tersedia)")
        else
            ShowNotification("ESP", ESP_Active and "Enabled" or "Disabled")
        end
    end
end

EspToggleBtn.MouseButton1Click:Connect(function()
    if SetESPEnabled then SetESPEnabled(not ESP_Active) end
end)

ShowNotification("Violence District", "Premium Glass V5.7.2 Loaded. RightAlt = tampil/sembunyikan UI.")
