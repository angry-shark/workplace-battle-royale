class_name Tooltip
extends PanelContainer
## Tooltip - 提示框组件
## 跟随鼠标显示提示信息

const PADDING: Vector2 = Vector2(12, 8)
const OFFSET: Vector2 = Vector2(16, 16)

var _title_label: Label
var _content_label: Label

func _init():
	_setup_appearance()
	_create_content()

func _setup_appearance():
	# 设置样式
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
	add_theme_stylebox_override("panel", style)
	
	# 初始隐藏
	visible = false
	z_index = 100  # 确保在最上层

func _create_content():
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	add_child(vbox)
	
	# 标题
	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", GameTheme.FONTS.body_medium)
	_title_label.add_theme_color_override("font_color", GameTheme.COLORS.text_primary)
	vbox.add_child(_title_label)
	
	# 内容
	_content_label = Label.new()
	_content_label.add_theme_font_size_override("font_size", GameTheme.FONTS.body_small)
	_content_label.add_theme_color_override("font_color", GameTheme.COLORS.text_secondary)
	_content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content_label.custom_minimum_size = Vector2(200, 0)
	vbox.add_child(_content_label)

## 显示提示
func show_tooltip(title: String, content: String, position: Vector2):
	_title_label.text = title
	_content_label.text = content
	
	# 计算位置（避免超出屏幕）
	var viewport_size = get_viewport_rect().size
	var size = get_minimum_size()
	
	var final_pos = position + OFFSET
	if final_pos.x + size.x > viewport_size.x:
		final_pos.x = position.x - size.x - OFFSET.x
	if final_pos.y + size.y > viewport_size.y:
		final_pos.y = position.y - size.y - OFFSET.y
	
	global_position = final_pos
	visible = true

## 隐藏提示
func hide_tooltip():
	visible = false

## 静态方法：快速创建并显示
static func create_and_show(parent: Node, title: String, content: String, position: Vector2) -> Tooltip:
	var tooltip = Tooltip.new()
	parent.add_child(tooltip)
	tooltip.show_tooltip(title, content, position)
	return tooltip
