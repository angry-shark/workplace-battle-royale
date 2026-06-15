extends Node
## CardManager - 卡牌管理器
## 管理所有卡牌的创建、使用、效果结算

# 卡牌类型枚举
enum CardType {
	WORK,       # 工作卡
	TRAP,       # 陷害卡
	ALLIANCE,   # 联盟卡
	SPECIAL     # 特殊卡
}

# 卡牌数据类
class CardData:
	var id: String
	var name: String
	var type: int
	var subtype: String
	var description: String
	var cost: int
	var effects: Dictionary
	
	func _init(p_id: String, p_name: String, p_type: int, p_desc: String):
		id = p_id
		name = p_name
		type = p_type
		description = p_desc
		effects = {}
		cost = 0

# 信号（必须在CardData类定义之后）
signal card_drawn(player_id: int, card: CardData)
signal card_played(player_id: int, card: CardData, target_id: int)
signal card_discarded(player_id: int, card: CardData)
signal deck_shuffled(card_type: String)

# 卡池
var _work_deck: Array[CardData] = []
var _trap_deck: Array[CardData] = []
var _alliance_deck: Array[CardData] = []
var _special_deck: Array[CardData] = []

# 弃牌堆
var _discard_piles: Dictionary = {}

func _ready():
	_load_all_cards()
	_setup_discard_piles()

## 加载所有卡牌配置
func _load_all_cards() -> void:
	var config = ConfigLoader.load_all_cards()
	
	# 加载工作卡
	for card_json in config.get("work", []):
		_work_deck.append(_create_card_from_json(card_json, CardType.WORK))
	
	# 加载陷害卡
	for card_json in config.get("trap", []):
		_trap_deck.append(_create_card_from_json(card_json, CardType.TRAP))
	
	# 加载联盟卡
	for card_json in config.get("alliance", []):
		_alliance_deck.append(_create_card_from_json(card_json, CardType.ALLIANCE))
	
	# 加载特殊卡
	for card_json in config.get("special", []):
		_special_deck.append(_create_card_from_json(card_json, CardType.SPECIAL))
	
	print("Cards loaded: Work=", _work_deck.size(), 
		", Trap=", _trap_deck.size(), 
		", Alliance=", _alliance_deck.size(),
		", Special=", _special_deck.size())

## 从JSON创建卡牌
func _create_card_from_json(json: Dictionary, type: int) -> CardData:
	var card = CardData.new(
		json.get("id", ""),
		json.get("name", "未知卡牌"),
		type,
		json.get("description", "")
	)
	card.subtype = json.get("subtype", "")
	card.cost = json.get("cost", 0)
	card.effects = json.get("effects", {})
	return card

## 初始化弃牌堆
func _setup_discard_piles() -> void:
	_discard_piles["work"] = []
	_discard_piles["trap"] = []
	_discard_piles["alliance"] = []
	_discard_piles["special"] = []

## 获取卡牌类型名称
static func get_card_type_name(type: int) -> String:
	match type:
		CardType.WORK:
			return "工作卡"
		CardType.TRAP:
			return "陷害卡"
		CardType.ALLIANCE:
			return "联盟卡"
		CardType.SPECIAL:
			return "特殊卡"
		_:
			return "未知"

## 抽卡
func draw_card(player: Player, card_type: int) -> CardData:
	var deck: Array[CardData]
	var type_key: String
	
	match card_type:
		CardType.WORK:
			deck = _work_deck
			type_key = "work"
		CardType.TRAP:
			deck = _trap_deck
			type_key = "trap"
		CardType.ALLIANCE:
			deck = _alliance_deck
			type_key = "alliance"
		CardType.SPECIAL:
			deck = _special_deck
			type_key = "special"
		_:
			return null
	
	if deck.is_empty():
		# 如果卡池空了，从弃牌堆重置
		_reshuffle_deck(type_key)
		if deck.is_empty():
			return null
	
	# 随机抽取
	var index = randi() % deck.size()
	var card = deck[index]
	deck.remove_at(index)
	
	# 添加到手牌
	if player.add_card(card.id):
		card_drawn.emit(player.player_id, card)
		print("Player ", player.player_name, " drew: ", card.name)
		return card
	else:
		# 手牌满了，放回卡池
		deck.append(card)
		return null

