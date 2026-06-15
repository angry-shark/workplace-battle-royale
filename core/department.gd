class_name Department
extends RefCounted
## Department - 部门系统
## 管理玩家所属部门，提供部门间互动和部门级加成

enum Dept {
	TECH,
	HR,
	FINANCE,
	OPERATIONS,
	SALES
}

const DEPT_DATA: Dictionary = {
	Dept.TECH: {
		"name": "技术部",
		"profession": Config.Profession.PROGRAMMER,
		"kpi_weight": 1.5,
		"description": "核心产出部门，绩效权重高"
	},
	Dept.HR: {
		"name": "人力资源部",
		"profession": Config.Profession.HR,
		"kpi_weight": 0.8,
		"description": "掌握人事信息，隐藏优势大"
	},
	Dept.FINANCE: {
		"name": "财务部",
		"profession": Config.Profession.FINANCE,
		"kpi_weight": 1.0,
		"description": "薪资优势部门"
	},
	Dept.OPERATIONS: {
		"name": "运营部",
		"profession": Config.Profession.OPERATIONS,
		"kpi_weight": 1.1,
		"description": "灵活协作部门"
	},
	Dept.SALES: {
		"name": "销售部",
		"profession": Config.Profession.SALES,
		"kpi_weight": 1.6,
		"description": "高风险高回报部门"
	}
}

static func get_dept_from_profession(profession: int) -> int:
	match profession:
		Config.Profession.PROGRAMMER:
			return Dept.TECH
		Config.Profession.HR:
			return Dept.HR
		Config.Profession.FINANCE:
			return Dept.FINANCE
		Config.Profession.OPERATIONS:
			return Dept.OPERATIONS
		Config.Profession.SALES:
			return Dept.SALES
		_:
			return Dept.OPERATIONS

static func get_dept_name(dept: int) -> String:
	return DEPT_DATA.get(dept, {}).get("name", "未知部门")

static func get_kpi_weight(dept: int) -> float:
	return DEPT_DATA.get(dept, {}).get("kpi_weight", 1.0)

static func calculate_dept_bonus(players: Array, dept: int) -> float:
	var dept_players: Array = []
	for player in players:
		if player.is_alive and get_dept_from_profession(player.profession) == dept:
			dept_players.append(player)
	
	if dept_players.is_empty():
		return 1.0
	
	var total_kpi = 0
	for p in dept_players:
		total_kpi += p.current_kpi
	var avg_kpi = float(total_kpi) / dept_players.size()
	
	var size_bonus = 1.0
	var size = dept_players.size()
	if size >= 3 and size <= 5:
		size_bonus = 1.15
	elif size > 5:
		size_bonus = 1.0
	else:
		size_bonus = 0.9
	
	return size_bonus

static func get_rivalry_bonus(attacker_dept: int, target_dept: int) -> float:
	if (attacker_dept == Dept.TECH and target_dept == Dept.SALES) or \
	   (attacker_dept == Dept.SALES and target_dept == Dept.TECH):
		return 1.2
	if target_dept == Dept.HR and attacker_dept != Dept.HR:
		return 0.8
	return 1.0

static func apply_dept_effect(players: Array, dept: int, effect_key: String, value: float) -> void:
	for player in players:
		if player.is_alive and get_dept_from_profession(player.profession) == dept:
			match effect_key:
				"kpi_bonus":
					player.modify_kpi(int(value))
				"hp_recovery":
					player.modify_hp(int(value))
				"salary_bonus":
					player.modify_salary(int(value))
