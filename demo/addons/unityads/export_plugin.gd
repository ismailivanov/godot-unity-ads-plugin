@tool
extends EditorPlugin

## Registers the Unity Ads Android library + Maven dependency at export time, and
## exposes configuration under Project Settings → Unity Ads (no hardcoded IDs).

const SETTINGS := {
	"unity_ads/android/game_id": {"type": TYPE_STRING, "default": ""},
	"unity_ads/test_mode": {"type": TYPE_BOOL, "default": true},
	"unity_ads/auto_initialize": {"type": TYPE_BOOL, "default": true},
	"unity_ads/placements/interstitial": {"type": TYPE_STRING, "default": "Interstitial_Android"},
	"unity_ads/placements/rewarded": {"type": TYPE_STRING, "default": "Rewarded_Android"},
	"unity_ads/placements/banner": {"type": TYPE_STRING, "default": "banner"},
}

var _export_plugin: AndroidExportPlugin


func _enter_tree() -> void:
	_register_settings()
	_export_plugin = AndroidExportPlugin.new()
	add_export_plugin(_export_plugin)


func _exit_tree() -> void:
	remove_export_plugin(_export_plugin)
	_export_plugin = null


func _register_settings() -> void:
	var changed := false
	for setting_name in SETTINGS:
		var info: Dictionary = SETTINGS[setting_name]
		if not ProjectSettings.has_setting(setting_name):
			ProjectSettings.set_setting(setting_name, info["default"])
			changed = true
		ProjectSettings.set_initial_value(setting_name, info["default"])
		ProjectSettings.add_property_info({"name": setting_name, "type": info["type"]})
		ProjectSettings.set_as_basic(setting_name, true)
	if changed:
		ProjectSettings.save()


class AndroidExportPlugin extends EditorExportPlugin:
	const PLUGIN_NAME := "GodotUnityAds"

	func _get_name() -> String:
		return PLUGIN_NAME

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	# Paths are relative to res://addons/.
	func _get_android_libraries(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		return PackedStringArray(["unityads/GodotUnityAds.release.aar"])

	func _get_android_dependencies(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		return PackedStringArray(["com.unity3d.ads:unity-ads:4.18.1"])
