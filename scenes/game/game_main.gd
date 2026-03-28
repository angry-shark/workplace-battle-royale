extends Node2D
## GameMain - 游戏主场景
## 游戏主逻辑的运行场景

# 游戏组件
var turn_manager: TurnManager
var players: Array[Player] = []
var ai_controllers: Dictionary = {}  # player_id -> AIController

# UI 引用
@onready var ui_layer: CanvasLayer = $UILayer
@onready var player_info: Control = $UILayer/PlayerInfoPanel
@onready var card_hand: CardHand = $UILayer/ActionPanel/CardHand
@onready var hex_display: HexDisplay = $UILayer/HexDisplay
@onready var message_log: MessageLog = $UILayer/MessageLog
@onready var time_label: Label = $UILayer/TimeLabel
@onready var action_label: Label = $UILayer/ActionLabel

func _ready():
	print("GameMain loaded")
	
	# 初始化游戏
	_initialize_game()
	
	# 连接事件
	_connect_signals()
	
	# 更新UI
	_update_ui()
	
	# 播放BGM
	AudioManager.play_bgm("game_main")
	
	# 显示欢迎消息
	message_log.log_important("游戏开始！欢迎来到《职场大逃杀》")
	message_log.log_system("你的目标：在HC紧缩中生存下来，成为最后的赢家！")
	
	# 启动回合管理器
	if turn_manager:
		turn_manager.start_game(players)

func _initialize_game() -> void:
	# 创建回合管理器
	turn_manager = TurnManager.new()
	turn_manager.name = "TurnManager"
	add_child(turn_manager)
	
	# 连接回合管理器信号
	turn_manager.turn_started.connect(_on_turn_manager_turn_started)
	turn_manager.quarter_settled.connect(_on_quarter_settled)
	
	# 创建玩家列表
	_create_players()

func _create_players() -> void:
	players.clear()
	
	# 创建人类玩家 (ID: 0)
	var human = Player.new(
		0,
		PlayerData.player_name,
		PlayerData.profession,
		PlayerData.rank,
		false
	)
	players.append(human)
	
	# 创建AI玩家
	var professions = Profession.get_all_professions()
	var rank_distribution = LevelSystem.generate_rank_distribution(GameManager.total_players)
	
	for i in range(1, GameManager.total_players):
		var ai_profession = professions[randi() % professions.size()]
		var ai_rank = rank_distribution[i] if i < rank_distribution.size() else Config.Rank.P3
		var ai_type = randi() % 6  # 随机AI类型
		
		var ai_player = Player.new(
			i,
			_get_ai_name(i, ai_type),
			ai_profession,
			ai_rank,
			true
		)
		ai_player.ai_type = ai_type
		players.append(ai_player)
		
		# 创建AI控制器
		var ai_controller = AIController.new(ai_player)
		ai_controller.name = "AIController_" + str(i)
		add_child(ai_controller)
		ai_controllers[i] = ai_controller
	
	# 为所有AI控制器设置玩家列表引用
	for controller in ai_controllers.values():
		controller.set_all_players(players)
	
	print("Created ", players.size(), " players")

func _get_ai_name(index: int, ai_type: int) -> String:
	var type_names = {
		AIController.AIType.GRINDER: "卷王",
		AIController.AIType.WELLNESS: "养生",
		AIController.AIType.DECEIVER: "老六",
		AIController.AIType.SOCIAL: "社交",
		AIController.AIType.PROMOTION: "晋升狂",
		AIController.AIType.LURKER: "潜伏"
	}
	var type_name = type_names.get(ai_type, "AI")
	return "%s%d号" % [type_name, index]

func _connect_signals() -> void:
	EventBus.player_hp_changed.connect(_on_player_hp_changed)
	EventBus.player_kpi_changed.connect(_on_player_kpi_changed)
	EventBus.player_eliminated.connect(_on_player_eliminated)
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.phase_changed.connect(_on_phase_changed)
	
	# 手牌信号
	card_hand.card_selected.connect(_on_card_selected)

func _update_ui() -> void:
	# 更新玩家信息面板
	player_info.update_player()
	
	# 更新时间显示
	time_label.text = GameManager.get_time_description()
	
	# 更新手牌
	card_hand.set_hand(PlayerData.hand_cards)
	
	# 更新海克斯
	hex_display.set_hexes(PlayerData.hexes)

