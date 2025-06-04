local urlConfigFile = "bootloader.lua"
local localFile = "main.lua"

local githubRawURL = nil
if fs.exists(urlConfigFile) then
    local f = fs.open(urlConfigFile, "r")
    githubRawURL = f.readLine()
    f.close()
end

if not githubRawURL or githubRawURL == "" then
    print("[Bootloader] Please 'edit bootloader.lua' and insert the raw URL on the first line.")
    return
end

-- Remove old version
if fs.exists(localFile) then
    fs.delete(localFile)
end

-- Attempt to download new version
local success, err = pcall(function()
    shell.run("wget", githubRawURL, localFile)
end)

-- Run the new script if downloaded
if fs.exists(localFile) then
    shell.run(localFile)
else
    print("Failed to download script.")
    if err then print(err) end
end

term.clear()
term.setCursorPos(1, 1)
