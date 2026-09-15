# New Fighting Vipers Research Archive

Fighting Vipers / Honey 的研究、工具与技术验证归档。当前没有活跃制作工程；2026-09 Mac M4 Blender 自动化测试已结束。

## 当前事实

- 当前状态：归档；唯一事实页为 [`Docs/PROJECT_STATUS.md`](Docs/PROJECT_STATUS.md)。
- Mac 实验记录：[`Reference/ResearchNotes/2026-09-09-mac-blender-honey-automation-test.md`](Reference/ResearchNotes/2026-09-09-mac-blender-honey-automation-test.md)。
- 保留模型：`ArtSource/Characters/Honey/Blockout/Honey_ClothingBlockout_v005.blend`，不是 game-ready 成品。
- 历史 ResearchNotes 和 Model 2/Hunyuan/Windows 工具保留。
- Unity 测试工程、受限原始素材和中间物不在仓库中。

想了解项目过去折腾过哪些路线和实验，请直接查看 `Reference/ResearchNotes/` 下的日期化研究记录。

本次 No-Go 只针对 Mac M4 + Blender 5.2.1 + MPFB 2.0.17 + 通用 LLM/脚本的低人工介入测试，不否定其他 AI 3D、平台或未来重启。

## 环境审计

```bash
python3 Tools/Environment/bootstrap.py
python3 Tools/Environment/check_environment.py --profile archive
python3 Tools/Environment/check_environment.py --profile archive --json
```

`archive` 支持 macOS、Windows、Linux/CI，不要求 Blender、MPFB、Unity、CUDA 或游戏数据。Mac、PC/Windows 和 Linux/CI 的职责见 [`Docs/Development/ENVIRONMENT.md`](Docs/Development/ENVIRONMENT.md)。

## 外部数据

原始视频、截图、ROM、dump 和第三方包不进入 Git。通过 `storage_key + relative_path + size + SHA-256` 记录；在本机 `toolchain.local.toml` 配置 `external_source_root` 后由 archive doctor 校验。

## 版本状态

当前工作区的 commit、push 和 v005 LFS 恢复状态以 Git 与资产 manifest 为准。未经用户明确授权，本仓库不会自动提交或操作远端。
