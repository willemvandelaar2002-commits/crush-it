--!strict
-- Presentation only. The server owns eligibility, outcome, grants and saves.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Tween=game:GetService("TweenService")
local Run=game:GetService("RunService")
local Content=game:GetService("ContentProvider")
local CollectionService=game:GetService("CollectionService")
local S=require(RS.Shared.DailySpinConfig)
local Style=require(RS.Shared.Kit.Style)
local Net=require(RS.Shared.Net)
local remote=Net.event("DailySpin")
local player=Players.LocalPlayer
local function make(class,props,parent)
	local v=Instance.new(class) for k,x in props do v[k]=x end v.Parent=parent return v
end
local gui=make("ScreenGui",{Name="DailySpinHud",ResetOnSpawn=false,DisplayOrder=8,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},player:WaitForChild("PlayerGui"))
local panel=make("Frame",{Name="DailySpinPanel",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.52),Size=UDim2.fromOffset(920,640),BackgroundColor3=Color3.fromRGB(24,28,46),Visible=false,ZIndex=5},gui)
Style.panel(panel,Color3.fromRGB(24,28,46)) Style.modal(panel)
local canvas=make("Frame",{Name="Canvas",Size=UDim2.fromOffset(920,640),BackgroundTransparency=1},panel)
local scale=make("UIScale",{Scale=1},canvas)
local function text(parent,name,value,pos,size,font)
	local l=make("TextLabel",{Name=name,Text=value,Position=pos,Size=size,TextSize=font or 22,TextWrapped=true,BackgroundTransparency=1,ZIndex=4},parent)
	Style.text(l,2) return l
end
local header=make("Frame",{Name="Header",Size=UDim2.new(1,0,0,70)},canvas)
Style.collectionPanel(header,Color3.fromRGB(180,65,225),Color3.fromRGB(105,35,165))
text(header,"Title","DAILY SPIN",UDim2.fromOffset(25,5),UDim2.fromOffset(690,60),38).TextXAlignment=Enum.TextXAlignment.Left
local function button(parent,name,value,pos,size,color,callback)
	local b=make("TextButton",{Name=name,Text=value,Position=pos,Size=size,TextSize=23,TextWrapped=true,ZIndex=4},parent)
	Style.button(b,color) b.Activated:Connect(callback) return b
end
button(header,"Close","X",UDim2.fromOffset(850,10),UDim2.fromOffset(52,50),Style.Colors.Red,function() Style.setOpen(panel,false) end)
local wheel=make("Frame",{Name="Wheel",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset(244,305),Size=UDim2.fromOffset(440,440),BackgroundTransparency=1},canvas)
make("UIAspectRatioConstraint",{AspectRatio=1},wheel)
local rotor=make("Frame",{Name="Rotor",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=1},wheel)
local image=make("ImageLabel",{Name="Artwork",Image=S.RotorImage,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ScaleType=Enum.ScaleType.Fit,ZIndex=1},rotor)
local frame=make("ImageLabel",{Name="FixedFrame",Image=S.FrameImage,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ScaleType=Enum.ScaleType.Fit,ZIndex=3},wheel)
text(canvas,"RewardHeading","PRIZES & CHANCES",UDim2.fromOffset(490,85),UDim2.fromOffset(400,32),25)
local rows={}
for i,def in S.Rewards do
	local row=make("Frame",{Name=def.id,Position=UDim2.fromOffset(490,126+(i-1)*43),Size=UDim2.fromOffset(405,38)},canvas)
	Style.collectionPanel(row,Style.darken(def.color,.35),Style.darken(def.color,.6))
	local l=text(row,"Reward","Loading...",UDim2.fromOffset(10,0),UDim2.fromOffset(302,38),19) l.TextXAlignment=Enum.TextXAlignment.Left
	text(row,"Odds",string.format("%g%%",S.odds(def.id)),UDim2.fromOffset(315,0),UDim2.fromOffset(80,38),19)
	rows[def.id]=l
