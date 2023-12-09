-- https://advancedperipherals.madefor.cc/peripherals/player_detector/#events

local detector = peripheral.find("playerDetector")

-- settings for monitor to be whtie text not gray
term.setTextColor(colors.white)
term.setBackgroundColor(colors.black)

-- create a map of players and their positions, instead of refreshing entire screen, just the lines that have changed
local playerMap = {}

-- first iteration of players
for _, player in pairs(detector.getOnlinePlayers()) do
    local pos = detector.getPlayerPos(player)
    playerMap[player] = pos
end

-- start with clear screen
term.clear()

local myPlayer = "s3nsuous"

-- function to convert YAW to direction
local function getYawDirection(yaw)
    local direction = ""
    if yaw >= -22.5 and yaw < 22.5 then
        direction = "S"
    elseif yaw >= 22.5 and yaw < 67.5 then
        direction = "SW"
    elseif yaw >= 67.5 and yaw < 112.5 then
        direction = "W"
    elseif yaw >= 112.5 and yaw < 157.5 then
        direction = "NW"
    elseif yaw >= 157.5 or yaw < -157.5 then
        direction = "N"
    elseif yaw >= -157.5 and yaw < -112.5 then
        direction = "NE"
    elseif yaw >= -112.5 and yaw < -67.5 then
        direction = "E"
    elseif yaw >= -67.5 and yaw < -22.5 then
        direction = "SE"
    else 
        direction = "?!"
    end
    return direction
end

-- function to convert relative position to direction
local function getRelativeDirection(relX, relZ)
    -- calcualte angle then pass into getYawDirection
    local angle = math.atan2(relZ, relX) * 180 / math.pi
    -- print("Angle: " .. angle)
    -- convert angle to yaw
    local yaw = angle + 90
    -- print("Yaw: " .. yaw)
    -- pass into getYawDirection
    return getYawDirection(yaw)
end

-- loop
while true do
    -- clear terminal
    -- loop through players
    -- format as following
    -- LINE 1: PLAYERNAME
    -- LINE 2: X: 123 Y: 123 Z: 123
    -- LINE 3: P: <pitch> Y: <yaw>
    -- LINE 4: [relative direction and distance from myPlayer]

    -- dont clear terminal, just clear line and rewrite with new data if changed
    for idx, player in pairs(detector.getOnlinePlayers()) do
        local pos = detector.getPlayerPos(player)
        if playerMap[player] ~= pos then

            -- clear line
            term.setCursorPos(1, idx * 4 - 3)
            term.clearLine()
            -- print new data
            print(player)
            
            term.setCursorPos(1, idx * 4 - 2)
            term.clearLine()
            -- print new data
            print("X: " .. pos.x .. " Y: " .. pos.y .. " Z: " .. pos.z)

            term.setCursorPos(1, idx * 4 - 1)
            term.clearLine()
            -- translate the YAW to direction
            local direction = getYawDirection(pos.yaw)
            print("D: " .. direction .. " P: " .. math.floor(pos.pitch * 100) / 100 .. " Y: " .. math.floor(pos.yaw * 100) / 100)

            term.setCursorPos(1, idx * 4)
            term.clearLine()
            -- print new data
            -- print("R: 123 D: 123")
            -- get my position
            local myPos = detector.getPlayerPos(myPlayer)
            -- calculate relative position
            local relX = math.floor(pos.x - myPos.x)
            local relY = math.floor(pos.y - myPos.y)
            local relZ = math.floor(pos.z - myPos.z)
            -- print("R: " .. relX .. " D: " .. relZ)
            -- translate the relative position to direction
            local relDirection = getRelativeDirection(relX, relZ)
            -- print("R: " .. relDirection .. " X: " .. relX .. " Y: " .. relY .. " Z: " .. relZ)
            local distance = math.floor(math.sqrt(relX * relX + relY * relY + relZ * relZ))
            print("R: " .. relDirection .. " D: " .. distance)
            
            -- update map
            playerMap[player] = pos
        end
    end
    -- update timer
    -- timer = timer + 0.2
    sleep(0.5)
end