class_name PlayerListPanel
extends PanelContainer
## PlayerListPanel - 玩家列表面板
## 显示所有存活玩家的头像和状态

var _player_items: Dictionary = {}  # player_id -> PlayerListItem
var _scroll_container: ScrollContainer
var _list_container: VBoxContainer
var _all_players: Array = []  # 所有玩家引用

@export var max_display: int = 10  # 最多显示多少玩家

## 设置玩家列表
func set_players(players: Array) -> void:
	_all_players = players
	_update_list()

func _ready():
	_setup_ui()
	_update_list()

func _setup_ui() -> void:
	GameTheme.apply_panel_style(self)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)
	
	# 标题
	var title = Label.new()
	title.text = "存活玩家"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", GameTheme.FONTS.body_medium)
	vbox.add_child(title)
	
	# 滚动容器
	_scroll_container = ScrollContainer.new()
	_scroll_container.custom_minimum_size = Vector2(200, 300)
	_scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_scroll_container)
	
	# 列表容器
	_list_container = VBoxContainer.new()
	_list_container.add_theme_constant_override("separation", 6)
	_scroll_container.add_child(_list_container)
	
	# 连接事件
	EventBus.player_eliminated.connect(_on_player_eliminated)
	EventBus.player_hp_changed.connect(_on_player_hp_changed)
	EventBus.player_kpi_changed.connect(_on_player_kpi_changed)

func _update_list() -> void:
	# 清空现有
	for child in _list_container.get_children():
		child.queue_free()
	_player_items.clear()
	
	# 获取所有存活玩家并排序（按KPI）
	var alive_players: Array[Player] = []
	for player in _all_players:
		if player.is_alive:
			alive_players.append(player)
	
	alive_players.sort_custom(func(a, b): return a.current_kpi > b.current_kpi)
	
	# 只显示前N名
	var display_count = min(alive_players.size(), max_display)
	
	for i in range(display_count):
		var player = alive_players[i]
		var item = load("res://scenes/components/player_list_item.gd").new()
		item.set_player(player)
		_list_container.add_child(item)
		_player_items[player.player_id] = item
	
	# 如果还有更多玩家，显示省略号
	if alive_players.size() > max_display:
		var more_label = Label.new()
		more_label.text = "...还有%d人" % (alive_players.size() - max_display)
		more_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		more_label.add_theme_color_override("font_color", GameTheme.COLORS.text_secondary)
		_list_container.add_child(more_label)

func _on_player_eliminated(player_id: int, reason: String) -> void:
	# 延迟更新列表
	await get_tree().create_timer(0.5).timeout
	_update_list()

func _on_player_hp_changed(player_id: int, current: int, max_hp: int) -> void:
	if _player_items.has(player_id):
		var player = _get_player_by_id(player_id)
		if player:
			_player_items[player_id].update_status(player)

func _on_player_kpi_changed(player_id: int, kpi: int) -> void:
	if _player_items.has(player_id):
		var player = _get_player_by_id(player_id)
		if player:
			_player_items[player_id].update_status(player)

func _get_player_by_id(id: int) -> Player:
	for player in _all_players:
		if player.player_id == id:
			return player
	return null
