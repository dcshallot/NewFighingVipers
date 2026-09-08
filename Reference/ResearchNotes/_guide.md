# Research Notes Guide

本目录只记录外部来源调查、提取测试、工具实验和可复用证据。研究笔记是历史事实层，**不能替代 `Docs/` 中的当前状态、正式决策、生产规格和计划**。

## File Naming

每个来源或测试运行使用一篇笔记：

- `YYYY-MM-DD-topic.md`
- `YYYY-MM-DD-source-name.md`
- `YYYY-MM-DD-extraction-test.md`

## Status Values

新笔记只使用：

- `todo`：尚未开始；
- `testing`：正在验证；
- `usable`：结论或方法当前可采用；
- `blocked`：缺少输入、环境或决定；
- `rejected`：已证明不适合目标；
- `historical`：只记录过去环境或状态；
- `superseded`：已被后续证据或正式决策替代；
- `reference`：保留局部经验，不作为生产路线。

旧笔记中的 `done`、`in-progress` 和自由格式状态按历史原文保留，不批量改写；当前解释以 `Docs/PROJECT_STATUS.md`、`Docs/DECISIONS.md` 和 `Tools/tool-manifest.csv` 为准。

## What Should Go Here

- 外部项目与资料来源；
- 模拟器和提取发现；
- 动作节奏观察；
- 模型、贴图和音频实验；
- 工具设置、失败条件和复现证据；
- 会影响正式规格的可复用结论。

## What Should Not Go Here

- 当前产品状态和路线图；
- 最终角色规格和 QA；
- 没有研究结果的一般任务计划；
- 大型二进制输出；
- 没有来源、哈希或上下文的截图；
- 密钥、账号和个人敏感路径。

## Related Locations

- 当前状态：`../../Docs/PROJECT_STATUS.md`
- 正式决策：`../../Docs/DECISIONS.md`
- 生产路线：`../../Docs/ROADMAP.md`
- 参考与资产清单：`../Manifests/`
- 本地 captures / original assets：`../../LocalData/`
- 提取工具：`../../Tools/Extraction/`

## Recommended Workflow

1. 复制 `_template.md` 并使用日期命名。
2. 先填写来源、目标、状态、环境和输入。
3. 将本地证据登记为逻辑路径，补 SHA-256；不要提交受限原文件。
4. 区分“命令运行成功”和“产出质量可用”。
5. 记录副作用、失败条件和替代路线。
6. 以 Decision 和 Next Action 结束。
7. 如果结论改变正式方案，在 `Docs/DECISIONS.md` 新增决策；不要只改历史笔记。
