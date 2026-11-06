--!strict
-- 6 Nov (Willem: "do all of them" for phones; vault audit round 7 gap: settings menu,
-- haptics). Player settings, saved in the profile (d.settings, server/Settings) so they
-- follow the player to every device. The client reads them as attributes "Set_<key>".
--   Music, Sounds  volume step: 1 = ON, 0.5 = LOW, 0 = OFF (SoundGroups, client/Settings)
--   Shake          screen shake on/off (Style.shakeOn)
--   Effects        "Auto" | "Low" | "High": Low trims post effects and particles like a
--                  phone (Style.lite); High keeps everything even on a phone
--   Vibration      phones and controllers: short vibrations on big moments (client/Haptics)
return {
	Defaults = { Music = 1, Sounds = 1, Shake = true, Effects = "Auto", Vibration = true },
	Levels = { 1, 0.5, 0 },
	LevelNames = { [1] = "ON", [0.5] = "LOW", [0] = "OFF" },
	Effects = { "Auto", "Low", "High" },
	-- the rows of the settings panel, in order
	Rows = {
		{ key = "Music", title = "MUSIC", kind = "level" },
		{ key = "Sounds", title = "SOUNDS", kind = "level" },
		{ key = "Shake", title = "SCREEN SHAKE", kind = "toggle" },
		{ key = "Effects", title = "EFFECTS", kind = "effects" },
		{ key = "Vibration", title = "VIBRATION", kind = "toggle", touchOnly = true },
	},
}
