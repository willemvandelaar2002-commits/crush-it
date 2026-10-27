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
} :: {[string]: string}
I.Ready={Titan=true,Laser=true,Plasma=true,Gravity=true,Quake=true,Cyclone=true,Mecha=true,
	Quantum=true,Starforge=true,DragonJaw=true,BlackHole=true,Clockwork=true,FactoryHeart=true,
	Mega=true,Thunder=true,Frost=true,Furnace=true,ScrapShark=true,SteamHammer=true,JunkyardJaw=true,
	Cobalt=true,Gearbox=true,Flywheel=true,Pneumatic=true,DoubleStamp=true,Boiler=true,Conveyor=true,
	Bumper=true,Steel=true,Clamp=true,Spring=true,Screw=true,Rivet=true,Bottle=true,Bench=true} :: {[string]: boolean}
function I.image(typeId: string): string?
	local uri=I.Overrides[typeId] if uri and uri~="" then return uri end
	return if I.Ready[typeId] then "rbxgameasset://Images/Crusher_"..typeId else nil
end
return I
