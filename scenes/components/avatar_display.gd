class_name AvatarDisplay
extends Control
## AvatarDisplay - 角色头像显示组件
## 显示职业头像，支持灰度效果（淘汰状态）

# 职业对应的Emoji（作为后备）
const PROFESSION_EMOJI: Dictionary = {
	Config.Profession.PROGRAMMER: "👨‍💻",
	Config.Profession.HR: "👩‍💼",
	Config.Profession.FINANCE: "👨‍💼",
	Config.Profession.OPERATIONS: "👩‍💻",
	Config.Profession.SALES: "👨‍💼"
}

# 职业对应的颜色
const PROFESSION_COLORS: Dictionary = {
	Config.Profession.PROGRAMMER: Color("#2ecc71"),
	Config.Profession.HR: Color("#9b59b6"),
	Config.Profession.FINANCE: Color("#34495e"),
	Config.Profession.OPERATIONS: Color("#e67e22"),
	Config.Profession.SALES: Color("#e74c3c")
}

# 节点引用
var _avatar_icon: Label
var _bg_rect: ColorRect
var _border_rect: ColorRect
var _eliminated_overlay: ColorRect

# 当前状态
var _profession: int = Config.Profession.PROGRAMMER
var _is_eliminated: bool = false
var _is_highlighted: bool = false

@export var avatar_size: int = 64
@export var show_border: bool = true
@export var border_width: int = 3

func _ready():
	_setup_ui()
	_update_appearance()

func _setup_ui() -> void:
	custom_minimum_size = Vector2(avatar_size, avatar_size)
	
	# 背景
	_bg_rect = ColorRect.new()
	_bg_rect.size = Vector2(avatar_size, avatar_size)
	_bg_rect.color = Color("#1a1a2e")
	add_child(_bg_rect)
	
	# 边框（ColorRect作为边框）
	if show_border:
		_border_rect = ColorRect.new()
		_border_rect.size = Vector2(avatar_size, avatar_size)
		_border_rect.color = PROFESSION_COLORS.get(_profession, Color.WHITE)
		add_child(_border_rect)
		
		# 内部头像区域
		_avatar_icon = Label.new()
		_avatar_icon.size = Vector2(avatar_size - border_width * 2, avatar_size - border_width * 2)
		_avatar_icon.position = Vector2(border_width, border_width)
	else:
		_avatar_icon = Label.new()
		_avatar_icon.size = Vector2(avatar_size, avatar_size)
	
	_avatar_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_avatar_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_avatar_icon.add_theme_font_size_override("font_size", avatar_size * 0.6)
	add_child(_avatar_icon)
	
	# 淘汰遮罩
	_eliminated_overlay = ColorRect.new()
	_eliminated_overlay.size = Vector2(avatar_size, avatar_size)
	_eliminated_overlay.color = Color(0, 0, 0, 0.6)
	_eliminated_overlay.visible = false
	add_child(_eliminated_overlay)
	
	# 淘汰标记
	var eliminated_label = Label.new()
	eliminated_label.name = "EliminatedLabel"
	eliminated_label.text = "💀"
	eliminated_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eliminated_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	eliminated_label.add_theme_font_size_override("font_size", avatar_size * 0.5)
	eliminated_label.size = Vector2(avatar_size, avatar_size)
	eliminated_label.visible = false
	_eliminated_overlay.add_child(eliminated_label)

## 设置职业
func set_profession(profession: int) -> void:
	_profession = profession
	if _avatar_icon:
		_update_appearance()

## 设置淘汰状态
func set_eliminated(eliminated: bool) -> void:
	_is_eliminated = eliminated
	_eliminated_overlay.visible = eliminated
	
	if eliminated:
		# 灰度效果
		_avatar_icon.modulate = Color(0.5, 0.5, 0.5)
		if _border_rect:
			_border_rect.color = Color(0.3, 0.3, 0.3)
	else:
		_avatar_icon.modulate = Color.WHITE
		_update_appearance()

## 设置高亮状态
func set_highlighted(highlighted: bool) -> void:
	_is_highlighted = highlighted
	
	if highlighted:
		# 发光效果
		if _border_rect:
			var tween = create_tween()
			tween.tween_property(_border_rect, "color", Color.WHITE, 0.2)
	else:
		_update_appearance()

## 更新外观
func _update_appearance() -> void:
	if not _avatar_icon:
		return
	# 设置头像图标（使用Emoji作为后备）
	var emoji = PROFESSION_EMOJI.get(_profession, "👤")
	_avatar_icon.text = emoji
	
	# 设置边框颜色
	if _border_rect:
		var color = PROFESSION_COLORS.get(_profession, Color.WHITE)
		_border_rect.color = color

## 获取职业颜色
static func get_profession_color(profession: int) -> Color:
	return PROFESSION_COLORS.get(profession, Color.WHITE)

## 便捷方法：从Player设置
func set_from_player(player: Player) -> void:
	set_profession(player.profession)
	set_eliminated(not player.is_alive)
