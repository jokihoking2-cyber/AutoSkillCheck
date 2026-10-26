--// ============================================
--// AUTO SKILL CHECK + ESP — LOADER
--// ============================================

local BASE_URL   = "https://raw.githubusercontent.com/jokihoking2-cyber/AutoSkillCheck/main"
local MAIN_URL   = BASE_URL .. "/main.lua"
local VERSION_URL= BASE_URL .. "/version.txt"
local SAVE_FILE  = "AutoSkillCheck_version.txt"

--// ---------- Helper ----------
local function notify(title, text, dur)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text  = text,
            Duration = dur or 4,
        })
    end)
end

local function fetch(url)
    local ok, res = pcall(function() return game:HttpGet(url, true) end)
    if ok and type(res) == "string" and #res > 0 then
        return res
    end
    return nil
end

--// ---------- Version check ----------
local function getLocalVersion()
    if isfile and isfile(SAVE_FILE) then
        local ok, v = pcall(readfile, SAVE_FILE)
        if ok then return (v:gsub("%s+", "")) end
    end
    return nil
end

local function saveLocalVersion(v)
    pcall(function()
        if writefile then writefile(SAVE_FILE, v) end
    end)
end

--// ---------- Loader ----------
local function main()
    -- 1. Ambil source script utama
    local source = fetch(MAIN_URL)
    if not source then
        notify("❌ Loader Error", "Gagal mengunduh main.lua", 6)
        return
    end

    -- 2. Cek versi terbaru
    local remoteVersion = fetch(VERSION_URL)
    if remoteVersion then
        remoteVersion = remoteVersion:gsub("%s+", "")
        local localVersion = getLocalVersion()

        if localVersion and localVersion ~= remoteVersion then
            notify(
                "🔄 Update Tersedia",
                ("v%s → v%s. Script akan dimuat ulang."):format(localVersion, remoteVersion),
                5
            )
        elseif not localVersion then
            notify("📦 Pertama Kali", "Menyimpan versi v" .. remoteVersion, 3)
        end
        saveLocalVersion(remoteVersion)
    end

    -- 3. Compile & jalankan
    local chunk, err = loadstring(source, "=AutoSkillCheck")
    if not chunk then
        notify("❌ Compile Error", tostring(err), 6)
        return
    end

    local ok, runtimeErr = pcall(chunk)
    if not ok then
        notify("❌ Runtime Error", tostring(runtimeErr):sub(1, 120), 6)
        warn("[AutoSkillCheck] " .. tostring(runtimeErr))
    end
end

main()
