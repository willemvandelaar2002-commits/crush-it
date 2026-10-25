--!strict
-- Shared loaded-image view with a static real-model fallback. Local only.
local RS=game:GetService("ReplicatedStorage")
local Content=game:GetService("ContentProvider")
local Images=require(RS.Shared.CrusherIcons)
local Finish=require(RS.Shared.CrusherFinish)
local Kit=require(RS.Shared.Kit.Style)
local Icons=require(RS.Shared.Icons)
local I={} local white=Color3.new(1,1,1) local black=Color3.new(0,0,0)
local cache={} :: {[string]: {status: string,started: boolean?,listeners: {[any]: (boolean)->()}}}
function I.ready(typeId: string,callback: (boolean)->()): ()->()
	local uri=Images.image(typeId)
	if not uri then callback(false) return function() end end
	local entry=cache[uri]
	if not entry then entry={status="pending",listeners={}} cache[uri]=entry end
	local key={} entry.listeners[key]=callback
	if entry.status~="pending" then callback(entry.status=="ready")
	elseif not entry.started then entry.started=true task.spawn(function()
		local loaded=false
		-- Supply image context: bare asset IDs can fail while ImageLabels load.
		local probe=Instance.new("ImageLabel") probe.Image=uri
		local ok=pcall(function() Content:PreloadAsync({probe},function(_,status) loaded=status==Enum.AssetFetchStatus.Success end) end)
		probe:Destroy()
		entry.status=if ok and loaded then "ready" else "failed"
		for _,listener in table.clone(entry.listeners) do listener(entry.status=="ready") end
	end) end
	return function() entry.listeners[key]=nil end
end
function I.new(parent: GuiObject,typeId: string,opts: any?): Frame
	opts=opts or {}
	local root=Instance.new("Frame") root.Name="CrusherIcon" root.BackgroundTransparency=1
	root.Size=opts.size or UDim2.fromScale(1,1) root.Position=opts.position or UDim2.new()
	root.ZIndex=opts.zIndex or 2 root.Parent=parent
	local image=Instance.new("ImageLabel") image.Name="Artwork" image.BackgroundTransparency=1
	image.Size=UDim2.fromScale(1,1) image.ScaleType=Enum.ScaleType.Fit image.ZIndex=root.ZIndex
	image.Image=Images.image(typeId) or "" image.Visible=false image.ImageColor3=if opts.hidden then black else white image.Parent=root
	local fallback: ViewportFrame? local generic: ImageLabel?
	local folderConnection: RBXScriptConnection? local sourceConnection: RBXScriptConnection? local fitConnection: RBXScriptConnection?
	local alive=true local loaded=false
	local function cleanup()
		if folderConnection then folderConnection:Disconnect() folderConnection=nil end
		if sourceConnection then sourceConnection:Disconnect() sourceConnection=nil end
		if fitConnection then fitConnection:Disconnect() fitConnection=nil end
		if fallback then fallback:Destroy() fallback=nil end
		if generic then generic:Destroy() generic=nil end
	end
	local function showFallback()
		if not alive or loaded or fallback then return end
		local folder=RS:FindFirstChild("CrusherPreviewModels") local source=folder and folder:FindFirstChild(typeId)
		if not source or not source:IsA("Model") or not source:FindFirstChildWhichIsA("BasePart",true) then
			if not generic then generic=Kit.image(root,Icons.Press,{Name="LoadingIcon",Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.8,.8),ZIndex=root.ZIndex})
				generic.ImageColor3=if opts.hidden then black else white end
			return
		end
		if generic then generic:Destroy() generic=nil end
		if sourceConnection then sourceConnection:Disconnect() sourceConnection=nil end
		fallback=Instance.new("ViewportFrame") fallback.Name="ModelFallback" fallback.BackgroundTransparency=1
		fallback.Size=UDim2.fromScale(1,1) fallback.ZIndex=root.ZIndex fallback.Ambient=Color3.fromRGB(220,226,245)
		fallback.LightColor=white fallback.LightDirection=Vector3.new(-.6,-1,-1.4)
		fallback.ImageColor3=if opts.hidden then black else white fallback.Parent=root
		local model=source:Clone() model.Parent=fallback
		if opts.modifier then Finish.apply(model,opts.modifier) end
		local cf,size=model:GetBoundingBox()
		local camera=Instance.new("Camera") camera.FieldOfView=28 camera.Parent=fallback
		local direction=Vector3.new(.72,.52,1).Unit local view=CFrame.lookAt(cf.Position+direction,cf.Position)
		local function fit()
			if not fallback then return end
			local aspect=math.max(.1,fallback.AbsoluteSize.X/math.max(1,fallback.AbsoluteSize.Y))
			local tanY=math.tan(math.rad(14))*.88 local tanX=tanY*aspect local distance=0
			for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
				local point=view:VectorToObjectSpace(Vector3.new(x*size.X/2,y*size.Y/2,z*size.Z/2))
				distance=math.max(distance,point.Z+math.max(math.abs(point.X)/tanX,math.abs(point.Y)/tanY))
			end end end
			camera.CFrame=CFrame.lookAt(cf.Position+direction*distance,cf.Position)
		end
		fitConnection=fallback:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit) fit() fallback.CurrentCamera=camera
	end
	local function watchFolder(folder)
		if not alive or loaded then return end
		if sourceConnection then sourceConnection:Disconnect() end
		sourceConnection=folder.DescendantAdded:Connect(showFallback) showFallback()
	end
	local unsubscribe=I.ready(typeId,function(success)
		if not alive then return end loaded=success image.Visible=success
		if success then cleanup() else showFallback() end
	end)
	task.delay(.35,function()
		if not alive or loaded then return end
		local folder=RS:FindFirstChild("CrusherPreviewModels")
		if folder then watchFolder(folder) else folderConnection=RS.ChildAdded:Connect(function(child)
			if child.Name=="CrusherPreviewModels" then watchFolder(child) end
		end) end
		showFallback()
	end)
	root.Destroying:Connect(function() alive=false unsubscribe() cleanup() end)
	return root
end
return I
