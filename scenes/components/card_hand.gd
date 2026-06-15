class_name CardHand
extends HBoxContainer
## CardHand - 手牌组件
## 使用CardDisplay显示玩家手牌

signal card_selected(card_id: String)
signal card_played(card_id: String, target_id: int)

var _card_displays: Dictionary = {}
var _selected_card: String = ""
var _is_interactable: bool = true

@export var card_spacing: int = 10

func _ready():
	add_theme_constant_override("separation", card_spacing)
	alignment = ALIGNMENT_CENTER

func set_hand(card_ids: Array[String]) -> void:
	for child in get_children():
		child.queue_free()
	_card_displays.clear()
	for card_id in card_ids:
		_add_card_display(card_id)

func _add_card_display(card_id: String) -> void:
	var card_info = CardManager.get_card_info(card_id)
	if card_info.is_empty():
		return
	var display = CardDisplay.new(card_id)
	display.name = "Card_" + card_id
	display.card_clicked.connect(_on_card_pressed.bind(card_id))
	display.card_hovered.connect(_on_card_hovered.bind(card_id, card_info))
	add_child(display)
	_card_displays[card_id] = display

func _on_card_pressed(card_id: String) -> void:
	if not _is_interactable:
		return
	AudioManager.play_button_click()
	if _selected_card == card_id:
		_selected_card = ""
		if _card_displays.has(card_id):
			_card_displays[card_id].set_highlighted(false)
	else:
		if _selected_card != "" and _card_displays.has(_selected_card):
			_card_displays[_selected_card].set_highlighted(false)
		_selected_card = card_id
		if _card_displays.has(card_id):
			_card_displays[card_id].set_highlighted(true)
	card_selected.emit(card_id)

func _on_card_hovered(card_id: String, card_info: Dictionary) -> void:
	if not _is_interactable:
		return
	AudioManager.play_button_hover()
	var title = card_info.get("name", "")
	var content = card_info.get("description", "")
	var cost = card_info.get("cost", 0)
	if cost > 0:
		content += "\n费用: " + str(cost)

func set_interactable(enabled: bool) -> void:
	_is_interactable = enabled
	for display in _card_displays.values():
		display.set_card_enabled(enabled)

func remove_card(card_id: String) -> void:
	if _card_displays.has(card_id):
		_card_displays[card_id].queue_free()
		_card_displays.erase(card_id)
	if _selected_card == card_id:
		_selected_card = ""

func clear_hand() -> void:
	for child in get_children():
		child.queue_free()
	_card_displays.clear()
	_selected_card = ""

func get_selected_card() -> String:
	return _selected_card

func deselect_all() -> void:
	if _selected_card != "" and _card_displays.has(_selected_card):
		_card_displays[_selected_card].set_highlighted(false)
	_selected_card = ""
