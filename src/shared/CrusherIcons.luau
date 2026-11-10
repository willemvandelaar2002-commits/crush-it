--!strict
-- Actual image content IDs take precedence. Named assets must be uploaded to
-- THIS experience's Asset Manager, with the supplied Crusher_<TypeId> names.
local I={}
I.Overrides={
	Bench="rbxassetid://79719083127025",BlackHole="rbxassetid://71766010804910",
	Boiler="rbxassetid://128485049172429",Bottle="rbxassetid://136908564407956",
	Bumper="rbxassetid://74524246034812",Clamp="rbxassetid://115834500404949",
	Clockwork="rbxassetid://106268597418524",Cobalt="rbxassetid://88879667321103",
	Conveyor="rbxassetid://138902731662627",Cyclone="rbxassetid://130819856264891",
	DoubleStamp="rbxassetid://81487076089282",DragonJaw="rbxassetid://126907883991741",
	FactoryHeart="rbxassetid://102981849282332",Flywheel="rbxassetid://114265124107464",
	Frost="rbxassetid://80388778578245",Furnace="rbxassetid://133576142187494",
	Gearbox="rbxassetid://83749251037061",Gravity="rbxassetid://140489774787044",
	JunkyardJaw="rbxassetid://84259457296508",Laser="rbxassetid://126202679885390",
	Mecha="rbxassetid://133844615284226",Mega="rbxassetid://83458352865806",
	Plasma="rbxassetid://75962279482979",Pneumatic="rbxassetid://111144052831483",
	Quake="rbxassetid://70381068849610",Quantum="rbxassetid://76047476059921",
	Rivet="rbxassetid://110716375711851",ScrapShark="rbxassetid://103271677428161",
	Screw="rbxassetid://110742848533015",Spring="rbxassetid://120889457829052",
	Starforge="rbxassetid://100677266625280",SteamHammer="rbxassetid://76591643349075",
	Steel="rbxassetid://120668077807036",Thunder="rbxassetid://126706827501232",
	Titan="rbxassetid://85273013130634",
	-- Mythics (Brasslight Studio images, 27 Oct)
	JackpotPress="rbxassetid://103371238513648",SeraphPress="rbxassetid://74047509223727",
	PrismMech="rbxassetid://132990678490693",PhantomPirate="rbxassetid://73886794705532",
	CandyColossus="rbxassetid://90430936805606",
	-- Imported specials (Brasslight Studio images, 27 Oct)
	Magnetron="rbxassetid://97262603783580",RocketPress="rbxassetid://72212153155335",
	TwinTitan="rbxassetid://98990714536752",Toyzilla="rbxassetid://89985784829786",
	GoldenKing="rbxassetid://101308752195885",
	-- Crate crushers (27 Oct Blender pack)
	WindUpWrecker="rbxassetid://76820861604914",KrakenClamp="rbxassetid://118908620786900",
	GumballGobbler="rbxassetid://97847833312808",DuckyDynamo="rbxassetid://95075734278359",
	DiscoDestroyer="rbxassetid://98862753364198",ArcadeClaw="rbxassetid://76980432342314",
	-- 10 Nov: Willem's new matching set (the image ids behind his decal uploads): the Secret/Divine chase crushers
	-- (were 29 Oct renders), the Exotics (were 8 Nov), the six Eternals and the Lucky Weekend three
	-- (no icon before).
	AstralLeviathan="rbxassetid://85265348836647",ArchangelAnvil="rbxassetid://81204722224449",
	OrigamiClamp="rbxassetid://92175483553785",RiftMonarch="rbxassetid://73265822162790",
	Worldbreaker="rbxassetid://111754069511137",RealitySplitter="rbxassetid://71408698764769",
	ChronoColossus="rbxassetid://96351543847117",InfinityEngine="rbxassetid://88479980666829",
	MaglevMauler="rbxassetid://116974647311097",WreckingWinch="rbxassetid://114101580700974",
	DrawbridgeCrusher="rbxassetid://102044781944167",CamCruncher="rbxassetid://73723252070774",
	ScrewStamper="rbxassetid://75407297769558",ShadowShredder="rbxassetid://96666882667645",
	VoidVise="rbxassetid://97155601435606",EclipseEngine="rbxassetid://79394832262598",
	HaloHammer="rbxassetid://107400526500870",NightRipper="rbxassetid://79860465863804",
	CelestialCrusher="rbxassetid://122800380371458",AuroraPress="rbxassetid://107445261283624",
	HorseshoeComet="rbxassetid://125219510469476",CloverOverdrive="rbxassetid://140183467587517",
	JackpotFoundry="rbxassetid://96009213996199",
} :: {[string]: string}
-- 10 Nov: the six Eternals load by name (Willem's Asset Manager import of Eternal\Icons: Crusher_<Id>)
I.Ready={AstralLeviathan=true,ChronoColossus=true,Worldbreaker=true,InfinityEngine=true,RiftMonarch=true,RealitySplitter=true,
	MaglevMauler=true,OrigamiClamp=true,WreckingWinch=true,CamCruncher=true,ScrewStamper=true,DrawbridgeCrusher=true,Titan=true,Laser=true,Plasma=true,Gravity=true,Quake=true,Cyclone=true,Mecha=true,
	Quantum=true,Starforge=true,DragonJaw=true,BlackHole=true,Clockwork=true,FactoryHeart=true,
	Mega=true,Thunder=true,Frost=true,Furnace=true,ScrapShark=true,SteamHammer=true,JunkyardJaw=true,
	Cobalt=true,Gearbox=true,Flywheel=true,Pneumatic=true,DoubleStamp=true,Boiler=true,Conveyor=true,
	Bumper=true,Steel=true,Clamp=true,Spring=true,Screw=true,Rivet=true,Bottle=true,Bench=true} :: {[string]: boolean}
function I.image(typeId: string): string?
	local uri=I.Overrides[typeId] if uri and uri~="" then return uri end
	return if I.Ready[typeId] then "rbxgameasset://Images/Crusher_"..typeId else nil
end
return I
