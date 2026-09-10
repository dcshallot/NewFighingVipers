---
name: unify-cross-platform-project-governance
overview: 收敛归档后的文档职责、manifest 语义、环境 profiles 和工具路径规范，使仓库能在 macOS、Windows 与 Linux/CI 上被一致理解、审计和按需重放。
todos:
  - id: audit-impact
    content: 使用[subagent:code-explorer]复核跨平台影响范围
    status: completed
  - id: profiles-doctor
    content: 建立环境 profiles、bootstrap 与 archive doctor
    status: completed
    dependencies:
      - audit-impact
  - id: manifest-schema
    content: 升级 manifests 和外部数据恢复协议
    status: completed
    dependencies:
      - profiles-doctor
  - id: unify-tool-paths
    content: 统一 Blender、Hunyuan、提取脚本路径与保护
    status: completed
    dependencies:
      - profiles-doctor
  - id: consolidate-docs
    content: 收敛文档职责并补齐许可和导航
    status: completed
    dependencies:
      - manifest-schema
      - unify-tool-paths
  - id: ci-validation
    content: 增加双平台 CI 并完成归档回归验证
    status: completed
    dependencies:
      - consolidate-docs
---

## User Requirements

### Product Overview

将当前研究归档收敛为可长期维护、可跨 macOS、Windows、Linux 审计和恢复的统一项目结构，同时保持历史实验、关键证据和工具的可追溯性。

### Core Features

- 明确入口、当前状态、决策、实验报告、研究证据、工具和资产清单各自的唯一职责，消除重复及过时描述。
- 建立归档审计、Blender 实验重放、Windows 提取和未来 Unity 开发四种独立环境配置，避免归档阅读依赖完整制作软件。
- 统一本地数据、外部原始素材和工具输出路径，使换机器后可通过逻辑存储标识重新映射和校验。
- 强化清单规则，校验唯一编号、状态、文件可用性、来源关联、哈希和跨清单引用。
- 统一各平台脚本的仓库定位、输出边界和覆盖保护，禁止个人绝对路径或默认覆盖归档证据。
- 提供轻量初始化、健康检查和双平台自动审计，不自动下载大型软件、游戏数据、模型或权重。
- 保留历史研究笔记、`.codebuddy/`、v005 模型和归档评审图；不修改外部 Downloads 素材。
- 本轮只整理和验证工作区，不自动提交、推送或操作远端 Git LFS。

## Tech Stack Selection

- **文档与治理**：Markdown、CSV manifest、TOML 配置。
- **跨平台审计**：Python 3.11+ 标准库，避免增加运行时依赖。
- **Windows 工具**：PowerShell 7，`.cmd` 仅作为兼容入口。
- **资产工具**：Blender 5.2.1、MPFB 2.0.17，仅用于 `blender-replay` profile。
- **版本管理**：Git、Git LFS；本轮只验证规则和状态，不执行提交或推送。
- **持续检查**：Ubuntu 与 Windows 轻量 CI，不安装 Blender、Unity、CUDA 或模型权重。

## Implementation Approach

采用“文档单一事实源 + profile 驱动环境 + 逻辑数据根 + 强类型 manifest + 轻量 CI”的方式收敛仓库：

1. `PROJECT_STATUS.md` 成为唯一当前事实页；实验报告保持不可变，决策页只记录生命周期和证据。
2. 将环境拆分为 `archive`、`blender-replay`、`windows-extraction`、`unity-dev`，每个 profile 只检查自身必需能力。
3. 外部素材通过 `external_data_root` 和逻辑 storage key 映射，仓库不保存个人绝对路径。
4. Doctor 同时验证文档链接、manifest、哈希、LFS 属性和路径策略；默认不递归扫描大型 `LocalData/`。
5. 历史脚本保留，但统一仓库根解析、LocalData 边界和显式覆盖参数。

关键权衡：

- 不使用 Docker、Nix、Conda，也不自动安装 DCC，避免为归档仓库引入重型基础设施。
- Blender 5.2.1 是本次实验精确重放版本；未来制作兼容范围必须通过新决策另行批准。
- Linux 作为文档、清单和 Python 审计平台；Windows 负责历史提取；Mac 是已验证的 Blender 重放平台。
- 不创建 `LICENSE`，因为项目自有代码和文档许可尚未由用户选择；只增加第三方许可说明。

### Performance and Reliability

