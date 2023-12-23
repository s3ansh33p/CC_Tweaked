local manager = peripheral.find("inventoryManager")
-- https://github.com/SirEndii/AdvancedPeripherals/blob/1c260bc5877e5805fe907c15342c7e60ccb2c174/src/main/java/de/srendi/advancedperipherals/common/addons/computercraft/peripheral/InventoryManagerPeripheral.java
local me = peripheral.find("meBridge")

-- check both exist
if manager == nil or me == nil then
    print("Missing peripheral")
    return
end

-- function to get item from ME to chest on left
local function getItemFromMeToChest(itemName, count)
    me.exportItemToPeripheral({ name = itemName, count = count }, "left")
end

-- function to move item from chest on left to player inventory via manager
local function getItemFromChestToPlayer(itemName, count)
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

local ITEM_NAME = "minecraft:spruce_log"
local ITEM_COUNT = 1


-- function to remove an item from the player and put in me system
local function removeItemFromPlayerToChest(itemName, count)
    local playerInventory = manager.getItems()
    local slot = nil
    for i, item in ipairs(playerInventory) do
        if item.name == itemName then
            if item.count >= count then
                slot = item.slot
                break
            end
        end
    end
    if slot == nil then
        print("No slot found with " .. itemName .. " with count " .. count)
        return
    end
    print("Next slot is " .. slot)
    print("Removing " .. count .. " " .. itemName .. " from player")
    manager.removeItemFromPlayer("front", count, slot, itemName)
end

-- function to get item to ME from chest on left
local function removeItemFromChestToMe(itemName, count)
    me.importItemFromPeripheral({ name = itemName, count = count }, "left")
end

-- function to list items in me system, with offset
local function listItems(offset, limit)
    local items = me.listItems()
    local i = offset
    local count = 0
    while items[i] ~= nil do
        print(items[i].displayName .. " " .. items[i].amount)
        i = i + 1
        count = count + 1
        if limit ~= nil and count >= limit then
            break
        end
    end
end

-- format item name
-- change spaces to _
-- make all lowercase
-- add minecraft: if no : exists
local function formatItemName(itemName)
    local formattedName = itemName:gsub(" ", "_")
    formattedName = formattedName:lower()
    if not formattedName:find(":") then
        formattedName = "minecraft:" .. formattedName
    end
    return formattedName
end

-- search items
-- filter search results by item query string
local function searchItems(query)
    local formattedQuery = query:lower()
    local items = me.listItems()
    local results = {}
    local limit = 10
    for i, item in ipairs(items) do
        if #results >= limit then
            break
        end
        -- convert all to lowercase
        local name = item.name:lower()
        if name:find(formattedQuery) then
            table.insert(results, item)
        end
    end
    return results    
end

-- function to show results
local function showResults(results)
    for i, item in ipairs(results) do
        print(item.displayName .. " " .. item.amount)
    end
end

-- function for system information
local function systemInformation()
    local numCells = #me.listCells()
    local totalItemStorage = me.getTotalItemStorage()
    local totalFluidStorage = me.getTotalFluidStorage()
    print("Number of Cells: " .. numCells)
    if totalItemStorage == 0 then
        print("Items: 0/0 (0%)")
    else
        local usedItemStorage = me.getUsedItemStorage()
        local itemPercent = math.floor(usedItemStorage / totalItemStorage * 10000) / 100
        print("Items: " .. usedItemStorage .. "/" .. totalItemStorage .. " (" .. itemPercent .. "%)")
    end
        if totalFluidStorage == 0 then
        print("Fluids: 0/0 (0%)")
    else 
        local usedFluidStorage = me.getUsedFluidStorage()
        local fluidPercent = math.floor(usedFluidStorage / totalFluidStorage * 10000) / 100
        print("Fluids: " .. usedFluidStorage .. "/" .. totalFluidStorage .. " (" .. fluidPercent .. "%)")
    end
end

local function main()

    local mainLoop = true
    while mainLoop do
        print("1. Export from ME")
        print("2. Import to ME")
        print("3. List items in ME")
        print("4. Search items in ME")
        print("5. ME System Information")
        print("6. Exit")

        local choice = tonumber(read())
        if choice == 1 then
            print("Enter item name")
            local itemName = read()
            itemName = formatItemName(itemName)
            print("Enter item count")
            local itemCount = tonumber(read())
            -- if count > 64 then split into multiple requests
            local leftOver = itemCount % 64
            while itemCount >= 64 do
                getItemFromMeToChest(itemName, 64)
                getItemFromChestToPlayer(itemName, 64)
                itemCount = itemCount - 64
            end
            if leftOver > 0 then
                getItemFromMeToChest(itemName, leftOver)
                getItemFromChestToPlayer(itemName, leftOver)
            end
        elseif choice == 2 then
            print("Enter item name")
            local itemName = read()
            itemName = formatItemName(itemName)
            print("Enter item count")
            local itemCount = tonumber(read())
            local leftOver = itemCount % 64
            while itemCount >= 64 do
                removeItemFromPlayerToChest(itemName, 64)
                removeItemFromChestToMe(itemName, 64)
                itemCount = itemCount - 64
            end
            if leftOver > 0 then
                removeItemFromPlayerToChest(itemName, leftOver)
                removeItemFromChestToMe(itemName, leftOver)
            end
        elseif choice == 3 then
            print("Enter offset")
            local offset = tonumber(read())
            print("Enter limit")
            local limit = tonumber(read())
            listItems(offset, limit)
        elseif choice == 4 then
            print("Enter search query")
            local query = read()
            local results = searchItems(query)
            showResults(results)
        elseif choice == 5 then
            systemInformation()
        elseif choice == 6 then
            mainLoop = false
        else
            print("Invalid choice")
        end
    end
end

main()