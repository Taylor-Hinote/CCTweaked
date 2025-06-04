-- Basic Mail Client for CC: Tweaked
-- Sends and receives mail, plays sound on new mail

-- Ensure a wireless modem is present and open rednet on it
local version = "0.2.1"
local modem = peripheral.find("modem", function(_, m) return m.isWireless and m.isWireless() end)
if not modem then error("No wireless modem attached") end
rednet.open(peripheral.getName(modem))

local speaker = peripheral.find("speaker")
local SOUND_URL = "https://github.com/Taylor-Hinote/CCTweaked/raw/refs/heads/main/Mailer/Client/YouGotMail.dfpwm"
local CONFIG_FILE = "config.lua"

local function playMailSound()
    if speaker then
        local ok, err = pcall(function()
            -- Download the DFPWM file and play as a table
            local response = http.get(SOUND_URL)
            if response then
                local data = response.readAll()
                response.close()
                speaker.playAudio({data})
            else
                print("[MailClient] Failed to download sound file from URL!")
            end
        end)
        if not ok then
            print("[MailClient] Error playing sound from URL: " .. tostring(err))
        end
    else
        print("[MailClient] Speaker not found!")
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
    -- Expects: mail @userName "Message Here"
    local name, msg = input:match('^mail%s+@([%w_%-]+)%s+"([^"]+)"%s*$')
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

print("[MailClient] Client Version v" .. version)
print("[MailClient] Your Computer ID is: " .. os.getComputerID())
print("[MailClient] Ready. Type: mail @ID \"Message Here\"")

while true do
    local event, p1, p2, p3 = os.pullEvent()
    if event == "rednet_message" then
        local senderId, msg, proto = p1, p2, p3
        if proto == "mail" then
            -- Expecting: senderName|message
            local from, message = msg:match('^([%w_%-]+)%|(.*)$')
            if from and message then
                print("[MailClient] New mail from @" .. from .. ": " .. message)
            else
                print("[MailClient] New mail: " .. msg)
            end
            playMailSound()
        end
    elseif event == "char" or event == "key" then
        -- Prompt for user input
        write(": ")
        local input = read()
        local name, msg = parseMailCommand(input)
        if name and msg then
            sendMail(name, msg)
        elseif input ~= "" then
            print("[MailClient] Invalid command. Use: mail @userName \"Message Here\"")
        end
    end
end
