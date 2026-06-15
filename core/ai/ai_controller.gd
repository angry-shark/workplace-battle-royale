class_name AIController
extends Node
## AIController - AI控制器
## 管理AI玩家的决策逻辑，接入ShopManager和CardManager

enum AIType {
	GRINDER,
	WELLNESS,
	DECEIVER,
	SOCIAL,
	PROMOTION,
	LURKER
}

const AI_PROFILES: Dictionary = {
	AIType.GRINDER: {
		"name": "卷王型",
		"hp_threshold": 30,
		"kpi_priority": 2.0,
		"survival_priority": 0.5,
		"trap_frequency": 0.3,
		"alliance_willingness": 0.2,
		"overwork_chance": 0.7,
		"preferred_hex": "performance"
	},
	AIType.WELLNESS: {
		"name": "养生型",
		"hp_threshold": 70,
		"kpi_priority": 0.6,
		"survival_priority": 2.0,
		"trap_frequency": 0.2,
		"alliance_willingness": 0.5,
		"overwork_chance": 0.1,
		"preferred_hex": "survival"
	},
	AIType.DECEIVER: {
		"name": "老六型",
		"hp_threshold": 40,
		"kpi_priority": 1.0,
		"survival_priority": 1.0,
		"trap_frequency": 0.8,
		"alliance_willingness": 0.7,
		"overwork_chance": 0.3,
		"preferred_hex": "strategy"
	},
	AIType.SOCIAL: {
		"name": "社交型",
		"hp_threshold": 50,
		"kpi_priority": 0.9,
		"survival_priority": 1.1,
		"trap_frequency": 0.1,
		"alliance_willingness": 0.9,
		"overwork_chance": 0.4,
		"preferred_hex": "economy"
	},
	AIType.PROMOTION: {
		"name": "晋升型",
		"hp_threshold": 35,
		"kpi_priority": 1.8,
		"survival_priority": 0.7,
		"trap_frequency": 0.5,
		"alliance_willingness": 0.4,
		"overwork_chance": 0.6,
		"preferred_hex": "performance"
	},
	AIType.LURKER: {
		"name": "潜伏型",
		"hp_threshold": 45,
		"kpi_priority": 0.8,
		"survival_priority": 1.2,
		"trap_frequency": 0.4,
		"alliance_willingness": 0.3,
		"overwork_chance": 0.2,
		"preferred_hex": "strategy"
	}
}

var _player: Player
var _profile: Dictionary
var _all_players: Array = []
var _shop_manager: ShopManager = null


func _init(player: Player):
	_player = player
	_profile = AI_PROFILES.get(player.ai_type, AI_PROFILES[AIType.GRINDER])


func set_all_players(players: Array) -> void:
	_all_players = players


func set_shop_manager(shop: ShopManager) -> void:
	_shop_manager = shop


func make_decision(context: Dictionary) -> void:
	if not _player.is_alive:
		return
	
	if context.get("phase") == "shop":
		_do_shopping()
		return
	
	var action = _evaluate_actions(context)
	_execute_action(action)


func _evaluate_actions(context: Dictionary) -> Dictionary:
	var actions: Array[Dictionary] = []
	
	actions.append({"type": "work_normal", "score": _evaluate_work_normal()})
	actions.append({"type": "work_overtime", "score": _evaluate_work_overtime()})
	actions.append({"type": "work_slack", "score": _evaluate_work_slack()})
	
	if not _player.hand_cards.is_empty():
		var trap_targets = _find_trap_targets()
		for target in trap_targets:
			for card_id in _player.hand_cards:
				var card_info = CardManager.get_card_info(card_id)
				if card_info.get("type") == "陷害卡":
					actions.append({
						"type": "play_trap",
						"card_id": card_id,
						"target": target,
						"score": _evaluate_trap_card(target, card_info)
					})
	
	if _profile.alliance_willingness > 0.5:
		var alliance_targets = _find_alliance_targets()
		for target in alliance_targets:
			for card_id in _player.hand_cards:
				var card_info = CardManager.get_card_info(card_id)
				if card_info.get("type") == "联盟卡":
					actions.append({
						"type": "form_alliance",
						"card_id": card_id,
						"target": target,
						"score": _evaluate_alliance(target)
					})
	
	actions.sort_custom(func(a, b): return a.score > b.score)
	
	if actions.is_empty():
		return {"type": "work_normal"}
	
	return actions[0]


func _execute_action(action: Dictionary) -> void:
	match action.type:
		"work_normal":
			_apply_work_action("work_normal")
		"work_overtime":
			_apply_work_action("work_overtime")
		"work_slack":
			_apply_work_action("work_slack")
		"play_trap":
			var card_id = action.get("card_id", "")
			var target: Player = action.get("target")
			if target and not card_id.is_empty():
				if _player.total_salary >= _get_card_cost(card_id):
					CardManager.play_card(_player, card_id, target)
		"form_alliance":
			var card_id = action.get("card_id", "")
			var target: Player = action.get("target")
			if target and not card_id.is_empty():
				if _player.total_salary >= _get_card_cost(card_id):
					CardManager.play_card(_player, card_id, target)


func _apply_work_action(action_type: String) -> void:
	match action_type:
		"work_normal":
			_player.set_meta("work_kpi_multiplier", 1.0)
			_player.modify_hp(-5)
		"work_overtime":
			_player.set_meta("work_kpi_multiplier", 1.5)
			_player.modify_hp(-15)
		"work_slack":
			_player.set_meta("work_kpi_multiplier", 0.7)
			_player.modify_hp(5)


