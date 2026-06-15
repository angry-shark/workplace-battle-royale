extends Node
## PlayerData - 玩家数据管理
## 管理当前游戏会话的玩家数据

# 玩家基础属性
var player_id: int = 0
var player_name: String = "打工人"
var profession: int = Config.Profession.PROGRAMMER
var rank: int = Config.Rank.P1

# 双资源系统
var current_hp: int = Config.INITIAL_HP
var max_hp: int = Config.INITIAL_HP
var current_kpi: int = 0
var total_salary: int = 0  # 累计薪资（永久）
var current_salary: int = 0  # 当前薪资（月度）

# 游戏状态
var is_alive: bool = true
var is_ai: bool = false
var elimination_reason: String = ""

# 拥有的Hex
var hexes: Array[String] = []

# 手牌
var hand_cards: Array[String] = []
var max_hand_size: int = 10

# 盟友
var allies: Array[int] = []  # 盟友玩家ID列表

# 统计数据
var stats: Dictionary = {
	"games_played": 0,
	"games_won": 0,
	"total_eliminations": 0,
	"traps_triggered": 0,
	"alliances_formed": 0,
	"betrayals_committed": 0,
	"highest_rank_reached": Config.Rank.P1,
	"highest_salary_earned": 0,
	"longest_survival_turns": 0
}

# 当前游戏统计
var current_game_stats: Dictionary = {
	"turns_survived": 0,
	"kpi_earned": 0,
	"salary_earned": 0,
	"cards_played": 0,
	"traps_placed": 0,
	"traps_triggered": 0,
	"damage_dealt": 0,
	"damage_taken": 0
}

func _ready():
	print("PlayerData initialized")
	_reset_current_game_data()

## 重置当前游戏数据
func _reset_current_game_data() -> void:
	current_hp = Config.INITIAL_HP
	max_hp = Config.INITIAL_HP
	current_kpi = 0
	current_salary = 0
	is_alive = true
	elimination_reason = ""
	hexes.clear()
	hand_cards.clear()
	allies.clear()
	current_game_stats = {
		"turns_survived": 0,
		"kpi_earned": 0,
		"salary_earned": 0,
		"cards_played": 0,
		"traps_placed": 0,
		"traps_triggered": 0,
		"damage_dealt": 0,
		"damage_taken": 0
	}

## 初始化新玩家
func initialize_new_game(p_name: String, p_profession: int, p_rank: int = Config.Rank.P1) -> void:
	player_name = p_name
	profession = p_profession
	rank = p_rank
	_reset_current_game_data()
	
	# 设置初始薪资
	current_salary = Config.INITIAL_SALARY.get(p_rank, 5000)
	max_hand_size = Config.STRATEGY_CARDS.get(p_rank, 3)
	
	stats["games_played"] += 1
	print("Player initialized: %s, Profession: %d, Rank: %d" % [p_name, p_profession, p_rank])

## 从运行时Player同步当前游戏数据
func sync_from_player(player: Player) -> void:
	player_id = player.player_id
	player_name = player.player_name
	profession = player.profession
	rank = player.rank
	current_hp = player.current_hp
	max_hp = player.max_hp
	current_kpi = player.current_kpi
	current_salary = player.current_salary
	total_salary = player.total_salary
	is_alive = player.is_alive
	is_ai = player.is_ai
	elimination_reason = player.elimination_reason
	
	hexes.assign(player.hexes)
	hand_cards.assign(player.hand_cards)
	allies.assign(player.allies)
	current_game_stats = player.game_stats.duplicate(true)

## 修改HP
func modify_hp(amount: int) -> void:
	var old_hp = current_hp
	current_hp = clamp(current_hp + amount, 0, max_hp)
	
	if amount < 0:
		current_game_stats["damage_taken"] += abs(amount)
	
	EventBus.player_hp_changed.emit(player_id, current_hp, max_hp)
	
	if current_hp <= 0 and is_alive:
		die("HP归零")

## 修改KPI
func modify_kpi(amount: int) -> void:
	current_kpi = max(0, current_kpi + amount)
	if amount > 0:
		current_game_stats["kpi_earned"] += amount
	EventBus.player_kpi_changed.emit(player_id, current_kpi)

## 修改薪资
func modify_salary(amount: int) -> void:
	current_salary += amount
	current_game_stats["salary_earned"] += amount
	EventBus.player_salary_changed.emit(player_id, current_salary)

## 结算薪资到总资产
func settle_salary() -> void:
	total_salary += current_salary
	if total_salary > stats["highest_salary_earned"]:
		stats["highest_salary_earned"] = total_salary

## 晋升
func promote() -> void:
	if rank < Config.Rank.P12:
		rank += 1
		current_salary = Config.INITIAL_SALARY.get(rank, current_salary)
		max_hand_size = Config.STRATEGY_CARDS.get(rank, max_hand_size)
		
		if rank > stats["highest_rank_reached"]:
			stats["highest_rank_reached"] = rank
		
		EventBus.player_promoted.emit(player_id, rank)
		print("Player promoted to P", rank)

## 添加Hex
func add_hex(hex_id: String, rarity: int) -> void:
	hexes.append(hex_id)
	EventBus.hex_acquired.emit(player_id, hex_id, rarity)

## 添加卡牌到手牌
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

## 移除盟友
func remove_ally(ally_id: int) -> void:
	if allies.has(ally_id):
		allies.erase(ally_id)

## 检查是否是盟友
func is_allied_with(other_id: int) -> bool:
	return allies.has(other_id)

## 死亡/淘汰
func die(reason: String) -> void:
	is_alive = false
	elimination_reason = reason
	stats["games_played"] -= 1  # 不计入完成的游戏
	EventBus.player_eliminated.emit(player_id, reason)
	print("Player eliminated: ", reason)

## 胜利
func victory(victory_condition: int) -> void:
	stats["games_won"] += 1
	EventBus.game_ended.emit(victory_condition)
	print("Player victory! Condition: ", victory_condition)

## 获取玩家等级名称
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
