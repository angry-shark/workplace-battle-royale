class_name CardHand
extends HBoxContainer
## CardHand - 手牌组件
## 显示和操作玩家手牌

signal card_selected(card_id: String)
signal card_played(card_id: String, target_id: int)

var _card_buttons: Dictionary = {}  # card_id -> Button
var _selected_card: String = ""
var _is_interactable: bool = true

@export var card_size: Vector2 = Vector2(100, 140)
@export var card_spacing: int = 10

func _ready():
	add_theme_constant_override("separation", card_spacing)
	alignment = ALIGNMENT_CENTER

## 设置手牌（传入卡牌ID列表）
func set_hand(card_ids: Array[String]) -> void:
	# 清除现有卡牌
	for child in get_children():
		child.queue_free()
	_card_buttons.clear()
	
	# 创建卡牌按钮
	for card_id in card_ids:
		_add_card_button(card_id)

## 添加单张卡牌按钮
func _add_card_button(card_id: String) -> void:
	var card_info = CardManager.get_card_info(card_id)
	if card_info.is_empty():
		return
	
	var button = Button.new()
	button.name = "Card_" + card_id
	button.custom_minimum_size = card_size
	button.toggle_mode = true
	
	# 创建卡牌视觉
	var vbox = VBoxContainer.new()
	vbox.alignment = ALIGNMENT_CENTER
	button.add_child(vbox)
	
	# 卡牌名称
	var name_label = Label.new()
	name_label.text = card_info.get("name", "未知")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", GameTheme.FONTS.body_small)
	name_label.add_theme_color_override("font_color", GameTheme.COLORS.text_primary)
	vbox.add_child(name_label)
	
	# 卡牌类型图标
	var type_icon = Label.new()
	type_icon.text = _get_type_icon(card_info.get("type", ""))
	type_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_icon.add_theme_font_size_override("font_size", 32)
	vbox.add_child(type_icon)
	
	# 费用
	var cost = card_info.get("cost", 0)
	if cost > 0:
		var cost_label = Label.new()
		cost_label.text = "💰" + str(cost)
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_label.add_theme_font_size_override("font_size", GameTheme.FONTS.label)
		cost_label.add_theme_color_override("font_color", GameTheme.COLORS.accent_orange)
		vbox.add_child(cost_label)
	
	# 设置样式
	_apply_card_style(button, false)
	
	# 连接信号
	button.pressed.connect(_on_card_pressed.bind(card_id))
	button.mouse_entered.connect(_on_card_hovered.bind(card_id, card_info))
	button.mouse_exited.connect(_on_card_exited)
	
	add_child(button)
	_card_buttons[card_id] = button

## 获取类型图标
func _get_type_icon(card_type: String) -> String:
	match card_type:
		"工作卡":
			return "📄"
		"陷害卡":
			return "⚔️"
		"联盟卡":
			return "🤝"
		"特殊卡":
			return "✨"
		_:
			return "🃏"

## 应用卡牌样式
func _apply_card_style(button: Button, is_selected: bool) -> void:
	var normal_style = StyleBoxFlat.new()
	var hover_style = StyleBoxFlat.new()
	var pressed_style = StyleBoxFlat.new()
	
	if is_selected:
		normal_style.bg_color = GameTheme.COLORS.primary_light
		normal_style.border_color = GameTheme.COLORS.accent_orange
		normal_style.border_width_left = 3
		normal_style.border_width_top = 3
		normal_style.border_width_right = 3
		normal_style.border_width_bottom = 3
	else:
		normal_style.bg_color = GameTheme.COLORS.bg_card
		normal_style.border_color = GameTheme.COLORS.primary_light
		normal_style.border_width_left = 1
		normal_style.border_width_top = 1
		normal_style.border_width_right = 1
		normal_style.border_width_bottom = 1
	
	hover_style.bg_color = GameTheme.COLORS.primary_light.lightened(0.1)
	hover_style.border_color = GameTheme.COLORS.accent_blue
	for style in [normal_style, hover_style, pressed_style]:
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
	
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)

## 卡牌点击
func _on_card_pressed(card_id: String) -> void:
	if not _is_interactable:
		return
	
	AudioManager.play_button_click()
	
	# 切换选中状态
	if _selected_card == card_id:
		_selected_card = ""
		_apply_card_style(_card_buttons[card_id], false)
	else:
		# 取消之前的选中
		if _selected_card != "" and _card_buttons.has(_selected_card):
			_apply_card_style(_card_buttons[_selected_card], false)
		
		_selected_card = card_id
		_apply_card_style(_card_buttons[card_id], true)
	
	card_selected.emit(card_id)

## 卡牌悬停
func _on_card_hovered(card_id: String, card_info: Dictionary) -> void:
	if not _is_interactable:
		return
	
	AudioManager.play_button_hover()
	
	# 显示提示
	var title = card_info.get("name", "")
	var content = card_info.get("description", "")
	var cost = card_info.get("cost", 0)
	if cost > 0:
		content += "\n\n费用: " + str(cost)
	
	# TODO: 显示Tooltip
	print("Card tooltip: ", title, " - ", content)

## 卡牌离开
func _on_card_exited() -> void:
	# TODO: 隐藏Tooltip
	pass

## 设置交互状态
func set_interactable(enabled: bool) -> void:
	_is_interactable = enabled
	for button in _card_buttons.values():
		button.disabled = not enabled

## 移除卡牌
func remove_card(card_id: String) -> void:
	if _card_buttons.has(card_id):
		_card_buttons[card_id].queue_free()
		_card_buttons.erase(card_id)
	
	if _selected_card == card_id:
		_selected_card = ""

## 清空手牌
func clear_hand() -> void:
	for child in get_children():
		child.queue_free()
	_card_buttons.clear()
	_selected_card = ""

## 获取选中的卡牌
func get_selected_card() -> String:
	return _selected_card

## 取消选择
func deselect_all() -> void:
	if _selected_card != "" and _card_buttons.has(_selected_card):
		_apply_card_style(_card_buttons[_selected_card], false)
	_selected_card = ""
