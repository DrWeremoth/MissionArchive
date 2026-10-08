local mod = get_mod("MissionArchive")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")
local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local InputUtils = require("scripts/managers/input/input_utils")
local ColorUtilities = require("scripts/utilities/ui/colors")
local DMF = get_mod("DMF")

local MAX_HISTORY = 10
local MAX_STATS = 14
local PANEL_WIDTH = 1600
local PANEL_HEIGHT = 860
local MISSION_ROW_HEIGHT = 58
local STAT_ROW_HEIGHT = 38
local TERMINAL_COLOR = { 255, 101, 145, 102 }
local PANEL_BACKGROUND = { 64, 0, 0, 0 }

local function text_style(base_style, font_size, color)
	local style = table.clone(base_style)
	style.font_size = font_size
	style.text_color = color
	style.text_horizontal_alignment = "left"
	style.text_vertical_alignment = "center"
	style.horizontal_alignment = "left"
	style.vertical_alignment = "center"
	style.offset = { 0, 0, 2 }

	return style
end

local title_style = text_style(UIFontSettings.header_1, 34, TERMINAL_COLOR)
local section_style = text_style(UIFontSettings.header_3, 22, Color.terminal_text_header(255, true))
local body_style = text_style(UIFontSettings.body, 20, Color.ui_grey_light(255, true))
local stat_label_style = text_style(UIFontSettings.body, 20, TERMINAL_COLOR)
local selected_style = text_style(UIFontSettings.body, 20, Color.terminal_text_header_selected(255, true))
local muted_style = text_style(UIFontSettings.body_small, 18, Color.ui_grey_medium(255, true))
local value_style = text_style(UIFontSettings.body, 20, Color.white(255, true))

local scenegraph_definition = {
	screen = UIWorkspaceSettings.screen,
	panel = {
		vertical_alignment = "center",
		parent = "screen",
		horizontal_alignment = "center",
		size = { PANEL_WIDTH, PANEL_HEIGHT },
		position = { 0, 0, 10 },
	},
	title = {
		vertical_alignment = "top",
		parent = "panel",
		horizontal_alignment = "left",
		size = { 1000, 54 },
		position = { 36, 24, 2 },
	},
	missions_header = {
		vertical_alignment = "top",
		parent = "panel",
		horizontal_alignment = "left",
		size = { 470, 34 },
		position = { 36, 100, 2 },
	},
	stats_header = {
		vertical_alignment = "top",
		parent = "panel",
		horizontal_alignment = "left",
		size = { 900, 34 },
		position = { 555, 100, 2 },
	},
	record_title = {
		vertical_alignment = "top",
		parent = "panel",
		horizontal_alignment = "left",
		size = { 970, 42 },
		position = { 555, 142, 2 },
	},
	record_subtitle = {
		vertical_alignment = "top",
		parent = "panel",
		horizontal_alignment = "left",
		size = { 970, 32 },
		position = { 555, 178, 2 },
	},
	stat_name_header = {
		vertical_alignment = "top",
		parent = "panel",
		horizontal_alignment = "left",
		size = { 450, 28 },
		position = { 555, 220, 2 },
	},
	stat_player_header = {
		vertical_alignment = "top",
		parent = "panel",
		horizontal_alignment = "left",
		size = { 180, 28 },
		position = { 1095, 220, 2 },
	},
	stat_team_header = {
		vertical_alignment = "top",
		parent = "panel",
		horizontal_alignment = "left",
		size = { 210, 28 },
		position = { 1300, 220, 2 },
	},
	empty_message = {
		vertical_alignment = "top",
		parent = "panel",
		horizontal_alignment = "left",
		size = { 1500, 52 },
		position = { 36, 164, 2 },
	},
	footer = {
		vertical_alignment = "bottom",
		parent = "panel",
		horizontal_alignment = "left",
		size = { 800, 32 },
		position = { 36, -24, 2 },
	},
}

