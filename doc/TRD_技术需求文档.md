# 《职场大逃杀：最后打工人》技术需求文档 (TRD)

**版本**: v1.0  
**日期**: 2026-03-25  
**引擎**: Godot 4.6  
**语言**: GDScript

---

## 一、项目概述

### 1.1 项目简介
《职场大逃杀：最后打工人》是一款以现代职场为背景的 Roguelike 策略生存游戏。玩家扮演一名普通打工人，在"HC（编制）紧缩"的环境下，与其他同事展开生存竞争。

### 1.2 技术目标（单机版）
- **开发周期**: MVP 3个月，完整版6个月
- **目标平台**: PC / Steam
- **游戏模式**: 单机（1人类玩家 + N个AI对手，支持5/20/50/100人局）
- **性能目标**: 60FPS，单局支持100人同局
- **调试模式**: 5人快速局（~5分钟），用于开发和测试

### 1.3 技术选型
| 层级 | 技术 | 版本 | 用途 |
|------|------|------|------|
| 游戏引擎 | Godot | 4.6 | 核心开发 |
| 脚本语言 | GDScript | - | 游戏逻辑 |
| 数据存储 | JSON + SQLite | - | 配置+存档 |
| 版本控制 | Git + Git LFS | - | 代码+资源 |
| CI/CD | GitHub Actions | - | 自动构建 |
| 测试 | GUT | 9.0+ | 单元测试 |

---

## 二、系统架构

### 2.1 整体架构（单机模式）

```
┌─────────────────────────────────────────────────────────────┐
│                      表现层 (Presentation)                    │
│              Godot Scene + UI + Tween动画                    │
│                    scenes/ 目录                              │
├─────────────────────────────────────────────────────────────┤
│                      逻辑层 (Game Logic)                      │
│    ┌─────────────┐    ┌─────────────────────┐              │
│    │  核心系统   │    │    扩展系统         │              │
│    │ - TurnMgr   │    │ - Card System       │              │
│    │ - Player    │    │ - Hex System        │              │
│    │ - Profession│    │ - AI System (本地)  │              │
│    │ - Economy   │    │ - Event System      │              │
│    └─────────────┘    └─────────────────────┘              │
│                      core/ 目录                              │
├─────────────────────────────────────────────────────────────┤
│                      数据层 (Data Layer)                      │
│         JSON配置 + SQLite存档 + Resource资源                │
│                    resources/ + user://                      │
├─────────────────────────────────────────────────────────────┤
│                      全局层 (Global)                          │
│    ┌─────────┐ ┌──────────┐ ┌────────────┐ ┌──────────┐   │
│    │ Config  │ │EventBus  │ │GameManager │ │SaveManager│   │
│    └─────────┘ └──────────┘ └────────────┘ └──────────┘   │
│                    autoload/ 目录 (AutoLoad)                 │
└─────────────────────────────────────────────────────────────┘

注：本版本为单机模式，所有AI在本地运算，无需网络层
支持20/50/100人三种对局规模，AI决策采用分帧处理保证流畅
```

### 2.2 核心设计原则

1. **数据驱动**: 卡牌、海克斯、事件等配置化，支持热更新
2. **核心解耦**: 纯GDScript类不依赖Godot节点，可单元测试
3. **状态集中**: 全局状态由GameManager统一管理
4. **事件通信**: 系统间通过EventBus解耦通信
5. **单机优先**: 专注单机体验，AI在本地运算，无需网络同步

---

## 三、数据模型

### 3.1 玩家数据模型 (Player)

```gdscript
class_name Player

# 基础信息
var player_id: int
var player_name: String
var is_ai: bool
var ai_type: AIType

# 职业和职级
var profession: Profession.Type
var rank: int  # 1-12 (P1-P12)

# 双资源系统
var current_hp: int
var max_hp: int
var current_kpi: int      # 季度内绩效
var total_kpi: int        # 累计绩效
var current_salary: int   # 月度薪资
var total_salary: int     # 累计总资产

# 状态
var is_alive: bool
var elimination_reason: String

# 能力
var hexes: Array[String]
var hand_cards: Array[String]
var max_hand_size: int
var allies: Array[int]

# 统计
var game_stats: Dictionary
```

### 3.2 海克斯数据模型 (Hex)

