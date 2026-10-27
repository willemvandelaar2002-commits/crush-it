
-- Additional test surfaces only; the production modules below are unmodified.
local clock=1000
local warnings={}
local function warn(message) table.insert(warnings,message) end
local function signal()
	local s={listeners={}}
	function s:Connect(fn)
		local entry={fn=fn,live=true} table.insert(self.listeners,entry)
		return {Disconnect=function() entry.live=false end}
	end
	function s:Fire(...)
		for _,entry in table.clone(self.listeners) do if entry.live then entry.fn(...) end end
	end
	return s
end
local oldFind=methods.FindFirstChild
function methods:FindFirstChild(name,recursive)
	local result=oldFind(self,name) if result or not recursive then return result end
	for _,child in self.children do local found=child:FindFirstChild(name,true) if found then return found end end
	return nil
end
function methods:IsDescendantOf(parent)
	local node=self.Parent while node do if node==parent then return true end node=node.Parent end return false
end
function methods:ClearAllChildren() for _,child in self:GetChildren() do child:Destroy() end end
local oldCfIndex=fm.__index
function fm.__index(a,k)
	if k=='Rotation' then return cf(Vector3.zero,a.R) end
	if k=='RightVector' then return Vector3.new(a.R[1],a.R[4],a.R[7]) end
	if k=='LookVector' then return Vector3.new(-a.R[3],-a.R[6],-a.R[9]) end
	return oldCfIndex(a,k)
end
function fm.__add(a,v) return cf(a.Position+v,a.R) end
function fm.__sub(a,v) return cf(a.Position-v,a.R) end
function fm.__eq(a,b)
	if (a.Position-b.Position).Magnitude>1e-8 then return false end
	for i=1,9 do if math.abs(a.R[i]-b.R[i])>1e-8 then return false end end return true
end
local originalNew=Instance.new
function Instance.new(class)
	local o=originalNew(class) o.LocalTransparencyModifier=0 o.Enabled=true
	o.CFrame=CFrame.new() o.Size=Vector3.new(1,1,1) return o
end
local previousIm=im.__index
function im.__index(o,k)
	if k=='Position' then return o.CFrame.Position end
	return previousIm(o,k)
end
local ColorSequence={new=function(...) return {...} end}
local NumberSequence={new=function(...) return {...} end}
services.Players=Instance.new('Players') services.ServerStorage=Instance.new('ServerStorage')
services.RunService=Instance.new('RunService') services.HttpService=Instance.new('HttpService')
services.Players.PlayerRemoving=signal() services.RunService.Heartbeat=signal()
local players={}
function services.Players:GetPlayers() return table.clone(players) end
function services.RunService:IsStudio() return true end
local guidCount=0
function services.HttpService:GenerateGUID() guidCount+=1 return 'round-test-'..guidCount end
function services.Workspace:GetServerTimeNow() return clock end
local workspace=services.Workspace
game.ReplicatedStorage=services.ReplicatedStorage
game.HttpService=services.HttpService
local function encode(v)
	if type(v)~='table' then return type(v)..':'..tostring(v) end
	local keys={} for k in v do table.insert(keys,k) end
	table.sort(keys,function(a,b) return tostring(a)<tostring(b) end)
	local out={} for _,k in keys do table.insert(out,encode(k)..'='..encode(v[k])) end
	return '{'..table.concat(out,',')..'}'
end
local encodedValues={}
local function copy(v) if type(v)~='table' then return v end local out={} for k,x in v do out[k]=copy(x) end return out end
function services.HttpService:JSONEncode(v) local key=encode(v) encodedValues[key]=copy(v) return key end
function services.HttpService:JSONDecode(v) return copy(assert(encodedValues[v],'mock roundtrip only')) end
local queuedTasks={}
function task.spawn(fn,...) table.insert(queuedTasks,{fn=fn,args={...}}) end
local remotes={}
modules.Net={event=function(name)
	if not remotes[name] then
		local r={OnServerEvent=signal(),sent={}}
		function r:FireClient(p,value) self.sent[p]=value end
		remotes[name]=r
	end
	return remotes[name]
end}
local tagged={}
function services.CollectionService:GetTagged(tag) return tagged[tag] or {} end
function services.CollectionService:AddTag(model,tag) tagged[tag]=tagged[tag] or {} table.insert(tagged[tag],model) end
