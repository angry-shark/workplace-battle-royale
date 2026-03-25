extends Node
## SaveManager - 存档管理
## 负责游戏数据的保存和加载

const SAVE_DIR: String = "user://saves/"
const SETTINGS_FILE: String = "user://settings.json"
const STATS_FILE: String = "user://stats.json"

# 游戏设置
var settings: Dictionary = {
	"master_volume": 100,
	"bgm_volume": 80,
	"sfx_volume": 100,
	"fullscreen": false,
	"language": "zh_CN"
}

func _ready():
	print("SaveManager initialized")
	_ensure_save_directory()
	_load_settings()

## 确保存档目录存在
func _ensure_save_directory() -> void:
	var dir = DirAccess.open("user://")
	if dir:
		if not dir.dir_exists("saves"):
			dir.make_dir("saves")

## 保存设置
func save_settings() -> bool:
	var file = FileAccess.open(SETTINGS_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(settings, "\t"))
		file.close()
		print("Settings saved")
		return true
	push_error("Failed to save settings")
	return false

## 加载设置
func _load_settings() -> bool:
	if not FileAccess.file_exists(SETTINGS_FILE):
		return false
		
	var file = FileAccess.open(SETTINGS_FILE, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(content)
		if error == OK:
			var data = json.get_data()
			for key in data:
				if settings.has(key):
					settings[key] = data[key]
			print("Settings loaded")
			return true
		else:
			push_error("Failed to parse settings: " + json.get_error_message())
	return false

## 保存游戏存档
func save_game(slot_name: String = "auto") -> bool:
	var save_data = _collect_save_data()
	var filename = SAVE_DIR + slot_name + ".json"
	
	var file = FileAccess.open(filename, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("Game saved to: " + filename)
		return true
	push_error("Failed to save game to: " + filename)
	return false

## 加载游戏存档
func load_game(slot_name: String = "auto") -> bool:
	var filename = SAVE_DIR + slot_name + "*.json"
	
	if not FileAccess.file_exists(filename):
		print("Save file not found: " + filename)
		return false
	
	var file = FileAccess.open(filename, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(content)
		if error == OK:
			var data = json.get_data()
			_apply_save_data(data)
			print("Game loaded from: " + filename)
			return true
		else:
			push_error("Failed to parse save file: " + json.get_error_message())
	return false

## 收集存档数据
func _collect_save_data() -> Dictionary:
	var data = {
		"version": Config.VERSION,
		"timestamp": Time.get_datetime_string_from_system(),
		"game_seed": GameManager.game_seed,
		"game_state": {
			"turn": GameManager.current_turn,
			"month": GameManager.current_month,
			"quarter": GameManager.current_quarter,
			"year": GameManager.current_year
		},
		"player": {
			"name": PlayerData.player_name,
			"profession": PlayerData.profession,
			"rank": PlayerData.rank,
			"hp": PlayerData.current_hp,
			"max_hp": PlayerData.max_hp,
			"kpi": PlayerData.current_kpi,
			"salary": PlayerData.current_salary,
			"total_salary": PlayerData.total_salary,
			"is_alive": PlayerData.is_alive,
			"hexes": PlayerData.hexes,
			"hand_cards": PlayerData.hand_cards
		}
	}
	return data

## 应用存档数据
func _apply_save_data(data: Dictionary) -> void:
	if data.has("game_seed"):
		GameManager.game_seed = data.game_seed
		seed(data.game_seed)
	
	if data.has("game_state"):
		GameManager.current_turn = data.game_state.get("turn", 0)
		GameManager.current_month = data.game_state.get("month", 1)
		GameManager.current_quarter = data.game_state.get("quarter", 1)
		GameManager.current_year = data.game_state.get("year", 1)
	
	if data.has("player"):
		var p = data.player
		PlayerData.player_name = p.get("name", "打工人")
		PlayerData.profession = p.get("profession", Config.Profession.PROGRAMMER)
		PlayerData.rank = p.get("rank", Config.Rank.P1)
		PlayerData.current_hp = p.get("hp", Config.INITIAL_HP)
		PlayerData.max_hp = p.get("max_hp", Config.INITIAL_HP)
		PlayerData.current_kpi = p.get("kpi", 0)
		PlayerData.current_salary = p.get("salary", 0)
		PlayerData.total_salary = p.get("total_salary", 0)
		PlayerData.is_alive = p.get("is_alive", true)
		PlayerData.hexes = p.get("hexes", [])
		PlayerData.hand_cards = p.get("hand_cards", [])

## 获取所有存档槽
func get_save_slots() -> Array:
	var slots = []
	var dir = DirAccess.open(SAVE_DIR)
	if dir:
		dir.list_dir_begin()
		var filename = dir.get_next()
		while filename != "":
			if filename.ends_with(".json"):
				slots.append(filename.get_basename())
			filename = dir.get_next()
		dir.list_dir_end()
	return slots

## 删除存档
func delete_save(slot_name: String) -> bool:
	var filename = SAVE_DIR + slot_name + ".json"
	if FileAccess.file_exists(filename):
		var dir = DirAccess.open(SAVE_DIR)
		if dir:
			dir.remove(filename)
			print("Save deleted: " + filename)
			return true
	return false

## 检查存档是否存在
func has_save(slot_name: String = "auto") -> bool:
	return FileAccess.file_exists(SAVE_DIR + slot_name + ".json")

## 保存统计数据
func save_stats() -> bool:
	var file = FileAccess.open(STATS_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(PlayerData.stats, "\t"))
		file.close()
		print("Stats saved")
		return true
	return false

## 加载统计数据
func load_stats() -> bool:
	if not FileAccess.file_exists(STATS_FILE):
		return false
		
	var file = FileAccess.open(STATS_FILE, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(content)
		if error == OK:
			var data = json.get_data()
			for key in data:
				if PlayerData.stats.has(key):
					PlayerData.stats[key] = data[key]
			print("Stats loaded")
			return true
	return false
