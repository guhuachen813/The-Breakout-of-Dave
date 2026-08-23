extends Node

const DIRS := ["e", "se", "s", "sw", "w", "nw", "n", "ne"]

static func from_vector(v: Vector2) -> String:
	if v.length_squared() < 0.001:
		return "s"
	var angle := fposmod(v.angle(), TAU)
	var index := int(round(angle / (TAU / 8.0))) % 8
	return DIRS[index]

static func play_direction(sprite: AnimatedSprite2D, prefix: String, direction: Vector2, fallback_dir: String = "s") -> String:
	var dir := fallback_dir
	if direction.length_squared() > 0.001:
		dir = from_vector(direction)
	var anim := "%s_%s" % [prefix, dir]
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(anim):
		if sprite.animation != anim:
			sprite.play(anim)
	return dir
