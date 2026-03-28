extends CanvasLayer
## TooltipManager - 全局提示框管理器
## 管理所有Tooltip的显示、定位和动画

var _current_tooltip: Control = null
var _target_control: Control = null
var _show_delay: float = 0.3
var _hide_delay: float = 0.1
var _fade_duration: float = 0.15

func _ready():
	layer = 100  # 确保在最上层
	process_mode = Node.PROCESS_MODE_ALWAYS  # 暂停时也处理

## 为控件注册Tooltip
func register_tooltip(control: Control, title: String, content: String, 
				   custom_data: Dictionary = {}) -> void:
	if not control:
		return
	
	# 存储tooltip数据
	control.set_meta("tooltip_title", title)
	control.set_meta("tooltip_content", content)
	control.set_meta("tooltip_custom", custom_data)
	
	# 连接信号（如果尚未连接）
	if not control.mouse_entered.is_connected(_on_control_mouse_entered):
		control.mouse_entered.connect(_on_control_mouse_entered.bind(control))
	if not control.mouse_exited.is_connected(_on_control_mouse_exited):
		control.mouse_exited.connect(_on_control_mouse_exited.bind(control))
	if not control.gui_input.is_connected(_on_control_gui_input):
		control.gui_input.connect(_on_control_gui_input.bind(control))

## 注销Tooltip
func unregister_tooltip(control: Control) -> void:
	if not control:
		return
	
	control.remove_meta("tooltip_title")
	control.remove_meta("tooltip_content")
	control.remove_meta("tooltip_custom")
	
	if control.mouse_entered.is_connected(_on_control_mouse_entered):
		control.mouse_entered.disconnect(_on_control_mouse_entered)
	if control.mouse_exited.is_connected(_on_control_mouse_exited):
		control.mouse_exited.disconnect(_on_control_mouse_exited)
	if control.gui_input.is_connected(_on_control_gui_input):
		control.gui_input.disconnect(_on_control_gui_input)

## 鼠标进入
func _on_control_mouse_entered(control: Control) -> void:
	_target_control = control
	
	# 延迟显示
	await get_tree().create_timer(_show_delay).timeout
	
	if _target_control == control and control.is_inside_tree():
		_show_tooltip(control)

## 鼠标离开
func _on_control_mouse_exited(control: Control) -> void:
	if _target_control == control:
		_target_control = null
		_hide_tooltip()

## GUI输入（处理点击）
func _on_control_gui_input(event: InputEvent, control: Control) -> void:
	if event is InputEventMouseButton and event.pressed:
		_hide_tooltip()

## 显示Tooltip
func _show_tooltip(control: Control) -> void:
	if _current_tooltip:
		_current_tooltip.queue_free()
		_current_tooltip = null
	
	var title = control.get_meta("tooltip_title", "")
	var content = control.get_meta("tooltip_content", "")
	var custom = control.get_meta("tooltip_custom", {})
	
	if title.is_empty() and content.is_empty():
		return
	
	_current_tooltip = _create_tooltip(title, content, custom)
	add_child(_current_tooltip)
	
	# 定位
	_position_tooltip(control)
	
	# 淡入动画
	_current_tooltip.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(_current_tooltip, "modulate:a", 1.0, _fade_duration)

## 隐藏Tooltip
func _hide_tooltip() -> void:
	if not _current_tooltip:
		return
	
	var tooltip = _current_tooltip
	_current_tooltip = null
	
	# 淡出动画
	var tween = create_tween()
	tween.tween_property(tooltip, "modulate:a", 0.0, _fade_duration)
	tween.finished.connect(func(): tooltip.queue_free())

## 创建Tooltip节点
func _create_tooltip(title: String, content: String, custom: Dictionary) -> Control:
	var panel = PanelContainer.new()
	
	# 样式
	var style = StyleBoxFlat.new()
	style.bg_color = GameTheme.COLORS.bg_panel
	style.border_color = GameTheme.COLORS.primary_light
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 4
	panel.add_theme_stylebox_override("panel", style)
	
	# 内容
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	
	# 标题
	if not title.is_empty():
		var title_label = Label.new()
		title_label.text = title
		title_label.add_theme_font_size_override("font_size", GameTheme.FONTS.body_medium)
		title_label.add_theme_color_override("font_color", GameTheme.COLORS.text_primary)
		vbox.add_child(title_label)
	
	# 分隔线
	if not title.is_empty() and not content.is_empty():
		var separator = ColorRect.new()
		separator.custom_minimum_size = Vector2(0, 1)
		separator.color = GameTheme.COLORS.primary_light
		vbox.add_child(separator)
	
	# 内容
	if not content.is_empty():
		var content_label = Label.new()
		content_label.text = content
		content_label.add_theme_font_size_override("font_size", GameTheme.FONTS.body_small)
		content_label.add_theme_color_override("font_color", GameTheme.COLORS.text_secondary)
		content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content_label.custom_minimum_size = Vector2(200, 0)
		vbox.add_child(content_label)
	
	# 自定义额外信息
	if custom.has("extra"):
		var extra_label = Label.new()
		extra_label.text = custom.extra
		extra_label.add_theme_font_size_override("font_size", GameTheme.FONTS.label)
		extra_label.add_theme_color_override("font_color", GameTheme.COLORS.accent_orange)
		vbox.add_child(extra_label)
	
	return panel

## 定位Tooltip
func _position_tooltip(target: Control) -> void:
	if not _current_tooltip:
		return
	
	var tooltip_size = _current_tooltip.get_minimum_size()
	var mouse_pos = get_viewport().get_mouse_position()
	var viewport_size = get_viewport().get_visible_rect().size
	
	# 默认在鼠标右下方
	var pos = mouse_pos + Vector2(16, 16)
	
	# 检查右边界
	if pos.x + tooltip_size.x > viewport_size.x:
		pos.x = mouse_pos.x - tooltip_size.x - 16
	
	# 检查下边界
	if pos.y + tooltip_size.y > viewport_size.y:
		pos.y = mouse_pos.y - tooltip_size.y - 16
	
	# 确保不超出左/上边界
	pos.x = max(0, pos.x)
	pos.y = max(0, pos.y)
	
	_current_tooltip.position = pos

## 每帧更新位置（跟随鼠标）
func _process(_delta: float) -> void:
	if _current_tooltip and _target_control:
		_position_tooltip(_target_control)

## 便捷方法：为卡牌注册Tooltip
func register_card_tooltip(card_button: Button, card_id: String) -> void:
	var card_info = CardManager.get_card_info(card_id)
	if card_info.is_empty():
		return
	
	var title = card_info.get("name", "")
	var content = card_info.get("description", "")
	var cost = card_info.get("cost", 0)
	
	if cost > 0:
		content += "\n\n费用: " + str(cost) + " 工资"
	
	register_tooltip(card_button, title, content)

## 便捷方法：为海克斯注册Tooltip
func register_hex_tooltip(hex_button: Button, hex_id: String) -> void:
	var hex_info = HexManager.get_hex_info(hex_id)
	if hex_info.is_empty():
		return
	
	var title = hex_info.get("name", "")
	var rarity = hex_info.get("rarity", "")
	var hex_type = hex_info.get("type", "")
	var description = hex_info.get("description", "")
	
	var content = "[%s] %s\n\n%s" % [
		_get_rarity_name(rarity),
		HexManager.get_type_name(hex_type),
		description
	]
	
	register_tooltip(hex_button, title, content)

func _get_rarity_name(rarity: String) -> String:
	match rarity:
		"common": return "普通"
		"rare": return "稀有"
		"epic": return "史诗"
		"legendary": return "传说"
		_: return "普通"
