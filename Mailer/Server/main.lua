-- Basic Mail Server for CC: Tweaked
-- Listens for broadcasted mail and relays to recipient

-- Ensure a wireless modem is present and open rednet on it
local modem = peripheral.find("modem", function(_, m) return m.isWireless and m.isWireless() end)
if not modem then error("No wireless modem attached") end
rednet.open(peripheral.getName(modem))

local SOUND_FILE = "YouGotMail.dfpwm" -- Only clients need this file

local USER_DB = "user_db.lua"
local LOG_FILE = "mail_log.txt"
local version = "0.2.4"

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
term.clear()
term.setCursorPos(1, 1)
print("[MailServer] Mail Server v" .. version .. " started.")
if next(userMap) then
    local count = 0
    for _ in pairs(userMap) do count = count + 1 end
    print("[MailServer] Loaded user map with " .. count .. " registered users online.")
else
    print("[MailServer] No registered users found. Awaiting registrations...")
end
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
            term.clear()
            term.setCursorPos(1, 1)
            print("[MailServer] Mail Server v" .. version .. " started.")
            local count = 0
            for _ in pairs(userMap) do count = count + 1 end
            print("[MailServer] Loaded user map with " .. count .. " registered users online.")
            print("[MailServer] Listening for mail broadcasts...")
            print("[MailServer] " .. logMsg)
            logEvent(logMsg)
        end
    else
        -- Expecting message as: "recipientName|senderName|mailData"
        local recipientName, senderName, mailData = message:match("^([%w_%-]+)%|([%w_%-]+)%|(.*)$")
        if recipientName and senderName and mailData then
            -- Find recipient ID by name
            local recipientId = nil
            for id, name in pairs(userMap) do
                if name == recipientName then
                    recipientId = id
                    break
                end
            end
            if recipientId then
                local logMsg = "Mail for " .. recipientName .. " from " .. senderName .. ": " .. mailData
                term.clear()
                term.setCursorPos(1, 1)
                print("[MailServer] Mail Server v" .. version .. " started.")
                local count = 0
                for _ in pairs(userMap) do count = count + 1 end
                print("[MailServer] Loaded user map with " .. count .. " registered users online.")
                print("[MailServer] Listening for mail broadcasts...")
                print("[MailServer] " .. logMsg)
                logEvent(logMsg)
                -- Relay mail to recipient, include senderName in message
                rednet.send(recipientId, senderName .. "|" .. mailData, "mail")
            else
                local logMsg = "Mail for unknown user '" .. recipientName .. "' from " .. (userMap[senderId] or senderId)
                print("[MailServer] " .. logMsg)
                logEvent(logMsg)
            end
        else
            local logMsg = "Malformed mail message from " .. senderId
            print("[MailServer] " .. logMsg)
            logEvent(logMsg)
        end
    end
end