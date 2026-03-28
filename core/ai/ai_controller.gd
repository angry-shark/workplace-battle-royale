class_name AIController
extends Node
## AIController - AI控制器
## 管理AI玩家的决策逻辑

# AI类型
enum AIType {
	GRINDER,      # 卷王型 - 高绩效，低HP
	WELLNESS,     # 养生型 - 高HP，低绩效
	DECEIVER,     # 老六型 - 爱陷害
	SOCIAL,       # 社交型 - 爱结盟
	PROMOTION,    # 晋升型 - 追求高职级
	LURKER        # 潜伏型 - 隐藏实力
}

# AI决策权重配置
const AI_PROFILES: Dictionary = {
	AIType.GRINDER: {
		"name": "卷王型",
		"hp_threshold": 30,          # HP低于此值才考虑恢复
		"kpi_priority": 2.0,         # 绩效权重
		"survival_priority": 0.5,    # 生存权重
		"trap_frequency": 0.3,       # 陷害频率
		"alliance_willingness": 0.2, # 结盟意愿
		"overwork_chance": 0.7,      # 加班概率
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
		"alliance_willingness": 0.7,  # 高结盟意愿但也会背叛
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

func _init(player: Player):
	_player = player
	_profile = AI_PROFILES.get(player.ai_type, AI_PROFILES[AIType.GRINDER])

## 设置所有玩家引用（用于查找目标）
func set_all_players(players: Array) -> void:
	_all_players = players

## 执行AI回合决策
func make_decision(context: Dictionary) -> void:
	if not _player.is_alive:
		return
	
	print("AI ", _player.player_name, " (", _profile.name, ") making decision...")
	
	# 阶段1: 商店购买
	if context.get("phase") == "shop":
		_do_shopping()
		return
	
	# 阶段2: 行动选择
	var action = _evaluate_actions(context)
	_execute_action(action)

## 评估所有可能的行动
func _evaluate_actions(context: Dictionary) -> Dictionary:
	var actions: Array[Dictionary] = []
	
	# 工作卡选项
	actions.append({
		"type": "work_normal",
		"score": _evaluate_work_normal()
	})
	actions.append({
		"type": "work_overtime",
		"score": _evaluate_work_overtime()
	})
	actions.append({
		"type": "work_slack",
		"score": _evaluate_work_slack()
	})
	
	# 陷害卡选项
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
	
	# 联盟卡选项
	if _profile.alliance_willingness > 0.5:
		var alliance_targets = _find_alliance_targets()
		for target in alliance_targets:
			actions.append({
				"type": "form_alliance",
				"target": target,
				"score": _evaluate_alliance(target)
			})
	
	# 选择最高分的行动
	actions.sort_custom(func(a, b): return a.score > b.score)
	
	if actions.is_empty():
		return {"type": "work_normal"}
	
	return actions[0]

## 执行行动
func _execute_action(action: Dictionary) -> void:
	match action.type:
		"work_normal":
			print("AI ", _player.player_name, " chooses: 正常上班")
			# TODO: 使用工作卡
		
		"work_overtime":
			print("AI ", _player.player_name, " chooses: 拼命加班")
			_player.modify_hp(-15)
			_player.set_meta("work_kpi_multiplier", 1.5)
		
		"work_slack":
			print("AI ", _player.player_name, " chooses: 划水摸鱼")
			_player.modify_hp(5)
			_player.set_meta("work_kpi_multiplier", 0.7)
		
		"play_trap":
			print("AI ", _player.player_name, " plays trap on ", action.target.player_name)
			# TODO: 调用CardManager使用陷害卡
		
		"form_alliance":
			print("AI ", _player.player_name, " wants alliance with ", action.target.player_name)
			# TODO: 发起结盟请求

## 评估正常上班
func _evaluate_work_normal() -> float:
	var score = 1.0 * _profile.kpi_priority
	return score

## 评估拼命加班
func _evaluate_work_overtime() -> float:
	var hp_ratio = float(_player.current_hp) / _player.max_hp
	
	# HP低时不加班
	if hp_ratio < 0.4:
		return -10.0
	
	var score = 1.5 * _profile.kpi_priority
	
	# 卷王型更倾向于加班
	if _player.ai_type == AIType.GRINDER:
		score *= 1.5
	
	return score

## 评估划水摸鱼
func _evaluate_work_slack() -> float:
	var hp_ratio = float(_player.current_hp) / _player.max_hp
	
	# HP高时不摸鱼
	if hp_ratio > 0.8:
		return -5.0
	
	var score = 0.5 * _profile.survival_priority
	
	# 养生型更倾向于摸鱼
	if _player.ai_type == AIType.WELLNESS:
		score *= 2.0
	
	return score

## 评估陷害卡
func _evaluate_trap_card(target: Player, card_info: Dictionary) -> float:
	if randf() > _profile.trap_frequency:
		return -1.0  # 不想陷害
	
	var score = 0.0
	
	# 优先陷害高绩效的竞争对手
	if target.current_kpi > _player.current_kpi:
		score += 2.0
	
	# 优先陷害HP低的目标（更容易淘汰）
	var target_hp_ratio = float(target.current_hp) / target.max_hp
	if target_hp_ratio < 0.3:
		score += 3.0
	
	# 不陷害盟友
	if _player.is_allied_with(target.player_id):
		score -= 10.0
	
	# 暴露风险
	var expose_chance = card_info.effects.get("expose_chance", 0.0)
	score -= expose_chance * 5.0
	
	return score

## 评估结盟
func _evaluate_alliance(target: Player) -> float:
	if not _can_form_alliance(target):
		return -1.0
	
	var score = 1.0 * _profile.alliance_willingness
	
	# 优先与实力相近的结盟
	var kpi_diff = abs(target.current_kpi - _player.current_kpi)
	if kpi_diff < 20:
		score += 1.0
	
	# 不结盟HP太低的（可能很快淘汰）
	var target_hp_ratio = float(target.current_hp) / target.max_hp
	if target_hp_ratio < 0.3:
		score -= 2.0
	
	return score

## 检查是否可以结盟
func _can_form_alliance(target: Player) -> bool:
	# 已经是盟友
	if _player.is_allied_with(target.player_id):
		return false
	
	# 目标已死亡
	if not target.is_alive:
		return false
	
	# 盟友数已达上限
	if _player.allies.size() >= 2:  # 假设最多2个盟友
		return false
	
	return true

## 查找陷害目标
func _find_trap_targets() -> Array[Player]:
	var targets: Array[Player] = []
	
	for player in _all_players:
		if player.player_id != _player.player_id and player.is_alive:
			# 不陷害盟友
			if not _player.is_allied_with(player.player_id):
				targets.append(player)
	
	# 按威胁度排序（高绩效优先）
	targets.sort_custom(func(a, b): return a.current_kpi > b.current_kpi)
	
	return targets

## 查找结盟目标
func _find_alliance_targets() -> Array[Player]:
	var targets: Array[Player] = []
	
	for player in _all_players:
		if player.player_id != _player.player_id and player.is_alive:
			if _can_form_alliance(player):
				targets.append(player)
	
	return targets

## 商店购物
func _do_shopping() -> void:
	if _player.total_salary <= 0:
		return
	
	# 优先购买食物恢复HP
	var hp_ratio = float(_player.current_hp) / _player.max_hp
	
	if hp_ratio < float(_profile.hp_threshold) / 100.0:
		# 买最好的食物
		if _player.total_salary >= 300:
			_purchase_item("food_counseling")
		elif _player.total_salary >= 150:
			_purchase_item("food_supplements")
		elif _player.total_salary >= 80:
			_purchase_item("food_coffee")
		elif _player.total_salary >= 50:
			_purchase_item("food_bento")
	
	# 卷王型购买升职礼包
	if _player.ai_type == AIType.GRINDER and _player.total_salary >= 800:
		_purchase_item("special_promotion")
	
	# 有钱就买卡包
	if _player.total_salary >= 400:
		_purchase_item("card_trap_pack")

## 购买商品（简化版）
func _purchase_item(item_id: String) -> void:
	print("AI ", _player.player_name, " wants to buy: ", item_id)
	# TODO: 调用ShopManager购买

## 选择海克斯
func select_hex(options: Array) -> int:
	var best_index = 0
	var best_score = -999.0
	
	for i in range(options.size()):
		var hex = options[i]
		var score = _evaluate_hex(hex)
		
		if score > best_score:
			best_score = score
			best_index = i
	
	return best_index

## 评估海克斯
func _evaluate_hex(hex: Dictionary) -> float:
	var hex_type = hex.get("type", "")
	var effects = hex.get("effects", {})
	var score = 0.0
	
	# 根据AI类型偏好不同类型
	if hex_type == _profile.preferred_hex:
		score += 2.0
	
	# 评估具体效果
	if effects.has("kpi_bonus"):
		score += effects.kpi_bonus * _profile.kpi_priority * 10
	
	if effects.has("hp_cost_reduction"):
		score += effects.hp_cost_reduction * _profile.survival_priority * 5
	
	if effects.has("salary_bonus"):
		score += effects.salary_bonus * 5
	
	# 传说海克斯优先
	if hex.get("rarity") == "legendary":
		score += 3.0
	
	return score

## 获取AI类型名称
static func get_ai_type_name(ai_type: int) -> String:
	var profile = AI_PROFILES.get(ai_type, AI_PROFILES[AIType.GRINDER])
	return profile.name
