--!strict
-- Pure derived state. No saved unlock flag, remote claims, or currency awards.
local C=require(script.Parent.CrusherConfig)
local R={}
function R.index(bay)
	return math.floor((bay-1)/C.Layout.PerWing)+1
end
function R.count() return math.ceil(C.MaxBays/C.Layout.PerWing) end
function R.snapshot(d)
	local s=d.crushers local owned={} local used={}
	local capacity=math.min(s.bays,C.bayCapacity(s.plotLevel))
	for _,item in s.owned do owned[item.id]=item end
	for bay=1,capacity do local id=s.equipped[tostring(bay)]
		if id then used[id]=(used[id] or 0)+1 end
	end
	local out={rows={},byItem={}}
	for index=1,R.count() do
		local first=(index-1)*C.Layout.PerWing+1 local last=first+C.Layout.PerWing-1
		local layout=C.bayLayout(first)
		local row={index=index,first=first,last=last,capacity=C.Layout.PerWing,filled=0,matches=0,
			unlocked=math.clamp(capacity-first+1,0,C.Layout.PerWing),active=false,bonus=0,multiplier=1,
			name=(if layout.tier==1 then "GROUND " elseif layout.tier==2 then "UPPER " else "TOP ")..(if layout.wing==1 then "LEFT" else "RIGHT")}
		if layout.rear then row.name="REAR "..(if layout.tier==2 then "UPPER " else "")..(if layout.wing==1 then "LEFT" else "RIGHT") end
		local counts={} local valid={}
		for bay=first,last do
			local id=if bay<=capacity then s.equipped[tostring(bay)] else nil
			local item=id and owned[id] local rarity=item and C.rarityOf(item.type)
			-- Corrupt duplicate equipment or a mismatched saved rarity cannot
			-- activate a set. Ordinary transactions/migration already forbid these.
			if item and used[id]==1 and rarity and item.rarity==rarity.name then
				row.filled+=1 counts[rarity.name]=(counts[rarity.name] or 0)+1
				table.insert(valid,item.id)
			end
		end
		local rank=-1
		for _,rarity in C.Rarities do local n=counts[rarity.name] or 0
			if n>row.matches or (n==row.matches and n>0 and rarity.rank>rank) then
				row.matches=n row.rarity=rarity.name rank=rarity.rank
			end
		end
		row.active=row.unlocked==row.capacity and row.matches==row.capacity
		if row.active then row.bonus=C.RowBonuses[row.rarity] or 0 row.multiplier=1+row.bonus end
		row.targetBonus=if row.rarity then C.RowBonuses[row.rarity] or 0 else 0
		out.rows[index]=row
		for _,id in valid do out.byItem[id]=row end
	end
	return out
end
function R.multiplier(snapshot,id)
	local row=id and snapshot.byItem[id]
	return if row then row.multiplier else 1
end
function R.label(row)
	if row.active then return string.upper(row.rarity).." ROW "..row.capacity.."/"..row.capacity, "+"..math.floor(row.bonus*100+.5).."% SCRAP · ACTIVE" end
	if row.rarity then return string.upper(row.rarity).." SET "..row.matches.."/"..row.capacity,
		"MATCH "..row.capacity.." RARITIES FOR +"..math.floor(row.targetBonus*100+.5).."% SCRAP" end
	return "MATCH A ROW · 0/"..row.capacity,"SAME RARITY · DIFFERENT CRUSHERS WELCOME"
end
return R
