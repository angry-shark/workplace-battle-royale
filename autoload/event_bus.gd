extends Node
## EventBus - 全局事件总线
## 用于解耦各系统间的通信

# 游戏状态事件
signal game_started
signal game_paused
signal game_resumed
signal game_ended(victory_condition: int)
signal game_over(winner_id: int)

# 回合事件
signal turn_started(turn_number: int)
signal turn_ended(turn_number: int)
signal phase_changed(phase: int)
signal month_ended(month: int)
signal quarter_ended(quarter: int)
signal year_ended(year: int)

# 玩家事件
signal player_hp_changed(player_id: int, current_hp: int, max_hp: int)
signal player_kpi_changed(player_id: int, current_kpi: int)
signal player_salary_changed(player_id: int, new_salary: int)
signal player_promoted(player_id: int, new_rank: int)
signal player_eliminated(player_id: int, reason: String)
signal player_action_taken(player_id: int, action_type: String)

# 卡牌事件
signal card_drawn(player_id: int, card_id: String)
signal card_played(player_id: int, card_id: String, target_id: int)
signal card_discarded(player_id: int, card_id: String)

# Hex 事件
signal hex_acquired(player_id: int, hex_id: String, rarity: int)
signal hex_activated(player_id: int, hex_id: String)

# 商店事件
signal shop_entered(player_id: int)
signal shop_exited(player_id: int)
signal item_purchased(player_id: int, item_id: String, cost: int)

# 交互事件
signal trap_placed(player_id: int, trap_id: String, target_id: int)
signal trap_triggered(trap_id: String, victim_id: int)
signal alliance_formed(player_a: int, player_b: int)
signal alliance_broken(player_a: int, player_b: int)
signal betrayal_occurred(betrayer: int, victim: int)

# UI 事件
signal ui_message(message: String, type: int)
signal ui_notification(title: String, content: String)
signal ui_show_dialog(dialog_id: String, data: Dictionary)

# 消息类型枚举
enum MessageType {
	INFO,
	WARNING,
	ERROR,
	SUCCESS,
	CRITICAL
}

func _ready():
	print("EventBus initialized")

## 发送UI消息快捷方法
func show_message(message: String, type: int = MessageType.INFO):
	ui_message.emit(message, type)

## 发送通知快捷方法
func notify(title: String, content: String):
	ui_notification.emit(title, content)
# 行动阶段协调
signal player_action_completed
signal player_action_phase_ready(player_id: int)
# 商店阶段协调
signal shop_completed


