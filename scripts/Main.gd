extends Node2D

const C = preload("res://scripts/GameConfig.gd")
const UI = preload("res://scripts/GameUI.gd")
const PLAYER_TEXTURE_FORM_B = preload("res://assets/sprites/player_dave_form_b.png")
const PLAYER_TEXTURE_FORM_A = preload("res://assets/sprites/player_dave_form_a.png")
const PLAYER_WALK_SHEET = preload("res://assets/sprites/player_dave_walk_right_sheet.png")
const ZOMBIE_TEXTURE = preload("res://assets/sprites/zombie_normal_user.png")
const RUNNER_TEXTURE = preload("res://assets/sprites/zombie_runner_user.png")
const TANK_TEXTURE = preload("res://assets/sprites/zombie_tank_user.png")
const RANGED_TEXTURE = preload("res://assets/sprites/zombie_ranged_user.png")
const ZOMBIE_FROZEN_TEXTURE = preload("res://assets/sprites/zombie_normal_frozen.png")
const RUNNER_FROZEN_TEXTURE = preload("res://assets/sprites/zombie_runner_frozen.png")
const TANK_FROZEN_TEXTURE = preload("res://assets/sprites/zombie_tank_frozen.png")
const RANGED_FROZEN_TEXTURE = preload("res://assets/sprites/zombie_ranged_frozen.png")
const ORANGE_TEXTURE = preload("res://assets/sprites/bullet_simple.png")
const LAVA_TEXTURE = preload("res://assets/sprites/bullet_lava.png")
const WATERMELON_TEXTURE = preload("res://assets/sprites/bullet_melon.png")
const MAP_TEXTURE = preload("res://assets/sprites/map_outdoor_user.png")
const EXPLOSION_TEXTURE = preload("res://assets/sprites/explosion.svg")
const VENOM_TEXTURE = preload("res://assets/sprites/venom_user.png")
const HEALTH_POTION_TEXTURE = preload("res://assets/sprites/health_potion.png")
const SFX_BUS = preload("res://scripts/SfxBus.gd")

# The supplied Dave art is a single full-body image. These regions let the
# runtime animate the legs without requiring a second set of source frames.
const PLAYER_SOURCE_SIZE := Vector2(365.0, 551.0)
const PLAYER_WALK_FRAME_SIZE := Vector2(251.0, 414.0)
const PLAYER_WALK_FRAME_COUNT := 8
const PLAYER_WALK_FRAME_SOURCE_Y := 174.0
const PLAYER_WALK_DRAW_SIZE := Vector2(125.0, 125.0)
const PLAYER_WALK_FEET_OFFSET := Vector2(0.0, 8.0)
const PLAYER_WALK_PHASE_SPEED := 7.5
const PLAYER_BODY_SOURCE := Rect2(0.0, 0.0, 365.0, 370.0)
# Keep hands and belt in the static layer. These narrower regions contain only
# the trousers and shoes, so their movement cannot pull the arms or waistband.
const PLAYER_LEFT_LEG_SOURCE := Rect2(100.0, 370.0, 90.0, 115.0)
const PLAYER_RIGHT_LEG_SOURCE := Rect2(175.0, 370.0, 95.0, 115.0)

