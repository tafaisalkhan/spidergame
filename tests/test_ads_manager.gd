extends SceneTree

class FakeAdsPlugin:
	extends RefCounted
	signal interstitial_finished
	signal rewarded_loaded
	signal reward_earned
	signal rewarded_finished
	var interstitial_ready := true
	var rewarded_ready := true
	var interstitial_shown := false
	var rewarded_shown := false
	var banner_shown := false

	func showBanner(_unit_id: String) -> void:
		banner_shown = true

	func hideBanner() -> void:
		banner_shown = false

	func isInterstitialReady() -> bool:
		return interstitial_ready

	func showInterstitial() -> void:
		interstitial_shown = true

	func isRewardedReady() -> bool:
		return rewarded_ready

	func showRewarded() -> void:
		rewarded_shown = true
		rewarded_ready = false

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var ads = root.get_node("AdsManager")
	var manager = root.get_node("GameManager")
	assert(ads.plugin == null and not ads.is_rewarded_ready())
	var fake := FakeAdsPlugin.new()
	ads.plugin = fake
	fake.interstitial_finished.connect(ads._on_interstitial_finished)
	fake.rewarded_loaded.connect(ads._on_rewarded_loaded)
	fake.reward_earned.connect(ads._on_reward_earned)
	fake.rewarded_finished.connect(ads._on_rewarded_finished)
	var continued := [false]
	ads.show_interstitial_then(func(): continued[0] = true)
	assert(fake.interstitial_shown and not continued[0])
	fake.interstitial_finished.emit()
	assert(continued[0])
	fake.interstitial_shown = false
	ads.show_result_interstitial()
	assert(fake.interstitial_shown)
	fake.interstitial_finished.emit()
	var starting_coins: int = manager.coins
	assert(not ads.show_rewarded_coins())
	fake.rewarded_loaded.emit()
	assert(ads.is_rewarded_ready())
	assert(ads.show_rewarded_coins() and fake.rewarded_shown)
	assert(manager.coins == starting_coins)
	fake.reward_earned.emit()
	assert(manager.coins == starting_coins + ads.REWARDED_COINS)
	fake.reward_earned.emit()
	assert(manager.coins == starting_coins + ads.REWARDED_COINS)
	fake.rewarded_finished.emit()
	assert(not ads.show_rewarded_coins())
	var power_charges := [0]
	fake.rewarded_ready = true
	fake.rewarded_loaded.emit()
	assert(ads.show_rewarded_power(func(): power_charges[0] += 2))
	assert(paused and power_charges[0] == 0)
	fake.reward_earned.emit()
	assert(paused and power_charges[0] == 2)
	fake.rewarded_finished.emit()
	assert(not paused)
	fake.rewarded_ready = true
	fake.rewarded_loaded.emit()
	assert(ads.show_rewarded_power(func(): power_charges[0] += 2))
	fake.rewarded_finished.emit()
	assert(not paused and power_charges[0] == 2)
	var billing = root.get_node("BillingManager")
	billing.remove_ads_owned = true
	ads.show_banner()
	assert(not fake.banner_shown)
	fake.interstitial_shown = false
	var resumed := [false]
	ads.show_interstitial_then(func(): resumed[0] = true)
	assert(resumed[0] and not fake.interstitial_shown)
	billing.remove_ads_owned = false
	print("SPIDER_TERRITORY_ADS_MANAGER_PASS")
	quit()
