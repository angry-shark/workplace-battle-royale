extends Node
## HexManager - 海克斯管理器
## 管理海克斯的获取、激活、效果结算

# 信号
signal hex_acquired(player_id: int, hex: HexData, rarity: String)
signal hex_activated(player_id: int, hex: HexData)
signal hex_expired(player_id: int, hex: HexData)
signal hex_selection_started(options: Array[HexData])

# 海克斯数据类
class HexData:
	var id: String
	var name: String
	var rarity: String  # common/rare/epic/legendary
	var type: String    # survival/performance/strategy/economy
	var duration: String # quarter/permanent
	var description: String
	var effects: Dictionary
	var profession_limit: int  # -1表示无限制
	var rank_limit: int        # 0表示无限制
	
	func _init(p_id: String, p_name: String, p_rarity: String, p_type: String):
		id = p_id
		name = p_name
		rarity = p_rarity
		type = p_type
		description = ""
		effects = {}
		profession_limit = -1
		rank_limit = 0

# 海克斯池
var _hex_pools: Dictionary = {
	"common": [],
	"rare": [],
	"epic": [],
	"legendary": []
}

# 当前季度玩家拥有的海克斯
var _player_hexes: Dictionary = {}  # player_id -> Array[HexData]

# 永久海克斯（跨季度保留）
var _permanent_hexes: Dictionary = {}  # player_id -> Array[HexData]

func _ready():
	_load_all_hexes()

## 加载所有海克斯配置
func _load_all_hexes() -> void:
	var config = ConfigLoader.load_all_hexes()
	
	for rarity in ["common", "rare", "epic", "legendary"]:
		for hex_json in config.get(rarity, []):
			_hex_pools[rarity].append(_create_hex_from_json(hex_json, rarity))
	
	print("Hexes loaded: Common=", _hex_pools["common"].size(),
		", Rare=", _hex_pools["rare"].size(),
		", Epic=", _hex_pools["epic"].size(),
		", Legendary=", _hex_pools["legendary"].size())

## 从JSON创建海克斯
func _create_hex_from_json(json: Dictionary, rarity: String) -> HexData:
	var hex = HexData.new(
		json.get("id", ""),
		json.get("name", "未知海克斯"),
		rarity,
		json.get("type", "survival")
	)
	hex.duration = json.get("duration", "quarter")
	hex.description = json.get("description", "")
	hex.effects = json.get("effects", {})
	hex.profession_limit = json.get("profession_limit", -1)
	hex.rank_limit = json.get("rank_limit", 0)
	return hex

## 季度开始 - 抽取海克斯选择
func start_hex_selection(player: Player) -> Array[HexData]:
	var options: Array[HexData] = []
	var rarity_weights = _get_rarity_weights()
	
	# 提供3个选项
	for i in range(3):
		var rarity = _roll_rarity(rarity_weights)
		var available = _get_available_hexes(player, rarity)
		
		if not available.is_empty():
			var hex = available[randi() % available.size()]
			options.append(hex)
	
	hex_selection_started.emit(options)
	return options

## 获取稀有度权重
func _get_rarity_weights() -> Dictionary:
	return {
		"common": 60,
		"rare": 30,
		"epic": 9,
		"legendary": 1
	}

## 随机抽取稀有度
func _roll_rarity(weights: Dictionary) -> String:
	var total = 0
	for weight in weights.values():
		total += weight
	
	var roll = randi() % total
	var current = 0
	
	for rarity in weights:
		current += weights[rarity]
		if roll < current:
			return rarity
	
	return "common"

## 获取可用的海克斯（排除已拥有和不符合条件的）
func _get_available_hexes(player: Player, rarity: String) -> Array[HexData]:
	var available: Array[HexData] = []
	var owned_ids = _get_player_hex_ids(player.player_id)
	
	for hex in _hex_pools[rarity]:
		# 检查是否已拥有
		if hex.id in owned_ids:
			continue
		
		# 检查职业限制
		if hex.profession_limit >= 0 and hex.profession_limit != player.profession:
			continue
		
		# 检查职级限制
		if hex.rank_limit > 0 and player.rank < hex.rank_limit:
			continue
		
		available.append(hex)
	
	return available

## 获取玩家已拥有的海克斯ID列表
func _get_player_hex_ids(player_id: int) -> Array[String]:
	var ids: Array[String] = []
	
	# 季度海克斯
	if _player_hexes.has(player_id):
		for hex in _player_hexes[player_id]:
			ids.append(hex.id)
	
	# 永久海克斯
	if _permanent_hexes.has(player_id):
		for hex in _permanent_hexes[player_id]:
			ids.append(hex.id)
	
	return ids

