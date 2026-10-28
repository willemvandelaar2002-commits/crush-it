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
-- compact boss bar, top centre under the travel buttons (28 Oct: no Join/Leave;
-- everyone takes part). One instruction line; MY FACTORY only while away.
local panel=Instance.new("Frame") panel.Name="EventPanel" panel.AnchorPoint=Vector2.new(.5,0)
panel.Position=UDim2.new(.5,0,0,124) panel.Size=UDim2.fromOffset(560,104) panel.Visible=false panel.Parent=gui
Style.panel(panel,Color3.fromRGB(147,54,227),Color3.fromRGB(68,33,121))
local function label(parent,name,text,pos,size)
	local t=Instance.new("TextLabel") t.Name=name t.Text=text t.BackgroundTransparency=1
	t.Position=pos t.Size=size t.TextScaled=true t.ZIndex=2 t.Parent=parent Style.text(t,2) return t
end
local title=label(panel,"Title","BEAR BREAKDOWN",UDim2.fromOffset(14,7),UDim2.fromOffset(300,28))
title.TextColor3=Color3.fromRGB(255,218,65) title.TextXAlignment=Enum.TextXAlignment.Left
local timer=label(panel,"Timer","",UDim2.fromOffset(436,7),UDim2.fromOffset(110,28))
timer.TextXAlignment=Enum.TextXAlignment.Right
local bar=Instance.new("Frame") bar.Name="ShieldBar" bar.Position=UDim2.fromOffset(14,40)
bar.Size=UDim2.fromOffset(532,26) bar.ClipsDescendants=true bar.BorderSizePixel=0 bar.BackgroundColor3=Color3.fromRGB(19,23,42)
bar.ZIndex=2 bar.Parent=panel
local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(0,8) corner.Parent=bar
local fill=Instance.new("Frame") fill.Name="Fill" fill.Size=UDim2.fromScale(1,1) fill.BackgroundColor3=Color3.fromRGB(90,235,255)
fill.BorderSizePixel=0 fill.Parent=bar
local barText=label(bar,"BarText","",UDim2.fromScale(.02,.05),UDim2.fromScale(.96,.9)) barText.ZIndex=3
local subtitle=label(panel,"Instruction","",UDim2.fromOffset(14,72),UDim2.fromOffset(532,24))
local primary=Instance.new("TextButton") primary.Name="GoToFactory" primary.Text="MY FACTORY"
primary.AnchorPoint=Vector2.new(.5,0) primary.Position=UDim2.new(.5,0,1,8) primary.Size=UDim2.fromOffset(200,40)
primary.TextScaled=true primary.ZIndex=3 primary.Visible=false primary.Parent=panel Style.button(primary,Color3.fromRGB(65,230,80))
do local pad=Instance.new("UIPadding") pad.PaddingTop=UDim.new(0,6) pad.PaddingBottom=UDim.new(0,6) pad.Parent=primary end
local skip=Instance.new("TextButton") skip.Name="SkipFinale" skip.Text="SKIP VIEW"
skip.AnchorPoint=Vector2.new(1,1) skip.Position=UDim2.new(1,-28,1,-28) skip.Size=UDim2.fromOffset(170,48)
skip.Visible=false skip.ZIndex=30 skip.TextScaled=true skip.Parent=gui Style.button(skip,Color3.fromRGB(255,150,35))
do local pad=Instance.new("UIPadding") pad.PaddingTop=UDim.new(0,8) pad.PaddingBottom=UDim.new(0,8) pad.Parent=skip end
-- Intro cutscene (reference-style: no captions, just Skip): bear transforms,
-- close on the corrupted bear, the core under the Mega Crusher, then your own
-- plot where your crushers fly together into one super crusher. Runs on the
-- server clock across Announce + Assemble; the HUD hides throughout.
local TweenService=game:GetService("TweenService")
local intro=Instance.new("Frame") intro.Name="EventIntro" intro.Size=UDim2.fromScale(1,1) intro.BackgroundTransparency=1
intro.Visible=false intro.ZIndex=20 intro.Parent=gui
local fade=Instance.new("Frame") fade.Name="Fade" fade.Size=UDim2.fromScale(1,1) fade.BackgroundColor3=Color3.new(0,0,0)
fade.BackgroundTransparency=1 fade.BorderSizePixel=0 fade.ZIndex=21 fade.Parent=intro
local flash=Instance.new("Frame") flash.Name="Flash" flash.Size=UDim2.fromScale(1,1) flash.BackgroundColor3=Color3.fromRGB(235,190,255)
flash.BackgroundTransparency=1 flash.BorderSizePixel=0 flash.ZIndex=21 flash.Parent=intro
local SHOTS={0,3.4,7.6,E.Announce} -- shot starts (s after the announcement); the last runs through Assemble
local INTRO_LENGTH=E.Announce+E.Assemble
local packet=nil local visuals=Visuals.new() local cameraState=nil local seenFinale=nil local seenIntro=nil
local stopped=false local connections={} local lastSoundBeat=-1 local finaleSound=nil local buttonColor=nil
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
	if not camera then return false end
	-- another cutscene (the plot upgrade marks itself) owns the camera: leave it
	local busy=camera.CameraType==Enum.CameraType.Scriptable
	if busy and (mode~="intro" or me:GetAttribute("CutscenePlaying")==true) then return false end
	local hum=me.Character and me.Character:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health<=0 then return false end
	cameraState={camera=camera,kind=if busy then Enum.CameraType.Custom else camera.CameraType,subject=camera.CameraSubject,fov=camera.FieldOfView,cf=camera.CFrame,mode=mode or "finale"}
	camera.CameraType=Enum.CameraType.Scriptable skip.Visible=true
	return true