var ui: CanvasLayer
var player_pos := C.PLAYER_START
var hp := 100.0
var game_time := 0.0
var game_state := "combat"
var enemies: Array[Dictionary] = []
var peas: Array[Dictionary] = []
var explosions: Array[Dictionary] = []
var venoms: Array[Dictionary] = []
var potions: Array[Dictionary] = []
var potion_spawned := [false, false, false]
var unlocked: Array[String] = ["orange"]
var cooldowns := {"orange": 0.0, "black": 0.0, "cow": 0.0}
var levels := {"U01": 0, "U02": 0, "U03": 0, "U04": 0}
var xp := 0
var level := 0
var kills := 0
var fired := 0
var upgrades := 0
var spawn_timer := 0.0
var invincible := 0.0
var rng := RandomNumberGenerator.new()
var camera: Camera2D
var sfx: Node
var next_enemy_id := 1
var skill_cooldowns := {"freeze": 25.0, "burst": 40.0}
var frozen_left := 0.0
var held_keys := {"left": false, "right": false, "up": false, "down": false}
var player_form := "b"
var player_texture: Texture2D = PLAYER_TEXTURE_FORM_B
var form_transition := 0.0
var form_switch_target: Texture2D
var form_swapped := false
var player_walk_phase := 0.0
var player_walk_blend := 0.0
var player_motion := Vector2.ZERO

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ui = UI.new()
	add_child(ui)
	sfx = SFX_BUS.new()
	add_child(sfx)
	camera = Camera2D.new()
	camera.position = player_pos
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(C.MAP_SIZE.x)
	camera.limit_bottom = int(C.MAP_SIZE.y)
	add_child(camera)
	camera.make_current()
	ui.upgrade_selected.connect(_select_upgrade)
	ui.restart_requested.connect(start_new_run)
	ui.resume_requested.connect(_resume)
	ui.skill_pressed.connect(_use_skill)
	rng.seed = 41021
	start_new_run()
	get_viewport().gui_release_focus()
	call_deferred("_focus_game_window")
	if get_window() != null and not get_window().focus_entered.is_connected(_focus_game_input):
		get_window().focus_entered.connect(_focus_game_input)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			rng.seed = int(arg.trim_prefix("--seed="))
		if arg == "--debug-mode=victory":
			_finish("victory")
		elif arg == "--debug-mode=failure":
			_finish("failure")
		elif arg == "--debug-mode=upgrade":
			xp = C.xp_needed(level)

func start_new_run() -> void:
	player_pos = C.PLAYER_START
	hp = 100.0
	game_time = 0.0
	game_state = "combat"
	enemies.clear()
	peas.clear()
	explosions.clear()
	venoms.clear()
	potions.clear()
	potion_spawned = [false, false, false]
	unlocked = ["orange"]
	cooldowns = {"orange": 0.0, "black": 0.0, "cow": 0.0}
	levels = {"U01": 0, "U02": 0, "U03": 0, "U04": 0}
	xp = 0
	level = 0
	kills = 0
	fired = 0
	upgrades = 0
	spawn_timer = 0.0
	invincible = 0.0
	skill_cooldowns = {"freeze": 25.0, "burst": 40.0}
	frozen_left = 0.0
	next_enemy_id = 1
	player_form = "b"
	player_texture = PLAYER_TEXTURE_FORM_B
	form_transition = 0.0
	form_switch_target = null
	form_swapped = false
	player_walk_phase = 0.0
	player_walk_blend = 0.0
	player_motion = Vector2.ZERO
	held_keys = {"left": false, "right": false, "up": false, "down": false}
	if camera != null:
		camera.position = player_pos
	if ui:
		ui.hide_popup()
		call_deferred("_focus_game_window")

func _focus_game_window() -> void:
	var game_window := get_window()
	if game_window != null:
		game_window.grab_focus()
	get_viewport().gui_release_focus()
	_focus_game_input()

