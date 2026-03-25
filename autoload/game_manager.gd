extends Node
## GameManager - 游戏状态管理
## 管理游戏整体状态、场景切换和游戏流程

var current_state: int = Config.GameState.MENU
var previous_state: int = Config.GameState.MENU
var current_scene: Node = null

# 游戏配置
enum GameScale {
	DEBUG,      # 调试模式：5人（1+4AI）
	QUICK,      # 快速模式：20人
	STANDARD,   # 标准模式：50人
	EPIC        # 史诗模式：100人
}

var game_scale: int = GameScale.QUICK
var total_players: int = 20  # 总玩家数（含玩家自己），根据game_scale自动设置
var game_seed: int = 0
var is_multiplayer: bool = false

# 各规模配置
const SCALE_CONFIG: Dictionary = {
	GameScale.DEBUG: {
		"total_players": 5,        # 1人 + 4 AI
		"elimination_rate": 0.25,  # 每季度淘汰1人
		"estimated_minutes": 5,
		"is_debug": true
	},
	GameScale.QUICK: {
		"total_players": 20,
		"elimination_rate": 0.20,  # 每季度淘汰20%
		"estimated_minutes": 20,
		"is_debug": false
	},
	GameScale.STANDARD: {
		"total_players": 50,
		"elimination_rate": 0.25,  # 每季度淘汰25%
		"estimated_minutes": 40,
		"is_debug": false
	},
	GameScale.EPIC: {
		"total_players": 100,
		"elimination_rate": 0.30,  # 每季度淘汰30%
		"estimated_minutes": 90,
		"is_debug": false
	}
}

# 游戏运行时数据
var current_turn: int = 0
var current_month: int = 1
var current_quarter: int = 1
var current_year: int = 1

func _ready():
	print("GameManager initialized")
	_randomize_seed()
	
	# 监听关键事件
	EventBus.game_started.connect(_on_game_started)
	EventBus.game_ended.connect(_on_game_ended)
	EventBus.turn_ended.connect(_on_turn_ended)

## 随机化种子
func _randomize_seed():
	game_seed = randi()
	seed(game_seed)

## 设置游戏规模
func set_game_scale(scale: int) -> void:
	game_scale = scale
	var config = SCALE_CONFIG.get(scale, SCALE_CONFIG[GameScale.QUICK])
	total_players = config.total_players
	print("Game scale set: ", get_scale_name(), " (", total_players, " players)")

## 获取当前规模名称
func get_scale_name() -> String:
	match game_scale:
		GameScale.DEBUG:
			return "调试用"
		GameScale.QUICK:
			return "快速模式"
		GameScale.STANDARD:
			return "标准模式"
		GameScale.EPIC:
			return "史诗模式"
		_:
			return "快速模式"

## 检查是否调试模式
func is_debug_mode() -> bool:
	var config = SCALE_CONFIG.get(game_scale, SCALE_CONFIG[GameScale.QUICK])
	return config.get("is_debug", false)

## 获取缩圈淘汰比例
func get_elimination_rate() -> float:
	var config = SCALE_CONFIG.get(game_scale, SCALE_CONFIG[GameScale.QUICK])
	return config.elimination_rate

## 设置游戏状态
func set_state(new_state: int) -> void:
	if current_state == new_state:
		return
		
	previous_state = current_state
	current_state = new_state
	
	match new_state:
		Config.GameState.MENU:
			print("Game State: MENU")
		Config.GameState.CHARACTER_SELECT:
			print("Game State: CHARACTER_SELECT")
		Config.GameState.PLAYING:
			print("Game State: PLAYING")
		Config.GameState.PAUSED:
			print("Game State: PAUSED")
			EventBus.game_paused.emit()
		Config.GameState.GAME_OVER:
			print("Game State: GAME_OVER")
		Config.GameState.VICTORY:
			print("Game State: VICTORY")

## 暂停游戏
func pause_game() -> void:
	if current_state == Config.GameState.PLAYING:
		set_state(Config.GameState.PAUSED)
		get_tree().paused = true

## 恢复游戏
func resume_game() -> void:
	if current_state == Config.GameState.PAUSED:
		set_state(previous_state)
		get_tree().paused = false
		EventBus.game_resumed.emit()

## 开始新游戏
func start_game() -> void:
	_randomize_seed()
	current_turn = 0
	current_month = 1
	current_quarter = 1
	current_year = 1
	set_state(Config.GameState.PLAYING)
	EventBus.game_started.emit()
	_load_game_scene()

## 返回主菜单
func return_to_menu() -> void:
	get_tree().paused = false
	set_state(Config.GameState.MENU)
	_load_menu_scene()

## 结束游戏
func end_game(victory_condition: int) -> void:
	set_state(Config.GameState.VICTORY)
	EventBus.game_ended.emit(victory_condition)

## 加载游戏场景
func _load_game_scene() -> void:
	var result = get_tree().change_scene_to_file("res://scenes/game/game_main.tscn")
	if result != OK:
		push_error("Failed to load game scene")

## 加载菜单场景
func _load_menu_scene() -> void:
	var result = get_tree().change_scene_to_file("res://menu.tscn")
	if result != OK:
		push_error("Failed to load menu scene")

## 事件回调
func _on_game_started() -> void:
	print("Game started! Seed: ", game_seed)

func _on_game_ended(condition: int) -> void:
	print("Game ended! Victory condition: ", condition)

func _on_turn_ended(turn: int) -> void:
	current_turn = turn
	_advance_time()

## 时间推进
func _advance_time() -> void:
	current_month += 1
	if current_month > Config.MONTHS_PER_QUARTER:
		current_month = 1
		current_quarter += 1
		EventBus.quarter_ended.emit(current_quarter - 1)
		
		if current_quarter > Config.QUARTERS_PER_YEAR:
			current_quarter = 1
			current_year += 1
			EventBus.year_ended.emit(current_year - 1)
	else:
		EventBus.month_ended.emit(current_month - 1)

## 获取游戏时间描述
func get_time_description() -> String:
	return "第%d年 第%d季度 第%d月" % [current_year, current_quarter, current_month]

## 是否处于季度结算
func is_quarter_end() -> bool:
	return current_month == Config.MONTHS_PER_QUARTER
