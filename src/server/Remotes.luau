-- Remotes: the server -> client event channels. Created once at require time.
-- Notify(message) goes to one player; CashPopup(position, amount) goes to everyone
-- so any client can float a "+$" over the earning pad.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = Instance.new("Folder")
folder.Name = "BazaarRemotes"
folder.Parent = ReplicatedStorage

local function makeEvent(name: string): RemoteEvent
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = folder
	return event
end

return {
	Notify = makeEvent("Notify"),
	CashPopup = makeEvent("CashPopup"),
	Banner = makeEvent("Banner"), -- FireAllClients(text): big top banner (events, tsunami, countdown)
	Toast = makeEvent("Toast"), -- FireClient(player, text): small corner toast (quests, index)
	Celebrate = makeEvent("Celebrate"), -- FireClient(player, rebirths): rebirth celebration
}
