class_name Economy
extends RefCounted
## Economy - 经济系统
## 管理税收、通货膨胀、奖金池等经济机制

# 税收等级
const TAX_BRACKETS: Array[Dictionary] = [
	{"threshold": 5000, "rate": 0.0},
	{"threshold": 10000, "rate": 0.05},
	{"threshold": 20000, "rate": 0.10},
	{"threshold": 40000, "rate": 0.18},
	{"threshold": 999999, "rate": 0.25}
]

# 通货膨胀基础参数
const INFLATION_BASE: float = 0.02
const INFLATION_PER_QUARTER: float = 0.005

# 奖金池参数
const BONUS_POOL_BASE: float = 1000.0
const BONUS_POOL_PER_PLAYER: float = 200.0
const BONUS_TOP_PCT: float = 0.20

# 物价指数
var inflation_rate: float = INFLATION_BASE
var total_quarters: int = 0

func reset() -> void:
	inflation_rate = INFLATION_BASE
	total_quarters = 0

func advance_quarter() -> void:
	total_quarters += 1
	inflation_rate = INFLATION_BASE + INFLATION_PER_QUARTER * total_quarters

## 计算税收
static func calculate_tax(salary: int) -> int:
	var tax = 0
	var remaining = salary
	
	for i in range(TAX_BRACKETS.size()):
		var bracket = TAX_BRACKETS[i]
		var prev_threshold = 0 if i == 0 else TAX_BRACKETS[i - 1].threshold
		var taxable_in_bracket = min(max(remaining, 0), bracket.threshold - prev_threshold)
		
		if taxable_in_bracket > 0:
			tax += int(taxable_in_bracket * bracket.rate)
			remaining -= taxable_in_bracket
	
	return tax

## 获取税后薪资
static func get_after_tax_salary(salary: int) -> int:
	return max(0, salary - calculate_tax(salary))

## 计算奖金池总额
static func calculate_bonus_pool(total_players: int) -> int:
	return int(BONUS_POOL_BASE + BONUS_POOL_PER_PLAYER * total_players)

## 分配季度奖金
static func distribute_quarterly_bonus(players: Array) -> void:
	var alive: Array = []
	for player in players:
		if player.is_alive:
			alive.append(player)
	
	if alive.is_empty():
		return
	
	var total_bonus = calculate_bonus_pool(alive.size())
	var top_count = max(1, int(alive.size() * BONUS_TOP_PCT))
	
	# 按KPI排序
	alive.sort_custom(func(a, b): return a.current_kpi > b.current_kpi)
	
	# 前20%获得大部分奖金
	var top_share = total_bonus * 0.6 / top_count
	var rest_share = total_bonus * 0.4 / max(alive.size() - top_count, 1)
	
	for i in range(alive.size()):
		var bonus = int(top_share) if i < top_count else int(rest_share)
		alive[i].modify_salary(bonus)

## 应用通货膨胀（增加商店价格）
func apply_inflation_to_prices(base_price: int) -> int:
	return int(base_price * (1.0 + inflation_rate))

## 计算实际购买力
func calculate_purchasing_power(salary: int) -> float:
	return float(salary) / (1.0 + inflation_rate)

## 获取当前通胀率
func get_inflation_rate() -> float:
	return inflation_rate

## 检查是否触发经济衰退
func check_recession(kpi_total: int, expected_kpi: int) -> bool:
	if expected_kpi <= 0:
		return false
	return float(kpi_total) < float(expected_kpi) * 0.6

## 经济衰退效果
func apply_recession(players: Array) -> void:
	for player in players:
		if player.is_alive:
			player.modify_salary(-int(player.current_salary * 0.15))
	EventBus.show_message("经济衰退！全公司薪资-15%", EventBus.MessageType.WARNING)
