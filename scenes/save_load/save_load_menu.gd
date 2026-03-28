extends Control
## SaveLoadMenu - 存档/读档菜单
## 管理游戏存档的保存、加载、删除

enum Mode {
	SAVE,    # 保存模式
	LOAD     # 读取模式
}

var _mode: int = Mode.LOAD
var _selected_slot: String = ""

@onready var title_label: Label = $TitleLabel
@onready var slot_list: VBoxContainer = $SlotList
@onready var info_panel: Panel = $InfoPanel
@onready var info_title: Label = $InfoPanel/InfoTitle
@onready var info_details: Label = $InfoPanel/InfoDetails
@onready var confirm_button: Button = $ConfirmButton
@onready var delete_button: Button = $DeleteButton
@onready var back_button: Button = $BackButton

func _ready():
	_setup_ui()
	_refresh_slot_list()

func set_mode(mode: int) -> void:
	_mode = mode
	if mode == Mode.SAVE:
		title_label.text = "保存游戏"
		confirm_button.text = "保存"
	else:
		title_label.text = "读取游戏"
		confirm_button.text = "读取"

func _setup_ui() -> void:
	GameTheme.apply_panel_style($InfoPanel)
	GameTheme.apply_button_style(confirm_button, "primary")
	GameTheme.apply_button_style(delete_button, "danger")
	GameTheme.apply_button_style(back_button, "secondary")
	
	confirm_button.disabled = true
	delete_button.disabled = true

func _refresh_slot_list() -> void:
	# 清除现有按钮
	for child in slot_list.get_children():
		child.queue_free()
	
	# 获取所有存档
	var slots = SaveManager.get_save_slots()
	
	# 添加存档槽按钮
	for i in range(5):  # 5个存档槽
		var slot_name = "save_%d" % (i + 1)
		var has_data = slot_name in slots
		
		var btn = Button.new()
		btn.name = "Slot_" + slot_name
		btn.custom_minimum_size = Vector2(0, 60)
		btn.toggle_mode = true
		
		if has_data:
			var save_info = _get_save_info(slot_name)
			btn.text = "存档 %d - %s\n%s | 第%d回合" % [
				i + 1,
				save_info.get("player_name", "未知"),
				save_info.get("date", ""),
				save_info.get("turn", 0)
			]
		else:
			btn.text = "存档 %d - [空]" % (i + 1)
		
		_apply_slot_style(btn, false)
		
		btn.pressed.connect(_on_slot_selected.bind(slot_name, has_data))
		slot_list.add_child(btn)
	
	# 添加自动存档按钮
	var auto_btn = Button.new()
	auto_btn.name = "Slot_auto"
	auto_btn.custom_minimum_size = Vector2(0, 60)
	auto_btn.toggle_mode = true
	
	if "auto" in slots:
		var auto_info = _get_save_info("auto")
		auto_btn.text = "自动存档 - %s\n第%d回合" % [
			auto_info.get("date", ""),
			auto_info.get("turn", 0)
		]
	else:
		auto_btn.text = "自动存档 - [空]"
	
	_apply_slot_style(auto_btn, false)
	auto_btn.pressed.connect(_on_slot_selected.bind("auto", "auto" in slots))
	slot_list.add_child(auto_btn)

func _apply_slot_style(button: Button, is_selected: bool) -> void:
	var style = StyleBoxFlat.new()
	
	if is_selected:
		style.bg_color = GameTheme.COLORS.primary_light
		style.border_color = GameTheme.COLORS.accent_orange
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
	else:
		style.bg_color = GameTheme.COLORS.bg_card
		style.border_color = GameTheme.COLORS.primary_light
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
	
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("pressed", style)
	
	var hover_style = style.duplicate()
	hover_style.bg_color = GameTheme.COLORS.primary_light.lightened(0.1)
	button.add_theme_stylebox_override("hover", hover_style)

