# Fighting Vipers Research Prototype

本仓库现在是 **Fighting Vipers / Honey 资产研究与原型方案归档**。它不再描述一个正在推进的完整 Unity fan remake，也不把 AI 高清化当作当前可行主线。

前一阶段已经验证过多条路线：Model 2 运行时贴图 dump、视频抽帧和截图比对、AI 三视图、Hunyuan3D、Meshy、Mixamo / Unity 导入、OpenKeeper 横向参考。总体结论是：**当前 AI 高清化 / AI 生成 Fighting Vipers 角色资产的方案不可直接产出可用游戏资产**。项目现在只保留阶段性产物、研究笔记和可复盘脚本。

更细的 Honey 抽帧、截图、贴图 dump、AI 生成模型和 OpenKeeper 路线索引见：

- `Reference/ResearchNotes/2026-05-10-honey-frame-screenshot-assets.md`

## 当前判断

- 原始游戏研究仍然有价值，尤其是贴图归属、角色比例、材质分区、动作参考。
- AI 可以做辅助图、局部 paintover、粗略体块观察，但不适合作为主生产链路。
- 如果目标是可玩原型，应该先用占位角色完成 combat slice，不要被 Honey 最终资产阻塞。
- 如果目标是 Honey 视觉重建，应改走手工 / 半手工建模、重拓扑、绑定、材质参考路线。
- 如果目标是资产研究，应继续沿原始资源、模拟器、公共 Saturn 资源、社区逆向工具方向推进。

## 保留内容

### Research Notes

- `Reference/ResearchNotes/2026-04-02-model2-honey-texture-pipeline-progress.md`
- `Reference/ResearchNotes/2026-04-03-model2-honey-model-extraction-routes.md`
- `Reference/ResearchNotes/2026-04-03-unity-project-setup-and-model-import-log.md`
- `Reference/ResearchNotes/2026-04-04-meshy-honey-unity-route.md`
- `Reference/ResearchNotes/2026-04-05-hunyuan3d-2mv-four-view-two-view-failure.md`
- `Reference/ResearchNotes/2026-04-06-meshy-single-front-reference-observation.md`
- `Reference/ResearchNotes/2026-05-10-honey-frame-screenshot-assets.md`

### Local Research Assets

这些目录是本机研究资产，不应默认提交：

- `Reference/Captures/`
- `Reference/OriginalAssets/`
- `Resources/`
- `Assets/`
- `Packages/`
- `ProjectSettings/`

`Resources/neonlightingforece/` 目前仅作为 Neon Lightning Force OpenBOR 包体、Melania sprite carve 和非 AI 放大实验记录，仍属于本地-only 研究资产。

### Tooling

- `Tools/Extraction/Model2/`：Model 2 dump、抽帧、筛选、辅助分析脚本。
- `Tools/Generation/Hunyuan3D/`：Hunyuan3D 包装脚本和实验入口。
- `Tools/Windows/Run-OpenKeeper-DK2.ps1`：OpenKeeper / DK2 横向参考运行脚本。

## 参考资源

### 原始资料 / 社区资料