end
text(canvas,"Explanation","One free spin every 24 hours.\nChances shown above determine the result.",UDim2.fromOffset(490,478),UDim2.fromOffset(405,54),18)
local result=text(canvas,"Result","Visit the Daily Spin station for a free prize!",UDim2.fromOffset(22,520),UDim2.fromOffset(444,43),21)
local timer=text(canvas,"Timer","Loading...",UDim2.fromOffset(28,604),UDim2.fromOffset(432,26),18)
local state local spinning=false local requesting=false local seen={} local currentTween
local spinButton
spinButton=button(canvas,"Spin","FREE SPIN",UDim2.fromOffset(65,565),UDim2.fromOffset(358,40),Style.Colors.Green,function()
	if spinning or requesting or not state or state.nextAt>workspace:GetServerTimeNow() and not state.pending or not image.IsLoaded or not frame.IsLoaded then return end
	requesting=true result.Text="Confirming your free spin..." remote:FireServer("Spin")
	task.delay(20,function()
		if requesting then requesting=false result.Text="Still waiting for the server. Reopen to check your spin." remote:FireServer("State") end
	end)
end)
local paid=button(canvas,"PaidSpins","PAID SPINS UNAVAILABLE",UDim2.fromOffset(510,555),UDim2.fromOffset(365,46),Color3.fromRGB(90,95,115),function() end)
paid.Active=false paid.AutoButtonColor=false paid.Selectable=false paid.TextSize=19
-- Optional place-only decoration. Never PivotTo the Model or move Frame/Stand.
-- Keep rest poses alive throughout a spin; weak Instance keys can be collected
-- while their parts still exist, causing the next frame to capture a rotated pose.
local worldRest={}
CollectionService:GetInstanceRemovedSignal("DailySpinWheel"):Connect(function(m)
	local part=m:FindFirstChild("Rotor") if part then worldRest[part]=nil end
end)
rotor:GetPropertyChangedSignal("Rotation"):Connect(function()
	local models=CollectionService:GetTagged("DailySpinWheel")
	local legacy=workspace:FindFirstChild("DailySpinWheel")
	if legacy and not table.find(models,legacy) then table.insert(models,legacy) end
	for _,m in models do
		local part=m:IsDescendantOf(workspace) and m:FindFirstChild("Rotor")
		if part and part:IsA("BasePart") and part.Anchored then
			if not worldRest[part] then
				worldRest[part]=part.CFrame
				part.Destroying:Once(function() worldRest[part]=nil end)
			end
			part.CFrame=worldRest[part]*CFrame.Angles(0,0,-math.rad(rotor.Rotation))
		end
	end
end)
remote.OnClientEvent:Connect(function(value)
	state=value requesting=false
	for _,reward in value.rewards do if rows[reward.id] then rows[reward.id].Text=reward.text end end
	if value.open then Style.setOpen(panel,true) end
	if value.message and not spinning then result.Text=value.message end
	local prize=value.result
	if prize and not seen[prize.token] then
		local def=S.reward(prize.id) if not def then return end
		seen[prize.token]=true spinning=true result.Text="Spinning..."
		if currentTween then currentTween:Cancel() end
		local target=S.target(rotor.Rotation,def.sector)
		currentTween=Tween:Create(rotor,TweenInfo.new(S.Duration,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Rotation=target})
		currentTween.Completed:Once(function()
			rotor.Rotation=target%360 spinning=false result.Text="YOU WON: "..prize.text
		end)
		currentTween:Play()
	end
end)
local function fit()
	local viewport=workspace.CurrentCamera.ViewportSize
	scale.Scale=S.desktopScale(viewport.X,viewport.Y) panel.Size=UDim2.fromOffset(920*scale.Scale,640*scale.Scale)
end
fit() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
panel:GetPropertyChangedSignal("Visible"):Connect(function() if panel.Visible then remote:FireServer("State") end end)
local last=0
Run.RenderStepped:Connect(function()
	if os.clock()-last<.15 then return end last=os.clock()
	local left=state and math.max(0,math.ceil(state.nextAt-workspace:GetServerTimeNow())) or 0
	local ready=state and (left==0 or state.pending) and not spinning and not requesting and image.IsLoaded and frame.IsLoaded
	spinButton.Active=ready==true
	spinButton.Text=if spinning then "SPINNING..." elseif requesting then "PLEASE WAIT..." elseif not image.IsLoaded or not frame.IsLoaded then "LOADING WHEEL..." elseif state and state.pending then "DELIVER RESERVED PRIZE" elseif ready then "FREE SPIN" else "COME BACK SOON"
	timer.Text=if not state then "Loading your spin..." elseif state.pending then "Your selected prize is waiting for delivery." elseif left==0 then "Your free spin is ready!" else string.format("Next free spin: %02d:%02d:%02d",left//3600,left%3600//60,left%60)
end)
task.spawn(function() pcall(function() Content:PreloadAsync({image,frame}) end) end)
remote:FireServer("State")
