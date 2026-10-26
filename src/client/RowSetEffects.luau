--!strict
-- Four client-only effect slots; no gameplay mutation, lights or hit audio.
-- Each full row gets: a rising light curtain per bay, dense sparkles over the
-- whole bay width and (for the two nearest rows, own plot first) a rarity
-- outline on every crusher. Highlights are capped at 12 for the 31 limit.
local E={}
local HIGHLIGHT_ROWS=2
local CURTAIN=9 -- studs the light curtain rises above the rail
local V,F=Vector3.new,CFrame.new
-- sparkles for every full rarity set (Common/Uncommon/Rare softer)
local palettes={Common=Color3.fromRGB(205,220,235),Uncommon=Color3.fromRGB(90,235,120),Rare=Color3.fromRGB(80,170,255),
	Epic=Color3.fromRGB(193,105,255),Legendary=Color3.fromRGB(255,204,62)}
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
			local host=part(folder,"SparkleHost",V(8.6,.1,1.2))
			local e=Instance.new("ParticleEmitter") e.Name="RowSparkles"
			e.Texture="rbxasset://textures/particles/sparkles_main.dds"
			e.Enabled=false e.Rate=0 e.Lifetime=NumberRange.new(1.2,1.9)
			e.Speed=NumberRange.new(2,3.6) e.Acceleration=V(0,.8,0)
			e.Shape=Enum.ParticleEmitterShape.Box e.ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume
			e.SpreadAngle=Vector2.new(12,12) e.EmissionDirection=Enum.NormalId.Top
			e.Rotation=NumberRange.new(0,360) e.RotSpeed=NumberRange.new(-40,40)
			e.LightEmission=1 e.LightInfluence=0 e.LockedToPart=false
			e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.2),NumberSequenceKeypoint.new(.3,.65),NumberSequenceKeypoint.new(1,0)})
			e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.12,0),NumberSequenceKeypoint.new(.7,.2),NumberSequenceKeypoint.new(1,1)})
			e.Parent=host slot.hosts[i]=host slot.emitters[i]=e
			-- light curtain: a flat glowing sheet rising from the rail, fading upward
			local a0=Instance.new("Attachment") a0.Parent=host
			local a1=Instance.new("Attachment") a1.Position=V(0,CURTAIN,0) a1.Parent=host
			local b=Instance.new("Beam") b.Name="RowCurtain" b.Attachment0=a0 b.Attachment1=a1
			b.Width0=8.6 b.Width1=8.6 b.FaceCamera=true b.LightEmission=1 b.LightInfluence=0 b.Segments=1 b.Enabled=false
			b.Parent=host slot.beams=slot.beams or {} slot.beams[i]=b
			local hl=Instance.new("Highlight") hl.Name="RowOutline" hl.Enabled=false hl.DepthMode=Enum.HighlightDepthMode.Occluded
			hl.FillTransparency=.7 hl.OutlineTransparency=0 hl.Parent=folder
			slot.outlines=slot.outlines or {} slot.outlines[i]=hl
		end
		slot.glint=part(folder,"EnergyGlint",V(.75,.30,.24))
		table.insert(self.slots,slot) return slot
	end
	local function release(slot)
		if slot.model then self.byModel[slot.model]=nil end
		slot.model=nil slot.rarity=nil slot.rails={} slot.glint.Transparency=1
		for _,e in slot.emitters do e.Enabled=false e:Clear() end
		for _,b in slot.beams do b.Enabled=false end
		for _,hl in slot.outlines do hl.Enabled=false hl.Adornee=nil end
	end
	-- the crusher standing at a rail (nearest bay of this row)
	local function crusherAt(model,rail)
		local plot=model.Parent local index=model:GetAttribute("RowIndex")
		if not plot or type(index)~="number" then return nil end
		local best,bestD=nil,math.huge
		for bay=(index-1)*6+1,index*6 do local m=plot:FindFirstChild("WorkingBay"..bay)
			if m and m:IsA("Model") then local d=(m:GetPivot().Position-rail.Position).Magnitude if d<bestD then best,bestD=m,d end end
		end
		return best and bestD<12 and best:FindFirstChild("EquippedCrusher") or nil
	end
	function self.forget(model) local slot=self.byModel[model] if slot then release(slot) end end
	function self.sync(ranked,now)
		local selected={} local count=0
		for _,candidate in ranked do local model=candidate.model
			if model:IsDescendantOf(world) and model:GetAttribute("RowSetActive") and palettes[model:GetAttribute("RowRarity")] then
				count+=1 selected[model]=candidate candidate.outline=count<=HIGHLIGHT_ROWS if count==4 then break end
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
					e.Rate=if rarity=="Legendary" then 16 elseif rarity=="Epic" then 12 else 8
				end
				for _,b in slot.beams do b.Color=ColorSequence.new(color:Lerp(white,.35),color) end
				for _,hl in slot.outlines do hl.FillColor=color hl.OutlineColor=color:Lerp(white,.45) end
			end
			local at=candidate.activatedAt local previous=history[model]
			local burst=at~=nil and (not previous or previous.activation~=at) and now>=at and now-at<=.8
				and (not previous or now-previous.lastBurst>=2.5)
			if #rails>0 and at~=nil then history[model]={activation=at,lastBurst=if burst then now else if previous then previous.lastBurst else -math.huge} end
			for i,e in slot.emitters do local rail=rails[i] e.Enabled=rail~=nil
				slot.beams[i].Enabled=rail~=nil
				local hl=slot.outlines[i] local target=if rail and candidate.outline then crusherAt(model,rail) else nil
				if hl.Adornee~=target then hl.Adornee=target end hl.Enabled=target~=nil
				if rail then
					local host=slot.hosts[i] host.Size=V(math.max(1,rail.Size.X),.1,1.2)
					host.CFrame=rail.CFrame*F(0,.2,0)
					slot.beams[i].Width0=rail.Size.X slot.beams[i].Width1=rail.Size.X
					if burst then e:Emit(if rarity=="Legendary" then 30 else 22) end
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
			-- breathing glow on curtains and outlines
			local wave=.5+.5*math.sin(now*2.4)
			local fade=NumberSequence.new({NumberSequenceKeypoint.new(0,.25+.2*(1-wave)),NumberSequenceKeypoint.new(.6,.7),NumberSequenceKeypoint.new(1,1)})
			for _,b in slot.beams do if b.Enabled then b.Transparency=fade end end
			for _,hl in slot.outlines do if hl.Enabled then hl.FillTransparency=.55+.25*(1-wave) end end
		end
	end
	function self.destroy()
		for _,slot in self.slots do release(slot) end folder:Destroy() table.clear(self.slots)
	end
	return self
end
return E