func _focus_game_input() -> void:
	if ui != null:
		ui.focus_game_input()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause_game"):
		if game_state == "combat":
			game_state = "paused"
			ui.show_pause()
		elif game_state == "paused":
			_resume()
	if game_state != "combat":
		ui.update_hud(snapshot())
		queue_redraw()
		return
	game_time += delta
	if form_transition > 0.0:
		form_transition = maxf(0.0, form_transition - delta)
		if not form_swapped and form_transition <= 0.11:
			player_texture = form_switch_target
			form_swapped = true
	invincible = maxf(0.0, invincible - delta)
	frozen_left = maxf(0.0, frozen_left - delta)
	if frozen_left <= 0.0:
		for enemy in enemies:
			if enemy["frozen"]:
				enemy["frozen"] = false
				enemy["freeze_anim"] = 0.35
				enemy["freeze_anim_to"] = false
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if movement.length_squared() <= 0.001:
		movement = Vector2(
			float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) or held_keys["right"]) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) or held_keys["left"]),
			float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) or held_keys["down"]) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or held_keys["up"])
		).normalized()
	var is_moving := movement.length_squared() > 0.001
	player_motion = movement if is_moving else Vector2.ZERO
	player_walk_blend = move_toward(player_walk_blend, 1.0 if is_moving else 0.0, delta * (11.0 if is_moving else 15.0))
	if is_moving:
		# Keep one gait cadence for horizontal and vertical movement. The player
		# speed remains unchanged; the reduced cadence is carried by a longer step.
		player_walk_phase = fmod(player_walk_phase + delta * PLAYER_WALK_PHASE_SPEED, TAU)
	if movement.x < -0.01:
		_switch_player_form("a")
	elif movement.x > 0.01:
		_switch_player_form("b")
	player_pos += movement * float(C.PLAYER.speed) * pow(1.12, int(levels["U04"])) * delta
	player_pos.x = clampf(player_pos.x, 80.0, C.MAP_SIZE.x - 80.0)
	player_pos.y = clampf(player_pos.y, 80.0, C.MAP_SIZE.y - 80.0)
	camera.position = player_pos
	for skill_id in skill_cooldowns.keys():
		skill_cooldowns[skill_id] = maxf(0.0, float(skill_cooldowns[skill_id]) - delta)
	if Input.is_action_just_pressed("skill_freeze"):
		_use_skill("freeze")
	if Input.is_action_just_pressed("skill_burst"):
		_use_skill("burst")
	spawn_timer -= delta
	if spawn_timer <= 0.0 and enemies.size() < 1000:
		_spawn_enemy()
		# Keep the previous 20% spawn-rate reduction, then shorten its interval by 10%.
		spawn_timer = maxf(0.05, float(C.wave_for_time(game_time)["spawn_interval"]) * 1.125)
	for kind in unlocked:
		cooldowns[kind] -= delta
		if cooldowns[kind] <= 0.0:
			_fire(kind)
			cooldowns[kind] = float(C.CAT_STATS[kind]["cooldown"]) * pow(0.85, int(levels["U01"]))
	_step_enemies(delta)
	_step_enemy_visuals(delta)
	_step_peas(delta)
	_step_venoms(delta)
	_step_potions()
	for explosion in explosions:
		explosion["life"] -= delta
	for index in range(explosions.size() - 1, -1, -1):
		if explosions[index]["life"] <= 0.0:
			explosions.remove_at(index)
	_check_level()
	if game_time >= 40.0 and not unlocked.has("black"):
		unlocked.append("black")
	if game_time >= 130.0 and not unlocked.has("cow"):
		unlocked.append("cow")
	if game_time >= 240.0:
		_finish("victory")
	ui.update_hud(snapshot())
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	var pressed := key_event.pressed and not key_event.echo
	var key := key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
	match key:
		KEY_A, KEY_LEFT:
			held_keys["left"] = pressed
		KEY_D, KEY_RIGHT:
			held_keys["right"] = pressed
		KEY_W, KEY_UP:
			held_keys["up"] = pressed
		KEY_S, KEY_DOWN:
			held_keys["down"] = pressed

func _switch_player_form(form: String) -> void:
	if form == player_form:
		return
	player_form = form
	form_switch_target = PLAYER_TEXTURE_FORM_A if form == "a" else PLAYER_TEXTURE_FORM_B
	form_transition = 0.22
	form_swapped = false

