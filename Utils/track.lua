-- https://advancedperipherals.madefor.cc/peripherals/player_detector/#events

local detector = peripheral.find("playerDetector")

-- Get the position of Player123 and print their coordinates
-- local pos = detector.getPlayerPos("Player123")
-- print("Position: " .. pos.x .. "," .. pos.y .. "," .. pos.z)

-- getOnlinePlayers() -> table

-- So loop through all players and show coords
-- for _, player in pairs(detector.getOnlinePlayers()) do
--     local pos = detector.getPlayerPos(player)
--     print(player .. " is at " .. pos.x .. "," .. pos.y .. "," .. pos.z)
-- end

-- then wrap this in loop and clear terminal and print again

-- while true do
--     term.clear()
--     term.setCursorPos(1,1)
--     for _, player in pairs(detector.getOnlinePlayers()) do
--         local pos = detector.getPlayerPos(player)
--         print(player .. " is at " .. pos.x .. "," .. pos.y .. "," .. pos.z)
--     end
--     sleep(1)
-- end

-- settings for monitor to be whtie text not gray
term.setTextColor(colors.white)
term.setBackgroundColor(colors.black)

-- create a map of players and their positions, instead of refreshing entire screen, just the lines that have changed
local playerMap = {}
-- second map for average player movement over last 5 seconds
local playerMapAvg = {}
-- timer
local timer = 0
-- first iteration of players
for _, player in pairs(detector.getOnlinePlayers()) do
    local pos = detector.getPlayerPos(player)
    playerMap[player] = pos
end

-- start with clear screen
term.clear()

local myPlayer = "s3nsuous"

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

            -- calculate average movement over last 5 seconds
            if playerMapAvg[player] == nil then
                playerMapAvg[player] = {}
                playerMapAvg[player].x = 0
                playerMapAvg[player].y = 0
                playerMapAvg[player].z = 0
            end
            -- add to average
            playerMapAvg[player].x = playerMapAvg[player].x + pos.x
            playerMapAvg[player].y = playerMapAvg[player].y + pos.y
            playerMapAvg[player].z = playerMapAvg[player].z + pos.z
            -- if timer is 5 seconds, then calculate average and reset timer
            if timer >= 1 then
                -- calculate average
                playerMapAvg[player].x = playerMapAvg[player].x / 50
                playerMapAvg[player].y = playerMapAvg[player].y / 50
                playerMapAvg[player].z = playerMapAvg[player].z / 50
                -- reset timer
                timer = 0
            end

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
            -- print new data
            -- print("P: " .. pos.pitch .. " Y: " .. pos.yaw)
            -- round each to 4 d.p
            -- print("P: " .. math.floor(pos.pitch * 10000) / 10000 .. " Y: " .. math.floor(pos.yaw * 10000) / 10000)
            -- translate the YAW to direction
            local direction = ""
            if pos.yaw >= -22.5 and pos.yaw < 22.5 then
                direction = "S"
            elseif pos.yaw >= 22.5 and pos.yaw < 67.5 then
                direction = "SW"
            elseif pos.yaw >= 67.5 and pos.yaw < 112.5 then
                direction = "W"
            elseif pos.yaw >= 112.5 and pos.yaw < 157.5 then
                direction = "NW"
            elseif pos.yaw >= 157.5 or pos.yaw < -157.5 then
                direction = "N"
            elseif pos.yaw >= -157.5 and pos.yaw < -112.5 then
                direction = "NE"
            elseif pos.yaw >= -112.5 and pos.yaw < -67.5 then
                direction = "E"
            elseif pos.yaw >= -67.5 and pos.yaw < -22.5 then
                direction = "SE"
            else 
                direction = "?!"
            end
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
            local relDirection = ""
            if relX == 0 and relZ == 0 then
                relDirection = "HERE"
            elseif relX == 0 and relZ > 0 then
                relDirection = "S"
            elseif relX == 0 and relZ < 0 then
                relDirection = "N"
            elseif relX > 0 and relZ == 0 then
                relDirection = "E"
            elseif relX < 0 and relZ == 0 then
                relDirection = "W"
            elseif relX > 0 and relZ > 0 then
                relDirection = "SE"
            elseif relX > 0 and relZ < 0 then
                relDirection = "NE"
            elseif relX < 0 and relZ > 0 then
                relDirection = "SW"
            elseif relX < 0 and relZ < 0 then
                relDirection = "NW"
            else
                relDirection = "?!"
            end
            -- print("R: " .. relDirection .. " X: " .. relX .. " Y: " .. relY .. " Z: " .. relZ)
            local distance = math.floor(math.sqrt(relX * relX + relY * relY + relZ * relZ))
            -- print("R: " .. relDirection .. " D: " .. distance)
            -- include average moved over last 5 seconds relative to each player
            -- if timer hsa reset then show, else don't update
            if timer == 0 then
                -- calculate average relative position
                local avgRelX = math.floor(playerMapAvg[player].x - myPos.x)
                local avgRelY = math.floor(playerMapAvg[player].y - myPos.y)
                local avgRelZ = math.floor(playerMapAvg[player].z - myPos.z)
                -- print("R: " .. relDirection .. " X: " .. relX .. " Y: " .. relY .. " Z: " .. relZ)
                local avgDistance = math.floor(math.sqrt(avgRelX * avgRelX + avgRelY * avgRelY + avgRelZ * avgRelZ))
                print("R: " .. relDirection .. " D: " .. distance .. " A: " .. avgDistance)
            else
                print("R: " .. relDirection .. " D: " .. distance)
            end
            -- update map
            playerMap[player] = pos
        end
    end
    -- sleep for 1 second
    -- sleep(1)

    -- sleep for 0.1 second
    -- sleep(0.1)

    -- update timer
    timer = timer + 0.2
end