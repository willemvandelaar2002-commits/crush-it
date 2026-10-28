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
local Reels=require(script.Parent.FactoryEventReels)
local Format=require(RS.Shared.Format)
local me=Players.LocalPlayer
local gui=Instance.new("ScreenGui") gui.Name="FactoryEventHud" gui.ResetOnSpawn=false
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling gui.DisplayOrder=4 gui.Parent=me:WaitForChild("PlayerGui")
-- Boss bar (reference style, 28 Oct): the bear's reactor in a tilted badge on
-- the left, a long chunky striped bar with 25/50/75% markers and the shield
-- percentage, under it the top damage dealers + YOU, and one instruction line.
local PURPLE=Color3.fromRGB(150,60,240) local INK=Style.Colors.Ink
local panel=Instance.new("Frame") panel.Name="EventPanel" panel.AnchorPoint=Vector2.new(.5,0)
panel.Position=UDim2.new(.5,0,0,122) panel.Size=UDim2.fromOffset(780,150) panel.BackgroundTransparency=1 panel.Visible=false panel.Parent=gui
local function label(parent,name,text,pos,size)
	local t=Instance.new("TextLabel") t.Name=name t.Text=text t.BackgroundTransparency=1
	t.Position=pos t.Size=size t.TextScaled=true t.ZIndex=4 t.Parent=parent Style.text(t,2.5) return t
