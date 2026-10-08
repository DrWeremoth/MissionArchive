return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`MissionArchive` failed loading DMF.")
		new_mod("MissionArchive", {
			mod_script = "MissionArchive/scripts/mods/MissionArchive/MissionArchive",
			mod_data = "MissionArchive/scripts/mods/MissionArchive/MissionArchive_data",
			mod_localization = "MissionArchive/scripts/mods/MissionArchive/MissionArchive_localization",
		})
	end,
	packages = {},
}
