# 环境入口

当前仓库是研究归档，不存在可打开的 Unity 工程。环境按 profile 管理，完整说明见 [`REPRODUCIBILITY.md`](REPRODUCIBILITY.md)。

## 最短开始方式

```bash
python3 Tools/Environment/bootstrap.py
python3 Tools/Environment/check_environment.py --profile archive
```

`archive` 在 macOS、Windows、Linux/CI 上支持，只要求 Python 3.11+ 和 Git；不要求 Blender、MPFB、Unity、CUDA 或游戏数据。

## Profiles

- `archive`：文档、manifest、哈希、路径和 LFS 规则审计；
- `blender-replay`：精确重放 Mac Blender 测试，要求 Blender 5.2.1 + MPFB 2.0.17；
- `windows-extraction`：Windows-only 历史提取，要求 PowerShell 7 + FFmpeg；
- `unity-dev`：当前 dormant；未来批准重启后再初始化 Unity。

## 平台职责

- macOS Apple Silicon：已验证 Blender 重放；
- Windows：Model 2/Noesis/Ninja Ripper/OpenKeeper 等按需历史工具；
- Linux：archive doctor 与 CI 的正式平台，可选 Blender 重放未验证；
- Unity：本次空白工程已清理，不属于当前归档必需环境。

## 固定历史版本

- Blender 5.2.1 LTS；
- MPFB 2.0.17，官方核心人体 CC0；
- Unity 6000.6.0f1 + URP 17.6.0 仅为本次已删除验证工程的历史记录；
- Hunyuan 环境未形成完整依赖锁，不能由 repo Python 版本推断可复现。

本机命令与外部数据根只写入被忽略的 `Tools/Environment/toolchain.local.toml`。
