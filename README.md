# New Fighting Vipers

以 **Honey 正常状态高清重建**为当前目标的 Fighting Vipers 研究与制作仓库。项目先完成方向 C 的可维护角色资产；通过 C6 验收后，才进入方向 B 的 1v1 战斗原型。

> 本项目不包含 ROM、模拟器、原作二进制资产或其他受限素材。使用者必须自行确认所用参考和资产的权利边界。

## 当前状态

- 当前阶段：**C0 — 制作基线整理中**
- 当前角色：Honey 正常状态
- 主开发机：Apple Silicon Mac（Mac M4）
- 辅助平台：Windows，仅用于 Model 2 等定向提取和后续目标平台验证
- 角色主流程：Blender 手工／半手工建模、人工拓扑、UV、绑定和权重
- 游戏验证：Unity 6 + URP，工程预留在 `Game/`
- 方向 B：**未准入**

当前 checkout 仍不包含可打开的 Unity 工程、Honey 可投产模型或历史本地采集文件。Unity `6000.4.1f1 + HDRP` 只是一段历史实验记录；新的正式基线采用 URP。

详见 [`Docs/PROJECT_STATUS.md`](Docs/PROJECT_STATUS.md)。

## 快速导航

| 内容 | 入口 |
| --- | --- |
| 当前事实与风险 | [`Docs/PROJECT_STATUS.md`](Docs/PROJECT_STATUS.md) |
| C0～C6 路线与 C→B Gate | [`Docs/ROADMAP.md`](Docs/ROADMAP.md) |
| 正式技术决策 | [`Docs/DECISIONS.md`](Docs/DECISIONS.md) |
| 开发环境 | [`Docs/Development/SETUP.md`](Docs/Development/SETUP.md) |
| 资产生产流程 | [`Docs/Development/ASSET_PIPELINE.md`](Docs/Development/ASSET_PIPELINE.md) |
| 美术资产管理 | [`Docs/Development/ART_ASSET_MANAGEMENT.md`](Docs/Development/ART_ASSET_MANAGEMENT.md) |
| 版本控制 | [`Docs/Development/VERSION_CONTROL.md`](Docs/Development/VERSION_CONTROL.md) |
| Honey 角色规格 | [`Docs/Production/Honey/CHARACTER_BIBLE.md`](Docs/Production/Honey/CHARACTER_BIBLE.md) |
| Honey 技术规格 | [`Docs/Production/Honey/ASSET_SPEC.md`](Docs/Production/Honey/ASSET_SPEC.md) |
| Honey 验收表 | [`Docs/Production/Honey/QA_CHECKLIST.md`](Docs/Production/Honey/QA_CHECKLIST.md) |
| 历史研究 | [`Reference/ResearchNotes/`](Reference/ResearchNotes/) |
| 工具分类 | [`Tools/README.md`](Tools/README.md) |

## 目录职责

```text
Docs/                  当前有效的方案、决策、规格与验收标准
Reference/ResearchNotes/ 历史实验、来源调查和失败证据
Reference/Manifests/   参考资料与正式资产的元数据
ArtSource/             可发布的原创美术工作源文件（大型文件使用 LFS）
LocalData/             ROM、dump、原作参考、AI 中间物等本地内容
Game/                  Unity URP 验证工程及未来方向 B 工程
Tools/                 自写工具、工具清单和环境检查
```

历史笔记不会因为结论过时而被删除；**当前决策以 `Docs/` 为准**。

## 当前生产原则

1. 先完成 Honey 正常状态，不做破甲版和完整阵容。
2. 参考优先级为可追溯原始资料、公开 Saturn 资源、Model 2 截图与视频；AI 输出不能替代证据。
3. AI 只用于概念辅助、局部修图、粗略体块、脚本和视觉 QA，不直接产出最终角色。
4. `.blend`、拓扑、UV、骨架和权重必须可人工维护。
5. C6 前，`Game/` 仅用于比例、材质、动画和性能验证，不扩展完整战斗系统。
6. ROM、模拟器 dump、第三方包、来源不明素材和批量生成物不得进入 Git 或 Git LFS。

## 已验证的历史结论

- Model 2 texture cache dump 对贴图归属研究有价值，但灰度 PNG 不是最终 albedo。
- Ninja Ripper 网格只适合作局部轮廓和贴图归属参考。
- Honey 的 Hunyuan3D 四视图／双视图结果没有达到可修门槛，已拒绝作为生产路线。
- Meshy/Mixamo 可帮助快速验证，但不能解决 Honey 的裙摆、双马尾、袖口、拓扑和权重问题。
- 历史 Unity 场景和本地生成模型未包含在当前仓库中。

证据索引见 [`Reference/ResearchNotes/2026-05-10-honey-frame-screenshot-assets.md`](Reference/ResearchNotes/2026-05-10-honey-frame-screenshot-assets.md)。

## 开始工作

1. 阅读 [`Docs/Development/SETUP.md`](Docs/Development/SETUP.md)。
2. 复制 `Tools/Environment/toolchain.example.toml` 为本地 `toolchain.local.toml`。
3. 运行 `python3 Tools/Environment/check_environment.py`。
4. 在添加参考或资产前更新 `Reference/Manifests/` 中对应清单。
5. 按 [`Docs/ROADMAP.md`](Docs/ROADMAP.md) 的当前里程碑工作，不跨 Gate。

## 方向 B 准入

只有 Honey 通过 C6，并满足可维护源模型、稳定导出、来源闭环、固定动作变形、视觉和性能验收后，方向 B 才能启动。完整条件见 [`Docs/ROADMAP.md`](Docs/ROADMAP.md#方向-c-到方向-b-的-gate)。
