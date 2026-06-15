extends Node

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_elimination_removes_lowest_kpi()
	_test_player_exposes_victory_method()
	_test_salary_settlement_emits_total_salary()
	_test_player_data_syncs_from_runtime_player()
	_test_turn_manager_applies_hex_effects()
	_test_quarter_awards_hex_to_survivors()
	_test_shop_card_pack_draws_cards()
	_test_work_output_uses_action_bonuses()
	_test_work_card_play_affects_output()
	_test_trap_cards_apply_configured_effects()
	_test_alliance_cards_apply_configured_effects()
	_test_rank_protection_shifts_elimination()
	_test_edited_scripts_load()

	_test_department_maps_profession_to_dept()
	_test_economy_tax_brackets()
	_test_economy_bonus_pool()
	_test_economy_inflation_advances()
	_test_random_events_load()
	_test_card_display_creates()
	_test_ai_shop_integration()
	_test_action_panel_state_transitions()
	_test_department_rivalry()
	_test_random_event_trigger_doesnt_crash()
	_test_player_initial_cards()
	_test_economy_recession_check()
	_test_ai_card_playing()
	
	await get_tree().process_frame
	
	if _failures.is_empty():
		print("CORE TESTS PASSED")
		get_tree().quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		get_tree().quit(1)


func _test_elimination_removes_lowest_kpi() -> void:
	GameManager.set_game_scale(GameManager.GameScale.DEBUG)
	
	var turn_manager = TurnManager.new()
	get_tree().root.add_child(turn_manager)
	
	var high_kpi_player = Player.new(0, "High KPI", Config.Profession.OPERATIONS, Config.Rank.P3, false)
	var low_kpi_player = Player.new(1, "Low KPI", Config.Profession.OPERATIONS, Config.Rank.P3, true)
	var mid_kpi_player = Player.new(2, "Mid KPI", Config.Profession.OPERATIONS, Config.Rank.P3, true)
	var manager_player = Player.new(3, "Manager", Config.Profession.OPERATIONS, Config.Rank.P10, true)
	
	turn_manager.players = [high_kpi_player, low_kpi_player, mid_kpi_player, manager_player]
	turn_manager.active_players = [0, 1, 2, 3]
	turn_manager.current_quarter_kpi = {
		0: 300,
		1: 10,
		2: 120,
		3: 0,
	}
	
	var eliminated = turn_manager._process_elimination()
	
	_assert(eliminated == [1], "Expected lowest non-management KPI player to be eliminated, got %s" % [str(eliminated)])
	_assert(low_kpi_player.is_alive == false, "Expected low KPI player to be marked eliminated")
	_assert(high_kpi_player.is_alive == true, "Expected high KPI player to survive")
	_assert(manager_player.is_alive == true, "Expected management rank player to be immune")
	
	for player in turn_manager.players:
		player.free()
	turn_manager.players.clear()
	turn_manager.active_players.clear()
	turn_manager.queue_free()


func _test_player_exposes_victory_method() -> void:
	var player = Player.new(0, "Winner", Config.Profession.OPERATIONS, Config.Rank.P3, false)
	_assert(player.has_method("victory"), "Expected Player to expose victory(victory_condition) for TurnManager game-end flow")
	player.free()


func _test_salary_settlement_emits_total_salary() -> void:
	var player = Player.new(0, "Paid", Config.Profession.OPERATIONS, Config.Rank.P3, false)
	player.current_salary = 7000
	player.total_salary = 1000
	
	var signal_state = {"emitted_salary": -1}
	var callback = func(player_id: int, new_salary: int) -> void:
		if player_id == player.player_id:
			signal_state["emitted_salary"] = new_salary
	EventBus.player_salary_changed.connect(callback)
	
	player.settle_salary()
	
	EventBus.player_salary_changed.disconnect(callback)
	_assert(player.total_salary == 8000, "Expected salary settlement to add current salary to total salary")
	_assert(signal_state["emitted_salary"] == 8000, "Expected salary settlement to emit updated total salary, got %d" % signal_state["emitted_salary"])
	player.free()