end
local function round(p,r) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r) c.Parent=p end
local function edge(p,th,col) local s=Instance.new("UIStroke") s.Thickness=th s.Color=col or INK s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Parent=p return s end
-- bar
local bar=Instance.new("Frame") bar.Name="ShieldBar" bar.Position=UDim2.fromOffset(70,14) bar.Size=UDim2.fromOffset(600,52)
bar.BackgroundColor3=Color3.fromRGB(38,26,66) bar.ZIndex=2 bar.Parent=panel round(bar,10) edge(bar,4)
local fill=Instance.new("Frame") fill.Name="Fill" fill.Size=UDim2.fromScale(1,1) fill.BackgroundColor3=Color3.new(1,1,1) fill.ZIndex=3 fill.Parent=bar round(fill,8)
local fillGradient=Instance.new("UIGradient") fillGradient.Rotation=90 fillGradient.Parent=fill
local stripes=Style.studsImage(fill,26,.5) stripes.ZIndex=3 stripes.ImageColor3=Color3.fromRGB(110,30,200)
local shine=Instance.new("Frame") shine.Name="Shine" shine.Position=UDim2.new(0,6,0,5) shine.Size=UDim2.new(1,-12,0,5) shine.BackgroundColor3=Color3.new(1,1,1)
shine.BackgroundTransparency=.55 shine.BorderSizePixel=0 shine.ZIndex=4 shine.Parent=fill round(shine,3)
local markers={} -- (28 Oct: no 25/50/75 circles)
local percent=label(panel,"Percent","100%",UDim2.fromOffset(676,14),UDim2.fromOffset(100,52)) Style.text(percent,4)
local timer=label(panel,"Timer","",UDim2.fromOffset(686,72),UDim2.fromOffset(80,30)) timer.TextColor3=Color3.fromRGB(255,218,65)
timer.BackgroundColor3=INK timer.BackgroundTransparency=.3 round(timer,10)
do local pad=Instance.new("UIPadding") pad.PaddingTop=UDim.new(0,3) pad.PaddingBottom=UDim.new(0,3) pad.Parent=timer end
-- reactor badge (a live copy of the event bear's core when available)
local badge=Instance.new("Frame") badge.Name="Badge" badge.Position=UDim2.fromOffset(0,0) badge.Size=UDim2.fromOffset(84,84) badge.Rotation=-8
badge.BackgroundColor3=Color3.fromRGB(40,30,64) badge.ZIndex=6 badge.Parent=panel round(badge,14) edge(badge,4)
badge.Visible=false -- (28 Oct: Willem: no side badge)
do local g=Instance.new("UIGradient") g.Rotation=90 g.Color=ColorSequence.new(Color3.fromRGB(110,70,170),Color3.fromRGB(30,20,50)) g.Parent=badge end
local view=Instance.new("ViewportFrame") view.Name="Core" view.Size=UDim2.fromScale(1,1) view.BackgroundTransparency=1 view.ZIndex=7 view.Parent=badge
view.Ambient=Color3.fromRGB(200,170,255) view.LightColor=Color3.fromRGB(255,230,255)
local viewCam=Instance.new("Camera") viewCam.FieldOfView=40 viewCam.Parent=view view.CurrentCamera=viewCam
local viewModel=nil
task.spawn(function()
	local library=RS:WaitForChild("FactoryEventMeshes",20)
	local template=library and library:FindFirstChild("FactoryBear")
	local Rig=RS.Shared:FindFirstChild("FactoryBearRig")
	if template and Rig then
		local ok,core=pcall(function() return require(Rig).core(template,CFrame.new(),4) end)
		if ok and core then core.Parent=view viewModel=core viewCam.CFrame=CFrame.lookAt(Vector3.new(0,1.2,8.5),Vector3.zero) return end
	end
	local ball=Instance.new("Part") ball.Shape=Enum.PartType.Ball ball.Size=Vector3.one*4 ball.Color=PURPLE ball.Material=Enum.Material.Neon ball.Parent=view
	viewModel=ball viewCam.CFrame=CFrame.lookAt(Vector3.new(0,1,8),Vector3.zero)
end)
-- top damage + YOU
local board=Instance.new("Frame") board.Name="TopDamage" board.AnchorPoint=Vector2.new(.5,0) board.Position=UDim2.new(.5,0,0,74)
board.Size=UDim2.fromOffset(470,40) board.BackgroundColor3=Color3.fromRGB(22,20,38) board.BackgroundTransparency=.15 board.ZIndex=2 board.Parent=panel round(board,20) edge(board,3)
local layout=Instance.new("UIListLayout") layout.FillDirection=Enum.FillDirection.Horizontal layout.HorizontalAlignment=Enum.HorizontalAlignment.Center
layout.VerticalAlignment=Enum.VerticalAlignment.Center layout.Padding=UDim.new(0,8) layout.SortOrder=Enum.SortOrder.LayoutOrder layout.Parent=board
local crown=label(board,"Crown","👑",UDim2.new(),UDim2.fromOffset(26,26)) crown.LayoutOrder=0
local RANK={Color3.fromRGB(255,206,40),Color3.fromRGB(200,210,225),Color3.fromRGB(205,130,70)}
local function entry(order,rankText,rankColor)
	local f=Instance.new("Frame") f.Name="Entry"..order f.LayoutOrder=order f.Size=UDim2.fromOffset(96,32) f.BackgroundTransparency=1 f.Parent=board
	local head=Instance.new("ImageLabel") head.Name="Head" head.Size=UDim2.fromOffset(30,30) head.Position=UDim2.fromOffset(14,1)
	head.BackgroundColor3=Color3.fromRGB(60,60,80) head.ZIndex=4 head.Parent=f round(head,15) local hs=edge(head,2.5,rankColor or Color3.fromRGB(120,220,90))
	local r=Instance.new("TextLabel") r.Name="Rank" r.Size=UDim2.fromOffset(20,20) r.Position=UDim2.fromOffset(0,6) r.BackgroundColor3=rankColor or Color3.fromRGB(90,200,90)
	r.Text=rankText r.TextScaled=true r.ZIndex=5 r.Parent=f round(r,10) Style.text(r,1.5) edge(r,2)
	local pct=label(f,"Pct","0%",UDim2.fromOffset(48,5),UDim2.fromOffset(48,22)) pct.TextXAlignment=Enum.TextXAlignment.Left pct.ZIndex=4
	return {frame=f,head=head,rank=r,pct=pct,stroke=hs,userId=nil}
end
local entries={} for i=1,3 do entries[i]=entry(i,tostring(i),RANK[i]) entries[i].pct.TextColor3=RANK[i] end
local divider=Instance.new("Frame") divider.LayoutOrder=4 divider.Size=UDim2.fromOffset(3,26) divider.BackgroundColor3=Color3.fromRGB(80,80,110) divider.BorderSizePixel=0 divider.Parent=board
local mine=entry(5,"",Color3.fromRGB(110,230,90)) mine.frame.Size=UDim2.fromOffset(110,32)
mine.rank.Text="#1" mine.pct.TextColor3=Color3.fromRGB(130,255,110)
local youTag=Instance.new("TextLabel") youTag.Text="YOU" youTag.Size=UDim2.fromOffset(34,14) youTag.Position=UDim2.fromOffset(12,-9) youTag.BackgroundColor3=Color3.fromRGB(70,200,80)
youTag.TextScaled=true youTag.ZIndex=6 youTag.Parent=mine.frame round(youTag,6) Style.text(youTag,1.2)
mine.rank.Size=UDim2.fromOffset(26,20) mine.rank.Position=UDim2.fromOffset(46,6) mine.rank.BackgroundTransparency=1 mine.pct.Position=UDim2.fromOffset(74,5)
local subtitle=label(panel,"Instruction","",UDim2.fromOffset(100,120),UDim2.fromOffset(580,30))
subtitle.BackgroundColor3=INK subtitle.BackgroundTransparency=.3 round(subtitle,12)
do local pad=Instance.new("UIPadding") pad.PaddingTop=UDim.new(0,4) pad.PaddingBottom=UDim.new(0,4) pad.PaddingLeft=UDim.new(0,14) pad.PaddingRight=UDim.new(0,14) pad.Parent=subtitle end
local function headshot(userId) return "rbxthumb://type=AvatarHeadShot&id="..userId.."&w=48&h=48" end
local function paintBoard(packet)
	if not packet then return end
	local list=table.clone(packet.participants or {})
	table.sort(list,function(a,b) return (a.dealt or 0)>(b.dealt or 0) end)
	local maxHp=math.max(1e-9,packet.maxHp or 0)
	for i=1,3 do
		local e=entries[i] local r=list[i]
		e.frame.Visible=r~=nil
		if r then
			if e.userId~=r.userId then e.userId=r.userId e.head.Image=headshot(r.userId) end
			e.pct.Text=string.format("%.1f%%",(r.dealt or 0)/maxHp*100)
		end
	end
	local myRank,myDealt=0,0
	for i,r in list do if r.userId==me.UserId then myRank=i myDealt=r.dealt or 0 end end
	mine.frame.Visible=myRank>0 divider.Visible=myRank>0
	if myRank>0 then
		if mine.userId~=me.UserId then mine.userId=me.UserId mine.head.Image=headshot(me.UserId) end
		mine.rank.Text="#"..myRank mine.pct.Text=string.format("%.1f%%",myDealt/maxHp*100)
	end
end
local reels=Reels.new(gui)
local primary=Instance.new("TextButton") primary.Name="GoToFactory" primary.Text="MY FACTORY"
primary.AnchorPoint=Vector2.new(.5,0) primary.Position=UDim2.new(.5,0,1,4) primary.Size=UDim2.fromOffset(200,40)
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
local shown=1
local packet=nil local visuals=Visuals.new() local cameraState=nil local seenFinale=nil local seenIntro=nil
local stopped=false local connections={} local lastSoundBeat=-1 local finaleSound=nil local buttonColor=nil
local impact=Instance.new("Sound") impact.Name="FactoryEventImpact" impact.SoundId="rbxassetid://"..Config.Sounds.Thud
impact.Volume=.22 impact.Parent=SoundService
-- Event audio (28 Oct): Willem's song while a round runs (the normal music
-- fades out), and one-shot effects for the intro, cores, slams and the finale.
local sfx={}
for name,id in E.Sounds do
	local s=Instance.new("Sound") s.Name="Event"..name s.SoundId="rbxassetid://"..id s.Parent=SoundService sfx[name]=s
