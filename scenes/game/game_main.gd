extends Node2D
## GameMain - 游戏主场景
## 游戏主逻辑的运行场景

# 游戏组件
var turn_manager: TurnManager
var players: Array[Player] = []
var ai_controllers: Dictionary = {}

# 玩家行动信号同步
signal _player_action_done
var _player_action_mutex: bool = false

# UI 引用
@onready var ui_layer: CanvasLayer = $UILayer
@onready var player_info: Control = $UILayer/PlayerInfoPanel
@onready var action_panel: ActionPanel = $UILayer/ActionPanel
@onready var card_hand: CardHand = $UILayer/ActionPanel/MainVBox/CardSection/CardHand
@onready var hex_display: HexDisplay = $UILayer/HexDisplay
@onready var message_log: MessageLog = $UILayer/MessageLog
@onready var time_label: Label = $UILayer/TimeLabel
@onready var action_label: Label = $UILayer/ActionLabel

# 动态创建的UI
var player_list_panel = null
var shop_panel = null


func _ready():
	print("GameMain loaded")
	_setup_dynamic_ui()
	_initialize_game()
	_connect_signals()
	_update_ui()
	AudioManager.play_bgm("game_main")
	message_log.log_important("游戏开始！欢迎来到《职场大逃杀》")
	message_log.log_system("你的目标：在HC紧缩中生存下来，成为最后的赢家！")
	if turn_manager:
		turn_manager.start_game(players)


func _setup_dynamic_ui() -> void:
	# 创建玩家列表面板
	player_list_panel = load("res://scenes/components/player_list_panel.gd").new()
	player_list_panel.name = "PlayerListPanel"
	player_list_panel.custom_minimum_size = Vector2(280, 250)
	$UILayer.add_child(player_list_panel)
	player_list_panel.position = Vector2(20, 440)
	player_list_panel.size = Vector2(280, 250)

	# 创建商店面板
	shop_panel = load("res://scenes/components/shop_panel.gd").new()
	shop_panel.name = "ShopPanel"
	shop_panel.anchors_preset = Control.PRESET_CENTER
	shop_panel.position = Vector2(660, 340)
	shop_panel.size = Vector2(600, 400)
	$UILayer.add_child(shop_panel)
	shop_panel.hide()


func _initialize_game() -> void:
	turn_manager = TurnManager.new()
	turn_manager.name = "TurnManager"
	add_child(turn_manager)
	turn_manager.turn_started.connect(_on_turn_manager_turn_started)
	turn_manager.quarter_settled.connect(_on_quarter_settled)
	_create_players()


func _create_players() -> void:
	players.clear()
	var human = Player.new(0, PlayerData.player_name, PlayerData.profession, PlayerData.rank, false)
	players.append(human)
	var professions = Profession.get_all_professions()
	var rank_distribution = LevelSystem.generate_rank_distribution(GameManager.total_players)
	for i in range(1, GameManager.total_players):
		var ai_profession = professions[randi() % professions.size()]
		var ai_rank = rank_distribution[i] if i < rank_distribution.size() else Config.Rank.P3
		var ai_type = randi() % 6
		var ai_player = Player.new(i, _get_ai_name(i, ai_type), ai_profession, ai_rank, true)
		ai_player.ai_type = ai_type
		players.append(ai_player)
		var ai_controller = AIController.new(ai_player)
		ai_controller.name = "AIController_" + str(i)
		add_child(ai_controller)
		ai_controllers[i] = ai_controller
	for controller in ai_controllers.values():
		controller.set_all_players(players)
		if turn_manager.shop_manager:
			controller.set_shop_manager(turn_manager.shop_manager)
	player_list_panel.set_players(players)
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
	EventBus.player_salary_changed.connect(_on_player_salary_changed)
	EventBus.player_eliminated.connect(_on_player_eliminated)
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.phase_changed.connect(_on_phase_changed)
	EventBus.shop_entered.connect(_on_shop_entered)
	action_panel.action_confirmed.connect(_on_player_action_confirmed)
	shop_panel.shop_closed.connect(_on_shop_closed)


