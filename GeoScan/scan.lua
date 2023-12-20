-- https://advancedperipherals.madefor.cc/peripherals/geo_scanner/

local geoScanner = peripheral.find("geoScanner")

-- get args
local tArgs = { ... }
if #tArgs ~= 2 then
    print("Usage: scan <radius> <type>")
    return
end

-- get radius
local radius = tonumber(tArgs[1])
if radius == nil then
    print("Radius must be a number")
    return
end

-- get type
local type = tArgs[2]
if type ~= "s" and type ~= "m" and type ~= "l" then
    print("Type must be 's', 'm', or 'l'")
    return
end

-- get scan
local scan = geoScanner.scan(radius)
if scan == nil then
    print("Scan Failed")
    return
end

local targetBlocksMapSmall = {
    ["minecraft:redstone_ore"] = true,
    ["minecraft:deepslate_redstone_ore"] = true,
    ["minecraft:ancient_debris"] = true
}
local targetBlocksMapMedium = {
    ["minecraft:diamond_ore"] = true,
    ["minecraft:redstone_ore"] = true,
    -- deepslate
    ["minecraft:deepslate_diamond_ore"] = true,
    ["minecraft:deepslate_redstone_ore"] = true,
    -- nether
    ["minecraft:nether_quartz_ore"] = true,
    ["minecraft:ancient_debris"] = true
}
local targetBlocksMapLarge = {
    ["minecraft:iron_ore"] = true,
    ["minecraft:gold_ore"] = true,
    ["minecraft:diamond_ore"] = true,
    ["minecraft:emerald_ore"] = true,
    ["minecraft:lapis_ore"] = true,
    ["minecraft:redstone_ore"] = true,
    ["minecraft:coal_ore"] = true,
    -- deepslate
    ["minecraft:deepslate_iron_ore"] = true,
    ["minecraft:deepslate_gold_ore"] = true,
    ["minecraft:deepslate_diamond_ore"] = true,
    ["minecraft:deepslate_emerald_ore"] = true,
    ["minecraft:deepslate_lapis_ore"] = true,
    ["minecraft:deepslate_redstone_ore"] = true,
    ["minecraft:deepslate_coal_ore"] = true,
    -- nether
    ["minecraft:nether_quartz_ore"] = true,
    ["minecraft:ancient_debris"] = true
}

local targetBlocksMap = {}
if type == "s" then
    targetBlocksMap = targetBlocksMapSmall
elseif type == "m" then
    targetBlocksMap = targetBlocksMapMedium
elseif type == "l" then
    targetBlocksMap = targetBlocksMapLarge
end

-- results
local results = {}

-- loop through results
for i, block in ipairs(scan) do
    -- check if target block
    if targetBlocksMap[block.name] then
        local _, endIndex = string.find(block.name, ":")
        local blockName = string.sub(block.name, endIndex + 1)
        -- print(blockName, block.x, block.y, block.z)
        -- add to results
        -- add distance
        local absDistance = math.abs(block.x) + math.abs(block.y) + math.abs(block.z)
        table.insert(results, {blockName, block.x, block.y, block.z, absDistance})
    end
end

-- loop through in order of distance
table.sort(results, function(a, b) return a[5] < b[5] end)
for i, result in ipairs(results) do
    if (i <= 10) then
        print(result[1], result[2], result[3], result[4])
    elseif (i == 11) then
        print("Showing 10 of " .. #results .. " results")
    end
   
end