| 方向 | 资源 | 用途 | 当前建议 |
| --- | --- | --- | --- |
| Saturn 模型 | [`The Models Resource - Fighting Vipers`](https://models.spriters-resource.com/saturn/fightingvipers/) | 快速查看角色比例、轮廓、部件结构。 | 高优先级参考。适合重启视觉重建时先看。 |
| Saturn 贴图 | [`The Textures Resource - Fighting Vipers`](https://textures.spriters-resource.com/saturn/fightingvipers/) | 研究贴图分区、颜色、UI、材质风格。 | 高优先级参考。比 AI 猜测更可靠。 |
| Saturn 声音 | [`The Sounds Resource - Fighting Vipers`](https://sounds.spriters-resource.com/saturn/fightingvipers/) | 研究打击反馈、语音、UI 声音节奏。 | 可用于 combat slice 反馈设计。 |
| 隐藏内容 | [`TCRF - Fighting Vipers (Saturn)`](https://tcrf.net/Fighting_Vipers_(Sega_Saturn)) | 版本差异、隐藏内容、调试信息。 | 研究原作内容边界。 |
| 街机信息 | [`TCRF - Fighting Vipers (Arcade)`](https://tcrf.net/Fighting_Vipers_(Arcade)) | 对照 Saturn 和 Model 2 差异。 | 中优先级。 |
| 社区讨论 | [`SegaXtreme - Fighting Vipers`](https://segaxtreme.net/tags/fighting-vipers/) | 补丁、提取经验、冷门线索。 | 遇到 Saturn 资源问题时查。 |
| 原型版本 | [`Hidden Palace - Fighting Vipers prototype`](https://hiddenpalace.org/Fighting_Vipers_(Jul_5,_1996_prototype)) | 历史版本、差异研究。 | 研究价值高，不是生产主路径。 |

### 提取 / 转换工具

| 工具 | 用途 | 当前建议 |
| --- | --- | --- |
| [`cyberwarriorx/vcdextract`](https://github.com/cyberwarriorx/vcdextract) | Saturn disc 内容提取。 | 可作为 Saturn 原始资源研究入口。 |
| [`doyousketch2/SatRGB`](https://github.com/doyousketch2/SatRGB) | Saturn 图像 / 调色板相关研究。 | 适合贴图和 palette 方向继续试。 |
| Model 2 Emulator `Dump texture cache` | 运行时 texture cache dump。 | Honey 贴图归属验证最可靠的本地路线之一。 |
| `_NinjaRipper` + Noesis | 运行时 mesh / texture 抓取和检查。 | 只作局部轮廓和贴图归属参考，不当完整模型提取方案。 |
| Blender | 检查、清理、重拓扑、绑定、格式转换。 | 如果重启 Honey 角色，应该成为主工具之一。 |

### Gameplay / Unity 参考

| 资源 | 用途 | 当前建议 |
| --- | --- | --- |
| [`tryandev/divekick-unity3d`](https://github.com/tryandev/divekick-unity3d) | 简单 3D fighting prototype 参考。 | 如果重启可玩原型，优先看 combat loop。 |
| [`OmarAlesharie/Fighting-Survival`](https://github.com/OmarAlesharie/Fighting-Survival) | Unity 3D 战斗结构参考。 | 可作为 secondary gameplay reference。 |
| [`homemech/unity-pattern-combo`](https://github.com/homemech/unity-pattern-combo) | command pattern combo demo。 | 只适合后期输入缓冲 / combo 架构，不适合早期。 |

### 横向参考

| 资源 | 用途 | 当前结论 |
| --- | --- | --- |
| [`tonihele/OpenKeeper`](https://github.com/tonihele/openkeeper) + 本机 Steam `Dungeon Keeper 2` | 观察老游戏原始资产如何接入开源重实现引擎。 | 能运行，但完成度不到可玩；高清材质方向未继续实验。 |

OpenKeeper 本地测试要求：

- DK2 安装目录：`C:/Program Files (x86)/Steam/steamapps/common/Dungeon Keeper 2`
- checkout：`Reference/OriginalAssets/OpenKeeper`
- 脚本：`Tools/Windows/Run-OpenKeeper-DK2.ps1`
- JDK 25+，`java` 和 `javac` 需要在 `PATH`

### AI 工具定位

AI 工具只作为辅助，不再作为主生产方案。

| 工具 / 方向 | 适合用途 | 不适合用途 |
| --- | --- | --- |
| Keling / Kling / Seedance | 缺失视角的概念补图、动作参考探索。 | 直接生成最终三视图生产资产。 |
| Qwen / character sheet 类工具 | 做设计草图、turnaround 草案。 | 直接替代原始资料和人工建模。 |
| OpenPose / pose editor | 给动作图或 paintover 定姿势。 | 自动解决动作系统。 |
| SDXL inpainting / 局部重绘 | 修局部参考图、做方案对比。 | 还原原版材质和拓扑。 |
| Image-to-3D / Meshy / Hunyuan3D | 粗略体块检查、快速原型观察。 | 直接产出可绑定、可动画、可入库角色。 |

## 可以尝试的后续方向

### 方向 A：资产研究继续

目标是把 Honey / Fighting Vipers 的原始资源关系研究得更清楚。

- 继续整理 Model 2 dump 与截图证据。
- 单独研究 palette、材质色、顶点色或光照对灰度贴图的影响。
- 对照 Saturn 公共模型 / 贴图资源，建立部件、材质、比例参考。
- 只在能闭环验证时继续做 `NormId -> 部位 -> UV` 映射。

### 方向 B：可玩原型重启

目标是先证明 Fighting Vipers 风格的 combat slice，而不是先追最终 Honey 资产。

- 用占位角色或公开资源快速搭 1v1 arena。
- 先做移动、站立、拳、脚、防御、受击、击退、hit stop。
- 只用原作视频、声音和动作节奏作参考。
- Honey 最终模型后置，不阻塞玩法。

### 方向 C：Honey 视觉重建

目标是得到一个可控制、可绑定、可修的 Honey 角色。

- 以公开 Saturn 资源、Model 2 截图、Honey_Master_TextureSet 为参考。
- 在 Blender 里手工 / 半手工建低模或中模。
- 明确先做正常状态，不做破甲状态。
- 拓扑、UV、骨骼、权重人工控制，AI 只做局部参考图。

### 方向 D：工具链整理

目标是让已有实验可复盘，而不是继续堆素材。

- 把保留脚本分成“可用”“实验”“废弃”。
- 给每个脚本补最小 usage。
- 清理本地-only 大型中间产物。
- 将 `Reference/ResearchNotes/` 作为唯一长期文字记录入口。

## Git / 本地文件策略

Git 只保存研究结论和可复盘脚本，不承载 Unity 工程和二进制资产。

可以保留：

- `README.md`
- `Reference/ResearchNotes/`
- `Tools/Extraction/`
- `Tools/Generation/` 里的自写脚本和包装脚本
- `Tools/Windows/`
- `.gitignore`

本地-only：

- `Assets/`
- `Packages/`
- `ProjectSettings/`
- `Library/`
- `Logs/`
- `UserSettings/`
- `Resources/`
- `Reference/Captures/`
- `Reference/OriginalAssets/`
- `Tools/Generation/**/vendor/`
- `Tools/Generation/**/cache/`
- AI 生成模型、视频抽帧、模拟器 dump、Unity 导入产物、第三方项目 checkout

## 重启原则

1. 不要从“继续 AI 高清化”开始。
2. 先选清楚目标：资产研究、可玩原型、视觉重建、还是工具链整理。
3. 资产研究优先走可验证原始资料。
4. 可玩原型优先走占位角色和 combat loop。
5. Honey 视觉重建优先走人工可控流程。
6. AI 只作辅助，不作主链路。
