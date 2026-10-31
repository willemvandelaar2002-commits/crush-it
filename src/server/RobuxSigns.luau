--!strict
-- Robux signs on every plot (Destroy a Vault's "Auto Collect 99" signs):
-- two small chunky signs left of the press for the strongest passes. Click one
-- to get the purchase prompt; on the plot owner's own signs a pass they already
-- have shows OWNED. Plots.luau builds and moves them, Game.server starts the loop.

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Store = require(ReplicatedStorage.Shared.Store)
local Net = require(ReplicatedStorage.Shared.Net)
local Style = require(ReplicatedStorage.Shared.Kit.Style)
local Icons = require(ReplicatedStorage.Shared.Icons)
local Build = require(script.Parent.Kit.Build)
local Analytics = require(script.Parent.Kit.Analytics)

local RobuxSigns = {}

RobuxSigns.Signs = {
	{ perk = "AutoCrush", icon = Icons.AutoCrush, a = Color3.fromRGB(255, 120, 90), b = Color3.fromRGB(200, 40, 70) },
	{ perk = "DoubleCash", icon = Icons.DoubleCash, a = Color3.fromRGB(120, 235, 100), b = Color3.fromRGB(40, 150, 60) },
	{ perk = "AutoCollect", icon = Icons.Cash, a = Color3.fromRGB(255, 185, 70), b = Color3.fromRGB(225, 110, 30) },
	{ perk = "Lucky", icon = Icons.Lucky, a = Color3.fromRGB(110, 230, 120), b = Color3.fromRGB(30, 150, 70) },
}
-- Which signs stand next to the press (the scrap shop island has its own Auto Collect sign).
RobuxSigns.PressSigns = { "AutoCrush", "DoubleCash" }

local W, H = 9, 6 -- sign face size (studs)
local GAP = 2

-- Builds a row of signs (default: PressSigns) into `parent` as Model "RobuxSigns"
-- (pivot at its ground centre).
-- 31 Oct: optional smaller size for the crusher plots (w, h = face studs)
function RobuxSigns.build(parent: Instance, frameColor: Color3, perks: { string }?, size: Vector2?): Model
	local W, H = if size then size.X else W, if size then size.Y else H
	local m = Instance.new("Model")
	m.Name = "RobuxSigns"
	local list = {}
	for _, perk in perks or RobuxSigns.PressSigns do
		for _, def in RobuxSigns.Signs do
			if def.perk == perk then
				table.insert(list, def)
			end
		end
	end
	local total = #list * (W + 2) + (#list - 1) * GAP
	for i, def in list do
		local pass = Store.passByPerk(def.perk)
		if not pass then
			continue
		end
		local x = -total / 2 + (i - 1) * (W + 2 + GAP) + (W + 2) / 2
		local sign, face = Build.signFrame(m, CFrame.new(x, 0, 0), W, H, frameColor)
		sign.Name = def.perk
		local gui = Instance.new("SurfaceGui")
		gui.Name = "Offer"
		gui.Face = Enum.NormalId.Back
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		gui.LightInfluence = 0
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- Style.panel puts its studs/border under the content
		gui.Parent = face
		local bg = Instance.new("Frame")
		bg.Size = UDim2.fromScale(1, 1)
		bg.Parent = gui
		Style.panel(bg, def.a, def.b)
		local icon = Instance.new("ImageLabel")
		icon.Position = UDim2.fromScale(0.04, 0.08)
		icon.Size = UDim2.fromScale(0.36, 0.56)
		icon.BackgroundTransparency = 1
		icon.ScaleType = Enum.ScaleType.Fit
		icon.Image = def.icon
		icon.ZIndex = 2
		icon.Parent = bg
		local title = Instance.new("TextLabel")
		title.Position = UDim2.fromScale(0.42, 0.08)
		title.Size = UDim2.fromScale(0.55, 0.3)
		title.BackgroundTransparency = 1
		title.TextScaled = true
		title.Text = pass.title
		title.ZIndex = 2
		title.Parent = bg
		Style.text(title, 4)
		local desc = Instance.new("TextLabel")
		desc.Position = UDim2.fromScale(0.42, 0.4)
		desc.Size = UDim2.fromScale(0.55, 0.24)
		desc.BackgroundTransparency = 1
		desc.TextScaled = true
		desc.TextWrapped = true
		desc.Text = pass.desc
		desc.ZIndex = 2
		desc.Parent = bg
		Style.text(desc, 2)
		local price = Instance.new("TextButton") -- Style.button wants a button; a SurfaceGui on a part doesn't take clicks
		price.Name = "Price"
		price.AnchorPoint = Vector2.new(0.5, 1)
		price.Position = UDim2.fromScale(0.5, 0.95)
		price.Size = UDim2.fromScale(0.8, 0.26)
		price.TextScaled = true
		price.Text = "R$ " .. pass.price
		price.ZIndex = 3
		price.Parent = bg
		Style.button(price, Style.GREEN)
		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0.12, 0)
		pad.PaddingBottom = UDim.new(0.12, 0)
		pad.Parent = price
		-- click anywhere on the sign
		for _, part in sign:GetDescendants() do
			if part:IsA("BasePart") and (part.Name == "Face" or part.Name == "Frame") then
				local click = Instance.new("ClickDetector")
				click.MaxActivationDistance = 60
				click:SetAttribute("Perk", def.perk)
				click.Parent = part
			end
		end
	end
	m.WorldPivot = CFrame.identity
	m.Parent = parent
	return m
