local githubRawURL = "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/main.lua"
local fullUrl = url .. "?t=" .. os.epoch("utc")
local localFile = "main.lua"

-- Remove old version
if fs.exists(localFile) then
    fs.delete(localFile)
end

-- Attempt to download new version
local success, err = pcall(function()
    shell.run("wget", fullUrl, localFile)
end)

-- Run the new script if downloaded
if fs.exists(localFile) then
    shell.run(localFile)
else
    print("Failed to download script.")
    if err then print(err) end
end
