extends Node

const VIEWPORT_SIZE := Vector2i(1920, 1080)
const MAP_SIZE := Vector2(4096, 2305)
const PLAYER_START := Vector2(2048, 1152)
const CAMERA_ZOOM := Vector2(1.0, 1.0)
const HEALTH_POTION_HEAL := 10.0

const PLAYER := {
	"max_hp": 100.0,
	"speed": 360.0,
	"invincible_time": 1.0,
	"radius": 50.4
}

const LIMITS := {
	"cats": 36,
	"enemies": 1000,
	"milk": 220,
	"xp": 500
}

const CAT_STATS := {
	"orange": {
		"name": "橘豌豆",
		"damage": 16.0,
		"speed": 760.0,
		"life": 1.25,
		"cooldown": 0.42,
		"limit": 18,
		"radius": 34.0,
		"spriteframes": "res://assets/sprites/pea_orange.svg",
		"sfx": "cat_orange_launch"
	},
	"black": {
		"name": "熔岩豌豆",
		"damage": 12.0,
		"speed": 620.0,
		"life": 1.4,
		"cooldown": 1.35,
		"limit": 8,
		"radius": 36.0,
		"explosion_radius": 220.0,
		"explosion_damage": 24.0,
		"spriteframes": "res://assets/sprites/pea_lava.svg",
		"sfx": "cat_black_launch"
	},
	"cow": {
		"name": "西瓜豌豆",
		"damage": 48.0,
		"speed": 520.0,
		"life": 1.6,
		"cooldown": 1.1,
		"limit": 10,
		"radius": 38.0,
		"max_hits": 5,
		"sweep_range": 360.0,
		"spriteframes": "res://assets/sprites/pea_watermelon.svg",
		"sfx": "cat_cow_spin"
	}
}

const ENEMY_STATS := {
	"normal": {
		"name": "普通僵尸",
		"hp": 32.0,
		"speed": 135.0,
		"contact_damage": 7.0,
		"xp": 8,
		"active_range": 1500.0,
		"radius": 48.0,
		"spriteframes": "res://assets/sprites/zombie_normal_user.png",
		"anim_prefix": "walk"
	},
	"calf": {
		"name": "橄榄球小僵尸",
		"hp": 28.8,
		"speed": 210.0,
		"contact_damage": 5.0,
		"xp": 7,
		"active_range": 1500.0,
		"radius": 38.0,
		"spriteframes": "res://assets/sprites/zombie_runner_user.png",
		"anim_prefix": "run"
	},
	"tank": {
		"name": "铁桶大僵尸",
		"hp": 270.0,
		"speed": 85.0,
		"contact_damage": 11.0,
		"xp": 18,
		"active_range": 1500.0,
		"radius": 64.0,
		"spriteframes": "res://assets/sprites/zombie_tank_user.png",
		"anim_prefix": "walk"
	},
	"ranged": {
		"name": "吐毒液远程僵尸",
		"hp": 42.0,
		"speed": 105.0,
		"contact_damage": 5.0,
		"xp": 12,
		"active_range": 1500.0,
		"radius": 50.0,
		"keep_distance": 430.0,
		"shoot_interval": 8.0,
		"max_milk": 2,
		"spriteframes": "res://assets/sprites/zombie_ranged_user.png",
		"anim_prefix": "walk"
	}
}

const MILK := {
	"damage": 3.0,
	"speed": 360.0,
	"life": 2.2,
	"radius": 15.4,
	"spriteframes": "res://assets/sprites/venom.svg",
	"shoot_interval": 8.0
}

const XP := {
	"pickup_range": 300.0,
	"speed": 650.0,
	"radius": 18.0,
	"sprite": "res://assets/sprites/xp_orb.svg"
}

const XP_REQUIREMENTS := [40, 80, 130, 190, 260, 280, 1000]

const SCORE := {
	"save_path": "user://huazi_scores.json",
	"max_entries": 10,
	"kill_points": 10,
	"survival_second_points": 1,
	"cat_fired_points": 1,
	"upgrade_points": 50,
	"victory_bonus": 500
}

const UPGRADES := {
	"U01": {
		"name": "子弹连发",
		"desc": "所有子弹发射冷却 -15%",
		"max": 4,
		"stat": "cooldown",
		"factor": 0.80,
		"icon": "res://assets/sprites/bullet_simple.png"
	},
	"U02": {
		"name": "增加伤害",
		"desc": "所有子弹伤害 +20%",
		"max": 4,
		"stat": "damage",
		"factor": 1.25,
		"icon": "res://assets/sprites/bullet_lava.png"
	},
	"U03": {
		"name": "子弹加速",
		"desc": "所有子弹飞行速度 +25%",
		"max": 3,
		"stat": "cat_speed",
		"factor": 1.25,
		"icon": "res://assets/sprites/bullet_melon.png"
	},
	"U04": {
		"name": "跑快一点",
		"desc": "戴夫移动速度 +25%",
		"max": 3,
		"stat": "player_speed",
		"factor": 1.25,
		"icon": "res://assets/sprites/ui/runtime/icon_dave.svg"
	}
}

