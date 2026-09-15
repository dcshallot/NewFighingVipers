# 决策记录

本文件保存决策历史。各章节原始 `Accepted` 表示当时被接受；当前生命周期以下表为准。当前事实只认 [`PROJECT_STATUS.md`](PROJECT_STATUS.md)。

| 决策 | 当前生命周期 | Evidence / 影响 |
| --- | --- | --- |
| D-001 | Dormant | 方向 C/B 当前均未激活 |
| D-002 | Recorded | Mac 测试报告与历史 AI 结论 |
| D-003 | Superseded | 被四 profile 支持矩阵替代 |
| D-004 | Archived | Unity 测试工程已删除 |
| D-005 | Archived exact replay | Blender 5.2.1 仅用于实验重放 |
| D-006 | Superseded | `Development/ENVIRONMENT.md` |
| D-007 | Active | 历史笔记与脚本继续保留 |
| D-008 | Recorded | Hunyuan 仍是非必需历史实验 |
| D-009 | Recorded | Honey 视觉研究规则 |
| D-010 | Recorded | P1-only 测试范围 |
| D-011 | Active archive decision | `../Reference/ResearchNotes/2026-09-09-mac-blender-honey-automation-test.md` |

新决策必须记录状态、证据、影响文件和替代关系，不静默改写版本或数据边界。

## D-001：先方向 C，后方向 B

- 日期：2026-09-08
- 状态：Accepted
- 决策：先完成 Honey 正常状态 C0～C6；通过 Gate 后才启动 1v1 战斗原型。
- 原因：当前没有可投产角色或游戏工程，同时推进会放大不确定性。
- 不包含：破甲状态、完整阵容、完整招式表和发布内容。

## D-002：AI 不作为最终角色生产主线

- 日期：2026-09-08
- 状态：Accepted
- 决策：Blender 手工／半手工制作是正式路线；AI 仅作概念、局部修图、体块参考、脚本和 QA 辅助。
- 证据：Honey Hunyuan3D 四视图／双视图结果已拒绝；Meshy/Mixamo 无法解决拓扑、复杂部件和权重。
- 替代历史假设：不再执行“截图 → AI 三视图 → AI 3D → 直接进入 Unity”。

## D-003：Mac-first，Windows 按需辅助

- 日期：2026-09-08
- 状态：Accepted
- 决策：Mac M4 是方向 C 和未来方向 B 的主开发机。
- Mac 职责：Blender、Unity、Python、FFmpeg、Git/LFS、文档和日常 QA。
- Windows 职责：Model 2、Noesis/Ninja Ripper、PowerShell 提取，以及方向 B 的 Windows Player、DirectX、手柄和目标硬件验证。
- 约束：Windows/CUDA 缺失不能阻塞 C0～C6；方向 B 发布候选必须通过 Windows 实机验证。

## D-004：Unity 6.6 + URP，新工程位于 `Game/`

- 日期：2026-09-08
- 状态：Accepted
- 决策：正式基线为 Unity `6000.6.0f1` Apple Silicon Editor，新建 URP 工程放在 `Game/`。
- 原因：这是当前正式 Supported 更新版，适合尚未产生 Unity 资产的新项目；兼顾 Mac 制作、Windows 验证和后续双角色性能。
- 当前验证：Unity Hub `3.21.1` 已安装，Editor `6000.6.0f1` 为原生 `arm64`。
- 历史说明：根目录 Unity `6000.4.1f1 + HDRP` 只是一段历史实验，当前 checkout 不包含该工程。
- 变更规则：Supported 更新版支持至下一更新版发布；后续升级必须新增决策并复验 URP、插件、角色导出和目标平台构建。

## D-005：Blender 5.2 LTS 为角色源工具

- 日期：2026-09-08
- 状态：Accepted
- 决策：建模、重拓扑、UV、骨架、权重和正式导出使用 Blender 5.2 LTS；当前验证安装版本为 `5.2.1`。
- 原因：5.2 已是官方 LTS，支持至 2028 年 7 月；项目尚未产生 4.5 正式资产或插件依赖，此时切换没有迁移成本。
- 约束：正式主文件必须可编辑；依赖插件必须登记版本和许可证；Blender 自动化优先使用内置 Python；项目制作期间只允许在 `5.2.x` 修订版本内升级，跨主版本或次版本升级必须新增决策并复验 Unity 导出。