- 常规 archive 检查复杂度为 `O(文档文件数 + manifest 行数)`。
- SHA-256 仅处理 manifest 声明且当前存在的关键产物，复杂度为 `O(关键产物字节数)`。
- 默认跳过 `LocalData/`、DCC cache 和外部数据根的递归遍历，避免大型目录拖慢 CI。
- JSON 输出保持稳定字段，供 CI 判断；控制台输出不打印个人路径、凭据或素材内容。
- 所有会覆盖、移动或删除内容的脚本必须要求显式参数，并验证目标位于允许的数据根下。

## Architecture Design

### Document Responsibility

- `README.md`：最短入口、当前状态、核心导航和 archive doctor 命令。
- `Docs/PROJECT_STATUS.md`：唯一当前事实、支持矩阵、风险和重启条件。
- `Docs/DECISIONS.md`：决策生命周期、证据、影响文件和替代关系。
- `Docs/MAC_BLENDER_HONEY_AUTOMATION_TEST.md`：不可变实验报告。
- `Docs/Development/REPRODUCIBILITY.md`：profiles、版本策略、安装来源和恢复步骤。
- `Docs/Development/REPOSITORY_AND_DATA_POLICY.md`：Git、LFS、LocalData、外部数据与备份规则。
- `Reference/README.md`：Archive、Manifests、ResearchNotes 总入口。
- `Reference/Manifests/README.md`：schema、枚举、外键、路径和 availability 规则。

### Environment Profiles

- `archive`：Python、Git、文档、manifest、哈希和路径审计；三平台正式支持。
- `blender-replay`：固定 Blender 5.2.1 与 MPFB 2.0.17；macOS 已验证。
- `windows-extraction`：PowerShell 7、FFmpeg 和本地 Model 2 能力；Windows-only。
- `unity-dev`：当前 dormant，只有未来重启 Unity 工程时启用。

### Configuration Flow

`toolchain.example.toml` → 被忽略的 `toolchain.local.toml` → CLI profile/override → doctor 报告。

外部文件恢复流程：

逻辑 storage key → 本机 `external_data_root` → manifest 文件名/大小/SHA-256 校验 → 按需复制到 `LocalData/Incoming`。

## Implementation Notes

- 保持 `Reference/ResearchNotes/` 正文不变，由 `Reference/README.md` 统一声明历史路径可能不存在。
- `.codebuddy/` 只作为内部计划历史，不纳入正式事实链，也不删除。
- Blender/Hunyuan 复盘脚本的默认输出迁至 `LocalData/Generated/`，不得覆盖归档 v005。
- 对历史不可完整复现的 CUDA/Hunyuan 路线明确标记，不伪造依赖锁定状态。
- CI 只运行无资产、无网络、无 DCC 的审计；Windows 仅做 PowerShell 解析和临时目录 smoke test。
- 保持向后兼容：旧 manifest 内容迁移到新版字段，原始哈希和历史状态不得丢失。
- 不输出凭据、个人路径、ROM、外部素材内容或大型 payload。

## Directory Structure Summary

本轮会收敛文档职责、升级环境审计和 manifest，并统一历史工具路径。不会恢复 Unity 工程或重新生成模型。

