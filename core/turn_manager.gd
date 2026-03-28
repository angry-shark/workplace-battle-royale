class_name TurnManager
extends Node
## TurnManager - 回合管理器
## 管理月度/季度的时间推进和结算

# 回合信号
signal turn_started(turn_number: int, month: int, quarter: int)
signal turn_ended(turn_number: int)
signal phase_started(phase: int)
signal phase_ended(phase: int)
signal month_settled(month: int)
signal quarter_settled(quarter: int, eliminated_players: Array)

# 游戏状态
var current_turn: int = 0
var current_phase: int = Config.TurnPhase.HP_DEDUCTION
var is_processing: bool = false

# 玩家列表
var players: Array = []  # Player 对象数组
var active_players: Array = []  # 存活玩家ID列表

# 当前季度数据
var current_quarter_kpi: Dictionary = {}  # player_id -> kpi

# AI管理器
var ai_manager: Node

func _init():
	print("TurnManager initialized")
	ai_manager = load("res://core/ai/ai_manager.gd").new()
	ai_manager.name = "AIManager"
	add_child(ai_manager)

## 开始游戏
func start_game(player_list: Array) -> void:
	players = player_list
	active_players.clear()
	for player in players:
		if player.is_alive:
			active_players.append(player.player_id)
	
	current_turn = 0
	current_quarter_kpi.clear()
	
	print("Game started with ", active_players.size(), " players")
	_start_turn()

## 开始新回合
func _start_turn() -> void:
	current_turn += 1
	current_phase = Config.TurnPhase.HP_DEDUCTION
	
	print("=== Turn ", current_turn, " Started ===")
	print("Time: ", GameManager.get_time_description())
	
	turn_started.emit(current_turn, GameManager.current_month, GameManager.current_quarter)
	EventBus.turn_started.emit(current_turn)
	
	_process_phase()

## 处理当前阶段
func _process_phase() -> void:
	phase_started.emit(current_phase)
	EventBus.phase_changed.emit(current_phase)
	
	match current_phase:
		Config.TurnPhase.HP_DEDUCTION:
			await _process_hp_deduction()
		Config.TurnPhase.ACTION:
			await _process_action_phase()
		Config.TurnPhase.WORK_OUTPUT:
			await _process_work_output()
		Config.TurnPhase.SALARY:
			await _process_salary_settlement()
		Config.TurnPhase.SHOP:
			await _process_shop_phase()
	
	phase_ended.emit(current_phase)
	_advance_phase()

## 推进到下一阶段
func _advance_phase() -> void:
	current_phase += 1
	
	if current_phase > Config.TurnPhase.SHOP:
		# 回合结束
		_end_turn()
	else:
		_process_phase()

## 回合结束
func _end_turn() -> void:
	print("=== Turn ", current_turn, " Ended ===")
	
	# 更新存活玩家数据
	for player in players:
		if player.is_alive:
			player.game_stats["turns_survived"] += 1
	
	turn_ended.emit(current_turn)
	EventBus.turn_ended.emit(current_turn)
	
	# 检查是否需要季度结算
	if GameManager.is_quarter_end():
		await _process_quarter_settlement()
	
	# 检查游戏是否结束
	if _check_game_end():
		return
	
	# 开始下一回合
	_start_turn()

## 阶段1: HP扣除
func _process_hp_deduction() -> void:
	print("Phase: HP Deduction")
	
	for player in players:
		if not player.is_alive:
			continue
		
		# 基础月度HP消耗
		var hp_cost = Config.MONTHLY_HP_COST
		
		# 程序员 burnout 风险
		if player.profession == Config.Profession.PROGRAMMER:
			var burnout_chance = Profession.get_data(Config.Profession.PROGRAMMER).burnout_risk
			if randf() < burnout_chance:
				hp_cost += 20
				print(player.player_name, " burnout! Extra HP cost: 20")
		
		# 销售抗压能力
		if player.profession == Config.Profession.SALES:
			if Profession.has_ability(Config.Profession.SALES, "stress_resistance"):
				hp_cost = int(hp_cost * 0.8)
		
		player.modify_hp(-hp_cost)
		print(player.player_name, " HP cost: ", hp_cost, ", Remaining HP: ", player.current_hp)
	
	await get_tree().create_timer(0.5).timeout

## 阶段2: 行动阶段
func _process_action_phase() -> void:
	print("Phase: Action")
	
	# 每个存活玩家执行行动
	for player in players:
		if not player.is_alive:
			continue
		
		if player.is_ai:
			# AI 决策
			await _process_ai_action(player)
		else:
			# 玩家操作 - 等待玩家输入
			await _process_player_action(player)

## 阶段3: 工作产出
func _process_work_output() -> void:
	print("Phase: Work Output")
	
	for player in players:
		if not player.is_alive:
			continue
		
		# 基础工作产出
		var work_effort = 10  # 默认工作努力度
		var kpi_earned = Profession.calculate_kpi(player.profession, work_effort)
		
		player.modify_kpi(kpi_earned)
		
		# 记录到当前季度KPI
		if not current_quarter_kpi.has(player.player_id):
			current_quarter_kpi[player.player_id] = 0
		current_quarter_kpi[player.player_id] += kpi_earned
		
		print(player.player_name, " earned KPI: ", kpi_earned)
	
	month_settled.emit(GameManager.current_month)
	await get_tree().create_timer(0.5).timeout

