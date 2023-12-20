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

local ITEM_NAME = "minecraft:spruce_log"
local ITEM_COUNT = 1

getItemFromMeToChest(ITEM_NAME, ITEM_COUNT)
getItemFromChestToPlayer(ITEM_NAME, ITEM_COUNT)
