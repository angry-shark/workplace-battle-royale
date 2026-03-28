extends HBoxContainer
## AvatarSelector - 头像选择器
## 在角色选择界面显示可选职业的头像

signal profession_selected(profession_id: int)

var _avatar_buttons: Dictionary = {}  # profession_id -> AvatarDisplay
var _selected_profession: int = Config.Profession.PROGRAMMER

@export var avatar_size: int = 80

func _ready():
	_setup_avatars()

func _setup_avatars() -> void:
	# 清除现有
	for child in get_children():
		child.queue_free()
	_avatar_buttons.clear()
	
	# 创建每个职业的头像按钮
	var professions = [
		{"id": Config.Profession.PROGRAMMER, "name": "程序员"},
		{"id": Config.Profession.HR, "name": "HR"},
		{"id": Config.Profession.FINANCE, "name": "财务"},
		{"id": Config.Profession.OPERATIONS, "name": "运营"},
		{"id": Config.Profession.SALES, "name": "销售"}
	]
	
	for prof in professions:
		var container = VBoxContainer.new()
		container.add_theme_constant_override("separation", 4)
		add_child(container)
		
		# 头像按钮
		var btn = Button.new()
		btn.name = "ProfBtn_" + str(prof.id)
		btn.custom_minimum_size = Vector2(avatar_size, avatar_size)
		btn.toggle_mode = true
		btn.button_pressed = (prof.id == _selected_profession)
		
		# 创建头像显示
		var avatar = AvatarDisplay.new()
		avatar.avatar_size = avatar_size - 8  # 留出按钮边框空间
		avatar.set_profession(prof.id)
		avatar.show_border = true
		avatar.border_width = 4
		
		# 如果选中，高亮
		if prof.id == _selected_profession:
			avatar.set_highlighted(true)
		
		btn.add_child(avatar)
		_avatar_buttons[prof.id] = avatar
		
		# 连接信号
		btn.pressed.connect(_on_profession_selected.bind(prof.id))
		
		container.add_child(btn)
		
		# 职业名称标签
		var label = Label.new()
		label.text = prof.name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", GameTheme.FONTS.body_small)
		label.add_theme_color_override("font_color", 
			GameTheme.COLORS.text_primary if prof.id == _selected_profession 
			else GameTheme.COLORS.text_secondary)
		label.name = "Label_" + str(prof.id)
		container.add_child(label)

func _on_profession_selected(profession_id: int) -> void:
	AudioManager.play_button_click()
	
	_selected_profession = profession_id
	
	# 更新所有头像状态
	for id in _avatar_buttons:
		var avatar = _avatar_buttons[id]
		var is_selected = (id == profession_id)
		
		# 获取父按钮
		var btn = avatar.get_parent()
		if btn is Button:
			btn.button_pressed = is_selected
		
		# 更新高亮
		avatar.set_highlighted(is_selected)
		
		# 更新标签颜色
		var label = btn.get_parent().get_node_or_null("Label_" + str(id))
		if label:
			label.add_theme_color_override("font_color",
				GameTheme.COLORS.text_primary if is_selected 
				else GameTheme.COLORS.text_secondary)
	
	profession_selected.emit(profession_id)

func get_selected_profession() -> int:
	return _selected_profession

func set_selected_profession(profession_id: int) -> void:
	if profession_id in _avatar_buttons:
		_on_profession_selected(profession_id)
