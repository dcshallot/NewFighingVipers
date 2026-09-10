# Mac M4 上 Honey Blender 自动化测试技术说明

测试日期：2026-09-08 至 2026-09-09  
状态：已结束并归档  
结论范围：**仅适用于本次 Mac M4 + Blender 5.2.1 + MPFB 2.0.17 + 通用 LLM/脚本自动化测试**

## 1. 测试问题

本次测试希望回答：在已有 Honey 原作研究基础上，使用当前 Mac M4 开发环境、Blender 5.2.1、MPFB 2.0.17 和通用大模型生成的 Blender Python 自动化，能否在几乎没有角色美术人工介入的情况下，生成接近可用成品的 Honey P1 正常状态角色。

本次测试不评估：

- 所有未来 AI 3D 模型；
- Meshy 7、Hunyuan 3D 3.1、Tripo 等专用图生 3D 的最终上限；
- Windows/Linux 上的其他 DCC 或 CUDA 管线；
- 有专业角色美术深度参与时的可行性；
- 整个方向 C 或 Honey 项目的永久可行性。

2026 年 4～5 月的 Model 2 dump、Ninja Ripper、Hunyuan3D-2mv、Meshy、Mixamo 和历史 Unity 实验只作为前置背景，详见 `Reference/ResearchNotes/`。

## 2. 环境

| 项目 | 版本／状态 |
| --- | --- |
| 主机 | Apple Silicon Mac M4 Pro |
| Blender | 5.2.1 LTS |
| MPFB | 2.0.17 |
| MPFB 官方包 SHA-256 | `4f0a879d64a39bf646fbf5f53601ac678855da329d650617dca5737548239a87` |
| Unity 验证环境 | 6000.6.0f1 Apple Silicon |
| URP | 17.6.0 |
| Python | 3.14.3 |
| Git | 2.48.1 |
| Git LFS | 3.7.1 |
| FFmpeg | 8.1 |

MPFB 代码使用 GPL-3.0-or-later；本次人物基线只使用 MPFB/MakeHuman 官方 CC0 1.0 核心人体，没有采用许可未核验的社区衣服、头发或皮肤。

## 3. 输入与证据边界

- 5 段用户自行录制的 Model 2 Honey P1 1080p 视频，约 116 秒；
- 33 张自录截图或裁剪图；
- 12 张固定视角和结构参考；
- P1 红色正常状态为唯一生产范围；
- P2 不制作独立资产，未来需要时仅作为材质配色变体；
- 原始 input 由用户保存在工作区外，仓库只保留名称、分类、大小与 SHA-256 索引；
- AI 生成图和来源未确认的社区 render 不参与原作事实裁决。

## 4. 测试路线

### 4.1 工程与自动化基线

完成了 Mac-first 工具链固定、只读环境检查、Git/LFS 规则、manifest、固定六视图和 Unity URP 空白验证工程。该部分证明了通用大模型在环境搭建、脚本编写、重复执行、QA 和文档治理方面的明显进步。

### 4.2 程序积木 Blockout v002

使用 Blender Python 将人体、服装、头发、靴子和背饰拆为球体、锥体、方块与简单曲线。

技术结果：

- 64 meshes；
- 8 materials；
- 固定六视图可自动输出；
- 生成和重新打开可复现。

视觉结果：失败。人体像廉价玩具，肩甲、裙摆、靴子、发束和背翼都缺少角色造型质量。该路线说明“可自动生成几何”不等于“可自动完成角色美术”。模型和渲染已删除，生成脚本作为失败证据保留。

### 4.3 MPFB 基础人体 v003

固定 MPFB 2.0.17，使用官方 CC0 核心人体，生成年轻、修长、适度运动感的女性基础体型。

定量结果：

- 19,158 vertices；
- 尺寸约 `1.021 × 0.405 × 1.678 m`；
- 胸廓、腰、骨盆和关节连续性明显优于程序积木；
- 六视图评审通过基础人体 Gate。

源 `.blend` 在最终归档中删除，只保留压缩六视图作为人体基线证据。

### 4.4 MPFB 贴体服装 Blockout v005

从 MPFB 人体表面提取贴体壳，并使用参数化裙摆、肩部壳、前臂护甲、长靴壳、曲线后发束和背饰。

定量结果：

- 42 objects；
- 24 meshes；
- 14 curves；
- 8 materials；
- Blender 5.2.1 可重新打开；
- 六视图可复现。

改善：

- 人体不再由基本几何拼接；
- 衣身、下装、护手和靴子贴合真实人体；
- 肩部不再是完整球体；
- 长靴连续覆盖脚部；
- 发束和背饰由平滑曲线生成。

仍然未达到成品门槛：

- MPFB 通用脸缺少 Honey 识别度；
- 刘海、后发束需要角色美术级组织；
- 裙摆、蕾丝和背饰缺少真实服装构造；
- 靴口、足弓、鞋头和鞋跟需要手工塑形；
- 胸甲分段、带扣和材质细节仍是占位；
- 尚未验证最终拓扑、UV、骨骼、权重和格斗动作变形。