func _spawn_enemy() -> void:
	var wave: Dictionary = C.wave_for_time(game_time)
	var weights: Dictionary = wave["weights"]
	var roll := rng.randf()
	var cumulative := 0.0
	var kind := "normal"
	for candidate in weights.keys():
		cumulative += float(weights[candidate])
		if roll <= cumulative:
			kind = String(candidate)
			break
	var position := player_pos + Vector2.from_angle(rng.randf_range(0.0, TAU)) * 900.0
	enemies.append({"id": next_enemy_id, "kind": kind, "pos": position, "hp": float(C.ENEMY_STATS[kind]["hp"]), "venom_timer": float(C.ENEMY_STATS[kind].get("shoot_interval", 8.0)), "frozen": frozen_left > 0.0, "freeze_anim": 0.0, "freeze_anim_to": frozen_left > 0.0})
	next_enemy_id += 1

func _fire(kind: String) -> void:
	if enemies.is_empty() or peas.size() >= 36:
		return
	var target: Dictionary = enemies[0]
	var best_distance := INF
	for candidate in enemies:
		var candidate_distance: float = player_pos.distance_squared_to(candidate["pos"])
		if candidate_distance < best_distance:
			best_distance = candidate_distance
			target = candidate
	var direction: Vector2 = (target["pos"] - player_pos).normalized()
	var bullet_speed := float(C.CAT_STATS[kind]["speed"]) * pow(1.25, int(levels["U03"]))
	peas.append({"kind": kind, "pos": player_pos, "velocity": direction * bullet_speed, "life": float(C.CAT_STATS[kind]["life"]), "hit_ids": []})
	fired += 1
	if sfx != null:
		sfx.play_event(C.CAT_STATS[kind]["sfx"])

func _step_enemies(delta: float) -> void:
	if frozen_left > 0.0:
		return
	for enemy in enemies:
		var direction: Vector2 = (player_pos - enemy["pos"]).normalized()
		enemy["pos"] += direction * float(C.ENEMY_STATS[enemy["kind"]]["speed"]) * delta
		if enemy["kind"] == "ranged":
			enemy["venom_timer"] -= delta
			if enemy["venom_timer"] <= 0.0 and enemy["pos"].distance_to(player_pos) <= 1500.0:
				var venom_direction: Vector2 = (player_pos - enemy["pos"]).normalized()
				venoms.append({"pos": enemy["pos"], "velocity": venom_direction * 218.5, "life": 8.0})
				enemy["venom_timer"] = float(C.ENEMY_STATS["ranged"]["shoot_interval"])
				if sfx != null:
					sfx.play_event("milk_launch")
		if enemy["pos"].distance_to(player_pos) < 70.0:
			_take_damage(float(C.ENEMY_STATS[enemy["kind"]]["contact_damage"]))

func _step_enemy_visuals(delta: float) -> void:
	for enemy in enemies:
		if float(enemy["freeze_anim"]) > 0.0:
			enemy["freeze_anim"] = maxf(0.0, float(enemy["freeze_anim"]) - delta)

func _step_venoms(delta: float) -> void:
	for venom in venoms:
		venom["life"] -= delta
		venom["pos"] += venom["velocity"] * delta
		if venom["pos"].distance_to(player_pos) <= float(C.MILK["radius"]) + 32.0:
			if sfx != null:
				sfx.play_event("venom_hit")
			_take_damage(float(C.MILK["damage"]), "")
			venom["life"] = 0.0
	for index in range(venoms.size() - 1, -1, -1):
		if venoms[index]["life"] <= 0.0:
			venoms.remove_at(index)

func _step_potions() -> void:
	var spawn_times := [60.0, 120.0, 180.0]
	for index in range(spawn_times.size()):
		if not potion_spawned[index] and game_time >= spawn_times[index]:
			_spawn_potion()
			potion_spawned[index] = true
	for index in range(potions.size() - 1, -1, -1):
		if potions[index]["pos"].distance_to(player_pos) <= 72.0:
			hp = minf(100.0, hp + float(C.HEALTH_POTION_HEAL))
			if sfx != null:
				sfx.play_event("potion_drink")
			potions.remove_at(index)

