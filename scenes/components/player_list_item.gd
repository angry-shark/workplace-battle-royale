class_name PlayerListItem
extends HBoxContainer
## PlayerListItem - 玩家列表项
## 显示单个玩家的头像和简要信息

var _avatar: AvatarDisplay
var _name_label: Label
var _status_label: Label

var player_id: int = -1

func _ready():
	_setup_ui()

func _setup_ui() -> void:
	add_theme_constant_override("separation", 8)
	
	# 头像
	_avatar = AvatarDisplay.new()
	_avatar.avatar_size = 40
	_avatar.show_border = true
	_avatar.border_width = 2
	add_child(_avatar)
	
	# 信息区域
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)
	add_child(vbox)
	
	# 玩家名
	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", GameTheme.FONTS.body_small)
	_name_label.add_theme_color_override("font_color", GameTheme.COLORS.text_primary)
	vbox.add_child(_name_label)
	
	# 状态（HP/KPI）
	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", GameTheme.FONTS.label)
	_status_label.add_theme_color_override("font_color", GameTheme.COLORS.text_secondary)
	vbox.add_child(_status_label)

func set_player(player: Player) -> void:
	player_id = player.player_id
	
	# 更新头像
	_avatar.set_profession(player.profession)
	_avatar.set_eliminated(not player.is_alive)
	
	# 更新名称
	_name_label.text = player.player_name
	
	# 更新状态
	if player.is_alive:
		_status_label.text = "HP:%d/%d | KPI:%d" % [player.current_hp, player.max_hp, player.current_kpi]
	else:
		_status_label.text = "已淘汰"
		_status_label.add_theme_color_override("font_color", GameTheme.COLORS.accent_red)

func update_status(player: Player) -> void:
	if player.player_id != player_id:
		return
	
	_avatar.set_eliminated(not player.is_alive)
	
	if player.is_alive:
		_status_label.text = "HP:%d/%d | KPI:%d" % [player.current_hp, player.max_hp, player.current_kpi]
	else:
		_status_label.text = "已淘汰"
		_status_label.add_theme_color_override("font_color", GameTheme.COLORS.accent_red)
