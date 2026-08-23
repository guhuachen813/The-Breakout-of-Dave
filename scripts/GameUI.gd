extends CanvasLayer

signal upgrade_selected(id: String)
signal restart_requested
signal resume_requested
signal skill_pressed(skill_id: String)

const HUD_FRAME = preload("res://assets/sprites/ui/runtime/hud_frame.svg")
const BAR_FRAME = preload("res://assets/sprites/ui/runtime/hud_bar.svg")
const CARD_FRAME = preload("res://assets/sprites/ui/runtime/upgrade_card.svg")
const FREEZE_ICON = preload("res://assets/sprites/ui/runtime/skill_freeze_ready.png")
const BURST_ICON = preload("res://assets/sprites/ui/runtime/skill_burst_ready.png")
const SKILL_ICON = preload("res://scripts/SkillIcon.gd")

var root: Control
var hud: Label
var hp_bar: ProgressBar
var xp_bar: ProgressBar
var popup: Control
var skill_buttons := {}
var wave_panel: Panel
var wave_label: Label
var objective_panel: Panel

func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.focus_mode = Control.FOCUS_ALL
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	hud = Label.new()
	var frame := TextureRect.new()
	frame.texture = HUD_FRAME
	frame.position = Vector2(24, 20)
	frame.size = Vector2(720, 180)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(frame)
	hud.position = Vector2(48, 34)
	hud.size = Vector2(640, 82)
	hud.add_theme_font_size_override("font_size", 28)
	root.add_child(hud)
	hp_bar = _make_bar(Vector2(48, 112), Color("e76555"))
	xp_bar = _make_bar(Vector2(48, 146), Color("e5b94f"))
	wave_panel = _make_panel(Vector2(1570, 26), Vector2(320, 94), Color("253b47"))
	wave_label = Label.new()
	wave_label.position = Vector2(18, 12)
	wave_label.size = Vector2(284, 70)
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wave_label.add_theme_font_size_override("font_size", 23)
	wave_panel.add_child(wave_label)
	objective_panel = _make_panel(Vector2(24, 900), Vector2(360, 82), Color("253b47"))
	var objective := Label.new()
	objective.position = Vector2(16, 10)
	objective.size = Vector2(328, 60)
	objective.text = "WASD 控制移动\nQ / E 释放大招"
	objective.add_theme_font_size_override("font_size", 19)
	objective.add_theme_color_override("font_color", Color("f2e5c7"))
	objective_panel.add_child(objective)
	_make_skill_button("freeze", FREEZE_ICON, Vector2(1650, 875), "Q", "冰封", 25.0)
	_make_skill_button("burst", BURST_ICON, Vector2(1790, 875), "E", "熔岩齐射", 40.0)
	focus_game_input()

func focus_game_input() -> void:
	if root != null:
		root.grab_focus()

func _make_panel(at: Vector2, panel_size: Vector2, color: Color) -> Panel:
	var panel := Panel.new()
	panel.position = at
	panel.size = panel_size
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.bg_color.a = 0.92
	style.border_color = Color("d8bd84")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)
	return panel

func _make_skill_button(skill_id: String, icon: Texture2D, at: Vector2, key_hint: String, title: String, cooldown: float) -> void:
	var button := SKILL_ICON.new()
	button.position = at
	button.setup(skill_id, icon, title, key_hint, cooldown)
	button.activated.connect(func() -> void: skill_pressed.emit(skill_id))
	root.add_child(button)
	skill_buttons[skill_id] = button

func update_hud(snapshot: Dictionary) -> void:
	var seconds := int(snapshot["game_time"])
	var bullet_names := []
	for weapon in snapshot["unlocked_weapons"]:
		bullet_names.append({"orange": "simple", "black": "lava", "cow": "melon"}.get(weapon, weapon))
	hud.text = "戴夫  %d / %d    第 %d 波\n子弹：%s        击败 %d   %02d:%02d" % [snapshot["player_hp"], snapshot["player_max_hp"], snapshot["current_wave"], "、".join(bullet_names), snapshot["kills"], seconds / 60, seconds % 60]
	wave_label.text = "战区 %02d  /  05\n推进 %02d%%" % [snapshot["current_wave"], int(snapshot["wave_progress"] * 100.0)]
	hp_bar.value = 100.0 * float(snapshot["player_hp"]) / maxf(1.0, float(snapshot["player_max_hp"]))
	xp_bar.value = 100.0 * float(snapshot["xp"]) / maxf(1.0, float(snapshot["xp_needed"]))
	for skill_id in skill_buttons.keys():
		var remaining := float(snapshot["skill_cooldowns"].get(skill_id, 0.0))
		skill_buttons[skill_id].set_cooldown(remaining)

func _make_bar(at: Vector2, fill: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = at
	bar.size = Vector2(420, 28)
	bar.max_value = 100.0
	bar.show_percentage = false
	var background := StyleBoxTexture.new()
	background.texture = BAR_FRAME
	var foreground := StyleBoxFlat.new()
	foreground.bg_color = fill
	foreground.corner_radius_top_left = 6
	foreground.corner_radius_top_right = 6
	foreground.corner_radius_bottom_left = 6
	foreground.corner_radius_bottom_right = 6
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", foreground)
	root.add_child(bar)
	return bar

func hide_popup() -> void:
	if popup:
		popup.queue_free()
		popup = null

func _make_popup(title: String) -> VBoxContainer:
	hide_popup()
	popup = ColorRect.new()
	popup.color = Color(0.03, 0.02, 0.04, 0.82)
	popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(popup)
	var box := VBoxContainer.new()
	box.position = Vector2(420, 150)
	box.size = Vector2(1080, 760)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 24)
	popup.add_child(box)
	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 52)
	box.add_child(heading)
	return box

func show_upgrade(options: Array, levels: Dictionary) -> void:
	var box := _make_popup("选择一次升级")
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	box.add_child(row)
	var config = preload("res://scripts/GameConfig.gd")
	for id in options:
		var data: Dictionary = config.UPGRADES[id]
		var card := TextureButton.new()
		card.texture_normal = CARD_FRAME
		card.ignore_texture_size = true
		card.custom_minimum_size = Vector2(310, 440)
		var label := Label.new()
		label.text = "%s\n\n%s\n当前 %d / %d" % [data["name"], data["desc"], levels[id], data["max"]]
		label.position = Vector2(24, 40)
		label.size = Vector2(262, 330)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 24)
		card.add_child(label)
		card.pressed.connect(func() -> void: upgrade_selected.emit(id))
		row.add_child(card)

func show_pause() -> void:
	var box := _make_popup("已暂停")
	var button := Button.new()
	button.text = "继续"
	button.custom_minimum_size = Vector2(300, 80)
	button.pressed.connect(func() -> void: resume_requested.emit())
	box.add_child(button)

func show_result(result: String, snapshot: Dictionary) -> void:
	var box := _make_popup(result)
	var seconds := int(snapshot["game_time"])
	var stats := Label.new()
	stats.text = "存活时间：%02d:%02d\n击败敌人：%d\n放出豌豆：%d\n游戏评分：%d\n升级次数：%d" % [seconds / 60, seconds % 60, snapshot["kills"], snapshot["cats_fired"], snapshot["game_score"], snapshot["upgrade_count"]]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 30)
	box.add_child(stats)
	var button := Button.new()
	button.text = "重新开始"
	button.custom_minimum_size = Vector2(320, 84)
	button.pressed.connect(func() -> void: restart_requested.emit())
	box.add_child(button)
