class_name ActionPanel
extends PanelContainer
## ActionPanel - 行动阶段主面板
## 显示行动按钮、手牌和目标选择，管理玩家行动阶段的完整交互

signal action_confirmed
signal target_selected(target_id: int)
signal target_cancelled
signal work_action_chosen(action_type: String)

enum ActionState {
	IDLE,
	CHOOSING_ACTION,
	SELECTING_TARGET,
	WAITING_CONFIRM
}

var _state: int = ActionState.IDLE
var _selected_card_id: String = ""
var _selected_target_id: int = -1
var _chosen_work_action: String = ""
var _human_player: Player = null
var _all_players: Array = []

@onready var title_label: Label = $TitleLabel
@onready var work_buttons: HBoxContainer = $WorkButtons
@onready var btn_normal: Button = $WorkButtons/BtnNormal
@onready var btn_overtime: Button = $WorkButtons/BtnOvertime
@onready var btn_slack: Button = $WorkButtons/BtnSlack
@onready var btn_end_turn: Button = $BtnEndTurn
@onready var target_overlay: Control = $TargetOverlay
@onready var target_list: VBoxContainer = $TargetOverlay/Panel/TargetList
@onready var card_hand: CardHand = $CardSection/CardHand
@onready var status_label: Label = $StatusLabel


func _ready() -> void:
	GameTheme.apply_panel_style(self)
	_setup_buttons()
	_setup_signals()
	target_overlay.hide()
	btn_end_turn.hide()
	work_buttons.hide()
	status_label.hide()


func _setup_buttons() -> void:
	GameTheme.apply_button_style(btn_normal, "primary")
	GameTheme.apply_button_style(btn_overtime, "secondary")
	GameTheme.apply_button_style(btn_slack, "secondary")
	GameTheme.apply_button_style(btn_end_turn, "primary")


func _setup_signals() -> void:
	btn_normal.pressed.connect(_on_work_action.bind("work_normal"))
	btn_overtime.pressed.connect(_on_work_action.bind("work_overtime"))
	btn_slack.pressed.connect(_on_work_action.bind("work_slack"))
	btn_end_turn.pressed.connect(_on_end_turn_pressed)
	card_hand.card_selected.connect(_on_card_selected)


func start_action_phase(human: Player, all_players: Array) -> void:
	_human_player = human
	_all_players = all_players
	_selected_card_id = ""
	_selected_target_id = -1
	_chosen_work_action = ""
	_state = ActionState.CHOOSING_ACTION

	show()
	work_buttons.show()
	target_overlay.hide()
	btn_end_turn.hide()

	title_label.text = "行动阶段 - 选择你的行动"
	status_label.text = ""

	card_hand.set_hand(human.hand_cards)
	card_hand.set_interactable(true)
	card_hand.deselect_all()

	var hp_ratio = float(human.current_hp) / max(human.max_hp, 1)
	btn_overtime.disabled = hp_ratio < 0.2

	AudioManager.play_ui("panel_open")


func _on_work_action(action_type: String) -> void:
	if _state != ActionState.CHOOSING_ACTION:
		return

	AudioManager.play_button_click()
	_chosen_work_action = action_type
	_selected_card_id = ""
	_selected_target_id = -1

	work_buttons.hide()
	card_hand.set_interactable(false)

	var action_names = {
		"work_normal": "正常上班",
		"work_overtime": "拼命加班",
		"work_slack": "划水摸鱼"
	}
	status_label.text = "已选择: " + action_names.get(action_type, action_type)
	status_label.show()
	btn_end_turn.text = "确认并结束行动"
	btn_end_turn.show()

	_state = ActionState.WAITING_CONFIRM
	card_hand.deselect_all()


func _on_card_selected(card_id: String) -> void:
	if _state != ActionState.CHOOSING_ACTION:
		return

	var card_info = CardManager.get_card_info(card_id)
	if card_info.is_empty():
		return

	var card_type = card_info.get("type", "")

	if card_type == "工作卡" or (card_type == "特殊卡" and not _card_needs_target(card_id)):
		_selected_card_id = card_id
		_selected_target_id = -1
		_chosen_work_action = ""
		work_buttons.hide()
		status_label.text = "已选择: " + card_info.get("name", card_id)
		status_label.show()
		btn_end_turn.text = "确认使用卡牌"
		btn_end_turn.show()
		_state = ActionState.WAITING_CONFIRM
		return

	if card_type == "陷害卡" or card_type == "联盟卡":
		_selected_card_id = card_id
		_state = ActionState.SELECTING_TARGET
		_show_target_overlay(card_type, card_info)
		return


func _card_needs_target(card_id: String) -> bool:
	match card_id:
		"special_job_hop", "special_sudden_death":
			return false
		_:
			return true


