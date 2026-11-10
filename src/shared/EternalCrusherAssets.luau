--!strict
-- 9 Nov: ETERNAL crushers (proposed tier, not in the game yet: no type, odds or Index entry).
-- Motion metadata in the SpecialCrushers "motion" format. Units: Blender units, axes: Studio's
-- (studio = (-bx, bz, by)), measured on Willem's Studio import (cm scale) relative to the Frame's
-- ground pivot. Template: ServerStorage.SpecialCrusherMeshes.<Id> (place file, Willem publishes).
--
-- AstralLeviathan: Claude's Blender pass on the Hunyuan3D image-to-3D prototype (100k faces ->
-- Frame 6,000 + UpperJaw 3,000 triangles, 1024 colour texture). The upper head swings about the
-- gold cheek hinge: it rests tipped 12 degrees up (baked into the import) and bites 32 degrees down,
-- where upper and lower teeth meet. Files: Downloads\CrushIt-Coating-and-Plot-Props\AstralLeviathan.--
-- 10 Nov: the other five (Willem's ChatGPT pack "Eternal Five": Hunyuan3D image-to-3D, reduced to
-- 3,000 triangles each). Claude's pass (same routine as the Leviathan, Blender 5.2): straight cuts
-- only around the moving parts, cuts capped with the model's own navy, stray chips dropped, back to
-- ~3,200 triangles in total. Files: Downloads\CrushIt-Coating-and-Plot-Props\Eternal\<Id>.
--   ChronoColossus: the upper crystal press slides 0.32 down onto the lower crystal.
--   Worldbreaker: the lava boulder, its collar and the upper arm swing 17 degrees down about the
--     elbow bolt onto the lava anvil.
--   InfinityEngine: the violet crossbar and its crystal press 0.32 down onto the white anvil.
--   RiftMonarch: the upper claw fingers close 10 degrees down, the lower ones 10 degrees up.
--   RealitySplitter: the two crystal jaws tip 9 degrees inward about the gold axle; the scrap
--     floats between their inner spikes.
return {
	["AstralLeviathan"] = {kit = "motion", grow = true, size = Vector3.new(4.3691, 6.0045, 3.1873), bedTop = 2.36,
		inputCenter = Vector3.new(-1.25, 2.62, 0), inputSize = 0.32,
		parts = {
			["Frame"] = {center = Vector3.new(0.1958, 3.0015, 0.0002), size = Vector3.new(4.011, 6.0045, 3.1874), origin = Vector3.new(0, 0, 0)},
			["UpperJaw"] = {center = Vector3.new(-0.9968, 4.3966, 0.0014), size = Vector3.new(2.3423, 2.814, 1.8343), origin = Vector3.new(-0.19, 3.69, 0)},
		},
		motion = {
			{name = "UpperJaw", kind = "rotate", axis = Vector3.new(0, 0, 1), angle = 0.5585, curve = "press"},
		},
		contact = {"UpperJaw"},
	},
	["ChronoColossus"] = {kit = "motion", grow = true, size = Vector3.new(4.5903, 5.9985, 4.2767),
		inputCenter = Vector3.new(0, 3.1, 0), inputSize = 0.35, bedTop = 2.925,
		parts = {
			["Frame"] = {center = Vector3.new(-0.0034, 3.0006, -0.0019), size = Vector3.new(4.5903, 5.9985, 4.2767), origin = Vector3.new(0, 0, 0)},
			["UpperPress"] = {center = Vector3.new(-0.0002, 4, 0.0015), size = Vector3.new(2.1008, 1.1004, 1.7941), origin = Vector3.new(0, 0, 0)},
		},
		motion = {
			{name = "UpperPress", kind = "move", vector = Vector3.new(0, -0.32, 0), curve = "press"},
		},
		contact = {"UpperPress"},
	},
	["Worldbreaker"] = {kit = "motion", grow = true, size = Vector3.new(4.4894, 6.0017, 4.188),
		inputCenter = Vector3.new(-0.75, 2.25, 0), inputSize = 0.4, bedTop = 2.05,
		parts = {
			["Frame"] = {center = Vector3.new(0.0004, 2.6289, -0), size = Vector3.new(4.4894, 5.2618, 4.188), origin = Vector3.new(0, 0, 0)},
			["Boulder"] = {center = Vector3.new(-0.4605, 4.2998, -0.3076), size = Vector3.new(3.521, 3.3996, 2.426), origin = Vector3.new(1.45, 4.85, 0)},
		},
		motion = {
			{name = "Boulder", kind = "rotate", axis = Vector3.new(0, 0, 1), angle = 0.2967, curve = "press"},
		},
		contact = {"Boulder"},
	},
	["InfinityEngine"] = {kit = "motion", grow = true, size = Vector3.new(4.9375, 5.993, 3.9823),
		inputCenter = Vector3.new(0, 1.38, 0), inputSize = 0.3, bedTop = 1.23,
		parts = {
			["Frame"] = {center = Vector3.new(-0, 2.9967, -0.0005), size = Vector3.new(4.9375, 5.993, 3.9823), origin = Vector3.new(0, 0, 0)},
			["Crossbar"] = {center = Vector3.new(-0.0005, 2.0617, 0.0189), size = Vector3.new(2.9011, 0.7305, 1.1131), origin = Vector3.new(0, 0, 0)},
		},
		motion = {
			{name = "Crossbar", kind = "move", vector = Vector3.new(0, -0.32, 0), curve = "press"},
		},
		contact = {"Crossbar"},
	},
	["RiftMonarch"] = {kit = "motion", grow = true, size = Vector3.new(3.3742, 6.0034, 3.8464),
		inputCenter = Vector3.new(0, 3.25, -0.7), inputSize = 0.45, bedTop = 3.025,
		parts = {
			["Frame"] = {center = Vector3.new(0.0003, 3.0055, 0.2), size = Vector3.new(3.3742, 6.0034, 3.4461), origin = Vector3.new(0, 0, 0)},
			["UpperClaw"] = {center = Vector3.new(-0.0584, 3.9334, -0.8616), size = Vector3.new(2.9847, 1.7667, 2.1233), origin = Vector3.new(0, 4, 0.2)},
			["LowerClaw"] = {center = Vector3.new(0.084, 2.6248, -1.06), size = Vector3.new(2.4223, 0.8504, 1.7199), origin = Vector3.new(0, 2.7, -0.2)},
		},
		motion = {
			{name = "UpperClaw", kind = "rotate", axis = Vector3.new(-1, 0, 0), angle = 0.1745, curve = "press"},
			{name = "LowerClaw", kind = "rotate", axis = Vector3.new(-1, 0, 0), angle = -0.1745, curve = "press"},
		},
		contact = {"UpperClaw", "LowerClaw"},
	},
	["RealitySplitter"] = {kit = "motion", grow = true, size = Vector3.new(4.9071, 6.0035, 4.1189),
		inputCenter = Vector3.new(0, 4.3, 0.1), inputSize = 0.45, bedTop = 4.075,
		parts = {
			["Frame"] = {center = Vector3.new(0.0036, 1.2988, -0.0001), size = Vector3.new(3.9354, 2.6025, 4.1189), origin = Vector3.new(0, 0, 0)},
			["LeftJaw"] = {center = Vector3.new(1.3831, 4.0755, -0.3439), size = Vector3.new(2.1426, 3.851, 1.6453), origin = Vector3.new(1.4, 1.85, 0)},
			["RightJaw"] = {center = Vector3.new(-1.4156, 4.0421, -0.3469), size = Vector3.new(2.0743, 3.7841, 1.8669), origin = Vector3.new(-1.4, 1.85, 0)},
		},
		motion = {
			{name = "LeftJaw", kind = "rotate", axis = Vector3.new(0, 0, 1), angle = 0.1571, curve = "press"},
			{name = "RightJaw", kind = "rotate", axis = Vector3.new(0, 0, 1), angle = -0.1571, curve = "press"},
		},
		contact = {"LeftJaw", "RightJaw"},
	},
}