## 5. 自动化能力的实际提升

相较 2026 年 5 月，本次测试确认自动化显著改善了：

- 开发环境检测和版本固定；
- Blender 扩展安装与版本验证；
- MPFB 人体参数化生成；
- 贴体 mesh shell、参数化裙摆和曲线部件；
- 固定视角渲染、评审板、SHA-256 与 manifest；
- Unity 工程初始化和批处理验证；
- 中间物识别与云盘空间清理；
- 文档、工具状态和风险边界管理。

这些能力可降低技术美术和工程重复劳动，但不能替代角色设计与造型判断。

## 6. 未被自动化解决的核心问题

- 从低清、多动作原作画面稳定恢复一致的角色设计；
- 忠实且有审美质量的脸型、发型和服装；
- 不可见背面结构的合理且忠实补全；
- 裙摆、蕾丝、发束、背翼、肩甲和长靴的专业形体；
- 动画友好的最终拓扑；
- 干净 UV、PBR 材质和原作色彩还原；
- 自动骨骼和权重在高踢、受击等格斗动作下的质量；
- 在低人工介入条件下把“完整模型”提升到“专业成品”。

更换同类通用大模型继续生成 Blender 脚本，可能改善操作和参数，但不预计产生角色质量的跃迁。专用图生 3D 仍可能提升视觉完整度，但本次测试未完成对 Meshy 7、Hunyuan 3D 3.1 或 Tripo 的同输入正式对照，因此不作否定结论。

## 7. 本次测试结论

**No-Go，仅针对本次 Mac Blender 自动化分支。**

在“几乎没有角色美术人工介入”的约束下，Blender 5.2.1 + MPFB 2.0.17 + 通用 LLM/脚本可以稳定完成环境、自然人体、粗略贴体服装和评审流程，但无法把 Honey P1 自动推进到可信的高清成品或 animation-ready 格斗角色。

这不表示：

- Honey 无法被重建；
- 方向 C 永久不可行；
- 未来专用多视图角色到 3D 模型不可行；
- 有专业角色美术参与时不可行。

## 8. 重启条件

满足任一条件时可重新测试：

1. 获得许可明确、接近目标体型的 production-ready 女性角色源资产；
2. 专用多视图 character-to-3D 模型在同一 Honey 输入上已证明能输出忠实脸部、服装分件和可绑定拓扑；
3. 有明确的角色美术预算承担脸、发型、服装、拓扑和权重；
4. 将目标改为玩法优先，使用 placeholder 推进方向 B，再延期替换最终角色。

## 9. 最终保留物

| 类型 | 路径 | SHA-256 |
| --- | --- | --- |
| 自动化上限模型 | `ArtSource/Characters/Honey/Blockout/Honey_ClothingBlockout_v005.blend` | `7a04eab30ad5e9811b457027dbde19afb0d378a0023648b93ca6511af9d49b5c` |
| MPFB 人体评审板 | `Reference/Archive/MacBlenderHoneyTest/Honey_BaseBody_v003_review_board.jpg` | `ca737f33880e281db9d78dd250af6c4c0fd3eb724bfae7ec23c309c539bb094d` |
| 服装自动化评审板 | `Reference/Archive/MacBlenderHoneyTest/Honey_ClothingBlockout_v005_review_board.jpg` | `40d9727989e5efc11c8a661f67c05cd3298f7f15a8a7996d9fb5d6c58f96ddbb` |

同时保留：历史研究笔记、manifest、三个 Blender 复盘脚本、环境检查及原有 Model 2/Hunyuan/Windows 工具。

## 10. 清理范围与体积

清理前递归磁盘占用：

- 工作区：`1,135,964 KiB`；
- `Game/`：`1,101,624 KiB`；
- `LocalData/`：`25,264 KiB`；
- `ArtSource/`：`5,284 KiB`。

清理内容：本次测试初始化的 Unity 工程及缓存、v003 源模型、逐视角 PNG、P1 工作截图副本、AI 概念图、社区 render、临时测试和空目录。外部 Downloads input 与 `.codebuddy/` 不受影响。

清理后递归磁盘占用：

- 工作区：`6,884 KiB`；
- `Game/`：`16 KiB`，仅保留墓碑 README；
- `LocalData/`：`4 KiB`，仅保留墓碑 README；
- `ArtSource/`：`2,904 KiB`，仅保留 v005 模型及目录说明；
- `Docs/`：`60 KiB`；
- `Reference/`：`348 KiB`；
- `Tools/`：`252 KiB`。

工作区从 `1,135,964 KiB` 降至 `6,884 KiB`，减少约 `99.39%`。

## 11. Git 归档状态

按用户要求，本次只整理工作区，**未创建 commit、tag 或 push**。v005 已匹配 Git LFS 规则，但 manifest 中保留 `lfs-configured-not-pushed` 与 `uncommitted`，准确表示它尚未形成远端版本归档。当前文件仍可由本机 Blender 5.2.1 打开且 SHA-256 已核验；若未来需要长期版本保存，应由用户检查工作区后再提交并验证 LFS push/fresh clone。
