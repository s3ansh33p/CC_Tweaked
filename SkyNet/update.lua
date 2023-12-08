-- delete and download the new track.lua file from psatebin and run it
-- get parameters
local tArgs = { ... }
if #tArgs ~= 1 then
    print("Usage: update <fileName>")
    return
end

-- map of files - track.lua is "KaH6ZGmw" (pastebin)
local fileMap = {
    ["track.lua"] = "KaH6ZGmw",
    ["update.lua"] = "QRA0Xx21",
    ["diskspace.lua"] = "qVUuNHtY",
}

-- get pastebin id from map
local fileName = tArgs[1]
local pastebinId = fileMap[fileName]
if pastebinId == nil then
    print("File '" .. fileName .. "' not found in map")
    return
end

local fileUrl = "https://pastebin.com/raw/" .. pastebinId
local file = fs.open(fileName, "w")
file.write(http.get(fileUrl).readAll())
file.close()

print("Downloaded '" .. fileName .. "' from pastebin")
sleep(0.5)
-- run the new track.lua file
shell.run(fileName)
