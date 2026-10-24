--!strict
-- A separate script context can clean pools after CrusherFeel is destroyed.
-- An owner's own Destroying callback is not reliable under deferred signals.
local Run=game:GetService("RunService")
local watched={}
local function watch(v)
	if v:IsA("Folder") and v.Name=="LocalCrusherFeedback" then watched[v]=true end
end
for _,v in workspace:GetChildren() do watch(v) end
workspace.ChildAdded:Connect(watch)
local last=0
Run.Heartbeat:Connect(function()
	if os.clock()-last<.1 then return end last=os.clock()
	for folder in watched do
		if not folder.Parent then watched[folder]=nil continue end
		local ref=folder:FindFirstChild("FeedbackOwner")
		if not ref or not ref:IsA("ObjectValue") then continue end
		local owner=ref.Value
		if not owner or not owner:IsA("LocalScript") or not owner:IsDescendantOf(game) or not owner.Enabled
			or owner:GetAttribute("FeedbackRun")~=folder:GetAttribute("FeedbackRun") then
			local mixer=folder:FindFirstChild("FeedbackMixer")
			if mixer and mixer:IsA("ObjectValue") and mixer.Value then mixer.Value:Destroy() end
			watched[folder]=nil folder:Destroy()
		end
	end
end)
