-- Music Player for CC: Tweaked
-- Plays audio files on an attached speaker peripheral

local speaker = peripheral.find("speaker")
if not speaker then
    error("No speaker attached!")
end

print("[MusicPlayer] Enter the filename of the audio file to play (e.g. song.dfpwm):")
write(": ")
local filename = read()

if not fs.exists(filename) then
    print("[MusicPlayer] File not found: " .. filename)
    return
end

print("[MusicPlayer] Playing: " .. filename)
shell.run("speaker", "play", filename)
print("[MusicPlayer] Done.")
