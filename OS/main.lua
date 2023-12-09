-- Custom OS for Computer Craft with Advanced Peripherals
-- Designed to run on pocket computer
-- Authors: Sean
-- Version: 0.3
-- Date: 2023-12-09

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

-- If server of client mode for modem
local modemServerMode = true

-- [[ END CUSTOM CONFIG ]] --

--======[[ OS VARIABLES ]]======--

local OS_NAME = "SeanOS"
local OS_VERSION = "0.3"
local OS_DATE = "2023-12-09"
local DEBUG_MODE = true

--======[[ GLOBAL VARIABLES ]]======--

local TABS = {
    "Info",
    "Main",
}

local tCurSelected = 1
local tMax = #TABS

-- Map for peripherals detected
-- e.g. pDetected["left"] = "modem"
local pDetected = {}
-- Map for peripherals detected by type
-- e.g. pDetectedByType["modem"] = {"left", "right"}
local pDetectedByType = {}

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
        if not pDetectedByType["playerDetector"] then
            term.write("No playerDetector found!")
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

    -- if server side, then listen for playerDetector events
    if modemServerMode then
        -- listen for playerDetector events
        local detector = peripheral.find("playerDetector")

        -- loop
        inLoop = true
        while inLoop do
            -- if not polling
            if not modemPoll then
                for _, player in pairs(detector.getOnlinePlayers()) do
                    local pos = detector.getPlayerPos(player)
                    local newPitch = math.floor(pos.pitch * 100) / 100
                    local newYaw = math.floor(pos.yaw * 100) / 100
                    local message = "1|" .. player .. "|" .. pos.x .. "|" .. pos.y .. "|" .. pos.z .. "|" .. newPitch .. "|" .. newYaw
                    -- send message
                    modem.transmit(modemChannelOffset + 1, modemChannelOffset + 2, message)
                    -- show on screen
                    -- replace
                    term.setCursorPos(1, 2)
                    term.clearLine()
                    term.write(message)
                    sleep(1)
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
                    term.clearLine()
                    term.write(message)
                elseif event[1] == "playerJoined" then
                    local message = "3|" .. event[2]
                    -- send message
                    modem.transmit(modemChannelOffset + 1, modemChannelOffset + 2, message)
                    -- show on screen
                    -- replace
                    term.setCursorPos(1, 2)
                    term.clearLine()
                    term.write(message)
                elseif event[1] == "playerLeft" then
                    local message = "4|" .. event[2]
                    -- send message
                    modem.transmit(modemChannelOffset + 1, modemChannelOffset + 2, message)
                    -- show on screen
                    -- replace
                    term.setCursorPos(1, 2)
                    term.clearLine()
                    term.write(message)
                end
            end

        end
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
                    term.setCursorPos(1, 3)
                    term.clearLine()
                    term.write("Player: " .. split[2])
                    term.setCursorPos(1, 4)
                    term.clearLine()
                    term.write("From: " .. split[3])
                    term.setCursorPos(1, 5)
                    term.clearLine()
                    term.write("To: " .. split[4])
                elseif split[1] == "3" then
                    -- PLAYER JOIN
                    term.write("Player Joined:")
                    term.setCursorPos(1, 3)
                    term.clearLine()
                    term.write("Player: " .. split[2])
                    -- clear other two lines
                    term.setCursorPos(1, 4)
                    term.clearLine()
                    term.setCursorPos(1, 5)
                    term.clearLine()
                elseif split[1] == "4" then
                    -- PLAYER LEAVE
                    term.write("Player Left:")
                    term.setCursorPos(1, 3)
                    term.clearLine()
                    term.write("Player: " .. split[2])
                    -- clear other two lines
                    term.setCursorPos(1, 4)
                    term.clearLine()
                    term.setCursorPos(1, 5)
                    term.clearLine()
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
        "",
        "",
        "",
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
            SETTING_OPTS[3] = "Position Events"
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
        term.write("Invalid offset (0 < x < 65535)")
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
        term.setCursorPos(1, yOffset)
        term.write(player)
        yOffset = yOffset + 1
        term.setCursorPos(1, yOffset)
        term.write("X: " .. pos.x .. " Y: " .. pos.y .. " Z: " .. pos.z)
        yOffset = yOffset + 1
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
        debugPrint("Player Detector found!")
    end
    if pDetectedByType["modem"] then
        --[[ Modem ]]
        table.insert(TABS, "Modem")
        table.insert(TAB_FUNCTIONS, tabModem)
        tMax = #TABS
        debugPrint("Modem found!")
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
        -- find S3_VER/S3_MODE/S3_CHN/S3_POLL
        local numSettings = 4
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
        print(message)
        sleep(0.2)
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
