--!strict
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Http=game:GetService("HttpService")
local Tags=game:GetService("CollectionService")
local Data=require(script.Parent.Kit.DataService)
local Net=require(RS.Shared.Net)
local S=require(RS.Shared.DailySpinConfig)
local R=require(RS.Shared.DailySpinRules)
local C=require(RS.Shared.CrusherConfig)
local Format=require(RS.Shared.Format)
local Spin={}
local rng=Random.new()
function Spin.start(api)
	local remote=Net.event("DailySpin")
	local busy={} local requested={} local bound=setmetatable({},{__mode="k"})
	local function description(out)
		if out.kind=="crusher" then return C.typeById(out.item.type).name.." ("..out.item.rarity..")" end
		if out.kind=="golden" then return out.amount.." Golden production bonuses" end
		if out.kind=="boost" then return "2x "..out.boost.." for "..out.amount.." minutes" end
		return Format.cash(out.amount).." cash"
	end
	local function send(p,open,message,result)
		local d=api.getData(p) if not d or not p.Parent then return end
		local rewards={}
		for _,def in S.Rewards do
			local text=if def.kind=="cash" then Format.cash(C.money(math.max(1,api.cashPerSecond(p))*def.seconds)).." cash"
				elseif def.kind=="boost" then "2x "..def.boost.." · "..def.minutes.." min"
				elseif def.kind=="golden" then def.count.." Golden bonuses" else def.rarity.." crusher"
			table.insert(rewards,{id=def.id,text=text,odds=S.odds(def.id)})
		end
		remote:FireClient(p,{open=open,message=message,result=result and {id=result.id,token=result.token,text=description(result)},
			nextAt=d.dailySpin.nextAt,pending=d.dailySpin.pending~=nil,rewards=rewards,paidEnabled=false})
	end
	local function handle(p,action,open)
		if busy[p] then return end
		local d=api.getData(p) if not d then return end
		if not Data.canSave(p) then send(p,open,"Daily Spin is unavailable until your profile can be saved.") return end
		busy[p]=true
		local ok,problem=xpcall(function()
			local state=d.dailySpin
			if action=="Spin" and not state.pending then
				local accepted,result=R.reserve(d,os.time(),api.cashPerSecond(p),function() return rng:NextNumber() end,function() return Http:GenerateGUID(false) end)
				if not accepted then send(p,open,result) return end
			end
			if state.pending then
				-- Persist outcome+cooldown before granting. On failure keep it pending:
				-- retry the same prize, never roll another or roll back an ambiguous write.
				if not Data.saveNow(p) then send(p,open,"Your prize is reserved. Reopen Daily Spin to retry saving it.") return end
				if not p.Parent then return end
				local delivered,result=R.deliver(d)
				if not delivered then send(p,open,result) return end
				d.stats=d.stats or {} d.stats.spins=(d.stats.spins or 0)+1 -- for quests
				local saved=Data.saveNow(p)
				if result.kind=="boost" then require(script.Parent.Boosts).add(p,result.boost,result.amount) end
				p:SetAttribute("GoldenRush",d.goldenRush) api.sync(p)
				send(p,open,if saved then "Reward granted!" else "Reward granted. Saving will retry automatically.",result)
			else send(p,open) end
		end,debug.traceback)
		busy[p]=nil
		if not ok then warn("Daily Spin: "..tostring(problem)) send(p,open,"Daily Spin could not finish. Reopen to recover your reserved prize.") end
	end
	remote.OnServerEvent:Connect(function(p,action)
		if action~="State" and action~="Spin" then return end -- no client reward IDs or paid path
		local now=os.clock() if now-(requested[p] or -math.huge)<.5 then return end requested[p]=now
		handle(p,action,false)
	end)
	local function bind(prompt)
		if not prompt:IsA("ProximityPrompt") or bound[prompt] then return end bound[prompt]=true
		prompt.Triggered:Connect(function(p)
			local part=prompt.Parent local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if part and part:IsA("BasePart") and root and (root.Position-part.Position).Magnitude<=prompt.MaxActivationDistance+4 then handle(p,"State",true) end
		end)
	end
	for _,prompt in Tags:GetTagged("DailySpinPrompt") do bind(prompt) end
	Tags:GetInstanceAddedSignal("DailySpinPrompt"):Connect(bind)
	Players.PlayerRemoving:Connect(function(p) requested[p]=nil end)
	local function recover(p) if api.whenLoaded(p) then handle(p,"State",false) end end
	Players.PlayerAdded:Connect(function(p) task.spawn(recover,p) end)
	for _,p in Players:GetPlayers() do task.spawn(recover,p) end
end
return Spin
