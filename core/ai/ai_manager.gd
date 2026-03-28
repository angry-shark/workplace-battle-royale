extends Node
## AIManager - AI管理器
## 管理所有AI的分帧处理和决策调度

const AI_PER_FRAME: int = 5  # 每帧处理5个AI
const AI_PROCESS_INTERVAL: float = 0.05  # AI处理间隔（秒）

# AI队列
var _ai_queue: Array[AIController] = []
var _is_processing: bool = false
var _current_player_index: int = 0

# 性能监控
var _process_start_time: int = 0
var _total_ai_processed: int = 0

func _ready():
	name = "AIManager"
	print("AIManager initialized")

## 开始处理AI回合
func start_ai_turn(players: Array[Player], ai_controllers: Dictionary) -> void:
	_ai_queue.clear()
	
	# 按优先级排序AI（威胁高的先处理）
	var sorted_players = players.duplicate()
	sorted_players.sort_custom(_compare_ai_priority)
	
	for player in sorted_players:
		if player.is_ai and player.is_alive:
			if ai_controllers.has(player.player_id):
				_ai_queue.append(ai_controllers[player.player_id])
	
	if _ai_queue.is_empty():
		return
	
	_is_processing = true
	_current_player_index = 0
	_process_start_time = Time.get_ticks_msec()
	_total_ai_processed = 0
	
	print("AI turn started, ", _ai_queue.size(), " AIs to process")
	
	# 开始分帧处理
	_process_next_batch()

## AI优先级比较（高威胁的优先）
func _compare_ai_priority(a: Player, b: Player) -> bool:
	# 高绩效的优先处理（威胁更大）
	if a.current_kpi != b.current_kpi:
		return a.current_kpi > b.current_kpi
	
	# 高职级的优先
	if a.rank != b.rank:
		return a.rank > b.rank
	
	# HP高的更危险
	return a.current_hp > b.current_hp

## 处理下一批AI
func _process_next_batch() -> void:
	if not _is_processing or _current_player_index >= _ai_queue.size():
		_finish_ai_turn()
		return
	
	var processed_this_frame = 0
	var start_time = Time.get_ticks_usec()
	var max_time_per_frame = 10000  # 每帧最多10ms（约1/6帧时间@60fps）
	
	while _current_player_index < _ai_queue.size() and processed_this_frame < AI_PER_FRAME:
		# 检查是否超时
		if Time.get_ticks_usec() - start_time > max_time_per_frame:
			break
		
		var ai_controller = _ai_queue[_current_player_index]
		
		# 执行AI决策
		if ai_controller._player.is_alive:
			ai_controller.make_decision({})
			_total_ai_processed += 1
		
		_current_player_index += 1
		processed_this_frame += 1
	
	# 如果还有未处理的AI，延迟处理下一批
	if _current_player_index < _ai_queue.size():
		call_deferred("_schedule_next_batch")
	else:
		_finish_ai_turn()

## 调度下一批
func _schedule_next_batch() -> void:
	# 使用Timer或await延迟
	await get_tree().create_timer(AI_PROCESS_INTERVAL).timeout
	_process_next_batch()

## 完成AI回合
func _finish_ai_turn() -> void:
	_is_processing = false
	
	var elapsed = Time.get_ticks_msec() - _process_start_time
	print("AI turn finished, processed ", _total_ai_processed, " AIs in ", elapsed, "ms")
	
	# 发送信号通知回合管理器
	EventBus.ui_message.emit("AI回合完成", EventBus.MessageType.INFO)

## 检查是否正在处理
func is_ai_processing() -> bool:
	return _is_processing

## 获取队列长度
func get_queue_size() -> int:
	return _ai_queue.size()

## 获取处理进度
func get_progress() -> float:
	if _ai_queue.is_empty():
		return 1.0
	return float(_current_player_index) / float(_ai_queue.size())

## 强制停止处理
func stop_processing() -> void:
	_is_processing = false
	_ai_queue.clear()
