extends RefCounted

const GameConfig = preload("res://scripts/GameConfig.gd")

static func save_path(default_path := "") -> String:
	return default_path if not default_path.is_empty() else String(GameConfig.SCORE["save_path"])

static func globalized_path(path := "") -> String:
	var resolved := save_path(path)
	if resolved.begins_with("user://") or resolved.begins_with("res://"):
		return ProjectSettings.globalize_path(resolved)
	return resolved

static func clear_scores(path := "") -> Dictionary:
	var resolved := save_path(path)
	if FileAccess.file_exists(resolved):
		var err := DirAccess.remove_absolute(globalized_path(resolved))
		return {
			"success": err == OK or err == ERR_FILE_NOT_FOUND,
			"error": err,
			"path": resolved,
			"global_path": globalized_path(resolved)
		}
	return {
		"success": true,
		"error": OK,
		"path": resolved,
		"global_path": globalized_path(resolved)
	}

static func load_scores(path := "") -> Array:
	var resolved := save_path(path)
	if not FileAccess.file_exists(resolved):
		return []
	var file := FileAccess.open(resolved, FileAccess.READ)
	if file == null:
		return []
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	var raw_scores: Array = parsed.get("scores", [])
	var scores := []
	for item in raw_scores:
		if typeof(item) == TYPE_DICTIONARY and item.has("score"):
			scores.append(_normalize_entry(item))
	return _top_scores(scores)

static func add_score(entry: Dictionary, path := "") -> Dictionary:
	var resolved := save_path(path)
	var current := load_scores(resolved)
	var previous_best := 0
	if not current.is_empty():
		previous_best = int(current[0].get("score", 0))
	var normalized := _normalize_entry(entry)
	var is_new_record := current.is_empty() or int(normalized["score"]) > previous_best
	current.append(normalized)
	var top := _top_scores(current)
	_write_scores(top, resolved)
	return {
		"entry": normalized,
		"scores": top,
		"previous_best": previous_best,
		"is_new_record": is_new_record,
		"persistence_path": resolved,
		"global_persistence_path": globalized_path(resolved)
	}

static func write_score_values(values: Array, path := "") -> Array:
	var written := []
	for value in values:
		var entry := {
			"score": int(value),
			"result": "probe",
			"game_time": 0.0,
			"kills": 0,
			"cats_fired": 0,
			"upgrade_count": 0,
			"created_at": Time.get_datetime_string_from_system(false, true)
		}
		add_score(entry, path)
		written.append(int(value))
	return written

static func score_values(scores: Array) -> Array:
	var values := []
	for item in scores:
		values.append(int(item.get("score", 0)))
	return values

static func _write_scores(scores: Array, path: String) -> void:
	var dir := path.get_base_dir()
	if not dir.is_empty():
		var global_dir := ProjectSettings.globalize_path(dir) if dir.begins_with("user://") or dir.begins_with("res://") else dir
		DirAccess.make_dir_recursive_absolute(global_dir)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("无法写入成绩：%s" % path)
		return
	file.store_string(JSON.stringify({
		"version": 1,
		"scores": scores
	}, "\t"))
	file.close()

static func _top_scores(scores: Array) -> Array:
	var sorted := scores.duplicate(true)
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var score_a := int(a.get("score", 0))
		var score_b := int(b.get("score", 0))
		if score_a == score_b:
			return String(a.get("created_at", "")) > String(b.get("created_at", ""))
		return score_a > score_b
	)
	var limit: int = min(sorted.size(), int(GameConfig.SCORE["max_entries"]))
	return sorted.slice(0, limit)

static func _normalize_entry(entry: Dictionary) -> Dictionary:
	return {
		"score": int(entry.get("score", 0)),
		"result": String(entry.get("result", "")),
		"game_time": float(entry.get("game_time", 0.0)),
		"kills": int(entry.get("kills", 0)),
		"cats_fired": int(entry.get("cats_fired", 0)),
		"upgrade_count": int(entry.get("upgrade_count", 0)),
		"created_at": String(entry.get("created_at", Time.get_datetime_string_from_system(false, true)))
	}
