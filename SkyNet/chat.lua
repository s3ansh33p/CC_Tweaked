-- https://advancedperipherals.madefor.cc/peripherals/chat_box/

-- local event, username, message, uuid, isHidden = os.pullEvent("chat")
-- print("The 'chat' event was fired with the username " .. username .. " and the message " .. message)

local chatBox = peripheral.find("chatBox")
-- chatBox.sendMessageToPlayer("Loaded", "s3nsuous") -- Sends "[AP] Hello there." to Player123 in chat


local message = {
    {text = "Check out my new video "},
    {
        text = "here",
        underlined = true,
        color = "aqua",
        clickEvent = {
            action = "open_url",
            value = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        }
    },
    {text = " :)"}
}

local json = textutils.serialiseJSON(message)

chatBox.sendFormattedMessage(json)

-- chatBox.sendFormattedMessageToPlayer(json, "s3nsuous")

-- send to all players
-- local players = {"s3nsuous", "Warie", "Jaarsh119", "OG_Duckosar", "benwolf22"}

-- for _, player in pairs(players) do
--     chatBox.sendFormattedMessageToPlayer(json, player)
-- end
