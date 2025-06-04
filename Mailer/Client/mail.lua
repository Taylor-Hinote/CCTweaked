-- Basic Mail Client for CC: Tweaked
-- Sends and receives mail, plays sound on new mail

-- Ensure a wireless modem is present and open rednet on it
local version = "0.2.3"
local modem = peripheral.find("modem", function(_, m) return m.isWireless and m.isWireless() end)
if not modem then error("No wireless modem attached") end
rednet.open(peripheral.getName(modem))

local speaker = peripheral.find("speaker")
local SOUND_URL = "https://github.com/Taylor-Hinote/CCTweaked/raw/refs/heads/main/Mailer/Client/YouGotMail.dfpwm"
local CONFIG_FILE = "config.lua"
local LOCAL_SOUND_FILE = "YouGotMail.dfpwm"

local function downloadSoundIfNeeded()
    if not fs.exists(LOCAL_SOUND_FILE) then
        print("[MailClient] Downloading sound file...")
        local response = http.get(SOUND_URL)
        if response then
            local data = response.readAll()
            response.close()
            local f = fs.open(LOCAL_SOUND_FILE, "wb")
            f.write(data)
            f.close()
            print("[MailClient] Sound file downloaded.")
        else
            print("[MailClient] Failed to download sound file from URL!")
        end
    end
end

downloadSoundIfNeeded()

local function playMailSound()
    if speaker and fs.exists(LOCAL_SOUND_FILE) then
        local ok, err = pcall(function()
            -- Use shell.run to play the sound as the shell command works
            shell.run("speaker", "play", LOCAL_SOUND_FILE)
        end)
        if not ok then
            print("[MailClient] Error playing sound using shell: " .. tostring(err))
        end
    else
        print("[MailClient] Speaker or sound file not found!")
    end
end

local function sendMail(recipientName, message)
    -- Include sender's userName in the payload
    local senderName = userName or tostring(os.getComputerID())
    local payload = recipientName .. "|" .. senderName .. "|" .. message
    rednet.broadcast(payload)
    print("[MailClient] Sent mail to " .. recipientName)
end

local function parseMailCommand(input)
    -- Expects: mail @userName "Message Here" or soundTest
    if input == "soundTest" then
        return "__SOUNDTEST__", nil
    end
    local name, msg = input:match('^mail%s+@([%w_%-]+)%s+"([^\"]+)"%s*$')
    if name and msg then
        return name, msg
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

local messageHistory = {}
local HISTORY_LIMIT = 10

local function printHeaderAndMessages()
    term.clear()
    term.setCursorPos(1, 1)
    print("[MailClient] Client Version v" .. version)
    print("[MailClient] Your Computer ID is: " .. os.getComputerID())
    print("[MailClient] Ready. Type: mail @userName \"Message Here\" or soundTest")
    print("\n--- Recent Messages ---")
    for i = math.max(1, #messageHistory - HISTORY_LIMIT + 1), #messageHistory do
        print(messageHistory[i])
    end
    print("----------------------\n")
end

print("[MailClient] Client Version v" .. version)
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
print("[MailClient] Ready. Type: mail @userName \"Message Here\" or soundTest")

while true do
    local event, p1, p2, p3 = os.pullEvent()
    if event == "rednet_message" then
        local senderId, msg, proto = p1, p2, p3
        if proto == "mail" then
            -- Expecting: senderName|message
            local from, message = msg:match('^([%w_%-]+)%|(.*)$')
            local displayMsg
            if from and message then
                displayMsg = "[MailClient] New mail from @" .. from .. ": " .. message
            else
                displayMsg = "[MailClient] New mail: " .. msg
            end
            table.insert(messageHistory, displayMsg)
            printHeaderAndMessages()
            playMailSound()
        end
    elseif event == "char" or event == "key" then
        printHeaderAndMessages()
        write(": ")
        local input = read()
        local name, msg = parseMailCommand(input)
        if name == "__SOUNDTEST__" then
            print("[MailClient] Playing sound test...")
            playMailSound()
        elseif name and msg then
            sendMail(name, msg)
            table.insert(messageHistory, "[MailClient] Sent mail to @" .. name .. ": " .. msg)
            printHeaderAndMessages()
        elseif input ~= "" then
            table.insert(messageHistory, "[MailClient] Invalid command. Use: mail @userName \"Message Here\" or soundTest")
            printHeaderAndMessages()
        end
    end
end