func _show_target_overlay(card_type: String, card_info: Dictionary) -> void:
	for child in target_list.get_children():
		child.queue_free()

	var valid_targets := _get_valid_targets(card_type)

	if valid_targets.is_empty():
		status_label.text = "没有可选目标！"
		status_label.show()
		return

	var overlay_title = target_overlay.get_node_or_null("Panel/OverlayTitle")
	if overlay_title:
		overlay_title.text = "选择目标 - " + card_info.get("name", "")

	for target in valid_targets:
		var btn = Button.new()
		btn.text = "%s [HP:%d/%d KPI:%d]" % [
			target.player_name,
			target.current_hp, target.max_hp,
			target.current_kpi
		]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 44)
		GameTheme.apply_button_style(btn, "secondary")
		btn.pressed.connect(_on_target_selected.bind(target.player_id))
		target_list.add_child(btn)

	var cancel_btn = Button.new()
	cancel_btn.text = "取消选择"
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	GameTheme.apply_button_style(cancel_btn, "danger")
	cancel_btn.pressed.connect(_on_target_cancelled)
	target_list.add_child(cancel_btn)

	target_overlay.show()
	card_hand.set_interactable(false)
	work_buttons.hide()
	AudioManager.play_ui("panel_open")


func _get_valid_targets(card_type: String) -> Array[Player]:
	var targets: Array[Player] = []
	var human_id = _human_player.player_id if _human_player else -1

	for player in _all_players:
		if not player.is_alive or player.player_id == human_id:
			continue

		if card_type == "联盟卡":
			if _selected_card_id == "alliance_form" and _human_player.is_allied_with(player.player_id):
				continue
			if _selected_card_id == "alliance_betray" and not _human_player.is_allied_with(player.player_id):
				continue

		targets.append(player)

	return targets


func _on_target_selected(target_id: int) -> void:
	AudioManager.play_button_click()
	_selected_target_id = target_id
	target_overlay.hide()

	var card_info = CardManager.get_card_info(_selected_card_id)
	status_label.text = "目标: %s, 卡牌: %s" % [_get_player_name(target_id), card_info.get("name", "")]
	status_label.show()
	btn_end_turn.text = "确认使用卡牌"
	btn_end_turn.show()

	_state = ActionState.WAITING_CONFIRM


func _on_target_cancelled() -> void:
	AudioManager.play_button_click()
	_selected_card_id = ""
	_selected_target_id = -1
	target_overlay.hide()
	card_hand.set_interactable(true)
	card_hand.deselect_all()
	work_buttons.show()
	btn_end_turn.hide()
	status_label.hide()

	_state = ActionState.CHOOSING_ACTION


func _get_player_name(player_id: int) -> String:
	for player in _all_players:
		if player.player_id == player_id:
			return player.player_name
	return "未知"


func _on_end_turn_pressed() -> void:
	if _state != ActionState.WAITING_CONFIRM:
		return

	AudioManager.play_button_click()

	var human = _human_player
	if not human or not human.is_alive:
		_reset_and_hide()
		action_confirmed.emit()
		return

	if not _chosen_work_action.is_empty():
		var player_card_id = _chosen_work_action
		if CardManager.play_card(human, player_card_id):
			print("Player chose work action: ", _chosen_work_action)
		else:
			_apply_work_action_effect(human, _chosen_work_action)
		work_action_chosen.emit(_chosen_work_action)

	if not _selected_card_id.is_empty():
		var target: Player = null
		if _selected_target_id >= 0:
			for player in _all_players:
				if player.player_id == _selected_target_id:
					target = player
					break

		if CardManager.play_card(human, _selected_card_id, target):
			print("Player played card: ", _selected_card_id, " on ", target.player_name if target else "self")
			target_selected.emit(_selected_target_id)

	_reset_and_hide()
	action_confirmed.emit()


func _apply_work_action_effect(player: Player, action_type: String) -> void:
	match action_type:
		"work_normal":
			player.set_meta("work_kpi_multiplier", 1.0)
			player.modify_hp(-5)
		"work_overtime":
			player.set_meta("work_kpi_multiplier", 1.5)
			player.modify_hp(-15)
		"work_slack":
			player.set_meta("work_kpi_multiplier", 0.7)
			player.modify_hp(5)


func _reset_and_hide() -> void:
	_selected_card_id = ""
	_selected_target_id = -1
	_chosen_work_action = ""
	_state = ActionState.IDLE

	work_buttons.hide()
	btn_end_turn.hide()
	target_overlay.hide()
	status_label.hide()
	card_hand.clear_hand()
	card_hand.set_interactable(false)

	hide()


func is_waiting() -> bool:
	return _state == ActionState.WAITING_CONFIRM


func get_selected_card() -> String:
	return _selected_card_id


func get_selected_target() -> int:
	return _selected_target_id


func get_work_action() -> String:
	return _chosen_work_action
