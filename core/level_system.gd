class_name LevelSystem
## LevelSystem - 职级系统
## 管理 P1-P12 的晋升机制

const MIN_RANK: int = 1  # P1
const MAX_RANK: int = 12  # P12

# 各职级的特性
const RANK_DATA: Dictionary = {
	1: {  # P1
		"title": "实习生",
		"population_pct": 0.10,
		"strategy_cards": 3,
		"salary": 5000
	},
	2: {  # P2
		"title": "初级专员",
		"population_pct": 0.15,
		"strategy_cards": 3,
		"salary": 6000
	},
	3: {  # P3
		"title": "专员",
		"population_pct": 0.25,
		"strategy_cards": 3,
		"salary": 7000
	},
	4: {  # P4
		"title": "高级专员",
		"population_pct": 0.12,
		"strategy_cards": 4,
		"salary": 9000
	},
	5: {  # P5
		"title": "资深专员",
		"population_pct": 0.10,
		"strategy_cards": 4,
		"salary": 11000
	},
	6: {  # P6
		"title": "专家",
		"population_pct": 0.08,
		"strategy_cards": 4,
		"salary": 13000
	},
	7: {  # P7
		"title": "资深专家",
		"population_pct": 0.06,
		"strategy_cards": 5,
		"salary": 16000
	},
	8: {  # P8
		"title": "架构师",
		"population_pct": 0.05,
		"strategy_cards": 5,
		"salary": 20000
	},
	9: {  # P9
		"title": "资深架构师",
		"population_pct": 0.04,
		"strategy_cards": 5,
		"salary": 25000
	},
	10: {  # P10
		"title": "总监",
		"population_pct": 0.03,
		"strategy_cards": 6,
		"salary": 35000
	},
	11: {  # P11
		"title": "资深总监",
		"population_pct": 0.015,
		"strategy_cards": 6,
		"salary": 50000
	},
	12: {  # P12
		"title": "VP",
		"population_pct": 0.005,
		"strategy_cards": 6,
		"salary": 80000
	}
}

# 晋升所需KPI（季度）
const PROMOTION_KPI: Dictionary = {
	1: 50,   # P1->P2
	2: 80,   # P2->P3
	3: 120,  # P3->P4
	4: 160,  # P4->P5
	5: 200,  # P5->P6
	6: 250,  # P6->P7
	7: 320,  # P7->P8
	8: 400,  # P8->P9
	9: 500,  # P9->P10
	10: 650, # P10->P11
	11: 850  # P11->P12
}

## 获取职级数据
static func get_rank_data(rank: int) -> Dictionary:
	var clamped_rank = clamp(rank, MIN_RANK, MAX_RANK)
	return RANK_DATA.get(clamped_rank, RANK_DATA[1])

## 获取职级名称 P1, P2, etc.
static func get_rank_name(rank: int) -> String:
	return "P" + str(rank)

## 获取职级标题
static func get_rank_title(rank: int) -> String:
	return get_rank_data(rank).title

## 获取策略卡数量
static func get_strategy_card_count(rank: int) -> int:
	return get_rank_data(rank).strategy_cards

## 获取职级薪资
static func get_salary(rank: int) -> int:
	return get_rank_data(rank).salary

## 检查是否可以晋升
static func can_promote(current_rank: int, quarterly_kpi: int) -> bool:
	if current_rank >= MAX_RANK:
		return false
	var required_kpi = PROMOTION_KPI.get(current_rank, 9999)
	return quarterly_kpi >= required_kpi

## 获取晋升所需KPI
static func get_promotion_kpi(rank: int) -> int:
	return PROMOTION_KPI.get(rank, 9999)

## 获取晋升进度百分比
static func get_promotion_progress(rank: int, quarterly_kpi: int) -> float:
	if rank >= MAX_RANK:
		return 1.0
	var required = get_promotion_kpi(rank)
	return min(float(quarterly_kpi) / float(required), 1.0)

## 获取职级分层
static func get_tier(rank: int) -> String:
	if rank <= 3:
		return "初级"
	elif rank <= 6:
		return "骨干"
	elif rank <= 9:
		return "专家"
	else:
		return "管理层"

## 获取淘汰危险阈值（低于此排名有危险）
## 在季度末结算时，排名靠后的玩家会被淘汰
static func get_elimination_threshold(total_players: int, rank: int) -> int:
	# 管理层(P10+)免疫淘汰
	if rank >= 10:
		return -1
	
	# 专家(P7-P9)淘汰比例较低
	if rank >= 7:
		return int(total_players * 0.15)
	
	# 骨干(P4-P6)淘汰比例中等
	if rank >= 4:
		return int(total_players * 0.25)
	
	# 初级(P1-P3)淘汰比例最高
	return int(total_players * 0.40)

## 根据总人口生成随机职级分布
static func generate_rank_distribution(total_players: int) -> Array:
	var distribution = []
	
	for rank in range(MAX_RANK, MIN_RANK - 1, -1):
		var data = get_rank_data(rank)
		var count = int(total_players * data.population_pct)
		for i in range(count):
			distribution.append(rank)
	
	# 补齐剩余人数
	while distribution.size() < total_players:
		distribution.append(randi() % 3 + 1)  # P1-P3
	
	# 打乱顺序
	distribution.shuffle()
	
	return distribution
