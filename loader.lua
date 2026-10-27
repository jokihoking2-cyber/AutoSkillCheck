--// ============================================
--// AUTO SKILL CHECK + ESP — LOADER v2
--// ============================================

local BASE_URL   = "https://raw.githubusercontent.com/jokihoking2-cyber/AutoSkillCheck/main"
local SAVE_FILE  = "AutoSkillCheck_version.txt"

--// ---------- Cache-busting token (PENTING untuk GitHub raw) ----------
local CACHE_BUST = "?cb=" .. tostring(math.floor(os.time())) .. tostring(math.random(100000, 999999))
local MAIN_URL    = BASE_URL .. "/main.lua"    .. CACHE_BUST
local VERSION_URL = BASE_URL .. "/version.txt" .. CACHE_BUST

--// ---------- Helper ----------
local function notify(title, text, dur)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text  = tostring(text),
            Duration = dur or 4,
        })
    end)
end

local function hasFileIO()
    return type(isfile) == "function"
       and type(readfile) == "function"
       and type(writefile) == "function"
end

local function sanitizeVersion(v)
    if type(v) ~= "string" then return nil end
    v = v:gsub("%s+", "")
    v = v:gsub("[^%w%.%-_]", "")
    if v == "" then return nil end
    return v:sub(1, 32)
end

-- Fetch dengan fallback ke berbagai executor API
local function fetch(url)
    -- 1) game:HttpGet
    local ok, res = pcall(function() return game:HttpGet(url, true) end)
    if ok and type(res) == "string" and #res > 0 then return res end

    -- 2) game:HttpGetAsync
    if type(game.HttpGetAsync) == "function" then
        local ok2, res2 = pcall(function() return game:HttpGetAsync(url) end)
        if ok2 and type(res2) == "string" and #res2 > 0 then return res2 end
    end

    -- 3) request / syn.request / http.request
    local req = (syn and syn.request) or (http and http.request) or request
    if type(req) == "function" then
        local ok3, r3 = pcall(req, {Url = url, Method = "GET"})
        if ok3 and r3 and type(r3.Body) == "string" and #r3.Body > 0 then
            return r3.Body
        end
    end
    return nil
end

--// ---------- Version storage ----------
local function getLocalVersion()
    if not hasFileIO() then return nil end
    if not isfile(SAVE_FILE) then return nil end
    local ok, v = pcall(readfile, SAVE_FILE)
    if ok then return sanitizeVersion(v) end
    return nil
end

local function saveLocalVersion(v)
    if not hasFileIO() then return end
    v = sanitizeVersion(v)
    if not v then return end
    pcall(writefile, SAVE_FILE, v)
end

--// ---------- Main ----------
local function main()
    -- 1) Cek versi remote (untuk notifikasi saja)
    local remoteVersion = sanitizeVersion(fetch(VERSION_URL) or "")
    local localVersion  = getLocalVersion()

    if remoteVersion and localVersion and localVersion ~= remoteVersion then
        notify("🔄 Update Tersedia",
            ("v%s → v%s. Memuat versi terbaru..."):format(localVersion, remoteVersion), 4)
    elseif remoteVersion and not localVersion then
        notify("📦 Pertama Kali", "Versi v" .. remoteVersion, 2)
    end

    -- 2) Ambil source TERBARU (dengan cache-bust)
    local source = fetch(MAIN_URL)
    if not source or #source < 100 then
        notify("❌ Loader Error", "Gagal mengunduh main.lua. Periksa koneksi / URL repo.", 6)
        return
    end

    -- 3) Compile dulu, BARU simpan versi
    local loadFn = loadstring or load
    if type(loadFn) ~= "function" then
        notify("❌ Loader Error", "Executor tidak mendukung loadstring/load.", 6)
        return
    end

    local chunk, err = loadFn(source, "=AutoSkillCheck")
    if not chunk then
        notify("❌ Compile Error", tostring(err):sub(1, 120), 6)
        warn("[AutoSkillCheck][Compile] " .. tostring(err))
        return
    end

    -- 4) Baru simpan versi setelah compile sukses
    if remoteVersion then saveLocalVersion(remoteVersion) end

    -- 5) Execute
    local ok, runtimeErr = pcall(chunk)
    if not ok then
        notify("❌ Runtime Error", tostring(runtimeErr):sub(1, 120), 6)
        warn("[AutoSkillCheck][Runtime] " .. tostring(runtimeErr))
    end
end

--// ---------- Safe entry ----------
local ok, err = pcall(main)
if not ok then
    warn("[AutoSkillCheck][Loader] " .. tostring(err))
    notify("❌ Loader Crash", tostring(err):sub(1, 120), 6)
end
