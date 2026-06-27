extends Control
## Unity Ads demo. IDs come from Project Settings → Unity Ads, not from code.
## Tabs mirror what the plugin actually supports: Interstitial and Rewarded.

const COFFEE_URL := "https://buymeacoffee.com/carbon06"

var _log_box: RichTextLabel
var _status: Label


func _ready() -> void:
	_build_ui()

	UnityAds.initialized.connect(func(): _log("initialized ✓"); _refresh_status())
	UnityAds.init_failed.connect(func(e, m): _log("init failed: %s — %s" % [e, m]))
	UnityAds.ad_loaded.connect(func(p): _log("loaded: %s" % p))
	UnityAds.ad_load_failed.connect(func(p, _e, m): _log("load failed: %s — %s" % [p, m]))
	UnityAds.ad_completed.connect(func(p, s): _log("completed: %s (%s)" % [p, s]))
	UnityAds.ad_show_failed.connect(func(p, _e, m): _log("show failed: %s — %s" % [p, m]))
	UnityAds.rewarded.connect(func(_p): _log("🎁 REWARD GRANTED"))
	UnityAds.banner_loaded.connect(func(p): _log("banner loaded: %s" % p))
	UnityAds.banner_load_failed.connect(func(p, _e, m): _log("banner failed: %s — %s" % [p, m]))

	_refresh_status()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	_add_header(root)
	_add_coffee(root)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_status)

	_add_tabs(root)
	_add_logs(root)


func _add_header(parent: Node) -> void:
	var title := Label.new()
	title.text = "Unity Ads Plugin"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	parent.add_child(title)


func _add_coffee(parent: Node) -> void:
	var coffee := Button.new()
	coffee.text = "☕  Buy me a coffee"
	coffee.custom_minimum_size = Vector2(0, 52)
	coffee.modulate = Color(1.0, 0.85, 0.4)
	coffee.pressed.connect(func(): OS.shell_open(COFFEE_URL))
	parent.add_child(coffee)


func _add_tabs(parent: Node) -> void:
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(tabs)

	var interstitial := _make_tab("Interstitial")
	_add_button(interstitial, "Load Interstitial", UnityAds.load_interstitial)
	_add_button(interstitial, "Show Interstitial", UnityAds.show_interstitial)
	tabs.add_child(interstitial)

	var rewarded := _make_tab("Rewarded")
	_add_button(rewarded, "Load Rewarded", UnityAds.load_rewarded)
	_add_button(rewarded, "Show Rewarded", UnityAds.show_rewarded)
	tabs.add_child(rewarded)

	var banner := _make_tab("Banner")
	banner.add_child(_make_label("Tap a position to load the banner there:"))
	banner.add_child(_make_position_grid())
	_add_button(banner, "Show Banner", UnityAds.show_banner)
	_add_button(banner, "Hide Banner", UnityAds.hide_banner)
	_add_button(banner, "Destroy Banner", UnityAds.destroy_banner)
	tabs.add_child(banner)


func _make_tab(tab_name: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.name = tab_name
	box.add_theme_constant_override("separation", 12)
	return box


func _make_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _make_position_grid() -> GridContainer:
	const POSITIONS := [
		["↖", "top_left"], ["↑", "top_center"], ["↗", "top_right"],
		["←", "center_left"], ["■", "center"], ["→", "center_right"],
		["↙", "bottom_left"], ["↓", "bottom_center"], ["↘", "bottom_right"],
	]
	var grid := GridContainer.new()
	grid.columns = 3
	for entry in POSITIONS:
		var pos: String = entry[1]
		var button := Button.new()
		button.text = entry[0]
		button.tooltip_text = pos
		button.custom_minimum_size = Vector2(0, 56)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func(): UnityAds.load_banner(pos))
		grid.add_child(button)
	return grid


func _add_logs(parent: Node) -> void:
	_log_box = RichTextLabel.new()
	_log_box.scroll_following = true
	_log_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_box.custom_minimum_size = Vector2(0, 160)
	_log_box.text = "--- LOGS START ---\n"
	parent.add_child(_log_box)


func _add_button(parent: Node, text: String, on_pressed: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 64)
	button.pressed.connect(on_pressed)
	parent.add_child(button)


func _refresh_status() -> void:
	if not UnityAds.is_available():
		_status.text = "Plugin not found — run on an Android device."
	elif UnityAds.game_id().is_empty():
		_status.text = "Game ID is empty — set it in Project Settings → Unity Ads."
	else:
		_status.text = "Game ID: %s" % UnityAds.game_id()


func _log(message: String) -> void:
	_log_box.add_text(message + "\n")
	print("[UnityAds] ", message)
