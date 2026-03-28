extends PanelContainer
## PlayerInfoPanel - 玩家信息面板
## 显示玩家HP、KPI、薪资、职级等关键信息

var _avatar: AvatarDisplay
var _hp_bar: ProgressBar
var _kpi_bar: ProgressBar
var _salary_label: Label
var _rank_label: Label
var _profession_icon: Label
var _name_label: Label

func _ready():
	_setup_ui()
	_connect_signals()

func _setup_ui() -> void:
	# 应用主题
	GameTheme.apply_panel_style(self)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)
	
	# 头像和基本信息横向排列
	var top_row = HBoxContainer.new()
	vbox.add_child(top_row)
	
	# 头像
	_avatar = AvatarDisplay.new()
	_avatar.avatar_size = 64
	_avatar.show_border = true
	_avatar.border_width = 3
	top_row.add_child(_avatar)
	
	# 玩家名称和职级
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 4)
	top_row.add_child(info_vbox)
	
	var header = HBoxContainer.new()
	info_vbox.add_child(header)
	
	_profession_icon = Label.new()
	_profession_icon.text = "💻"
	_profession_icon.add_theme_font_size_override("font_size", 20)
	header.add_child(_profession_icon)
	
	_name_label = Label.new()
	_name_label.text = "打工人"
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.add_theme_font_size_override("font_size", GameTheme.FONTS.body_large)
	_name_label.add_theme_color_override("font_color", GameTheme.COLORS.text_primary)
	header.add_child(_name_label)
	
	# 职级标签
	_rank_label = Label.new()
	_rank_label.text = "P3"
	_rank_label.add_theme_font_size_override("font_size", GameTheme.FONTS.body_medium)
	_rank_label.add_theme_color_override("font_color", GameTheme.COLORS.accent_orange)
	header.add_child(_rank_label)
	
	# HP条
	var hp_label = Label.new()
	hp_label.text = "HP"
	hp_label.add_theme_color_override("font_color", GameTheme.COLORS.text_secondary)
	vbox.add_child(hp_label)
	
	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(_hp_bar)
	
	# KPI条
	var kpi_header = HBoxContainer.new()
	vbox.add_child(kpi_header)
	
	var kpi_label = Label.new()
	kpi_label.text = "KPI"
	kpi_label.add_theme_color_override("font_color", GameTheme.COLORS.text_secondary)
	kpi_header.add_child(kpi_label)
	
	var kpi_promotion_label = Label.new()
	kpi_promotion_label.name = "PromotionLabel"
	kpi_promotion_label.text = ""
	kpi_promotion_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kpi_promotion_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	kpi_promotion_label.add_theme_color_override("font_color", GameTheme.COLORS.accent_green)
	kpi_header.add_child(kpi_promotion_label)
	
	_kpi_bar = ProgressBar.new()
	_kpi_bar.custom_minimum_size = Vector2(0, 16)
	vbox.add_child(_kpi_bar)
	
	# 薪资
	var salary_hbox = HBoxContainer.new()
	vbox.add_child(salary_hbox)
	
	var salary_title = Label.new()
	salary_title.text = "💰 总资产:"
	salary_title.add_theme_color_override("font_color", GameTheme.COLORS.text_secondary)
	salary_hbox.add_child(salary_title)
	
	_salary_label = Label.new()
	_salary_label.text = "0"
	_salary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_salary_label.add_theme_font_size_override("font_size", GameTheme.FONTS.body_medium)
	_salary_label.add_theme_color_override("font_color", GameTheme.COLORS.accent_orange)
	salary_hbox.add_child(_salary_label)

func _connect_signals() -> void:
	EventBus.player_hp_changed.connect(_on_hp_changed)
	EventBus.player_kpi_changed.connect(_on_kpi_changed)
	EventBus.player_salary_changed.connect(_on_salary_changed)
	EventBus.player_promoted.connect(_on_promoted)

func update_player(player = null) -> void:
	if not player:
		player = PlayerData
	
	# 更新头像
	_avatar.set_profession(player.profession)
	_avatar.set_eliminated(not player.is_alive)
	
	# 更新名称
	_name_label.text = player.player_name
	
	# 更新职业图标
	match player.profession:
		Config.Profession.PROGRAMMER:
			_profession_icon.text = "💻"
		Config.Profession.HR:
			_profession_icon.text = "📋"
		Config.Profession.FINANCE:
			_profession_icon.text = "💰"
		Config.Profession.OPERATIONS:
			_profession_icon.text = "📊"
		Config.Profession.SALES:
			_profession_icon.text = "📞"
	
	# 更新职级
	_rank_label.text = "P" + str(player.rank)
	
	# 更新HP
	_hp_bar.max_value = player.max_hp
	_hp_bar.value = player.current_hp
	
	# 更新KPI
	var required_kpi = LevelSystem.get_promotion_kpi(player.rank)
	_kpi_bar.max_value = required_kpi
	_kpi_bar.value = player.current_kpi
	
	# 更新晋升进度提示和KPI条颜色
	var promotion_label = _kpi_bar.get_parent().get_node_or_null("PromotionLabel")
	var progress = LevelSystem.get_promotion_progress(player.rank, player.current_kpi)
	if promotion_label:
		if progress >= 1.0:
			promotion_label.text = "可晋升!"
		else:
			promotion_label.text = "%.0f%%" % (progress * 100)
	
	# 更新KPI条颜色
	var fg_style = StyleBoxFlat.new()
	if progress >= 1.0:
		fg_style.bg_color = GameTheme.COLORS.accent_green
	elif progress >= 0.7:
		fg_style.bg_color = GameTheme.COLORS.accent_orange
	else:
		fg_style.bg_color = GameTheme.COLORS.accent_blue
	fg_style.corner_radius_top_left = 4
	fg_style.corner_radius_top_right = 4
	fg_style.corner_radius_bottom_left = 4
	fg_style.corner_radius_bottom_right = 4
	_kpi_bar.add_theme_stylebox_override("fill", fg_style)
	
	# 更新薪资
	_salary_label.text = str(player.total_salary)

func _on_hp_changed(player_id: int, current: int, max_hp: int) -> void:
	if player_id == 0 and _hp_bar:  # 人类玩家
		_hp_bar.max_value = max_hp
		_hp_bar.value = current

func _on_kpi_changed(player_id: int, kpi: int) -> void:
	if player_id == 0 and _kpi_bar:
		update_player()

func _on_salary_changed(player_id: int, salary: int) -> void:
	if player_id == 0 and _salary_label:
		_salary_label.text = str(PlayerData.total_salary)

func _on_promoted(player_id: int, new_rank: int) -> void:
	if player_id == 0 and _rank_label:
		_rank_label.text = "P" + str(new_rank)
		update_player()