## 阶段4: 薪资结算
func _process_salary_settlement() -> void:
	print("Phase: Salary Settlement")
	
	for player in players:
		if not player.is_alive:
			continue
		
		# 职业薪资加成
		var salary_multiplier = 1.0
		if Profession.has_ability(player.profession, "salary_bonus"):
			salary_multiplier = Profession.get_data(player.profession).salary_bonus
		
		var final_salary = int(player.current_salary * salary_multiplier)
		player.modify_salary(final_salary - player.current_salary)  # 调整差额
		player.settle_salary()
		
		print(player.player_name, " salary settled: ", final_salary)
	
	await get_tree().create_timer(0.5).timeout

## 阶段5: 商店
func _process_shop_phase() -> void:
	print("Phase: Shop")
	
	for player in players:
		if not player.is_alive:
			continue
		
		EventBus.shop_entered.emit(player.player_id)
		
		if player.is_ai:
			# AI 自动购物
			_process_ai_shopping(player)
		
		EventBus.shop_exited.emit(player.player_id)

## 季度结算
func _process_quarter_settlement() -> void:
	print("=== Quarter ", GameManager.current_quarter, " Settlement ===")
	
	# 晋升检查
	for player in players:
		if not player.is_alive:
			continue
		
		var quarterly_kpi = current_quarter_kpi.get(player.player_id, 0)
		if LevelSystem.can_promote(player.rank, quarterly_kpi):
			player.promote()
			print(player.player_name, " promoted to P", player.rank)
	
	# 淘汰检查 (HC紧缩)
	var eliminated = _process_elimination()
	
	# 重置季度KPI
	current_quarter_kpi.clear()
	
	# 发放Hex
	_award_hexes()
	
	quarter_settled.emit(GameManager.current_quarter, eliminated)
	await get_tree().create_timer(1.0).timeout

## 淘汰处理
func _process_elimination() -> Array:
	var eliminated = []
	var total_active = 0
	
	for player in players:
		if player.is_alive:
			total_active += 1
	
	# 根据游戏规模计算淘汰人数
	var elimination_rate = GameManager.get_elimination_rate()
	var target_elimination = max(1, int(total_active * elimination_rate))
	
	# 管理层(P10+)免疫淘汰，计算实际可淘汰人数
	var immune_count = 0
	for player in players:
		if player.is_alive and player.rank >= 10:
			immune_count += 1
	
	var actual_elimination = min(target_elimination, total_active - immune_count - 1)  # 至少留1人
	
	# 按KPI排序
	var kpi_list = []
	for player in players:
		if player.is_alive:
			kpi_list.append({
				"id": player.player_id,
				"kpi": current_quarter_kpi.get(player.player_id, 0),
				"rank": player.rank
			})
	
	# 管理层排最后（免疫淘汰），其他人按KPI排序
	kpi_list.sort_custom(func(a, b):
		if a.rank >= 10 and b.rank < 10:
			return false  # a是管理层，排后面
		if a.rank < 10 and b.rank >= 10:
			return true   # b是管理层，a排前面
		return a.kpi > b.kpi  # 都非管理层，按KPI排序
	)
	
	# 淘汰排名靠后的玩家
	for i in range(kpi_list.size()):
		if eliminated.size() >= actual_elimination:
			break
		
		var player_id = kpi_list[i].id
		var player = _get_player_by_id(player_id)
		
		# 管理层免疫淘汰
		if player.rank >= 10:
			continue
		
		# 处于淘汰区
		player.die("季度绩效排名靠后，被优化")
		eliminated.append(player_id)
		active_players.erase(player_id)
	
	print("Eliminated this quarter: ", eliminated.size(), "/", total_active, " (rate: ", elimination_rate * 100, "%)")
	return eliminated

## 发放Hex
func _award_hexes() -> void:
	for player in players:
		if not player.is_alive:
			continue
		
		# TODO: 根据稀有度随机发放Hex
		pass

## 处理AI行动（批量处理）
func _process_ai_action(player) -> void:
	# 通过AIManager批量处理所有AI
	if not ai_manager.is_ai_processing():
		# 获取GameMain中的ai_controllers
		var game_main = get_parent()
		if game_main and game_main.has_method("_create_players"):
			var ai_controllers = game_main.ai_controllers if "ai_controllers" in game_main else {}
			ai_manager.start_ai_turn(players, ai_controllers)
		
		# 等待AI处理完成
		while ai_manager.is_ai_processing():
			await get_tree().create_timer(0.1).timeout
	
	await get_tree().create_timer(0.1).timeout

## 处理玩家行动
func _process_player_action(player) -> void:
	# 等待玩家UI输入
	EventBus.show_message("请选择行动", EventBus.MessageType.INFO)
	
	# 给玩家5秒时间选择（测试用，实际应该等待玩家输入）
	await get_tree().create_timer(2.0).timeout

## AI购物
func _process_ai_shopping(player) -> void:
	# 简单的AI购物逻辑
	if player.total_salary >= 80:
		# 买咖啡恢复HP
		player.modify_hp(25)
		player.total_salary -= 80
		print(player.player_name, " bought coffee")

## 检查游戏结束
func _check_game_end() -> bool:
	# 只剩一个玩家存活
	if active_players.size() <= 1:
		if active_players.size() == 1:
			var winner = _get_player_by_id(active_players[0])
			if winner and not winner.is_ai:
				winner.victory(Config.VictoryCondition.LAST_STANDING)
		return true
	return false

## 根据ID获取玩家
func _get_player_by_id(id: int):
	for player in players:
		if player.player_id == id:
			return player
	return null