func _get_save_info(slot_name: String) -> Dictionary:
	var filename = SaveManager.SAVE_DIR + slot_name + ".json"
	
	if not FileAccess.file_exists(filename):
		return {}
	
	var file = FileAccess.open(filename, FileAccess.READ)
	if not file:
		return {}
	
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(content) == OK:
		var data = json.get_data()
		return {
			"player_name": data.get("player", {}).get("name", "未知"),
			"turn": data.get("game_state", {}).get("turn", 0),
			"date": data.get("timestamp", "").substr(0, 10),
			"profession": data.get("player", {}).get("profession", 0),
			"rank": data.get("player", {}).get("rank", 1),
			"hp": data.get("player", {}).get("hp", 100),
			"total_salary": data.get("player", {}).get("total_salary", 0)
		}
	
	return {}

func _on_slot_selected(slot_name: String, has_data: bool) -> void:
	AudioManager.play_button_click()
	
	_selected_slot = slot_name
	
	# 更新按钮样式
	for child in slot_list.get_children():
		if child is Button:
			_apply_slot_style(child, child.name == "Slot_" + slot_name)
	
	# 更新信息面板
	if has_data:
		var info = _get_save_info(slot_name)
		info_title.text = "存档信息"
		
		var prof_names = ["程序员", "HR", "财务", "运营", "销售"]
		var prof_name = prof_names[info.get("profession", 0)] if info.get("profession", 0) < 5 else "未知"
		
		info_details.text = """
玩家: %s
职业: %s
职级: P%d
HP: %d
总资产: %d
回合: 第%d回合
日期: %s
		""" % [
			info.get("player_name", "未知"),
			prof_name,
			info.get("rank", 1),
			info.get("hp", 100),
			info.get("total_salary", 0),
			info.get("turn", 0),
			info.get("date", "")
		]
		
		confirm_button.disabled = false
		delete_button.disabled = false
	else:
		info_title.text = "空存档"
		info_details.text = "此存档槽为空"
		
		if _mode == Mode.LOAD:
			confirm_button.disabled = true
		else:
			confirm_button.disabled = false
		
		delete_button.disabled = true

func _on_confirm_pressed() -> void:
	AudioManager.play_button_click()
	
	if _selected_slot.is_empty():
		return
	
	if _mode == Mode.SAVE:
		# 确认覆盖
		if SaveManager.has_save(_selected_slot):
			var dialog = ConfirmationDialog.new()
			dialog.title = "确认覆盖"
			dialog.dialog_text = "此存档已存在，是否覆盖？"
			dialog.confirmed.connect(_do_save)
			add_child(dialog)
			dialog.popup_centered()
		else:
			_do_save()
	else:
		_do_load()

func _do_save() -> void:
	if SaveManager.save_game(_selected_slot):
		AudioManager.play_success()
		EventBus.show_message("游戏已保存！", EventBus.MessageType.SUCCESS)
		_refresh_slot_list()
	else:
		AudioManager.play_error()
		EventBus.show_message("保存失败！", EventBus.MessageType.ERROR)

func _do_load() -> void:
	if SaveManager.load_game(_selected_slot):
		AudioManager.play_success()
		EventBus.show_message("游戏已加载！", EventBus.MessageType.SUCCESS)
		
		# 切换到游戏场景
		GameManager.set_state(Config.GameState.PLAYING)
		get_tree().change_scene_to_file("res://scenes/game/game_main.tscn")
	else:
		AudioManager.play_error()
		EventBus.show_message("加载失败！", EventBus.MessageType.ERROR)

func _on_delete_pressed() -> void:
	AudioManager.play_button_click()
	
	if _selected_slot.is_empty():
		return
	
	var dialog = ConfirmationDialog.new()
	dialog.title = "确认删除"
	dialog.dialog_text = "确定要删除此存档吗？此操作不可恢复。"
	dialog.confirmed.connect(_do_delete)
	add_child(dialog)
	dialog.popup_centered()

func _do_delete() -> void:
	if SaveManager.delete_save(_selected_slot):
		AudioManager.play_success()
		EventBus.show_message("存档已删除", EventBus.MessageType.SUCCESS)
		_selected_slot = ""
		_refresh_slot_list()
		info_title.text = "请选择存档"
		info_details.text = ""
		confirm_button.disabled = true
		delete_button.disabled = true

func _on_back_pressed() -> void:
	AudioManager.play_button_click()
	GameManager.return_to_menu()
