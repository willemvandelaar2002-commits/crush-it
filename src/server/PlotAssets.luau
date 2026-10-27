--!strict
-- Willem's Blender plot models (coating booth and props). Templates live in the
-- place file, NOT in Git: ServerStorage.PlotAssets.<Name>, set up in Studio
-- (scaled to studs, anchored, non-colliding, pivot at the bottom centre with
-- the model's front along the pivot's LookVector) and marked Ready=true.
-- Missing or not-ready templates return nil, so callers keep their code-built
-- fallback.
local ServerStorage=game:GetService("ServerStorage")
local A={}

function A.template(name: string): Model?
	local folder=ServerStorage:FindFirstChild("PlotAssets")
	local t=folder and folder:FindFirstChild(name)
	if t and t:IsA("Model") and t:GetAttribute("Ready")==true then return t end
	return nil
end

-- Clone a template so it stands on cf's floor point, its front facing cf's
-- LookVector. Adds one invisible solid box (its footprint, a little smaller)
-- so players can't walk through it; the meshes themselves never collide.
function A.place(name: string, parent: Instance, cf: CFrame, opts: {solid: boolean?, inset: number?}?): Model?
	local t=A.template(name) if not t then return nil end
	opts=opts or {}
	local holder=Instance.new("Model") holder.Name=name holder.Parent=parent
	local m=t:Clone() m:SetAttribute("Ready",nil)
	for _,p in m:GetDescendants() do
		if p:IsA("BasePart") then p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false end
	end
	m:PivotTo(cf)
	m.Parent=holder
	if opts.solid~=false then
		local box,size=m:GetBoundingBox()
		local inset=opts.inset or .4
		local b=Instance.new("Part") b.Name="AssetCollision" b.Anchored=true b.CanCollide=true b.CanQuery=false b.CanTouch=false
		b.Transparency=1 b.CastShadow=false
		b.Size=Vector3.new(math.max(.5,size.X-inset),size.Y,math.max(.5,size.Z-inset)) b.CFrame=box
		b.Parent=holder
	end
	return holder
end

-- Like place, but stretches the template per axis to an exact size (x, y, z
-- in studs along the pivot's axes); its centre lands on cf. Used to fit a
-- frame around boards of any width.
function A.placeSized(name: string, parent: Instance, cf: CFrame, size: Vector3): Model?
	local t=A.template(name) if not t then return nil end
	local m=t:Clone() m:SetAttribute("Ready",nil)
	local pivot=m:GetPivot() local box,have=m:GetBoundingBox()
	local k=Vector3.new(size.X/have.X,size.Y/have.Y,size.Z/have.Z)
	local centre=pivot:PointToObjectSpace(box.Position)
	for _,p in m:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false
			local rel=pivot:ToObjectSpace(p.CFrame)
			local axes=rel.Rotation
			-- size along the part's own axes, scaled by the model axis each one lies on
			local function f(v: Vector3) local a=axes:VectorToWorldSpace(v) return math.abs(a.X)*k.X+math.abs(a.Y)*k.Y+math.abs(a.Z)*k.Z end
			p.Size=Vector3.new(p.Size.X*f(Vector3.xAxis),p.Size.Y*f(Vector3.yAxis),p.Size.Z*f(Vector3.zAxis))
			local at=(rel.Position-centre)*k
			p.CFrame=cf*CFrame.new(at)*axes
		end
	end
	m:PivotTo(m:GetPivot()) -- keep pivot data valid
	m.Parent=parent
	return m
end
return A
