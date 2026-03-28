# 角色头像资源

## 头像规格
- 尺寸: 128x128 像素
- 格式: PNG (带透明通道)
- 风格: 扁平化、Q版

## 头像列表

| 文件名 | 职业 | 主色调 |
|--------|------|--------|
| programmer.png | 程序员 | 蓝绿色 #2ecc71 |
| hr.png | HR | 紫色 #9b59b6 |
| finance.png | 财务 | 深蓝色 #34495e |
| operations.png | 运营 | 橙色 #e67e22 |
| sales.png | 销售 | 红色 #e74c3c |

## 状态变体

每个头像需要以下状态:
- 正常 (normal)
- 灰度 (grayscale) - 淘汰时使用
- 选中高亮 (highlight) - 选中时发光效果

## 生成占位文件

运行以下命令生成占位文件:
```bash
cd assets/images/avatars
touch programmer.png hr.png finance.png operations.png sales.png
```

## 推荐素材来源

1. **Kenney Assets** (CC0)
   - https://kenney.nl/assets/roguelike-characters
   
2. **OpenGameArt** (CC-BY/CC0)
   - 搜索 "character portrait" 或 "avatar"

3. **使用 Emoji 临时替代**
   - 程序员: 👨‍💻
   - HR: 👩‍💼
   - 财务: 👨‍💼
   - 运营: 👩‍💻
   - 销售: 👨‍💼
