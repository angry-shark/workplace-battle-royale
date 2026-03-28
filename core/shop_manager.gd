class_name ShopManager
extends Node
## ShopManager - 商店管理器
## 管理商店商品、购买、刷新

# 信号
signal shop_entered(player_id: int)
signal shop_exited(player_id: int)
signal item_purchased(player_id: int, item_id: String, price: int)
signal shop_refreshed(items: Array[ShopItem])

# 商品数据类
class ShopItem:
	var id: String
	var name: String
	var type: String  # food/card/info/special
	var price: int
	var description: String
	var effects: Dictionary
	var stock: int  # -1表示无限
	
	func _init(p_id: String, p_name: String, p_type: String, p_price: int):
		id = p_id
		name = p_name
		type = p_type
		price = p_price
		description = ""
		effects = {}
		stock = -1

# 商品配置
var _shop_catalog: Dictionary = {}

# 当前商店商品
var _current_items: Array[ShopItem] = []

# 商店刷新次数（每月）
var _refresh_count: int = 0
const MAX_REFRESH_PER_MONTH: int = 3
const REFRESH_COST: int = 100

func _ready():
	_setup_shop_catalog()

## 初始化商店商品目录
func _setup_shop_catalog() -> void:
	# 食物类
	_shop_catalog["food_bento"] = _create_item(
		"food_bento", "便当", "food", 50,
		"HP+15",
		{"hp_recovery": 15}
	)
	
	_shop_catalog["food_coffee"] = _create_item(
		"food_coffee", "咖啡", "food", 80,
		"HP+25",
		{"hp_recovery": 25}
	)
	
	_shop_catalog["food_supplements"] = _create_item(
		"food_supplements", "保健品", "food", 150,
		"HP+40",
		{"hp_recovery": 40}
	)
	
	_shop_catalog["food_counseling"] = _create_item(
		"food_counseling", "心理咨询", "food", 300,
		"HP+80",
		{"hp_recovery": 80}
	)
	
	# 卡牌包
	_shop_catalog["card_trap_pack"] = _create_item(
		"card_trap_pack", "陷害卡包", "card", 400,
		"随机获得2张陷害卡",
		{"card_type": "trap", "count": 2}
	)
	
	_shop_catalog["card_alliance_pack"] = _create_item(
		"card_alliance_pack", "联盟卡包", "card", 350,
		"随机获得2张联盟卡",
		{"card_type": "alliance", "count": 2}
	)
	
	# 情报
	_shop_catalog["info_investigation"] = _create_item(
		"info_investigation", "背景调查", "info", 200,
		"查看指定同事的完整状态",
		{"reveal_target": "full_status"}
	)
	
	# 特殊
	_shop_catalog["special_promotion"] = _create_item(
		"special_promotion", "升职礼包", "special", 800,
		"下月绩效+30%",
		{"next_month_kpi_bonus": 0.3}
	)
	
	_shop_catalog["special_sudden_death"] = _create_item(
		"special_sudden_death", "猝死预警", "special", 500,
		"HP归零时恢复50HP（一次性）",
		{"death_immunity": true, "hp_recovery_on_death": 50},
		1  # 限量1个
	)
	
	print("Shop catalog setup complete, ", _shop_catalog.size(), " items")

## 创建商品
func _create_item(id: String, name: String, type: String, price: int, 
			description: String, effects: Dictionary, stock: int = -1) -> ShopItem:
	var item = ShopItem.new(id, name, type, price)
	item.description = description
	item.effects = effects
	item.stock = stock
	return item

## 进入商店
func enter_shop(player: Player) -> Array[ShopItem]:
	_refresh_count = 0
	
	# 检查是否需要刷新商品
	if _current_items.is_empty():
		_refresh_shop_items(player)
	
	shop_entered.emit(player.player_id)
	print("Player ", player.player_name, " entered shop")
	
	return _current_items

## 刷新商店商品
func refresh_shop(player: Player, force: bool = false) -> bool:
	if not force:
		# 检查刷新次数
		if _refresh_count >= MAX_REFRESH_PER_MONTH:
			EventBus.show_message("本月刷新次数已用完！", EventBus.MessageType.WARNING)
			return false
		
		# 检查费用
		if player.total_salary < REFRESH_COST:
			EventBus.show_message("工资不足以刷新商店！", EventBus.MessageType.WARNING)
			return false
		
		# 扣除费用
		player.total_salary -= REFRESH_COST
		_refresh_count += 1
	
	_refresh_shop_items(player)
	shop_refreshed.emit(_current_items)
	
	return true

