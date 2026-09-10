# 可复现环境与 Profiles

## 支持矩阵

| Profile | macOS | Windows | Linux/CI | 必需能力 |
| --- | --- | --- | --- | --- |
| `archive` | 支持 | 支持 | 支持 | Python 3.11+、Git；Git LFS 可选 |
| `blender-replay` | **已验证：Apple Silicon** | 未验证 | 未验证 | Blender 5.2.1、MPFB 2.0.17、Git LFS |
| `windows-extraction` | 不支持 | 支持 | 不支持 | PowerShell 7、FFmpeg、本地合法工具/数据 |
| `unity-dev` | dormant | dormant | 不支持 | 未来重新批准的 Unity 工程与版本 |

归档阅读和 CI 不需要 Blender、MPFB、Unity、CUDA、ROM 或模型权重。

## 初始化

```bash
python3 Tools/Environment/bootstrap.py
```

该命令只复制本地 TOML、创建被忽略的 `LocalData` 目录并打印官方安装链接，不下载任何软件或资产。

编辑：

`Tools/Environment/toolchain.local.toml`

本地文件可保存命令覆盖和 `external_source_root`，但被 Git 忽略。

## Doctor

```bash
python3 Tools/Environment/check_environment.py --profile archive
python3 Tools/Environment/check_environment.py --profile archive --json
python3 Tools/Environment/check_environment.py --profile blender-replay
python3 Tools/Environment/check_environment.py --profile windows-extraction
```

`archive` 检查文档链接、manifest schema、唯一 ID、外键、SHA-256、归档文件、工具 inventory、LFS 属性和个人绝对路径。它不会联网，也不会递归扫描 `LocalData/`。

## 外部 input 恢复

1. 在本地 TOML 将 `external_source_root` 指向外部 `vf-assets/input`。
2. 保持 `external_source_key = "vf-assets-input"`。
3. 运行 archive doctor。
4. Doctor 根据 `honey-intake-2026-09-09.csv` 的 `relative_path`、`size_bytes` 和 `sha256` 校验文件。
5. 只有当前任务需要时，才将最小子集复制到 `LocalData/Incoming/`。

## Blender 精确重放

本次实验只验证：

- Blender `5.2.1 LTS`
- MPFB `2.0.17`
- macOS Apple Silicon

MPFB 官方安装包历史 SHA-256：

`4f0a879d64a39bf646fbf5f53601ac678855da329d650617dca5737548239a87`

三个 Blender 脚本是历史重放入口，默认只能写入 `LocalData/Generated/`。若要保存新的正式资产，必须显式指定新路径，不能覆盖归档 v005。

## Windows 提取

- 使用 PowerShell 7 (`pwsh`) 和 FFmpeg；
- 所有输入/输出必须位于 `LocalData/` 或本地配置允许的根目录；
- GUI 自动化必须检查实际文件副作用；
- Model 2、Noesis、Ninja Ripper、DK2/OpenKeeper 都是按需历史工具，不属于 archive profile。

## Unity

本次空白 Unity 工程已删除。`unity-dev` 当前 dormant；未来重启时必须新增决策，重新固定 Editor、render pipeline、目标平台与 clean-clone 流程。

## Hunyuan 历史路线

历史 Hunyuan 包装器缺少完整 Python/CUDA/PyTorch/vendor commit/模型 snapshot 锁定，当前标记为 partial historical replay。repo tooling 的 Python 3.11+ 不能被解释为 Hunyuan 环境兼容声明。
