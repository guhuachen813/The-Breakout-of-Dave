# Experience Library

Experience Library 用于沉淀本仓库开发时真实踩过、修过、验证过的问题。它不是事后总结，也不是泛泛建议；只有遇到问题并解决之后，才写入经验库。

## 文件

| 文件 | 用途 |
| --- | --- |
| `active-rules.md` | 每次开发前必须读的短规则，只放高频、关键、容易复犯的问题 |
| `lessons.md` | 完整经验记录，按条目记录现象、原因、修复、验证和下次检查方式 |

## 使用规则

每次执行新方案前：

1. 先读 `AGENTS.md`。
2. 再读 `docs/experience-library/active-rules.md`。
3. 如果当前任务涉及已记录问题，再读 `docs/experience-library/lessons.md` 中相关条目。

遇到问题并解决后：

1. 必须在 `docs/experience-library/lessons.md` 新增经验条目。
2. 如果这个问题会高概率复发，必须把短规则补充到 `docs/experience-library/active-rules.md`。

不要写入：

- 没有复现过的问题。
- 没有解决的问题，除非明确标为“未解决”并写清阻塞原因。
- 泛泛而谈的建议，例如“注意测试”“代码要清晰”。
- 为了显得完成而写的空洞总结。

## 经验条目格式

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
