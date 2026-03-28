extends Control
## CharacterSelect - 角色选择场景
## 玩家选择职业和初始职级

@onready var title_label: Label = $TitleLabel
@onready var profession_list: VBoxContainer = $ProfessionList
@onready var rank_selector: OptionButton = $RankSelector
@onready var start_button: Button = $StartButton
@onready var back_button: Button = $BackButton
@onready var info_panel: Panel = $InfoPanel
@onready var info_title: Label = $InfoPanel/InfoTitle
@onready var info_description: Label = $InfoPanel/InfoDescription
@onready var info_stats: VBoxContainer = $InfoPanel/InfoStats

var _selected_profession: int = Config.Profession.PROGRAMMER
var _selected_rank: int = Config.Rank.P3

func _ready():
	print("CharacterSelect loaded")
	_setup_ui()
	_setup_profession_buttons()
	_setup_rank_selector()
	_update_info_panel()

func _setup_ui():
	# 应用主题样式
	GameTheme.apply_panel_style($InfoPanel)
	GameTheme.apply_button_style(start_button, "primary")
	GameTheme.apply_button_style(back_button, "secondary")
	
	# 设置标题
	title_label.add_theme_font_size_override("font_size", GameTheme.FONTS.title_large)
	title_label.add_theme_color_override("font_color", GameTheme.COLORS.text_primary)

func _setup_profession_buttons():
	# 清除现有按钮
	for child in profession_list.get_children():
		child.queue_free()
	
	# 创建头像选择器
	var avatar_selector = load("res://scenes/character_select/avatar_selector.gd").new()
	avatar_selector.name = "AvatarSelector"
	avatar_selector.profession_selected.connect(_on_profession_selected)
	profession_list.add_child(avatar_selector)

func _apply_profession_button_style(button: Button, color: Color, is_selected: bool):
	var normal_style = StyleBoxFlat.new()
	var hover_style = StyleBoxFlat.new()
	var pressed_style = StyleBoxFlat.new()
	
	if is_selected:
		normal_style.bg_color = color.darkened(0.3)
		normal_style.border_color = color
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
	
	hover_style.bg_color = color.darkened(0.5)
	pressed_style.bg_color = color.darkened(0.4)
	
	for style in [normal_style, hover_style, pressed_style]:
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
	
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_color_override("font_color", GameTheme.COLORS.text_primary)

func _setup_rank_selector():
	rank_selector.clear()
	
	for rank in range(Config.Rank.P1, Config.Rank.P12 + 1):
		var salary = LevelSystem.get_salary(rank)
		var card_count = LevelSystem.get_strategy_card_count(rank)
		rank_selector.add_item("P%d (工资:%d 卡牌:%d)" % [rank, salary, card_count], rank)
	
	rank_selector.selected = _selected_rank - 1
	rank_selector.item_selected.connect(_on_rank_selected)

func _on_profession_selected(profession_id: int):
	_selected_profession = profession_id
	_update_info_panel()

func _on_rank_selected(index: int):
	_selected_rank = index + 1
	_update_info_panel()

func _update_info_panel():
	var prof_data = ConfigLoader.load_profession(_selected_profession)
	
	info_title.text = prof_data.get("name", "未知职业")
	info_description.text = prof_data.get("description", "")
	
	# 清空并更新属性列表
	for child in info_stats.get_children():
		child.queue_free()
	
	# 基础属性
	_add_stat_row("初始HP:", str(prof_data.get("base_hp", 100)))
	_add_stat_row("基础绩效:", str(prof_data.get("base_kpi", 10)))
	_add_stat_row("初始工资:", str(LevelSystem.get_salary(_selected_rank)))
	_add_stat_row("策略卡数:", str(LevelSystem.get_strategy_card_count(_selected_rank)))
	
	# 被动技能
	var passive = prof_data.get("passive", {})
	if not passive.is_empty():
		_add_stat_row("被动:", passive.get("name", ""), true)
		_add_stat_row("  Buff:", passive.get("buff", ""))
		_add_stat_row("  Debuff:", passive.get("debuff", ""))

func _add_stat_row(label: String, value: String, is_header: bool = false):
	var hbox = HBoxContainer.new()
	
	var label_node = Label.new()
	label_node.text = label
	label_node.add_theme_color_override("font_color", GameTheme.COLORS.text_secondary)
	if is_header:
		label_node.add_theme_font_size_override("font_size", GameTheme.FONTS.body_medium)
		label_node.add_theme_color_override("font_color", GameTheme.COLORS.accent_orange)
	hbox.add_child(label_node)
	
	var value_node = Label.new()
	value_node.text = value
	value_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value_node.add_theme_color_override("font_color", GameTheme.COLORS.text_primary)
	hbox.add_child(value_node)
	
	info_stats.add_child(hbox)

func _on_start_pressed():
	print("Starting game with profession:", _selected_profession, "rank:", _selected_rank)
	
	# 初始化玩家数据
	PlayerData.initialize_new_game(
		"打工人",
		_selected_profession,
		_selected_rank
	)
	
	# 开始游戏
	GameManager.start_game()

func _on_back_pressed():
	GameManager.return_to_menu()