## 使用卡牌
func play_card(player: Player, card_id: String, target: Player = null) -> bool:
	# 检查手牌
	if not player.hand_cards.has(card_id):
		push_warning("Player doesn't have card: " + card_id)
		return false
	
	# 获取卡牌数据
	var card = _get_card_data(card_id)
	if not card:
		return false
	
	# 检查费用
	if player.total_salary < card.cost:
		EventBus.show_message("工资不足！", EventBus.MessageType.WARNING)
		return false
	
	if card.type == CardType.ALLIANCE and player.get_meta("alliance_disabled", false):
		EventBus.show_message("你本月无法使用联盟卡！", EventBus.MessageType.WARNING)
		return false
	
	# 扣除费用
	if card.cost > 0:
		player.total_salary -= card.cost
	
	# 从手牌移除
	player.remove_card(card_id)
	
	# 执行效果
	_execute_card_effect(player, card, target)
	
	# 加入弃牌堆
	_discard_card(card)
	
	var target_id = target.player_id if target else -1
	card_played.emit(player.player_id, card, target_id)
	
	print("Player ", player.player_name, " played: ", card.name, 
		" on " + target.player_name if target else "")
	
	return true

## 执行卡牌效果
func _execute_card_effect(player: Player, card: CardData, target: Player) -> void:
	match card.type:
		CardType.WORK:
			_execute_work_card(player, card)
		CardType.TRAP:
			_execute_trap_card(player, card, target)
		CardType.ALLIANCE:
			_execute_alliance_card(player, card, target)
		CardType.SPECIAL:
			_execute_special_card(player, card, target)

## 执行工作卡效果
func _execute_work_card(player: Player, card: CardData) -> void:
	var effects = card.effects
	
	# HP消耗
	if effects.has("hp_cost"):
		player.modify_hp(-effects.hp_cost)
	
	# HP恢复
	if effects.has("hp_gain"):
		player.modify_hp(effects.hp_gain)
	
	# 绩效加成（在月度结算时计算）
	if effects.has("kpi_multiplier"):
		# 存储到玩家的临时buff中
		var multiplier = effects.kpi_multiplier
		if player.has_meta("work_card_debuff"):
			multiplier *= 1.0 - float(player.get_meta("work_card_debuff"))
			player.remove_meta("work_card_debuff")
		player.set_meta("work_kpi_multiplier", multiplier)

## 执行陷害卡效果
func _execute_trap_card(player: Player, card: CardData, target: Player) -> void:
	if not target:
		return
	
	var effects = card.effects
	var expose_chance = effects.get("expose_chance", 0.0)
	var is_exposed = randf() < expose_chance
	
	# 绩效影响
	if effects.has("target_kpi"):
		var kpi_damage = int(target.current_kpi * abs(effects.target_kpi))
		target.modify_kpi(-kpi_damage)
	
	# HP伤害
	if effects.has("target_hp"):
		target.modify_hp(effects.target_hp)
	
	# 窃取绩效
	if effects.has("steal_kpi_ratio"):
		var steal_amount = int(target.current_kpi * effects.steal_kpi_ratio)
		target.modify_kpi(-steal_amount)
		player.modify_kpi(steal_amount)
	
	# 禁用联盟卡
	if effects.get("disable_alliance", false):
		target.set_meta("alliance_disabled", true)
	
	# 工作卡效果削弱
	if effects.has("work_card_debuff"):
		target.set_meta("work_card_debuff", effects.work_card_debuff)
	
	# 薪资影响
	if effects.has("target_salary"):
		target.set_meta("next_salary_multiplier", 1.0 + float(effects.target_salary))
	
	# 解除目标所有联盟
	if effects.get("break_all_alliances", false):
		target.allies.clear()
	
	# 暴露处理
	if is_exposed:
		EventBus.show_message(player.player_name + "陷害被发现了！", EventBus.MessageType.WARNING)
		# TODO: 添加暴露惩罚逻辑

