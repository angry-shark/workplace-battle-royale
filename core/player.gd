class_name Player
extends Node
## Player - 玩家实体
## 代表游戏中的一个玩家（人类或AI）

# 基础属性
var player_id: int = 0
var player_name: String = "打工人"
var is_ai: bool = false
var ai_type: int = Config.AIType.GRINDER

# 职业和职级
var profession: int = Config.Profession.PROGRAMMER
var rank: int = Config.Rank.P1

# 双资源系统
var current_hp: int = 100
var max_hp: int = 100
var current_kpi: int = 0  # 当前季度KPI
var total_kpi: int = 0    # 累计KPI
var current_salary: int = 5000
var total_salary: int = 0

# 状态
var is_alive: bool = true
var elimination_reason: String = ""
var is_ready: bool = false  # 回合是否已操作

# Hex
var hexes: Array[String] = []

# 卡牌
var hand_cards: Array[String] = []
var max_hand_size: int = 3

# 联盟
var allies: Array[int] = []  # 盟友玩家ID列表

# 当前游戏统计
var game_stats: Dictionary = {
	"turns_survived": 0,
	"kpi_earned": 0,
	"salary_earned": 0,
	"cards_played": 0,
	"traps_placed": 0,
	"traps_triggered": 0,
	"damage_dealt": 0,
	"damage_taken": 0
}

func _init(p_id: int, p_name: String, p_profession: int, p_rank: int, ai: bool = false):
	player_id = p_id
	player_name = p_name
	profession = p_profession
	rank = p_rank
	is_ai = ai
	
	# 初始化属性
	max_hp = Profession.calculate_hp(profession, rank)
	current_hp = max_hp
	max_hand_size = LevelSystem.get_strategy_card_count(rank)
	current_salary = LevelSystem.get_salary(rank)
	
	print("Player created: ", player_name, " (", get_profession_name(), " P", rank, ")")

## 修改HP
func modify_hp(amount: int) -> void:
	var old_hp = current_hp
	current_hp = clamp(current_hp + amount, 0, max_hp)
	
	if amount < 0:
		game_stats["damage_taken"] += abs(amount)
	elif amount > 0:
		# 治疗
		pass
	
	EventBus.player_hp_changed.emit(player_id, current_hp, max_hp)
	
	if current_hp <= 0 and is_alive:
		die("HP归零")

## 修改KPI
func modify_kpi(amount: int) -> void:
	current_kpi = max(0, current_kpi + amount)
	if amount > 0:
		total_kpi += amount
		game_stats["kpi_earned"] += amount
	EventBus.player_kpi_changed.emit(player_id, current_kpi)

## 修改薪资
func modify_salary(amount: int) -> void:
	current_salary = max(0, current_salary + amount)
	if amount > 0:
		game_stats["salary_earned"] += amount
	EventBus.player_salary_changed.emit(player_id, current_salary)

## 结算薪资到总资产
func settle_salary() -> void:
	total_salary += current_salary
	game_stats["salary_earned"] += current_salary

## 晋升
func promote() -> void:
	if rank < Config.Rank.P12:
		rank += 1
		_update_rank_bonuses()
		EventBus.player_promoted.emit(player_id, rank)

## 更新职级加成
func _update_rank_bonuses() -> void:
	current_salary = LevelSystem.get_salary(rank)
	max_hand_size = LevelSystem.get_strategy_card_count(rank)

## 添加Hex
func add_hex(hex_id: String, rarity: int) -> void:
	hexes.append(hex_id)
	EventBus.hex_acquired.emit(player_id, hex_id, rarity)

## 添加卡牌
func add_card(card_id: String) -> bool:
	if hand_cards.size() >= max_hand_size:
		return false
	hand_cards.append(card_id)
	EventBus.card_drawn.emit(player_id, card_id)
	return true

## 移除卡牌
func remove_card(card_id: String) -> bool:
	if hand_cards.has(card_id):
		hand_cards.erase(card_id)
		return true
	return false

