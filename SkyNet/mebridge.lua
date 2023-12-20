-- https://advancedperipherals.madefor.cc/peripherals/me_bridge/

local bridge = peripheral.find("meBridge")
-- check is not nil
if bridge == nil then
    print("Missing peripheral")
    return
end

local TARGET_ITEM = "minecraft:spruce_log"

-- getItem(item: table) -> table, err: string
-- Returns a table with information about the item type in the system.
-- Properties
-- name: string	The registry name of the item
-- fingerprint: string?	A unique fingerprint which identifies the item to craft
-- amount: number	The amount of the item in the system
-- displayName: string	The display name for the item
-- isCraftable: boolean	Whether the item has a crafting pattern or not
-- nbt: string?	NBT to match the item on
-- tags: table	A list of all of the item tags

local itemInfo = bridge.getItem({ name = TARGET_ITEM })
print(itemInfo.amount)

-- getEnergyUsage() -> number, err: string
-- Returns the energy usage of the whole ME System in AE/t.
local energyUsage = bridge.getEnergyUsage()
print(energyUsage)

-- exportItem(item: table, direction: string) -> number, err: string
-- Exports an item to a container in the direction from the ME bridge block.
-- Returns the number of the item exported into the container.

-- Exports 1 "Protection I" book into the container above
-- bridge.exportItem({name="minecraft:enchanted_book", count=1, nbt="ae70053c97f877de546b0248b9ddf525"}, "up")

-- move one item from the ME system to the chest on left relative to mebridge
-- bridge.exportItem({ name = TARGET_ITEM, count = 1 }, "left")

-- exportItemToPeripheral(item: table, container: string) -> number, err: string
-- Similar to exportItem() it exports an item to a container which is connected to the peripheral network.
-- container should be the exact name of the container peripheral on the network.
-- Returns the number of the item exported into the container.

-- move one of target item to minecraft:chest
bridge.exportItemToPeripheral({ name = TARGET_ITEM, count = 1 }, "left")
-- find the peripheral
local targetPeripheral = peripheral.find("minecraft:chest")
-- print the peripheral's inventory
print(textutils.serialize(targetPeripheral.list()))
