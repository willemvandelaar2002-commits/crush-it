--!strict
-- 4 Nov (VIP pass, Store "VIP"): a gold [VIP] tag before the names of VIP players in
-- chat. Reads the pass attribute (Store.hasPass) that the server sets; local only.
-- (OnIncomingMessage is a single callback: nothing else in the game sets it.)
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local RS = game:GetService("ReplicatedStorage")
local Store = require(RS.Shared.Store)

if TextChatService.ChatVersion ~= Enum.ChatVersion.TextChatService then return end

TextChatService.OnIncomingMessage = function(message: TextChatMessage)
	local props = Instance.new("TextChatMessageProperties")
	local source = message.TextSource
	local player = source and Players:GetPlayerByUserId(source.UserId)
	if player and Store.hasPass(player, "VIP") then
		props.PrefixText = '<font color="#FFC832">[VIP]</font> ' .. message.PrefixText
	end
	return props
end