local widget_definitions = {
	background = UIWidget.create_definition({
		{
			pass_type = "rect",
			style = {
				color = PANEL_BACKGROUND,
				offset = { 0, 0, 0 },
			},
		},
		{
			pass_type = "texture",
			value = "content/ui/materials/backgrounds/terminal_basic",
			style = {
				color = TERMINAL_COLOR,
				offset = { 0, 0, 1 },
			},
		},
		{
			pass_type = "texture",
			value = "content/ui/materials/frames/frame_tile_2px",
			style = {
				color = TERMINAL_COLOR,
				offset = { 0, 0, 3 },
			},
		},
		{
			pass_type = "texture",
			value = "content/ui/materials/frames/frame_corner_2px",
			style = {
				color = TERMINAL_COLOR,
				offset = { 0, 0, 4 },
			},
		},
		{
			pass_type = "texture",
			value = "content/ui/materials/frames/premium_store/offer_card_lower_regular",
			style = {
				horizontal_alignment = "center",
				vertical_alignment = "bottom",
				offset = { 0, 30, 5 },
				size = { nil, 48 },
				size_addition = { 50, 20 },
			},
		},
	}, "panel"),
	title = UIWidget.create_definition({
		{
			pass_type = "text",
			value_id = "text",
			style_id = "text",
			value = mod:localize("mission_archive_title"),
			style = title_style,
		},
	}, "title"),
	missions_header = UIWidget.create_definition({
		{
			pass_type = "text",
			value_id = "text",
			style_id = "text",
			value = mod:localize("mission_archive_missions"),
			style = section_style,
		},
	}, "missions_header"),
	stats_header = UIWidget.create_definition({
		{
			pass_type = "text",
			value_id = "text",
			style_id = "text",
			value = "",
			style = section_style,
		},
	}, "stats_header"),
	record_title = UIWidget.create_definition({
		{
			pass_type = "text",
			value_id = "text",
			style_id = "text",
			value = "",
			style = section_style,
		},
	}, "record_title"),
	record_subtitle = UIWidget.create_definition({
		{
			pass_type = "text",
			value_id = "text",
			style_id = "text",
			value = "",
			style = muted_style,
		},
	}, "record_subtitle"),
	stat_name_header = UIWidget.create_definition({
		{
			pass_type = "text",
			value_id = "text",
			style_id = "text",
			value = mod:localize("mission_archive_statistic"),
			style = muted_style,
		},
	}, "stat_name_header"),
	stat_player_header = UIWidget.create_definition({
		{
			pass_type = "text",
			value_id = "text",
			style_id = "text",
			value = mod:localize("mission_archive_player"),
			style = muted_style,
		},
	}, "stat_player_header"),
	stat_team_header = UIWidget.create_definition({
		{
			pass_type = "text",
			value_id = "text",
			style_id = "text",
			value = mod:localize("mission_archive_team"),
			style = muted_style,
		},
	}, "stat_team_header"),
	empty_message = UIWidget.create_definition({
		{
			pass_type = "text",
			value_id = "text",
			style_id = "text",
			value = "",
			style = body_style,
		},
	}, "empty_message"),
	footer = UIWidget.create_definition({
		{
			pass_type = "text",
			value_id = "text",
			style_id = "text",
			value = mod:localize("mission_archive_close_hint"),
			style = muted_style,
		},
	}, "footer"),
}

for i = 1, MAX_HISTORY do
	local scenegraph_id = "mission_row_" .. i
	local y = 146 + (i - 1) * MISSION_ROW_HEIGHT
	local row_default_color = i % 2 == 0 and { 64, 0, 0, 0 } or { 0, 0, 0, 0 }

	scenegraph_definition[scenegraph_id] = {
		vertical_alignment = "top",
		parent = "panel",
		horizontal_alignment = "left",
		size = { 470, MISSION_ROW_HEIGHT - 4 },
		position = { 36, y, 2 },
	}

	widget_definitions[scenegraph_id] = UIWidget.create_definition({
		{
			pass_type = "hotspot",
			content_id = "hotspot",
			content = {
				use_is_focused = true,
			},
		},
		{
			pass_type = "rect",
			style = {
				color = table.clone(row_default_color),
				default_color = table.clone(row_default_color),
				hover_color = Color.terminal_background_selected(nil, true),
				size = { 470, MISSION_ROW_HEIGHT - 4 },
				offset = { 0, 0, 0 },
			},
			change_function = function(content, style)
				local hotspot = content.hotspot
				local progress = content.is_selected and 1 or hotspot and hotspot.anim_hover_progress or 0

				ColorUtilities.color_lerp(style.default_color, style.hover_color, progress, style.color)
			end,
		},
		{
			pass_type = "text",
			value_id = "text",
			style_id = "text",
			value = "",
			style = body_style,
		},
	}, scenegraph_id, {
		text = "",
		visible = false,
	})
end

for i = 1, MAX_STATS do
	local scenegraph_id = "stat_name_" .. i
	local y = 253 + (i - 1) * STAT_ROW_HEIGHT
	local row_shade = i % 2 == 0 and { 64, 0, 0, 0 } or { 0, 0, 0, 0 }

	scenegraph_definition[scenegraph_id] = {
		vertical_alignment = "top",
		parent = "panel",
		horizontal_alignment = "left",
		size = { 520, STAT_ROW_HEIGHT },
		position = { 555, y, 2 },
	}

	widget_definitions[scenegraph_id] = UIWidget.create_definition({
		{
			pass_type = "rect",
			style = {
				color = row_shade,
				size = { 970, STAT_ROW_HEIGHT },
				offset = { 0, 0, 0 },
			},
		},
		{
			pass_type = "text",
			value_id = "text",
			style_id = "text",
			value = "",
			style = stat_label_style,
		},
	}, scenegraph_id, { text = "" })

	for _, column in ipairs({ "player", "team" }) do
		local value_id = "stat_" .. column .. "_" .. i
		local x = column == "player" and 1095 or 1300

		scenegraph_definition[value_id] = {
			vertical_alignment = "top",
			parent = "panel",
			horizontal_alignment = "left",
			size = { 190, STAT_ROW_HEIGHT },
			position = { x, y, 2 },
		}

		widget_definitions[value_id] = UIWidget.create_definition({
			{
				pass_type = "text",
				value_id = "text",
				style_id = "text",
				value = "",
				style = value_style,
			},
		}, value_id, { text = "" })
	end