```json
{
  "id": "hex_slacking_master",
  "name": "摸鱼大师",
  "name_en": "Slacking Master",
  "description": "加班只扣3HP，但绩效-5%",
  "rarity": "rare",
  "type": "survival",
  "duration": "quarter",
  "effects": {
    "hp_cost_overtime": -7,
    "performance_penalty": -0.05
  },
  "profession_limit": null,
  "rank_limit": 0
}
```

### 3.3 卡牌数据模型 (Card)

```json
{
  "id": "card_shift_blame",
  "name": "甩锅",
  "type": "trap",
  "subtype": "frame",
  "description": "指定目标绩效-15%，50%暴露",
  "cost": 200,
  "effects": {
    "target_kpi": -0.15,
    "expose_chance": 0.5
  },
  "target_type": "single_enemy",
  "profession_limit": null,
  "rank_limit": 0
}
```

### 3.4 存档数据模型

```json
{
  "version": "0.1.0",
  "timestamp": "2026-03-25T10:30:00",
  "game_seed": 12345,
  "game_state": {
    "turn": 5,
    "month": 2,
    "quarter": 1,
    "year": 1
  },
  "players": [
    {
      "id": 0,
      "name": "打工人",
      "profession": 0,
      "rank": 3,
      "hp": 85,
      "max_hp": 100,
      "kpi": 45,
      "salary": 7000,
      "total_salary": 21000,
      "hexes": ["hex_slacking_master", "hex_ppt_god"],
      "hand_cards": ["card_shift_blame", "card_alliance"],
      "allies": [5, 12]
    }
  ]
}
```

---

## 四、核心系统实现

### 4.1 全局单例系统 (AutoLoad)

| 单例 | 职责 | 关键方法 |
|------|------|----------|
| **Config** | 游戏常量、枚举、配置 | 枚举定义、常量查询 |
| **EventBus** | 全局事件总线 | 信号定义、事件分发 |
| **GameManager** | 游戏状态管理 | start_game(), pause_game(), change_scene() |
| **PlayerData** | 玩家数据持久化 | init_new_game(), save_progress() |
| **SaveManager** | 存档/读档系统 | save_game(), load_game(), delete_save() |
| **AudioManager** | 音频管理 | play_bgm(), play_sfx() |

### 4.2 回合管理系统 (TurnManager)

```gdscript
class_name TurnManager
extends Node

enum TurnPhase {
    HP_DEDUCTION,    # HP扣除
    ACTION,          # 行动阶段
    WORK_OUTPUT,     # 工作产出
    SALARY,          # 薪资结算
    SHOP             # 商店
}

signal turn_started(turn_number: int)
signal phase_changed(phase: TurnPhase)
signal quarter_ended(quarter: int, eliminated: Array)

var current_turn: int
var current_phase: TurnPhase
var players: Array[Player]

func start_game(players: Array[Player]) -> void
func process_phase() -> void
func advance_phase() -> void
func process_quarter_settlement() -> void
```

**月度流程**:  
`HP扣除 → 行动阶段(卡牌使用) → 工作产出 → 薪资结算 → 商店购买`

**季度流程**:  
`绩效清零 + 海克斯清空 → HC盘点(缩圈+淘汰) → 晋升评审 → 抽取海克斯`

### 4.3 职级系统 (LevelSystem)

```gdscript
class_name LevelSystem

const MIN_RANK: int = 1   # P1
const MAX_RANK: int = 12  # P12

static func get_rank_data(rank: int) -> Dictionary
static func get_promotion_kpi(rank: int) -> int
static func can_promote(rank: int, quarterly_kpi: int) -> bool
static func get_elimination_threshold(total_players: int, rank: int) -> int
static func generate_rank_distribution(total: int) -> Array[int]
```

**职级属性**:
| 职级段 | 人数占比 | 初始工资 | 策略卡数 |
|--------|----------|----------|----------|
| P1-P3 | 50% | 5000 | 3张 |
| P4-P6 | 30% | 11000 | 4张 |
| P7-P9 | 15% | 20000 | 5张 |
| P10-P12 | 5% | 50000 | 6张 |

### 4.4 职业系统 (Profession)