end
local function play(name,volume,speed)
	local s=sfx[name] if not s then return end
	local c=s:Clone() c.Volume=volume or .6 c.PlaybackSpeed=speed or 1 c.Parent=SoundService c:Play()
	c.Ended:Once(function() c:Destroy() end) game:GetService("Debris"):AddItem(c,12)
end
local song=Instance.new("Sound") song.Name="EventMusic" song.SoundId="rbxassetid://"..E.Music song.Looped=true song.Volume=0 song.Parent=SoundService
task.spawn(function() local list={song} for _,s in sfx do table.insert(list,s) end pcall(function() Content:PreloadAsync(list) end) end)
local normalVolume=nil local musicState=false
local function musicOn(on)
	if on==musicState then return end musicState=on
	local normal=SoundService:FindFirstChild("BackgroundMusic")
	if on then
		if not song.IsPlaying then song:Play() end
		TweenService:Create(song,TweenInfo.new(1.5),{Volume=E.MusicVolume}):Play()
		if normal and normalVolume==nil then normalVolume=normal.Volume TweenService:Create(normal,TweenInfo.new(1.5),{Volume=0}):Play() end
	else
		if song.IsPlaying then TweenService:Create(song,TweenInfo.new(2),{Volume=0}):Play() task.delay(2,function() if song.Volume<.01 then song:Stop() end end) end
		if normal and normalVolume~=nil then TweenService:Create(normal,TweenInfo.new(2),{Volume=normalVolume}):Play() normalVolume=nil end
	end
