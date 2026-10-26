--!strict
-- Pure claim gate. Favorite completion is a CLIENT ASSERTION tied to a short
-- session challenge, not independent Roblox server proof. Group checks stay
-- server-side. Nothing is persisted except the existing reward cooldown.
local G={}
function G.beginFavorite(ctx,token,now)
	if ctx.favoriteConfirmed then return end
	if not ctx.favoriteChallenge or now>=ctx.favoriteChallenge.expires then
		ctx.favoriteChallenge={token=token,expires=now+120}
	end
end
function G.validFavorite(ctx,token,now)
	local challenge=ctx.favoriteChallenge
	return not ctx.favoriteConfirmed and type(token)=="string" and challenge~=nil
		and token==challenge.token and now<challenge.expires
end
function G.confirmFavorite(ctx,token,now)
	if not G.validFavorite(ctx,token,now) then return false end
	ctx.favoriteConfirmed=true ctx.favoriteChallenge=nil return true
end
function G.view(ctx,d,now)
	local favorite=ctx.favoriteConfirmed==true local group=ctx.inGroup==true
	local left=math.max(0,math.ceil((d.timeSkipAt or 0)-now))
	local reason=if not favorite then "Favorite the game first, then join the group."
		elseif not group then "Join the group to complete both goals."
		elseif left>0 then "Your next free time skip isn't ready yet." else nil
	local challenge=ctx.favoriteChallenge
	return {favorite=favorite,inGroup=group,left=left,canClaim=reason==nil,reason=reason,
		favoriteToken=if challenge and now<challenge.expires then challenge.token else nil}
end
function G.claim(ctx,d,now,reward,cooldown,money)
	local view=G.view(ctx,d,now)
	if not view.canClaim then return false,view.reason end
	-- No yielding between the last gate and both saved mutations.
	d.cash=money(d.cash+reward) d.timeSkipAt=now+cooldown
	return true
end
return G