## 玩家选择海克斯
func select_hex(player: Player, hex: HexData) -> void:
	if hex.duration == "permanent":
		# 永久海克斯
		if not _permanent_hexes.has(player.player_id):
			_permanent_hexes[player.player_id] = []
		_permanent_hexes[player.player_id].append(hex)
		
		# 永久海克斯立即生效
		_apply_permanent_hex(player, hex)
	else:
		# 季度海克斯
		if not _player_hexes.has(player.player_id):
			_player_hexes[player.player_id] = []
		_player_hexes[player.player_id].append(hex)
	
	hex_acquired.emit(player.player_id, hex, hex.rarity)
	player.add_hex(hex.id, _rarity_to_int(hex.rarity))
	
	print("Player ", player.player_name, " acquired hex: ", hex.name, " (", hex.rarity, ")")

## 稀有度转整数
func _rarity_to_int(rarity: String) -> int:
	match rarity:
		"common":
			return Config.HexRarity.COMMON
		"rare":
			return Config.HexRarity.RARE
		"epic":
			return Config.HexRarity.EPIC
		"legendary":
			return Config.HexRarity.LEGENDARY
		_:
			return Config.HexRarity.COMMON

## 季度结束 - 清理非永久海克斯
func on_quarter_end() -> void:
	for player_id in _player_hexes:
		for hex in _player_hexes[player_id]:
			hex_expired.emit(player_id, hex)
	
	_player_hexes.clear()
	print("Quarter hexes cleared")

## 计算海克斯效果（月度结算时调用）
func calculate_hex_effects(player: Player) -> Dictionary:
	var effects = {
		"hp_cost_reduction": 0,
		"hp_recovery_bonus": 0,
		"kpi_bonus": 0.0,
		"salary_bonus": 0.0,
		"shop_discount": 0.0,
		"trap_success_bonus": 0.0,
		"info_reveal": 0,
		"expose_immunity": 0.0
	}
	
	# 合并季度海克斯和永久海克斯
	var all_hexes: Array[HexData] = []
	
	if _player_hexes.has(player.player_id):
		all_hexes.append_array(_player_hexes[player.player_id])
	
	if _permanent_hexes.has(player.player_id):
		all_hexes.append_array(_permanent_hexes[player.player_id])
	
	# 累加所有效果
	for hex in all_hexes:
		var hex_effects = hex.effects
		
		for key in hex_effects:
			if effects.has(key):
				if typeof(effects[key]) == TYPE_FLOAT:
					effects[key] += float(hex_effects[key])
				elif typeof(effects[key]) == TYPE_INT:
					effects[key] += int(hex_effects[key])
	
	return effects

## 应用永久海克斯效果
func _apply_permanent_hex(player: Player, hex: HexData) -> void:
	match hex.id:
		"hex_wealth_freedom":
			# 财富自由：工资永久+50%
			pass  # 效果在calculate_hex_effects中计算
		"hex_bald_warning":
			# 秃头警告：HP上限-20，绩效+15%
			player.max_hp -= 20
			player.current_hp = min(player.current_hp, player.max_hp)

## 获取玩家海克斯列表
func get_player_hexes(player_id: int) -> Array[HexData]:
	var result: Array[HexData] = []
	
	if _player_hexes.has(player_id):
		result.append_array(_player_hexes[player_id])
	
	if _permanent_hexes.has(player_id):
		result.append_array(_permanent_hexes[player_id])
	
	return result

## 检查玩家是否拥有特定海克斯
func has_hex(player_id: int, hex_id: String) -> bool:
	var hexes = get_player_hexes(player_id)
	for hex in hexes:
		if hex.id == hex_id:
			return true
	return false

## 获取海克斯信息
func get_hex_info(hex_id: String) -> Dictionary:
	for rarity in _hex_pools:
		for hex in _hex_pools[rarity]:
			if hex.id == hex_id:
				return {
					"id": hex.id,
					"name": hex.name,
					"rarity": hex.rarity,
					"type": hex.type,
					"duration": hex.duration,
					"description": hex.description,
					"effects": hex.effects
				}
	return ConfigLoader.get_hex_by_id(hex_id)

## 获取稀有度颜色
static func get_rarity_color(rarity: String) -> Color:
	return GameTheme.get_rarity_color(rarity)

## 获取类型名称
static func get_type_name(type: String) -> String:
	match type:
		"survival":
			return "生存"
		"performance":
			return "绩效"
		"strategy":
			return "策略"
		"economy":
			return "经济"
		_:
			return "未知"