```gdscript
class_name Profession

enum Type {
    PROGRAMMER,   # 程序员 - 高绩效，低社交
    HR,           # HR - 信息优势，陷害专家
    FINANCE,      # 财务 - 薪资加成，资源控制
    OPERATIONS,   # 运营 - 全能，无短板
    SALES         # 销售 - 高风险高回报
}

static func get_data(type: Type) -> Dictionary
static func calculate_hp(type: Type, rank: int) -> int
static func calculate_kpi(type: Type, effort: int) -> int
```

**职业特性**:

| 职业 | 被动Buff | 被动Debuff |
|------|----------|------------|
| 程序员 | 绩效+15% | HP消耗+3，社交卡-20% |
| HR | 查看2人状态，陷害+15% | 绩效-10%，被集火+20% |
| 财务 | 工资+20%，商店-15% | 绩效-5%，禁用高风险卡 |
| 运营 | 策略卡上限+1 | 无传说海克斯 |
| 销售 | 绩效±50%，社交+25% | HP消耗+2，低绩惩罚-10% |

### 4.5 AI系统 (AIController) - 单机本地AI

```gdscript
class_name AIController

enum AIType {
    GRINDER,      # 卷王型 - 高绩效，低HP
    WELLNESS,     # 养生型 - 高HP，低绩效
    DECEIVER,     # 老六型 - 爱陷害
    SOCIAL,       # 社交型 - 爱结盟
    PROMOTION,    # 晋升型 - 追求高职级
    LURKER        # 潜伏型 - 隐藏实力
}

func make_decision(player: Player, context: GameContext) -> Action
func evaluate_targets(player: Player) -> Dictionary
func calculate_action_value(action: Action) -> float
```

**AI架构说明（单机模式）**:  
- 所有AI运算在本地执行，采用分帧+分时处理
- AI决策按优先级分批执行，每帧处理5-10个AI
- AI难度通过调整评估参数实现
- 支持19/49/99个AI同时参与对局（20/50/100人局）

**对局规模配置**:
| 模式 | 总人数 | AI数 | 缩圈速度 | 预计时长 | 用途 |
|------|--------|------|----------|----------|------|
| **调试** | 5 | 4 | 每季度淘汰1人 | ~5分钟 | 开发调试 |
| 快速 | 20 | 19 | 每季度淘汰20% | 15-20分钟 | 休闲对局 |
| 标准 | 50 | 49 | 每季度淘汰25% | 30-40分钟 | 标准体验 |
| 史诗 | 100 | 99 | 每季度淘汰30% | 60-90分钟 | 周末局 |

**调试模式特性**:
- 仅5人（1人类 + 4 AI），用于快速验证游戏逻辑
- 启用调试日志，显示详细AI决策过程
- 支持快捷键：F1显示所有玩家状态，F2强制进入下一回合
- 自动保存每回合状态，便于回溯调试

**AI决策流程**:  
`感知环境 → 评估状态 → 目标筛选 → 行动评估 → 执行最优`

---

## 五、配置文件结构

### 5.1 目录结构

```
resources/
├── cards/
│   ├── work_cards.json      # 工作卡配置
│   ├── trap_cards.json      # 陷害卡配置
│   ├── alliance_cards.json  # 联盟卡配置
│   └── special_cards.json   # 特殊卡配置
├── hex/
│   ├── common_hex.json      # 普通海克斯
│   ├── rare_hex.json        # 稀有海克斯
│   ├── epic_hex.json        # 史诗海克斯
│   └── legendary_hex.json   # 传说海克斯
├── professions/
│   ├── programmer.json      # 程序员配置
│   ├── hr.json
│   ├── finance.json
│   ├── operations.json
│   └── sales.json
├── events/
│   └── random_events.json   # 随机事件
└── localization/
    ├── zh_CN.json           # 中文
    └── en.json              # 英文
```

### 5.2 配置加载代码

```gdscript
# 配置加载器
class_name ConfigLoader

static func load_cards(type: String) -> Array[CardData]
static func load_hexes(rarity: String) -> Array[HexData]
static func load_profession(type: String) -> ProfessionData
static func load_localization(lang: String) -> Dictionary
```

---

## 六、API接口设计

### 6.1 事件总线接口 (EventBus)

