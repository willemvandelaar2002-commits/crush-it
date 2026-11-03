--!strict
-- 3 Nov (vault: Mobile and Low-End Optimization, "what to cut on low tiers"; Willem:
-- phone sessions are shorter). On phones and tablets (touch, no keyboard) and on PCs
-- with graphics quality set to 1-3 (Style.lite), this client trims what costs the
-- most on a weak GPU and changes no gameplay information:
--   * screen post effects off: Bloom, SunRays, DepthOfField (full-screen passes)
--   * the Atmosphere's glare and haze lowered (less fill per pixel)
--   * every particle emitter in the world at half its rate
-- Everything is local to this player; the server's settings stay as they are.
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RS = game:GetService("ReplicatedStorage")
local Style = require(RS.Shared.Kit.Style)
if not Style.lite() then return end

local me = Players.LocalPlayer
me:SetAttribute("LiteGraphics", true) -- other client scripts can read this

local POST = { BloomEffect = true, SunRaysEffect = true, DepthOfFieldEffect = true }
local function post(e: Instance)
	if POST[e.ClassName] then
		local fx = e :: PostEffect
		fx.Enabled = false
		-- the server (or an event look) may switch it back on: keep it off here
		fx:GetPropertyChangedSignal("Enabled"):Connect(function() if fx.Enabled then fx.Enabled = false end end)
	elseif e:IsA("Atmosphere") then
		local function trim()
			if e.Glare > 0 then e.Glare = 0 end
			if e.Haze > 1 then e.Haze = 1 end
		end
		trim()
		e:GetPropertyChangedSignal("Glare"):Connect(trim)
		e:GetPropertyChangedSignal("Haze"):Connect(trim)
	end
end
for _, e in Lighting:GetChildren() do post(e) end
Lighting.ChildAdded:Connect(post)

local function particles(e: Instance)
	if e:IsA("ParticleEmitter") and e:GetAttribute("LiteBaseRate") == nil then
		e:SetAttribute("LiteBaseRate", e.Rate)
		e.Rate = e.Rate * 0.5
		-- scripts that set a new rate later get halved too
		e:GetPropertyChangedSignal("Rate"):Connect(function()
			local want = e:GetAttribute("LiteSetting")
			if want then return end
			e:SetAttribute("LiteSetting", true)
			e:SetAttribute("LiteBaseRate", e.Rate)
			e.Rate = e.Rate * 0.5
			e:SetAttribute("LiteSetting", nil)
		end)
	end
end
for _, e in workspace:GetDescendants() do particles(e) end
workspace.DescendantAdded:Connect(particles)
