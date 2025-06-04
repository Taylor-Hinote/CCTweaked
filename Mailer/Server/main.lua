-- Basic Mail Server for CC: Tweaked
-- Listens for broadcasted mail and relays to recipient

-- Ensure a wireless modem is present and open rednet on it
local modem = peripheral.find("modem", function(_, m) return m.isWireless and m.isWireless() end)
if not modem then error("No wireless modem attached") end
rednet.open(peripheral.getName(modem))

local SOUND_FILE = "YouGotMail.dfpwm" -- Only clients need this file

local USER_DB = "user_db.lua"
local LOG_FILE = "mail_log.txt"

local function loadUserMap()
    if fs.exists(USER_DB) then
        local ok, data = pcall(dofile, USER_DB)
        if ok and type(data) == "table" then return data end
    end
    return {}
end

local function saveUserMap(map)
    local f = fs.open(USER_DB, "w")
    f.write("return ")
    f.write(textutils.serialize(map))
    f.close()
end

local function logEvent(text)
    local f = fs.open(LOG_FILE, fs.exists(LOG_FILE) and "a" or "w")
    f.writeLine(os.date("[%Y-%m-%d %H:%M:%S] ") .. text)
    f.close()
end

-- Ensure user_db and log files exist on server startup
if not fs.exists(USER_DB) then
    local f = fs.open(USER_DB, "w")
    f.write("return {}")
    f.close()
end
if not fs.exists(LOG_FILE) then
    local f = fs.open(LOG_FILE, "w")
    f.writeLine("[MailServer] Log initialized at " .. os.date("%Y-%m-%d %H:%M:%S"))
    f.close()
end

-- Manual user map: [ID] = "Name"
local userMap = loadUserMap()

print("[MailServer] Listening for mail broadcasts...")

while true do
    local senderId, message, protocol = rednet.receive()
    if protocol == "mail_register" then
        local id, name = message:match("^register|(%d+)|(.+)$")
        if id and name then
            id = tonumber(id)
            userMap[id] = name
            saveUserMap(userMap)
            local logMsg = "Registered " .. name .. " (ID " .. id .. ")"
            print("[MailServer] " .. logMsg)
            logEvent(logMsg)
        end
    else
        -- Expecting message as: "recipientId|mailData"
        local recipientId, mailData = message:match("^(%d+)%|(.*)$")
        if recipientId and mailData then
            recipientId = tonumber(recipientId)
            local senderName = userMap[senderId] or ("ID:" .. tostring(senderId))
            local recipientName = userMap[recipientId] or ("ID:" .. tostring(recipientId))
            local logMsg = "Mail for " .. recipientName .. " from " .. senderName .. ": " .. mailData
            print("[MailServer] " .. logMsg)
            logEvent(logMsg)
            -- Relay mail to recipient
            rednet.send(recipientId, mailData, "mail")
            -- Tell recipient to play sound (clients are responsible for having the file)
            rednet.send(recipientId, "play_sound:"..SOUND_FILE, "mail_sound")
        else
            local logMsg = "Malformed mail message from " .. senderId
            print("[MailServer] " .. logMsg)
            logEvent(logMsg)
        end
    end
end