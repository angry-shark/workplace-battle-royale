class_name ShopPanel
extends PanelContainer
## ShopPanel - 商店面板
## 人类玩家的商店界面，显示商品并允许购买

signal purchase_confirmed(item_index: int)
signal shop_closed
signal shop_refresh_requested

var _shop_manager: ShopManager = null
var _player: Player = null
var _item_buttons: Array = []

@onready var title_label: Label = $MainVBox/TitleLabel
@onready var items_container: VBoxContainer = $MainVBox/ItemsContainer
@onready var refresh_btn: Button = $MainVBox/RefreshBtn
@onready var salary_label: Label = $MainVBox/SalaryLabel
@onready var close_btn: Button = $MainVBox/CloseBtn
@onready var status_label: Label = $MainVBox/StatusLabel


func _ready() -> void:
	GameTheme.apply_panel_style(self)
	refresh_btn.pressed.connect(_on_refresh_pressed)
	close_btn.pressed.connect(_on_close_pressed)
	hide()


func open_shop(player: Player, shop_manager: ShopManager) -> void:
	_player = player
	_shop_manager = shop_manager
	
	shop_manager.enter_shop(player)
	_refresh_display()
	show()
	AudioManager.play_ui("panel_open")


func _refresh_display() -> void:
	if not _player or not _shop_manager:
		return
	
	# 清空旧商品
	for child in items_container.get_children():
		child.queue_free()
	_item_buttons.clear()
	
	salary_label.text = "💰 可用工资: %d" % _player.total_salary
	status_label.text = ""
	
	var items = _shop_manager.get_current_items()
	if items.is_empty():
		status_label.text = "商店暂时无货"
		return
	
	for i in range(items.size()):
		var item = items[i]
		var btn = Button.new()
		
		var item_text = "%s  💰%d" % [item.name, item.price]
		if item.stock == 0:
			item_text += " [售罄]"
			btn.disabled = true
		elif _player.total_salary < item.price:
			btn.disabled = true
			item_text += " [余额不足]"
		
		btn.text = item_text
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 40)
		
		GameTheme.apply_button_style(btn, "secondary")
		btn.pressed.connect(_on_item_pressed.bind(i))
		btn.mouse_entered.connect(_on_item_hovered.bind(item))
		
		items_container.add_child(btn)
		_item_buttons.append(btn)
	
	# 刷新按钮状态
	var remaining = _shop_manager.get_remaining_refreshes()
	refresh_btn.text = "刷新商品 (剩余%d次, 💰%d)" % [remaining, _shop_manager.get_refresh_cost()]
	refresh_btn.disabled = remaining <= 0 or _player.total_salary < _shop_manager.get_refresh_cost()


func _on_item_pressed(index: int) -> void:
	AudioManager.play_button_click()
	
	if _shop_manager.purchase_item(_player, index):
		AudioManager.play_sfx("shop_buy")
		_refresh_display()
	else:
		status_label.text = "购买失败！"


func _on_item_hovered(item) -> void:
	var desc = item.description
	if not desc.is_empty():
		status_label.text = desc


func _on_refresh_pressed() -> void:
	AudioManager.play_button_click()
	
	if _shop_manager.refresh_shop(_player):
		_refresh_display()
		shop_refresh_requested.emit()
	else:
		status_label.text = "刷新失败！"


func _on_close_pressed() -> void:
	AudioManager.play_button_click()
	AudioManager.play_ui("panel_close")
	
	if _player and _shop_manager:
		_shop_manager.exit_shop(_player)
	
	_player = null
	_shop_manager = null
	hide()
	shop_closed.emit()


func is_open() -> bool:
	return visible
