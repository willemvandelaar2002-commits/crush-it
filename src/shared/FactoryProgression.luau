--!strict
-- Non-yielding transactions. Server supplies held ID, clock and quote token.
local C=require(script.Parent.CrusherConfig)
local Rows=require(script.Parent.CrusherRows)
local P={}
local function level(d)
	local n=d.crushers.plotLevel
	if type(n)~="number" or n~=n or math.abs(n)==math.huge then return 0 end
	return math.clamp(math.floor(n),0,C.PlotUpgrade.MaxLevel)
end
function P.level(d) return level(d) end
-- Every bay the current plot level has (24, then 30) holds a crusher:
-- the next plot upgrade can be bought.
function P.full(d)
	local need=C.bayCapacity(level(d))
	if d.crushers.bays<need then return false end
	local state=Rows.snapshot(d)
	for i=1,need/C.Layout.PerWing do if state.rows[i].filled<C.Layout.PerWing then return false end end
	return true
end
function P.needed(d) return C.bayCapacity(level(d)) end
function P.expand(d)
	local now=level(d)
	if now>=C.PlotUpgrade.MaxLevel then return false,"Your plot is fully expanded." end
	if not P.full(d) then return false,"Fill all "..P.needed(d).." bays before upgrading your plot." end
	local cost=C.plotCost(now+1)
	if d.cash<cost then return false,"Not enough cash for the plot upgrade." end
	d.cash=C.money(d.cash-cost)
	d.crushers.plotLevel=now+1 d.crushers.bays=C.bayCapacity(now+1)
	return true,"Done!"
end
function P.recipe(name) for _,r in C.Coatings do if r.name==name then return r end end end
local function find(d,id) for _,v in d.crushers.owned do if v.id==id then return v end end end
function P.cost(item,name)
	local recipe=P.recipe(name)
	return if recipe then math.floor(C.rarity(item.rarity).price*recipe.factor*(1+.15*(item.level-1))) else nil
end
function P.quote(d,id,name,now,token)
	if level(d)<1 then return nil,"Upgrade your plot to unlock the Coating Lab." end
	local item=find(d,id)
	if not item then return nil,"Hold one of your unequipped crushers first." end
	for _,equipped in d.crushers.equipped do if equipped==id then return nil,"Unequip this crusher before coating it." end end
	local target=P.recipe(name) local current=C.modifier(item.modifier)
	if not target or not current then return nil,"Unknown coating." end
	if C.modifier(name).mult<=current.mult then return nil,"Choose a stronger finish; nothing was charged." end
	return {id=id,target=name,old=item.modifier,level=item.level,cost=P.cost(item,name),token=token,expires=now+C.CoatingQuoteSeconds}
end
function P.apply(d,quote,token,held,now)
	if not quote or type(token)~="string" or quote.token~=token then return false,"Select a coating and review its preview first." end
	if now>=quote.expires then return false,"Preview expired. Select the coating again." end
	if held~=quote.id then return false,"Keep holding the crusher shown in the preview." end
	local fresh,problem=P.quote(d,held,quote.target,now,token)
	if not fresh then return false,problem end
	if fresh.old~=quote.old or fresh.level~=quote.level or fresh.cost~=quote.cost then return false,"Crusher changed. Request a fresh preview." end
	if d.cash<fresh.cost then return false,"Not enough cash for this coating." end
	local item=find(d,held)
	d.cash=C.money(d.cash-fresh.cost) item.modifier=fresh.target
	return true,"Done!"
end
return P