end
-- Shots from the real bear spot, Mega Crusher and your plot (fallback: plaza).
local function introShots()
	local shots={}
	local spot=visuals:bearSpot()
	local char=me.Character local root=char and char:FindFirstChild("HumanoidRootPart")
	local central=visuals.central
	local core=if central then central.origin.Position+Vector3.new(0,central.room*.45,0) else Vector3.new(0,12,0)
	if spot then
		local head=spot.head local r=spot.height
		local face=(Vector3.new(0,head.Y,0)-head) face=Vector3.new(face.X,0,face.Z).Unit
		local function under(v) return Vector3.new(v.X,math.min(v.Y,132),v.Z) end
		-- A: over your shoulder, looking at the bear far away
		if root then
			local dir=(head-root.Position).Unit
			local flat=Vector3.new(dir.X,0,dir.Z).Unit
			local from=root.Position-flat*9+Vector3.new(0,4.5,0)+flat:Cross(Vector3.yAxis)*3
			shots[1]={from=from,to=from+flat*6,look=head,fov=50}
		else shots[1]={from=under(head+face*r*3+Vector3.new(0,10,0)),to=under(head+face*r*2.4),look=head,fov=55} end
		-- B: low and close on the bear as it turns, then roars
		shots[2]={from=under(head+face*r*1.45-Vector3.new(0,r*.22,0)),to=under(head+face*r*.8-Vector3.new(0,r*.08,0)),look=head,fov=60,shake=true}
	end
	-- C: the shielded core under the Mega Crusher, circling down
	local toward=if central then central.origin.LookVector else Vector3.new(0,0,1)
	local side=toward:Cross(Vector3.yAxis)
	shots[3]={from=core+toward*80+side*40+Vector3.new(0,60,0),to=core+toward*32-side*8+Vector3.new(0,8,0),look=core,fov=60}
	-- D: your plot, while the crushers fly into the super crusher
	local plot=workspace:FindFirstChild("Plots") and workspace.Plots:FindFirstChild("Plot"..tostring(me:GetAttribute("Plot")))
	local o=plot and plot:GetAttribute("Origin")
	if typeof(o)=="CFrame" then
		local middle=(o*CFrame.new(0,10,-13)).Position
		shots[4]={from=(o*CFrame.new(-14,30,46)).Position,to=(o*CFrame.new(0,19,30)).Position,look=middle,fov=66} -- straight down the walkway into the gap between the banks
	else shots[4]=shots[3] end
	shots[1]=shots[1] or shots[3] shots[2]=shots[2] or shots[3]
	return shots
end
local function playIntro(announced)
	if not startCamera("intro") then return end
	cameraState.begin=announced
	local ok,shots=pcall(introShots)
	if not ok then warn("[FactoryEvent] intro shots: "..tostring(shots)) stopCamera() return end
	cameraState.shots=shots cameraState.shot=0
	skip.Text="SKIP" intro.Visible=true showOtherHuds(false) panel.Visible=false
	fade.BackgroundTransparency=0 TweenService:Create(fade,TweenInfo.new(.5),{BackgroundTransparency=1}):Play()
end
local function introStep(now)
	local s=cameraState local age=now-s.begin
	if age>=INTRO_LENGTH then stopCamera() return end
	local index=1 for i,start in SHOTS do if age>=start then index=i end end
	if index~=s.shot then
		s.shot=index
		if index==4 then s.shots=introShots() end -- your plot may have streamed in by now
		if index>1 then fade.BackgroundTransparency=0 TweenService:Create(fade,TweenInfo.new(.35),{BackgroundTransparency=1}):Play() end
	end
	-- the white-purple flash when the bear changes (visuals: 2.6 s)
	flash.BackgroundTransparency=if age>=2.6 and age<3.2 then .2+.8*(age-2.6)/.6 else 1
	local start=SHOTS[index] local stop=SHOTS[index+1] or INTRO_LENGTH
	local k=math.clamp((age-start)/(stop-start),0,1) k=k*k*(3-2*k)
	local shot=s.shots[index]
	local at=shot.from:Lerp(shot.to,k)
	local cf=CFrame.lookAt(at,shot.look)
	-- shake: the landing (2.6-3.4) and the roar (5.2-7)
	local shake=(if age>=2.6 and age<3.4 then 1-(age-2.6)/.8 else 0)+(if age>=5.2 and age<7 then .7 else 0)
	if shake>0 then cf*=CFrame.Angles(math.sin(now*47)*.012*shake,math.sin(now*39)*.012*shake,0) end
	s.camera.CFrame=cf s.camera.FieldOfView=shot.fov
	if age>INTRO_LENGTH-.4 then fade.BackgroundTransparency=math.clamp((INTRO_LENGTH-age)/.4,0,1) end
