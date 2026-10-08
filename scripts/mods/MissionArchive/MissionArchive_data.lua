local mod = get_mod("MissionArchive")

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "open_archive",
				type = "keybind",
				title = "open_archive",
				tooltip = "open_archive_desc",
				default_value = { "f8" },
				keybind_global = true,
				keybind_trigger = "pressed",
				keybind_type = "view_toggle",
				view_name = "mission_archive_view",
			},
		},
	},
}
