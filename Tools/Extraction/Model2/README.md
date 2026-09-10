# Model 2 / Honey 历史工具

Profile：`windows-extraction`。这些脚本仅用于按需重放历史采集，不属于 archive profile 或当前生产链。权威状态与副作用见 [`../../tool-manifest.csv`](../../tool-manifest.csv)。

## 环境

- Windows；
- PowerShell 7 (`pwsh`)；
- FFmpeg（视频工具）；
- 本地合法取得的模拟器、游戏数据和可选 Noesis/Ninja Ripper。

相对路径从脚本位置推导仓库根。默认输入、输出和生成数据统一位于 `LocalData/`；会删除、移动或覆盖的操作必须阅读工具清单并显式提供参数。

## 可用/历史入口

- `ExportHoneyVideoFrameSamples.ps1`：视频抽帧；会清理目标中的旧 `frame_*.png`。
- `WatchTexCacheAndDiff.ps1/.cmd`：监听 TEXCACHE；会移动稳定 PNG，并替换旧候选 sheet。
- `SplitHoneyTurnaroundSheet.ps1`：启发式三视图切分，输出必须人工复核。
- `BuildHoneyFalseColorUvDebugSet.ps1/.cmd`：局部材质槽参考，不恢复原始 UV。
- Ninja Ripper 匹配/合并脚本：只作局部参考，不重建完整角色。

## 已拒绝

- `CropHoneyFrameSamples.ps1`：固定裁剪不可靠；仅保留复盘，配置只在显式 `-WriteConfig` 时写回。
- `SendDumpTextureCache.ps1/.cmd`：窗口消息成功不代表生成 PNG；应手工菜单 dump。
- `Experimental/fvipers.lua.disabled`：大范围内存读取可能拖死模拟器。

## 安全原则

1. 先运行 `python Tools/Environment/check_environment.py --profile windows-extraction`。
2. 输入可来自外部本地目录，输出必须位于 `LocalData/`。
3. 不将 ROM、dump、截图、第三方包或抓取数据提交到 Git/LFS。
4. GUI 操作必须验证新增文件、时间戳和数量。
5. 历史路径和结果见 [`../../../Reference/ResearchNotes/`](../../../Reference/ResearchNotes/)。