end

local Definitions = {
	scenegraph_definition = scenegraph_definition,
	widget_definitions = widget_definitions,
}

local MissionArchiveView = class("MissionArchiveView", "BaseView")

local function archive_key_text()
	local keys = mod:get("open_archive")
	local key_info = keys and DMF.local_keys_to_keywatch_result(keys)
	local key_text = key_info and InputUtils.localized_string_from_key_info(key_info)

	return key_text or mod:localize("mission_archive_unbound_key")
end

local function format_duration(seconds)
	if type(seconds) ~= "number" then
		return "--"
	end

	return string.format("%dm %02ds", math.floor(seconds / 60), math.floor(seconds % 60))
end

local function format_stat(stat, value)
	if type(value) ~= "number" then
		return "--"
	end

	if stat.format == "time" then
		return format_duration(value)
	end

	return tostring(value)
end

local function record_title(record)
	local outcome = record.won and mod:localize("mission_archive_victory")
		or mod:localize("mission_archive_defeat")

	return string.format("%s - %s", record.mission_name or "Unknown mission", outcome)
end

local function mission_row_text(record, index, selected)
	local outcome = record.won and mod:localize("mission_archive_victory")
		or mod:localize("mission_archive_defeat")
	local name = record.mission_name or "Unknown mission"

	local marker = selected and "> " or "  "

	return string.format("%s%02d  %s\n     %s - %s", marker, index, outcome, name, format_duration(record.duration))
end

MissionArchiveView.init = function(self, settings, context)
	MissionArchiveView.super.init(self, Definitions, settings, context)
	self._pass_draw = false
end

MissionArchiveView.on_enter = function(self)
	MissionArchiveView.super.on_enter(self)
	self._close_requested = false

	self._widgets_by_name.footer.content.text = table.concat({
		mod:localize("mission_archive_close_hint"),
		archive_key_text(),
		mod:localize("mission_archive_close_suffix"),
	}, " ")

	self._history = mod:get_history() or {}
	self._selected_record = #self._history
	self:_refresh_archive()

	for i = 1, MAX_HISTORY do
		local widget = self._widgets_by_name["mission_row_" .. i]
		widget.content.hotspot.pressed_callback = callback(self, "_select_record", i)
	end
end

MissionArchiveView._handle_input = function(self, input_service, dt, t)
	if input_service:get("back") then
		if not self._close_requested then
			self._close_requested = true
			Managers.ui:close_view("mission_archive_view")
		end

		return
	end

	local move_up = input_service:get("navigate_up_continuous")
		or input_service:get("navigate_secondary_up_pressed")
	local move_down = input_service:get("navigate_down_continuous")
		or input_service:get("navigate_secondary_down_pressed")

	if #self._history > 0 and move_up ~= move_down then
		local selected_record = self._selected_record

		if move_up then
			selected_record = math.min(selected_record + 1, #self._history)
		else
			selected_record = math.max(selected_record - 1, 1)
		end

		if selected_record ~= self._selected_record then
			self._selected_record = selected_record
			self:_refresh_archive()
		end
	end

	MissionArchiveView.super._handle_input(self, input_service, dt, t)
end

MissionArchiveView._select_record = function(self, visible_row)
	-- History is stored oldest-first, while the on-screen list shows newest-first.
	local record_index = #self._history - visible_row + 1

	if record_index < 1 or record_index > #self._history then
		return
	end

	self._selected_record = record_index
	self:_refresh_archive()
end

MissionArchiveView._refresh_archive = function(self)
	local history = self._history or {}
	local count = #history
	local selected = history[self._selected_record]
	local widgets = self._widgets_by_name

	widgets.stats_header.content.text = string.format("%d / %d", count, MAX_HISTORY)
	widgets.empty_message.content.text = count == 0 and mod:localize("mission_archive_no_missions") or ""
	widgets.record_title.content.text = selected and record_title(selected) or ""
	widgets.record_subtitle.content.text = selected and string.format(
		"%s  |  %s",
		selected.player_name or "Player",
		format_duration(selected.duration)
	) or ""

	for i = 1, MAX_HISTORY do
		local record_index = count - i + 1
		local record = history[record_index]
		local widget = widgets["mission_row_" .. i]

		widget.content.visible = record ~= nil
		widget.content.is_selected = record_index == self._selected_record
		local row_style = record_index == self._selected_record and selected_style or body_style
		widget.style.text.text_color = row_style.text_color
		widget.content.text = record and mission_row_text(record, record_index, record_index == self._selected_record) or ""
	end

	for i = 1, MAX_STATS do
		local stat = selected and selected.stats and selected.stats[i]

		widgets["stat_name_" .. i].content.text = stat and stat.label or ""
		widgets["stat_player_" .. i].content.text = stat and format_stat(stat, stat.player) or ""
		widgets["stat_team_" .. i].content.text = stat and format_stat(stat, stat.team) or ""
	end
end

return MissionArchiveView
