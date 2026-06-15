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

# 商店管理器
var shop_manager: ShopManager

# 经济系统
var economy: Economy

# 随机事件缓存
var _random_events: Array = []
var _extra_elimination: int = 0


func _init():
	print("TurnManager initialized")
	ai_manager = load("res://core/ai/ai_manager.gd").new()
	ai_manager.name = "AIManager"
	add_child(ai_manager)

	shop_manager = ShopManager.new()
	shop_manager.name = "ShopManager"
	add_child(shop_manager)

	economy = Economy.new()

	_random_events = ConfigLoader.load_random_events()
	print("Loaded ", _random_events.size(), " random events")

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

	# 给每个玩家发放初始卡牌
	for player in players:
		if player.is_alive:
			CardManager.draw_card(player, CardManager.CardType.WORK)
			CardManager.draw_card(player, CardManager.CardType.WORK)
	_start_turn()

## 开始新回合
func _start_turn() -> void:
	current_turn += 1
	current_phase = Config.TurnPhase.HP_DEDUCTION
	
	print("=== Turn ", current_turn, " Started ===")
	print("Time: ", GameManager.get_time_description())
	
	turn_started.emit(current_turn, GameManager.current_month, GameManager.current_quarter)
	EventBus.turn_started.emit(current_turn)

	# 触发随机事件
	_trigger_random_event()
	
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
		var hp_cost = _get_monthly_hp_cost(player)
		
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
		_apply_monthly_hex_recovery(player)
		print(player.player_name, " HP cost: ", hp_cost, ", Remaining HP: ", player.current_hp)
	
	await get_tree().create_timer(0.5).timeout

## 阶段2: 行动阶段
func _process_action_phase() -> void:
	print("Phase: Action")

	# 检查是否因随机事件跳过
	if _skip_next_action:
		_skip_next_action = false
		print("Action phase skipped due to event")
		await get_tree().create_timer(0.5).timeout
		return
	
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
		var kpi_earned = _calculate_work_kpi(player, work_effort)
		_clear_consumed_work_bonuses(player)
		
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
		
		var final_salary = _calculate_salary(player, salary_multiplier)
		player.modify_salary(final_salary - player.current_salary)  # 调整差额
		player.settle_salary()

		# 应用税收
		var tax = Economy.calculate_tax(player.total_salary)
		if tax > 0:
			player.total_salary -= tax
			EventBus.player_salary_changed.emit(player.player_id, player.total_salary)
		_clear_consumed_salary_bonuses(player)
		
		print(player.player_name, " salary settled: ", final_salary)
	
	await get_tree().create_timer(0.5).timeout