func _get_card_cost(card_id: String) -> int:
	var info = CardManager.get_card_info(card_id)
	return info.get("cost", 0)


func _evaluate_work_normal() -> float:
	return 1.0 * _profile.kpi_priority


func _evaluate_work_overtime() -> float:
	var hp_ratio = float(_player.current_hp) / _player.max_hp
	if hp_ratio < 0.4:
		return -10.0
	var score = 1.5 * _profile.kpi_priority
	if _player.ai_type == AIType.GRINDER:
		score *= 1.5
	return score


func _evaluate_work_slack() -> float:
	var hp_ratio = float(_player.current_hp) / _player.max_hp
	if hp_ratio > 0.8:
		return -5.0
	var score = 0.5 * _profile.survival_priority
	if _player.ai_type == AIType.WELLNESS:
		score *= 2.0
	return score


func _evaluate_trap_card(target: Player, card_info: Dictionary) -> float:
	if randf() > _profile.trap_frequency:
		return -1.0
	var score = 0.0
	if target.current_kpi > _player.current_kpi:
		score += 2.0
	var target_hp_ratio = float(target.current_hp) / target.max_hp
	if target_hp_ratio < 0.3:
		score += 3.0
	if _player.is_allied_with(target.player_id):
		score -= 10.0
	var expose_chance = card_info.get("effects", {}).get("expose_chance", 0.0)
	score -= expose_chance * 5.0
	return score


func _evaluate_alliance(target: Player) -> float:
	if not _can_form_alliance(target):
		return -1.0
	var score = 1.0 * _profile.alliance_willingness
	var kpi_diff = abs(target.current_kpi - _player.current_kpi)
	if kpi_diff < 20:
		score += 1.0
	var target_hp_ratio = float(target.current_hp) / target.max_hp
	if target_hp_ratio < 0.3:
		score -= 2.0
	return score


func _can_form_alliance(target: Player) -> bool:
	if _player.is_allied_with(target.player_id):
		return false
	if not target.is_alive:
		return false
	if _player.allies.size() >= 2:
		return false
	return true


func _find_trap_targets() -> Array[Player]:
	var targets: Array[Player] = []
	for player in _all_players:
		if player.player_id != _player.player_id and player.is_alive:
			if not _player.is_allied_with(player.player_id):
				targets.append(player)
	targets.sort_custom(func(a, b): return a.current_kpi > b.current_kpi)
	return targets


func _find_alliance_targets() -> Array[Player]:
	var targets: Array[Player] = []
	for player in _all_players:
		if player.player_id != _player.player_id and player.is_alive:
			if _can_form_alliance(player):
				targets.append(player)
	return targets


## 商店购物 - 通过ShopManager购买
func _do_shopping() -> void:
	if not _shop_manager:
		return
	if _player.total_salary <= 0:
		return
	
	var hp_ratio = float(_player.current_hp) / _player.max_hp
	
	# 进入商店获取商品列表
	var items = _shop_manager.get_current_items()
	if items.is_empty():
		_shop_manager.enter_shop(_player)
		items = _shop_manager.get_current_items()
	
	if items.is_empty():
		return
	
	# 优先恢复HP食物
	if hp_ratio < float(_profile.hp_threshold) / 100.0:
		# 购买最好的可负担食物
		var food_items: Array[Dictionary] = []
		for i in range(items.size()):
			if items[i].type == "food":
				food_items.append({"index": i, "item": items[i], "heal": items[i].effects.get("hp_recovery", 0)})
		
		if not food_items.is_empty():
			food_items.sort_custom(func(a, b): return a.heal > b.heal)
			for food in food_items:
				if _player.total_salary >= food.item.price:
					_shop_manager.purchase_item(_player, food.index)
					break
	
	# 晋升型买升职包
	if _player.ai_type == AIType.GRINDER or _player.ai_type == AIType.PROMOTION:
		for i in range(items.size()):
			if items[i].id == "special_promotion" and _player.total_salary >= items[i].price:
				_shop_manager.purchase_item(_player, i)
				break
	
	# 剩余资金买陷害卡包
	if _player.total_salary >= 400:
		for i in range(items.size()):
			if items[i].id == "card_trap_pack" and _player.total_salary >= items[i].price:
				_shop_manager.purchase_item(_player, i)
				break
	
	_shop_manager.exit_shop(_player)


func select_hex(options: Array) -> int:
	if options.is_empty():
		return 0
	
	var best_index = 0
	var best_score = -999.0
	
	for i in range(options.size()):
		var hex = options[i]
		var score = _evaluate_hex(hex)
		if score > best_score:
			best_score = score
			best_index = i
	
	return best_index


func _evaluate_hex(hex) -> float:
	var hex_type = hex.get("type", "") if hex is Dictionary else hex.type
	var effects = hex.get("effects", {}) if hex is Dictionary else hex.effects
	var score = 0.0
	
	if hex_type == _profile.preferred_hex:
		score += 2.0
	
	if effects.has("kpi_bonus"):
		score += effects.kpi_bonus * _profile.kpi_priority * 10
	if effects.has("hp_cost_reduction"):
		score += effects.hp_cost_reduction * _profile.survival_priority * 5
	if effects.has("salary_bonus"):
		score += effects.salary_bonus * 5
	
	var rarity = hex.get("rarity", "") if hex is Dictionary else hex.rarity
	if rarity == "legendary":
		score += 3.0
	
	return score


static func get_ai_type_name(ai_type: int) -> String:
	var profile = AI_PROFILES.get(ai_type, AI_PROFILES[AIType.GRINDER])
	return profile.name
