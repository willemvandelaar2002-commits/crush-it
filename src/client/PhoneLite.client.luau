--!strict
-- 3 Nov (vault: Mobile and Low-End Optimization, "what to cut on low tiers"; Willem:
-- phone sessions are shorter). On phones and tablets (touch, no keyboard) and on PCs
-- with graphics quality set to 1-3 (Style.lite), this client trims what costs the
-- most on a weak GPU and changes no gameplay information:
--   * screen post effects off: Bloom, SunRays, DepthOfField (full-screen passes)
--   * the Atmosphere's glare and haze lowered (less fill per pixel)
--   * every particle emitter in the world at half its rate
-- Everything is local to this player; the server's settings stay as they are.
-- 6 Nov: the EFFECTS setting (client/Settings) can switch it on or off at any time, so
-- everything it changes is remembered and put back when it switches off.
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RS = game:GetService("ReplicatedStorage")
local Style = require(RS.Shared.Kit.Style)

local me = Players.LocalPlayer
local active = false
local POST = { BloomEffect = true, SunRaysEffect = true, DepthOfFieldEffect = true }
local switchedOff: { [PostEffect]: boolean } = {}
local atmo: { [Atmosphere]: { glare: number, haze: number } } = {}
local watched: { [Instance]: boolean } = {}

local function post(e: Instance)
	if POST[e.ClassName] then
		local fx = e :: PostEffect
		if active and fx.Enabled then switchedOff[fx] = true fx.Enabled = false end
		if not watched[fx] then
			watched[fx] = true
			-- the server (or an event look) may switch it back on: keep it off while lite
			fx:GetPropertyChangedSignal("Enabled"):Connect(function()
				if active and fx.Enabled then switchedOff[fx] = true fx.Enabled = false end
			end)
		end
	elseif e:IsA("Atmosphere") then
		local function trim()
			if not active then return end
			if not atmo[e] then atmo[e] = { glare = e.Glare, haze = e.Haze } end
			if e.Glare > 0 then e.Glare = 0 end
			if e.Haze > 1 then e.Haze = 1 end
		end
		trim()
		if not watched[e] then
			watched[e] = true
			e:GetPropertyChangedSignal("Glare"):Connect(trim)
			e:GetPropertyChangedSignal("Haze"):Connect(trim)
		end
	end
end

local function particles(e: Instance)
	if not e:IsA("ParticleEmitter") then return end
	if active and e:GetAttribute("LiteBaseRate") == nil then
		e:SetAttribute("LiteBaseRate", e.Rate)
		e:SetAttribute("LiteSetting", true)
		e.Rate = e.Rate * 0.5
		e:SetAttribute("LiteSetting", nil)
	end
	if not watched[e] then
		watched[e] = true
		-- scripts that set a new rate later get halved too (while lite)
		e:GetPropertyChangedSignal("Rate"):Connect(function()
			if not active or e:GetAttribute("LiteSetting") then return end
			e:SetAttribute("LiteSetting", true)
			e:SetAttribute("LiteBaseRate", e.Rate)
			e.Rate = e.Rate * 0.5
			e:SetAttribute("LiteSetting", nil)
		end)
	end
end

local function apply()
	if active then return end
	active = true
	me:SetAttribute("LiteGraphics", true) -- other client scripts can read this
	for _, e in Lighting:GetChildren() do post(e) end
	for _, e in workspace:GetDescendants() do particles(e) end
end

local function revert()
	if not active then return end
	active = false
	me:SetAttribute("LiteGraphics", nil)
	for fx in switchedOff do if fx.Parent then fx.Enabled = true end end
	table.clear(switchedOff)
	for a, o in atmo do if a.Parent then a.Glare = o.glare a.Haze = o.haze end end
	table.clear(atmo)
	for _, e in workspace:GetDescendants() do
		if e:IsA("ParticleEmitter") then
			local base = e:GetAttribute("LiteBaseRate")
			if type(base) == "number" then
				e:SetAttribute("LiteSetting", true)
				e.Rate = base
				e:SetAttribute("LiteSetting", nil)
				e:SetAttribute("LiteBaseRate", nil)
			end
		end
	end
end

Lighting.ChildAdded:Connect(post)
workspace.DescendantAdded:Connect(particles)
local function update()
	if Style.lite() then apply() else revert() end
end
me:GetAttributeChangedSignal("Set_Effects"):Connect(update)
update()
