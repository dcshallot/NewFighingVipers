> **Archived research record.** This note records the Mac Blender automation experiment as it happened. Paths and statuses are historical evidence and do not replace current project status or production specifications.

# Mac M4 Honey Blender 自动化实验归档

日期：2026-09-08 至 2026-09-09  
状态：`historical`  
实验类型：技术验证与样本资产归档  
实验范围：Mac M4 + Blender 5.2.1 + MPFB 2.0.17 + 通用 LLM / Blender Python 自动化

## 实验目标

验证在已有 Fighting Vipers / Honey 研究资料基础上，使用 Mac M4、Blender、MPFB 和通用大模型生成的 Blender Python 自动化，能否在几乎没有角色美术人工介入的情况下，形成 Honey P1 红色正常状态角色的可用三维样本。

本次只测试 P1 正常状态，不制作 P2 独立资产，不测试正式战斗原型，也不把本次结果扩展为对所有 AI 3D 工具、Windows/Linux 管线或人工角色制作的结论。

## 输入资料

- 5 段用户自行录制的 Model 2 Honey P1 1080p 视频，约 116 秒；
- 33 张用户自行录制或裁剪的截图；
- 12 张固定视角和结构参考；
- 原始视频和截图保存在仓库外；仓库只保留 manifest、文件大小和 SHA-256 索引；
- AI 生成图和来源未确认的社区 render 不作为原作事实依据。

## 部署环境

| 项目 | 实验配置 |
| --- | --- |
| 主机 | Apple Silicon Mac M4 Pro |
| 建模工具 | Blender 5.2.1 LTS |
| 人体基础 | MPFB 2.0.17 |
| 自动化 | Blender 内置 Python 脚本 |
| 游戏导入验证 | Unity 6000.6.0f1，Apple Silicon |
| 渲染管线 | URP 17.6.0 |
| Python | 3.14.3 |
| Git | 2.48.1 |
| Git LFS | 3.7.1 |
| 媒体处理 | FFmpeg 8.1 |

MPFB 官方包 SHA-256：

`4f0a879d64a39bf646fbf5f53601ac678855da329d650617dca5737548239a87`

人物基线只使用 MPFB/MakeHuman 官方 CC0 1.0 核心人体，没有采用许可未核验的社区服装、头发或皮肤。

## 技术方案

实验采用分阶段自动化方案：

1. 使用 Blender Python 生成程序积木 Blockout，验证脚本、几何生成和重复打开；
2. 使用固定版本 MPFB 生成基础人体，验证人体连续性和尺寸；
3. 从 MPFB 人体表面提取贴体壳，使用参数化几何和曲线生成服装、头发及背饰；
4. 以固定六视图输出评审板，结合对象数量、材质数量、顶点数量和 SHA-256 记录样本；
5. 使用 Unity 空白验证工程检查导入路径；
6. 清理临时模型、缓存和中间渲染，只保留可追溯的最终样本与评审证据。

## 执行记录

### 1. 程序积木 Blockout v002

输入为 Honey 的角色部件和轮廓观察，使用球体、锥体、方块和简单曲线生成身体、服装、头发、靴子和背饰。

技术产出：

- 64 meshes；
- 8 materials；
- 固定六视图可自动输出；
- 生成文件可以重新打开，脚本流程可重复。

样本观察：人体像低质量玩具，肩甲、裙摆、靴子、发束和背翼缺少角色造型质量。该阶段保留为失败路线证据，模型和渲染在清理阶段删除。

### 2. MPFB 基础人体 v003

固定 MPFB 2.0.17，使用官方 CC0 核心人体生成修长、适度运动感的女性基础体型。

技术产出：

- 19,158 vertices；
- 尺寸约 `1.021 × 0.405 × 1.678 m`；
- 胸廓、腰、骨盆和关节连续性优于程序积木；
- 固定六视图通过基础人体检查。

v003 源 `.blend` 在清理阶段删除，仅保留人体评审板作为视觉基线证据。

### 3. MPFB 贴体服装 Blockout v005

从 MPFB 人体表面提取贴体壳，再使用参数化裙摆、肩部壳、前臂护甲、长靴壳、曲线后发束和背饰形成服装 Blockout。

技术产出：

- 42 objects；
- 24 meshes；
- 14 curves；
- 8 materials；
- Blender 5.2.1 可重新打开；
- 固定六视图可重新生成。

样本观察：人体、衣身、下装、护手和靴子的贴合关系明显优于 v002。该样本作为本次自动化分支的最高保留样本，但仍属于 Blockout。

