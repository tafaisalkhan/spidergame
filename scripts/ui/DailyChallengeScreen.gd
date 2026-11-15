extends "res://scripts/ui/MenuScreenBase.gd"

const MONTH_NAMES := ["JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"]
const WEEKDAYS := ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

var display_year := 0
var display_month := 0
var calendar_grid: GridContainer
var month_label: Label
var challenge_label: Label
var play_button: Button
var reminder_button: Button

func screen_title() -> String:
	return "DAILY CHALLENGE"

func build_content() -> void:
	var daily := get_node("/root/DailyChallenge")
	daily.refresh_calendar()
	var now := Time.get_date_dict_from_system()
	display_year = now.year
	display_month = now.month
	challenge_label = make_label("", 40, Color(0.95, 0.99, 0.77))
	challenge_label.position = Vector2(85, 335)
	challenge_label.size = Vector2(750, 130)
	design.add_child(challenge_label)
	play_button = make_button("PLAY TODAY", Vector2(85, 525), 112.0)
	play_button.name = "PlayDailyChallengeButton"
	play_button.pressed.connect(get_node("/root/GameManager").start_daily_challenge)
	reminder_button = make_button("ENABLE REMINDERS", Vector2(85, 665), 100.0)
	reminder_button.name = "DailyReminderButton"
	reminder_button.pressed.connect(_enable_reminders)
	var back := make_button("BACK", Vector2(85, 800), 100.0)
	back.name = "DailyBackButton"
	back.pressed.connect(open_scene.bind("res://scenes/main_menu.tscn"))
	month_label = make_label("", 40, Color(1.0, 0.88, 0.52))
	month_label.position = Vector2(1030, 265)
	month_label.size = Vector2(540, 65)
	design.add_child(month_label)
	var previous := make_button("<", Vector2(925, 265), 65.0)
	previous.name = "PreviousMonthButton"
	previous.size.x = 90
	previous.pressed.connect(_change_month.bind(-1))
	var next := make_button(">", Vector2(1580, 265), 65.0)
	next.name = "NextMonthButton"
	next.size.x = 90
	next.pressed.connect(_change_month.bind(1))
	calendar_grid = GridContainer.new()
	calendar_grid.name = "CalendarGrid"
	calendar_grid.columns = 7
	calendar_grid.position = Vector2(895, 355)
	calendar_grid.add_theme_constant_override("h_separation", 8)
	calendar_grid.add_theme_constant_override("v_separation", 8)
	design.add_child(calendar_grid)
	var legend := make_label("GREEN  Completed     RED  Missed     GOLD  Today", 27, Color(0.95, 0.93, 0.78))
	legend.position = Vector2(880, 920)
	legend.size = Vector2(850, 70)
	design.add_child(legend)
	_refresh()

func _enable_reminders() -> void:
	var daily := get_node("/root/DailyChallenge")
	daily.enable_reminders()
	reminder_button.text = "REMINDERS ENABLED" if daily.reminders_enabled() else "ALLOW NOTIFICATIONS"

func _change_month(direction: int) -> void:
	display_month += direction
	if display_month < 1:
		display_month = 12
		display_year -= 1
	elif display_month > 12:
		display_month = 1
		display_year += 1
	_refresh_calendar()

func _refresh() -> void:
	var daily := get_node("/root/DailyChallenge")
	var mode := "RIVAL MODE" if daily.challenge_is_rival() else "BUGS MODE"
	var shown_level: int = daily.challenge_level() - 1 if daily.completed_today() else daily.challenge_level()
	challenge_label.text = "TODAY: %s\nCHALLENGE LEVEL %d" % [mode, shown_level]
	play_button.disabled = daily.completed_today()
	play_button.text = "COMPLETED TODAY" if play_button.disabled else "PLAY TODAY"
	reminder_button.visible = daily.reminder_plugin != null
	reminder_button.text = "REMINDERS ENABLED" if daily.reminders_enabled() else "ENABLE REMINDERS"
	status_label.text = ""
	_refresh_calendar()

func _refresh_calendar() -> void:
	month_label.text = "%s %d" % [MONTH_NAMES[display_month - 1], display_year]
	for child in calendar_grid.get_children():
		calendar_grid.remove_child(child)
		child.queue_free()
	for weekday in WEEKDAYS:
		_add_cell(weekday, Color(0.16, 0.23, 0.21), Color.WHITE)
	var first := "%04d-%02d-01" % [display_year, display_month]
	var first_unix := Time.get_unix_time_from_datetime_string(first + "T12:00:00")
	var weekday: int = Time.get_date_dict_from_unix_time(int(first_unix)).weekday
	for index in weekday:
		_add_cell("", Color(0.06, 0.10, 0.09), Color.TRANSPARENT)
	var next_year := display_year + (1 if display_month == 12 else 0)
	var next_month := 1 if display_month == 12 else display_month + 1
	var next_key := "%04d-%02d-01" % [next_year, next_month]
	var count := int((Time.get_unix_time_from_datetime_string(next_key + "T12:00:00") - first_unix) / 86400.0)
	var daily := get_node("/root/DailyChallenge")
	for day in range(1, count + 1):
		var key := "%04d-%02d-%02d" % [display_year, display_month, day]
		var status: String = daily.status_for_day(key)
		var color := Color(0.08, 0.14, 0.12)
		if status == "completed":
			color = Color(0.13, 0.51, 0.29)
		elif status == "missed":
			color = Color(0.55, 0.19, 0.17)
		elif status == "today":
			color = Color(0.66, 0.47, 0.12)
		_add_cell(str(day), color, Color.WHITE)

func _add_cell(value: String, background: Color, foreground: Color) -> void:
	var label := make_label(value, 32, foreground)
	label.custom_minimum_size = Vector2(106, 67)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(106, 67)
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", style)
	panel.add_child(label)
	calendar_grid.add_child(panel)