## 添加盟友
func add_ally(ally_id: int) -> void:
	if not allies.has(ally_id):
		allies.append(ally_id)
		EventBus.alliance_formed.emit(player_id, ally_id)

## 移除盟友
func remove_ally(ally_id: int) -> void:
	if allies.has(ally_id):
		allies.erase(ally_id)
		EventBus.alliance_broken.emit(player_id, ally_id)

## 检查是否是盟友
func is_allied_with(other_id: int) -> bool:
	return allies.has(other_id)

## 死亡/淘汰
func die(reason: String) -> void:
	is_alive = false
	elimination_reason = reason
	EventBus.player_eliminated.emit(player_id, reason)
	print(player_name, " eliminated: ", reason)

## 复活（某些特殊技能可能用到）
func revive() -> bool:
	if not is_alive:
		is_alive = true
		current_hp = max_hp / 2
		elimination_reason = ""
		return true
	return false

## 获取职级名称
func get_rank_name() -> String:
	return "P" + str(rank)

## 获取职业名称
func get_profession_name() -> String:
	match profession:
		Config.Profession.PROGRAMMER:
			return "程序员"
		Config.Profession.HR:
			return "HR"
		Config.Profession.FINANCE:
			return "财务"
		Config.Profession.OPERATIONS:
			return "运营"
		Config.Profession.SALES:
			return "销售"
		_:
			return "未知"

## 获取AI类型名称
func get_ai_type_name() -> String:
	match ai_type:
		Config.AIType.GRINDER:
			return "奋斗逼"
		Config.AIType.WELLNESS:
			return "养生党"
		Config.AIType.DECEIVER:
			return "老六"
		Config.AIType.SOCIAL:
			return "社交狂"
		Config.AIType.PROMOTION:
			return "晋升狂"
		Config.AIType.LURKER:
			return "老阴逼"
		_:
			return "普通"

## 获取HP百分比
func get_hp_percent() -> float:
	return float(current_hp) / float(max_hp)

## 获取晋升进度
func get_promotion_progress() -> float:
	return LevelSystem.get_promotion_progress(rank, current_kpi)

## 回合开始
func on_turn_start() -> void:
	is_ready = false
	# 重置回合相关状态

## 回合结束
func on_turn_end() -> void:
	game_stats["turns_survived"] += 1
	is_ready = true

## 序列化为字典（用于存档）
func to_dictionary() -> Dictionary:
	return {
		"id": player_id,
		"name": player_name,
		"is_ai": is_ai,
		"ai_type": ai_type,
		"profession": profession,
		"rank": rank,
		"hp": current_hp,
		"max_hp": max_hp,
		"kpi": current_kpi,
		"total_kpi": total_kpi,
		"salary": current_salary,
		"total_salary": total_salary,
		"is_alive": is_alive,
		"hexes": hexes,
		"hand_cards": hand_cards,
		"allies": allies,
		"stats": game_stats
	}

## 从字典反序列化
func from_dictionary(data: Dictionary) -> void:
	player_id = data.get("id", 0)
	player_name = data.get("name", "打工人")
	is_ai = data.get("is_ai", false)
	ai_type = data.get("ai_type", Config.AIType.GRINDER)
	profession = data.get("profession", Config.Profession.PROGRAMMER)
	rank = data.get("rank", Config.Rank.P1)
	current_hp = data.get("hp", 100)
	max_hp = data.get("max_hp", 100)
	current_kpi = data.get("kpi", 0)
	total_kpi = data.get("total_kpi", 0)
	current_salary = data.get("salary", 5000)
	total_salary = data.get("total_salary", 0)
	is_alive = data.get("is_alive", true)
	hexes = data.get("hexes", [])
	hand_cards = data.get("hand_cards", [])
	allies = data.get("allies", [])
	game_stats = data.get("stats", {})
