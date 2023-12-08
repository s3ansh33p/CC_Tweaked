-- Custom OS for Computer Craft with Advanced Peripherals
-- Designed to run on pocket computer
-- Authors: Sean
-- Version: 0.1
-- Date: 2023-12-09

-- [[ CUSTOM CONFIG ]] --

-- Change system colors
local systemColors = {
    background = colors.black,
    text = colors.white,
    selectedBackground = colors.white,
    selectedText = colors.black,
}

-- [[ END CUSTOM CONFIG ]] --

--======[[ OS VARIABLES ]]======--

local OS_NAME = "SeanOS"
local OS_VERSION = "0.1"
local OS_DATE = "2023-12-09"
local DEBUG_MODE = true

--======[[ GLOBAL VARIABLES ]]======--

local TABS = {
    "Home",
    "About",
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

-- Function for home tab
function tabHome()
    term.write("Hello World!")
    term.setCursorPos(1, 3)
    -- show all peripherals
    checkPeripherals()
end

-- Function for about tab
function tabAbout()
    term.write("About")
    -- Version info
    term.setCursorPos(1, 3)
    term.write("Version: " .. OS_VERSION .. " (" .. OS_DATE .. ")")
    -- Peripherals
    term.setCursorPos(1, 4)
    term.write("Peripherals:")
    local yOffset = 5
    for k, v in pairs(pDetectedByType) do
        term.setCursorPos(1, yOffset)
        term.write(k .. ":")
        yOffset = yOffset + 1
        for i = 1, #v do
            term.setCursorPos(1, yOffset)
            term.write("  " .. v[i])
            yOffset = yOffset + 1
        end
    end
end

-- Function map for each tab
local TAB_FUNCTIONS = {
    tabHome,
    tabAbout,
}

--======[[ WINDOW FUNCTIONS ]]======--

-- Function to render the tabs and currently selected
function renderTabs()
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
    
    if TAB_FUNCTIONS[tCurSelected] then
        TAB_FUNCTIONS[tCurSelected]()
    else 
        term.write("No function for tab " .. tCurSelected)
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
        renderTabs()
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
        renderTabs()
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
        -- find S3_VER
        local found = false
        local line = settings.readLine()
        while line do
            if line:find("S3_VER") then
                found = true
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
            end
            line = settings.readLine()
        end

        if not found then
            -- if S3_VER is not found, then add it
            settings.close()
            settings = fs.open(".settings", "a")
            settings.write("S3_VER=" .. OS_VERSION)
            settings.close()
            firstTimeBoot()
        end
    else
        -- if .settings does not exist, then create it
        local settings = fs.open(".settings", "w")
        settings.write("S3_VER=" .. OS_VERSION)
        settings.close()
        firstTimeBoot()
    end
end

-- Function to handle exiting
function handleExit()
    term.clear()
end

-- Main function to simply render tabs, then say hello world, sleep(1) then exit
function main()

    -- Check if first time boot
    checkFirstTimeBoot()

    renderTabs()
    local inLoop = true
    while inLoop do
        inLoop = waitForInput()
    end

    handleExit()
end

main()
