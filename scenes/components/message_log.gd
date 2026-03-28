class_name MessageLog
extends RichTextLabel
## MessageLog - 消息日志组件
## 显示游戏过程中的消息和事件

const MAX_LINES: int = 100

var _message_history: Array[String] = []

func _ready():
	bbcode_enabled = true
	scroll_following = true
	custom_minimum_size = Vector2(300, 200)
	
	# 连接事件
	EventBus.ui_message.connect(_on_ui_message)
	EventBus.player_eliminated.connect(_on_player_eliminated)
	EventBus.player_promoted.connect(_on_player_promoted)
	EventBus.alliance_formed.connect(_on_alliance_formed)
	EventBus.betrayal_occurred.connect(_on_betrayal)

## 添加普通消息
func log_message(text: String, color: String = "#aaaaaa") -> void:
	var time_str = _get_time_string()
	var formatted = "[color=%s][%s][/color] %s\n" % [color, time_str, text]
	_append_text(formatted)

## 添加系统消息
func log_system(text: String) -> void:
	log_message("[系统] " + text, "#888888")

## 添加成功消息
func log_success(text: String) -> void:
	log_message("[color=#2ecc71]✓ " + text + "[/color]", "#2ecc71")

## 添加警告消息
func log_warning(text: String) -> void:
	log_message("[color=#f39c12]⚠ " + text + "[/color]", "#f39c12")

## 添加错误消息
func log_error(text: String) -> void:
	log_message("[color=#e74c3c]✗ " + text + "[/color]", "#e74c3c")

## 添加重要消息
func log_important(text: String) -> void:
	var formatted = "[center][color=#f1c40f]★ %s ★[/color][/center]\n" % text
	_append_text(formatted)

## 添加玩家事件
func log_player_event(player_name: String, event: String, is_player: bool = false) -> void:
	var color = "#3498db" if is_player else "#aaaaaa"
	var prefix = "[你]" if is_player else ""
	log_message("[color=%s]%s%s[/color]: %s" % [color, prefix, player_name, event], color)

## 内部添加文本
func _append_text(text: String) -> void:
	append_text(text)
	_message_history.append(text)
	
	# 限制历史记录数量
	if _message_history.size() > MAX_LINES:
		_message_history.pop_front()
		_clear_and_rewrite()
	
	# 自动滚动到底部
	scroll_to_line(get_line_count())

func _clear_and_rewrite() -> void:
	clear()
	for line in _message_history:
		append_text(line)

## 获取时间字符串
func _get_time_string() -> String:
	var time = Time.get_time_dict_from_system()
	return "%02d:%02d" % [time.hour, time.minute]

## 清空日志
func clear_log() -> void:
	clear()
	_message_history.clear()

## 事件回调
func _on_ui_message(message: String, type: int) -> void:
	match type:
		EventBus.MessageType.INFO:
			log_message(message)
		EventBus.MessageType.WARNING:
			log_warning(message)
		EventBus.MessageType.ERROR:
			log_error(message)
		EventBus.MessageType.SUCCESS:
			log_success(message)
		EventBus.MessageType.CRITICAL:
			log_important(message)

func _on_player_eliminated(player_id: int, reason: String) -> void:
	var is_player = (player_id == 0)
	var player_name = "你" if is_player else ("同事%d" % player_id)
	var color = "#e74c3c" if is_player else "#aaaaaa"
	log_message("[color=%s]💀 %s被淘汰了！原因：%s[/color]" % [color, player_name, reason])
	
	if is_player:
		AudioManager.play_defeat()

func _on_player_promoted(player_id: int, new_rank: int) -> void:
	var is_player = (player_id == 0)
	var player_name = "你" if is_player else ("同事%d" % player_id)
	var color = "#f1c40f" if is_player else "#aaaaaa"
	log_message("[color=%s]⭐ %s晋升至P%d！[/color]" % [color, player_name, new_rank])
	
	if is_player:
		AudioManager.play_level_up()

func _on_alliance_formed(player_a: int, player_b: int) -> void:
	var is_player_involved = (player_a == 0) or (player_b == 0)
	if is_player_involved:
		var other_id = player_b if player_a == 0 else player_a
		log_success("🤝 你与同事%d结成了联盟！" % other_id)

func _on_betrayal(betrayer: int, victim: int) -> void:
	if victim == 0:
		log_error("💔 你被同事%d背叛了！" % betrayer)
	elif betrayer == 0:
		log_warning("⚔️ 你背叛了同事%d！" % victim)
