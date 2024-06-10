-- Custom OS for Computer Craft with Advanced Peripherals
-- Designed to run on pocket computer
-- Authors: Sean
-- Version: 0.5
-- Date: 2023-12-20

-- [[ CUSTOM CONFIG ]] --

-- Change system colors
local systemColors = {
    background = colors.black,
    text = colors.white,
    selectedBackground = colors.white,
    selectedText = colors.black,
}

-- Modem channel offset
local modemChannelOffset = 1000

-- If polling for modem (blocking for join/leaves)
local modemPoll = false

-- Type of polling/looping events
-- POS - position
-- ENV - environment
-- INV - inventory for armor updates
-- MEI - ME + Inventory (transfer items wirelessly)
local eventType = "POS"

-- If server of client mode for modem
local modemServerMode = true

-- Client side, delay if non position update
local nonPosUpdateTime = 5

-- [[ END CUSTOM CONFIG ]] --

--======[[ OS VARIABLES ]]======--

local OS_NAME = "SeanOS"
local OS_VERSION = "0.5"
local OS_DATE = "2023-12-20"
local DEBUG_MODE = true

--======[[ GLOBAL VARIABLES ]]======--

local TABS = {
    "Info",
    "Main",
}

local tCurSelected = 1
local tMax = #TABS

-- Helper variable for keeping track of time
local prevTicks = 0

-- Map for peripherals detected
-- e.g. pDetected["left"] = "modem"
local pDetected = {}
-- Map for peripherals detected by type
-- e.g. pDetectedByType["modem"] = {"left", "right"}
local pDetectedByType = {}

-- https://minecraft.fandom.com/wiki/Durability
local DEFAULT_MAX_ARMOR_DURABILITY = {
    ["minecraft:turtle_helmet"] = 275,
    ["minecraft:leather_helmet"] = 55,
    ["minecraft:golden_helmet"] = 77,
    ["minecraft:chainmail_helmet"] = 165,
    ["minecraft:iron_helmet"] = 165,
    ["minecraft:diamond_helmet"] = 363,
    ["minecraft:netherite_helmet"] = 407,
    ["minecraft:leather_chestplate"] = 80,
    ["minecraft:golden_chestplate"] = 112,
    ["minecraft:chainmail_chestplate"] = 240,
    ["minecraft:iron_chestplate"] = 240,
    ["minecraft:diamond_chestplate"] = 528,
    ["minecraft:netherite_chestplate"] = 592,
    ["minecraft:leather_leggings"] = 75,
    ["minecraft:golden_leggings"] = 105,
    ["minecraft:chainmail_leggings"] = 225,
    ["minecraft:iron_leggings"] = 225,
    ["minecraft:diamond_leggings"] = 495,
    ["minecraft:netherite_leggings"] = 555,
    ["minecraft:leather_boots"] = 65,
    ["minecraft:golden_boots"] = 91,
    ["minecraft:chainmail_boots"] = 195,
    ["minecraft:iron_boots"] = 195,
    ["minecraft:diamond_boots"] = 429,
    ["minecraft:netherite_boots"] = 481
}

--======[[ TIME FUNCTIONS ]]======--
-- function to covert ticks to time
function ticksToTime(ticks)
    local days = math.floor(ticks / 24000)
    local years = math.floor(days / 365)
    local ticksInDay = ticks % 24000
    local hours = math.floor(ticksInDay / 1000)
    local minutes = math.floor((ticksInDay % 1000) / 16.67)
    local seconds = math.floor((ticksInDay % 1000) % 16.67)
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
    local percentThroughPhase = 0
    local phase = "UNKNOWN"
    if ticks >= 0 and ticks < 12000 then
        phase = "DAYTIME"
        percentThroughPhase = ticks / 12000
    elseif ticks >= 12000 and ticks < 13000 then
        phase = "SUNSET"
        percentThroughPhase = (ticks - 12000) / 1000
    elseif ticks >= 13000 and ticks < 23000 then
        phase = "NIGHTTIME"
        percentThroughPhase = (ticks - 13000) / 10000
    else
        phase = "SUNRISE"
        percentThroughPhase = (ticks - 23000) / 1000
    end
    -- round to 2 d.p.
    percentThroughPhase = math.floor(percentThroughPhase * 10000) / 100
    return {
        phase = phase,
        percentThroughPhase = percentThroughPhase
    }
end

--======[[ TEXT FUNCTIONS ]]======--
-- local text = 'some really really really long text that needs to be wrapped severely'
-- local wrapped = wrapText(text, 15)
-- print(table.concat(wrapped, '\n'))
-- https://www.computercraft.info/forums2/index.php?/topic/14274-text-wrapping/