## 执行联盟卡效果
func _execute_alliance_card(player: Player, card: CardData, target: Player) -> void:
	if not target:
		return
	
	var effects = card.effects
	
	# 形成联盟
	if effects.get("form_alliance", false):
		player.add_ally(target.player_id)
		target.add_ally(player.player_id)
	
	# 背叛联盟
	if effects.get("break_alliance", false):
		player.remove_ally(target.player_id)
		target.remove_ally(player.player_id)
		
		# 双倍伤害
		if effects.get("double_damage", false):
			target.modify_hp(-20)
	
	# 联盟互助
	if effects.has("alliance_kpi_bonus"):
		var bonus = float(effects.alliance_kpi_bonus)
		player.set_meta("next_month_kpi_bonus", float(player.get_meta("next_month_kpi_bonus", 0.0)) + bonus)
		target.set_meta("next_month_kpi_bonus", float(target.get_meta("next_month_kpi_bonus", 0.0)) + bonus)
	
	# 缩圈保护
	if effects.has("rank_protection"):
		player.set_meta("rank_protection", int(effects.rank_protection))
		target.set_meta("rank_protection", int(effects.rank_protection))

## 执行特殊卡效果
func _execute_special_card(player: Player, card: CardData, target: Player) -> void:
	var effects = card.effects
	
	# 猝死预警（一次性复活）
	if card.id == "card_sudden_death_warning":
		player.set_meta("has_death_immunity", true)

## 获取卡牌数据
func _get_card_data(card_id: String) -> CardData:
	for card in _work_deck:
		if card.id == card_id:
			return card
	for card in _trap_deck:
		if card.id == card_id:
			return card
	for card in _alliance_deck:
		if card.id == card_id:
			return card
	for card in _special_deck:
		if card.id == card_id:
			return card
	
	# 从ConfigLoader加载
	var json = ConfigLoader.get_card_by_id(card_id)
	if not json.is_empty():
		var card_type = _string_to_card_type(json.get("type", "work"))
		var card = CardData.new(card_id, json.get("name", ""), card_type, json.get("description", ""))
		card.subtype = json.get("subtype", "")
		card.cost = json.get("cost", 0)
		card.effects = json.get("effects", {})
		return card
	
	return null

## 弃牌
func _discard_card(card: CardData) -> void:
	var type_key = ""
	match card.type:
		CardType.WORK:
			type_key = "work"
		CardType.TRAP:
			type_key = "trap"
		CardType.ALLIANCE:
			type_key = "alliance"
		CardType.SPECIAL:
			type_key = "special"
	
	if type_key:
		_discard_piles[type_key].append(card)

## 重置卡池（从弃牌堆）
func _reshuffle_deck(type_key: String) -> void:
	var discard: Array = _discard_piles.get(type_key, [])
	if discard.is_empty():
		return
	
	var deck: Array[CardData]
	match type_key:
		"work":
			deck = _work_deck
		"trap":
			deck = _trap_deck
		"alliance":
			deck = _alliance_deck
		"special":
			deck = _special_deck
	
	# 弃牌堆返回卡池
	deck.append_array(discard)
	discard.clear()
	
	deck_shuffled.emit(type_key)
	print("Deck reshuffled: ", type_key)

## 获取玩家可使用的卡牌列表
func get_usable_cards(player: Player) -> Array[CardData]:
	var usable: Array[CardData] = []
	
	for card_id in player.hand_cards:
		var card = _get_card_data(card_id)
		if card and card.cost <= player.total_salary:
			usable.append(card)
	
	return usable

## 字符串转卡牌类型
func _string_to_card_type(type_str: String) -> int:
	match type_str:
		"work":
			return CardType.WORK
		"trap":
			return CardType.TRAP
		"alliance":
			return CardType.ALLIANCE
		"special":
			return CardType.SPECIAL
		_:
			return CardType.WORK

## 获取卡牌信息（供UI显示）
func get_card_info(card_id: String) -> Dictionary:
	var card = _get_card_data(card_id)
	if not card:
		return {}
	
	return {
		"id": card.id,
		"name": card.name,
		"type": get_card_type_name(card.type),
		"description": card.description,
		"cost": card.cost,
		"effects": card.effects
	}
