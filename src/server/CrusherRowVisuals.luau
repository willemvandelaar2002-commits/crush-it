--!strict
-- Small world plaques and emissive row rails, independent of imported rigs.
local RS=game:GetService("ReplicatedStorage")
local Tags=game:GetService("CollectionService")
local C=require(RS.Shared.CrusherConfig)
local Rows=require(RS.Shared.CrusherRows)
local Style=require(RS.Shared.Kit.Style)
local W=require(script.Parent.Kit.CrusherWorkshop)
local V={Tag="CrusherRarityRow"}
function V.create(plot)
	plot.rarityRows={}
	for index=1,Rows.count() do
		local first=(index-1)*C.Layout.PerWing+1 local layout=C.bayLayout(first)
		local last=C.bayLayout(first+C.Layout.PerWing-1)
		local origin=plot.origin*C.bayFrame(layout)
		local model=Instance.new("Model") model.Name="RarityRow"..index model.Parent=plot.model
		model:SetAttribute("RowIndex",index) model:SetAttribute("RowSetActive",false)
		local record={model=model,rails={},aura={},first=first}
		for bay=first,first+C.Layout.PerWing-1 do local at=C.bayLayout(bay)
			local rail=W.part(model,"RarityRail",Vector3.new(C.Layout.BayWidth-1,.24,.18),
				origin*CFrame.new(at.x,at.y+C.Layout.Pedestal+.25,at.z+C.Layout.MachineZ+(C.Layout.MachineDepth+1)/2+.2),Style.Colors.Ink)
			rail.Material=Enum.Material.Neon rail.CastShadow=false rail.Transparency=1
			table.insert(record.rails,rail)
			-- Full-set aura (hidden until the row is complete): a glowing floor
			-- plate round the pedestal, two light pillars at the bay front and a
			-- glowing back panel with a light, all in the rarity colour.
			local L=C.Layout
			local bay=origin*CFrame.new(at.x,at.y,at.z)
			local function aura(name,size,cf,base)
				local a=W.part(model,"RowAura",size,cf,Style.Colors.Ink)
				a.Material=Enum.Material.Neon a.CastShadow=false a.Transparency=1 a:SetAttribute("Base",base) a:SetAttribute("Kind",name)
				table.insert(record.aura,a) return a
			end
			aura("Floor",Vector3.new(L.BayWidth-.6,.12,L.MachineDepth+2.2),bay*CFrame.new(0,.47,L.MachineZ),.15)
			for _,x in {-1,1} do
				aura("Pillar",Vector3.new(.35,L.TierHeight-3.2,.35),bay*CFrame.new(x*(L.BayWidth/2-.45),(L.TierHeight-3.2)/2+.5,L.BayDepth/2-.9),.2)
			end
			local back=aura("Back",Vector3.new(L.BayWidth-1.8,L.TierHeight-5.2,.12),bay*CFrame.new(0,(L.TierHeight-5.2)/2+.6,-L.BayDepth/2+.75),.45)
			local light=Instance.new("PointLight") light.Name="AuraLight" light.Range=14 light.Brightness=1.8 light.Enabled=false light.Parent=back
		end
		-- A low desk sign forward of the individual bay plaques. It has no
		-- buttons or queryable surface, so it cannot intercept their input.
		local cf=origin*CFrame.new((layout.x+last.x)/2,layout.y+.9,layout.z+C.Layout.BayDepth/2+5.8)
			*CFrame.Angles(math.rad(-66),0,0)
		local plate=W.part(model,"RowBonusPlaque",Vector3.new(18,2.5,.28),cf,Style.Colors.Ink)
		plate.Transparency=1
		local gui=W.sign(plate) gui.Enabled=false gui.LightInfluence=0
		local panel=Instance.new("Frame") panel.Name="RowStatus" panel.Size=UDim2.fromScale(1,1) panel.Parent=gui
		Style.panel(panel,Style.Colors.SteelDark)
		record.title=W.text(panel,"RowTitle","",UDim2.fromScale(.02,.03),UDim2.fromScale(.96,.5))
		record.detail=W.text(panel,"RowDetail","",UDim2.fromScale(.02,.55),UDim2.fromScale(.96,.4))
		record.plate=plate record.gui=gui record.panel=panel
		plot.rarityRows[index]=record Tags:AddTag(model,V.Tag)
	end
end
function V.sync(plot,snapshot)
	for index,record in plot.rarityRows or {} do
		local row=snapshot and snapshot.rows[index]
		local visible=row~=nil and row.unlocked>0
		local active=visible and row.active
		local title,detail="",""
		if visible then title,detail=Rows.label(row) end
		local signature=tostring(visible)..":"..title..":"..detail
		if record.signature==signature then continue end record.signature=signature
		local rarity=row and row.rarity and C.rarity(row.rarity)
		local color=if rarity then rarity.color else Style.Colors.Steel
		record.model:SetAttribute("RowSetActive",active==true)
		record.model:SetAttribute("RowRarity",if rarity then rarity.name else nil)
		record.model:SetAttribute("RowBonus",if active then row.bonus else 0)
		record.model:SetAttribute("RowMatches",if row then row.matches else 0)
		record.gui.Enabled=visible record.plate.Transparency=if visible then 0 else 1
		record.title.Text=title record.detail.Text=detail
		record.title.TextColor3=if rarity then color:Lerp(Color3.new(1,1,1),.25) else Color3.new(1,1,1)
		Style.panel(record.panel,if active then Style.darken(color,.15) else Style.Colors.SteelDark)
		for _,rail in record.rails do rail.Color=color rail.Transparency=if active then .18 else 1 end
		for _,a in record.aura do
			a.Color=color a.Transparency=if active then a:GetAttribute("Base") else 1
			local l=a:FindFirstChild("AuraLight") if l then l.Color=color l.Enabled=active==true end
		end
		for bay=record.first,record.first+C.Layout.PerWing-1 do local frame=plot.bays[bay]
			if active then frame.strip.Color=color
			elseif record.wasActive and frame.shown=="busy" then frame.strip.Color=Color3.fromRGB(255,244,214) end
		end
		record.wasActive=active
	end
end
return V