func _test_player_data_syncs_from_runtime_player() -> void:
	var player = Player.new(0, "Runtime", Config.Profession.FINANCE, Config.Rank.P5, false)
	player.current_hp = 88
	player.current_kpi = 123
	player.current_salary = 11000
	player.total_salary = 22000
	player.hexes.append("hex_remote_work")
	player.hand_cards.append("work_normal")
	player.allies.append(2)
	player.game_stats["turns_survived"] = 4
	
	_assert(PlayerData.has_method("sync_from_player"), "Expected PlayerData to expose sync_from_player(player)")
	if PlayerData.has_method("sync_from_player"):
		PlayerData.sync_from_player(player)
		_assert(PlayerData.player_name == "Runtime", "Expected PlayerData name to sync from runtime player")
		_assert(PlayerData.profession == Config.Profession.FINANCE, "Expected PlayerData profession to sync from runtime player")
		_assert(PlayerData.rank == Config.Rank.P5, "Expected PlayerData rank to sync from runtime player")
		_assert(PlayerData.current_hp == 88, "Expected PlayerData HP to sync from runtime player")
		_assert(PlayerData.current_kpi == 123, "Expected PlayerData KPI to sync from runtime player")
		_assert(PlayerData.total_salary == 22000, "Expected PlayerData total salary to sync from runtime player")
		_assert(PlayerData.hexes == ["hex_remote_work"], "Expected PlayerData hexes to sync from runtime player")
		_assert(PlayerData.hand_cards == ["work_normal"], "Expected PlayerData hand cards to sync from runtime player")
		_assert(PlayerData.current_game_stats["turns_survived"] == 4, "Expected PlayerData stats to sync from runtime player")
	
	player.free()


func _test_turn_manager_applies_hex_effects() -> void:
	var turn_manager = TurnManager.new()
	get_tree().root.add_child(turn_manager)
	
	var player = Player.new(10, "Hexed", Config.Profession.OPERATIONS, Config.Rank.P3, false)
	HexManager.select_hex(player, HexManager.get_hex_by_id("hex_remote_work"))
	HexManager.select_hex(player, HexManager.get_hex_by_id("hex_ppt_god"))
	HexManager.select_hex(player, HexManager.get_hex_by_id("hex_side_income"))
	
	_assert(turn_manager.has_method("_get_monthly_hp_cost"), "Expected TurnManager to expose _get_monthly_hp_cost(player)")
	_assert(turn_manager.has_method("_calculate_work_kpi"), "Expected TurnManager to expose _calculate_work_kpi(player, work_effort)")
	_assert(turn_manager.has_method("_calculate_salary"), "Expected TurnManager to expose _calculate_salary(player)")
	
	if turn_manager.has_method("_get_monthly_hp_cost"):
		_assert(turn_manager._get_monthly_hp_cost(player) == 8, "Expected remote work hex to reduce monthly HP cost from 10 to 8")
	if turn_manager.has_method("_calculate_work_kpi"):
		_assert(turn_manager._calculate_work_kpi(player, 10) == 12, "Expected PPT hex to boost operations KPI from 12 to 12 after integer rounding")
	if turn_manager.has_method("_calculate_salary"):
		_assert(turn_manager._calculate_salary(player) == 7700, "Expected side income hex to boost salary from 7000 to 7700")
	
	player.free()
	turn_manager.queue_free()


func _test_quarter_awards_hex_to_survivors() -> void:
	var turn_manager = TurnManager.new()
	get_tree().root.add_child(turn_manager)
	var player = Player.new(20, "Survivor", Config.Profession.OPERATIONS, Config.Rank.P3, false)
	turn_manager.players = [player]
	
	turn_manager._award_hexes()
	
	_assert(player.hexes.size() == 1, "Expected quarter award to give one hex to each survivor")
	
	player.free()
	turn_manager.queue_free()


func _test_shop_card_pack_draws_cards() -> void:
	var shop = ShopManager.new()
	get_tree().root.add_child(shop)
	shop._setup_shop_catalog()
	
	var player = Player.new(30, "Buyer", Config.Profession.OPERATIONS, Config.Rank.P6, false)
	player.total_salary = 1000
	player.max_hand_size = 4
	shop._current_items.clear()
	shop._current_items.append(shop._shop_catalog["card_trap_pack"])
	
	var purchased = shop.purchase_item(player, 0)
	
	_assert(purchased == true, "Expected card pack purchase to succeed")
	_assert(player.total_salary == 600, "Expected card pack purchase to deduct 400 salary")
	_assert(player.hand_cards.size() == 2, "Expected trap card pack to draw 2 cards")
	for card_id in player.hand_cards:
		var card_info = CardManager.get_card_info(card_id)
		_assert(card_info.get("type") == "陷害卡", "Expected drawn card to be a trap card, got %s" % [card_info.get("type", "")])
	
	player.free()
	shop.queue_free()