```gdscript
# 游戏状态事件
signal game_started
signal game_paused
signal game_resumed
signal game_ended(victory_condition: int)

# 回合事件
signal turn_started(turn_number: int)
signal phase_changed(phase: int)
signal month_ended(month: int)
signal quarter_ended(quarter: int)

# 玩家事件
signal player_hp_changed(player_id: int, current: int, max_hp: int)
signal player_kpi_changed(player_id: int, kpi: int)
signal player_promoted(player_id: int, new_rank: int)
signal player_eliminated(player_id: int, reason: String)

# 交互事件
signal card_played(player_id: int, card_id: String, target_id: int)
signal hex_acquired(player_id: int, hex_id: String, rarity: int)
signal alliance_formed(player_a: int, player_b: int)
signal betrayal_occurred(betrayer: int, victim: int)
```

### 6.2 存档接口 (SaveManager)

```gdscript
# 存档管理
func save_game(slot_name: String = "auto") -> bool
func load_game(slot_name: String = "auto") -> bool
func delete_save(slot_name: String) -> bool
func has_save(slot_name: String) -> bool
func get_save_slots() -> Array[String]

# 设置管理
func save_settings() -> bool
func load_settings() -> bool
```

---

## 七、关键算法

### 7.1 淘汰算法 (Elimination)

```gdscript
func process_elimination() -> Array[int]:
    # 1. 计算各部门人均绩效
    var dept_performance = calculate_dept_performance()
    
    # 2. 部门排名，分配淘汰名额
    var elimination_quota = allocate_elimination_quota(dept_performance)
    
    # 3. 各部门内部按个人绩效排序，末尾淘汰
    var eliminated = []
    for dept in departments:
        var quota = elimination_quota[dept.id]
        var sorted = dept.members.sort_by_performance()
        for i in range(quota):
            eliminated.append(sorted[-(i+1)].id)
    
    return eliminated
```

### 7.2 AI决策评估 (Minimax)

```gdscript
func evaluate_action(action: Action, depth: int = 3) -> float:
    if depth == 0:
        return heuristic_score()
    
    var score = 0.0
    
    # 执行动作
    var result = simulate_action(action)
    
    # 评估结果
    match action.type:
        ActionType.WORK:
            score += result.kpi_gain * 2.0
            score -= result.hp_cost * 1.5
        ActionType.TRAP:
            score += result.target_damage * 2.5
            score -= result.expose_risk * 5.0
        ActionType.ALLIANCE:
            score += result.alliance_value * 3.0
    
    # 递归评估对手反应
    if depth > 1:
        var opponent_best = get_opponent_best_response()
        score -= evaluate_action(opponent_best, depth - 1) * 0.5
    
    return score
```

### 7.3 海克斯组合评分

```gdscript
func evaluate_hex_synergy(hexes: Array[String]) -> float:
    var score = 0.0
    var tags = get_hex_tags(hexes)
    
    # Combo检测
    if "996福报" in hexes and "养生达人" in hexes:
        score += 2.0  # 卷王生存流
    
    if "双面间谍" in hexes and "职场幽灵" in hexes:
        score += 2.5  # 老六阴人流
    
    # 标签平衡
    var survival = tags.count("survival")
    var performance = tags.count("performance")
    if survival > 0 and performance > 0:
        score += 1.0  # 平衡构建
    
    return score
```

---

## 八、性能优化

### 8.1 渲染优化

- **UI对象池**: 卡牌、海克斯使用对象池复用
- **离屏剔除**: 不可见UI元素暂停更新
- **纹理压缩**: 使用ETC/ASTC压缩移动平台纹理

### 8.2 逻辑优化

- **分帧处理**: AI决策分帧执行，避免卡顿
- **数据缓存**: 配置数据加载后缓存，避免重复IO
- **状态脏标记**: UI更新使用脏标记机制

### 8.3 内存优化

- **资源懒加载**: 音频、图片按需加载
- **存档压缩**: 存档数据使用压缩存储
- **对象回收**: 游戏对象使用对象池管理

---

## 九、测试策略

### 9.1 单元测试 (GUT)

```gdscript
# test_player.gd
extends GutTest

func test_player_hp_modification():
    var player = Player.new(0, "Test", Profession.PROGRAMMER, 3)
    player.modify_hp(-20)
    assert_eq(player.current_hp, 80)

func test_promotion_mechanics():
    var player = Player.new(0, "Test", Profession.PROGRAMMER, 3)
    player.current_kpi = 200
    assert_true(LevelSystem.can_promote(3, 200))
```

