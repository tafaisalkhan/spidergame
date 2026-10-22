extends SceneTree

const SPLASH = preload("res://scenes/splash.tscn")
const APP_ICON = preload("res://assets/branding/app-icon-spider-territory.png")
const SPLASH_ART = preload("res://assets/background/splash-spider-territory.png")

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	assert(ProjectSettings.get_setting("application/config/name") == "Spider Territory")
	assert(ProjectSettings.get_setting("application/config/icon") == "res://assets/branding/app-icon-spider-territory.png")
	assert(APP_ICON.get_width() == APP_ICON.get_height() and APP_ICON.get_width() >= 512)
	assert(SPLASH_ART.get_height() > SPLASH_ART.get_width() and SPLASH_ART.get_height() >= 1500)
	var splash = SPLASH.instantiate()
	root.add_child(splash)
	current_scene = splash
	await process_frame
	assert(splash.get_child_count() == 2)
	assert(splash.get_child(0).texture == SPLASH_ART)
	assert(splash.spider_stage.get_node("SplashTitle").text == "SPIDER TERRITORY")
	assert(splash.blue_spider.position.x < splash.red_spider.position.x)
	assert(splash.center_bug.texture == splash.SPLASH_BUG)
	assert(splash.center_bug.position.x > splash.blue_spider.position.x and splash.center_bug.position.x < splash.red_spider.position.x)
	var blue_start: float = splash.blue_spider.position.x
	var red_start: float = splash.red_spider.position.x
	await create_timer(0.45).timeout
	assert(splash.blue_spider.position.x > blue_start)
	assert(splash.red_spider.position.x < red_start)
	assert(splash.walk_phase > 0.0)
	await create_timer(2.55).timeout
	await process_frame
	assert(current_scene != null and current_scene.name == "MainMenu")
	current_scene.open_scene("res://scenes/first_hunt.tscn")
	await process_frame
	assert(current_scene != null and current_scene.intro_mode)
	print("SPIDER_TERRITORY_SPLASH_PASS")
	quit()
