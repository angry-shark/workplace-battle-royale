extends Control
## MainMenu - 主菜单
## 游戏入口界面

@onready var title_label: Label = $TitleLabel
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var load_button: Button = $VBoxContainer/LoadButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var version_label: Label = $VersionLabel

func _ready():
	print("MainMenu loaded")
	
	# 设置版本号
	version_label.text = "v" + Config.VERSION
	
	# 检查是否有存档
	load_button.disabled = not SaveManager.has_save()
	
	# 连接按钮信号
	start_button.pressed.connect(_on_start_pressed)
	load_button.pressed.connect(_on_load_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# 按钮动画
	_animate_buttons()

func _animate_buttons() -> void:
	# 简单的入场动画
	var buttons = [start_button, load_button, settings_button, quit_button]
	for i in range(buttons.size()):
		buttons[i].modulate.a = 0
		var tween = create_tween()
		tween.tween_property(buttons[i], "modulate:a", 1.0, 0.3).set_delay(i * 0.1)

func _on_start_pressed() -> void:
	print("Start new game")
	# 显示游戏规模选择对话框
	_show_scale_selection_dialog()

func _on_load_pressed() -> void:
	print("Load game")
	if SaveManager.load_game():
		GameManager.start_game()
	else:
		_show_message("加载存档失败")

func _on_settings_pressed() -> void:
	print("Open settings")
	# TODO: 打开设置界面
	_show_message("设置功能开发中...")

func _on_quit_pressed() -> void:
	print("Quit game")
	get_tree().quit()

## 显示游戏规模选择对话框
func _show_scale_selection_dialog() -> void:
	var dialog = AcceptDialog.new()
	dialog.name = "ScaleSelectionDialog"
	dialog.title = "选择对局规模"
	dialog.dialog_text = "请选择游戏规模：\n\n" \
		+ "调试模式：5人（约5分钟）- 用于快速测试\n" \
		+ "快速模式：20人（约20分钟）\n" \
		+ "标准模式：50人（约40分钟）\n" \
		+ "史诗模式：100人（约90分钟）"
	
	# 添加自定义按钮
	dialog.add_button("调试", true, "debug")
	dialog.add_button("快速", true, "quick")
	dialog.add_button("标准", true, "standard")
	dialog.add_button("史诗", true, "epic")
	
	dialog.custom_action.connect(func(action):
		match action:
			"debug":
				GameManager.set_game_scale(GameManager.GameScale.DEBUG)
			"quick":
				GameManager.set_game_scale(GameManager.GameScale.QUICK)
			"standard":
				GameManager.set_game_scale(GameManager.GameScale.STANDARD)
			"epic":
				GameManager.set_game_scale(GameManager.GameScale.EPIC)
		dialog.queue_free()
		# 跳转到角色选择场景
		get_tree().change_scene_to_file("res://scenes/character_select/character_select.tscn")
	)
	
	add_child(dialog)
	dialog.popup_centered()

func _show_message(text: String) -> void:
	# 简单的消息提示
	var dialog = AcceptDialog.new()
	dialog.name = "MessageDialog"
	dialog.title = "提示"
	dialog.dialog_text = text
	add_child(dialog)
	dialog.popup_centered()