### 9.2 集成测试

- 完整单局游戏流程测试（20/50/100人模式）
- AI行为一致性测试
- 大规模AI性能测试（100人模式）
- 存档/读档一致性测试

### 9.3 平衡性测试

- 各职业胜率统计
- 海克斯组合效果分析
- 不同AI类型对抗测试

---

## 十、开发路线图

### Phase 1: 核心框架 (4周)
- [x] 项目结构搭建
- [x] 全局单例系统 (Config, EventBus, GameManager, SaveManager)
- [x] 基础数据模型 (Player, Profession, LevelSystem)
- [x] 回合管理系统 (TurnManager)
- [ ] 配置系统实现
- [ ] 基础UI框架

### Phase 2: 游戏系统 (4周)
- [ ] 卡牌系统 (CardManager)
- [ ] 海克斯系统 (HexManager)
- [ ] 商店系统 (ShopManager)
- [ ] AI系统 (AIController)
- [ ] 淘汰机制 (Elimination)

### Phase 3: 内容填充 (2周)
- [ ] 20个海克斯实现
- [ ] 15张策略卡实现
- [ ] 5个职业配置
- [ ] 基础音效/音乐

### Phase 4: 打磨测试 (2周)
- [ ] UI/UX优化
- [ ] AI难度调优
- [ ] 平衡性调整
- [ ] Bug修复
- [ ] 性能优化

---

## 十一、附录

### 11.1 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 类名 | PascalCase | `TurnManager`, `PlayerData` |
| 方法 | snake_case | `start_game()`, `modify_hp()` |
| 变量 | snake_case | `current_hp`, `player_list` |
| 常量 | UPPER_SNAKE_CASE | `INITIAL_HP`, `MAX_RANK` |
| 信号 | snake_case | `turn_started`, `player_died` |
| 文件 | snake_case | `game_manager.gd` |

### 11.2 颜色规范

| 用途 | 颜色值 | 说明 |
|------|--------|------|
| 主背景 | #1a1a2e | 深夜办公室 |
| 次背景 | #16213e | 面板背景 |
| 强调色1 | #0f4c75 | 霓虹蓝 |
| 强调色2 | #f39c12 | 橙色 |
| 普通海克斯 | #aaaaaa | 白色/灰色 |
| 稀有海克斯 | #3498db | 蓝色 |
| 史诗海克斯 | #9b59b6 | 紫色 |
| 传说海克斯 | #f1c40f | 金色 |

### 11.3 大规模AI性能优化（100人模式）

#### 优化目标
- 支持100人同局（1人类 + 99 AI）
- 保持60FPS流畅运行
- AI决策延迟 < 100ms

#### 优化策略

**1. 分帧处理（Frame Splitting）**

```gdscript
class_name AIManager

const AI_PER_FRAME: int = 10  # 每帧处理10个AI
var ai_queue: Array[AIController] = []
var processing: bool = false

func process_ai_batch() -> void:
	if ai_queue.is_empty():
		processing = false
		return
	
	var count = min(AI_PER_FRAME, ai_queue.size())
	for i in range(count):
		var ai = ai_queue.pop_front()
		ai.make_decision()
	
	# 下一帧继续处理
	if not ai_queue.is_empty():
		call_deferred("process_ai_batch")
```

**2. 决策缓存（Decision Caching）**

```gdscript
# AI缓存相似状态的决策结果
var decision_cache: Dictionary = {}

func get_cached_decision(state_hash: int) -> Action:
	return decision_cache.get(state_hash, null)

func cache_decision(state_hash: int, action: Action) -> void:
	decision_cache[state_hash] = action
	# LRU清理，保持缓存大小
	if decision_cache.size() > 100:
		decision_cache.erase(decision_cache.keys()[0])
```

**3. 分层AI评估（Hierarchical Evaluation）**

| 优先级 | AI类型 | 评估深度 | 处理时机 |
|--------|--------|----------|----------|
| 高 | 人类玩家周围3人 | 完整评估 | 立即处理 |
| 中 | 职级P8+的高威胁AI | 简化评估 | 分批处理 |
| 低 | 偏远/低威胁AI | 基础规则 | 每5帧处理1次 |

