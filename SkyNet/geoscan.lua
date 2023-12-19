-- https://advancedperipherals.madefor.cc/peripherals/geo_scanner/

local geoScanner = peripheral.find("geoScanner")

-- file writing for results
local file = fs.open("results.txt", "w")

-- scan(radius: number) -> table | nil, string
-- Returns a list of data about all blocks in the radius. Or if the scan fails it returns nil and an error message.
-- Block Properties
-- name: string	The registry name of the block
-- tags: table	A list of block tags
-- x: number	The block's x coordinate
-- y: number	The block's y coordinate
-- z: number	The block's z coordinate
local radius = 1
local scan = geoScanner.scan(radius)
-- first check if null
if scan == nil then
    print("Scan Failed")
    -- write to file
    file.writeLine("Scan Failed")
    -- close file
    file.close()
    -- exit program
    return
end

-- write to file
file.writeLine("Block ID, Block Name, X, Y, Z")
-- print each block
for i, block in ipairs(scan) do
    -- local tags = table.concat(block.tags, ", ") -- convert the tags table to a string
    print(i, block.name, block.x, block.y, block.z)
    -- write to file
    file.writeLine(i .. ", " .. block.name .. ", " .. block.x .. ", " .. block.y .. ", " .. block.z)
end

-- chunkAnalyze() -> table | nil, reason
-- Returns a table of data about how many of each ore type is in the block's chunk. Or if the analyze fails it returns nil and an error message.
local chunkAnalyze = geoScanner.chunkAnalyze()
-- determine if nil
if chunkAnalyze == nil then
    print("Chunk Analyze Failed")
    -- write to file
    file.writeLine("Chunk Analyze Failed")
    -- close file
    file.close()
    -- exit program
    return
end

-- write to file
file.writeLine("Ore ID, Ore Name, Ore Count")
-- print each ore
for i, ore in ipairs(chunkAnalyze) do
    print(i, ore.name, ore.count)
    -- write to file
    file.writeLine(i .. ", " .. ore.name .. ", " .. ore.count)
end

-- save and close file
file.close()
