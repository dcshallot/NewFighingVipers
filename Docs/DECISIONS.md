# 正式决策记录

本文件记录当前有效决策。研究笔记保留历史事实，但不能覆盖这里的决策。新决策按相同格式追加，不静默改写版本、平台或资产边界。

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

## D-004：Unity 6 + URP，新工程位于 `Game/`

- 日期：2026-09-08
- 状态：Accepted
- 决策：初始目标版本为 Unity `6000.4.1f1` Apple Silicon Editor，新建 URP 工程放在 `Game/`。
- 原因：兼顾 Mac 制作、Windows 验证和后续双角色性能；与研究工具和受限素材隔离。
- 历史说明：根目录 Unity `6000.4.1f1 + HDRP` 只是一段历史实验，当前 checkout 不包含该工程。
- 变更规则：若该版本无法稳定复现，必须新增决策记录批准替代版本。

## D-005：Blender 4.5 LTS 为角色源工具

- 日期：2026-09-08
- 状态：Accepted
- 决策：建模、重拓扑、UV、骨架、权重和正式导出使用 Blender 4.5 LTS。
- 约束：正式主文件必须可编辑；依赖插件必须登记版本和许可证；Blender 自动化优先使用内置 Python。

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
