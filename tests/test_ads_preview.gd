extends SceneTree

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var ads = root.get_node("AdsManager")
	ads.preview_mode = true
	ads._build_preview()
	await process_frame
	assert(ads.preview_top.size.x > 0.0 and ads.preview_bottom.size.x > 0.0)
	ads.show_banner()
	assert(ads.preview_top.visible and ads.preview_bottom.visible)
	var billing = root.get_node("BillingManager")
	billing.remove_ads_owned = true
	ads.hide_banner()
	ads.show_banner()
	assert(not ads.preview_top.visible and not ads.preview_bottom.visible)
	billing.remove_ads_owned = false
	ads.show_banner()
	ads.hide_banner()
	assert(not ads.preview_top.visible and not ads.preview_bottom.visible)
	ads.show_result_interstitial()
	assert(ads.preview_overlay.visible and not ads.preview_watch.visible)
	ads._finish_preview(false)
	assert(not ads.preview_overlay.visible)
	var granted := [0]
	assert(ads.show_rewarded_power(func(): granted[0] += 2))
	assert(paused and ads.preview_overlay.visible and ads.preview_watch.visible)
	ads._finish_preview(true)
	assert(not paused and granted[0] == 2 and not ads.preview_overlay.visible)
	print("SPIDER_WARS_ADS_PREVIEW_PASS")
	quit()
