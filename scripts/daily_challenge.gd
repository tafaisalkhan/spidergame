extends Node

const SAVE_PATH := "user://daily_challenges.json"

var first_day := ""
var days: Dictionary = {}
var active_day := ""
var next_level := 1
var reminder_plugin: Object

func _ready() -> void:
	load_history()
	refresh_calendar()
	if OS.has_feature("android") and Engine.has_singleton("SpiderDailyReminder"):
		reminder_plugin = Engine.get_singleton("SpiderDailyReminder")
		reminder_plugin.syncReminder(completed_today())

func today_key() -> String:
	var date := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [date.year, date.month, date.day]

func challenge_level() -> int:
	return next_level

func challenge_is_rival(day_key: String = "") -> bool:
	var key := today_key() if day_key.is_empty() else day_key
	var day_number := int(Time.get_unix_time_from_datetime_string(key + "T12:00:00") / 86400.0)
	return day_number % 2 == 1

func load_history() -> void:
	if OS.get_cmdline_args().has("--script"):
		return
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if parsed is not Dictionary:
		return
	first_day = str(parsed.get("first_day", ""))
	next_level = maxi(1, int(parsed.get("next_level", 1)))
	var saved_days: Variant = parsed.get("days", {})
	if saved_days is Dictionary:
		days = saved_days

func save_history() -> void:
	if OS.get_cmdline_args().has("--script"):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save daily challenge history.")
		return
	file.store_string(JSON.stringify({"version": 1, "first_day": first_day, "next_level": next_level, "days": days}, "\t"))

func refresh_calendar() -> void:
	var today := today_key()
	if first_day.is_empty():
		first_day = today
	elif today < first_day:
		first_day = today
	var cursor := Time.get_unix_time_from_datetime_string(first_day + "T12:00:00")
	var end := Time.get_unix_time_from_datetime_string(today + "T12:00:00")
	while cursor < end:
		var date := Time.get_date_dict_from_unix_time(int(cursor))
		var key := "%04d-%02d-%02d" % [date.year, date.month, date.day]
		if not days.has(key) or days[key] != "completed":
			days[key] = "missed"
		cursor += 86400.0
	save_history()

func completed_today() -> bool:
	return days.get(today_key(), "") == "completed"

func start_today() -> bool:
	refresh_calendar()
	if completed_today():
		return false
	active_day = today_key()
	return true

func complete_active() -> void:
	if active_day.is_empty() or active_day != today_key():
		return
	if days.get(active_day, "") == "completed":
		return
	days[active_day] = "completed"
	next_level += 1
	save_history()
	if reminder_plugin != null:
		reminder_plugin.syncReminder(true)

func status_for_day(key: String) -> String:
	if key > today_key() or key < first_day:
		return "future"
	if key == today_key() and days.get(key, "") != "completed":
		return "today"
	return str(days.get(key, "missed"))

func reminders_enabled() -> bool:
	return reminder_plugin != null and reminder_plugin.remindersEnabled()

func enable_reminders() -> void:
	if reminder_plugin != null:
		reminder_plugin.enableReminders(completed_today())
