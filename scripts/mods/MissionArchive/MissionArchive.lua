local mod = get_mod("MissionArchive")
local SessionStatsDisplay = require("scripts/settings/stats/session_stats_display")
local StatDefinitions = require("scripts/managers/stats/stat_definitions")

local MAX_HISTORY = 10
local HISTORY_SETTING = "mission_history"
local DEMO_SEEDED_SETTING = "demo_missions_seeded"

local DEMO_MISSIONS = {
	{
		mission_name = "DEMO - Hab Dreyko",
		won = true,
		duration = 915,
		start_time = "2030-01-02T18:30:00Z",
		player_name = "Demo Operative",
		player_stats = { 342, 348903, 30983, 16, 46, 1461, 6, 146, 4, 4, 101, 0, 0, 780 },
		team_stats = { 966, 969838, 104603, 40, 97, 2802, 8, 660, 5, 49, 423, 1, 0, false },
	},
	{
		mission_name = "DEMO - Chasm Logistratum",
		won = false,
		duration = 1278,
		start_time = "2030-01-03T20:15:00Z",
		player_name = "Demo Operative",
		player_stats = { 218, 241672, 18240, 11, 32, 973, 12, 208, 7, 3, 74, 1, 2, 624 },
		team_stats = { 1042, 892415, 119832, 51, 126, 3470, 33, 941, 26, 38, 387, 4, 9, false },
	},
}

local function read_stat(stats_key, stat_name)
	if not stat_name then
		return nil
	end

	local definition = StatDefinitions[stat_name]

	if not definition or not definition.flags or definition.flags.hook or definition.flags.no_sync then
		return nil
	end

	return math.round(Managers.stats:read_user_stat(stats_key, stat_name))
end

local function current_stats(stats_key)
	local stats_manager = Managers.stats
	local pushed_rows = stats_manager:leaderboard_session_stats(stats_key)
	local game_session = Managers.state and Managers.state.game_session
	local live_key = game_session and game_session:is_client() and stats_key or nil

	if live_key and stats_manager:user_state(live_key) == nil then
		live_key = nil
	end

	local rows = {}

	for i = 1, #SessionStatsDisplay do
		local display = SessionStatsDisplay[i]
		local pushed = pushed_rows and pushed_rows[i]
		local player_value = pushed and pushed.private
			or live_key and read_stat(live_key, display.private)
		local team_value = pushed and pushed.team
			or live_key and read_stat(live_key, display.team)

		rows[#rows + 1] = {
			label = Localize(display.display_name),
			player = player_value,
			team = team_value,
			format = display.private == "session_time_coherency" and "time" or "number",
		}
	end

	return rows
end

function mod:get_history()
	local history = self:get(HISTORY_SETTING)

	if history == nil then
		history = {}
	elseif type(history) ~= "table" then
		self:error("Saved mission history is not a valid table.")
		return nil
	end

	local changed = false
	local seed_demo_records = not self:get(DEMO_SEEDED_SETTING)

	if seed_demo_records then
		local demo_records = {}

		for _, demo in ipairs(DEMO_MISSIONS) do
			local stats = {}

			for i, display in ipairs(SessionStatsDisplay) do
				local team_value = demo.team_stats[i]

				stats[i] = {
					label = Localize(display.display_name),
					player = demo.player_stats[i],
					team = team_value ~= false and team_value or nil,
					format = display.private == "session_time_coherency" and "time" or "number",
				}
			end

			demo_records[#demo_records + 1] = {
				mission_name = demo.mission_name,
				won = demo.won,
				duration = demo.duration,
				start_time = demo.start_time,
				player_name = demo.player_name,
				stats = stats,
				demo = true,
			}
		end

		for i = #demo_records, 1, -1 do
			table.insert(history, 1, demo_records[i])
		end

		changed = true
	end

	while #history > MAX_HISTORY do
		table.remove(history, 1)
		changed = true
	end

	if changed then
		self:set(HISTORY_SETTING, history)
	end

	if seed_demo_records then
		self:set(DEMO_SEEDED_SETTING, true)
	end

	return history
end

local function save_current_mission(view)
	local report = view._session_report
	local eor = report and report.eor
	local mission = eor and eor.mission
	local local_player = Managers.player and Managers.player:local_player(1)
	local stats_key = local_player and local_player:local_player_id()

	if not mission or not stats_key or not Managers.stats then
		mod:error("Could not save this mission: the end-of-mission report or local stats were unavailable.")
		return
	end

	local history = mod:get_history()

	if not history then
		mod:error("Could not save this mission because saved mission history could not be loaded.")
		return
	end

	local mission_settings = require("scripts/settings/mission/mission_templates")[mission.missionName]
	local mission_display_name = mission_settings and mission_settings.mission_name
		and Localize(mission_settings.mission_name)

	local record = {
		mission_name = mission_display_name or mission.missionName or "Unknown mission",
		won = view._round_won == true,
		duration = mission.playTimeSeconds,
		start_time = mission.startTime,
		player_name = local_player:name(),
		stats = current_stats(stats_key),
	}

	if type(mission.win) == "boolean" then
		record.won = mission.win
	end

	history[#history + 1] = record

	while #history > MAX_HISTORY do
		table.remove(history, 1)
	end

	mod:set(HISTORY_SETTING, history)
	mod._history_index = nil
	mod:info("Saved mission stats for %s.", record.mission_name)
end

mod:add_require_path("MissionArchive/scripts/mods/MissionArchive/MissionArchive_view")

mod:register_view({
	view_name = "mission_archive_view",
	view_settings = {
		init_view_function = function()
			return true
		end,
		active = {
			inn = true,
			ingame = true,
		},
		class = "MissionArchiveView",
		disable_game_world = false,
		display_name = "mission_archive_title",
		game_world_blur = 0.6,
		load_always = true,
		load_in_hub = true,
		package = "packages/ui/views/end_player_view/end_player_view",
		path = "MissionArchive/scripts/mods/MissionArchive/MissionArchive_view",
		state_bound = true,
	},
	view_transitions = {},
	view_options = {
		close_all = false,
		close_previous = false,
	},
})

mod:io_dofile("MissionArchive/scripts/mods/MissionArchive/MissionArchive_view")

mod:hook_safe(CLASS.EndView, "on_enter", function(view)
	if view._mission_archive_saved then
		return
	end

	view._mission_archive_saved = true
	save_current_mission(view)
end)
