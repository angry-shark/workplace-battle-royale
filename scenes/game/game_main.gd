extends Node2D
## GameMain - 游戏主场景
## 游戏主逻辑的运行场景

# 游戏组件
var turn_manager: TurnManager
var players: Array = []

# UI 引用
@onready var ui_layer: CanvasLayer = $UILayer
@onready var time_label: Label = $UILayer/TimeLabel
@onready var player_info: Panel = $UILayer/PlayerInfo
@onready var action_panel: Panel = $UILayer/ActionPanel
@onready var message_log: RichTextLabel = $UILayer/MessageLog

func _ready():
	print("GameMain loaded")
	
	# 初始化游戏
	_initialize_game()
	
	# 连接事件
	EventBus.player_hp_changed.connect(_on_player_hp_changed)
	EventBus.player_kpi_changed.connect(_on_player_kpi_changed)
	EventBus.player_eliminated.connect(_on_player_eliminated)
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.ui_message.connect(_on_ui_message)
	
	# 更新UI
	_update_time_display()
	_update_player_info()
	
	# 开始游戏
	_log_message("游戏开始！欢迎来到《职场大逃杀》")
	_log_message("你的目标：在HC紧缩中生存下来，成为最后的赢家！")
	
	# 启动回合管理器
	if turn_manager:
		turn_manager.start_game(players)

func _initialize_game() -> void:
	# 创建回合管理器
	turn_manager = TurnManager.new()
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
	
	# 创建AI玩家 (ID: 1-19)
	var professions = Profession.get_all_professions()
	var rank_distribution = LevelSystem.generate_rank_distribution(GameManager.total_players)
	
	for i in range(1, GameManager.total_players):
		var ai_profession = professions[randi() % professions.size()]
		var ai_rank = rank_distribution[i] if i < rank_distribution.size() else Config.Rank.P3
		var ai_type = randi() % 6  # 随机AI类型
		
		var ai_player = Player.new(
			i,
			"同事%d" % i,
			ai_profession,
			ai_rank,
			true
		)
		ai_player.ai_type = ai_type
		players.append(ai_player)
	
	print("Created ", players.size(), " players")

func _update_time_display() -> void:
	if time_label:
		time_label.text = GameManager.get_time_description()

func _update_player_info() -> void:
	if not player_info:
		return
	
	# 更新玩家信息面板
	var hp_bar = player_info.get_node_or_null("HPBar")
	var kpi_label = player_info.get_node_or_null("KPILabel")
	var salary_label = player_info.get_node_or_null("SalaryLabel")
	var rank_label = player_info.get_node_or_null("RankLabel")
	
	if hp_bar:
		hp_bar.max_value = PlayerData.max_hp
		hp_bar.value = PlayerData.current_hp
	
	if kpi_label:
		kpi_label.text = "KPI: %d" % PlayerData.current_kpi
	
	if salary_label:
		salary_label.text = "薪资: %d" % PlayerData.current_salary
	
	if rank_label:
		rank_label.text = "职级: %s" % PlayerData.get_rank_name()

func _log_message(text: String) -> void:
	if message_log:
		message_log.append_text("[color=#888888]%s[/color] %s\n" % [GameManager.get_time_description(), text])
		message_log.scroll_to_line(message_log.get_line_count())
	print(text)

## 事件处理
func _on_player_hp_changed(player_id: int, current: int, max_hp: int) -> void:
	if player_id == 0:  # 人类玩家
		_update_player_info()

func _on_player_kpi_changed(player_id: int, kpi: int) -> void:
	if player_id == 0:
		_update_player_info()

func _on_player_eliminated(player_id: int, reason: String) -> void:
	if player_id == 0:
		_log_message("[color=#ff0000]你被淘汰了！原因：%s[/color]" % reason)
		_show_game_over(false)
	else:
		_log_message("同事%d被淘汰了 (%s)" % [player_id, reason])

func _on_turn_started(turn: int) -> void:
	_update_time_display()

func _on_turn_manager_turn_started(turn: int, month: int, quarter: int) -> void:
	_log_message("--- 第%d回合开始 ---" % turn)
	_update_time_display()

func _on_quarter_settled(quarter: int, eliminated: Array) -> void:
	_log_message("=== 第%d季度结算 ===" % quarter)
	_log_message("本季度淘汰人数: %d" % eliminated.size())
	
	if PlayerData.is_alive:
		var progress = PlayerData.get_promotion_progress()
		_log_message("你的晋升进度: %.0f%%" % (progress * 100))

func _on_ui_message(message: String, type: int) -> void:
	var color = "#ffffff"
	match type:
		EventBus.MessageType.WARNING:
			color = "#ffaa00"
		EventBus.MessageType.ERROR:
			color = "#ff0000"
		EventBus.MessageType.SUCCESS:
			color = "#00ff00"
		EventBus.MessageType.CRITICAL:
			color = "#ff00ff"
	
	_log_message("[color=%s]%s[/color]" % [color, message])

func _show_game_over(victory: bool) -> void:
	# TODO: 显示游戏结束界面
	if victory:
		_log_message("[color=#00ff00]恭喜！你赢得了胜利！[/color]")
	else:
		_log_message("[color=#ff0000]游戏结束[/color]")
	
	# 延迟返回主菜单
	await get_tree().create_timer(3.0).timeout
	GameManager.return_to_menu()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()

func _toggle_pause() -> void:
	if GameManager.current_state == Config.GameState.PLAYING:
		GameManager.pause_game()
		# TODO: 显示暂停菜单
	elif GameManager.current_state == Config.GameState.PAUSED:
		GameManager.resume_game()