end
-- cue(key, condition, fn): runs fn once per round when condition turns true
local fired={} local firedRound=nil
local function cue(key,condition,fn)
	if not packet then return end
	if firedRound~=packet.roundId then fired={} firedRound=packet.roundId end
	if condition and not fired[key] then fired[key]=true fn() end
end
local lastYou=nil local seenHazards={}
local function soundStep(now)
	local ph=packet.phase local age=now-packet.started
	musicOn(ph~="Idle" and ph~="Recover")
	if ph=="Announce" then
		cue("rumble",age>=.2,function() play("Clunk",.7,.6) play("Impact",.5,.5) end)
		cue("lift",age>=1.3,function() play("Whoosh",.8,.7) end)
		cue("flash",age>=2.6,function() play("Shatter",.6,.8) play("Charge",.5,1.3) end)
		cue("land",age>=3.2,function() play("Impact",1,.7) end)
		cue("evil",age>=3.6,function() play("Charge",.6,.8) end)
		cue("roar",age>=5.2,function() play("Roar",1,.9) play("Screech",.8,.8) end)
		cue("beam",age>=7.2,function() play("Charge",.7,1.1) end)
		cue("swoop",age>=7.6,function() play("Whoosh",.7,.6) end)
	elseif ph=="Assemble" then
		cue("fly",age>=.5,function() play("Whoosh",.8,.8) play("Clunk",.6,1) end)
		cue("fly2",age>=1.3,function() play("Whoosh",.6,1.1) end)
		cue("merge",age>=2.6,function() play("Sparkle",.8,1) play("PowerUp",.7,.8) end)
		cue("rise",age>=E.Assemble*.5,function() play("Clunk",.9,.7) play("Impact",.6,.6) end)
		cue("ready",age>=E.Assemble*.85,function() play("Impact",.9,.9) play("Charge",.5,1.4) end)
	elseif ph=="Active" then
		local you=packet.you
		if you and lastYou then
			if you.carrying and not lastYou.carrying then play("Sparkle",.7,1.2) end
			if (you.loaded or 0)>(lastYou.loaded or 0) then play("PowerUp",.8,if (you.loaded or 0)>E.Cores.Multiplier then .8 else 1.1) end
			if (you.critUntil or 0)>now and (lastYou.critUntil or 0)<=now then play("Alarm",.4,1.3) play("Sparkle",.6,.8) end
		end
		lastYou=you
		for _,h in packet.hazards or {} do
			if not seenHazards[h.id] then
				seenHazards[h.id]=true
				local mine=h.userId==me.UserId
				play("Screech",if mine then .7 else .25,1.1) if mine then play("Alarm",.5,1) end
				task.delay(math.max(0,h.at-now),function() play("Impact",if mine then 1 else .35,.8) end)
			end
		end
	elseif ph=="Finale" then
		cue("fcharge",age>=.1,function() play("Charge",.9,.7) play("Roar",.7,1.2) end)
		cue("fbreak",age>=2.85,function() play("Shatter",1,.9) play("Impact",1,.6) end)
		cue("fscreech",age>=3.2,function() play("Screech",.8,.7) end)
	elseif ph=="Victory" then
		cue("fanfare",age>=.1,function() play("Fanfare",.8,1) end)
	end
