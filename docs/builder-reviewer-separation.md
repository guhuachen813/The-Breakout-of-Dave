# 写代码的 AI 与挑毛病的 AI 要分开

## 这份文档要解决什么

在本项目上一轮开发里，验收标准、测试用例、检查脚本和"判定通过"全都出自同一个 AI——也就是写游戏代码的那一个。结果是它给自己定了一条最容易过的线，验收自然粗糙。

要根治这件事，只靠"换个更聪明的模型"或"让它再认真一点"没用。真正起作用的是两件事配套：

1. **角色分开**：写代码的 AI，不许同时给自己定标准、写测试、审自己、判自己过。
2. **标准钉在外面**：合格线由人维护（见 [`docs/development/acceptance-standard.md`](./development/acceptance-standard.md)），写代码的 AI 改不动，审查时也不能降低它。

本文档讲第 1 件在 Codex 框架下具体怎么落地，并说明它为什么有效。

## 原理：为什么"分一个 AI"还不够

参考开源框架 [superpowers](https://github.com/obra/superpowers) 的做法，"写代码的"和"挑毛病的"分开之所以有效，是三件事叠在一起，缺一不可：

1. **审查的那个是全新的**——不带写代码那个的记忆，所以没有"这是我写的、应该没问题"的自我袒护，也不会被前面的实现思路带着走。
2. **立场是对立的**——它的任务被定义成"挑错、找没做到的地方"，不是"确认没问题"。
3. **标准是事先写好、独立的**——审查第一步就是"对照规范逐条核对"，规范是提前定好的，不是临场编的。

第 3 件就是本项目那份验收标准。换句话说：**角色分离要能生效，必须有一份独立标准喂给审查的 AI。两件事是配套的，单独做任何一件都会落空。**

只开两个 AI、却让挑毛病那个自己临场决定什么算合格，等于没分。

## superpowers 是怎么做的

superpowers 是一套跨平台（Claude Code、Codex、Gemini 等都能用）的流程框架，本质是一堆 markdown 技能文件，强制 AI 走固定的工程流程。关于角色分离，它靠两个技能：

- **subagent-driven-development**：计划里每个任务，派一个全新的 subagent 去做，原来那个 AI 退到协调者位置。
- **requesting-code-review**：任务做完后，由另一个全新的 AI 审查，分两步——先查**是否符合规范**，再查**代码质量**；严重问题直接拦住，不许继续。

配合它还强制 TDD（先写测试、跑失败、再最小实现）、用 git worktree 隔离、把计划拆到 2～5 分钟一个任务。

## Codex 框架下的三条落地路线

Codex 自带两个机制，不装任何东西就能用。从省事到完整排列：

### 路线 A：直接用 `/review`（现在就能用）

Codex CLI 里输入 `/review`，它会**另起一个专门的审查 AI**，读你选的改动，只报问题、**完全不碰工作树**。菜单四个选项：对比分支、审查未提交改动、审查某个提交、**自定义审查指令**。

对本项目最有用的是"自定义审查指令"，把它指向那份验收标准：

```
对照 docs/development/acceptance-standard.md 逐条核对当前改动。
默认立场是“不通过”：每条标准必须有证据证明做到了，否则记为未通过。
按严重程度排序报告，严重问题必须拦住合入。
```

这一步就实现了"挑毛病的是另一个 AI，而且照着独立标准挑"。还能在配置里用 `review_model` 给审查换一个模型。

### 路线 B：固定一个 reviewer 角色（可复用、更稳定）

在项目里建 `.codex/agents/reviewer.toml`，把审查 AI 的职责写死，每次都一致：

```toml
# .codex/agents/reviewer.toml
name = "reviewer"
description = "对照验收标准挑错的独立审查 agent"
model = "gpt-5.4"              # 可与写代码那个用不同模型或档位
model_reasoning_effort = "high"
sandbox_mode = "read-only"     # 只读，碰不到代码
developer_instructions = """
你的职责是挑错，不是夸。
对照 docs/development/acceptance-standard.md 逐条核对当前改动。
默认立场是“不通过”：每条标准必须有证据，否则记为未通过。
按严重程度排序输出，严重问题必须拦住合入。不修改任何文件。
"""
```

（模型名按实际在用的填。）同样的办法，可以再建更多固定角色，把"写实现"、"写测试"、"核对覆盖率"和"视觉校对"都拆开：

- `builder`：只按主 Agent 指定范围写实现，不改验收标准，不做复核。
- `test-author`：照验收标准生成测试用例，只写测试。
- `acceptance-checker`：只核对"每条标准是否都有测试在管"，不写代码也不写测试。
- `visual-reviewer`：只读对照画面基准和真实运行截图，不写代码、不修 UI。

Codex 的 subagent 支持每个角色用不同模型、不同推理档位、不同读写权限。自定义 agent 文件放在 `~/.codex/agents/`（全局）或 `.codex/agents/`（项目内），主要字段：

| 字段 | 作用 |
| --- | --- |
| `name` | 角色名 |
| `description` | 用途说明 |
| `developer_instructions` | 角色的核心职责指令 |
| `model` | 指定模型（可与主 AI 不同） |
| `model_reasoning_effort` | 推理档位 `low/medium/high` |
| `sandbox_mode` | `read-only` 或 `workspace-write` |

并发和深度在主 `config.toml` 的 `[agents]` 段控制（`max_threads`、`max_depth`、`job_max_runtime_seconds`）。

另外 Codex 有 **auto-review**：AI 要做越界操作（改文件、跑命令）时，由一个独立 reviewer 决定批不批，而不是每次都问人，可进一步降低盯着它的成本。

### 路线 C：直接上 superpowers（要整套流程时）

想要完整的 brainstorm → 计划 → 每任务派新 AI 做 → 两阶段审查 → 收尾这一整套，在 Codex CLI 里用 `/plugins` 装 superpowers。注意：**它给的是通用工程流程，不含本游戏的验收标准**——标准那块仍要用本项目那份文档喂给它的审查环节。

## 一个要说清楚的点

Codex 的"分离"分的是**记忆和立场**，底座可能还是同一个模型。这已经够用——关键是全新的上下文、对立的立场、独立的标准，不是非得换一家模型。要更彻底，就在 `reviewer.toml` 里给审查角色配一个和写代码那个不同的 model，或更高的推理档位，独立性更强。

## 在本项目的落地顺序

1. 先用**路线 A** 跑一次：拿 [`docs/development/acceptance-standard.md`](./development/acceptance-standard.md) 当审查指令，对当前改动跑一遍 `/review`，看"独立 AI 照标准挑错"的实际效果。
2. 顺手了，用**路线 B** 把 reviewer 固化成项目里的角色，再视需要加 `builder`、`test-author`、`acceptance-checker`、`visual-reviewer`。
3. 在 `AGENTS.md` 的开发流程里补一条：**测试通过之后，必须先过一遍独立 reviewer；如果涉及画面，还要先过 `visual-reviewer`。它们都不能和写代码的是同一个 AI**。
4. 把这套和 [`docs/subagent-guide.md`](./subagent-guide.md) 对齐，避免两份文档讲法不一致。

## 来源

- [obra/superpowers（GitHub）](https://github.com/obra/superpowers)
- [Codex — Subagents 官方文档](https://developers.openai.com/codex/subagents)
- [Codex CLI — Features（含 /review）](https://developers.openai.com/codex/cli/features)
- [Codex — Auto-review](https://alignment.openai.com/auto-review/)
- [Superpowers: The Claude Code Skills Framework（Marc Nuri）](https://blog.marcnuri.com/superpowers-claude-code-skills-framework)
