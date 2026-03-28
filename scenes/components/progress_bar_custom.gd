@tool
extends ProgressBar
## ProgressBarCustom - 自定义进度条
## 支持渐变色、数值标签、多种样式

@export var show_value_label: bool = true
@export var value_format: String = "%d/%d"
@export var use_gradient: bool = true

var _label: Label
var _gradient: Gradient

func _ready():
	_setup_appearance()
	if show_value_label:
		_create_label()
	_update_appearance()

func _setup_appearance():
	# 设置基础样式
	var fg_style = StyleBoxFlat.new()
	var bg_style = StyleBoxFlat.new()
	
	bg_style.bg_color = GameTheme.COLORS.bg_dark
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	
	fg_style.corner_radius_top_left = 4
	fg_style.corner_radius_top_right = 4
	fg_style.corner_radius_bottom_left = 4
	fg_style.corner_radius_bottom_right = 4
	
	add_theme_stylebox_override("background", bg_style)
	
	# 创建渐变色
	_gradient = Gradient.new()
	_gradient.add_point(0.0, GameTheme.COLORS.accent_green)
	_gradient.add_point(0.5, GameTheme.COLORS.accent_orange)
	_gradient.add_point(1.0, GameTheme.COLORS.accent_red)

func _create_label():
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_color_override("font_color", GameTheme.COLORS.text_primary)
	_label.add_theme_font_size_override("font_size", GameTheme.FONTS.body_small)
	
	# 将标签添加到进度条
	add_child(_label)
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)

func _update_appearance():
	if use_gradient:
		var ratio = value / max_value if max_value > 0 else 0
		var color = _gradient.sample(ratio)
		
		var fg_style = StyleBoxFlat.new()
		fg_style.bg_color = color
		fg_style.corner_radius_top_left = 4
		fg_style.corner_radius_top_right = 4
		fg_style.corner_radius_bottom_left = 4
		fg_style.corner_radius_bottom_right = 4
		add_theme_stylebox_override("fill", fg_style)
	
	if _label:
		_label.text = value_format % [value, max_value]

func set_value_silent(new_value: float):
	value = new_value
	_update_appearance()

func _on_value_changed(_new_value: float):
	_update_appearance()
