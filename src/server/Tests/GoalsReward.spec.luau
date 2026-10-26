--!strict
-- Pure gate and client lifecycle checks; no live saves or Roblox prompts.
return function()
	local G=require(script.Parent.Parent.GoalsReward)
	local F=require(game.StarterPlayer.StarterPlayerScripts.Client.FavoriteGoal)
	local checks=0
	local function check(value,message) checks+=1 assert(value,message) end
	for _,favorite in {false,true} do for _,group in {false,true} do
		local ctx={favoriteConfirmed=favorite,inGroup=group}
		local d={cash=100,timeSkipAt=0}
		local expected=favorite and group
		check(G.view(ctx,d,1000).canClaim==expected,"claim requires BOTH flags")
		local ok=G.claim(ctx,d,1000,500,86400,math.floor)
		check(ok==expected,"server reward matches gate")
		check(d.cash==(if expected then 600 else 100),"no premature reward")
		check(d.timeSkipAt==(if expected then 87400 else 0),"no premature cooldown")
	end end
	local ctx={inGroup=true} local d={cash=100,timeSkipAt=0}
	check(not G.confirmFavorite(ctx,"unsolicited",1),"unsolicited confirmation refused")
	G.beginFavorite(ctx,"one",1)
	G.beginFavorite(ctx,"replacement",2)
	check(ctx.favoriteChallenge.token=="one","repeated start retains live challenge")
	check(not G.confirmFavorite(ctx,true,3),"boolean cannot masquerade as token")
	check(not G.confirmFavorite(ctx,"wrong",3),"wrong token refused")
	check(not G.confirmFavorite({},"one",3),"another session can't use the challenge")
	check(not G.confirmFavorite(ctx,"one",121),"expired challenge refused")
	G.beginFavorite(ctx,"two",122)
	check(G.confirmFavorite(ctx,"two",123),"matching live confirmation accepted")
	check(not G.confirmFavorite(ctx,"two",123),"confirmation is one use")
	check(G.claim(ctx,d,1000,500,86400,math.floor),"both complete can claim")
	check(not G.claim(ctx,d,1000,500,86400,math.floor) and d.cash==600,"repeated claim cannot pay twice")
	check(not G.claim(ctx,d,87399.99,500,86400,math.floor),"cooldown boundary enforced")
	check(G.claim(ctx,d,87400,500,86400,math.floor) and d.cash==1100,"ready cooldown allows next existing reward")
	local saved={cash=d.cash,timeSkipAt=d.timeSkipAt}
	check(not G.view({},saved,87400).canClaim,"favorite isn't silently granted by rejoining")
	ctx.inGroup=false
	check(not G.claim(ctx,d,180000,500,86400,math.floor) and d.cash==1100,"fresh negative membership blocks reward")

	local function fixture(read,promptThrows)
		local api={calls={},notices={},timers={},success="Success",placeId=123,itemType="Asset",prompts=0}
		local listener
		api.service={PromptSetFavoriteCompleted={Connect=function(_,callback)
			listener=callback return {Disconnect=function() listener=nil end}
		end}}
		function api.service:GetFavoriteAsync(place,kind) check(place==123 and kind=="Asset","read targets this place") return read() end
		function api.service:PromptSetFavorite(place,kind,value)
			check(place==123 and kind=="Asset" and value==true,"prompt targets favorite, not unfavorite")
			api.prompts+=1 if promptThrows then error("prompt failure") end
		end
		api.act=function(name,args) table.insert(api.calls,{name=name,args=args}) end
		api.notice=function(message) table.insert(api.notices,message) end
		api.spawn=function(fn) fn() end
		api.later=function(seconds,fn) table.insert(api.timers,{seconds=seconds,fn=fn}) end
		api.emit=function(result) if listener then listener(result) end end
		return F.new(api),api
	end
	for _,result in {"Cancel","Failed","PermissionDenied"} do
		local f,a=fixture(function() return false end)
		f:request() f:request()
		check(#a.calls==1 and a.calls[1].name=="FavoriteStart","repeated click cannot create multiple prompts")
		a.emit("Success") check(#a.calls==1,"unrelated completion ignored before own prompt")
		f:update({favorite=false,favoriteToken="token"})
		check(a.prompts==1 and #a.calls==1,"opening prompt alone never confirms")
		a.emit(result)
		check(#a.calls==1 and not f.busy,"cancel/error never confirms")
		f:Destroy()
	end
	local f,a=fixture(function() return false end)
	f:request() f:update({favorite=false,favoriteToken="ok"}) a.emit("Success")
	check(#a.calls==2 and a.calls[2].name=="FavoriteConfirmed" and a.calls[2].args.token=="ok","real success reports exact challenge")
	a.emit("Success") check(#a.calls==2,"success event can't replay acknowledgement")
	f:update({favorite=true}) f:request()
	check(#a.calls==2,"complete goal does not reprompt")
	f:Destroy()
	f,a=fixture(function() return true end)
	f:request() f:update({favorite=false,favoriteToken="already"})
	check(a.prompts==0 and a.calls[2].args.token=="already","existing favorite completes without undoing it")
	f:Destroy()
	f,a=fixture(function() error("read not permitted") end)
	f:request() f:update({favorite=false,favoriteToken="fallback"})
	check(a.prompts==1 and #a.calls==1,"unavailable favorite read falls back without granting")
	a.emit("Success") check(#a.calls==2,"fallback still requires actual success")
	f:Destroy()
	f,a=fixture(function() return false end,true)
	f:request() f:update({favorite=false,favoriteToken="error"})
	check(#a.calls==1 and not f.busy,"prompt exception leaves goal incomplete") f:Destroy()
	f,a=fixture(function() return false end)
	f:request() a.timers[1].fn()
	check(not f.busy and #a.calls==1,"missing server response times out without granting") f:Destroy()
	f,a=fixture(function() return false end)
	f:request() f:update({favorite=false,favoriteToken="timeout"})
	a.timers[#a.timers].fn() a.emit("Success")
	check(not f.busy and #a.calls==1,"late result after timeout cannot confirm")
	f:Destroy() f:Destroy() f:request() a.emit("Success")
	check(#a.calls==1,"destroy disconnects and prevents new actions")
	-- Async favorite read completing after destruction cannot report success.
	f,a=fixture(function() return true end)
	local deferred a.spawn=function(fn) deferred=fn end
	f:request() f:update({favorite=false,favoriteToken="removed"}) f:Destroy() deferred()
	check(#a.calls==1,"removed controller cannot finish deferred work")
	print("GoalsReward:",checks,"checks passed")
	return checks
end
