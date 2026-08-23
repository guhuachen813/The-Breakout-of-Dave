extends Control

signal activated

var skill_id := ""
var key_hint := ""
var title := ""
var icon: Texture2D
var remaining := 0.0
var duration := 1.0
var armed := false

func setup(id: String, texture: Texture2D, label: String, key: String, cooldown: float) -> void:
	skill_id = id
	icon = texture
	title = label
	key_hint = key
	duration = cooldown
	custom_minimum_size = Vector2(128, 154)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	queue_redraw()

func set_cooldown(value: float) -> void:
	remaining = maxf(0.0, value)
	armed = remaining <= 0.0
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if armed:
			activated.emit()
		accept_event()

func _draw() -> void:
	var center := Vector2(64, 58)
	draw_circle(center + Vector2(0, 5), 55.0, Color(0.02, 0.04, 0.06, 0.55))
	draw_circle(center, 53.0, Color("182936"))
	draw_arc(center, 53.0, 0.0, TAU, 64, Color("e7d3a1"), 3.0, true)
	var progress := 1.0 - remaining / maxf(0.01, duration)
	var ring_color := Color("f6b44c") if armed else Color("6f8791")
	draw_arc(center, 49.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 64, ring_color, 7.0, true)
	if not armed:
		draw_circle(center, 38.0, Color(0.05, 0.09, 0.12, 0.42))
	if icon != null:
		var icon_rect := Rect2(center - Vector2(34, 34), Vector2(68, 68))
		draw_texture_rect(icon, icon_rect, false, Color(1.0, 1.0, 1.0, 1.0 if armed else 0.18))
	var key_box := Rect2(43, 8, 42, 22)
	draw_style_box(_key_style(), key_box)
	draw_string(ThemeDB.fallback_font, Vector2(43, 24), key_hint, HORIZONTAL_ALIGNMENT_CENTER, 42, 15, Color("fff0cf"))
	draw_string(ThemeDB.fallback_font, Vector2(0, 136), title, HORIZONTAL_ALIGNMENT_CENTER, 128, 17, Color("f2e5c7"))
	if not armed:
		draw_string(ThemeDB.fallback_font, Vector2(0, 66), "%.1f" % remaining, HORIZONTAL_ALIGNMENT_CENTER, 128, 18, Color.WHITE)

func _key_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("394f5b")
	style.border_color = Color("f2d6a2")
	style.set_border_width_all(1)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	return style
