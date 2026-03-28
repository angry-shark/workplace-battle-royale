extends Node
## AudioManager - 音频管理器
## 管理游戏音效和背景音乐

# 禁用标志（开发测试时设为 false 可静默运行）
var enabled: bool = false  # 默认禁用，直到有实际音效资源

# 音频轨道
@onready var _bgm_player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var _sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var _ui_player: AudioStreamPlayer = AudioStreamPlayer.new()

# 音量设置 (0-100)
var master_volume: int = 100
var bgm_volume: int = 80
var sfx_volume: int = 100
var ui_volume: int = 100

# 音效库
var _sfx_library: Dictionary = {}
var _ui_sfx_library: Dictionary = {}

# 当前BGM
var _current_bgm: String = ""

func _ready():
	name = "AudioManager"
	
	# 强制初始为禁用状态，避免编辑器状态覆盖
	enabled = false
	
	# 检查是否有音效文件，有才启用
	var test_file = "res:/" + "/assets/audio/ui/click.wav"
	var has_audio_files = FileAccess.file_exists(test_file)
	
	if has_audio_files:
		enabled = true
		_setup_audio_players()
		_load_sfx_library()
		print("AudioManager initialized (enabled)")
	else:
		print("AudioManager initialized (disabled - no audio files)")

## 设置音频播放器
func _setup_audio_players() -> void:
	# BGM播放器
	_bgm_player.name = "BGMPlayer"
	_bgm_player.bus = "Music"
	add_child(_bgm_player)
	
	# SFX播放器
	_sfx_player.name = "SFXPlayer"
	_sfx_player.bus = "SFX"
	add_child(_sfx_player)
	
	# UI音效播放器
	_ui_player.name = "UIPlayer"
	_ui_player.bus = "UI"
	add_child(_ui_player)
	
	# 设置初始音量
	_update_volumes()

## 加载音效库
func _load_sfx_library() -> void:
	# 动态构建路径，避免编辑器静态分析资源引用
	var base_path = "res:/" + "/assets/audio"
	
	# 游戏音效
	_sfx_library = {
		"card_draw": base_path + "/sfx/card_draw.wav",
		"card_play": base_path + "/sfx/card_play.wav",
		"trap_trigger": base_path + "/sfx/trap_trigger.wav",
		"damage": base_path + "/sfx/damage.wav",
		"heal": base_path + "/sfx/heal.wav",
		"coin": base_path + "/sfx/coin.wav",
		"level_up": base_path + "/sfx/level_up.wav",
		"elimination": base_path + "/sfx/elimination.wav",
		"victory": base_path + "/sfx/victory.wav",
		"defeat": base_path + "/sfx/defeat.wav",
		"hex_acquire": base_path + "/sfx/hex_acquire.wav",
		"shop_buy": base_path + "/sfx/shop_buy.wav",
		"turn_start": base_path + "/sfx/turn_start.wav"
	}
	
	# UI音效
	_ui_sfx_library = {
		"button_click": base_path + "/ui/click.wav",
		"button_hover": base_path + "/ui/hover.wav",
		"panel_open": base_path + "/ui/panel_open.wav",
		"panel_close": base_path + "/ui/panel_close.wav",
		"notification": base_path + "/ui/notification.wav",
		"error": base_path + "/ui/error.wav"
	}

## 更新音量
func _update_volumes() -> void:
	if not enabled:
		return
	var master_db = _volume_to_db(master_volume)
	var bgm_db = _volume_to_db(bgm_volume)
	var sfx_db = _volume_to_db(sfx_volume)
	var ui_db = _volume_to_db(ui_volume)
	
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), master_db)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), bgm_db)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), sfx_db)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("UI"), ui_db)

## 音量转分贝
func _volume_to_db(volume: int) -> float:
	if volume <= 0:
		return -80.0
	return 20.0 * log(float(volume) / 100.0) / log(10.0)

## 播放背景音乐
func play_bgm(bgm_name: String, fade_duration: float = 1.0) -> void:
	if not enabled:
		return
	if _current_bgm == bgm_name:
		return
	
	var path = "res:/" + "/assets/audio/bgm/" + bgm_name + ".ogg"
	
	if not ResourceLoader.exists(path):
		# BGM文件不存在，静默返回（开发阶段正常）
		return
	
	var stream = load(path)
	if not stream:
		return
	
	_current_bgm = bgm_name
	
	# 淡入淡出
	if _bgm_player.playing and fade_duration > 0:
		var tween = create_tween()
		tween.tween_property(_bgm_player, "volume_db", -80.0, fade_duration / 2.0)
		tween.tween_callback(func():
			_bgm_player.stream = stream
			_bgm_player.volume_db = -80.0
			_bgm_player.play()
			var tween2 = create_tween()
			tween2.tween_property(_bgm_player, "volume_db", _volume_to_db(bgm_volume), fade_duration / 2.0)
		)
	else:
		_bgm_player.stream = stream
		_bgm_player.volume_db = _volume_to_db(bgm_volume)
		_bgm_player.play()
	
	print("Playing BGM: ", bgm_name)

