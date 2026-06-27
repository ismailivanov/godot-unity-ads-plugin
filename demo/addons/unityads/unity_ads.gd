extends Node
## Autoload bridge to the GodotUnityAds Android plugin.
## All config lives in Project Settings → Unity Ads — nothing is hardcoded.
## ponytail: on editor/desktop the singleton is absent → calls are no-ops, so the
## same game code runs everywhere without platform guards at call sites.

signal initialized
signal init_failed(error: String, message: String)
signal ad_loaded(placement_id: String)
signal ad_load_failed(placement_id: String, error: String, message: String)
signal ad_completed(placement_id: String, state: String)
signal ad_show_failed(placement_id: String, error: String, message: String)
signal rewarded(placement_id: String)
signal banner_loaded(placement_id: String)
signal banner_load_failed(placement_id: String, error: String, message: String)

## Default placement IDs — must mirror export_plugin.gd's registered defaults. Godot strips a
## setting equal to its default from project.godot, and the editor plugin that registers them
## never runs on device, so every lookup must pass its own default (see _get_string).
const DEFAULT_INTERSTITIAL := "Interstitial_Android"
const DEFAULT_REWARDED := "Rewarded_Android"
const DEFAULT_BANNER := "Banner_Android"

var _plugin: Object = null


func _ready() -> void:
	if Engine.has_singleton("GodotUnityAds"):
		_plugin = Engine.get_singleton("GodotUnityAds")
		_connect_plugin()
	else:
		push_warning("GodotUnityAds plugin not found — run on Android with the plugin enabled.")

	if _get_bool("unity_ads/auto_initialize", true) and not game_id().is_empty():
		initialize()


func is_available() -> bool:
	return _plugin != null


func game_id() -> String:
	return _get_string("unity_ads/android/game_id")


func initialize() -> void:
	if _plugin:
		_plugin.initialize(game_id(), _get_bool("unity_ads/test_mode", true))


func load_ad(placement_id: String) -> void:
	if _plugin:
		_plugin.load_ad(placement_id)


func show_ad(placement_id: String) -> void:
	if _plugin:
		_plugin.show_ad(placement_id)


func load_interstitial() -> void:
	load_ad(_get_string("unity_ads/placements/interstitial", DEFAULT_INTERSTITIAL))


func show_interstitial() -> void:
	show_ad(_get_string("unity_ads/placements/interstitial", DEFAULT_INTERSTITIAL))


func load_rewarded() -> void:
	load_ad(_get_string("unity_ads/placements/rewarded", DEFAULT_REWARDED))


func show_rewarded() -> void:
	show_ad(_get_string("unity_ads/placements/rewarded", DEFAULT_REWARDED))


## position: "<top|center|bottom>_<left|center|right>", e.g. "bottom_center".
func load_banner(position: String = "bottom_center") -> void:
	if _plugin:
		_plugin.load_banner(_get_string("unity_ads/placements/banner", DEFAULT_BANNER), position)


func show_banner() -> void:
	if _plugin:
		_plugin.show_banner()


func hide_banner() -> void:
	if _plugin:
		_plugin.hide_banner()


func destroy_banner() -> void:
	if _plugin:
		_plugin.destroy_banner()


func _connect_plugin() -> void:
	_plugin.connect("initialized", func(): initialized.emit())
	_plugin.connect("init_failed", func(e, m): init_failed.emit(e, m))
	_plugin.connect("ad_loaded", func(p): ad_loaded.emit(p))
	_plugin.connect("ad_load_failed", func(p, e, m): ad_load_failed.emit(p, e, m))
	_plugin.connect("ad_completed", _on_ad_completed)
	_plugin.connect("ad_show_failed", func(p, e, m): ad_show_failed.emit(p, e, m))
	_plugin.connect("banner_loaded", func(p): banner_loaded.emit(p))
	_plugin.connect("banner_load_failed", func(p, e, m): banner_load_failed.emit(p, e, m))


func _on_ad_completed(placement_id: String, state: String) -> void:
	ad_completed.emit(placement_id, state)
	var rewarded_id := _get_string("unity_ads/placements/rewarded", DEFAULT_REWARDED)
	if state == "COMPLETED" and placement_id == rewarded_id:
		rewarded.emit(placement_id)


func _get_string(setting_name: String, default: String = "") -> String:
	# ponytail: like _get_bool, Godot strips settings equal to their registered default from
	# project.godot, so on device (no editor plugin) the caller must pass the real default.
	return str(ProjectSettings.get_setting(setting_name, default))


func _get_bool(setting_name: String, default: bool = false) -> bool:
	# ponytail: Godot strips settings equal to their registered default from
	# project.godot, so on device (no editor plugin) pass the real default here.
	return bool(ProjectSettings.get_setting(setting_name, default))