func _on_turn_manager_turn_started(turn: int, month: int, quarter: int) -> void:
	message_log.log_important("第%d回合开始 - %s" % [turn, GameManager.get_time_description()])
	
	# 自动存档（每3回合）
	if turn % 3 == 0:
		if SaveManager.save_game("auto"):
			print("Auto saved at turn ", turn)

func _on_quarter_settled(quarter: int, eliminated: Array) -> void:
	message_log.log_important("第%d季度结算 - 淘汰了%d人" % [quarter, eliminated.size()])

func _on_turn_started(turn: int) -> void:
	time_label.text = GameManager.get_time_description()

func _on_phase_changed(phase: int) -> void:
	var phase_names = {
		Config.TurnPhase.HP_DEDUCTION: "健康度扣除",
		Config.TurnPhase.ACTION: "行动阶段",
		Config.TurnPhase.WORK_OUTPUT: "工作产出",
		Config.TurnPhase.SALARY: "薪资结算",
		Config.TurnPhase.SHOP: "商店阶段"
	}
	action_label.text = "当前阶段: " + phase_names.get(phase, "未知")

func _on_player_hp_changed(player_id: int, current: int, max_hp: int) -> void:
	if player_id == 0:
		player_info.update_player()

func _on_player_kpi_changed(player_id: int, kpi: int) -> void:
	if player_id == 0:
		player_info.update_player()

func _on_player_eliminated(player_id: int, reason: String) -> void:
	if player_id == 0:
		_show_game_over(false)

func _on_card_selected(card_id: String) -> void:
	print("Selected card: ", card_id)
	# TODO: 显示目标选择或直接使用

func _show_game_over(victory: bool) -> void:
	# 切换到游戏结束画面
	var result = 0 if victory else 1  # GameOverScreen.ResultType
	
	# 保存结果到GameManager供下个场景读取
	GameManager.set_meta("game_result", result)
	
	# 延迟后切换场景
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/game_over/game_over_screen.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()
	
	# F5快速保存
	if event.is_action_pressed("debug_save"):
		_quick_save()
	
	# F9快速读档
	if event.is_action_pressed("debug_load"):
		_quick_load()
	
	# 调试快捷键
	if GameManager.is_debug_mode():
		if event.is_action_pressed("debug_show_all_status"):
			_debug_show_all_status()
		elif event.is_action_pressed("debug_force_next_turn"):
			_debug_force_next_turn()
		elif event.is_action_pressed("debug_add_hp"):
			PlayerData.modify_hp(50)
		elif event.is_action_pressed("debug_add_money"):
			PlayerData.total_salary += 1000

func _quick_save() -> void:
	if SaveManager.save_game("quicksave"):
		message_log.log_success("游戏已快速保存 (F5)")
		AudioManager.play_success()
	else:
		message_log.log_error("快速保存失败！")

func _quick_load() -> void:
	if SaveManager.has_save("quicksave"):
		if SaveManager.load_game("quicksave"):
			message_log.log_success("游戏已快速读取 (F9)")
			AudioManager.play_success()
			# 刷新UI
			_update_ui()
		else:
			message_log.log_error("快速读档失败！")
	else:
		message_log.log_warning("没有快速存档！")

func _toggle_pause() -> void:
	if GameManager.current_state == Config.GameState.PLAYING:
		GameManager.pause_game()
		message_log.log_system("游戏已暂停 (ESC继续, F5快速保存)")
	elif GameManager.current_state == Config.GameState.PAUSED:
		GameManager.resume_game()
		message_log.log_system("游戏继续")

func _debug_show_all_status() -> void:
	message_log.log_system("=== 所有玩家状态 ===")
	for player in players:
		var status = "[%s] HP:%d/%d KPI:%d 工资:%d 职级:P%d %s" % [
			player.player_name,
			player.current_hp, player.max_hp,
			player.current_kpi,
			player.total_salary,
			player.rank,
			"[存活]" if player.is_alive else "[淘汰]"
		]
		message_log.log_message(status)

func _debug_force_next_turn() -> void:
	message_log.log_system("强制进入下一回合")
	if turn_manager:
		turn_manager._end_turn()
