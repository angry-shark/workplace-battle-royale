class_name GameTheme
## GameTheme - 游戏主题配置
## 集中管理颜色、字体、尺寸等UI样式

# ========== 颜色配置 ==========
const COLORS: Dictionary = {
	# 主色调
	"primary_dark": Color("#1a1a2e"),
	"primary": Color("#16213e"),
	"primary_light": Color("#0f3460"),
	
	# 强调色
	"accent_blue": Color("#0f4c75"),
	"accent_orange": Color("#f39c12"),
	"accent_red": Color("#e74c3c"),
	"accent_green": Color("#2ecc71"),
	
	# 文字颜色
	"text_primary": Color("#ffffff"),
	"text_secondary": Color("#aaaaaa"),
	"text_disabled": Color("#666666"),
	
	# 背景色
	"bg_dark": Color("#0d0d15"),
	"bg_panel": Color("#1a1a2e"),
	"bg_card": Color("#16213e"),
	
	# 海克斯稀有度颜色
	"hex_common": Color("#aaaaaa"),
	"hex_rare": Color("#3498db"),
	"hex_epic": Color("#9b59b6"),
	"hex_legendary": Color("#f1c40f"),
	
	# 职业颜色
	"prof_programmer": Color("#2ecc71"),
	"prof_hr": Color("#9b59b6"),
	"prof_finance": Color("#34495e"),
	"prof_operations": Color("#e67e22"),
	"prof_sales": Color("#e74c3c")
}

# ========== 尺寸配置 ==========
const SIZES: Dictionary = {
	# 窗口
	"window_width": 1920,
	"window_height": 1080,
	
	# 卡牌尺寸
	"card_width": 120,
	"card_height": 160,
	"card_corner_radius": 8,
	
	# 海克斯尺寸
	"hex_size": 64,
	"hex_corner_radius": 4,
	
	# 按钮
	"button_height": 48,
	"button_width_small": 100,
	"button_width_medium": 150,
	"button_width_large": 200,
	
	# 间距
	"spacing_small": 8,
	"spacing_medium": 16,
	"spacing_large": 24,
	"spacing_xl": 32
}

# ========== 字体配置 ==========
const FONTS: Dictionary = {
	"title_large": 48,
	"title_medium": 32,
	"title_small": 24,
	"body_large": 18,
	"body_medium": 14,
	"body_small": 12,
	"label": 11
}

# ========== 动画配置 ==========
const ANIMATIONS: Dictionary = {
	"duration_short": 0.15,
	"duration_medium": 0.3,
	"duration_long": 0.5,
	"ease_type": Tween.EASE_OUT,
	"trans_type": Tween.TRANS_QUAD
}

# ========== 静态获取方法 ==========
static func get_color(key: String) -> Color:
	return COLORS.get(key, Color.WHITE)

static func get_size(key: String) -> int:
	return SIZES.get(key, 0)

static func get_font_size(key: String) -> int:
	return FONTS.get(key, 14)

static func get_animation_duration(key: String) -> float:
	return ANIMATIONS.get(key, 0.3)

# ========== 稀有度颜色 ==========
static func get_rarity_color(rarity: String) -> Color:
	match rarity:
		"common":
			return COLORS.hex_common
		"rare":
			return COLORS.hex_rare
		"epic":
			return COLORS.hex_epic
		"legendary":
			return COLORS.hex_legendary
		_:
			return COLORS.hex_common

# ========== 职业颜色 ==========
static func get_profession_color(profession: int) -> Color:
	match profession:
		Config.Profession.PROGRAMMER:
			return COLORS.prof_programmer
		Config.Profession.HR:
			return COLORS.prof_hr
		Config.Profession.FINANCE:
			return COLORS.prof_finance
		Config.Profession.OPERATIONS:
			return COLORS.prof_operations
		Config.Profession.SALES:
			return COLORS.prof_sales
		_:
			return COLORS.text_primary

# ========== 样式预设 ==========
static func apply_panel_style(panel: Control) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = COLORS.bg_panel
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = COLORS.primary_light
	panel.add_theme_stylebox_override("panel", style)

static func apply_button_style(button: Button, style_type: String = "primary") -> void:
	var normal_style = StyleBoxFlat.new()
	var hover_style = StyleBoxFlat.new()
	var pressed_style = StyleBoxFlat.new()
	
	match style_type:
		"primary":
			normal_style.bg_color = COLORS.accent_blue
			hover_style.bg_color = COLORS.accent_blue.lightened(0.2)
			pressed_style.bg_color = COLORS.accent_blue.darkened(0.2)
		"secondary":
			normal_style.bg_color = COLORS.primary_light
			hover_style.bg_color = COLORS.primary_light.lightened(0.2)
			pressed_style.bg_color = COLORS.primary_light.darkened(0.2)
		"danger":
			normal_style.bg_color = COLORS.accent_red
			hover_style.bg_color = COLORS.accent_red.lightened(0.2)
			pressed_style.bg_color = COLORS.accent_red.darkened(0.2)
		"success":
			normal_style.bg_color = COLORS.accent_green
			hover_style.bg_color = COLORS.accent_green.lightened(0.2)
			pressed_style.bg_color = COLORS.accent_green.darkened(0.2)
	
	for style in [normal_style, hover_style, pressed_style]:
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
	
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_color_override("font_color", COLORS.text_primary)
