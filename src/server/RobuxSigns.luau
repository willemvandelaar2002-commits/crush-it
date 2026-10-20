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
}

local W, H = 9, 6 -- sign face size (studs)
local GAP = 2

-- Builds the sign pair into `parent` as Model "RobuxSigns" (pivot at its ground centre).
function RobuxSigns.build(parent: Instance, frameColor: Color3): Model
	local m = Instance.new("Model")
	m.Name = "RobuxSigns"
	local total = #RobuxSigns.Signs * (W + 2) + (#RobuxSigns.Signs - 1) * GAP
	for i, def in RobuxSigns.Signs do
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
	-- OWNED on the owner's own signs (cheap poll: 8 plots x 2 labels).
	task.spawn(function()
		while true do
			for _, plot in getPlots() do
				local signs = plot.model:FindFirstChild("RobuxSigns")
				if not signs then
					continue
				end
				for _, def in RobuxSigns.Signs do
					local price = signs:FindFirstChild(def.perk) and signs[def.perk]:FindFirstChild("Price", true) :: TextButton?
					local pass = Store.passByPerk(def.perk)
					if price and pass then
						local owned = plot.owner ~= nil and Store.hasPass(plot.owner, def.perk)
						local text = if owned then "OWNED" else "R$ " .. pass.price
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
