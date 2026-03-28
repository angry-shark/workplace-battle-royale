extends Control
## GameOverScreen - 游戏结束画面
## 显示战后统计和结果

enum ResultType {
	VICTORY,  # 胜利
	DEFEAT    # 失败
}

var _result: int = ResultType.DEFEAT
var _stats: Dictionary = {}

@onready var title_label: Label = $TitleLabel
@onready var result_icon: Label = $ResultIcon
@onready var stats_panel: Panel = $StatsPanel
@onready var stats_container: VBoxContainer = $StatsPanel/StatsContainer
@onready var achievements_panel: Panel = $AchievementsPanel
@onready var achievement_list: VBoxContainer = $AchievementsPanel/AchievementList
@onready var continue_button: Button = $ContinueButton
@onready var save_replay_button: Button = $SaveReplayButton

func _ready():
	_setup_ui()
	
	# 从GameManager读取结果
	if GameManager.has_meta("game_result"):
		_result = GameManager.get_meta("game_result")
	
	_load_game_stats()
	_display_results()

func set_result(result: int, stats: Dictionary = {}) -> void:
	_result = result
	_stats = stats

func _setup_ui() -> void:
	GameTheme.apply_panel_style(stats_panel)
	GameTheme.apply_panel_style(achievements_panel)
	GameTheme.apply_button_style(continue_button, "primary")
	GameTheme.apply_button_style(save_replay_button, "secondary")
	
	if not continue_button.pressed.is_connected(_on_continue_pressed):
		continue_button.pressed.connect(_on_continue_pressed)
	if not save_replay_button.pressed.is_connected(_on_save_replay_pressed):
		save_replay_button.pressed.connect(_on_save_replay_pressed)

func _load_game_stats() -> void:
	# 从PlayerData收集统计数据
	_stats = {
		"turns_survived": PlayerData.current_game_stats.get("turns_survived", 0),
		"kpi_earned": PlayerData.current_game_stats.get("kpi_earned", 0),
		"salary_earned": PlayerData.current_game_stats.get("salary_earned", 0),
		"cards_played": PlayerData.current_game_stats.get("cards_played", 0),
		"traps_placed": PlayerData.current_game_stats.get("traps_placed", 0),
		"traps_triggered": PlayerData.current_game_stats.get("traps_triggered", 0),
		"damage_dealt": PlayerData.current_game_stats.get("damage_dealt", 0),
		"damage_taken": PlayerData.current_game_stats.get("damage_taken", 0),
		"highest_rank": PlayerData.rank,
		"final_salary": PlayerData.total_salary,
		"is_victory": _result == ResultType.VICTORY
	}

func _display_results() -> void:
	# 显示胜利/失败
	if _result == ResultType.VICTORY:
		title_label.text = "胜利！"
		title_label.add_theme_color_override("font_color", GameTheme.COLORS.accent_green)
		result_icon.text = "🏆"
		AudioManager.play_victory()
	else:
		title_label.text = "失败"
		title_label.add_theme_color_override("font_color", GameTheme.COLORS.accent_red)
		result_icon.text = "💀"
		AudioManager.play_defeat()
	
	# 清空并填充统计
	for child in stats_container.get_children():
		child.queue_free()
	
	_add_stat_row("存活回合", str(_stats.turns_survived), "📅")
	_add_stat_row("累计绩效", str(_stats.kpi_earned), "📈")
	_add_stat_row("累计工资", str(_stats.salary_earned), "💰")
	_add_stat_row("最高职级", "P" + str(_stats.highest_rank), "⭐")
	_add_stat_row("使用卡牌", str(_stats.cards_played), "🃏")
	_add_stat_row("放置陷阱", str(_stats.traps_placed), "⚔️")
	_add_stat_row("陷阱触发", str(_stats.traps_triggered), "💥")
	_add_stat_row("造成伤害", str(_stats.damage_dealt), "⚡")
	_add_stat_row("受到伤害", str(_stats.damage_taken), "🩸")
	
	# 检查成就
	_check_achievements()