function wrapText(text, limit)
    local lines = {}
    local curLine = ''
    for word in text:gmatch('%S+%s*') do
            curLine = curLine .. word
            if #curLine + #word >= limit then
                    lines[#lines + 1] = curLine
                    curLine = ''
            end
    end
    return lines
end

--======[[ ME BRIDGE / INVENTORY FUNCTIONS ]]======--

-- function to get item from ME to chest on left
local function getItemFromMeToChest(me, itemName, count)
    me.exportItemToPeripheral({ name = itemName, count = count }, "left")
    print("Exported " .. count .. " " .. itemName .. " to chest on left")
end

-- function to move item from chest on left to player inventory via manager
local function getItemFromChestToPlayer(manager, itemName, count)
    -- check if the item already is in player inventory
    -- if so get slot where not full
    -- if not get free slot
    -- if no free slot return
    -- if free slot add item to player
    local playerInventory = manager.getItems()
    local slot = nil
    for i, item in ipairs(playerInventory) do
        if item.name == itemName then
            if item.count < item.maxStackSize then
                slot = item.slot
                break
            end
        end
    end
    if slot == nil then
        print("No slot found with " .. itemName .. " not full")
        slot = manager.getFreeSlot()
    end
    if slot == nil then
        print("No free slot found")
        return
    end
    print("Next free slot is " .. slot)
    print("Adding " .. count .. " " .. itemName .. " to player")
    manager.addItemToPlayer("front", count, slot, itemName)
end

--======[[ TAB FUNCTIONS ]]======--

-- Function for home/main tab
function tabHome()
    term.write("Event Log:")
    -- similar to modem tab, but creating a heartbeat depending
    -- on if in server or client mode
    local modem = peripheral.find("modem")
    if not modem then
        term.write("No modem found!")
        return false
    end

    -- if server side, check that playerDetector is connected
    if modemServerMode then
        -- must have at least one detector
        local isDetector = false
        if not pDetectedByType["playerDetector"] then
            term.write("No playerDetector found!")
        else
            isDetector = true
        end

        -- check for environmentDetector
        if not pDetectedByType["environmentDetector"] then
            term.write("No environmentDetector found!")
        else
            isDetector = true
        end

        -- check for inventoryManager
        if not pDetectedByType["inventoryManager"] then
            term.write("No inventoryManager found!")
        else
            isDetector = true
        end

        if not isDetector then
            term.write("No detectors found!")
            return false
        end
    end

    -- check if wanting to start program, as will be locked to this tab
    term.write("Enter to Start, q to Quit")

    -- poll for input, if not enter, then return
    local inLoop = true
    while inLoop do
        local event = { os.pullEventRaw() }
        if event[1] == "key" then
            if event[2] == keys.enter then
                inLoop = false
            elseif event[2] == keys.q or event[2] == keys.left or event[2] == keys.right then
                -- write cancel msg
                term.write("Cancelled!")
                return false
            end
        end
    end

    -- clear line
    term.clearLine()
    term.write("Starting...")
    -- open modem
    modem.open(modemChannelOffset + 1)
    -- for MEI modem
    if eventType == "MEI" then
        modem.open(modemChannelOffset + 3)
    end

    -- if server side, then listen for playerDetector events
    if modemServerMode then
        -- listen for playerDetector events

        -- determine type of detector to use
        local detector = nil
        local meBridge = nil
        if eventType == "POS" then
            detector = peripheral.find("playerDetector")
        elseif eventType == "ENV" then
            detector = peripheral.find("environmentDetector")
        elseif eventType == "INV" then
            detector = peripheral.find("inventoryManager")
        elseif eventType == "MEI" then
            detector = peripheral.find("inventoryManager")
            meBridge = peripheral.find("meBridge")
            if not meBridge then
                term.write("Ensure that ME Bridge is connected!")
                return false
            end
        end

        -- check if nil
        if not detector then
            term.write("Ensure that correct detector is connected!")
            return false
        end

        -- loop
        inLoop = true
        while inLoop do
            -- clear lines 2 and 3
            term.setCursorPos(1, 2)
            term.clearLine()
            term.setCursorPos(1, 3)
            term.clearLine()

            -- if pos
            if eventType == "POS" then
                -- if not polling
                if not modemPoll then
                    for _, player in pairs(detector.getOnlinePlayers()) do
                        local pos = detector.getPlayerPos(player)
                        if pos then
                            pos.pitch = if pos.pitch then pos.pitch else 0 end
                            pos.yaw = if pos.yaw then pos.yaw else 0 end
                            pos.x = if pos.x then pos.x else 0 end
                            pos.y = if pos.y then pos.y else 0 end
                            pos.z = if pos.z then pos.z else 0 end
                            local newPitch = math.floor(pos.pitch * 100) / 100
                            local newYaw = math.floor(pos.yaw * 100) / 100
                            local message = "1|" .. player .. "|" .. pos.x .. "|" .. pos.y .. "|" .. pos.z .. "|" .. newPitch .. "|" .. newYaw
                            -- send message
                            modem.transmit(modemChannelOffset + 1, modemChannelOffset + 2, message)
                            -- show on screen
                            -- replace
                            term.setCursorPos(1, 2)
                            term.write(message)
                        end
                        sleep(0.5)
                    end
                else
                    local event = { os.pullEventRaw() }
                    if event[1] == "playerChangedDimension" then
                        local message = "2|" .. event[2] .. "|" .. event[3] .. "|" .. event[4]
                        -- send message
                        modem.transmit(modemChannelOffset + 1, modemChannelOffset + 2, message)
                        -- show on screen
                        -- replace
                        term.setCursorPos(1, 2)
                        term.write(message)
                    elseif event[1] == "playerJoined" then
                        local message = "3|" .. event[2]
                        -- send message
                        modem.transmit(modemChannelOffset + 1, modemChannelOffset + 2, message)
                        -- show on screen
                        -- replace
                        term.setCursorPos(1, 2)
                        term.write(message)
                    elseif event[1] == "playerLeft" then
                        local message = "4|" .. event[2]
                        -- send message
                        modem.transmit(modemChannelOffset + 1, modemChannelOffset + 2, message)
                        -- show on screen
                        -- replace
                        term.setCursorPos(1, 2)
                        term.write(message)
                    end
                end

                -- else other detectors
            elseif eventType == "ENV" then
                -- is not affected by polling / position
                -- get time
                local ticks = detector.getTime()
                -- send packet 
                local message = "5|" .. ticks
                modem.transmit(modemChannelOffset + 1, modemChannelOffset + 2, message)
                -- show on screen
                -- replace
                term.setCursorPos(1, 2)
                term.write(message)

                local ticksInHour = (ticks % 24000) % 1000
                
                if prevTicks > ticksInHour then
                    -- get moon id
                    local moonId = detector.getMoonId()
                    -- get moon name
                    local moonName = detector.getMoonName()
                    -- send new packet
                    message = "6|" .. moonId .. "|" .. moonName
                    modem.transmit(modemChannelOffset + 1, modemChannelOffset + 2, message)
                    -- show on screen
                    -- replace
                    term.setCursorPos(1, 3)
                    term.write(message)
                end
                -- set prev ticks to cur ticks
                prevTicks = ticksInHour
                sleep(0.2)
            elseif eventType == "INV" then
                -- is not affected by polling
                -- get armor
                local armor = detector.getArmor()
                -- send packet
                local message = "7|"
                local SLOTSMAP = {
                    [103] = "Helmet    ",
                    [102] = "Chestplate",
                    [101] = "Leggings  ",
                    [100] = "Boots     "
                }
                for i = 1, #armor do
                    local item = armor[i].name
                    local slot = armor[i].slot
                    -- convert to generic
                    local genericName = SLOTSMAP[slot]

                    local damage = armor[i].nbt.Damage
                    local maxDurability = DEFAULT_MAX_ARMOR_DURABILITY[item]
                    if maxDurability == nil then
                        message = message .. genericName .. " " .. damage .. " / ?"
                    else 
                        local durabilityLeft = maxDurability - damage
                        local durabilityPercent = math.floor((durabilityLeft / maxDurability) * 100)
                        message = message .. genericName .. " " .. durabilityLeft .. " / " .. maxDurability .. " (" .. durabilityPercent .. "%)"
                    end
                    if i < #armor then
                        message = message .. "|"
                    end
                end
                -- finally send
                modem.transmit(modemChannelOffset + 1, modemChannelOffset + 2, message)
                -- show on screen
                -- replace
                term.setCursorPos(1, 2)
                -- term.write(#armor .. " " .. message)
                -- wrap text
                local termWidth, termHeight = term.getSize()
                local wrapped = wrapText(message, termWidth)
                for i = 1, #wrapped do
                    term.setCursorPos(1, 2 + i - 1)
                    term.write(wrapped[i])
                end
                sleep(1)
            elseif eventType == "MEI" then
                -- client will be sending on channel offset + 3
                -- server will be listening on channel offset + 4
                -- check for message
                -- main loop
                local inServerLoop = true
                while inServerLoop do
                    local event = { os.pullEventRaw() }
                    if event[1] == "modem_message" then
                        -- to be implemented

                        -- packet format
                        -- FROM CLIENT TO SERVER 
                        -- 9|<item name>|<item count>
                        -- server side to determine next slot and will take from ME to Player Inventory
                        
                        -- FROM SERVER TO CLIENT
                        -- then communicate back to client if success, or error
                        -- 8|<response message>
                        -- client side to display message

                        -- decode with |
                        local message = event[5]
                        local split = {}
                        for s in message:gmatch("[^|]+") do
                            table.insert(split, s)
                        end

                        -- check if 9
                        if split[1] == "9" then
                            -- check if 3
                            if #split == 3 then
                                -- get item name and count
                                local itemName = split[2]
                                local itemCount = tonumber(split[3])
                                -- check if item exists in ME
                                local meItem = meBridge.getItem({ name = itemName })
                                if not meItem then
                                    -- send error message
                                    local responseMessage = "8|Item " .. itemName .. " not found in ME"
                                    modem.transmit(modemChannelOffset + 1, modemChannelOffset + 3, responseMessage)
                                    -- show on screen
                                    -- replace
                                    term.setCursorPos(1, 2)
                                    term.write(responseMessage)
                                else
                                    -- get next free slot
                                    local slot = detector.getFreeSlot()
                                    if slot == nil then
                                        -- send error message
                                        local responseMessage = "8|No free slot found"
                                        modem.transmit(modemChannelOffset + 1, modemChannelOffset + 3, responseMessage)
                                        -- show on screen
                                        -- replace
                                        term.setCursorPos(1, 2)
                                        term.write(responseMessage)
                                    else
                                        -- get item from ME to chest
                                        getItemFromMeToChest(meBridge, itemName, itemCount)
                                        -- get item from chest to player
                                        getItemFromChestToPlayer(detector, itemName, itemCount)
                                        -- send success message
                                        local responseMessage = "8|Added " .. itemCount .. " " .. itemName .. " to player"
                                        modem.transmit(modemChannelOffset + 1, modemChannelOffset + 3, responseMessage)
                                        -- show on screen
                                        -- replace
                                        term.setCursorPos(1, 2)
                                        term.write(responseMessage)
                                    end
                                end
                            else
                                -- send error message
                                local responseMessage = "8|Invalid packet format"
                                modem.transmit(modemChannelOffset + 1, modemChannelOffset + 3, responseMessage)
                                -- show on screen
                                -- replace
                                term.setCursorPos(1, 2)
                                term.write(responseMessage)
                            end
                        end

                    -- Server side kill switch
                    elseif event[1] == "key" then
                        if event[2] == keys.q or event[2] == keys.left or event[2] == keys.right then
                            inServerLoop = false
                        end
                    elseif event[1] == "mouse_click" then
                        if event[2] == 1 then
                            inServerLoop = false
                        end
                    end
                end
                inLoop = false
            end

        end
    else
        -- check client event type - i.e if in MEI, then client will communicate with server
        if eventType == "MEI" then 
            -- get prompt for user
            -- setup prompt
            term.setCursorPos(1, 2)
            term.clearLine()
            term.write("Item:")
            local itemName = read()
            -- if not starts with minecraft:, add it, but if it has :, skip
            if not string.find(itemName, ":") then
                itemName = "minecraft:" .. itemName
            end
            -- get count
            term.setCursorPos(1, 3)
            term.clearLine()
            term.write("Count:")
            local itemCount = tonumber(read())
            -- send packet
            local packet = "9|" .. itemName .. "|" .. itemCount
            modem.transmit(modemChannelOffset + 1, modemChannelOffset + 4, packet)
            -- show on screen
            -- replace
            term.setCursorPos(1, 2)
            term.write(packet)
            -- listen for response
            local inClientLoop = true
            while inClientLoop do
                local event = { os.pullEventRaw() }
                if event[1] == "modem_message" then
                    -- decode with |
                    local message = event[5]
                    local split = {}
                    for s in message:gmatch("[^|]+") do
                        table.insert(split, s)
                    end
                    -- check if 8
                    if split[1] == "8" then
                        -- show on screen
                        -- replace
                        term.setCursorPos(1, 3)
                        term.write(split[2])
                        sleep(1)
                        inClientLoop = false
                    end
                elseif event[1] == "key" then
                    if event[2] == keys.q or event[2] == keys.left or event[2] == keys.right then
                        inClientLoop = false
                    end
                elseif event[1] == "mouse_click" then
                    if event[2] == 1 then
                        inClientLoop = false
                    end
                end
            end

            -- print end message
            term.setCursorPos(1, 4)
            term.clearLine()
            term.write("Press any key to continue")
            local event = { os.pullEventRaw() }
            inLoop = false
            
            
        else
            -- listen for modem_message
            local inLoop = true
            while inLoop do
                local event = { os.pullEventRaw() }
                if event[1] == "modem_message" then

                    term.setCursorPos(1, 2)
                    term.clearLine()
                    -- decode with |
                    local message = event[5]
                    local split = {}
                    for s in message:gmatch("[^|]+") do
                        table.insert(split, s)
                    end
                    -- 1 == PLAYER POSITION
                    -- 2 == PLAYER CHANGED DIMENSION
                    -- 3 == PLAYER JOIN
                    -- 4 == PLAYER LEAVE
                    -- 5 == TIME UPDATE
                    -- 6 == MOON UPDATE
                    -- 7 == ARMOR UPDATE

                    local yOffset = 3
                    -- if 5 then offset by extra 4
                    if split[1] == "5" then
                        yOffset = yOffset + 4
                    end
                    -- if 6 then offset by extra 8
                    if split[1] == "6" then
                        yOffset = yOffset + 8
                    end
                    -- if 7 then offset by extra 10
                    if split[1] == "7" then
                        yOffset = yOffset + 10
                    end

                    if split[1] == "1" then
                        -- PLAYER POSITION
                        term.write("Player Position:")
                        term.setCursorPos(1, 3)
                        term.clearLine()
                        term.write("Player: " .. split[2])
                        term.setCursorPos(1, 4)
                        term.clearLine()
                        term.write("X: " .. split[3] .. " Y: " .. split[4] .. " Z: " .. split[5])
                        term.setCursorPos(1, 5)
                        term.clearLine()
                        term.write("Pitch: " .. split[6] .. " Yaw: " .. split[7])
                    elseif split[1] == "2" then
                        -- PLAYER CHANGED DIMENSION
                        term.write("Player Changed Dimension:")
                        term.setCursorPos(1, yOffset)
                        term.clearLine()
                        term.write("Player: " .. split[2])
                        term.setCursorPos(1, yOffset + 1)
                        term.clearLine()
                        term.write("From: " .. split[3])
                        term.setCursorPos(1, yOffset + 2)
                        term.clearLine()
                        term.write("To: " .. split[4])
                        sleep(nonPosUpdateTime)
                    elseif split[1] == "3" then
                        -- PLAYER JOIN
                        term.write("Player Joined:")
                        term.setCursorPos(1, yOffset)
                        term.clearLine()
                        term.write("Player: " .. split[2])
                        -- clear other two lines
                        term.setCursorPos(1, yOffset + 1)
                        term.clearLine()
                        term.setCursorPos(1, yOffset + 2)
                        term.clearLine()
                        sleep(nonPosUpdateTime)
                    elseif split[1] == "4" then
                        -- PLAYER LEAVE
                        term.write("Player Left:")
                        term.setCursorPos(1, yOffset)
                        term.clearLine()
                        term.write("Player: " .. split[2])
                        -- clear other two lines
                        term.setCursorPos(1, yOffset + 1)
                        term.clearLine()
                        term.setCursorPos(1, yOffset + 2)
                        term.clearLine()
                        sleep(nonPosUpdateTime)
                    elseif split[1] == "5" then
                        -- TIME UPDATE
                        term.write("Time Update:")
                        term.setCursorPos(1, yOffset)
                        term.clearLine()
                        term.write("Ticks: " .. split[2])
                        -- set next line to days :: hours :: mins
                        local ticks = tonumber(split[2])
                        local time = ticksToTime(ticks)
                        term.setCursorPos(1, yOffset + 1)
                        term.clearLine()
                        local timeString = "Day: " .. time.days .. " Hour: " .. time.hours .. " Min: " .. time.minutes
                        term.write(timeString)
                        -- other line to phase of the day
                        term.setCursorPos(1, yOffset + 2)
                        term.clearLine()
                        -- get % through phase
                        local phaseInfo = getPhaseOfDay(ticks % 24000)
                        local phaseString = "Phase: " .. phaseInfo.phase .. " (" .. phaseInfo.percentThroughPhase .. "%)"
                        term.write(phaseString)
                    elseif split[1] == "6" then
                        -- MOON UPDATE
                        term.write("Moon Update:")
                        term.setCursorPos(1, yOffset)
                        term.clearLine()
                        term.write("Moon: " .. "(" .. split[2] .. ") " .. split[3])
                    elseif split[1] == "7" then
                        -- ARMOR UPDATE
                        term.write("Armor Update:")
                        -- for split[2 onwards]
                        for i = 2, #split do
                            term.setCursorPos(1, yOffset)
                            term.clearLine()
                            term.write(split[i])
                            yOffset = yOffset + 1
                        end

                    end

                    -- else if q or < or >, then quit
                elseif event[1] == "key" then
                    if event[2] == keys.q or event[2] == keys.left or event[2] == keys.right then
                        inLoop = false
                    end
                elseif event[1] == "mouse_click" then
                    if event[2] == 1 then
                        inLoop = false
                    end
                end
            end
        end
    end
        
    return false
end

-- Function for about/info tab
function tabAbout()
    local yOffset = 2
    term.setCursorPos(1, yOffset)
    term.write("Version: " .. OS_VERSION .. " (" .. OS_DATE .. ")")

    -- computer label
    yOffset = yOffset + 1
    term.setCursorPos(1, yOffset)
    local label = os.getComputerLabel()
    if label then
        term.write("Computer Label: " .. label)
    else
        term.write("Computer Label: None")
    end

    -- window size
    yOffset = yOffset + 1
    term.setCursorPos(1, yOffset)
    local w, h = term.getSize()
    term.write("Window Size: " .. w .. "x" .. h)

    -- disk space
    yOffset = yOffset + 1
    term.setCursorPos(1, yOffset)
    term.write("Disk Space: " .. fs.getFreeSpace("/") .. "/" .. fs.getCapacity("/"))
    -- in terms of KB
    yOffset = yOffset + 1
    term.setCursorPos(1, yOffset)
    term.write("Disk Space: " .. math.floor(fs.getFreeSpace("/") / 1024) .. "/" .. math.floor(fs.getCapacity("/") / 1024) .. " KB")

    -- Peripherals

    yOffset = yOffset + 1
    term.setCursorPos(1, yOffset)
    term.write("Peripherals:")

    for k, v in pairs(pDetectedByType) do
        yOffset = yOffset + 1
        term.setCursorPos(1, yOffset)
        term.write(k .. ":")
        for i = 1, #v do
            yOffset = yOffset + 1
            term.setCursorPos(1, yOffset)
            term.write("  " .. v[i])
        end
    end

    return false
end

-- Function for settings tab
function tabSettings()

    local yOffset = 2

    -- menu with a few different options, using keyboard and mouse for vertical selection
    local SETTING_OPTS = {
        "", -- modem channel
        "", -- server/client mode
        "", -- position/polling
        "", -- event type
    }

    local sCurSelected = 1
    local sMax = #SETTING_OPTS

    local inLoop = true
    while inLoop do
        -- render settings
        yOffset = 2
        term.setCursorPos(1, yOffset)
        term.write("Settings:")
        yOffset = yOffset + 1

        -- add modem offset to string
        SETTING_OPTS[1] = "Modem Chn Offset (" .. modemChannelOffset .. ")"

        if modemServerMode then
            SETTING_OPTS[2] = "In SERVER Mode"
        else
            SETTING_OPTS[2] = "In CLIENT Mode"
        end

        if modemPoll then
            SETTING_OPTS[3] = "Polling Events"
        else
            SETTING_OPTS[3] = "Looping Events"
        end

        if eventType == "POS" then
            SETTING_OPTS[4] = "Position Events"
        elseif eventType == "ENV" then
            SETTING_OPTS[4] = "Environment Events"
        elseif eventType == "INV" then
            SETTING_OPTS[4] = "Inventory Events"
        elseif eventType == "MEI" then
            SETTING_OPTS[4] = "ME + Inventory Events"
        end

        for i = 1, sMax do
            if i == sCurSelected then
                term.setBackgroundColor(systemColors.selectedBackground)
                term.setTextColor(systemColors.selectedText)
            else
                term.setBackgroundColor(systemColors.background)
                term.setTextColor(systemColors.text)
            end
            term.setCursorPos(1, yOffset)
            term.clearLine()
            term.write(SETTING_OPTS[i])
            yOffset = yOffset + 1
        end

        -- Resets
        term.setBackgroundColor(systemColors.background)
        term.setTextColor(systemColors.text)
        

        -- handle input
        local event = { os.pullEventRaw() }
        if event[1] == "key" then
            if event[2] == keys.up then
                if sCurSelected > 1 then
                    sCurSelected = sCurSelected - 1
                end
            elseif event[2] == keys.down then
                if sCurSelected < sMax then
                    sCurSelected = sCurSelected + 1
                end
            elseif event[2] == keys.enter then
                if sCurSelected == 1 then
                    settingsCBModemOffset()
                elseif sCurSelected == 2 then
                    settingsCBModemMode()
                elseif sCurSelected == 3 then
                    settingsCBModemPoll()
                elseif sCurSelected == 4 then
                    settingsCBEventType()
                end
                -- [ check for tab switching ]
            elseif event[2] == keys.left then
                inLoop = false
                -- change tab
                if tCurSelected > 1 then
                    tCurSelected = tCurSelected - 1
                end
            end
        elseif event[1] == "mouse_click" then
            if event[2] == 1 then
                if event[4] >= 2 and event[4] <= 2 + sMax then
                    sCurSelected = event[4] - 2
                    -- call callback
                    if sCurSelected == 1 then
                        settingsCBModemOffset()
                    elseif sCurSelected == 2 then
                        settingsCBModemMode()
                    elseif sCurSelected == 3 then
                        settingsCBModemPoll()
                    elseif sCurSelected == 4 then
                        settingsCBEventType()
                    end
                elseif event[4] == 1 then
                    inLoop = false
                    -- change tab based on x
                    local xOffset = 1
                    for i = 1, tMax do
                        -- Note: Need to -1 from #TABS[i] because of the
                        -- space between tabs
                        if event[3] >= xOffset and event[3] <= xOffset + #TABS[i] - 1
                        then
                            tCurSelected = i
                            break
                        end
                        xOffset = xOffset + #TABS[i] + 1
                    end
                end
            end
        end
    end
            
    return true
end

-- Callbacks for settings
function settingsCBModemOffset() 
    --[[ Modem Channel Offset ]]
    -- Go to bottom of screen - 2
    local w, h = term.getSize()
    local yOffset = h - 2

    -- clear bottom 2 lines
    term.setCursorPos(1, yOffset - 1)
    term.clearLine()
    term.setCursorPos(1, yOffset)
    term.clearLine()

    term.setCursorPos(1, yOffset)
    term.write("Modem Chn Offset: " .. modemChannelOffset)
    yOffset = yOffset + 1
    term.setCursorPos(1, yOffset)
    term.write("Enter new offset: ")
    local newOffset = read()
    local val = tonumber(newOffset)
    -- must be 0 < x < 65535
    if val and val > 0 and val < 65535 then
        modemChannelOffset = val
        updateSetting("S3_CHN", modemChannelOffset)

        -- clear last 2 lines and success message
        term.setCursorPos(1, yOffset - 1)
        term.clearLine()
        term.setCursorPos(1, yOffset)
        term.clearLine()
        term.write("Success!")
    else
        term.setCursorPos(1, yOffset)
        term.clearLine()
        term.write("Must be (0 < x < 65500)")
    end

end

function settingsCBModemMode()
    --[[ Modem Mode ]]
    modemServerMode = not modemServerMode
    updateSetting("S3_MODE", tostring(modemServerMode))
end

function settingsCBModemPoll()
    --[[ Modem Poll ]]
    modemPoll = not modemPoll
    updateSetting("S3_POLL", tostring(modemPoll))
end

function settingsCBEventType()
    --[[ Event Type ]]
    -- Cycle through
    local eventTypes = {"POS", "ENV", "INV", "MEI"}
    local curIndex = 1
    for i = 1, #eventTypes do
        if eventType == eventTypes[i] then
            curIndex = i
            break
        end
    end
    curIndex = curIndex + 1
    if curIndex > #eventTypes then
        curIndex = 1
    end
    eventType = eventTypes[curIndex]
    updateSetting("S3_EVT", eventType)
end

-- Function for players tab
function tabPlayers()
    local yOffset = 2
    term.setCursorPos(1, yOffset)
    term.write("Players:")
    yOffset = yOffset + 1

    local detector = peripheral.find("playerDetector")
    local players = detector.getOnlinePlayers()

    -- just show playername and xyz below
    for i = 1, #players do
        local player = players[i]
        local pos = detector.getPlayerPos(player)
        if pos and pos.x and pos.y then
            pos.z = pos.z or "UNK"
            term.setCursorPos(1, yOffset)
            term.write(player)
            yOffset = yOffset + 1
            term.setCursorPos(1, yOffset)
            term.write("X: " .. pos.x .. " Y: " .. pos.y .. " Z: " .. pos.z)
            yOffset = yOffset + 1
        end
    end


    return false
end

-- Function for modem tab
function tabModem()

    local modem = peripheral.find("modem")
    if not modem then
        term.write("No modem found!")
        return false
    end

    local yOffset = 2
    term.setCursorPos(1, yOffset)
    term.write("Modem:")
    yOffset = yOffset + 1

    -- If in client mode, just listen, if in server mode, listen and send, with 10 second delay
    -- First ask for starting to send/listen
    term.setCursorPos(1, yOffset)
    term.write("Enter to Start, q to Quit")
    -- poll for input, if not enter, then return
    local inLoop = true
    while inLoop do
        local event = { os.pullEventRaw() }
        if event[1] == "key" then
            if event[2] == keys.enter then
                inLoop = false
            elseif event[2] == keys.q or event[2] == keys.left or event[2] == keys.right then
                -- write cancel msg
                term.setCursorPos(1, yOffset)
                term.clearLine()
                term.write("Cancelled!")
                return false
            end
        end
    end

    -- clear line
    term.setCursorPos(1, yOffset)
    term.clearLine()
    if modemServerMode then
        term.write("Sending...")
        -- open modem
        modem.open(modemChannelOffset + 1)
        -- send message
        modem.transmit(modemChannelOffset + 1, modemChannelOffset + 2, "Hello World!")
        -- close modem
        modem.close(modemChannelOffset + 1)
        term.setCursorPos(1, yOffset)
        term.clearLine()
        term.write("Sent!")
    else
        term.write("Listening...")
        -- open modem
        modem.open(modemChannelOffset + 1)
        -- listen for message
        -- wait for modem_message
        local cancelled = false
        local inLoop = true
        while inLoop do
            local event = { os.pullEventRaw() }
            if event[1] == "modem_message" then
                term.setCursorPos(1, yOffset)
                term.clearLine()
                term.write("Message: " .. event[5])
                inLoop = false
                -- else if q or < or >, then quit
            elseif event[1] == "key" then
                if event[2] == keys.q or event[2] == keys.left or event[2] == keys.right then
                    inLoop = false
                    cancelled = true
                end
            elseif event[1] == "mouse_click" then
                if event[2] == 1 then
                    inLoop = false
                    cancelled = true
                end
            end
        end
        if cancelled then
            term.setCursorPos(1, yOffset)
            term.clearLine()
            term.write("Cancelled!")
        end
        -- close modem
        modem.close(modemChannelOffset + 1)
    end

    return false
end

-- Function for environment tab
function tabEnvironment() 
    local envDetector = peripheral.find("environmentDetector")
    if not envDetector then
        term.write("No environmentDetector found!")
        return false
    end

    local ticks = envDetector.getTime()
    local time = ticksToTime(ticks)
    local ticksInDay = ticks % 24000
    local timeString = "Day: " .. time.days .. " Hour: " .. time.hours .. " Min: " .. time.minutes
    local phaseInfo = getPhaseOfDay(ticks % 24000)
    local phaseString = "Phase: " .. phaseInfo.phase .. " (" .. phaseInfo.percentThroughPhase .. "%)"
    local moonString = "Moon: " .. envDetector.getMoonName()

    local yOffset = 2
    term.setCursorPos(1, yOffset)
    term.write("Environment:")
    -- TIME AND MOON INFORMATION
    yOffset = yOffset + 1
    term.setCursorPos(1, yOffset)
    term.write(timeString)
    yOffset = yOffset + 1
    term.setCursorPos(1, yOffset)
    term.write(phaseString)
    yOffset = yOffset + 1
    term.setCursorPos(1, yOffset)
    term.write(moonString)

    return false
end

-- Function for inventory tab
function tabInventory()
    local invManager = peripheral.find("inventoryManager")
    if not invManager then
        term.write("No inventoryManager found!")
        return false
    end

    local yOffset = 2
    term.setCursorPos(1, yOffset)
    -- just show armour information
    term.write("Armor:")
    yOffset = yOffset + 1
    term.setCursorPos(1, yOffset)
    yOffset = yOffset + 1
    local armor = invManager.getArmor()

    for i, armorPiece in ipairs(armor) do
        -- get each item and it's nbt damage and then do % to get durability left
        local item = armorPiece.name
        local damage = armorPiece.nbt.Damage
        local maxDurability = DEFAULT_MAX_ARMOR_DURABILITY[item]
        if maxDurability == nil then
            print("No max durability found for " .. item)
        else 
            local durabilityLeft = maxDurability - damage
            local durabilityPercent = math.floor((durabilityLeft / maxDurability) * 100)
            print(i, armorPiece.displayName)
            print("Durability: " .. durabilityPercent .. "% (" .. durabilityLeft .. "/" .. maxDurability .. ")")
        end
        
    end

    return false

end

-- Function map for each tab
local TAB_FUNCTIONS = {
    tabAbout,
    tabHome,
}

--======[[ FILE SYSTEM FUNCTIONS ]]======--

-- Function to update a setting value
function updateSetting(setting, value)
    --[[ Update Setting ]]
    -- find specific line then write new value
    local settings = fs.open(".settings", "r")
    local lines = {}
    local line = settings.readLine()
    while line do
        if line:find(setting) then
            line = setting .. "=" .. value
        end
        table.insert(lines, line)
        line = settings.readLine()
    end
    settings.close()
    settings = fs.open(".settings", "w")
    for i = 1, #lines do
        settings.write(lines[i] .. "\n")
    end
    settings.close()
end

--======[[ WINDOW FUNCTIONS ]]======--

-- Function to render the tabs and currently selected
function renderTabs(skipExec)
    term.clear()
    local xOffset = 1
    for i = 1, tMax do
        if i == tCurSelected then
            term.setBackgroundColor(systemColors.selectedBackground)
            term.setTextColor(systemColors.selectedText)
        else
            term.setBackgroundColor(systemColors.background)
            term.setTextColor(systemColors.text)
        end
        term.setCursorPos(xOffset, 1)
        term.write(TABS[i])
        xOffset = xOffset + #TABS[i] + 1
    end

    -- Resets
    term.setBackgroundColor(systemColors.background)
    term.setTextColor(systemColors.text)
    term.setCursorPos(1, 2)
    
    if not skipExec then
        if TAB_FUNCTIONS[tCurSelected] then
            local prevTab = tCurSelected
            local cleanupTab = TAB_FUNCTIONS[tCurSelected]()
            -- Top prevent double inputs needed form sub menus
            if cleanupTab then
                if prevTab ~= tCurSelected then
                    renderTabs(false)
                end
            end
        else 
            term.write("No function for tab " .. tCurSelected)
        end
    end
end

--======[[ INPUT FUNCTIONS ]]======--

-- Function to handle keyboard input
function handleKeyBoardInput(key)
    local doTabsRender = false
    local quitting = false

    -- [[ Tab switching ]]
    if key == keys.left then
        if tCurSelected > 1 then
            tCurSelected = tCurSelected - 1
            doTabsRender = true
        end
    elseif key == keys.right then
        if tCurSelected < tMax then
            tCurSelected = tCurSelected + 1
            doTabsRender = true
        end
    --[[ Quit ]]
    elseif key == keys.q then
        quitting = true
    end
    
    -- Render tabs if needed
    if doTabsRender then
        renderTabs(false)
    end

    return quitting
end

-- Function to handle mouse input
function handleMouseInput(event)
    local doTabsRender = false
    -- Note: event[2] is mouse btn
    -- 1 = left, 2 = right, 3 = middle
    -- event[3] is x, event[4] is y
    if event[2] == 1 then
        --[[ Tab switching ]]
        if event[4] == 1 then
            local xOffset = 1
            for i = 1, tMax do
                -- Note: Need to -1 from #TABS[i] because of the
                -- space between tabs
                if event[3] >= xOffset and event[3] <= xOffset + #TABS[i] - 1
                then
                    tCurSelected = i
                    doTabsRender = true
                    break
                end
                xOffset = xOffset + #TABS[i] + 1
            end
        end
    end

    -- Render tabs if needed
    if doTabsRender then
        renderTabs(false)
    end
    
end

-- Function to wait for keyboard or mouse input
function waitForInput()
    --[[ Input ]]
    local event = { os.pullEventRaw() }

    local quitting = false

    if event[1] == "key" then
        quitting = handleKeyBoardInput(event[2])
    elseif event[1] == "mouse_click" then
        handleMouseInput(event)
    end
    -- Note: other events are noted here
    -- https://www.computercraft.info/wiki/Category:Events

    return not quitting
end

--======[[ PERIPHERAL FUNCTIONS ]]======--

-- Function determine what peripherals are connected
function checkPeripherals()
    --[[ Peripherals ]]
    local peripherals = peripheral.getNames()
    -- for each, log
    for i = 1, #peripherals do
        peripheralType = peripheral.getType(peripherals[i])
        -- add to pDetected
        pDetected[peripherals[i]] = peripheralType
        -- add to pDetectedByType
        if pDetectedByType[peripheralType] then
            table.insert(pDetectedByType[peripheralType], peripherals[i])
        else
            pDetectedByType[peripheralType] = {peripherals[i]}
        end
    end
end

-- Function to determine what features are available
-- Mainly checking for playerDetector
function determineFeatures()

    if pDetectedByType["playerDetector"] then
        --[[ Player Detector ]]
        table.insert(TABS, "Players")
        table.insert(TAB_FUNCTIONS, tabPlayers)
        tMax = #TABS
        -- debugPrint("Player Detector found!")
    end
    -- env
    if pDetectedByType["environmentDetector"] then
        --[[ Environment Detector ]]
        table.insert(TABS, "Environment")
        table.insert(TAB_FUNCTIONS, tabEnvironment)
        tMax = #TABS
        -- debugPrint("Environment Detector found!")
    end
    -- inventory
    if pDetectedByType["inventoryManager"] then
        --[[ Inventory Manager ]]
        table.insert(TABS, "Inventory")
        table.insert(TAB_FUNCTIONS, tabInventory)
        tMax = #TABS
        -- debugPrint("Inventory Manager found!")
    end
    if pDetectedByType["modem"] then
        --[[ Modem ]]
        table.insert(TABS, "Modem")
        table.insert(TAB_FUNCTIONS, tabModem)
        tMax = #TABS
        -- debugPrint("Modem found!")
    end

end

--======[[ MAIN FUNCTIONS ]]======--

-- First time boot callback
function firstTimeBoot()
    --[[ First time boot ]]
    term.clear()
    term.setCursorPos(1, 1)
    term.write("Welcome to " .. OS_NAME .. "!")
    term.setCursorPos(1, 2)
    term.write("Version: " .. OS_VERSION .. " (" .. OS_DATE .. ")")
    term.setCursorPos(1, 3)
    term.write("Press any key to continue...")
    os.pullEvent("key")
end

-- Check for first boot
function checkFirstTimeBoot()
    -- check .settings for s3.version
    if fs.exists(".settings") then
        local settings = fs.open(".settings", "r")
        -- find S3_VER/S3_MODE/S3_CHN/S3_POLL/S3_EVT
        local numSettings = 5
        local finished = 0
        local line = settings.readLine()
        while line and finished ~= numSettings do
            if line:find("S3_VER") then
                finished = finished + 1
                -- if S3_VER is not equal to current version,
                -- then show update message
                if line:find(OS_VERSION) == nil then
                    -- save old version into variable
                    local oldVersion = line:sub(8)
                    settings.close()
                    -- set S3_VER to current version
                    settings = fs.open(".settings", "w")
                    settings.write("S3_VER=" .. OS_VERSION)
                    settings.close()
                    -- show update message
                    term.clear()
                    term.setCursorPos(1, 1)
                    term.write(OS_NAME .. " has been updated to version "
                        .. OS_VERSION .. " from " .. oldVersion .. ".")
                    sleep(1)
                end
            elseif line:find("S3_MODE") then
                finished = finished + 1
                -- simply set modemServerMode to value
                modemServerMode = line:sub(9) == "true"
            elseif line:find("S3_POLL") then
                finished = finished + 1
                -- simply set modemPoll to value
                modemPoll = line:sub(9) == "true"
            elseif line:find("S3_CHN") then
                finished = finished + 1
                -- simply set modemChannelOffset to value
                modemChannelOffset = tonumber(line:sub(8))
            elseif line:find("S3_EVT") then
                finished = finished + 1
                -- simply set eventType to value
                eventType = line:sub(8)
            end
            -- check if at end before trying to readline
            if finished ~= numSettings then
                line = settings.readLine()
            end
        end

        if not line then
            -- if S3_VER/MODE is not found, then add it
            settings.close()
            settings = fs.open(".settings", "a")
            settings.write("S3_VER=" .. OS_VERSION)
            settings.write("\nS3_MODE=" .. tostring(modemServerMode))
            settings.write("\nS3_CHN=" .. modemChannelOffset)
            settings.write("\nS3_POLL=" .. tostring(modemPoll))
            settings.write("\nS3_EVT=" .. eventType)
            settings.close()
            firstTimeBoot()
        end
    else
        -- if .settings does not exist, then create it
        local settings = fs.open(".settings", "w")
        settings.write("S3_VER=" .. OS_VERSION)
        settings.write("\nS3_MODE=" .. tostring(modemServerMode))
        settings.write("\nS3_CHN=" .. modemChannelOffset)
        settings.write("\nS3_POLL=" .. tostring(modemPoll))
        settings.write("\nS3_EVT=" .. eventType)
        settings.close()
        firstTimeBoot()
    end
end

-- Function to handle exiting
function handleExit()
    term.clear()
    term.setCursorPos(1, 1)
end

-- Function to print message if in DEBUG mode
function debugPrint(message)
    if DEBUG_MODE then
        term.clear()
        print(message)
        sleep(1)
    end
end

-- Main function to simply render tabs, then say hello world, sleep(1) then exit
function main()

    -- Check if first time boot
    checkFirstTimeBoot()
    
    -- Loading
    term.clear()
    term.setCursorPos(1, 1)
    term.write("Loading...")

    checkPeripherals()
    -- determine what features are available
    determineFeatures()
    -- add settings tab
    table.insert(TABS, "Settings")
    table.insert(TAB_FUNCTIONS, tabSettings)
    tMax = #TABS

    term.setCursorPos(1, 1)
    term.clearLine()
    term.write("Loaded!")
    

    renderTabs(false)
    local inLoop = true
    while inLoop do
        inLoop = waitForInput()
    end

    handleExit()
end

main()