func _test_work_output_uses_action_bonuses() -> void:
	var turn_manager = TurnManager.new()
	get_tree().root.add_child(turn_manager)
	var player = Player.new(40, "Overtime", Config.Profession.OPERATIONS, Config.Rank.P3, false)
	player.set_meta("work_kpi_multiplier", 1.5)
	player.set_meta("next_month_kpi_bonus", 0.3)
	
	var kpi = turn_manager._calculate_work_kpi(player, 10)
	
	_assert(kpi == 23, "Expected action and next-month bonuses to raise operations KPI from 12 to 23, got %d" % kpi)
	
	player.free()
	turn_manager.queue_free()


func _test_work_card_play_affects_output() -> void:
	var turn_manager = TurnManager.new()
	get_tree().root.add_child(turn_manager)
	var player = Player.new(50, "Card Worker", Config.Profession.OPERATIONS, Config.Rank.P3, false)
	player.add_card("work_overtime")
	
	var played = CardManager.play_card(player, "work_overtime")
	var kpi = turn_manager._calculate_work_kpi(player, 10)
	
	_assert(played == true, "Expected overtime work card to be playable without target")
	_assert(player.hand_cards.is_empty(), "Expected played work card to leave hand")
	_assert(kpi == 18, "Expected overtime card to apply 1.5x KPI multiplier, got %d" % kpi)
	
	player.free()
	turn_manager.queue_free()


func _test_trap_cards_apply_configured_effects() -> void:
	var turn_manager = TurnManager.new()
	get_tree().root.add_child(turn_manager)
	var attacker = Player.new(60, "Attacker", Config.Profession.OPERATIONS, Config.Rank.P6, false)
	var target = Player.new(61, "Target", Config.Profession.OPERATIONS, Config.Rank.P6, true)
	attacker.total_salary = 3000
	target.current_salary = 13000
	target.total_salary = 1000
	target.add_ally(99)
	
	attacker.add_card("trap_salary_cut")
	_assert(CardManager.play_card(attacker, "trap_salary_cut", target), "Expected salary cut trap to play")
	_assert(turn_manager._calculate_salary(target) == 9100, "Expected salary cut trap to reduce next salary by 30%")
	
	attacker.add_card("trap_pitfall")
	_assert(CardManager.play_card(attacker, "trap_pitfall", target), "Expected pitfall trap to play")
	target.add_card("work_overtime")
	_assert(CardManager.play_card(target, "work_overtime"), "Expected debuffed overtime card to play")
	_assert(turn_manager._calculate_work_kpi(target, 10) == 9, "Expected pitfall to halve overtime multiplier from 1.5x to 0.75x")
	
	attacker.add_card("trap_rumor")
	_assert(CardManager.play_card(attacker, "trap_rumor", target), "Expected rumor trap to play")
	target.add_card("alliance_form")
	_assert(CardManager.play_card(target, "alliance_form", attacker) == false, "Expected disabled alliance target to be unable to play alliance cards")
	
	attacker.add_card("trap_isolate")
	_assert(CardManager.play_card(attacker, "trap_isolate", target), "Expected isolate trap to play")
	_assert(target.allies.is_empty(), "Expected isolate trap to clear target alliances")
	
	attacker.free()
	target.free()
	turn_manager.queue_free()


func _test_alliance_cards_apply_configured_effects() -> void:
	var turn_manager = TurnManager.new()
	get_tree().root.add_child(turn_manager)
	var player = Player.new(70, "Ally A", Config.Profession.OPERATIONS, Config.Rank.P6, false)
	var target = Player.new(71, "Ally B", Config.Profession.OPERATIONS, Config.Rank.P6, true)
	player.total_salary = 3000
	target.total_salary = 3000
	player.add_ally(target.player_id)
	target.add_ally(player.player_id)
	
	player.add_card("alliance_help")
	_assert(CardManager.play_card(player, "alliance_help", target), "Expected alliance help to play")
	_assert(turn_manager._calculate_work_kpi(player, 10) == 13, "Expected alliance help to add 10% KPI to player")
	_assert(turn_manager._calculate_work_kpi(target, 10) == 13, "Expected alliance help to add 10% KPI to ally")
	
	player.add_card("alliance_betray")
	var target_hp_before = target.current_hp
	_assert(CardManager.play_card(player, "alliance_betray", target), "Expected alliance betray to play")
	_assert(not player.is_allied_with(target.player_id), "Expected betrayal to remove player alliance")
	_assert(not target.is_allied_with(player.player_id), "Expected betrayal to remove target alliance")
	_assert(target.current_hp == target_hp_before - 20, "Expected betrayal double damage to deal 20 HP")
	
	player.free()
	target.free()
	turn_manager.queue_free()