func _add_stat_row(label: String, value: String, icon: String = "") -> void:
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_container.add_child(hbox)
	
	var icon_label = Label.new()
	icon_label.text = icon + " " if not icon.is_empty() else ""
	icon_label.custom_minimum_size = Vector2(30, 0)
	hbox.add_child(icon_label)
	
	var name_label = Label.new()
	name_label.text = label
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", GameTheme.COLORS.text_secondary)
	hbox.add_child(name_label)
	
	var value_label = Label.new()
	value_label.text = value
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_font_size_override("font_size", GameTheme.FONTS.body_medium)
	value_label.add_theme_color_override("font_color", GameTheme.COLORS.text_primary)
	hbox.add_child(value_label)

func _check_achievements() -> void:
	# 清空成就列表
	for child in achievement_list.get_children():
		child.queue_free()
	
	var unlocked: Array[String] = []
	
	# 检查各项成就
	if _stats.turns_survived >= 10:
		unlocked.append("初出茅庐 - 存活10回合")
	
	if _stats.turns_survived >= 30:
		unlocked.append("职场老兵 - 存活30回合")
	
	if _stats.highest_rank >= 7:
		unlocked.append("专家之路 - 晋升至P7")
	
	if _stats.highest_rank >= 10:
		unlocked.append("管理层 - 晋升至P10")
	
	if _stats.highest_rank >= 12:
		unlocked.append("P12传奇 - 晋升至最高职级")
	
	if _stats.salary_earned >= 5000:
		unlocked.append("小资生活 - 累计获得5000工资")
	
	if _stats.salary_earned >= 10000:
		unlocked.append("财务自由 - 累计获得10000工资")
	
	if _stats.traps_placed >= 5:
		unlocked.append("老六初现 - 放置5个陷阱")
	
	if _stats.traps_placed >= 15:
		unlocked.append("陷阱大师 - 放置15个陷阱")
	
	if _stats.traps_triggered >= 3:
		unlocked.append("一箭双雕 - 陷阱触发3次")
	
	if _result == ResultType.VICTORY and _stats.traps_placed == 0:
		unlocked.append("和平主义者 - 不陷害任何人获胜")
	
	if _result == ResultType.VICTORY:
		unlocked.append("最后打工人 - 获得游戏胜利")
	
	# 显示成就
	if unlocked.is_empty():
		var no_achievement = Label.new()
		no_achievement.text = "本次游戏未解锁新成就"
		no_achievement.add_theme_color_override("font_color", GameTheme.COLORS.text_secondary)
		achievement_list.add_child(no_achievement)
	else:
		for achievement in unlocked:
			var label = Label.new()
			label.text = "🏅 " + achievement
			label.add_theme_color_override("font_color", GameTheme.COLORS.accent_orange)
			achievement_list.add_child(label)
	
	# 保存统计数据
	_save_stats_to_history()

func _save_stats_to_history() -> void:
	# 更新玩家统计数据
	PlayerData.stats["games_played"] += 1
	
	if _result == ResultType.VICTORY:
		PlayerData.stats["games_won"] += 1
	
	if _stats.highest_rank > PlayerData.stats.get("highest_rank_reached", 0):
		PlayerData.stats["highest_rank_reached"] = _stats.highest_rank
	
	if _stats.salary_earned > PlayerData.stats.get("highest_salary_earned", 0):
		PlayerData.stats["highest_salary_earned"] = _stats.salary_earned
	
	if _stats.turns_survived > PlayerData.stats.get("longest_survival_turns", 0):
		PlayerData.stats["longest_survival_turns"] = _stats.turns_survived
	
	PlayerData.stats["total_eliminations"] += _stats.traps_triggered
	PlayerData.stats["traps_triggered"] += _stats.traps_triggered
	
	# 保存到文件
	SaveManager.save_stats()

func _on_continue_pressed() -> void:
	AudioManager.play_button_click()
	GameManager.return_to_menu()

func _on_save_replay_pressed() -> void:
	AudioManager.play_button_click()
	
	# 保存本场游戏数据到文件
	var replay_data = {
		"timestamp": Time.get_datetime_string_from_system(),
		"result": "victory" if _result == ResultType.VICTORY else "defeat",
		"stats": _stats
	}
	
	var filename = "user://replays/replay_" + str(Time.get_unix_time_from_system()) + ".json"
	
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("replays"):
		dir.make_dir("replays")
	
	var file = FileAccess.open(filename, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(replay_data, "\t"))
		file.close()
		_show_message("战报已保存！")
	else:
		_show_message("保存失败！", true)

func _show_message(text: String, is_error: bool = false) -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "提示"
	dialog.dialog_text = text
	add_child(dialog)
	dialog.popup_centered()
