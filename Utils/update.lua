-- get parameters
local tArgs = { ... }
if #tArgs ~= 1 then
    print("Usage: update <fileName>")
    return
end

local fileMap = {
    ["track"] = "KaH6ZGmw",
    ["update"] = "QRA0Xx21",
    ["diskspace"] = "qVUuNHtY",
    ["s3"] = "AkgyTdY0",
    ["scan"] = "vtM0ChSt"
}

local fileName = tArgs[1]
-- check if .lua also given, if so, remove from end
if string.sub(fileName, -4) == ".lua" then
    fileName = string.sub(fileName, 1, -5)
end
local pastebinId = fileMap[fileName]
if pastebinId == nil then
    print("File '" .. fileName .. "' not found in map")
    return
end

fileName = fileName .. ".lua"

local fileUrl = "https://" .. "pastebin.com" .. "/raw/" .. pastebinId
local file = fs.open(fileName, "w")
file.write(http.get(fileUrl).readAll())
file.close()

print("Got '" .. fileName .. "'")
sleep(0.2)
shell.run(fileName)
