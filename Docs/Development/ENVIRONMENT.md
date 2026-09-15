# Environment and Data Policy

本文件是项目唯一的环境、平台职责、复现、外部数据和版本管理说明。

## 支持矩阵

| Profile | macOS | Windows/PC | Linux/CI | 用途 |
| --- | --- | --- | --- | --- |
| `archive` | 支持 | 支持 | 支持 | 文档、manifest、哈希、路径和 LFS 审计 |
| `blender-replay` | Apple Silicon 已验证 | 未验证 | 未验证 | 重放 Mac Blender 实验 |
| `windows-extraction` | 不支持 | 支持 | 不支持 | Model 2 和历史提取工具 |
| `unity-dev` | dormant | dormant | 不支持 | 未来重新批准后启用 |

归档阅读和 CI 不要求 Blender、MPFB、Unity、CUDA、ROM 或模型权重。

## 平台职责

### Mac M4：角色实验和正式美术主环境

- Blender 5.2.1 LTS 建模和实验重放；
- MPFB 2.0.17 人体基础；
- Python、FFmpeg、Git、Git LFS 和文档维护；
- 未来重新批准 Unity 工程后的日常角色导入和视觉验证；
- 当前已验证 Blender 5.2.1 + MPFB 2.0.17 的 Apple Silicon 重放。

### PC/Windows：提取和 Windows 目标验证环境

- PowerShell 7、FFmpeg 和 Model 2 提取流程；
- Noesis、Ninja Ripper、Model 2 Emulator 等按需历史工具；
- 外部视频、截图、ROM、dump 和提取结果保持在本地受限数据根；
- 未来方向 B 的 Windows Player、DirectX、手柄和目标 GPU 性能验证；
- Windows 未验证本次 Blender 样本重放，不能替代 Mac 实验环境结论。

### Linux/CI：审计环境

- 运行 archive doctor、文档链接、manifest、哈希、路径和 LFS 属性检查；
- 不承担 Blender、Unity、CUDA 或 Windows 提取工具；
- 不把 CI 检查结果解释为角色样本重放结果。

## 固定软件配置

| 软件 | 版本/状态 |
| --- | --- |
| Blender | 5.2.1 LTS，Mac Apple Silicon 已验证 |
| MPFB | 2.0.17，官方核心人体 CC0 |
| Unity | 6000.6.0f1 + URP 17.6.0，仅为已删除验证工程的历史记录 |
| Python | 3.11+ 用于仓库工具；实验记录中的 Mac 环境为 3.14.3 |
| Git | 实验记录中的 Mac 环境为 2.48.1 |
| Git LFS | 实验记录中的 Mac 环境为 3.7.1 |
| FFmpeg | 实验记录中的 Mac 环境为 8.1；Windows 提取 profile 需要可用版本 |

MPFB 官方包历史 SHA-256：

`4f0a879d64a39bf646fbf5f53601ac678855da329d650617dca5737548239a87`

Hunyuan/CUDA 不属于 archive 或 Mac 正式基线。历史 Hunyuan 包装器缺少完整 Python、CUDA、PyTorch、vendor commit 和模型 snapshot 锁定，只能部分重放。

## 初始化与检查

```bash
python3 Tools/Environment/bootstrap.py
python3 Tools/Environment/check_environment.py --profile archive
python3 Tools/Environment/check_environment.py --profile archive --json
```

`bootstrap.py` 只复制被忽略的本地 TOML 并创建 LocalData 目录，不下载软件或资产。

本地命令覆盖和外部数据根写入被忽略的：

`Tools/Environment/toolchain.local.toml`

`archive` 检查文档链接、manifest schema、唯一 ID、外键、SHA-256、归档文件、工具清单、LFS 属性和个人绝对路径；默认不联网，也不递归扫描大型 LocalData 或外部数据目录。

## 外部数据恢复

1. 在本地 TOML 设置 `external_source_root`。
2. 保持 `external_source_key = "vf-assets-input"`。
3. 运行 archive doctor。
4. Doctor 根据 intake manifest 的 `relative_path`、文件大小和 SHA-256 校验外部 input。
5. 任务需要时，只复制最小子集到 `LocalData/Incoming/`。

仓库只记录外部文件的逻辑 storage key、原文件名、相对路径、大小和 SHA-256，不记录个人绝对路径。

## 数据与版本边界

- 文档、CSV、TOML、脚本和小型评审图使用普通 Git；
- 原创 `.blend`、`.fbx` 和大型原创纹理使用 Git LFS，必要时 lockable；
- ROM、原作媒体、第三方包、抓取数据、来源不明参考和 AI 批量输出放在 `LocalData/` 或外部数据根，不进 Git/LFS；
- Git LFS 不是备份；正式源资产必须验证 commit/tag、LFS push、fresh clone 和独立备份；
- `LocalData/` 是脚本默认写入根，脚本不得默认覆盖 `Assets/`、`Resources/` 或 `Reference/Captures/`；
- 删除、移动、覆盖和联网操作必须由工具清单声明，并要求显式参数。

当前 v005 的提交、LFS push 和 fresh-clone 恢复状态以资产 manifest 和 Git 实际状态为准。

## 历史实验重放

本次 Mac Blender 实验的完整事实记录位于：

`Reference/ResearchNotes/2026-09-09-mac-blender-honey-automation-test.md`

精确重放要求 Blender 5.2.1、MPFB 2.0.17、Apple Silicon Mac 和可用实验输入。三个 Blender 脚本默认写入 `LocalData/Generated/`，不得覆盖归档 v005。

## Windows 提取边界

- 使用 PowerShell 7 (`pwsh`) 和 FFmpeg；
- 输入、输出和临时文件必须位于 LocalData 或本地配置允许的根目录；
- GUI 自动化必须检查真实文件副作用；
- Model 2、Noesis、Ninja Ripper、DK2/OpenKeeper 是按需历史工具，不属于 archive profile。

## Unity 状态

本次空白 Unity 工程已删除。`unity-dev` 当前 dormant。未来重启必须新增决策，重新固定 Editor、渲染管线、目标平台和 clean-clone 流程。