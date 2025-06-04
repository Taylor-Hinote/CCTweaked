-- Basic Mail Client for CC: Tweaked
-- Sends and receives mail, plays sound on new mail

-- Ensure a wireless modem is present and open rednet on it
local modem = peripheral.find("modem", function(_, m) return m.isWireless and m.isWireless() end)
if not modem then error("No wireless modem attached") end
rednet.open(peripheral.getName(modem))

local speaker = peripheral.find("speaker")
local SOUND_URL = "https://github.com/Taylor-Hinote/CCTweaked/raw/refs/heads/main/MailTest/YouGotMail.dfpwm"
local CONFIG_FILE = "config.lua"

local function playMailSound()
    if speaker then
        local ok, err = pcall(function()
            speaker.playAudio(SOUND_URL)
        end)
        if not ok then
            print("[MailClient] Error playing sound from URL: " .. tostring(err))
        end
    else
        print("[MailClient] Speaker not found!")
    end
end

local function sendMail(recipientId, message)
    local myId = os.getComputerID()
    local payload = tostring(recipientId) .. "|" .. message
    rednet.broadcast(payload)
    print("[MailClient] Sent mail to " .. recipientId)
end

local function parseMailCommand(input)
    -- Expects: mail @ID "Message Here"
    local id, msg = input:match("^mail%s+@(%d+)%s+\"(.-)\"")
    if id and msg then
        return tonumber(id), msg
    end
    return nil, nil
end

local function fileExists(path)
    local f = fs.open(path, "r")
    if f then f.close() return true end
    return false
end

local function saveConfig(id, name)
    local f = fs.open(CONFIG_FILE, "w")
    f.writeLine("return { id = " .. id .. ", userName = \"" .. name .. "\" }")
    f.close()
end

local function loadConfig()
    if fileExists(CONFIG_FILE) then
        local conf = dofile(CONFIG_FILE)
        return conf.id, conf.userName
    end
    return nil, nil
end

local id, userName = loadConfig()
if not id or not userName then
    print("[MailClient] First time setup. Please enter your username:")
    write(": ")
    userName = read()
    id = os.getComputerID()
    saveConfig(id, userName)
    print("[MailClient] Registered as '" .. userName .. "' with ID " .. id)
    -- Broadcast registration to server
    rednet.broadcast("register|" .. id .. "|" .. userName, "mail_register")
else
    print("[MailClient] Loaded config: " .. userName .. " (ID " .. id .. ")")
    -- Broadcast registration to server on every startup for sync
    rednet.broadcast("register|" .. id .. "|" .. userName, "mail_register")
end

print("[MailClient] Your Computer ID is: " .. os.getComputerID())
print("[MailClient] Ready. Type: mail @ID \"Message Here\"")

while true do
    -- Non-blocking check for rednet messages
    os.queueEvent("mail_prompt")
    local event = os.pullEvent()
    if event == "rednet_message" then
        local senderId, msg, proto = os.pullEventRaw()
        if proto == "mail" then
            print("[MailClient] New mail from " .. senderId .. ": " .. msg)
        elseif proto == "mail_sound" and msg:match("^play_sound:") then
            playMailSound()
        end
    elseif event == "mail_prompt" or event == "char" or event == "key" then
        -- Prompt for user input
        write(": ")
        local input = read()
        local id, msg = parseMailCommand(input)
        if id and msg then
            sendMail(id, msg)
        elseif input ~= "" then
            print("[MailClient] Invalid command. Use: mail @ID \"Message Here\"")
        end
    end
end