## 阶段5: 商店
func _process_shop_phase() -> void:
	print("Phase: Shop")
	
	for player in players:
		if not player.is_alive:
			continue
		
		shop_manager.enter_shop(player)
		
		if player.is_ai:
			_process_ai_shopping(player)
		else:
			EventBus.show_message("请选择商品", EventBus.MessageType.INFO)
			await EventBus.shop_completed
		
		shop_manager.exit_shop(player)

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
	
	
	# 发放季度奖金
	Economy.distribute_quarterly_bonus(players)

	# 推进经济系统（通货膨胀）
	economy.advance_quarter()

	# 重置额外淘汰计数
	_extra_elimination = 0

	# 检查经济衰退
	var expected_kpi = GameManager.total_players * 50 * current_quarter
	var total_kpi = 0
	for player in players:
		if player.is_alive:
			total_kpi += player.current_kpi
	if economy.check_recession(total_kpi, expected_kpi):
		economy.apply_recession(players)

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
	
	var actual_elimination = min(target_elimination + _extra_elimination, total_active - immune_count - 1)  # 至少留1人
	
	# 按KPI排序
	var kpi_list = []
	for player in players:
		if player.is_alive:
			kpi_list.append({
				"id": player.player_id,
				"kpi": current_quarter_kpi.get(player.player_id, 0),
				"effective_kpi": current_quarter_kpi.get(player.player_id, 0) + _get_rank_protection_bonus(player),
				"rank": player.rank
			})
	
	# 管理层排最后（免疫淘汰），其他人按KPI排序
	kpi_list.sort_custom(func(a, b):
		if a.rank >= 10 and b.rank < 10:
			return false  # a是管理层，排后面
		if a.rank < 10 and b.rank >= 10:
			return true   # b是管理层，a排前面
		return a.effective_kpi < b.effective_kpi  # 都非管理层，按保护后的KPI从低到高排序
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
		
		var options = HexManager.start_hex_selection(player)
		if options.is_empty():
			continue
		
		var selected_index = 0
		if player.is_ai:
			var controller = _get_ai_controller(player.player_id)
			if controller and controller.has_method("select_hex"):
				selected_index = clamp(controller.select_hex(options), 0, options.size() - 1)
		
		HexManager.select_hex(player, options[selected_index])

## 计算月度HP消耗
func _get_monthly_hp_cost(player: Player) -> int:
	var effects = HexManager.calculate_hex_effects(player)
	var hp_cost = Config.MONTHLY_HP_COST - effects.get("hp_cost_reduction", 0)
	return max(0, hp_cost)

## 应用月度海克斯恢复
func _apply_monthly_hex_recovery(player: Player) -> void:
	var effects = HexManager.calculate_hex_effects(player)
	var recovery = effects.get("hp_recovery", 0)
	var threshold = effects.get("low_hp_threshold", 0)
	if threshold > 0 and player.current_hp <= threshold:
		recovery += effects.get("low_hp_recovery", 0)
	
	if recovery > 0:
		player.modify_hp(recovery)

## 计算工作产出KPI
func _calculate_work_kpi(player: Player, work_effort: int) -> int:
	var base_kpi = Profession.calculate_kpi(player.profession, work_effort)
	var effects = HexManager.calculate_hex_effects(player)
	var multiplier = 1.0 + effects.get("kpi_bonus", 0.0) + effects.get("kpi_penalty", 0.0)
	multiplier *= float(player.get_meta("work_kpi_multiplier", 1.0))
	multiplier *= 1.0 + float(player.get_meta("next_month_kpi_bonus", 0.0))
	if effects.get("early_turns", 0) > 0 and current_turn <= effects.get("early_turns", 0):
		multiplier += effects.get("early_kpi_bonus", 0.0)
	return max(0, int(base_kpi * multiplier))

## 清理已消耗的工作产出Buff
func _clear_consumed_work_bonuses(player: Player) -> void:
	if player.has_meta("work_kpi_multiplier"):
		player.remove_meta("work_kpi_multiplier")
	if player.has_meta("next_month_kpi_bonus"):
		player.remove_meta("next_month_kpi_bonus")

## 计算最终薪资
func _calculate_salary(player: Player, base_multiplier: float = 1.0) -> int:
	var effects = HexManager.calculate_hex_effects(player)
	var multiplier = base_multiplier + effects.get("salary_bonus", 0.0)
	multiplier *= float(player.get_meta("next_salary_multiplier", 1.0))
	return max(0, int(player.current_salary * multiplier))

## 获取缩圈排名保护加成
func _get_rank_protection_bonus(player: Player) -> int:
	return int(player.get_meta("rank_protection", 0)) * 10

## 清理已消耗的薪资Buff
func _clear_consumed_salary_bonuses(player: Player) -> void:
	if player.has_meta("next_salary_multiplier"):
		player.remove_meta("next_salary_multiplier")

## 获取AI控制器
func _get_ai_controller(player_id: int):
	var game_main = get_parent()
	if game_main and "ai_controllers" in game_main:
		return game_main.ai_controllers.get(player_id)
	return null

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
	EventBus.show_message("请选择行动", EventBus.MessageType.INFO)
	EventBus.player_action_phase_ready.emit(player.player_id)

	# 等待玩家通过UI确认行动
	await EventBus.player_action_completed
	print("Player action completed")

## AI购物
func _process_ai_shopping(player) -> void:
	# 通过AI控制器的do_shopping方法进行购物
	var controller = _get_ai_controller(player.player_id)
	if controller:
		controller.make_decision({"phase": "shop"})

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

## 触发随机事件
func _trigger_random_event() -> void:
	if _random_events.is_empty():
		return
	
	# 30%概率触发事件
	if randf() > 0.3:
		return
	
	var event = _random_events[randi() % _random_events.size()]
	var effects = event.get("effects", {})
	
	print("Random event triggered: ", event.get("name", "Unknown"))
	EventBus.show_message("随机事件: " + event.get("description", ""), EventBus.MessageType.INFO)
	
	# 全场HP效果
	if effects.has("all_hp"):
		var hp_change = effects.all_hp
		for player in players:
			if player.is_alive:
				player.modify_hp(hp_change)
	
	# 全场薪资效果
	if effects.has("all_salary"):
		for player in players:
			if player.is_alive:
				player.modify_salary(effects.all_salary)
	
	# 全员KPI倍率（当月）
	if effects.has("all_kpi_multiplier"):
		for player in players:
			if player.is_alive:
				var current = float(player.get_meta("work_kpi_multiplier", 1.0))
				player.set_meta("work_kpi_multiplier", current * effects.all_kpi_multiplier)
	
	# 下月KPI加成
	if effects.has("next_month_kpi_bonus"):
		for player in players:
			if player.is_alive:
				player.set_meta("next_month_kpi_bonus", effects.next_month_kpi_bonus)
	
	# 额外淘汰
	if effects.has("extra_elimination"):
		_extra_elimination += effects.extra_elimination
		EventBus.show_message("本季度淘汰人数 +" + str(effects.extra_elimination), EventBus.MessageType.WARNING)
	
	# 随机目标HP效果
	if effects.has("random_hp") and effects.has("random_count"):
		var alive = _get_alive_players()
		var count = min(effects.random_count, alive.size())
		alive.shuffle()
		for i in range(count):
			alive[i].modify_hp(effects.random_hp)
	
	# 随机目标薪资效果
	if effects.has("random_salary") and effects.has("random_count"):
		var alive = _get_alive_players()
		var count = min(effects.random_count, alive.size())
		alive.shuffle()
		for i in range(count):
			alive[i].modify_salary(effects.random_salary)
	
	# 跳过行动阶段
	if effects.get("skip_action_phase", false):
		_skip_next_action = true
		EventBus.show_message("本月行动阶段被跳过！", EventBus.MessageType.WARNING)
	
	# 绩效最低者惩罚
	if effects.has("bottom_hp") and effects.has("bottom_count"):
		var alive = _get_alive_players()
		alive.sort_custom(func(a, b): return a.current_kpi < b.current_kpi)
		var count = min(effects.bottom_count, alive.size())
		for i in range(count):
			alive[i].modify_hp(effects.bottom_hp)

var _skip_next_action: bool = false

## 获取存活玩家列表
func _get_alive_players() -> Array:
	var alive: Array = []
	for player in players:
		if player.is_alive:
			alive.append(player)
	return alive
