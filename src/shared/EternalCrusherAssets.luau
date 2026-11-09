--!strict
-- 9 Nov: ETERNAL crushers (proposed tier, not in the game yet: no type, odds or Index entry).
-- Motion metadata in the SpecialCrushers "motion" format. Units: Blender units, axes: Studio's
-- (studio = (-bx, bz, by)), measured on Willem's Studio import (cm scale) relative to the Frame's
-- ground pivot. Template: ServerStorage.SpecialCrusherMeshes.<Id> (place file, Willem publishes).
--
-- AstralLeviathan: Claude's Blender pass on the Hunyuan3D image-to-3D prototype (100k faces ->
-- Frame 6,000 + UpperJaw 3,000 triangles, 1024 colour texture). The upper head swings about the
-- gold cheek hinge: it rests tipped 12 degrees up (baked into the import) and bites 32 degrees down,
-- where upper and lower teeth meet. Files: Downloads\CrushIt-Coating-and-Plot-Props\AstralLeviathan.
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
}