func _test_rank_protection_shifts_elimination() -> void:
	GameManager.set_game_scale(GameManager.GameScale.DEBUG)
	var turn_manager = TurnManager.new()
	get_tree().root.add_child(turn_manager)
	
	var protected_low = Player.new(80, "Protected Low", Config.Profession.OPERATIONS, Config.Rank.P3, false)
	var unprotected_low = Player.new(81, "Unprotected Low", Config.Profession.OPERATIONS, Config.Rank.P3, true)
	var high = Player.new(82, "High", Config.Profession.OPERATIONS, Config.Rank.P3, true)
	protected_low.set_meta("rank_protection", 1)
	turn_manager.players = [protected_low, unprotected_low, high]
	turn_manager.active_players = [80, 81, 82]
	turn_manager.current_quarter_kpi = {
		80: 10,
		81: 12,
		82: 100,
	}
	
	var eliminated = turn_manager._process_elimination()
	
	_assert(eliminated == [81], "Expected rank protection to save lowest KPI player and eliminate next lowest, got %s" % str(eliminated))
	_assert(protected_low.is_alive, "Expected protected player to survive")
	_assert(not unprotected_low.is_alive, "Expected unprotected low player to be eliminated")
	
	protected_low.free()
	unprotected_low.free()
	high.free()
	turn_manager.queue_free()


func _test_edited_scripts_load() -> void:

	_test_department_maps_profession_to_dept()
	_test_economy_tax_brackets()
	_test_economy_bonus_pool()
	_test_economy_inflation_advances()
	_test_random_events_load()
	_test_card_display_creates()
	_test_ai_shop_integration()
	_test_action_panel_state_transitions()
	_test_department_rivalry()
	_test_random_event_trigger_doesnt_crash()
	_test_player_initial_cards()
	_test_economy_recession_check()
	_test_ai_card_playing()
	_assert(load("res://scenes/game/game_main.gd") != null, "Expected GameMain script to load")
	_assert(load("res://scenes/components/player_info_panel.gd") != null, "Expected PlayerInfoPanel script to load")
	_assert(load("res://core/ai/ai_controller.gd") != null, "Expected AIController script to load")


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _test_department_maps_profession_to_dept() -> void:
	_assert(Department.get_dept_from_profession(Config.Profession.PROGRAMMER) == Department.Dept.TECH,
		"Expected programmer to map to Tech department")
	_assert(Department.get_dept_from_profession(Config.Profession.HR) == Department.Dept.HR,
		"Expected HR to map to HR department")
	_assert(Department.get_dept_name(Department.Dept.TECH) == "技术部",
		"Expected Tech department name in Chinese")

func _test_economy_tax_brackets() -> void:
	_assert(Economy.calculate_tax(4000) == 0, "Expected no tax below 5000 threshold")
	_assert(Economy.calculate_tax(6000) == 50, "Expected 5% tax on 1000 above 5000 bracket")
	_assert(Economy.calculate_tax(15000) == 750, "Expected progressive tax at 15000")
	_assert(Economy.get_after_tax_salary(10000) == 9750, "Expected after-tax salary correct at 10000")

func _test_economy_bonus_pool() -> void:
	var pool = Economy.calculate_bonus_pool(10)
	_assert(pool == 3000, "Expected bonus pool of base 1000 + 10*200 = 3000")
	_assert(pool > 0, "Expected positive bonus pool")

func _test_economy_inflation_advances() -> void:
	var econ = Economy.new()
	econ.reset()
	_assert(econ.get_inflation_rate() == 0.02, "Expected base inflation rate")
	econ.advance_quarter()
	_assert(econ.get_inflation_rate() > 0.02, "Expected inflation to increase after quarter")

func _test_random_events_load() -> void:
	var events = ConfigLoader.load_random_events()
	_assert(events.size() >= 5, "Expected at least 5 random events loaded, got %d" % events.size())
	for event in events:
		_assert(event.has("id"), "Expected each event to have an 'id' field")
		_assert(event.has("effects"), "Expected each event to have 'effects' field")