func _update_ui() -> void:
	var human = _get_human_player()
	if human:
		_sync_player_data_from_human()
	player_info.update_player(human if human else PlayerData)
	time_label.text = GameManager.get_time_description()
	card_hand.set_hand(human.hand_cards if human else PlayerData.hand_cards)
	hex_display.set_hexes(human.hexes if human else PlayerData.hexes)


func _on_turn_manager_turn_started(turn: int, month: int, quarter: int) -> void:
	message_log.log_important("第%d回合开始 - %s" % [turn, GameManager.get_time_description()])
	player_list_panel.set_players(players)
	if turn % 3 == 0:
		_sync_player_data_from_human()
		if SaveManager.save_game("auto"):
			print("Auto saved at turn ", turn)


func _on_quarter_settled(quarter: int, eliminated: Array) -> void:
	message_log.log_important("第%d季度结算 - 淘汰了%d人" % [quarter, eliminated.size()])
	player_list_panel.set_players(players)


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

	if phase == Config.TurnPhase.ACTION:
		var human = _get_human_player()
		if human and human.is_alive:
			action_panel.start_action_phase(human, players)


func _on_player_hp_changed(player_id: int, current: int, max_hp: int) -> void:
	if player_id == 0:
		_sync_player_data_from_human()
		player_info.update_player(_get_human_player())


func _on_player_kpi_changed(player_id: int, kpi: int) -> void:
	if player_id == 0:
		_sync_player_data_from_human()
		player_info.update_player(_get_human_player())


func _on_player_salary_changed(player_id: int, salary: int) -> void:
	if player_id == 0:
		_sync_player_data_from_human()
		player_info.update_player(_get_human_player())


func _on_player_eliminated(player_id: int, reason: String) -> void:
	if player_id == 0:
		_sync_player_data_from_human()
		_show_game_over(false)


func _on_player_action_confirmed() -> void:
	_player_action_done.emit()
	EventBus.shop_completed.emit()


func _on_shop_entered(player_id: int) -> void:
	if player_id != 0:
		return
	var human = _get_human_player()
	if human and turn_manager.shop_manager:
		shop_panel.open_shop(human, turn_manager.shop_manager)


func _on_shop_closed() -> void:
	EventBus.shop_completed.emit()


func _show_game_over(victory: bool) -> void:
	var result = 0 if victory else 1
	GameManager.set_meta("game_result", result)
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/game_over/game_over_screen.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()
	if event.is_action_pressed("debug_save"):
		_quick_save()
	if event.is_action_pressed("debug_load"):
		_quick_load()
	if GameManager.is_debug_mode():
		if event.is_action_pressed("debug_show_all_status"):
			_debug_show_all_status()
		elif event.is_action_pressed("debug_force_next_turn"):
			_debug_force_next_turn()
		elif event.is_action_pressed("debug_add_hp"):
			var human = _get_human_player()
			if human:
				human.modify_hp(50)
		elif event.is_action_pressed("debug_add_money"):
			var human = _get_human_player()
			if human:
				human.total_salary += 1000
				_sync_player_data_from_human()
				player_info.update_player(human)


func _quick_save() -> void:
	_sync_player_data_from_human()
	if SaveManager.save_game("quicksave"):
		message_log.log_success("游戏已快速保存 (F5)")
	else:
		message_log.log_error("快速保存失败！")


func _quick_load() -> void:
	if SaveManager.has_save("quicksave"):
		if SaveManager.load_game("quicksave"):
			message_log.log_success("游戏已快速读取 (F9)")
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


func _get_human_player() -> Player:
	if players.is_empty():
		return null
	return players[0]


func _sync_player_data_from_human() -> void:
	var human = _get_human_player()
	if human:
		PlayerData.sync_from_player(human)
