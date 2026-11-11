--!strict
-- 11 Nov: puts a PLOT STYLE (Shared/PlotStyles) on a plot. For now the style's palette
-- recolours the Classic look: floor tops (through PlotStages.sync), the trim studs and
-- collars, the rim blocks and corners, the lamp posts' caps and lights. Willem's kit per
-- style (CornerBrace_<Style> etc.) slots in later. Classic puts the authored colours back.
local Styles = require(game:GetService("ReplicatedStorage").Shared.PlotStyles)
local Stages = require(script.Parent.PlotStages)

local L = {}
local RIM = { RimBlock = "rim", RimCorner = "rim", LampCap = "trim", LampPost = "rim", LampLight = "lamp" }

function L.apply(plot: any, id: string)
	local st = Styles.ById[id] or Styles.ById[Styles.Default]
	plot.styleId = st.id
	plot.stylePalette = st.palette -- read by PlotStages.sync (floors, trim)
	local pal = st.palette
	for _, p in plot.model:GetDescendants() do
		if p:IsA("BasePart") and RIM[p.Name] and p.Parent and p.Parent.Name == "PlotBorder" then
			if p:GetAttribute("StyleColor") == nil then p:SetAttribute("StyleColor", p.Color) end
			p.Color = if pal then (pal :: any)[RIM[p.Name]] else p:GetAttribute("StyleColor") :: Color3
			for _, l in p:GetChildren() do
				if l:IsA("Light") then
					if l:GetAttribute("StyleColor") == nil then l:SetAttribute("StyleColor", l.Color) end
					l.Color = if pal then pal.lamp else l:GetAttribute("StyleColor") :: Color3
				end
			end
		end
	end
	-- the stage look again at the same level, now with this palette
	local v = plot.stages
	if v and v.level and v.level >= 0 then
		local level = v.level
		v.level = -1
		Stages.sync(plot, level)
	end
end

return L
