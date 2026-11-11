--!strict
-- 11 Nov (audit 7, vault: Streaming and instance count): hidden plot parts leave the
-- Workspace. Every plot is built in full at start (later floors, stage walls, props,
-- the rear yard) and the parts not reached yet used to be made invisible in place, so
-- every client still loaded them: an empty plot was 7,300 instances, 2,800 of them
-- invisible. Now hiding a model moves it into ServerStorage.PlotStash (clients don't
-- get it at all) and showing it puts it back under its own parent. The server keeps
-- the same instances, so references, prompts and connections keep working.
-- Clients see a hidden model leave and come back like streaming out and in.
local ServerStorage = game:GetService("ServerStorage")

local S = {}
local home: { [Instance]: Instance } = setmetatable({}, { __mode = "k" }) :: any
local folder = ServerStorage:FindFirstChild("PlotStash") or Instance.new("Folder")
folder.Name = "PlotStash"
folder.Parent = ServerStorage

function S.hide(model: Instance)
	if home[model] or not model.Parent or model.Parent == folder then return end
	home[model] = model.Parent
	model.Parent = folder
end
function S.show(model: Instance)
	local parent = home[model]
	if not parent then return end
	home[model] = nil
	model.Parent = parent
end
function S.set(model: Instance, visible: boolean)
	if visible then S.show(model) else S.hide(model) end
end
function S.hidden(model: Instance): boolean return home[model] ~= nil end

-- does this stashed model belong under root (through any stashed parents)?
local function under(model: Instance, root: Instance): boolean
	local at: Instance? = home[model]
	while at do
		if at == root or at:IsDescendantOf(root) then return true end
		at = home[at]
	end
	return false
end
-- root:GetDescendants() plus the descendants of root's stashed models
function S.descendants(root: Instance): { Instance }
	local out = root:GetDescendants()
	for model in home do
		if model.Parent == folder and under(model, root) then
			table.insert(out, model)
			for _, d in model:GetDescendants() do table.insert(out, d) end
		end
	end
	return out
end

return S
