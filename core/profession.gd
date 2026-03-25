class_name Profession
## Profession - 职业系统
## 定义不同职业的特性和能力

enum Type {
	PROGRAMMER,   # 程序员
	HR,           # HR
	FINANCE,      # 财务
	OPERATIONS,   # 运营
	SALES         # 销售
}

# 职业基础属性模板
const PROFESSION_DATA: Dictionary = {
	Type.PROGRAMMER: {
		"name": "程序员",
		"name_en": "Programmer",
		"description": "高产出，低社交，容易 burnout",
		"color": Color("#2ecc71"),  # 蓝绿色
		"base_hp": 100,
		"base_kpi": 15,        # 高绩效产出
		"kpi_bonus": 1.5,      # 工作卡效果+50%
		"social_penalty": 0.7, # 社交效果-30%
		"burnout_risk": 0.15,  # 15% burnout 几率
		"special_skills": ["加班狂魔", "代码重构", "技术债务"]
	},
	Type.HR: {
		"name": "HR",
		"name_en": "HR Admin",
		"description": "信息优势，陷阱专家",
		"color": Color("#9b59b6"),  # 紫色
		"base_hp": 110,
		"base_kpi": 8,
		"info_advantage": true,  # 可以看到其他玩家部分信息
		"trap_bonus": 1.3,       # 陷阱效果+30%
		"special_skills": ["信息收集", "背调", "绩效评估"]
	},
	Type.FINANCE: {
		"name": "财务",
		"name_en": "Finance",
		"description": "薪资加成，资源控制，保守稳健",
		"color": Color("#34495e"),  # 深蓝灰
		"base_hp": 120,
		"base_kpi": 10,
		"salary_bonus": 1.2,     # 薪资+20%
		"shop_discount": 0.9,    # 商店9折
		"special_skills": ["预算管控", "成本优化", "财务审计"]
	},
	Type.OPERATIONS: {
		"name": "运营",
		"name_en": "Operations",
		"description": "全能发展，适应性强，无明显弱点",
		"color": Color("#e67e22"),  # 橙色
		"base_hp": 115,
		"base_kpi": 12,
		"adaptability": true,    # 所有效果+10%
		"special_skills": ["数据分析", "用户增长", "活动策划"]
	},
	Type.SALES: {
		"name": "销售",
		"name_en": "Sales",
		"description": "高风险高回报，社交主导，抗压能力强",
		"color": Color("#e74c3c"),  # 红色
		"base_hp": 105,
		"base_kpi": 20,
		"kpi_variance": 0.3,     # KPI波动±30%
		"social_bonus": 1.4,     # 社交效果+40%
		"stress_resistance": true, # 抗压（减少HP消耗）
		"special_skills": ["客户攻关", "资源整合", "谈判专家"]
	}
}

## 获取职业数据
static func get_data(profession_type: int) -> Dictionary:
	return PROFESSION_DATA.get(profession_type, PROFESSION_DATA[Type.PROGRAMMER])

## 获取职业名称
static func get_name(profession_type: int) -> String:
	return get_data(profession_type).name

## 获取职业颜色
static func get_color(profession_type: int) -> Color:
	return get_data(profession_type).color

## 计算职业初始HP
static func calculate_hp(profession_type: int, rank: int) -> int:
	var base = get_data(profession_type).base_hp
	# 职级越高，HP上限略高（代表工作年限和抗压能力）
	var rank_bonus = (rank - 1) * 2
	return base + rank_bonus

## 计算职业KPI产出
static func calculate_kpi(profession_type: int, work_effort: int) -> int:
	var data = get_data(profession_type)
	var base_kpi = data.base_kpi
	var kpi_multiplier = data.get("kpi_bonus", 1.0)
	
	# 销售的KPI波动
	if profession_type == Type.SALES and data.has("kpi_variance"):
		var variance = randf_range(-data.kpi_variance, data.kpi_variance)
		kpi_multiplier += variance
	
	return int(base_kpi * work_effort * kpi_multiplier / 10.0)

## 获取所有职业列表
static func get_all_professions() -> Array:
	return [
		Type.PROGRAMMER,
		Type.HR,
		Type.FINANCE,
		Type.OPERATIONS,
		Type.SALES
	]

## 检查职业是否有特殊能力
static func has_ability(profession_type: int, ability_name: String) -> bool:
	var data = get_data(profession_type)
	return data.has(ability_name) and data[ability_name]
