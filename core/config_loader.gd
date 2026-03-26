class_name ConfigLoader
## ConfigLoader - 配置加载器
## 负责加载和管理所有JSON配置文件

const RESOURCES_PATH: String = "res://resources/"

# 缓存配置数据
var _cache: Dictionary = {}

## 加载职业配置
static func load_profession(profession_type: int) -> Dictionary:
	var file_name: String
	match profession_type:
		Config.Profession.PROGRAMMER:
			file_name = "programmer.json"
		Config.Profession.HR:
			file_name = "hr.json"
		Config.Profession.FINANCE:
			file_name = "finance.json"
		Config.Profession.OPERATIONS:
			file_name = "operations.json"
		Config.Profession.SALES:
			file_name = "sales.json"
		_:
			return _get_default_profession_data()
	
	var data = _load_json_file(RESOURCES_PATH + "professions/" + file_name)
	if data.is_empty():
		return _get_default_profession_data()
	return data

## 加载卡牌配置
static func load_cards(card_type: String) -> Array:
	var file_name: String
	match card_type:
		"work":
			file_name = "work_cards.json"
		"trap":
			file_name = "trap_cards.json"
		"alliance":
			file_name = "alliance_cards.json"
		"special":
			file_name = "special_cards.json"
		_:
			return []
	
	var data = _load_json_file(RESOURCES_PATH + "cards/" + file_name)
	if data.is_empty():
		return []
	return data.get("cards", [])

## 加载所有卡牌
static func load_all_cards() -> Dictionary:
	var all_cards: Dictionary = {}
	var types = ["work", "trap", "alliance", "special"]
	
	for type in types:
		all_cards[type] = load_cards(type)
	
	return all_cards

## 加载海克斯配置
static func load_hexes(rarity: String) -> Array:
	var file_name: String
	match rarity:
		"common":
			file_name = "hex_common.json"
		"rare":
			file_name = "hex_rare.json"
		"epic":
			file_name = "hex_epic.json"
		"legendary":
			file_name = "hex_legendary.json"
		_:
			return []
	
	var data = _load_json_file(RESOURCES_PATH + "hex/" + file_name)
	if data.is_empty():
		return []
	return data.get("hexes", [])

## 加载所有海克斯
static func load_all_hexes() -> Dictionary:
	var all_hexes: Dictionary = {}
	var rarities = ["common", "rare", "epic", "legendary"]
	
	for rarity in rarities:
		all_hexes[rarity] = load_hexes(rarity)
	
	return all_hexes

## 加载本地化文本
static func load_localization(lang: String = "zh_CN") -> Dictionary:
	var data = _load_json_file(RESOURCES_PATH + "localization/" + lang + ".json")
	if data.is_empty():
		return _get_default_localization()
	return data

## 加载随机事件配置
static func load_random_events() -> Array:
	var data = _load_json_file(RESOURCES_PATH + "events/random_events.json")
	if data.is_empty():
		return []
	return data.get("events", [])

## 通用JSON文件加载
static func _load_json_file(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		push_warning("Config file not found: " + file_path)
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Failed to open config file: " + file_path)
		return {}
	
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(content)
	if error != OK:
		push_error("Failed to parse JSON: " + file_path + " - " + json.get_error_message())
		return {}
	
	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Config file must contain a JSON object: " + file_path)
		return {}
	
	return data

## 默认职业配置（当JSON加载失败时使用）
static func _get_default_profession_data() -> Dictionary:
	return {
		"name": "默认职业",
		"description": "基础职业配置",
		"base_hp": 100,
		"base_kpi": 10,
		"special_skills": []
	}

## 默认本地化配置
static func _get_default_localization() -> Dictionary:
	return {
		"game_title": "职场大逃杀",
		"menu_start": "开始游戏",
		"menu_load": "继续游戏",
		"menu_settings": "设置",
		"menu_quit": "退出"
	}

## 获取卡牌配置（通过ID）
static func get_card_by_id(card_id: String) -> Dictionary:
	var all_cards = load_all_cards()
	for type in all_cards:
		for card in all_cards[type]:
			if card.get("id") == card_id:
				return card
	return {}

## 获取海克斯配置（通过ID）
static func get_hex_by_id(hex_id: String) -> Dictionary:
	var all_hexes = load_all_hexes()
	for rarity in all_hexes:
		for hex in all_hexes[rarity]:
			if hex.get("id") == hex_id:
				return hex
	return {}
