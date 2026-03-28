extends Control
## SettingsMenu - 设置菜单
## 管理游戏音量、显示等设置

enum SettingTab {
	AUDIO,    # 音频
	DISPLAY,  # 显示
	GAME      # 游戏
}

var _current_tab: int = SettingTab.AUDIO

@onready var title_label: Label = $TitleLabel
@onready var tab_container: TabContainer = $TabContainer

# 音频设置
@onready var master_slider: HSlider = $TabContainer/音频/MasterVolume/MasterSlider
@onready var bgm_slider: HSlider = $TabContainer/音频/BGMVolume/BGMSlider
@onready var sfx_slider: HSlider = $TabContainer/音频/SFXVolume/SFXSlider
@onready var ui_slider: HSlider = $TabContainer/音频/UIVolume/UISlider

# 显示设置
@onready var fullscreen_check: CheckBox = $TabContainer/显示/FullscreenCheck
@onready var resolution_option: OptionButton = $TabContainer/显示/ResolutionOption

# 游戏设置
@onready var language_option: OptionButton = $TabContainer/游戏/LanguageOption
@onready var auto_save_check: CheckBox = $TabContainer/游戏/AutoSaveCheck

@onready var save_button: Button = $SaveButton
@onready var reset_button: Button = $ResetButton
@onready var back_button: Button = $BackButton

func _ready():
	_setup_ui()
	_load_current_settings()

func _setup_ui() -> void:
	GameTheme.apply_button_style(save_button, "primary")
	GameTheme.apply_button_style(reset_button, "secondary")
	GameTheme.apply_button_style(back_button, "secondary")
	
	# 设置分辨率选项
	resolution_option.add_item("1920x1080", 0)
	resolution_option.add_item("1600x900", 1)
	resolution_option.add_item("1280x720", 2)
	resolution_option.add_item("1024x576", 3)
	
	# 设置语言选项
	language_option.add_item("简体中文", 0)
	language_option.add_item("English", 1)
	
	# 连接信号
	master_slider.value_changed.connect(_on_master_volume_changed)
	bgm_slider.value_changed.connect(_on_bgm_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	ui_slider.value_changed.connect(_on_ui_volume_changed)
	
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	resolution_option.item_selected.connect(_on_resolution_changed)
	
	language_option.item_selected.connect(_on_language_changed)
	auto_save_check.toggled.connect(_on_auto_save_toggled)
	
	save_button.pressed.connect(_on_save_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	back_button.pressed.connect(_on_back_pressed)

func _load_current_settings() -> void:
	# 加载音频设置
	master_slider.value = SaveManager.settings.get("master_volume", 100)
	bgm_slider.value = SaveManager.settings.get("bgm_volume", 80)
	sfx_slider.value = SaveManager.settings.get("sfx_volume", 100)
	ui_slider.value = SaveManager.settings.get("ui_volume", 100)
	
	# 加载显示设置
	fullscreen_check.button_pressed = SaveManager.settings.get("fullscreen", false)
	var res_index = SaveManager.settings.get("resolution_index", 0)
	resolution_option.selected = res_index
	
	# 加载游戏设置
	var lang_index = SaveManager.settings.get("language_index", 0)
	language_option.selected = lang_index
	auto_save_check.button_pressed = SaveManager.settings.get("auto_save", true)

## 音频设置回调
func _on_master_volume_changed(value: float) -> void:
	AudioManager.set_master_volume(int(value))
	_save_setting("master_volume", int(value))

func _on_bgm_volume_changed(value: float) -> void:
	AudioManager.set_bgm_volume(int(value))
	_save_setting("bgm_volume", int(value))

func _on_sfx_volume_changed(value: float) -> void:
	AudioManager.set_sfx_volume(int(value))
	_save_setting("sfx_volume", int(value))
	AudioManager.play_button_click()  # 播放测试音效

func _on_ui_volume_changed(value: float) -> void:
	AudioManager.set_ui_volume(int(value))
	_save_setting("ui_volume", int(value))

## 显示设置回调
func _on_fullscreen_toggled(enabled: bool) -> void:
	_save_setting("fullscreen", enabled)
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_resolution_changed(index: int) -> void:
	_save_setting("resolution_index", index)
	
	var resolutions = [
		Vector2i(1920, 1080),
		Vector2i(1600, 900),
		Vector2i(1280, 720),
		Vector2i(1024, 576)
	]
	
	if index >= 0 and index < resolutions.size():
		DisplayServer.window_set_size(resolutions[index])
		# 居中窗口
		var screen_size = DisplayServer.screen_get_size()
		var window_size = resolutions[index]
		DisplayServer.window_set_position((screen_size - window_size) / 2)

## 游戏设置回调
func _on_language_changed(index: int) -> void:
	_save_setting("language_index", index)
	var languages = ["zh_CN", "en"]
	_save_setting("language", languages[index])
	# TODO: 应用语言切换

func _on_auto_save_toggled(enabled: bool) -> void:
	_save_setting("auto_save", enabled)

## 保存单个设置
func _save_setting(key: String, value) -> void:
	SaveManager.settings[key] = value

## 按钮回调
func _on_save_pressed() -> void:
	AudioManager.play_button_click()
	
	if SaveManager.save_settings():
		AudioManager.play_success()
		_show_message("设置已保存！")
	else:
		AudioManager.play_error()
		_show_message("保存失败！", true)

func _on_reset_pressed() -> void:
	AudioManager.play_button_click()
	
	var dialog = ConfirmationDialog.new()
	dialog.title = "确认重置"
	dialog.dialog_text = "确定要恢复默认设置吗？"
	dialog.confirmed.connect(_reset_to_default)
	add_child(dialog)
	dialog.popup_centered()

func _reset_to_default() -> void:
	AudioManager.play_button_click()
	
	# 恢复默认设置
	SaveManager.settings = {
		"master_volume": 100,
		"bgm_volume": 80,
		"sfx_volume": 100,
		"ui_volume": 100,
		"fullscreen": false,
		"resolution_index": 0,
		"language": "zh_CN",
		"language_index": 0,
		"auto_save": true
	}
	
	# 应用设置
	_load_current_settings()
	_apply_all_settings()
	
	SaveManager.save_settings()
	_show_message("已恢复默认设置！")

func _apply_all_settings() -> void:
	# 应用音频
	AudioManager.set_master_volume(SaveManager.settings.master_volume)
	AudioManager.set_bgm_volume(SaveManager.settings.bgm_volume)
	AudioManager.set_sfx_volume(SaveManager.settings.sfx_volume)
	AudioManager.set_ui_volume(SaveManager.settings.ui_volume)
	
	# 应用显示
	_on_fullscreen_toggled(SaveManager.settings.fullscreen)
	_on_resolution_changed(SaveManager.settings.resolution_index)

func _on_back_pressed() -> void:
	AudioManager.play_button_click()
	GameManager.return_to_menu()

func _show_message(text: String, is_error: bool = false) -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "提示"
	dialog.dialog_text = text
	add_child(dialog)
	dialog.popup_centered()