end
skip.Activated:Connect(stopCamera)
table.insert(connections,me.CharacterRemoving:Connect(stopCamera))
-- The plot-upgrade cutscene waits .15s for replication before taking the
-- camera. Release ours immediately on its confirmed server event.
table.insert(connections,Net.event("PlotUpgraded").OnClientEvent:Connect(stopCamera))
local function renderHud(now)
	if not packet then return end
	local phase=packet.phase local you=packet.you
	-- no panel while the intro/assembly plays (Announce, Assemble)
	panel.Visible=phase~="Idle" and phase~="Announce" and phase~="Assemble" and not (cameraState~=nil and cameraState.mode=="intro")
	if not panel.Visible then return end
	local remaining=math.max(0,math.ceil(packet.ends-now))
	timer.Text=string.format("%d:%02d",math.floor(remaining/60),remaining%60)
	local fraction=if packet.maxHp>0 then math.clamp(packet.hp/packet.maxHp,0,1) else 1
	fill.Size=UDim2.fromScale(fraction,1)
	-- cyan at full shield, warmer as it breaks
	fill.BackgroundColor3=Color3.fromRGB(255,140,40):Lerp(Color3.fromRGB(90,235,255),fraction)
	barText.Text=if phase=="Active" then string.format("BEAR'S SHIELD · %d%%",math.ceil(fraction*100))
		elseif phase=="Finale" then "SHIELD BROKEN · MEGA CRUSHER CHARGING"
		elseif phase=="Victory" then "CORE DESTROYED!" elseif phase=="Announce" then "STARTS IN "..remaining.."s"
		else "YOUR FACTORY POWERS THE FINAL BLOW"
	primary.Visible=false
	subtitle.TextColor3=Color3.new(1,1,1)
	if phase=="Announce" then
		subtitle.Text="The bear is corrupted! Every factory fights: your crushers combine soon."
	elseif phase=="Assemble" then
		subtitle.Text=if you and you.fallback then "No crushers placed: you get a stand-in SUPER PRESS!"
			elseif you then E.Grades[you.grade].name.." · ASSEMBLING!" else "Factories are assembling their super crushers!"
	elseif phase=="Active" then
		local danger=false
		for _,h in packet.hazards or {} do if h.userId==me.UserId and not h.result then danger=true end end
		if not you then subtitle.Text="Factories are breaking the bear's shield!"
		elseif danger then subtitle.Text="BEAR SLAM! Get out of the red circle!" subtitle.TextColor3=Color3.fromRGB(255,110,110)
		elseif not you.present then subtitle.Text="Go back to your factory to keep crushing!" primary.Visible=true
		elseif now<=(you.critUntil or 0) then subtitle.Text="CRITICAL! Load a core into your super crusher NOW!" subtitle.TextColor3=Color3.fromRGB(255,218,65)
		elseif you.carrying then subtitle.Text="Load the core into your super crusher's glowing port!"
		elseif (you.loaded or 0)>1 then subtitle.Text="Core loaded! Your next hit does x"..you.loaded.." damage."
		else subtitle.Text="Pick up the purple cores on your plot and load them into your super crusher!" end
	elseif phase=="Finale" then
		subtitle.Text="Your factories powered it up. The Mega Crusher is finishing the core!"
	elseif phase=="Victory" then
		subtitle.Text=if you and you.reward>0 then "YOU EARNED "..Format.cash(you.reward).."!"
			elseif you then "Bear defeated! Stay on your plot longer next time to earn the reward."
			else "The factory is safe again!"
	elseif phase=="Recover" then
		subtitle.Text=if packet.outcome=="Victory" then "Your original crushers are returning." else packet.outcome.." · restoring the factory."
	end
end
primary.Activated:Connect(function() Net.event("Travel"):FireServer("Plot") end)
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
	local introPhase=packet.phase=="Announce" or packet.phase=="Assemble"
	if packet.phase=="Announce" then
		-- once per round, only at its start (not for someone arriving mid-announcement)
		if seenIntro~=packet.roundId and workspace:GetServerTimeNow()-packet.started<4 then
			seenIntro=packet.roundId playIntro(packet.started)
		end
	elseif introRunning and not introPhase then stopCamera() end
	if introPhase then -- the intro keeps going; the finale view never runs now
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
			if not hum or hum.Health<=0 or workspace.CurrentCamera~=cameraState.camera then stopCamera() else introStep(now) end
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
