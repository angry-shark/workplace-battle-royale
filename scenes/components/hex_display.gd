class_name HexDisplay
extends GridContainer
## HexDisplay - 海克斯显示组件
## 显示玩家当前拥有的海克斯科技

var _hex_items: Dictionary = {}  # hex_id -> Control

@export var hex_size: int = 48
@export var hex_spacing: int = 8

func _ready():
	columns = 4
	add_theme_constant_override("h_separation", hex_spacing)
	add_theme_constant_override("v_separation", hex_spacing)

## 设置海克斯列表
func set_hexes(hex_ids: Array[String]) -> void:
	# 清除现有
	for child in get_children():
		child.queue_free()
	_hex_items.clear()
	
	# 创建海克斯图标
	for hex_id in hex_ids:
		_add_hex_icon(hex_id)

## 添加单个海克斯图标
func _add_hex_icon(hex_id: String) -> void:
	var hex_info = HexManager.get_hex_info(hex_id)
	if hex_info.is_empty():
		return
	
	var button = Button.new()
	button.name = "Hex_" + hex_id
	button.custom_minimum_size = Vector2(hex_size, hex_size)
	button.tooltip_text = hex_info.get("name", "")
	
	# 应用样式
	_apply_hex_style(button, hex_info.get("rarity", "common"))
	
	# 图标
	var icon = Label.new()
	icon.text = _get_hex_icon(hex_info.get("type", ""))
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 24)
	button.add_child(icon)
	
	# 连接信号
	button.mouse_entered.connect(_on_hex_hovered.bind(hex_id, hex_info))
	
	add_child(button)
	_hex_items[hex_id] = button

## 获取海克斯类型图标
func _get_hex_icon(hex_type: String) -> String:
	match hex_type:
		"survival":
			return "🛡️"
		"performance":
			return "⚡"
		"strategy":
			return "🧠"
		"economy":
			return "💰"
		_:
			return "⭐"

## 应用海克斯样式（根据稀有度）
func _apply_hex_style(button: Button, rarity: String) -> void:
	var style = StyleBoxFlat.new()
	var color = HexManager.get_rarity_color(rarity)
	
	style.bg_color = color.darkened(0.5)
	style.border_color = color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	
	# 传说海克斯添加发光效果
	if rarity == "legendary":
		style.shadow_color = color
		style.shadow_size = 4
	
	# 六边形效果（近似）
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	
	button.add_theme_stylebox_override("normal", style)
	
	# 悬停效果
	var hover_style = style.duplicate()
	hover_style.bg_color = color.darkened(0.3)
	button.add_theme_stylebox_override("hover", hover_style)

## 海克斯悬停
func _on_hex_hovered(hex_id: String, hex_info: Dictionary) -> void:
	var title = hex_info.get("name", "")
	var rarity = hex_info.get("rarity", "common")
	var hex_type = hex_info.get("type", "")
	var duration = hex_info.get("duration", "quarter")
	var description = hex_info.get("description", "")
	
	var content = "[%s] %s\n持续时间: %s\n\n%s" % [
		HexManager.get_type_name(hex_type),
		_get_rarity_name(rarity),
		"永久" if duration == "permanent" else "本季度",
		description
	]
	
	print("Hex tooltip: ", title, " - ", content)

## 获取稀有度名称
func _get_rarity_name(rarity: String) -> String:
	match rarity:
		"common":
			return "普通"
		"rare":
			return "稀有"
		"epic":
			return "史诗"
		"legendary":
			return "传说"
		_:
			return "普通"

## 添加海克斯
func add_hex(hex_id: String) -> void:
	if not _hex_items.has(hex_id):
		_add_hex_icon(hex_id)

## 移除海克斯
func remove_hex(hex_id: String) -> void:
	if _hex_items.has(hex_id):
		_hex_items[hex_id].queue_free()
		_hex_items.erase(hex_id)

## 清空所有海克斯
func clear_hexes() -> void:
	for child in get_children():
		child.queue_free()
	_hex_items.clear()