end

type PlotLike = { model: Model, owner: Player? }

-- Roblox's own pass price (cached; the Store price until it answers)
local livePrice: { [number]: number } = {}
function RobuxSigns.price(pass: any): number
	local id = pass.gamePassId
	if id == 0 then return pass.price end
	if livePrice[id] == nil then
		livePrice[id] = pass.price
		task.spawn(function()
			local ok, info = pcall(function() return MarketplaceService:GetProductInfo(id, Enum.InfoType.GamePass) end)
			if ok and info and type(info.PriceInRobux) == "number" then livePrice[id] = info.PriceInRobux end
		end)
	end
	return livePrice[id]
end

function RobuxSigns.start(getPlots: () -> { PlotLike })
	local Notice = Net.event("Notice")
	local function onClick(player: Player, perk: string)
		local pass = Store.passByPerk(perk)
		if not pass or Store.hasPass(player, perk) then
			return
		end
		Analytics.custom(player, "SignClicked", nil, perk)
		if pass.gamePassId == 0 then
			Notice:FireClient(player, { text = pass.title .. ": coming soon!" })
			return
		end
		MarketplaceService:PromptGamePassPurchase(player, pass.gamePassId)
	end
	for _, plot in getPlots() do
		for _, d in plot.model:GetDescendants() do
			if d:IsA("ClickDetector") and d:GetAttribute("Perk") then
				d.MouseClick:Connect(function(player)
					onClick(player, d:GetAttribute("Perk") :: string)
				end)
			end
		end
	end
	-- OWNED on the owner's own signs (cheap poll over the sign models found once).
	type Entry = { plot: PlotLike, signs: Instance }
	local entries: { Entry } = {}
	for _, plot in getPlots() do
		for _, d in plot.model:GetDescendants() do
			if d:IsA("Model") and d.Name == "RobuxSigns" then
				table.insert(entries, { plot = plot, signs = d })
			end
		end
	end
	task.spawn(function()
		while true do
			for _, e in entries do
				for _, def in RobuxSigns.Signs do
					local sign = e.signs:FindFirstChild(def.perk)
					local price = sign and sign:FindFirstChild("Price", true) :: TextButton?
					local pass = Store.passByPerk(def.perk)
					if price and pass then
						local owner = e.plot.owner
						local owned = owner ~= nil and Store.hasPass(owner, def.perk)
						local text = if owned then "OWNED" else "R$ " .. RobuxSigns.price(pass)
						if price.Text ~= text then
							price.Text = text
							Style.setButtonColor(price, if owned then Color3.fromRGB(110, 112, 120) else Style.GREEN)
						end
					end
				end
			end
			task.wait(1)
		end
	end)
end

return RobuxSigns
