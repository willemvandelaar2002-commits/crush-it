--!strict
-- Desktop event HUD, local transformations, the intro cutscene when a round is
-- announced (corrupted bear -> shielded core under the Mega Crusher -> your
-- factory) and the optional seven-second finale view. Both views can be skipped.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local SoundService=game:GetService("SoundService")
local Content=game:GetService("ContentProvider")
local Config=require(RS.Shared.Config)
if not Config.Crushers.Enabled then return end
local E=require(RS.Shared.FactoryEventConfig)
if not E.Enabled then return end
local Net=require(RS.Shared.Net)
local Style=require(RS.Shared.Kit.Style)
local Rules=require(RS.Shared.FactoryEventRules)
local Visuals=require(script.Parent.FactoryEventVisuals)
local Format=require(RS.Shared.Format)
local me=Players.LocalPlayer
local gui=Instance.new("ScreenGui") gui.Name="FactoryEventHud" gui.ResetOnSpawn=false
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling gui.DisplayOrder=4 gui.Parent=me:WaitForChild("PlayerGui")
-- bottom centre, above the hotbar (the top centre has the travel buttons and tutorial card)
local panel=Instance.new("Frame") panel.Name="EventPanel" panel.AnchorPoint=Vector2.new(.5,1)
panel.Position=UDim2.new(.5,0,1,-108) panel.Size=UDim2.fromOffset(600,160) panel.Visible=false panel.Parent=gui
Style.panel(panel,Color3.fromRGB(147,54,227),Color3.fromRGB(68,33,121))
local function label(parent,name,text,pos,size)
	local t=Instance.new("TextLabel") t.Name=name t.Text=text t.BackgroundTransparency=1
	t.Position=pos t.Size=size t.TextScaled=true t.ZIndex=2 t.Parent=parent Style.text(t,2) return t
end
local title=label(panel,"Title","BEAR BREAKDOWN",UDim2.fromOffset(15,9),UDim2.fromOffset(430,31))
title.TextColor3=Color3.fromRGB(255,218,65)
local timer=label(panel,"Timer","",UDim2.fromOffset(460,10),UDim2.fromOffset(125,28))
local bar=Instance.new("Frame") bar.Name="ShieldBar" bar.Position=UDim2.fromOffset(16,46)
bar.Size=UDim2.fromOffset(568,25) bar.ClipsDescendants=true bar.BorderSizePixel=0 bar.BackgroundColor3=Color3.fromRGB(19,23,42)
bar.ZIndex=2 bar.Parent=panel
local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(0,8) corner.Parent=bar
local fill=Instance.new("Frame") fill.Name="Fill" fill.Size=UDim2.fromScale(1,1) fill.BackgroundColor3=Color3.fromRGB(90,235,255)
fill.BorderSizePixel=0 fill.Parent=bar
local barText=label(bar,"BarText","",UDim2.fromScale(.02,.05),UDim2.fromScale(.96,.9)) barText.ZIndex=3
local subtitle=label(panel,"Instruction","",UDim2.fromOffset(16,78),UDim2.fromOffset(568,24))
local detail=label(panel,"Fleet","",UDim2.fromOffset(16,112),UDim2.fromOffset(260,31))
detail.TextXAlignment=Enum.TextXAlignment.Left
local function button(name,text,x,w,color)
	local b=Instance.new("TextButton") b.Name=name b.Text=text b.Position=UDim2.fromOffset(x,111)
	b.Size=UDim2.fromOffset(w,36) b.ZIndex=3 b.TextScaled=true b.Parent=panel Style.button(b,color)
	local pad=Instance.new("UIPadding") pad.PaddingTop=UDim.new(0,6) pad.PaddingBottom=UDim.new(0,6) pad.PaddingLeft=UDim.new(0,8) pad.PaddingRight=UDim.new(0,8) pad.Parent=b
	return b
