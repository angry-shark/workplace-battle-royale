# 音频资源目录

## 目录结构

```
assets/audio/
├── bgm/          # 背景音乐
│   ├── main_menu.ogg    # 主菜单BGM
│   ├── game_main.ogg    # 游戏主BGM
│   └── victory.ogg      # 胜利BGM
├── sfx/          # 游戏音效
│   ├── card_draw.wav    # 抽卡音效
│   ├── card_play.wav    # 使用卡牌
│   ├── trap_trigger.wav # 触发陷阱
│   ├── damage.wav       # 受到伤害
│   ├── heal.wav         # 恢复HP
│   ├── coin.wav         # 获得金币
│   ├── level_up.wav     # 升级
│   ├── elimination.wav  # 玩家淘汰
│   ├── victory.wav      # 胜利
│   ├── defeat.wav       # 失败
│   ├── hex_acquire.wav  # 获得海克斯
│   ├── shop_buy.wav     # 购买商品
│   └── turn_start.wav   # 回合开始
└── ui/           # UI音效
    ├── click.wav        # 按钮点击
    ├── hover.wav        # 按钮悬停
    ├── panel_open.wav   # 面板打开
    ├── panel_close.wav  # 面板关闭
    ├── notification.wav # 通知提示
    ├── error.wav        # 错误提示
    └── success.wav      # 成功提示
```

## 推荐资源

### Kenney Audio Assets (免费，CC0)
https://kenney.nl/assets/category:Audio

推荐下载：
1. **UI Audio** - UI音效包
2. **Digital Audio** - 科幻风格音效
3. **RPG Audio** - 游戏通用音效

### 使用说明

1. 下载Kenney Audio资源包
2. 将合适的音频文件复制到对应目录
3. 确保文件名与上述列表一致
4. 建议使用 `.ogg` 格式（BGM）和 `.wav` 格式（音效）

## 格式建议

- **BGM**: OGG格式，192kbps，循环播放
- **SFX**: WAV格式，44.1kHz，单声道或立体声
- **UI**: WAV格式，44.1kHz，较短（<0.5秒）

## 音量建议

- BGM: -5dB ~ -10dB（相对主音量）
- SFX: 0dB（标准音量）
- UI: -3dB（略低于SFX）
