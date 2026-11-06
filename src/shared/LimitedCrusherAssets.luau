--!strict
-- 6 Nov 2026: Willem's Lucky Weekend crushers (CrusherIncremental-Lucky-Weekend-Crushers).
-- Generated (scratch limited_gen/gen.py) from the Studio import (part centres, sizes, pivots in
-- Blender units, the import's axes: studio = (-blenderX, blenderZ, blenderY)) and the pack's
-- Model-manifest.json: strike moves/turns, and per-part keys (frames 1..80 mapped so each
-- model's impact frame lands on the rig's contact time). Merged into SpecialCrusherAssets.
return {
	["CloverOverdrive"] = {kit = "motion", grow = true, size = Vector3.new(4.58, 3.77, 3.042), bedTop = 1.92,
		inputCenter = Vector3.new(0, 2.13, -0.3), inputSize = 0.42,
		parts = {
			["Frame"] = {center = Vector3.new(0, 1.885, -0.041), size = Vector3.new(4.58, 3.77, 3.042), origin = Vector3.new(0, 0, 0)},
			["Jaw_Bottom"] = {center = Vector3.new(0, 1.2801, -0.2372), size = Vector3.new(0.8809, 1.1502, 0.4905), origin = Vector3.new(0, 1.45, -0.207)},
			["Jaw_Left"] = {center = Vector3.new(0.8499, 2.13, -0.2372), size = Vector3.new(1.1502, 0.8809, 0.4905), origin = Vector3.new(0.68, 2.13, -0.207)},
			["Jaw_Right"] = {center = Vector3.new(-0.8499, 2.13, -0.2372), size = Vector3.new(1.1502, 0.8809, 0.4905), origin = Vector3.new(-0.68, 2.13, -0.207)},
			["Jaw_Top"] = {center = Vector3.new(0, 2.9799, -0.2372), size = Vector3.new(0.8809, 1.1502, 0.4905), origin = Vector3.new(0, 2.81, -0.207)},
		},
		motion = {
			{name = "Jaw_Top", kind = "move", vector = Vector3.new(0, -0.18, 0), keys = {{0, 0}, {0.1992, 0}, {0.4648, 1}, {0.5068, 1}, {0.7691, 0}, {1, 0}}},
			{name = "Jaw_Right", kind = "move", vector = Vector3.new(0.18, 0, 0), keys = {{0, 0}, {0.1992, 0}, {0.4648, 1}, {0.5068, 1}, {0.7691, 0}, {1, 0}}},
			{name = "Jaw_Bottom", kind = "move", vector = Vector3.new(0, 0.18, 0), keys = {{0, 0}, {0.1992, 0}, {0.4648, 1}, {0.5068, 1}, {0.7691, 0}, {1, 0}}},
			{name = "Jaw_Left", kind = "move", vector = Vector3.new(-0.18, 0, 0), keys = {{0, 0}, {0.1992, 0}, {0.4648, 1}, {0.5068, 1}, {0.7691, 0}, {1, 0}}},
		},
		contact = {"Jaw_Top", "Jaw_Right", "Jaw_Bottom", "Jaw_Left"},
	},
	["HorseshoeComet"] = {kit = "motion", grow = true, size = Vector3.new(4.58, 3.1749, 3.042), bedTop = 0.735,
		inputCenter = Vector3.new(0.59, 0.96, -0.38), inputSize = 0.45,
		parts = {
			["Frame"] = {center = Vector3.new(0, 1.0324, -0.041), size = Vector3.new(4.58, 2.0648, 3.042), origin = Vector3.new(0, 0, 0)},
			["SwingArm"] = {center = Vector3.new(0.1197, 2.1754, -0.307), size = Vector3.new(3.0794, 1.9989, 0.794), origin = Vector3.new(-1.17, 1.72, -0.18)},
		},
		motion = {
			{name = "SwingArm", kind = "rotate", axis = Vector3.new(0, 0, 1), angle = -0.1833, keys = {{0, 0}, {0.2435, -0.34}, {0.4648, 1}, {0.4925, 1}, {0.7139, 0}, {1, 0}}},
		},
		contact = {"SwingArm"},
	},
	["JackpotFoundry"] = {kit = "motion", grow = true, size = Vector3.new(4.58, 3.6724, 3.042), bedTop = 0.78,
		inputCenter = Vector3.new(0, 1.03, -0.4), inputSize = 0.5,
		parts = {
			["Frame"] = {center = Vector3.new(0, 1.8362, -0.041), size = Vector3.new(4.58, 3.6724, 3.042), origin = Vector3.new(0, 0, 0)},
			["Lever"] = {center = Vector3.new(-2.015, 1.7925, 0.3125), size = Vector3.new(0.504, 1.519, 0.699), origin = Vector3.new(-1.97, 1.29, 0.22)},
			["RamShaft"] = {center = Vector3.new(0, 1.83, -0.41), size = Vector3.new(0.33, 0.61, 0.33), origin = Vector3.new(0, 1.83, -0.41)},
			["Reel_1"] = {center = Vector3.new(0.84, 2.4957, -0.085), size = Vector3.new(0.811, 0.7525, 0.749), origin = Vector3.new(0.84, 2.494, -0.085)},
			["Reel_2"] = {center = Vector3.new(0, 2.494, -0.0867), size = Vector3.new(0.811, 0.749, 0.7525), origin = Vector3.new(0, 2.494, -0.085)},
			["Reel_3"] = {center = Vector3.new(-0.84, 2.4957, -0.085), size = Vector3.new(0.811, 0.7525, 0.749), origin = Vector3.new(-0.84, 2.494, -0.085)},
			["StarRam"] = {center = Vector3.new(0, 1.7007, -0.4641), size = Vector3.new(1.2138, 0.6885, 1.1544), origin = Vector3.new(0, 1.6, -0.41)},
		},
		motion = {
			{name = "Reel_1", kind = "rotate", axis = Vector3.new(-1, 0, 0), angle = 6.2832, keys = {{0, 0}, {0.1101, 0}, {0.1318, 0.1111}, {0.1536, 0.2222}, {0.1753, 0.3333}, {0.1971, 0.4444}, {0.2188, 0.5556}, {0.2405, 0.6667}, {0.2623, 0.7778}, {0.284, 0.8889}, {0.3058, 1}, {1, 1}}},
			{name = "Reel_2", kind = "rotate", axis = Vector3.new(-1, 0, 0), angle = 14.1372, keys = {{0, 0}, {0.1223, 0}, {0.1322, 0.0476}, {0.1421, 0.0952}, {0.152, 0.1429}, {0.1619, 0.1905}, {0.1718, 0.2381}, {0.1817, 0.2857}, {0.1916, 0.3333}, {0.2015, 0.381}, {0.2114, 0.4286}, {0.2213, 0.4762}, {0.2312, 0.5238}, {0.2411, 0.5714}, {0.251, 0.619}, {0.2609, 0.6667}, {0.2708, 0.7143}, {0.2807, 0.7619}, {0.2906, 0.8095}, {0.3005, 0.8571}, {0.3104, 0.9048}, {0.3203, 0.9524}, {0.3302, 1}, {0.6084, 1}, {0.7041, 0.963}, {0.7998, 0.9259}, {0.8956, 0.8889}, {1, 0.8889}}},
			{name = "Reel_3", kind = "rotate", axis = Vector3.new(-1, 0, 0), angle = 18.8496, keys = {{0, 0}, {0.1345, 0}, {0.1427, 0.037}, {0.1509, 0.0741}, {0.159, 0.1111}, {0.1672, 0.1481}, {0.1753, 0.1852}, {0.1835, 0.2222}, {0.1916, 0.2593}, {0.1998, 0.2963}, {0.2079, 0.3333}, {0.2161, 0.3704}, {0.2242, 0.4074}, {0.2324, 0.4444}, {0.2405, 0.4815}, {0.2487, 0.5185}, {0.2569, 0.5556}, {0.265, 0.5926}, {0.2732, 0.6296}, {0.2813, 0.6667}, {0.2895, 0.7037}, {0.2976, 0.7407}, {0.3058, 0.7778}, {0.3139, 0.8148}, {0.3221, 0.8519}, {0.3302, 0.8889}, {0.3384, 0.9259}, {0.3466, 0.963}, {0.3547, 1}, {1, 1}}},
			{name = "StarRam", kind = "move", vector = Vector3.new(0, -0.54, 0), keys = {{0, 0}, {0.3547, 0}, {0.4648, 1}, {0.504, 1}, {0.752, 0}, {1, 0}}},
			{name = "RamShaft", kind = "move", vector = Vector3.new(0, -0.27, 0), keys = {{0, 0}, {0.3547, 0}, {0.4648, 1}, {0.504, 1}, {0.752, 0}, {1, 0}}},
			{name = "Lever", kind = "rotate", axis = Vector3.new(-1, 0, 0), angle = 0.733, keys = {{0, 0}, {0.0489, 0.5}, {0.0979, 1}, {0.1712, 1}, {0.3058, 0.5}, {0.4403, 0}, {1, 0}}},
		},
		contact = {"StarRam"},
	},
}
