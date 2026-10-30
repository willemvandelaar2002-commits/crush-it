--!strict
-- Presentation only: prices, production and ownership remain in Config/Rules.
local C=require(script.Parent.CrusherConfig)
local Rules=require(script.Parent.CrusherRules)
local Format=require(script.Parent.Format)
local V={}
V.Colors={Ready=Color3.fromRGB(45,230,45),Short=Color3.fromRGB(104,116,138),Max=Color3.fromRGB(77,91,115)}
V.Boards={
	Production={heading="FACTORY UPGRADES",scope="ALL YOUR CRUSHERS",success="FACTORY +1!"},
	Rolling={heading="ROLL UPGRADES",scope="FUTURE ROLLS",success="ROLLING +1!"},
}

function V.purchase(cash,cost,maxed,hint,success)
	local state=if maxed then "Max" elseif cash>=cost then "Ready" else "Short"
	return {state=state,cost=cost,button="",effect="",hint=if maxed then "Maximum level reached." elseif state=="Short" then
		"Need "..Format.cash(math.ceil(cost-cash)).." more. Collect and sell scrap. "..hint else hint,success=success}
end

local function uncommonChance(level,lucky)
	local weights=Rules.weights(level,lucky) local total,special=0,0
	for i,w in weights do total+=w if C.Rarities[i].rank>0 then special+=w end end
	return special/total*100
end

function V.board(d,id,perks)
	local u=C.Upgrades[id] local lv=d.crushers.upgrades[id] local max=C.upgradeMax(id,d.crushers.plotLevel)
	local n=math.min(max,lv+1) local maxed=lv>=max local effect
	if id=="Damage" then
		effect=if maxed then string.format("Damage x%.2f",C.DamageFactor^lv) else string.format("x%.2f > x%.2f damage",C.DamageFactor^lv,C.DamageFactor^n)
	elseif id=="Speed" then
		-- Cycle duration, not an incorrectly labelled attack-rate percentage.
		effect=if maxed then string.format("Cycle %.0f%%",C.SpeedFactor^lv*100) else string.format("Cycle %.0f%% > %.0f%%",C.SpeedFactor^lv*100,C.SpeedFactor^n*100)
	elseif id=="Yield" then
		effect=if maxed then string.format("Scrap x%.1f",1+C.YieldPerLevel*lv) else string.format("x%.1f > x%.1f scrap",1+C.YieldPerLevel*lv,1+C.YieldPerLevel*n)
	elseif id=="Luck" then
		local lucky=perks and perks.lucky
		effect=if maxed then string.format("Uncommon+ %.1f%%",uncommonChance(lv,lucky)) else string.format("Uncommon+ %.1f%% > %.1f%%",uncommonChance(lv,lucky),uncommonChance(n,lucky))
	else
		effect=if maxed then C.pedestals(lv).." choices / roll" else C.pedestals(lv).." > "..C.pedestals(n).." choices / roll"
	end
	local hint=if id=="Luck" then "Changes future roll odds; owned crushers keep their rarity."
		elseif id=="Pedestals" then "More offers per free roll; each crusher still costs cash to buy."
		elseif id=="Speed" then "Shorter strike cycles for every crusher you own or equip later."
		else "Applies to every crusher you own or equip later."
	local view=V.purchase(d.cash,C.globalCost(id,lv),maxed,hint,V.Boards[u.group].success)
	if maxed and not u.max then view.hint=Rules.capMessage(d.crushers.plotLevel) end
	view.effect=effect
	view.button=if maxed then "MAX\nLV "..lv else "LV "..lv.." > "..n.."\n"..Format.cash(view.cost)
	return view
end

function V.crusher(d,item,perks)
	local maxed=item.level>=C.levelCap(d.crushers.plotLevel) local current=Rules.stats(d,item,perks)
	local view=V.purchase(d.cash,C.individualCost(item),maxed,
		"Only this crusher. Its level stays with it when swapped.","CRUSHER +1!")
	if maxed then view.hint=Rules.capMessage(d.crushers.plotLevel) end
	if maxed then
		view.effect="LV "..item.level.."  MAX\n"..Format.cash(current.cps*60).."/min"
	else
		local nextItem=table.clone(item) nextItem.level+=1
		local nextStats=Rules.stats(d,nextItem,perks)
		view.effect="LV "..item.level.." > "..nextItem.level.."\n"..Format.cash(current.cps*60).." > "..Format.cash(nextStats.cps*60).."/min"
	end
	view.button=if maxed then "MAX\nLEVEL" else "LEVEL UP\n"..Format.cash(view.cost)
	view.short="LV "..item.level.." · "..Format.cash(current.cps*60).."/min" -- compact plaque line
	return view
end
-- MAX on the plaque: as many LEVEL UPs for this crusher as the cash covers.
function V.crusherMax(d,item)
	local cap=C.levelCap(d.crushers.plotLevel)
	local maxed=item.level>=cap
	local n,total=Rules.maxLevels(d.cash,item,cap)
	-- with n>0 the cash covers total (Ready); with n=0 it misses the next level (Short)
	local cost=if n>0 then total else C.individualCost(item)
	local view=V.purchase(d.cash,cost,maxed,"Spends your cash on as many levels for this crusher as it can.","CRUSHER +"..math.max(n,1).."!")
	if maxed then view.hint=Rules.capMessage(d.crushers.plotLevel) end
	view.button=if maxed then "MAX" else "MAX\n+"..n
	return view
end
return V
