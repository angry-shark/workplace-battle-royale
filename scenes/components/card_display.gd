class_name CardDisplay
extends Button
## CardDisplay - 卡牌可视化组件
## 单张卡牌的视觉渲染：类型色彩、图标、费用徽章等

signal card_clicked(card_id: String)
signal card_hovered(card_id: String)

var card_id: String = ""
var card_data: Dictionary = {}

# 样式常量
const CARD_SIZE := Vector2(110, 150)
const CORNER_RADIUS := 8
const BORDER_WIDTH := 2

# 类型色彩映射
const TYPE_COLORS := {
	"工作卡": Color("#2ecc71"),
	"陷害卡": Color("#e74c3c"),
	"联盟卡": Color("#3498db"),
	"特殊卡": Color("#f39c12")
}
const TYPE_BG_COLORS := {
	"工作卡": Color("#1a3a25"),
	"陷害卡": Color("#3a1a1a"),
	"联盟卡": Color("#1a253a"),
	"特殊卡": Color("#3a301a")
}
const TYPE_ICONS := {
	"工作卡": "📄",
	"陷害卡": "⚔️",
	"联盟卡": "🤝",
	"特殊卡": "✨"
}

# 子节点引用
var _main_vbox: VBoxContainer
var _cost_badge: Label
var _icon_label: Label
var _name_label: Label
var _type_label: Label
var _border_highlight: int = 0

func _init(p_card_id: String = "") -> void:
	if not p_card_id.is_empty():
		setup_card(p_card_id)

func setup_card(p_card_id: String) -> void:
	card_id = p_card_id
	card_data = CardManager.get_card_info(card_id)
	
	custom_minimum_size = CARD_SIZE
	toggle_mode = true
	
	_build_visual()
	_apply_styles()
	_connect_signals()


func _build_visual() -> void:
	# 清除旧子节点
	for child in get_children():
		child.queue_free()
	
	_main_vbox = VBoxContainer.new()
	_main_vbox.alignment = ALIGNMENT_CENTER
	_main_vbox.add_theme_constant_override("separation", 4)
	add_child(_main_vbox)
	
	var card_type = card_data.get("type", "")
	var card_name = card_data.get("name", "未知")
	var cost = card_data.get("cost", 0)
	
	# 费用徽章（左上角）
	_cost_badge = Label.new()
	_cost_badge.text = "💰" + str(cost) if cost > 0 else ""
	_cost_badge.add_theme_font_size_override("font_size", GameTheme.FONTS.label)
	_cost_badge.add_theme_color_override("font_color", GameTheme.COLORS.accent_orange)
	_cost_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_main_vbox.add_child(_cost_badge)
	
	# 间距
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 8)
	_main_vbox.add_child(spacer1)
	
	# 类型图标
	_icon_label = Label.new()
	_icon_label.text = TYPE_ICONS.get(card_type, "🃏")
	_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_icon_label.add_theme_font_size_override("font_size", 32)
	_main_vbox.add_child(_icon_label)
	
	# 间距
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 4)
	_main_vbox.add_child(spacer2)
	
	# 卡牌名称
	_name_label = Label.new()
	_name_label.text = card_name
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", GameTheme.FONTS.body_small)
	_name_label.add_theme_color_override("font_color", Color.WHITE)
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name_label.custom_minimum_size = Vector2(CARD_SIZE.x - 16, 0)
	_main_vbox.add_child(_name_label)
	
	# 类型标签
	_type_label = Label.new()
	_type_label.text = card_type
	_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_type_label.add_theme_font_size_override("font_size", GameTheme.FONTS.label)
	_type_label.add_theme_color_override("font_color", TYPE_COLORS.get(card_type, Color.WHITE))
	_main_vbox.add_child(_type_label)


func _apply_styles() -> void:
	var card_type = card_data.get("type", "")
	var bg_color = TYPE_BG_COLORS.get(card_type, GameTheme.COLORS.bg_card)
	var border_color = TYPE_COLORS.get(card_type, GameTheme.COLORS.primary_light)
	
	# Normal
	var normal = StyleBoxFlat.new()
	normal.bg_color = bg_color
	normal.border_color = border_color
	normal.border_width_left = BORDER_WIDTH
	normal.border_width_top = BORDER_WIDTH
	normal.border_width_right = BORDER_WIDTH
	normal.border_width_bottom = BORDER_WIDTH
	normal.corner_radius_top_left = CORNER_RADIUS
	normal.corner_radius_top_right = CORNER_RADIUS
	normal.corner_radius_bottom_left = CORNER_RADIUS
	normal.corner_radius_bottom_right = CORNER_RADIUS
	add_theme_stylebox_override("normal", normal)
	
	# Hover
	var hover = StyleBoxFlat.new()
	hover.bg_color = bg_color.lightened(0.15)
	hover.border_color = border_color.lightened(0.3)
	hover.border_width_left = BORDER_WIDTH + 1
	hover.border_width_top = BORDER_WIDTH + 1
	hover.border_width_right = BORDER_WIDTH + 1
	hover.border_width_bottom = BORDER_WIDTH + 1
	hover.corner_radius_top_left = CORNER_RADIUS
	hover.corner_radius_top_right = CORNER_RADIUS
	hover.corner_radius_bottom_left = CORNER_RADIUS
	hover.corner_radius_bottom_right = CORNER_RADIUS
	hover.shadow_size = 8
	hover.shadow_color = Color(border_color, 0.4)
	add_theme_stylebox_override("hover", hover)
	
	# Pressed/Selected
	var selected = StyleBoxFlat.new()
	selected.bg_color = bg_color.lightened(0.1)
	selected.border_color = GameTheme.COLORS.accent_orange
	selected.border_width_left = 3
	selected.border_width_top = 3
	selected.border_width_right = 3
	selected.border_width_bottom = 3
	selected.corner_radius_top_left = CORNER_RADIUS
	selected.corner_radius_top_right = CORNER_RADIUS
	selected.corner_radius_bottom_left = CORNER_RADIUS
	selected.corner_radius_bottom_right = CORNER_RADIUS
	selected.shadow_size = 6
	selected.shadow_color = Color(GameTheme.COLORS.accent_orange, 0.5)
	add_theme_stylebox_override("pressed", selected)
	add_theme_stylebox_override("focus", selected)


func _connect_signals() -> void:
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _on_pressed() -> void:
	AudioManager.play_button_click()
	card_clicked.emit(card_id)


func _on_mouse_entered() -> void:
	AudioManager.play_button_hover()
	card_hovered.emit(card_id)
	
	# 升起动画
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "position:y", position.y - 4, 0.15)


func _on_mouse_exited() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "position:y", position.y + 4, 0.15)


## 设置高亮状态
func set_highlighted(highlighted: bool) -> void:
	if highlighted:
		# 脉冲动画边框
		_border_highlight = 3
	else:
		_border_highlight = 0


## 设置可用状态
func set_card_enabled(enabled: bool) -> void:
	disabled = not enabled
	modulate.a = 1.0 if enabled else 0.5


## 获取卡牌数据
func get_card_data() -> Dictionary:
	return card_data
