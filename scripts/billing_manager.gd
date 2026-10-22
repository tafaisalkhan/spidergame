extends Node

signal purchase_changed(owned: bool)
signal price_changed(price: String)
signal billing_failed(message: String)
signal coin_purchase_changed(owned: bool)
signal coin_price_changed(price: String)

const PRODUCT_ID := "remove_ads"
const COIN_PRODUCT_ID := "coins1"
const COIN_PURCHASE_REWARD := 100
const SAVE_PATH := "user://spider_wars_billing.cfg"

var plugin: Object
var remove_ads_owned := false
var coin_purchase_owned := false
var displayed_price := "$4.99"
var coin_displayed_price := "$2.00"

func _ready() -> void:
	var save := ConfigFile.new()
	if save.load(SAVE_PATH) == OK:
		remove_ads_owned = bool(save.get_value("purchases", PRODUCT_ID, false))
		coin_purchase_owned = bool(save.get_value("purchases", COIN_PRODUCT_ID, false))
	if OS.has_feature("android") and Engine.has_singleton("SpiderBilling"):
		plugin = Engine.get_singleton("SpiderBilling")
		plugin.billing_ready.connect(_on_billing_ready)
		plugin.coin_price_ready.connect(_on_coin_price_ready)
		plugin.remove_ads_owned.connect(_on_remove_ads_owned)
		plugin.coin_purchase_owned.connect(_on_coin_purchase_owned)
		plugin.billing_error.connect(_on_billing_error)
		plugin.initializeBilling()

func purchase_remove_ads() -> bool:
	if remove_ads_owned or plugin == null:
		return false
	plugin.purchaseRemoveAds()
	return true

func purchase_coins() -> bool:
	if coin_purchase_owned or plugin == null:
		return false
	plugin.purchaseCoins()
	return true

func restore_purchases() -> void:
	if plugin != null:
		plugin.restorePurchases()

func _on_billing_ready(price: String) -> void:
	displayed_price = price
	price_changed.emit(price)

func _on_coin_price_ready(price: String) -> void:
	coin_displayed_price = price
	coin_price_changed.emit(price)

func _on_remove_ads_owned() -> void:
	if remove_ads_owned:
		return
	remove_ads_owned = true
	get_node("/root/AdsManager").hide_banner()
	var save := ConfigFile.new()
	save.load(SAVE_PATH)
	save.set_value("purchases", PRODUCT_ID, true)
	save.save(SAVE_PATH)
	purchase_changed.emit(true)

func _on_coin_purchase_owned() -> void:
	if coin_purchase_owned:
		return
	coin_purchase_owned = true
	var save := ConfigFile.new()
	save.load(SAVE_PATH)
	save.set_value("purchases", COIN_PRODUCT_ID, true)
	save.save(SAVE_PATH)
	get_node("/root/GameManager").add_coins(COIN_PURCHASE_REWARD)
	coin_purchase_changed.emit(true)

func _on_billing_error(message: String) -> void:
	billing_failed.emit(message)
