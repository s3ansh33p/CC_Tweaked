-- https://advancedperipherals.madefor.cc/peripherals/inventory_manager/

-- https://minecraft.fandom.com/wiki/Durability
local DEFAULT_MAX_DURABILITY = {
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

local manager = peripheral.find("inventoryManager")

-- addItemToPlayer(direction: string, item: table) -> number
-- Adds an item to the player's inventory and returns the amount of the item added.
-- The direction is the direction of the container relative to the peripheral.
-- The slot is the slot to take items from in the container.
-- The Inventory Manager will add a random item to the player's inventory
-- if the item or slot argument are not provided.
-- NOTE:
-- You can now use both relative (right, left, front, back, top, bottom) and
-- cardinal (north, south, east, west, up, down) directions for the direction argument.

-- Add 32 cobblestone to the players offhand slot from the block above
-- manager.addItemToPlayer("up", {name="minecraft:cobblestone", toSlot=36, count=32})

-- removeItemFromPlayer(direction: string item: table) -> number
-- Removes an item from the player's inventory and returns the amount of the item removed.
-- The direction is the direction of the container relative to the peripheral to put the item into.
-- The slot is the slot to take items from in the player's inventory. The Inventory Manager will
-- remove a random item from the player's inventory if the item or slot argument are not provided.
-- The slot and count are overwritten if fromSlot or count is specified in the item filter if the
-- item argument is empty, the manager will move any item.

-- Remove up to 5 of the item in slot 1 of the player's inventory
-- and place it in the block above
-- manager.removeItemFromPlayer("up", {name="minecraft:cobblestone", toSlot=3, fromSlot=1, count=5})

-- getArmor() -> table
-- Returns a list of the player's current armor slots
-- Item Properties
-- name: string	The registry name of the item
-- count: number	The amount of the item
-- maxStackSize: number	Maximum stack size for the item type
-- displayName: string	The item's display name
-- slot: number	The slot that the item stack is in
-- tags: table	A list of item tags
-- nbt: table	The item's nbt data

local armor = manager.getArmor()
print("First armor piece is: " .. armor[1].displayName)
for i, armorPiece in ipairs(armor) do
    -- get each item and it's nbt damage and then do % to get durability left
    local item = armorPiece.name
    local damage = armorPiece.nbt.Damage
    local maxDurability = DEFAULT_MAX_DURABILITY[item]
    if maxDurability == nil then
        print("No max durability found for " .. item)
    else 
        local durabilityLeft = maxDurability - damage
        local durabilityPercent = math.floor((durabilityLeft / maxDurability) * 100)
        print(i, armorPiece.displayName, durabilityPercent .. "%")
    end
    
end

if false then 
    -- getItems() -> table
    -- Returns the contents of the player's inventory as a list of items
    -- Item Properties
    -- name: string	The registry name of the item
    -- count: number	The amount of the item
    -- maxStackSize: number	Maximum stack size for the item type
    -- slot: number	The slot that the item stack is in
    -- displayName: string	The item's display name
    -- tags: table	A list of item tags
    -- nbt: table	The item's nbt data
    local items = manager.getItems()
    print("First item is: " .. items[1].displayName)
    -- for loop
    for i, item in ipairs(items) do
        print(i, item.displayName, item.slot)
    end
    sleep(5)

    -- getOwner() -> string | nil
    -- Returns the username of the owner of the memory card in the manager or nil if there is no memory card or owner.
    local owner = manager.getOwner()
    print("Owner is: " .. owner)

    -- isPlayerEquipped() -> boolean
    -- Returns true if the player is wearing atleast one piece of armor.
    local isPlayerEquipped = manager.isPlayerEquipped()
    print("Is player equipped: " .. tostring(isPlayerEquipped))

    -- isWearing(slot: number) -> boolean
    -- Returns true if the player is wearing a armor piece on the given slot.
    -- Slots: 103(Helmet) - 100(Boots).
    local isWearingHelmet = manager.isWearing(103)
    print("Is player wearing helmet: " .. tostring(isWearingHelmet))
    local isWearingChestplate = manager.isWearing(102)
    print("Is player wearing chestplate: " .. tostring(isWearingChestplate))
    local isWearingLeggings = manager.isWearing(101)
    print("Is player wearing leggings: " .. tostring(isWearingLeggings))
    local isWearingBoots = manager.isWearing(100)
    print("Is player wearing boots: " .. tostring(isWearingBoots))
    sleep(2)

    -- getItemInHand() -> table
    -- Returns the item in the player's main hand.
    -- Item Properties
    -- name: string	The registry name of the item
    -- count: number	The amount of the item
    -- maxStackSize: number	Maximum stack size for the item type
    -- displayName: string	The item's display name
    -- tags: table	A list of item tags
    -- nbt: table	The item's nbt data
    local itemInHand = manager.getItemInHand()
    print("Item in hand: " .. itemInHand.displayName)

    -- getItemInOffHand() -> table
    -- Returns the item in the player's off hand.
    -- Item Properties
    -- name: string	The registry name of the item
    -- count: number	The amount of the item
    -- maxStackSize: number	Maximum stack size for the item type
    -- displayName: string	The item's display name
    -- tags: table	A list of item tags
    -- nbt: table	The item's nbt data
    local itemInOffHand = manager.getItemInOffHand()
    print("Item in off hand: " .. itemInOffHand.displayName)

    -- getFreeSlot() -> number
    -- Returns the next free slot in the player's inventory. Or -1 if their inventory is full.
    local freeSlot = manager.getFreeSlot()  
    print("Free slot: " .. freeSlot)

    -- isSpaceAvailable() -> boolean
    -- Returns true if space is available in the player's inventory.
    local isSpaceAvailable = manager.isSpaceAvailable()
    print("Is space available: " .. tostring(isSpaceAvailable))

    -- getEmptySpace() -> number
    -- Returns the number of empty slots in the player's inventory.
    local emptySpace = manager.getEmptySpace()
    print("Empty space: " .. emptySpace)
end