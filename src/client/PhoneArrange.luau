--!strict
-- 4 Nov (vault: Case Study - Phone UI Overhaul, "per-screen phone arrangements, with exact
-- restore"): a tiny helper for menus that get their own phone layout.
--   local A = PhoneArrange.new(function(set) ...phone values via set(obj, {Prop = value})... end)
-- On compact screens (Style.compact) the arrange function runs; every property it changes
-- is remembered first and put back exactly when the screen is big again (window resize,
-- Studio device emulator). A.on tells whether the phone layout is active.
local RS = game:GetService("ReplicatedStorage")
local Style = require(RS.Shared.Kit.Style)

local P = {}

export type Arranger = { on: boolean, apply: () -> () }

function P.new(arrange: (set: (Instance, { [string]: any }) -> ()) -> (), onChange: ((boolean) -> ())?): Arranger
	local saved: { [Instance]: { [string]: any } } = {}
	-- keys starting with "@" are attributes (e.g. "@FitHeight"); `false` stands for "no value"
	local function get(g: Instance, k: string): any
		if k:sub(1, 1) == "@" then local v = g:GetAttribute(k:sub(2)) return if v == nil then false else v end
		return (g :: any)[k]
	end
	local function put(g: Instance, k: string, v: any)
		if k:sub(1, 1) == "@" then g:SetAttribute(k:sub(2), if v == false then nil else v) else (g :: any)[k] = v end
	end
	local function set(g: Instance, props: { [string]: any })
		local keep = saved[g] or {}
		saved[g] = keep
		for k, v in props do
			if keep[k] == nil then keep[k] = get(g, k) end
			put(g, k, v)
		end
	end
	local self: Arranger = { on = false, apply = function() end }
	function self.apply()
		local want = Style.compact()
		if want then
			arrange(set)
		else
			for g, keep in saved do for k, v in keep do put(g, k, v) end end
			table.clear(saved)
		end
		local changed = want ~= self.on
		self.on = want
		if changed and onChange then onChange(want) end
	end
	self.apply()
	local last = Style.compact()
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		local now = Style.compact()
		if now ~= last then last = now self.apply() end
	end)
	return self
end

return P