end
local primary=button("JoinOrPulse","JOIN EVENT",290,190,Color3.fromRGB(65,230,80))
local secondary=button("Leave","LEAVE",492,92,Color3.fromRGB(236,69,91))
local skip=Instance.new("TextButton") skip.Name="SkipFinale" skip.Text="SKIP VIEW"
skip.AnchorPoint=Vector2.new(1,1) skip.Position=UDim2.new(1,-28,1,-28) skip.Size=UDim2.fromOffset(170,48)
skip.Visible=false skip.ZIndex=30 skip.TextScaled=true skip.Parent=gui Style.button(skip,Color3.fromRGB(255,150,35))
do local pad=Instance.new("UIPadding") pad.PaddingTop=UDim.new(0,8) pad.PaddingBottom=UDim.new(0,8) pad.Parent=skip end
-- Intro cutscene: letterbox bars and one caption per shot.
local TweenService=game:GetService("TweenService")
local intro=Instance.new("Frame") intro.Name="EventIntro" intro.Size=UDim2.fromScale(1,1) intro.BackgroundTransparency=1
intro.Visible=false intro.ZIndex=20 intro.Parent=gui
local bars={}
for i,anchor in {0,1} do
	local b=Instance.new("Frame") b.Name="Letterbox" b.AnchorPoint=Vector2.new(0,anchor) b.Position=UDim2.fromScale(0,anchor)
	b.Size=UDim2.new(1,0,0,0) b.BackgroundColor3=Color3.new(0,0,0) b.BorderSizePixel=0 b.ZIndex=20 b.Parent=intro bars[i]=b
end
local fade=Instance.new("Frame") fade.Name="Fade" fade.Size=UDim2.fromScale(1,1) fade.BackgroundColor3=Color3.new(0,0,0)
fade.BackgroundTransparency=1 fade.BorderSizePixel=0 fade.ZIndex=21 fade.Parent=intro
local caption=Instance.new("TextLabel") caption.Name="Caption" caption.AnchorPoint=Vector2.new(.5,1)
caption.Position=UDim2.new(.5,0,.86,0) caption.Size=UDim2.new(.72,0,.085,0) caption.BackgroundTransparency=1
caption.TextScaled=true caption.ZIndex=22 caption.Text="" caption.Parent=intro Style.text(caption,3.5)
local kicker=Instance.new("TextLabel") kicker.Name="Kicker" kicker.AnchorPoint=Vector2.new(.5,0)
kicker.AnchorPoint=Vector2.new(.5,.5) kicker.Position=UDim2.fromScale(.5,.055) kicker.Size=UDim2.new(.5,0,.075,0) kicker.BackgroundTransparency=1
kicker.TextScaled=true kicker.ZIndex=22 kicker.Text="BEAR BREAKDOWN" kicker.Parent=intro Style.text(kicker,4)
kicker.TextColor3=Color3.fromRGB(255,218,65)
local INTRO={ -- seconds; each shot's caption
	{t=0,text="Uh oh... the giant toy bear has gone BAD!"},
	{t=3.4,text="Its corrupted core hides under the MEGA CRUSHER, behind a shield."},
	{t=7,text="Join, and your crushers combine into one SUPER CRUSHER to break it!"},
}
local INTRO_LENGTH=10.4
local packet=nil local visuals=Visuals.new() local cameraState=nil local seenFinale=nil local seenIntro=nil
local stopped=false local connections={} local lastSoundBeat=-1 local finaleSound=nil local buttonColor=nil
local function setColor(color)
	if buttonColor~=color then buttonColor=color Style.setButtonColor(primary,color) end
end
local impact=Instance.new("Sound") impact.Name="FactoryEventImpact" impact.SoundId="rbxassetid://"..Config.Sounds.Thud
impact.Volume=.22 impact.Parent=SoundService
task.spawn(function() pcall(function() Content:PreloadAsync({impact}) end) end)
local hiddenGuis={}
local function showOtherHuds(show)
	if show then
		for g in hiddenGuis do if g.Parent then g.Enabled=true end end
		hiddenGuis={}
	else
		for _,g in me.PlayerGui:GetChildren() do
			if g:IsA("ScreenGui") and g~=gui and g.Enabled then hiddenGuis[g]=true g.Enabled=false end
		end
	end
