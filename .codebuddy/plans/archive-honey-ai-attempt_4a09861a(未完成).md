---
name: archive-honey-ai-attempt
overview: 将本次 Honey AI/自动化高清重建尝试整理为一份最终技术说明，并按归档模式只保留文档、清单、关键脚本、v005 服装模型及 v003/v005 压缩评审图，清理 Unity 工程和所有非关键中间产物。
todos:
  - id: audit-archive-inputs
    content: 使用[subagent:code-explorer]审计保留物、引用路径与待删除目录
    status: pending
  - id: write-technical-report
    content: 编写最终技术说明并更新归档状态、决策与路线图
    status: pending
    dependencies:
      - audit-archive-inputs
  - id: archive-key-artifacts
    content: 迁移两张评审板并更新模型、参考与工具清单
    status: pending
    dependencies:
      - write-technical-report
  - id: clean-project-directories
    content: 删除 Unity 工程、v003 源模型、LocalData 中间物与重复文档
    status: pending
    dependencies:
      - archive-key-artifacts
  - id: validate-final-archive
    content: 复核哈希、Blender、链接、LFS、目录体积与 Git 工作区
    status: pending
    dependencies:
      - clean-project-directories
---

## 用户需求

### Product Overview

将本次 Honey 高清重建与 AI 自动化实验整理为只读技术归档，结束当前制作尝试，不再保留可继续开发的完整工程。

### Core Features

- 编写一份可独立阅读的技术说明，记录实验路线、版本环境、关键产物、质量结论、失败原因与重启条件。
- 保留 Honey 服装 Blockout v005，作为当前 AI 与自动化建模上限的实物证据。
- 保留 v003 基础人体和 v005 服装模型各一张压缩六视图评审板。
- 保留关键决策、研究笔记、环境版本、来源与资产清单，以及具有复盘价值的脚本。
- 删除 Unity 工程、基础人体 v003 源模型、逐视角渲染、原始素材副本、临时生成物和被淘汰结果。
- 保留 `.codebuddy/`，不删除用户在 Downloads 中保存的原始 input。
- 最终将项目标记为归档状态，不提交或推送 Git 变更。

## 技术方案

### 技术栈与归档格式

- 主技术说明：Markdown。
- 资产索引：现有 CSV manifest。
- 唯一保留模型：Blender `5.2.1` 的 `Honey_ClothingBlockout_v005.blend`。
- 关键视觉证据：两张压缩 JPG 六视图评审板。
- 环境记录：Blender `5.2.1`、MPFB `2.0.17`、Unity `6000.6.0f1`、URP `17.6.0` 及现有工具版本。
- 校验：SHA-256、Markdown 链接检查、CSV schema、Python 语法、Git LFS 属性及 `git diff --check`。

## 实施策略

先将技术结论和两个评审板迁入稳定归档位置，再更新所有文档与清单路径，最后删除大型工程和中间文件。采用“先验证保留物、后删除源目录、再执行全局复核”的顺序，避免因清理造成关键证据丢失。

### 最终技术报告

新建 `Docs/HONEY_AI_RECONSTRUCTION_TECHNICAL_REPORT.md`，覆盖：

1. Honey P1 正常状态的目标与范围；
2. Model 2 自录素材、来源登记和 SHA-256 策略；
3. 2026 年 5 月至 9 月自动化能力变化；
4. Model 2 dump、抽帧、Ninja Ripper、Hunyuan3D、Meshy、Mixamo、Unity、程序积木、MPFB 和贴体服装路线；
5. MPFB v003 与服装 v005 的定量结果；
6. 自动化显著改善的部分；
7. 仍需大量角色美术介入的部分；
8. 通用大模型与专用图生 3D 模型的能力边界；
9. 当前约束下方向 C 的 No-Go 结论；
10. 可重新启动项目的前置条件；
11. 最终保留物、删除范围和可验证哈希。

## 归档架构

```text
研究证据与决策
        ↓
独立技术说明
        ↓
关键模型与两张评审图
        ↓
manifest 和 SHA-256
        ↓
删除 Unity、LocalData 和淘汰产物
        ↓
归档模式验证
```

## 目录结构