**4. 空间分区（Spatial Partitioning）**

```gdscript
# 将玩家按部门/职级分区，减少评估目标数
class_name PlayerGrid

var grid: Dictionary = {}  # department -> Array[Player]

func get_nearby_threats(player: Player, radius: int) -> Array[Player]:
	# 只评估同部门或相邻部门玩家
	var dept = player.department
	var threats = []
	for d in get_adjacent_departments(dept):
		threats.append_array(grid.get(d, []))
	return threats
```

**5. 简化评估算法（Simplified Heuristic）**

```gdscript
# 100人模式使用简化版Minimax
func fast_evaluate(player: Player) -> float:
	var score = 0.0
	
	# 仅评估关键指标（O(1)复杂度）
	score += player.current_kpi * KPI_WEIGHT
	score += player.current_hp * HP_WEIGHT
	score += player.total_salary * 0.01 * ECONOMY_WEIGHT
	
	# 跳过复杂的递归评估
	return score
```

**6. 对象池（Object Pooling）**

```gdscript
class_name AIObjectPool

var action_pool: Array[Action] = []
const POOL_SIZE: int = 200

func get_action() -> Action:
	if action_pool.is_empty():
		return Action.new()
	return action_pool.pop_back()

func recycle_action(action: Action) -> void:
	action.reset()
	if action_pool.size() < POOL_SIZE:
		action_pool.append(action)
```

**7. 异步预处理（Async Precomputation）**

```gdscript
# 在玩家行动时预处理AI决策
func _on_player_action_started() -> void:
	# 启动后台线程预处理下一回合AI决策
	Thread.new().start(_precompute_ai_decisions)

func _precompute_ai_decisions() -> void:
	for ai in ai_players:
		ai.precompute_next_turn()
```

#### 性能监控指标

| 指标 | 目标值 | 警告阈值 |
|------|--------|----------|
| 帧率 | 60 FPS | < 45 FPS |
| AI决策时间 | < 100ms | > 200ms |
| 内存占用 | < 512MB | > 1GB |
| 垃圾回收频率 | < 1次/分钟 | > 3次/分钟 |

#### 降级策略

当性能不足时自动降级：
1. **轻度降级**：AI评估深度从3层降到2层
2. **中度降级**：每帧处理AI数从10降到5
3. **重度降级**：远距离AI暂停思考，仅执行基础行为

#### 调试模式专用功能

```gdscript
# 调试模式（5人局）专用功能
class_name DebugManager

static var is_debug_mode: bool = false

## 快捷键处理
func _input(event: InputEvent) -> void:
	if not is_debug_mode:
		return
	
	if event.is_action_pressed("debug_show_all_status"):
		_show_all_players_status()
	elif event.is_action_pressed("debug_force_next_turn"):
		_force_next_turn()
	elif event.is_action_pressed("debug_add_hp"):
		PlayerData.modify_hp(50)
	elif event.is_action_pressed("debug_add_money"):
		PlayerData.modify_salary(1000)

## 显示所有玩家状态
func _show_all_players_status() -> void:
	for player in GameManager.players:
		print("[%s] HP:%d/%d KPI:%d Salary:%d Rank:P%d %s" % [
			player.player_name,
			player.current_hp, player.max_hp,
			player.current_kpi,
			player.total_salary,
			player.rank,
			"[AI]" if player.is_ai else "[玩家]"
		])

## 自动保存每回合状态
func _on_turn_ended(turn: int) -> void:
	if is_debug_mode:
		SaveManager.save_game("debug_turn_%d" % turn)
```

**调试模式快捷键**:
| 快捷键 | 功能 |
|--------|------|
| F1 | 显示所有玩家完整状态 |
| F2 | 强制进入下一回合 |
| F3 | 玩家HP +50 |
| F4 | 玩家工资 +1000 |
| F5 | 显示AI决策日志 |
| F9 | 快速存档 |
| F10 | 快速读档 |

### 11.4 参考文档

- [游戏策划案](./游戏策划案_职场大逃杀_完整版.md)
- [技术栈选型](./技术栈选型_职场大逃杀.md)
- [美术资源推荐](./美术资源推荐_职场大逃杀.md)

---

*文档维护: AI开发助手*  
*最后更新: 2026-03-25*
