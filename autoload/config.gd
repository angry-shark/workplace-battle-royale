extends Node
## Config - 全局配置
## 存储游戏常量、枚举和配置数据

# 游戏版本
const VERSION: String = "0.1.0"

# 职级系统 P1-P12
enum Rank {
	P1 = 1, P2, P3,   # 初级员工 (50%)
	P4, P5, P6,       # 骨干员工 (30%)
	P7, P8, P9,       # 专家 (15%)
	P10, P11, P12     # 管理层 (5%)
}

# 职业类型
enum Profession {
	PROGRAMMER,   # 程序员 - 高产出，低社交
	HR,           # HR - 信息优势，陷阱专家
	FINANCE,      # 财务 - 薪资加成，资源控制
	OPERATIONS,   # 运营 - 全能，无弱点
	SALES         # 销售 - 高风险高回报
}

# 游戏状态
enum GameState {
	MENU,
	CHARACTER_SELECT,
	PLAYING,
	PAUSED,
	GAME_OVER,
	VICTORY
}

# 回合阶段
enum TurnPhase {
	HP_DEDUCTION,    # HP扣除
	ACTION,          # 行动阶段
	WORK_OUTPUT,     # 工作产出
	SALARY,          # 薪资结算
	SHOP             # 商店
}

# 时间周期
const MONTHS_PER_QUARTER: int = 3
const QUARTERS_PER_YEAR: int = 4

# 初始属性
const INITIAL_HP: int = 100
const INITIAL_SALARY: Dictionary = {
	Rank.P1: 5000, Rank.P2: 6000, Rank.P3: 7000,
	Rank.P4: 9000, Rank.P5: 11000, Rank.P6: 13000,
	Rank.P7: 16000, Rank.P8: 20000, Rank.P9: 25000,
	Rank.P10: 35000, Rank.P11: 50000, Rank.P12: 80000
}

# 每回合HP扣除
const MONTHLY_HP_COST: int = 10

# 策略卡数量
const STRATEGY_CARDS: Dictionary = {
	Rank.P1: 3, Rank.P2: 3, Rank.P3: 3,
	Rank.P4: 4, Rank.P5: 4, Rank.P6: 4,
	Rank.P7: 5, Rank.P8: 5, Rank.P9: 5,
	Rank.P10: 6, Rank.P11: 6, Rank.P12: 6
}

# Hex 稀有度
enum HexRarity {
	COMMON,     # 普通 - 60%
	RARE,       # 稀有 - 30%
	EPIC,       # 史诗 - 9%
	LEGENDARY   # 传说 - 1%
}

# Hex 类型
enum HexType {
	SURVIVAL,    # 生存
	PERFORMANCE, # 绩效
	STRATEGY,    # 策略
	ECONOMY      # 经济
}

# AI 类型
enum AIType {
	GRINDER,      # 奋斗逼 - 高绩效，低HP
	WELLNESS,     # 养生党 - 高HP，低绩效
	DECEIVER,     # 老六 - 中等，爱陷阱
	SOCIAL,       # 社交狂 - 爱结盟，低背叛
	PROMOTION,    # 晋升狂 - 追求高职级
	LURKER        # 老阴逼 - 隐藏实力
}

# 胜利条件
enum VictoryCondition {
	LAST_STANDING,      # 标准 - 最后存活
	FINANCIAL_FREEDOM,  # 财务自由
	JOB_HOP,            # 跳槽
	ARBITRATION,        # 劳动仲裁
	PACIFIST,           # 和平主义
	P12_LEGEND,         # P12传奇
	LURKER_MASTER       # 老阴逼大师
}

# 颜色配置
const COLORS: Dictionary = {
	"primary_dark": Color("#1a1a2e"),
	"primary": Color("#16213e"),
	"accent_blue": Color("#0f4c75"),
	"accent_orange": Color("#f39c12"),
	"common": Color("#aaaaaa"),
	"rare": Color("#3498db"),
	"epic": Color("#9b59b6"),
	"legendary": Color("#f1c40f")
}

func _ready():
	print("Config loaded - Version: ", VERSION)