end
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
		-- A: from the open hall in front of the bear (nothing of the plots in the way)
		local side=face:Cross(Vector3.yAxis)
		shots[1]={from=under(head+face*r*2+side*r*.4+Vector3.new(0,r*.1,0)),to=under(head+face*r*1.8-side*r*.15),look=head-Vector3.new(0,r*.3,0),fov=62}
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
		local middle=(o*CFrame.new(0,32,-13)).Position
		shots[4]={from=(o*CFrame.new(-26,58,100)).Position,to=(o*CFrame.new(0,40,76)).Position,look=middle,fov=66} -- straight down the walkway into the gap between the banks
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
	-- local flag for other HUD (the crusher toolbar hides while a round runs)
	local running=if phase~="Idle" then true else nil
	if me:GetAttribute("FactoryEventRunning")~=running then me:SetAttribute("FactoryEventRunning",running) end
	-- no panel while the intro/assembly plays (Announce, Assemble)
	panel.Visible=phase~="Idle" and phase~="Announce" and phase~="Assemble" and not (cameraState~=nil and cameraState.mode=="intro")
	-- win reward reels (server already granted the results); they replace the
	-- boss bar until the round is over
	if phase=="Victory" and you and type(you.prizes)=="table" and #you.prizes>0 and reels.round~=packet.roundId then
		reels:play(packet.roundId,you.prizes,you.values,{
			onTick=function() play("Clunk",.12,1.8) end,
			onLand=function(_,won) play("Sparkle",if won.kind=="crusher" then .9 else .5) if won.kind=="crusher" then play("Fanfare",.6) end end,
		})
	elseif reels.round and phase~="Victory" and phase~="Recover" then reels:clear() end
	if reels.round then panel.Visible=false end
	if not panel.Visible then return end
	local remaining=math.max(0,math.ceil(packet.ends-now))
	timer.Text=string.format("%d:%02d",math.floor(remaining/60),remaining%60)
	local fraction=if packet.maxHp>0 then math.clamp(packet.hp/packet.maxHp,0,1) else 1
	if phase~="Active" then fraction=if phase=="Finale" or phase=="Victory" or phase=="Recover" then 0 else 1 end
	shown=shown+(fraction-shown)*.15 -- smooth drain
	fill.Size=UDim2.fromScale(math.max(shown,.001),1) fill.Visible=shown>.002
	-- purple at full shield, magenta then orange as it breaks
	local warm=1-fraction
	fillGradient.Color=ColorSequence.new(Color3.fromRGB(215,95,255):Lerp(Color3.fromRGB(255,150,60),warm*warm),Color3.fromRGB(125,25,225):Lerp(Color3.fromRGB(220,50,70),warm*warm))
	percent.Text=math.ceil(fraction*100).."%"
	for _,m in markers do
		local broken=fraction*100<=m.pct
		m.gradient.Color=if broken then ColorSequence.new(Color3.fromRGB(255,235,120),Color3.fromRGB(230,140,20)) else ColorSequence.new(Color3.fromRGB(150,155,175),Color3.fromRGB(45,48,62))
		m.stroke.Color=if broken then Color3.fromRGB(120,60,0) else INK
	end
	if viewModel then
		local spin=CFrame.Angles(.25,now*1.2,0)
		if viewModel:IsA("Model") then viewModel:PivotTo(spin) else viewModel.CFrame=spin end
	end
	badge.Rotation=-8+math.sin(now*2)*3
	paintBoard(packet)
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
		visuals:step(now) renderHud(now) soundStep(now)
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
