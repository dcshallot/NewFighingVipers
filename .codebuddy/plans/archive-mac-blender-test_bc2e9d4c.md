---
name: archive-mac-blender-test
overview: 仅归档本次 Mac M4 上 Blender 5.2.1、MPFB 2.0.17 与自动化服装建模测试；结论不外推到整个项目、所有 AI 3D 技术或方向 C 的永久可行性。
todos:
  - id: audit-mac-test
    content: 使用[subagent:code-explorer]审计本次 Mac 测试文件与历史资料边界
    status: completed
  - id: write-mac-report
    content: 编写限定范围技术报告并更新项目归档状态
    status: completed
    dependencies:
      - audit-mac-test
  - id: archive-test-evidence
    content: 迁移两张评审板并更新模型与 manifest 哈希
    status: completed
    dependencies:
      - write-mac-report
  - id: clean-mac-workspace
    content: 清理本次 Unity、LocalData、中间模型和逐视角渲染
    status: completed
    dependencies:
      - archive-test-evidence
  - id: validate-mac-archive
    content: 验证 Blender、LFS、链接、目录边界和清理后体积
    status: completed
    dependencies:
      - clean-mac-workspace
---

## 用户需求

### Product Overview

仅归档 **2026-09-08 至 2026-09-09 的 Mac M4 新 Blender 自动化测试**，整理技术说明并清理本次测试产生的工程和中间文件。

### Core Features

- 技术报告仅覆盖 Blender 5.2.1、MPFB 2.0.17、程序化 Blockout、MPFB 人体及服装 v005 测试。
- 结论限定为：本次 Mac Blender 自动化方案在低人工介入条件下未达到 Honey 成品门槛。
- 不将结论扩大到整个 Honey 项目、全部 AI 3D 技术、其他平台或未来专用模型。
- 2026 年 4～5 月研究仅作前置背景；保留历史研究笔记与原有提取、Hunyuan、Windows 工具。
- 保留 v005 模型、v003/v005 各一张六视图评审板、关键清单和复盘脚本。
- 删除本次 Mac 测试创建的 Unity 工程、v003 源模型、逐视角渲染、临时素材、缓存与淘汰结果。
- 保留 `.codebuddy/`，不修改 Downloads 中的原始 input。
- 只整理工作区，不提交或推送 Git。

## 实施策略

先迁移并校验关键产物，再编写限定范围的主报告，最后清理本次 Mac 测试目录，避免误删历史研究资料。

## 技术说明

新建 `Docs/MAC_BLENDER_HONEY_AUTOMATION_TEST.md`，记录：

- Mac M4 测试环境、许可与输入边界；
- v002 程序积木路线、v003 MPFB 人体、v005 服装路线；
- 自动化有效部分与仍需大量人工美术的部分；
- 模型规模、版本和 SHA-256；
- 本次测试停止结论及未验证范围；
- 最终保留物、删除物与未来重启条件。

## 归档结构

- `[PRESERVE] ArtSource/Characters/Honey/Blockout/Honey_ClothingBlockout_v005.blend`
- `[NEW] Reference/Archive/MacBlenderHoneyTest/Honey_BaseBody_v003_review_board.jpg`
- `[NEW] Reference/Archive/MacBlenderHoneyTest/Honey_ClothingBlockout_v005_review_board.jpg`
- `[MODIFY] Reference/Manifests/honey-asset-manifest.csv`
- `[MODIFY] README.md`
- `[MODIFY] Docs/PROJECT_STATUS.md`
- `[MODIFY] Docs/DECISIONS.md`
- `[MODIFY] Docs/ROADMAP.md`
- `[PRESERVE] Reference/ResearchNotes/`
- `[PRESERVE] Tools/Extraction/`、`Tools/Generation/`、`Tools/Windows/`
- `[PRESERVE] Tools/Blender/` 三个复盘脚本
- `[REPLACE] Game/README.md`，其余 Unity 工程内容删除
- `[REPLACE] LocalData/README.md`，其余本次测试中间物删除

## 清理边界

删除：

- 本次测试初始化的 `Game/` Unity 工程、缓存和生成文件；
- `Honey_BaseBody_v003.blend`；
- v003/v005 独立视角 PNG；
- `LocalData/Captures/`、`Generated/`、`MPFB/`、`Raw/`、`Reviews/`、`ThirdParty/` 中的测试中间物；
- v002/v004 淘汰结果、自动备份与空目录。

不删除：

- `.codebuddy/`；
- `Reference/ResearchNotes/`；
- 非 Blender 历史研究脚本；
- Downloads 外部原始素材。

## 验证

- 重算 v005 与两张评审板 SHA-256；
- 用 Blender 5.2.1 重新打开 v005；
- 验证 v005 继续应用 Git LFS；
- 确认归档中仅保留两张评审图；
- 确认 `Game/` 不再包含 Unity 工程；
- 检查 Markdown 链接、manifest 路径和 CSV schema；
- 运行脚本语法检查与 `git diff --check`；
- 输出清理前后目录体积，不创建提交。

## Agent Extensions

### SubAgent

- **code-explorer**
- Purpose：在删除前后审计跨目录引用、历史资料边界和残留测试文件。
- Expected outcome：确保只清理本次 Mac Blender 测试内容，不影响早期研究归档。