## 生成商店商品
func _refresh_shop_items(player: Player) -> void:
	_current_items.clear()
	
	# 根据职级解锁不同商品
	var unlocked_items = _get_unlocked_items(player.rank)
	
	# 随机选择6个商品
	var selected = []
	var available = unlocked_items.duplicate()
	available.shuffle()
	
	for i in range(min(6, available.size())):
		var item_id = available[i]
		var item = _shop_catalog[item_id].duplicate()
		_current_items.append(item)
	
	print("Shop refreshed: ", _current_items.size(), " items")

## 获取解锁的商品（根据职级）
func _get_unlocked_items(rank: int) -> Array[String]:
	var unlocked: Array[String] = []
	
	# 基础商品（所有职级）
	unlocked.append_array([
		"food_bento",
		"food_coffee",
		"food_supplements",
		"card_trap_pack",
		"card_alliance_pack",
		"info_investigation"
	])
	
	# P4+解锁
	if rank >= 4:
		unlocked.append("food_counseling")
	
	# P7+解锁
	if rank >= 7:
		unlocked.append("special_promotion")
	
	# P10+解锁
	if rank >= 10:
		unlocked.append("special_sudden_death")
	
	return unlocked

## 购买商品
func purchase_item(player: Player, item_index: int) -> bool:
	if item_index < 0 or item_index >= _current_items.size():
		return false
	
	var item = _current_items[item_index]
	
	# 检查库存
	if item.stock == 0:
		EventBus.show_message("该商品已售罄！", EventBus.MessageType.WARNING)
		return false
	
	# 检查费用
	if player.total_salary < item.price:
		EventBus.show_message("工资不足！", EventBus.MessageType.WARNING)
		return false
	
	# 检查是否可以购买此类型
	if not _can_purchase_type(player, item.type):
		return false
	
	# 扣除费用
	player.total_salary -= item.price
	
	# 减少库存
	if item.stock > 0:
		item.stock -= 1
	
	# 应用效果
	_apply_purchase_effect(player, item)
	
	item_purchased.emit(player.player_id, item.id, item.price)
	
	print("Player ", player.player_name, " purchased: ", item.name)
	
	return true

## 检查是否可以购买此类型商品
func _can_purchase_type(player: Player, item_type: String) -> bool:
	match item_type:
		"food":
			# 检查HP是否已满
			if player.current_hp >= player.max_hp:
				EventBus.show_message("HP已满，无需购买食物！", EventBus.MessageType.WARNING)
				return false
		"card":
			# 检查手牌是否已满
			if player.hand_cards.size() >= player.max_hand_size:
				EventBus.show_message("手牌已满！", EventBus.MessageType.WARNING)
				return false
		"info":
			# 检查是否有可调查的目标（暂时跳过检查）
			pass
	
	return true

## 应用购买效果
func _apply_purchase_effect(player: Player, item: ShopItem) -> void:
	var effects = item.effects
	
	match item.type:
		"food":
			# 恢复HP
			if effects.has("hp_recovery"):
				player.modify_hp(effects.hp_recovery)
				EventBus.show_message("恢复了 " + str(effects.hp_recovery) + " 点HP！", 
					EventBus.MessageType.SUCCESS)
		
		"card":
			# 发放卡牌
			if effects.has("card_type") and effects.has("count"):
				var card_type = _string_to_card_type(effects.card_type)
				for i in range(effects.count):
					# TODO: 调用CardManager抽卡
					pass
		
		"info":
			# 显示信息选择界面
			if effects.get("reveal_target") == "full_status":
				# TODO: 打开目标选择界面
				pass
		
		"special":
			# 特殊效果
			if effects.has("death_immunity"):
				player.set_meta("has_death_immunity", true)
				EventBus.show_message("获得猝死预警保护！", EventBus.MessageType.SUCCESS)
			
			if effects.has("next_month_kpi_bonus"):
				player.set_meta("next_month_kpi_bonus", effects.next_month_kpi_bonus)

## 字符串转卡牌类型
func _string_to_card_type(type_str: String) -> int:
	match type_str:
		"work":
			return CardManager.CardType.WORK
		"trap":
			return CardManager.CardType.TRAP
		"alliance":
			return CardManager.CardType.ALLIANCE
		"special":
			return CardManager.CardType.SPECIAL
		_:
			return CardManager.CardType.WORK

## 退出商店
func exit_shop(player: Player) -> void:
	shop_exited.emit(player.player_id)
	print("Player ", player.player_name, " exited shop")

## 获取当前商品列表
func get_current_items() -> Array[ShopItem]:
	return _current_items

## 获取刷新费用
func get_refresh_cost() -> int:
	if _refresh_count >= MAX_REFRESH_PER_MONTH:
		return -1  # 不可刷新
	return REFRESH_COST

## 获取剩余刷新次数
func get_remaining_refreshes() -> int:
	return MAX_REFRESH_PER_MONTH - _refresh_count
