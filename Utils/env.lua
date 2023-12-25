-- https://advancedperipherals.madefor.cc/peripherals/environment_detector/

local envDetector = peripheral.find("environmentDetector")

-- get biome
-- Returns the current biome the block is in.
local biome = envDetector.getBiome()
print("Biome: " .. biome)

-- get block light level
-- Returns the block light level (0 to 15) at the detector block, this can be influenced by light sources
local blockLight = envDetector.getBlockLightLevel()
print("Block Light: " .. blockLight)

-- get day light level
-- Returns the day light level of the current world from 0 to 15. This is uneffected by blocks covering the peripheral.
local dayLight = envDetector.getDayLightLevel()
print("Day Light: " .. dayLight)

-- getSkyLightLevel
-- Returns the current sky light level from 0 to 15 (like a daylight sensor).
local skyLight = envDetector.getSkyLightLevel()
print("Sky Light: " .. skyLight)

-- getMoonId
-- Returns the current moon phase's id.
-- There are 8 different moon phases, see below a list of their names and ids
-- 0 = Full moon, 1 = Waning gibbous, 2 = Third quarter, 3 = Waning crescent, 4 = New moon, 5 = Waxing crescent, 6 = First quarter, 7 = Waxing gibbous
local moonId = envDetector.getMoonId()
print("Moon Id: " .. moonId)

-- getMoonName
-- Returns the current moon phase's name.
local moonName = envDetector.getMoonName()
print("Moon Name: " .. moonName)

-- getTime
-- Returns the total number of ticks since the world was created.
local time = envDetector.getTime()
print("Time: " .. time)

-- DAYTIME
-- Start: 0 ticks (06:00:00.0)
-- Mid: 6000 ticks (12:00:00.0)
-- End: 12000 ticks (18:00:00.0)

-- SUNSET/DUSK
-- Start: 12000 ticks (18:00:00.0)
-- End: 13000 ticks (19:00:00.0)

-- NIGHTTIME
-- Start: 13000 ticks (19:00:00.0)
-- Mid: 18000 ticks (00:00:00.0)
-- End: 23000 ticks (05:00:00.0)

-- SUNRISE/DAWN
-- Start: 23000 ticks (05:00:00.0)
-- End: 24000 (0) ticks (06:00:00.0)

-- function to covert ticks to time
function ticksToTime(ticks)
    local days = math.floor(ticks / 24000)
    local years = math.floor(days / 365)
    local ticksInDay = ticks % 24000
    local hours = math.floor(ticksInDay / 1000)
    local minutes = math.floor((ticksInDay % 1000) / 16.66666666666667)
    local seconds = math.floor((ticksInDay % 1000) % 16.66666666666667)
    return {
        seconds = seconds,
        minutes = minutes,
        hours = hours,
        days = days,
        years = years
    }
end

-- function to get phase of day
function getPhaseOfDay(ticks)
    local phase = "UNKNOWN"
    if ticks >= 0 and ticks < 12000 then
        phase = "DAYTIME"
    elseif ticks >= 12000 and ticks < 13000 then
        phase = "SUNSET"
    elseif ticks >= 13000 and ticks < 23000 then
        phase = "NIGHTTIME"
    else
        phase = "SUNRISE"
    end
    return phase
end

-- print time info
local timeInfo = ticksToTime(time)
print("Time Info: ")
print("Seconds: " .. timeInfo.seconds)
print("Minutes: " .. timeInfo.minutes)
print("Hours: " .. timeInfo.hours)
print("Days: " .. timeInfo.days)
print("Years: " .. timeInfo.years)

-- get ticks in day with %
local ticksInDay = time % 24000

-- get phase
local phase = getPhaseOfDay(ticksInDay)
print("Phase: " .. phase)

