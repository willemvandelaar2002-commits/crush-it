--!strict
-- Four client-only effect slots; no gameplay mutation, lights or hit audio.
local E={}
local V,F=Vector3.new,CFrame.new
local palettes={Epic=Color3.fromRGB(193,105,255),Legendary=Color3.fromRGB(255,204,62)}
local white=Color3.new(1,1,1)
local function part(parent,name,size)
	local p=Instance.new("Part") p.Name=name p.Size=size p.Anchored=true
	p.Transparency=1 p.CanCollide=false p.CanTouch=false p.CanQuery=false
	p.CastShadow=false p.Material=Enum.Material.Neon p.Parent=parent return p
end
function E.new(world)
	local self={slots={},byModel={}}
	local history=setmetatable({}, {__mode="k"})
	local folder=Instance.new("Folder") folder.Name="RarityRowEffects" folder.Parent=world
	local function build()
		local slot={hosts={},emitters={},rails={},model=nil}
		for i=1,6 do
			local host=part(folder,"SparkleHost",V(.35,.1,.35))
			local e=Instance.new("ParticleEmitter") e.Name="RowSparkles"
			e.Texture="rbxasset://textures/particles/sparkles_main.dds"
			e.Enabled=false e.Rate=0 e.Lifetime=NumberRange.new(.7,1.25)
			e.Speed=NumberRange.new(.5,1.1) e.Acceleration=V(0,.35,0)
			e.SpreadAngle=Vector2.new(22,22) e.EmissionDirection=Enum.NormalId.Top
			e.Rotation=NumberRange.new(0,360) e.RotSpeed=NumberRange.new(-30,30)
			e.LightEmission=1 e.LightInfluence=0 e.LockedToPart=false
			e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.10),NumberSequenceKeypoint.new(.3,.30),NumberSequenceKeypoint.new(1,0)})
			e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.15,.12),NumberSequenceKeypoint.new(.7,.3),NumberSequenceKeypoint.new(1,1)})
			e.Parent=host slot.hosts[i]=host slot.emitters[i]=e
		end
		slot.glint=part(folder,"EnergyGlint",V(.75,.30,.24))
		table.insert(self.slots,slot) return slot
	end
	local function release(slot)
		if slot.model then self.byModel[slot.model]=nil end
		slot.model=nil slot.rarity=nil slot.rails={} slot.glint.Transparency=1
		for _,e in slot.emitters do e.Enabled=false e:Clear() end
	end
	function self.forget(model) local slot=self.byModel[model] if slot then release(slot) end end
	function self.sync(ranked,now)
		local selected={} local count=0
		for _,candidate in ranked do local model=candidate.model
			if model:IsDescendantOf(world) and model:GetAttribute("RowSetActive") and palettes[model:GetAttribute("RowRarity")] then
				count+=1 selected[model]=candidate if count==4 then break end
			end
		end
		for model,slot in self.byModel do if not selected[model] then release(slot) end end
		for model,candidate in selected do
			local slot=self.byModel[model]
			if not slot then
				for _,free in self.slots do if not free.model then slot=free break end end
				slot=slot or build() slot.model=model self.byModel[model]=slot
			end
			local rarity=model:GetAttribute("RowRarity") local color=palettes[rarity]
			local rails={}
			for _,p in model:GetChildren() do if p:IsA("BasePart") and p.Name=="RarityRail" then table.insert(rails,p) end end
			if #rails>1 then local axis=rails[1].CFrame.RightVector
				table.sort(rails,function(a,b) return a.Position:Dot(axis)<b.Position:Dot(axis) end)
			end
			slot.rails=rails
			if slot.rarity~=rarity then
				slot.rarity=rarity slot.glint.Color=color:Lerp(white,.65)
				for _,e in slot.emitters do e:Clear() e.Color=ColorSequence.new(color:Lerp(white,.5),color)
					e.Rate=if rarity=="Legendary" then 3 else 1.8
				end
			end
			local at=candidate.activatedAt local previous=history[model]
			local burst=at~=nil and (not previous or previous.activation~=at) and now>=at and now-at<=.8
				and (not previous or now-previous.lastBurst>=2.5)
			if #rails>0 and at~=nil then history[model]={activation=at,lastBurst=if burst then now else if previous then previous.lastBurst else -math.huge} end
			for i,e in slot.emitters do local rail=rails[i] e.Enabled=rail~=nil
				if rail then slot.hosts[i].CFrame=F(rail.Position+V(0,.2,0))
					if burst then e:Emit(if rarity=="Legendary" then 5 else 4) end
				else e:Clear() end
			end
		end
	end
	function self.step(now)
		for model,slot in self.byModel do
			if not model:IsDescendantOf(world) or not model:GetAttribute("RowSetActive") or not palettes[model:GetAttribute("RowRarity")] then release(slot) continue end
			local rails=slot.rails local n=math.min(6,#rails)
			for i,e in slot.emitters do if not rails[i] or not rails[i].Parent then e.Enabled=false e:Clear() end end
			if n==0 then slot.glint.Transparency=1 continue end
			local phase=(now*.45)%1*n local rail=rails[math.floor(phase)+1]
			if not rail.Parent then slot.glint.Transparency=1 continue end
			slot.glint.CFrame=rail.CFrame*F(((phase%1)-.5)*rail.Size.X,.04,.06) slot.glint.Transparency=.12
		end
	end
	function self.destroy()
		for _,slot in self.slots do release(slot) end folder:Destroy() table.clear(self.slots)
	end
	return self
end
return E