end
local function stopCamera()
	local s=cameraState if not s then return end cameraState=nil skip.Visible=false
	if s.mode=="intro" then intro.Visible=false showOtherHuds(true) skip.Text="SKIP VIEW" end
	-- A different cutscene may have taken over; never overwrite its camera.
	if workspace.CurrentCamera==s.camera and s.camera.CameraType==Enum.CameraType.Scriptable then
		s.camera.CameraType=s.kind s.camera.CameraSubject=s.subject
		s.camera.FieldOfView=s.fov s.camera.CFrame=s.cf
	end
end
local function startCamera(mode)
	local camera=workspace.CurrentCamera
	if not camera or camera.CameraType==Enum.CameraType.Scriptable then return false end
	local hum=me.Character and me.Character:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health<=0 then return false end
	cameraState={camera=camera,kind=camera.CameraType,subject=camera.CameraSubject,fov=camera.FieldOfView,cf=camera.CFrame,mode=mode or "finale"}
	camera.CameraType=Enum.CameraType.Scriptable skip.Visible=true
	return true
end
-- The three intro shots, worked out once from the real bear, Mega Crusher and
-- your plot (each falls back to the plaza centre if it hasn't streamed in).
local function introShots()
	local shots={}
	local bear=visuals.bear and visuals.bear.model
	if bear then
		local cf,size=bear:GetBoundingBox()
		-- the bear faces the middle of the hall; stay under the roof
		local head=cf.Position+Vector3.new(0,size.Y*.25,0)
		local face=(Vector3.new(0,head.Y,0)-head).Unit
		local r=math.max(size.X,size.Y)
		local function under(v) return Vector3.new(v.X,math.min(v.Y,130),v.Z) end
		shots[1]={from=under(head+face*r*1.5-Vector3.new(0,r*.12,0)),to=under(head+face*r*.85),look=head,fov=55}
	end
	local central=visuals.central
	local core=if central then central.origin.Position+Vector3.new(0,central.room*.45,0) else Vector3.new(0,12,0)
	local toward=if central then central.origin.LookVector else Vector3.new(0,0,1)
	shots[2]={from=core+toward*95+Vector3.new(0,70,0),to=core+toward*34+Vector3.new(0,9,0),look=core,fov=60}
	local plot=workspace:FindFirstChild("Plots") and workspace.Plots:FindFirstChild("Plot"..tostring(me:GetAttribute("Plot")))
	local o=plot and plot:GetAttribute("Origin")
	if typeof(o)=="CFrame" then
		local middle=(o*CFrame.new(0,8,-13)).Position
		shots[3]={from=(o*CFrame.new(-60,55,150)).Position,to=(o*CFrame.new(20,38,95)).Position,look=middle,fov=60}
	else shots[3]={from=core+Vector3.new(120,90,120),to=core+Vector3.new(80,60,80),look=core,fov=65} end
	if not shots[1] then shots[1]=shots[2] end
	return shots
end
local function playIntro()
	if not startCamera("intro") then return end
	cameraState.shots=introShots() cameraState.begin=os.clock() cameraState.shot=0
	skip.Text="SKIP" intro.Visible=true showOtherHuds(false) panel.Visible=false
	for _,b in bars do b.Size=UDim2.new(1,0,0,0) TweenService:Create(b,TweenInfo.new(.5),{Size=UDim2.new(1,0,.11,0)}):Play() end
	kicker.TextTransparency=1 TweenService:Create(kicker,TweenInfo.new(.6),{TextTransparency=0}):Play()
end
local function introStep()
	local s=cameraState local age=os.clock()-s.begin
	if age>=INTRO_LENGTH then stopCamera() return end
	local index=1 for i,shot in INTRO do if age>=shot.t then index=i end end
	if index~=s.shot then
		s.shot=index caption.Text=INTRO[index].text
		caption.TextTransparency=1 TweenService:Create(caption,TweenInfo.new(.35),{TextTransparency=0}):Play()
		if index>1 then fade.BackgroundTransparency=0 TweenService:Create(fade,TweenInfo.new(.45),{BackgroundTransparency=1}):Play() end
	end
	local start=INTRO[index].t local stop=if INTRO[index+1] then INTRO[index+1].t else INTRO_LENGTH
	local k=math.clamp((age-start)/(stop-start),0,1) k=1-(1-k)^2 -- ease out
	local shot=s.shots[index]
	local at=shot.from:Lerp(shot.to,k)
	s.camera.CFrame=CFrame.lookAt(at,shot.look) s.camera.FieldOfView=shot.fov
	if age>INTRO_LENGTH-.6 then
		for _,b in bars do b.Size=UDim2.new(1,0,.11*math.clamp((INTRO_LENGTH-age)/.6,0,1),0) end
	end
end
skip.Activated:Connect(stopCamera)
table.insert(connections,me.CharacterRemoving:Connect(stopCamera))
-- The plot-upgrade cutscene waits .15s for replication before taking the
-- camera. Release ours immediately on its confirmed server event.
table.insert(connections,Net.event("PlotUpgraded").OnClientEvent:Connect(stopCamera))
local function renderHud(now)
	if not packet then return end
	local phase=packet.phase local you=packet.you
	panel.Visible=phase~="Idle" and not (cameraState~=nil and cameraState.mode=="intro")
	if not panel.Visible then return end
	local remaining=math.max(0,math.ceil(packet.ends-now))
	timer.Text=string.format("%d:%02d",math.floor(remaining/60),remaining%60)
	local fraction=if packet.maxHp>0 then math.clamp(packet.hp/packet.maxHp,0,1) else 1
	fill.Size=UDim2.fromScale(fraction,1)
	barText.Text=if phase=="Active" then string.format("BEAR'S SHIELD · %d%%",math.ceil(fraction*100))
		elseif phase=="Finale" then "SHIELD BROKEN · MEGA CRUSHER CHARGING"
		elseif phase=="Victory" then "CORE DESTROYED!" else "YOUR FACTORY POWERS THE FINAL BLOW"
	detail.Text=if you then tostring(you.points).." POINTS · "..tostring(you.count).." CRUSHERS" else tostring(#packet.participants).." FACTORIES JOINED"
	primary.Visible=false secondary.Visible=you~=nil and phase~="Victory" and phase~="Recover"
	if phase=="Announce" then
		setColor(Color3.fromRGB(65,230,80))
		subtitle.Text=if you then "You're in! Your placed crushers combine when the timer ends." else "The bear is corrupted! Join from your own factory."
		primary.Visible=you==nil primary.Text="JOIN EVENT"
	elseif phase=="Assemble" then
		subtitle.Text=if you then E.Grades[you.grade].name.." · ASSEMBLING!" else "Factories are assembling their super crushers!"
	elseif phase=="Active" then
		if you then
			local ready=now>=(you.pulseReady or 0)
			local beat=Rules.onBeat(now,packet.started)
			subtitle.Text=if not you.present then "Return to your factory to crush the core fragment!"
				elseif you.eligible then "Reward qualified! Keep crushing to break the shared shield."
				else string.format("Stay on your plot · %ds / %ds to qualify",math.min(E.MinimumActive,math.floor(you.active)),E.MinimumActive)
			primary.Visible=true
			primary.Text=if not you.present then "MY FACTORY" elseif not ready then "RECHARGING "..math.ceil(you.pulseReady-now).."s"
				elseif beat then "OVERDRIVE · NOW!" else "WAIT FOR THE BEAT"
			setColor(if ready and beat then Color3.fromRGB(65,230,80) else Color3.fromRGB(80,130,200))
		else subtitle.Text="Factories are breaking the bear's shield! Join the next round." end
	elseif phase=="Finale" then
		subtitle.Text="Your factories powered it up. The Mega Crusher is finishing the core!"
	elseif phase=="Victory" then
		subtitle.Text=if you and you.reward>0 then "YOU EARNED "..Format.cash(you.reward).."!"
			elseif you then "Bear defeated! Stay active for 30 seconds to earn next round's reward."
			else "The factory is safe again!"
	elseif phase=="Recover" then
		subtitle.Text=if packet.outcome=="Victory" then "Your original crushers are returning." else packet.outcome.." · restoring the factory."
	end
end
primary.Activated:Connect(function()
	if not packet then return end
	if packet.phase=="Announce" and not packet.you then Net.event("FactoryEventAction"):FireServer("Join")
	elseif packet.phase=="Active" and packet.you then
		if not packet.you.present then Net.event("Travel"):FireServer("Plot")
		else Net.event("FactoryEventAction"):FireServer("Pulse") end
	end
end)
secondary.Activated:Connect(function() stopCamera() Net.event("FactoryEventAction"):FireServer("Leave") end)
local function cleanup()
	if stopped then return end stopped=true
	stopCamera() visuals:destroy() impact:Destroy() gui:Destroy()
	for _,connection in connections do connection:Disconnect() end
end
table.insert(connections,Net.event("FactoryEventState").OnClientEvent:Connect(function(value)
	if stopped or type(value)~="table" then return end
	packet=value
	local ok,err=xpcall(function() visuals:update(packet) end,debug.traceback)
	if not ok then warn("[FactoryEvent] Visuals stopped safely: "..tostring(err)) cleanup() return end
	local introRunning=cameraState~=nil and cameraState.mode=="intro"
	if packet.phase=="Announce" then
		-- once per round, only at its start (not for someone arriving mid-announcement)
		if seenIntro~=packet.roundId and workspace:GetServerTimeNow()-packet.started<4 then
			seenIntro=packet.roundId playIntro()
		end
	elseif introRunning then stopCamera() end
	if packet.phase=="Announce" then -- the intro keeps going; the finale view never runs now
	elseif packet.phase~="Finale" or not packet.you then if not introRunning then stopCamera() end
	elseif seenFinale~=packet.roundId then
		seenFinale=packet.roundId
		if packet.you.present then startCamera("finale") end
	end
	renderHud(workspace:GetServerTimeNow())
end))
table.insert(connections,Run.RenderStepped:Connect(function()
	if stopped or not packet then return end
	local now=workspace:GetServerTimeNow()
	local ok,err=xpcall(function()
		visuals:step(now) renderHud(now)
		if cameraState and cameraState.mode=="intro" then
			local hum=me.Character and me.Character:FindFirstChildOfClass("Humanoid")
			if not hum or hum.Health<=0 or workspace.CurrentCamera~=cameraState.camera then stopCamera() else introStep() end
		elseif cameraState then
			local s=cameraState local camera=s.camera
			local hum=me.Character and me.Character:FindFirstChildOfClass("Humanoid")
			local central=visuals.central
			if not hum or hum.Health<=0 or not central or workspace.CurrentCamera~=camera then stopCamera()
			else
				local age=now-packet.started local target=central.origin.Position+Vector3.new(0,central.room*.5,0)
				local distance=math.max(60,central.room*1.8)
				local at=(central.origin*CFrame.new(math.sin(age*.15)*distance*.35,distance*.65,distance)).Position
				camera.CFrame=CFrame.lookAt(at,target) camera.FieldOfView=60
			end
		end
		if packet.phase=="Active" then
			local beat=math.floor((now-packet.started)/E.Strike)
			if beat~=lastSoundBeat then
				lastSoundBeat=beat
				local camera=workspace.CurrentCamera local distance=math.huge
				if camera then for _,r in packet.participants do
					if r.present then distance=math.min(distance,(r.origin.Position-camera.CFrame.Position).Magnitude) end
				end end
				if beat>0 and distance<130 and impact.IsLoaded then
					impact.Volume=.22*(1-distance/130) impact.PlaybackSpeed=.7 impact:Play()
				end
			end
		elseif packet.phase=="Finale" and now-packet.started>=2.85 and finaleSound~=packet.roundId then
			finaleSound=packet.roundId
			if impact.IsLoaded then impact.Volume=.4 impact.PlaybackSpeed=.5 impact:Play() end
		end
	end,debug.traceback)
	if not ok then warn("[FactoryEvent] Presentation stopped safely: "..tostring(err)) cleanup() end
end))
table.insert(connections,script.Destroying:Connect(cleanup))
Net.event("FactoryEventAction"):FireServer("Sync")
