# Lessons

完整经验记录放在这里。每条经验必须来自真实遇到并处理过的问题。

## Template

```md
### YYYY-MM-DD | 简短标题

- 场景：
- 现象：
- 影响：
- 原因：
- 修复：
- 验证：
- 下次规则：
- 关联文件 / 提交：
```

## Records

暂无。

### 2026-08-23 | Godot 开局键盘焦点

- 场景：运行时主场景使用 CanvasLayer 动态创建 HUD，主循环直接读取输入。
- 现象：首次启动时 WASD 可能无效，点击技能或升级控件后才恢复移动。
- 原因：窗口/嵌入游戏视图没有稳定的 GUI 键盘焦点；仅调用 `gui_release_focus()` 不能保证后续输入路由。
- 修复：给 HUD 根 Control 设置 `FOCUS_ALL`，启动和窗口获得焦点时主动 `grab_focus()`，移动同时读取已配置的 InputMap 动作。
- 验证：Godot headless 编辑器和启动检查通过；需在实际窗口启动后第一秒直接按 WASD 做人工回归。
- 下次规则：动态 HUD 初始化后必须显式设置键盘焦点目标，并在窗口重新获得焦点时恢复。
- 关联文件 / 提交：`scripts/Main.gd`、`scripts/GameUI.gd`、`scripts/GameConfig.gd`