## D-006：美术资产四层管理

- 日期：2026-09-08
- 状态：Accepted
- 决策：普通 Git 管文本和工程配置；Git LFS 管原创正式二进制；`LocalData/` 管受限、可再生和高噪声内容；独立存储负责备份。
- 约束：Git LFS 不是备份；ROM、dump、第三方包、来源不明参考和 AI 批量输出不得进入 LFS。
- 协作：不可合并 DCC 文件使用 LFS locking，并保持单阶段单 owner。

## D-007：不移动首轮历史脚本与笔记

- 日期：2026-09-08
- 状态：Accepted
- 决策：C0 先通过 README 和 manifest 分类，不移动或重命名现有工具、研究笔记。
- 原因：多个脚本依赖目录深度、当前工作目录或同目录包装器；直接移动会破坏复盘路径。

## D-008：Hunyuan/CUDA 不属于正式环境基线

- 日期：2026-09-08
- 状态：Accepted
- 决策：Hunyuan3D 只保留实验复盘，CUDA、NVIDIA GPU、vendor checkout 和模型权重均为可选项。
- 原因：当前 Honey 多视图路线已拒绝，Mac M4 不支持 CUDA，这不应阻塞正式角色制作。

## D-009：Model 2 为 Honey 可见外观主标准

- 日期：2026-09-09
- 状态：Accepted
- 决策：可追溯的 Model 2 正常状态实战画面优先裁决 Honey 的轮廓、比例、主要色块和可见部件；Saturn 只补充 Model 2 无法看清的隐藏结构，并标记为 provisional。
- 冲突规则：先排除正常／破甲、P1／P2、实战／展示资产、透视和动作形变差异；确属平台差异时分别记录，不做平均设计。
- 颜色规则：Model 2 多帧彩色画面优先；灰度 dump 不能裁决 albedo；Saturn 彩色资料只作支持证据。
- AI 规则：AI、Meshy、Hunyuan 和来源不明同人图不参与事实票决。
- 证据变化：2026-09-09 核验 The Models Resource 与 The Textures Resource 的 Saturn Fighting Vipers 分类页均为 0 assets，因此不再把它们视为现成 Honey 资产来源。

## D-010：当前只制作 P1，允许多帧重建

- 日期：2026-09-09
- 状态：Accepted
- 决策：方向 C 只制作 Honey P1 红色正常状态；P2 蓝色不作为独立角色资产，未来需要时从批准的 P1 材质派生。
- 输入：当前 5 段视频和 33 张图片均由用户自行录制，允许作为本地研究参考。
- 标准视图：原作没有标准站姿不构成阻塞；使用多帧、不同动作和 replay 角度组合测量，并记录误差范围。
- 缺失细节：原作分辨率和遮挡无法确认的背面连接、厚度和内部结构可采用 `artist-reconstruction`，但不得改变关键轮廓，并在 C2 评审时允许修订。
- 补采策略：不再主动收集清晰度和角度相近的普通对战视频；只有 C2 暴露具体部件证据缺口时才定向补采。

## D-011：结束并归档本次 Mac Blender 自动化测试

- 日期：2026-09-09
- 状态：Accepted
- 范围：只适用于本次 Mac M4、Blender `5.2.1`、MPFB `2.0.17` 与通用 LLM/Blender Python 测试。
- 决策：停止继续自动迭代 v005；保留 v005 模型和 v003/v005 两张评审板作为证据，删除 Unity 空白工程和中间物。
- 原因：自动化已证明能完成环境、自然人体、贴体壳和固定 QA，但无法在低人工介入下完成 Honey 的脸、发型、服装造型、最终拓扑、材质和动作变形。
- 非结论：不否定整个 Honey 项目、方向 C、其他平台、未来模型或专用 Meshy/Hunyuan/Tripo 路线。
- 重启：需满足高质量许可源资产、同输入有效的专用角色到 3D 模型、专业角色美术资源或 placeholder 玩法优先之一。