func _spawn_potion() -> void:
	var margin := 160.0
	var potion_position := Vector2(
		rng.randf_range(margin, C.MAP_SIZE.x - margin),
		rng.randf_range(margin, C.MAP_SIZE.y - margin)
	)
	potions.append({"pos": potion_position})

func _step_peas(delta: float) -> void:
	for pea in peas:
		pea["life"] -= delta
		pea["pos"] += pea["velocity"] * delta
		var hit_distance := 100.0 if pea["kind"] == "cow" else 68.0
		for enemy in enemies:
			if enemy["pos"].distance_to(pea["pos"]) < hit_distance and not pea["hit_ids"].has(enemy["id"]):
				var damage := float(C.CAT_STATS[pea["kind"]]["damage"]) * pow(1.2, int(levels["U02"]))
				if pea["kind"] == "black":
					var blast_radius := float(C.CAT_STATS["black"]["explosion_radius"])
					explosions.append({"pos": pea["pos"], "life": 0.24, "radius": blast_radius})
					if sfx != null:
						sfx.play_event("cat_black_explode")
					for nearby in enemies:
						if nearby["pos"].distance_to(pea["pos"]) <= blast_radius:
							nearby["hp"] -= float(C.CAT_STATS["black"]["explosion_damage"]) * pow(1.2, int(levels["U02"]))
				else:
					enemy["hp"] -= damage
				pea["hit_ids"].append(enemy["id"])
				if pea["kind"] != "cow":
					pea["life"] = 0.0
					break
	for index in range(peas.size() - 1, -1, -1):
		if peas[index]["life"] <= 0.0:
			peas.remove_at(index)
	for index in range(enemies.size() - 1, -1, -1):
		if enemies[index]["hp"] <= 0.0:
			enemies.remove_at(index)
			kills += 1
			xp += 8

func _use_skill(skill_id: String) -> void:
	if game_state != "combat" or float(skill_cooldowns.get(skill_id, 0.0)) > 0.0:
		return
	if skill_id == "freeze":
		frozen_left = 3.0
		for enemy in enemies:
			enemy["frozen"] = true
			enemy["freeze_anim"] = 0.35
			enemy["freeze_anim_to"] = true
		skill_cooldowns["freeze"] = 25.0
		if sfx != null:
			sfx.play_event("level_up")
	elif skill_id == "burst":
		for direction_index in range(8):
			var direction := Vector2.from_angle(TAU * float(direction_index) / 8.0)
			for shot in range(1):
				var burst_speed := float(C.CAT_STATS["black"]["speed"]) * pow(1.25, int(levels["U03"]))
				peas.append({"kind": "black", "pos": player_pos, "velocity": direction * burst_speed, "life": float(C.CAT_STATS["black"]["life"]), "hit_ids": []})
				fired += 1
		skill_cooldowns["burst"] = 40.0
		if sfx != null:
			sfx.play_event("cat_black_launch")

func _take_damage(amount: float, sound_event: String = "player_hurt") -> void:
	if invincible > 0.0:
		return
	hp = maxf(0.0, hp - amount)
	invincible = float(C.PLAYER["invincible_time"])
	if sfx != null and not sound_event.is_empty():
		sfx.play_event(sound_event)
	if hp <= 0.0:
		_finish("failure")

func _check_level() -> void:
	if xp < C.xp_needed(level):
		return
	xp -= C.xp_needed(level)
	level += 1
	var options: Array[String] = []
	for id in C.UPGRADES.keys():
		if int(levels[id]) < int(C.UPGRADES[id]["max"]):
			options.append(id)
	if not options.is_empty():
		game_state = "upgrade"
		ui.show_upgrade(options.slice(0, mini(3, options.size())), levels)

func _select_upgrade(id: String) -> void:
	if levels.has(id):
		levels[id] += 1
		upgrades += 1
	game_state = "combat"
	ui.hide_popup()

func _resume() -> void:
	game_state = "combat"
	ui.hide_popup()

func _finish(result: String) -> void:
	if game_state in ["victory", "failure"]:
		return
	game_state = result
	ui.show_result("胜利" if result == "victory" else "失败", snapshot())

