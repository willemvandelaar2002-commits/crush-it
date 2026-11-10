--!strict
-- 10 Nov: the seven Mythic crushers' new models (Willem's ChatGPT pack "Mythic Models": image-to-3D,
-- 3,000 triangles, 1024 PBR maps). They replace the old flat-coloured Blender models; type ids,
-- rarities, stats, offers and icons are unchanged. Claude's pass (Blender 5.2, same routine as the
-- Eternals): straight cuts only around the moving parts, cuts capped, back to ~3,200 triangles, the
-- explicit Metalness/Roughness maps wired in for the FBX. Motion metadata in the SpecialCrushers
-- "motion" format: Blender units, Studio axes (studio = (-bx, bz, by)), relative to the Frame's ground.
-- Template: ServerStorage.SpecialCrusherMeshes.<Id> (place file, Willem publishes).
-- Files: Downloads\CrushIt-Coating-and-Plot-Props\Mythic (FBX + GameReady .blend).
--   Presses (Jackpot, Candy, Prism, Seraph, Disco): the ram slides down onto the bed and its
--     PistonShaft stretches out of the fixed sleeve above it.
--   PhantomPirate: the chest lid, teeth and skull crest bite 30 degrees down about the rear hinge.
--   KrakenClamp: both tentacle jaws swing 12 degrees inward about their gold shoulder hubs.
return {
	["JackpotPress"] = {kit = "motion", grow = true, size = Vector3.new(8.0106, 7.802, 4.8091),
		inputCenter = Vector3.new(0.4, 1.795, 0.2), inputSize = 0.45, bedTop = 1.5700,
		parts = {
			["Frame"] = {center = Vector3.new(-0.0067, 3.9076, 0.0093), size = Vector3.new(8.0106, 7.802, 4.7046), origin = Vector3.new(0, 0, 0)},
			["Ram"] = {center = Vector3.new(0.2296, 2.9646, 0.0066), size = Vector3.new(4.3261, 2.1108, 4.8091), origin = Vector3.new(0, 0, 0)},
			["PistonShaft"] = {center = Vector3.new(0.4426, 4.32, -0.0232), size = Vector3.new(0.9969, 0.6, 1.0023), origin = Vector3.new(0.4, 4.62, -0.2)},
		},
		motion = {
			{name = "Ram", kind = "move", vector = Vector3.new(0, -0.5, 0), curve = "press"},
			{name = "PistonShaft", kind = "extend", axis = "Y", ratio = 1.8333, curve = "press"},
		},
		contact = {"Ram"},
	},
	["CandyColossus"] = {kit = "motion", grow = true, size = Vector3.new(7.5965, 8.5539, 7.9877),
		inputCenter = Vector3.new(0, 2.31, -1.5), inputSize = 0.5, bedTop = 2.0600,
		parts = {
			["Frame"] = {center = Vector3.new(0.0152, 4.2762, 0.0119), size = Vector3.new(7.5965, 8.5539, 7.9877), origin = Vector3.new(0, 0, 0)},
			["Ram"] = {center = Vector3.new(0.0232, 3.8731, -1.4996), size = Vector3.new(3.2532, 1.4139, 2.9848), origin = Vector3.new(0, 0, 0)},
			["PistonShaft"] = {center = Vector3.new(0.0914, 5.01, -1.1325), size = Vector3.new(1.4973, 0.86, 1.544), origin = Vector3.new(0, 5.44, -1.2)},
		},
		motion = {
			{name = "Ram", kind = "move", vector = Vector3.new(0, -0.6, 0), curve = "press"},
			{name = "PistonShaft", kind = "extend", axis = "Y", ratio = 1.6977, curve = "press"},
		},
		contact = {"Ram"},
	},
	["PrismMech"] = {kit = "motion", grow = true, size = Vector3.new(7.9641, 6.7562, 6.3675),
		inputCenter = Vector3.new(0, 1.4, 0), inputSize = 0.4, bedTop = 1.2000,
		parts = {
			["Frame"] = {center = Vector3.new(0.0024, 3.3775, 0.0011), size = Vector3.new(7.9641, 6.7562, 6.3675), origin = Vector3.new(0, 0, 0)},
			["Ram"] = {center = Vector3.new(-0.0364, 2.8825, -0.0874), size = Vector3.new(3.7486, 2.3951, 3.417), origin = Vector3.new(0, 0, 0)},
			["PistonShaft"] = {center = Vector3.new(0.1, 4.3, 0.1247), size = Vector3.new(1.3821, 0.44, 1.5921), origin = Vector3.new(0, 4.52, 0)},
		},
		motion = {
			{name = "Ram", kind = "move", vector = Vector3.new(0, -0.4, 0), curve = "press"},
			{name = "PistonShaft", kind = "extend", axis = "Y", ratio = 1.9091, curve = "press"},
		},
		contact = {"Ram"},
	},
	["SeraphPress"] = {kit = "motion", grow = true, size = Vector3.new(8.0189, 7.286, 5.4308),
		inputCenter = Vector3.new(0, 1.88, 0), inputSize = 0.4, bedTop = 1.6800,
		parts = {
			["Frame"] = {center = Vector3.new(0.0024, 3.6416, -0.0018), size = Vector3.new(8.0189, 7.286, 5.4308), origin = Vector3.new(0, 0, 0)},
			["Ram"] = {center = Vector3.new(-0.0038, 3.0453, -0.044), size = Vector3.new(2.9538, 1.0698, 2.3414), origin = Vector3.new(0, 0, 0)},
			["PistonShaft"] = {center = Vector3.new(0.0176, 3.915, 0.1476), size = Vector3.new(1.171, 0.67, 1.2291), origin = Vector3.new(0, 4.25, 0)},
		},
		motion = {
			{name = "Ram", kind = "move", vector = Vector3.new(0, -0.5, 0), curve = "press"},
			{name = "PistonShaft", kind = "extend", axis = "Y", ratio = 1.7463, curve = "press"},
		},
		contact = {"Ram"},
	},
	["DiscoDestroyer"] = {kit = "motion", grow = true, size = Vector3.new(7.9912, 7.9209, 5.4529),
		inputCenter = Vector3.new(0, 2.04, 0.25), inputSize = 0.4, bedTop = 1.8400,
		parts = {
			["Frame"] = {center = Vector3.new(-0.001, 3.9682, -0.0032), size = Vector3.new(7.9912, 7.9209, 5.4529), origin = Vector3.new(0, 0, 0)},
			["Ram"] = {center = Vector3.new(0.0026, 4.0845, 0.2952), size = Vector3.new(3.2494, 3.0716, 3.0174), origin = Vector3.new(0, 0, 0)},
			["PistonShaft"] = {center = Vector3.new(0.0278, 5.945, 0.4154), size = Vector3.new(1.348, 0.65, 1.3238), origin = Vector3.new(0, 6.27, 0.25)},
		},
		motion = {
			{name = "Ram", kind = "move", vector = Vector3.new(0, -0.45, 0), curve = "press"},
			{name = "PistonShaft", kind = "extend", axis = "Y", ratio = 1.6923, curve = "press"},
		},
		contact = {"Ram"},
	},
	["PhantomPirate"] = {kit = "motion", grow = true, size = Vector3.new(7.9607, 8.3173, 7.4889),
		inputCenter = Vector3.new(0, 2.91, -1.6), inputSize = 0.5, bedTop = 2.6600,
		parts = {
			["Frame"] = {center = Vector3.new(-0.0068, 4.157, 0.0067), size = Vector3.new(7.9607, 8.3173, 7.4889), origin = Vector3.new(0, 0, 0)},
			["Lid"] = {center = Vector3.new(-0.0173, 5.7845, -0.4423), size = Vector3.new(7.0107, 2.769, 4.0847), origin = Vector3.new(0, 3.9, 1.55)},
		},
		motion = {
			{name = "Lid", kind = "rotate", axis = Vector3.new(-1, 0, 0), angle = 0.5236, curve = "press"},
		},
		contact = {"Lid"},
	},
	["KrakenClamp"] = {kit = "motion", grow = true, size = Vector3.new(8.0059, 8.68, 7.3405),
		inputCenter = Vector3.new(0, 3.7, -1), inputSize = 0.6, bedTop = 3.4000,
		parts = {
			["Frame"] = {center = Vector3.new(0.0017, 4.3407, 0.0107), size = Vector3.new(8.0059, 8.68, 7.3405), origin = Vector3.new(0, 0, 0)},
			["Jaw_L"] = {center = Vector3.new(2.2031, 4.3067, -0.5373), size = Vector3.new(3.2341, 4.1547, 3.9256), origin = Vector3.new(3.45, 5.5, -0.25)},
			["Jaw_R"] = {center = Vector3.new(-2.1844, 4.2946, -0.7601), size = Vector3.new(3.266, 4.1195, 3.5554), origin = Vector3.new(-3.45, 5.5, -0.25)},
		},
		motion = {
			{name = "Jaw_L", kind = "rotate", axis = Vector3.new(0, 0, 1), angle = -0.2094, curve = "press"},
			{name = "Jaw_R", kind = "rotate", axis = Vector3.new(0, 0, 1), angle = 0.2094, curve = "press"},
		},
		contact = {"Jaw_L", "Jaw_R"},
	},
}