const WAVES := [
	{
		"index": 1,
		"start": 0.0,
		"end": 40.0,
		"target_spawns": 100,
		"spawn_interval": 0.4,
		"weights": {"normal": 1.0},
		"unlock": "black"
	},
	{
		"index": 2,
		"start": 40.0,
		"end": 80.0,
		"target_spawns": 300,
		"spawn_interval": 0.1333333333,
		"weights": {"normal": 0.35, "calf": 0.65},
		"unlock": ""
	},
	{
		"index": 3,
		"start": 80.0,
		"end": 130.0,
		"target_spawns": 500,
		"spawn_interval": 0.1,
		"weights": {"normal": 0.3, "calf": 0.2, "tank": 0.5},
		"unlock": "cow"
	},
	{
		"index": 4,
		"start": 130.0,
		"end": 190.0,
		"target_spawns": 800,
		"spawn_interval": 0.075,
		"weights": {"normal": 0.45, "calf": 0.1, "tank": 0.25, "ranged": 0.2},
		"unlock": ""
	},
	{
		"index": 5,
		"start": 190.0,
		"end": 240.0,
		"target_spawns": 1000,
		"spawn_interval": 0.05,
		"weights": {"normal": 0.18, "calf": 0.24, "tank": 0.25, "ranged": 0.33},
		"unlock": ""
	}
]

const SFX := {
	"cat_orange_launch": "res://assets/audio/sfx/cat_orange_launch_01.wav",
	"cat_black_launch": "res://assets/audio/sfx/cat_black_launch_01.wav",
	"cat_cow_spin": "res://assets/audio/sfx/watermelon_launch_user.mp3",
	"milk_launch": "res://assets/audio/sfx/milk_launch_01.wav",
	"venom_hit": "res://assets/audio/sfx/venom_hit_user.mp3",
	"cat_black_explode": "res://assets/audio/sfx/cat_black_explode_01.mp3",
	"enemy_die": "res://assets/audio/sfx/enemy_die_01.wav",
	"player_hurt": "res://assets/audio/sfx/player_hurt_user.wav",
	"potion_drink": "res://assets/audio/sfx/potion_drink_user.mp3",
	"xp_pickup": "res://assets/audio/sfx/xp_pickup_01.wav",
	"level_up": "res://assets/audio/sfx/level_up_01.wav",
	"ui_select": "res://assets/audio/sfx/ui_select_01.wav",
	"wave_start": "res://assets/audio/sfx/wave_start_01.wav",
	"weapon_unlock": "res://assets/audio/sfx/weapon_unlock_01.wav",
	"victory": "res://assets/audio/sfx/victory_01.wav",
	"defeat": "res://assets/audio/sfx/defeat_01.wav"
}

const BGM := {
	"source_input_path": "/Users/wawa/Downloads/39995331_da2-1-16.mp4",
	"runtime_path": "res://assets/audio/sfx/background_bgm_01.wav"
}

static func xp_needed(level_index: int) -> int:
	if level_index < XP_REQUIREMENTS.size():
		return XP_REQUIREMENTS[level_index]
	return XP_REQUIREMENTS[-1] + 400 * (level_index - XP_REQUIREMENTS.size() + 1)

static func wave_for_time(game_time: float) -> Dictionary:
	for wave in WAVES:
		if game_time >= wave.start and game_time < wave.end:
			return wave
	return WAVES[-1]

static func wave_progress(game_time: float) -> float:
	var wave := wave_for_time(game_time)
	return clamp((game_time - wave.start) / max(0.01, wave.end - wave.start), 0.0, 1.0)

static func score_for_stats(game_time: float, kills: int, cats_fired: int, upgrade_count: int, result: String) -> int:
	var score := int(floor(max(0.0, game_time))) * int(SCORE["survival_second_points"])
	score += max(0, kills) * int(SCORE["kill_points"])
	score += max(0, cats_fired) * int(SCORE["cat_fired_points"])
	score += max(0, upgrade_count) * int(SCORE["upgrade_points"])
	if result == "victory":
		score += int(SCORE["victory_bonus"])
	return max(0, score)