func snapshot() -> Dictionary:
	var score := 20 if game_state == "failure" else mini(100, int(round(hp)) + 20)
	return {"player_hp": hp, "player_max_hp": 100, "current_wave": int(C.wave_for_time(game_time)["index"]), "wave_progress": C.wave_progress(game_time), "game_time": game_time, "game_state": game_state, "enemies": enemies.size(), "peas": peas.size(), "venom": venoms.size(), "potions": potions.size(), "kills": kills, "xp": xp, "xp_needed": C.xp_needed(level), "upgrade_count": upgrades, "unlocked_weapons": unlocked.duplicate(), "upgrade_levels": levels.duplicate(), "cats_fired": fired, "skill_cooldowns": skill_cooldowns.duplicate(), "frozen_left": frozen_left, "game_score": score}

func _draw_player_pose(texture: Texture2D, center: Vector2, draw_size: Vector2, alpha: float) -> void:
	var tint := Color(1.0, 1.0, 1.0, clampf(alpha, 0.0, 1.0))
	var top_left := center - draw_size * 0.5
	if player_walk_blend <= 0.01:
		draw_texture_rect(texture, Rect2(top_left, draw_size), false, tint)
		return

	# The supplied strip is a right-facing walk cycle. Use it for every movement
	# direction so vertical travel becomes an in-place step, preserving the last
	# horizontal facing instead of switching to a different gait.
	if player_motion.length_squared() > 0.001:
		var phase := fmod(player_walk_phase, TAU)
		var frame_index := clampi(int(floor(phase / TAU * PLAYER_WALK_FRAME_COUNT)), 0, PLAYER_WALK_FRAME_COUNT - 1)
		var source := Rect2(float(frame_index) * PLAYER_WALK_FRAME_SIZE.x, PLAYER_WALK_FRAME_SOURCE_Y, PLAYER_WALK_FRAME_SIZE.x, PLAYER_WALK_FRAME_SIZE.y)
		var walk_center := center + PLAYER_WALK_FEET_OFFSET
		var mirror := -1.0 if player_form == "a" else 1.0
		draw_set_transform(walk_center, 0.0, Vector2(mirror, 1.0))
		draw_texture_rect_region(PLAYER_WALK_SHEET, Rect2(-PLAYER_WALK_DRAW_SIZE * 0.5, PLAYER_WALK_DRAW_SIZE), source, tint)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return

	var source_scale := draw_size / PLAYER_SOURCE_SIZE
	var step := sin(player_walk_phase)
	var left_lift := maxf(0.0, step)
	var right_lift := maxf(0.0, -step)
	var stride := 12.0 * player_walk_blend
	var lift := 5.0 * player_walk_blend
	var body_size := PLAYER_BODY_SOURCE.size * source_scale
	var body_center := top_left + body_size * 0.5
	draw_set_transform(body_center, 0.0, Vector2.ONE)
	draw_texture_rect_region(texture, Rect2(-body_size * 0.5, body_size), PLAYER_BODY_SOURCE, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var left_size := PLAYER_LEFT_LEG_SOURCE.size * source_scale
	var left_center := top_left + (PLAYER_LEFT_LEG_SOURCE.position + PLAYER_LEFT_LEG_SOURCE.size * 0.5) * source_scale
	left_center += Vector2(step * stride, -left_lift * lift)
	draw_set_transform(left_center, -0.035 * step * player_walk_blend, Vector2.ONE)
	draw_texture_rect_region(texture, Rect2(-left_size * 0.5, left_size), PLAYER_LEFT_LEG_SOURCE, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var right_size := PLAYER_RIGHT_LEG_SOURCE.size * source_scale
	var right_center := top_left + (PLAYER_RIGHT_LEG_SOURCE.position + PLAYER_RIGHT_LEG_SOURCE.size * 0.5) * source_scale
	right_center += Vector2(-step * stride, -right_lift * lift)
	draw_set_transform(right_center, 0.035 * step * player_walk_blend, Vector2.ONE)
	draw_texture_rect_region(texture, Rect2(-right_size * 0.5, right_size), PLAYER_RIGHT_LEG_SOURCE, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw() -> void:
	draw_texture_rect(MAP_TEXTURE, Rect2(Vector2.ZERO, C.MAP_SIZE), false)
	# Idle/full-body art is rendered 5% larger to match the perceived size of
	# the cropped walking frames.
	var player_size := Vector2(151.2, 151.2)
	var player_alpha := 1.0
	var player_scale := 1.0
	if form_transition > 0.0:
		var progress := 1.0 - form_transition / 0.22
		player_scale = 1.0 - 0.20 * sin(progress * PI)
		player_alpha = 0.72 + 0.28 * abs(cos(progress * PI))
	_draw_player_pose(player_texture, player_pos, player_size * player_scale, player_alpha)
	if form_transition > 0.0 and not form_swapped:
		var target_progress := (1.0 - form_transition / 0.22) / 0.5
		_draw_player_pose(form_switch_target, player_pos, player_size * player_scale, clampf(target_progress, 0.0, 1.0) * 0.55)
	for enemy in enemies:
		var texture: Texture2D = ZOMBIE_TEXTURE
		var frozen_texture: Texture2D = ZOMBIE_FROZEN_TEXTURE
		if enemy["kind"] == "calf":
			texture = RUNNER_TEXTURE
			frozen_texture = RUNNER_FROZEN_TEXTURE
		elif enemy["kind"] == "tank":
			texture = TANK_TEXTURE
			frozen_texture = TANK_FROZEN_TEXTURE
		elif enemy["kind"] == "ranged":
			texture = RANGED_TEXTURE
			frozen_texture = RANGED_FROZEN_TEXTURE
		var enemy_size := Vector2(104, 104)
		var anim_left := float(enemy["freeze_anim"])
		if anim_left > 0.0:
			var progress := 1.0 - anim_left / 0.35
			var squash := 1.0 - 0.12 * sin(progress * PI)
			var rect := Rect2(enemy["pos"] - enemy_size * squash * 0.5, enemy_size * squash)
			var frozen_alpha := progress if enemy["freeze_anim_to"] else 1.0 - progress
			draw_texture_rect(texture, rect, false, Color(1, 1, 1, 1.0 - frozen_alpha))
			draw_texture_rect(frozen_texture, rect, false, Color(1, 1, 1, frozen_alpha))
		else:
			draw_texture_rect(frozen_texture if enemy["frozen"] else texture, Rect2(enemy["pos"] - enemy_size * 0.5, enemy_size), false)
	for pea in peas:
		var texture = ORANGE_TEXTURE
		var bullet_size := Vector2(28, 28)
		if pea["kind"] == "black":
			texture = LAVA_TEXTURE
			bullet_size = Vector2(42, 42)
		elif pea["kind"] == "cow":
			texture = WATERMELON_TEXTURE
			bullet_size = Vector2(84, 84)
		draw_texture_rect(texture, Rect2(pea["pos"] - bullet_size * 0.5, bullet_size), false)
	for explosion in explosions:
		var size := Vector2.ONE * float(explosion["radius"]) * 1.35 * (1.0 - float(explosion["life"]) / 0.24)
		draw_texture_rect(EXPLOSION_TEXTURE, Rect2(explosion["pos"] - size * 0.5, size), false)
	for venom in venoms:
		draw_set_transform(venom["pos"], venom["velocity"].angle(), Vector2(0.0385, 0.0385))
		draw_texture_rect(VENOM_TEXTURE, Rect2(-1137.5, -693.5, 2275.0, 1387.0), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for potion in potions:
		draw_texture_rect(HEALTH_POTION_TEXTURE, Rect2(potion["pos"] - Vector2(34, 42), Vector2(68, 84)), false)