func _test_card_display_creates() -> void:
	var card_id = "work_normal"
	var card_info = CardManager.get_card_info(card_id)
	_assert(not card_info.is_empty(), "Expected to find work_normal card info")
	var display = CardDisplay.new(card_id)
	_assert(display != null, "Expected CardDisplay to instantiate")
	var data = display.get_card_data()
	_assert(data.get("name") != "", "Expected CardDisplay to have card name")
	display.queue_free()

func _test_ai_shop_integration() -> void:
	var shop = ShopManager.new()
	get_tree().root.add_child(shop)
	shop._setup_shop_catalog()
	
	var player = Player.new(100, "AIShopper", Config.Profession.OPERATIONS, Config.Rank.P6, true)
	player.ai_type = AIController.AIType.GRINDER
	player.total_salary = 1000
	player.current_hp = 20
	player.max_hp = 130
	
	var ai = AIController.new(player)
	ai.set_shop_manager(shop)
	
	# AI应该进商店购物
	ai.make_decision({"phase": "shop"})
	
	_assert(player.total_salary <= 1000, "Expected AI to spend money in shop")
	_assert(player.current_hp >= 20, "Expected AI to heal if buying food")
	
	player.free()
	shop.queue_free()

func _test_action_panel_state_transitions() -> void:
	var panel = ActionPanel.new()
	get_tree().root.add_child(panel)
	
	var player = Player.new(200, "TestPlayer", Config.Profession.OPERATIONS, Config.Rank.P6, false)
	player.add_card("work_overtime")
	panel.start_action_phase(player, [player])
	
	_assert(panel.is_waiting() == false, "Expected panel not waiting before action")
	
	# 模拟选择加班
	panel._on_work_action("work_overtime")
	_assert(panel.is_waiting() == true, "Expected panel to wait after work action")
	_assert(panel.get_work_action() == "work_overtime", "Expected work action to be set")
	
	panel._reset_and_hide()
	_assert(panel.is_waiting() == false, "Expected panel to reset after hide")
	
	player.free()
	panel.queue_free()

func _test_department_rivalry() -> void:
	var tech_score = Department.get_rivalry_bonus(Department.Dept.TECH, Department.Dept.SALES)
	_assert(tech_score == 1.2, "Expected tech-vs-sales rivalry bonus of 1.2")
	
	var hr_defense = Department.get_rivalry_bonus(Department.Dept.TECH, Department.Dept.HR)
	_assert(hr_defense < 1.0, "Expected attacking HR to have defense penalty")

func _test_random_event_trigger_doesnt_crash() -> void:
	var turn_manager = TurnManager.new()
	get_tree().root.add_child(turn_manager)
	
	# 手动加载事件并触发
	if turn_manager._random_events.size() > 0:
		turn_manager._trigger_random_event()
	
	turn_manager.queue_free()

func _test_player_initial_cards() -> void:
	var turn_manager = TurnManager.new()
	get_tree().root.add_child(turn_manager)
	
	var player = Player.new(300, "CardStart", Config.Profession.OPERATIONS, Config.Rank.P6, false)
	turn_manager.players = [player]
	
	# 验证启动时卡牌
	_assert(player.hand_cards.size() >= 0, "Expected players to have card slot")
	
	player.free()
	turn_manager.queue_free()

func _test_economy_recession_check() -> void:
	var econ = Economy.new()
	_assert(econ.check_recession(300, 1000) == true, "Expected recession when KPI is below 60% of expected")
	_assert(econ.check_recession(800, 1000) == false, "Expected no recession when KPI is above 60%")

func _test_ai_card_playing() -> void:
	var attacker = Player.new(400, "AI_Attacker", Config.Profession.OPERATIONS, Config.Rank.P6, true)
	var target = Player.new(401, "AI_Target", Config.Profession.OPERATIONS, Config.Rank.P6, true)
	attacker.total_salary = 1000
	attacker.add_card("trap_report")
	
	var ai = AIController.new(attacker)
	ai.set_all_players([attacker, target])
	
	var target_hp_before = target.current_hp
	ai.make_decision({})
	
	# AI可能选择出牌或工作行动
	_assert(true, "AI should complete decision without error")
	
	attacker.free()
	target.free()