```text
NewFighingVipers/
├── README.md                                      # [MODIFY] 精简为统一入口，增加 profiles、doctor、manifest 和恢复导航。
├── .editorconfig                                  # [NEW] 统一 Markdown、Python、PowerShell、CSV/TOML 的编码、换行和缩进。
├── .github/workflows/repo-audit.yml               # [NEW] Ubuntu archive 审计与 Windows PowerShell 解析检查。
├── THIRD_PARTY_NOTICES.md                         # [NEW] 记录 Blender、MPFB/MakeHuman、Unity、Hunyuan、Meshy 等许可边界。
├── Docs/
│   ├── PROJECT_STATUS.md                          # [MODIFY] 唯一当前事实页；吸收归档路线图和支持矩阵。
│   ├── DECISIONS.md                               # [MODIFY] 增加 Dormant/Superseded/Archived、证据和影响文件。
│   ├── ROADMAP.md                                 # [MODIFY] 收敛为历史墓碑并指向 PROJECT_STATUS。
│   └── Development/
│       ├── SETUP.md                               # [MODIFY] 修复 Unity 状态冲突，改为 profile 入口。
│       ├── REPRODUCIBILITY.md                     # [NEW] 环境矩阵、精确重放、恢复和验证流程。
│       ├── REPOSITORY_AND_DATA_POLICY.md          # [NEW] 合并仓库、LFS、本地数据、外部存储和备份规则。
│       ├── VERSION_CONTROL.md                     # [DELETE] 内容迁入统一数据策略并更新全部引用。
│       ├── ART_ASSET_MANAGEMENT.md                # [DELETE] 内容迁入统一数据策略并更新全部引用。
│       └── ASSET_PIPELINE.md                      # [MODIFY] 仅保留资产阶段、晋级和质量门槛。
├── Reference/
│   ├── README.md                                  # [NEW] Archive、Manifests、ResearchNotes 的统一导航与历史声明。
│   └── Manifests/
│       ├── README.md                              # [NEW] 定义 schema v2、枚举、外键、availability 和路径语义。
│       ├── honey-asset-manifest.csv               # [MODIFY] 拆分 source、review、export、availability 字段。
│       ├── honey-reference-manifest.csv           # [MODIFY] 使用 storage key 和稳定 evidence 关联。
│       ├── honey-p1-selected-views.csv             # [MODIFY] 增加 parent source、selection 与 availability。
│       └── honey-intake-2026-09-09.csv            # [MODIFY] 增加外部存储标识和跨机器恢复信息。
├── Tools/
│   ├── README.md                                  # [MODIFY] 按 profile 导航，区分 active、reference、rejected。
│   ├── tool-manifest.csv                          # [MODIFY] 增加 profile、破坏性、网络和可复现性字段。
│   ├── Environment/
│   │   ├── toolchain.example.toml                 # [MODIFY] 增加 profiles、逻辑数据根和版本策略。
│   │   ├── check_environment.py                   # [MODIFY] profile、JSON、schema、哈希、链接、LFS 和路径审计。
│   │   └── bootstrap.py                           # [NEW] 创建本地配置和 LocalData 目录，仅打印安装指引。
│   ├── Blender/
│   │   ├── create_honey_blockout.py               # [MODIFY] rejected 复盘脚本只输出 LocalData，不覆盖正式资产。
│   │   ├── create_honey_mpfb_base.py              # [MODIFY] MPFB module 可配置并验证版本。
│   │   └── create_honey_clothing_blockout.py      # [MODIFY] 显式输入输出，禁止覆盖归档 v005。
│   ├── Generation/Hunyuan3D/
│   │   ├── GenerateHoneyMvGlb.py                  # [MODIFY] 消除 import 副作用，默认 LocalData，声明历史依赖。
│   │   ├── GenerateHoneyMvGlb.ps1                 # [MODIFY] 统一 repo root、LocalData 和输出边界。
│   │   └── README.md                              # [MODIFY] 标记历史重放限制与 profile。
│   ├── Extraction/Model2/
│   │   ├── README.md                              # [MODIFY] 统一 Windows profile、路径和副作用说明。
│   │   ├── CropHoneyFrameSamples.ps1              # [MODIFY] 使用脚本根和 LocalData，禁止默认重写配置。
│   │   ├── SplitHoneyTurnaroundSheet.ps1          # [MODIFY] 使用脚本根和受控输出。
│   │   ├── MatchNinjaRipperFrameToHoneyTextureSet.ps1 # [MODIFY] 移除当前目录和旧 Reference 默认值。
│   │   ├── MergeNinjaRipperMeshesByTexture.ps1    # [MODIFY] 统一路径和覆盖保护。
│   │   ├── BuildHoneyFalseColorUvDebugSet.ps1     # [MODIFY] 输入输出迁入 LocalData。
│   │   ├── BuildHoneyFalseColorUvDebugSet.cmd     # [MODIFY] 使用 pwsh 或明确回退策略。
│   │   ├── SendDumpTextureCache.cmd               # [MODIFY] 使用 pwsh 或明确回退策略。
│   │   └── WatchTexCacheAndDiff.cmd               # [MODIFY] 使用 pwsh 或明确回退策略。
│   └── Windows/
│       ├── Run-OpenKeeper-DK2.ps1                 # [MODIFY] 删除硬编码路径，使用 local 配置与 LocalData。
│       └── PowerShell-Runbook.md                  # [MODIFY] 统一 PowerShell 7 和路径边界范式。
```

## Key Verification

- `archive` profile 在 macOS、Windows、Linux 上不要求 Blender、MPFB 或 Unity。
- `blender-replay` 精确验证 Blender 5.2.1 与 MPFB 2.0.17。
- 清单 ID、枚举、外键、SHA-256 和 availability 与真实文件一致。
- Markdown 链接、逻辑数据根、LFS 属性和非历史绝对路径检查通过。
- 所有主动脚本默认只写 `LocalData/`，归档证据必须显式指定并禁止覆盖。
- 不执行 Git commit、push、LFS 上传，不修改 `.codebuddy/` 和 Downloads input。

## Agent Extensions

### SubAgent

- **code-explorer**
- Purpose：复核跨文档引用、脚本默认路径、manifest 外键和最终删除/合并影响。
- Expected outcome：输出实施前后可验证的影响清单，确保历史研究和关键归档证据不被误改。