## 停止背景音乐
func stop_bgm(fade_duration: float = 1.0) -> void:
	if not enabled:
		return
	if not _bgm_player.playing:
		return
	
	if fade_duration > 0:
		var tween = create_tween()
		tween.tween_property(_bgm_player, "volume_db", -80.0, fade_duration)
		tween.tween_callback(func():
			_bgm_player.stop()
			_current_bgm = ""
		)
	else:
		_bgm_player.stop()
		_current_bgm = ""

## 播放音效
func play_sfx(sfx_name: String) -> void:
	if not enabled:
		return
	var path = _sfx_library.get(sfx_name, "")
	if path.is_empty():
		return
	
	var stream: AudioStream
	if ResourceLoader.exists(path):
		stream = load(path)
	else:
		# 使用内置音效作为后备
		stream = _generate_fallback_sound(sfx_name)
	
	if stream:
		_sfx_player.stream = stream
		_sfx_player.volume_db = _volume_to_db(sfx_volume)
		_sfx_player.play()

## 播放UI音效
func play_ui(ui_name: String) -> void:
	if not enabled:
		return
	var path = _ui_sfx_library.get(ui_name, "")
	if path.is_empty():
		return
	
	var stream: AudioStream
	if ResourceLoader.exists(path):
		stream = load(path)
	else:
		# 使用简单的点击音效
		stream = _generate_beep_sound()
	
	if stream:
		_ui_player.stream = stream
		_ui_player.volume_db = _volume_to_db(ui_volume)
		_ui_player.play()

## 生成后备音效（简单的合成音效）
func _generate_fallback_sound(sfx_name: String) -> AudioStream:
	if not enabled:
		return null
	
	match sfx_name:
		"success":
			# 上升音调
			return _generate_tone([440, 554, 659], 0.3)
		"error":
			# 下降音调
			return _generate_tone([330, 277], 0.3)
		"coin":
			# 高频短音
			return _generate_tone([880], 0.1)
		"heal":
			# 柔和音调
			return _generate_tone([523, 659], 0.4)
		_:
			# 默认短音
			return _generate_tone([440], 0.1)

## 生成简单音调
func _generate_tone(frequencies: Array, duration: float):
	# 简化版本：使用 AudioStreamWAV 生成简单波形
	var stream = AudioStreamWAV.new()
	var sample_rate = 44100
	var num_samples = int(duration * sample_rate)
	
	var data = PackedByteArray()
	data.resize(num_samples * 2)  # 16-bit mono
	
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var sample = 0.0
		
		# 叠加所有频率
		for freq in frequencies:
			sample += sin(t * freq * TAU) * 0.3
		
		# 添加衰减
		var envelope = 1.0 - (float(i) / float(num_samples))
		sample *= envelope
		
		# 转换为16位整数
		var value = int(clamp(sample * 32767, -32768, 32767))
		data.encode_s16(i * 2, value)
	
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	stream.mix_rate = sample_rate
	
	return stream

## 生成简单的哔哔声
func _generate_beep_sound() -> AudioStream:
	return _generate_tone([800], 0.05)

## 设置主音量
func set_master_volume(volume: int) -> void:
	master_volume = clamp(volume, 0, 100)
	_update_volumes()

## 设置BGM音量
func set_bgm_volume(volume: int) -> void:
	bgm_volume = clamp(volume, 0, 100)
	_update_volumes()

## 设置SFX音量
func set_sfx_volume(volume: int) -> void:
	sfx_volume = clamp(volume, 0, 100)
	_update_volumes()

## 设置UI音量
func set_ui_volume(volume: int) -> void:
	ui_volume = clamp(volume, 0, 100)
	_update_volumes()

## 启用/禁用音效
func set_enabled(value: bool) -> void:
	enabled = value
	if enabled:
		_setup_audio_players()
		_load_sfx_library()
		print("Audio enabled")
	else:
		stop_bgm()
		print("Audio disabled")

## 预加载音效（可选优化）
func preload_sfx(sfx_name: String) -> void:
	if not enabled:
		return
	var path = _sfx_library.get(sfx_name, "")
	if not path.is_empty():
		ResourceLoader.load_threaded_request(path)

## 便捷的播放方法
func play_card_draw() -> void:
	play_sfx("card_draw")

func play_card_play() -> void:
	play_sfx("card_play")

func play_damage() -> void:
	play_sfx("damage")

func play_heal() -> void:
	play_sfx("heal")

func play_coin() -> void:
	play_sfx("coin")

func play_level_up() -> void:
	play_sfx("level_up")

func play_victory() -> void:
	play_sfx("victory")

func play_defeat() -> void:
	play_sfx("defeat")

func play_button_click() -> void:
	play_ui("button_click")

func play_button_hover() -> void:
	play_ui("button_hover")