```text
NewFighingVipers/
├── README.md
│   # [MODIFY] 改为归档入口，声明技术验证结束、方向 C No-Go、保留物和重启条件。
├── .gitattributes
│   # [MODIFY] 保证保留的 v005 .blend 继续使用 Git LFS；移除无效规则仅在必要时进行。
├── .codebuddy/
│   # [PRESERVE] 项目数据，禁止删除。
├── ArtSource/
│   └── Characters/Honey/Blockout/
│       └── Honey_ClothingBlockout_v005.blend
│           # [PRESERVE] 唯一保留模型；重算 SHA-256并验证 Blender 可打开。
├── Docs/
│   ├── HONEY_AI_RECONSTRUCTION_TECHNICAL_REPORT.md
│   │   # [NEW] 唯一主技术说明，完整记录实验、结论、产物和重启条件。
│   ├── PROJECT_STATUS.md
│   │   # [MODIFY] 状态改为 archived/finished，移除仍处于 C2 的过时描述。
│   ├── DECISIONS.md
│   │   # [MODIFY] 新增 AI-first 自动化方案 No-Go 与归档决策。
│   ├── ROADMAP.md
│   │   # [MODIFY] 标记方向 C 停止，方向 B 未启动。
│   ├── Development/
│   │   ├── SETUP.md
│   │   ├── ART_ASSET_MANAGEMENT.md
│   │   └── 其他现有关键规则
│   │       # [MODIFY/PRESERVE] 改为历史环境与归档规则，删除不再适用的生产指令。
│   └── Production/Honey/
│       ├── CHARACTER_BIBLE.md
│       ├── MPFB_BASELINE.md
│       └── 过程文档
│           # [CONSOLIDATE] 把关键结论并入主报告；删除不再需要的重复计划和阶段文档。
├── Reference/
│   ├── Archive/HoneyAIValidation/
│   │   ├── Honey_BaseBody_v003_review_board.jpg
│   │   └── Honey_ClothingBlockout_v005_review_board.jpg
│   │       # [NEW/MOVE] 两张唯一保留的关键视觉证据。
│   ├── Manifests/
│   │   ├── honey-asset-manifest.csv
│   │   ├── honey-reference-manifest.csv
│   │   ├── honey-intake-2026-09-09.csv
│   │   └── honey-p1-selected-views.csv
│   │       # [MODIFY/PRESERVE] 更新归档路径、删除状态、哈希和最终结论。
│   └── ResearchNotes/
│       # [PRESERVE] 保留全部历史研究笔记。
├── Tools/
│   ├── Blender/
│   │   # [PRESERVE] 保留 MPFB、服装和失败路线脚本作为可复盘证据。
│   ├── Environment/
│   │   # [MODIFY] 支持 archive 模式，不因 Unity 工程被主动删除而失败。
│   ├── Extraction/
│   ├── Generation/
│   ├── Windows/
│   └── tool-manifest.csv
│       # [MODIFY/PRESERVE] 区分 stable、historical、rejected 和 archived 工具。
├── Game/
│   └── README.md
│       # [REPLACE] 仅保留归档墓碑说明；删除 Assets、Packages、ProjectSettings、Library 和 IDE 文件。
└── LocalData/
    └── README.md
        # [REPLACE] 仅保留本地数据策略说明；其他内容全部删除。
```

## 删除范围

- `Game/Assets/`
- `Game/Packages/`
- `Game/ProjectSettings/`
- `Game/Library/`
- `Game/Logs/`
- `Game/Temp/`
- `Game/UserSettings/`
- `Game/*.csproj`
- `Game/*.slnx`
- `ArtSource/Characters/Honey/Blockout/Honey_BaseBody_v003.blend`
- v003、v005 全部独立视角 PNG
- `LocalData/Captures/`
- `LocalData/Generated/`
- `LocalData/MPFB/`
- `LocalData/Raw/`
- `LocalData/Reviews/` 中迁移评审板后的其余内容
- `LocalData/ThirdParty/`
- 自动备份、缓存、被拒绝模型和空目录

不会触碰 `/Users/chaoyang/Downloads/vf-assets/input` 或 `.codebuddy/`。

## 执行与回归说明

- 删除前重新计算 v005 和两张评审板哈希，并将评审板复制到归档目录后再次核对。
- 使用 Blender `5.2.1` 后台重新打开 v005，确认 MPFB `2.0.17` 环境仍可识别。
- 环境检查新增 archive 模式：Unity Editor 版本可保留为历史信息，但缺少 `Game/ProjectSettings` 不再视为失败。
- 清理后应仅剩两张 Honey 评审图，避免保留可再生逐视角 PNG。
- 预计工作区从约 `1.1 GB` 降至几十 MB；实际结果写入技术报告。
- 不创建 Git commit，不推送远端。

## Agent Extensions

### SubAgent

- **code-explorer**
- Purpose：在删除前后审计跨目录引用、关键文件、manifest 路径和残留大型工程内容。
- Expected outcome：确认保留物完整、待删除内容无误，并找出所有需要同步更新的文档链接。