## 实验产出与资产状态

### 保留资产

| 产出 | 路径 | 用途 | SHA-256 |
| --- | --- | --- | --- |
| Honey Clothing Blockout v005 | `ArtSource/Characters/Honey/Blockout/Honey_ClothingBlockout_v005.blend` | 自动化分支最高样本 | `7a04eab30ad5e9811b457027dbde19afb0d378a0023648b93ca6511af9d49b5c` |
| Honey Base Body v003 review board | `Reference/Archive/MacBlenderHoneyTest/Honey_BaseBody_v003_review_board.jpg` | 基础人体视觉证据 | `ca737f33880e281db9d78dd250af6c4c0fd3eb724bfae7ec23c309c539bb094d` |
| Honey Clothing Blockout v005 review board | `Reference/Archive/MacBlenderHoneyTest/Honey_ClothingBlockout_v005_review_board.jpg` | 服装样本视觉证据 | `40d9727989e5efc11c8a661f67c05cd3298f7f15a8a7996d9fb5d6c58f96ddbb` |

同时保留：

- `Tools/Blender/create_honey_blockout.py`；
- `Tools/Blender/create_honey_mpfb_base.py`；
- `Tools/Blender/create_honey_clothing_blockout.py`；
- `Tools/Environment/check_environment.py`；
- 本目录中已有的 Honey 历史研究笔记；
- 资产、参考和工具 manifest。

### 清理资产

实验结束时清理了：

- v002 程序积木模型和渲染；
- v003 基础人体源模型；
- 逐视角 PNG 和工作截图副本；
- AI 概念图、社区 render 和来源不明确的参考图；
- Unity 空白测试工程及缓存；
- 临时测试文件、缓存和自动生成中间物。

外部 Downloads input 与 `.codebuddy/` 不在清理范围内。

清理前后工作区体积：

| 范围 | 清理前 | 清理后 |
| --- | ---: | ---: |
| 工作区 | 1,135,964 KiB | 6,884 KiB |
| `Game/` | 1,101,624 KiB | 16 KiB，仅墓碑 README |
| `ArtSource/` | 5,284 KiB | 2,904 KiB，保留 v005 |

## 复现入口

历史重放脚本：

- `Tools/Blender/create_honey_blockout.py`；
- `Tools/Blender/create_honey_mpfb_base.py`；
- `Tools/Blender/create_honey_clothing_blockout.py`。

精确重放条件：

- Blender 5.2.1；
- MPFB 2.0.17；
- Apple Silicon Mac；
- 实验输入资料可用。

Windows/Linux 未验证 Blender 样本重放。仓库级归档审计可独立运行：

```bash
python Tools/Environment/check_environment.py --profile archive
```

该命令检查文档链接、manifest、哈希、归档文件、工具清单、LFS 属性和个人路径，不等于在当前平台重新生成 Blender 样本。

## 技术结论

### 已验证

- 通用 LLM / Blender Python 可以完成环境搭建、脚本执行和重复生成；
- MPFB 可以提供连续、可用的基础人体；
- 参数化 mesh shell、裙摆和曲线部件可以快速生成服装 Blockout；
- 固定视图、评审板、哈希和 manifest 可以形成可审计的实验记录；
- 自动化可以减少技术美术和工程重复劳动。

### 本次实验的限制

- Honey 脸型、发型和服装的可信还原未解决；
- 专业级服装结构、材质和部件组织未解决；
- 最终拓扑、UV、骨骼、权重和格斗动作变形未验证；
- 结果不能直接作为 Unity 生产角色或战斗原型角色。

### 结论

**No-Go：仅针对本次 Mac M4 + Blender 5.2.1 + MPFB 2.0.17 + 通用 LLM / Blender Python、且几乎没有角色美术人工介入的自动化分支。**

本次实验确认了自动化流程、样本生成方式和能力边界，并形成了 v005 及两张评审板等可核验产出。该结论不延伸到人工角色制作、专用多视图角色到 3D 工具、其他平台或未来不同实验路线。

## 相关记录

- 当前项目状态：`Docs/PROJECT_STATUS.md`；
- 环境与复现说明：`Docs/Development/ENVIRONMENT.md`；
- 决策记录：`Docs/DECISIONS.md`；
- 资产清单：`Reference/Manifests/honey-asset-manifest.csv`；
- 当前状态：`Docs/PROJECT_STATUS.md`。

本笔记记录本次实验的历史事实。若未来测试不同软件、输入或人工介入程度，应新建日期化研究笔记，不在本文追加新的实验结果。
