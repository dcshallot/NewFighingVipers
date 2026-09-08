# Model 2 / Honey 工具

本目录是 Windows-only 的历史采集和分析工具。方向 C 只有在 C1 出现明确参考缺口时才使用它们；所有 ROM、模拟器、dump、截图和输出应放在 `LocalData/`。

工具权威状态见 [`../../tool-manifest.csv`](../../tool-manifest.csv)。

## 推荐入口

### Texture cache 监听与比对

- `WatchTexCacheAndDiff.ps1`：`stable`；
- `WatchTexCacheAndDiff.cmd`：同工具包装器；
- 前提：Model 2 Emulator、TEXCACHE 和 canonical manifest 已准备；
- 重要副作用：脚本会把 TEXCACHE 中稳定的 PNG **移动**到批次目录，并删除旧 candidate sheets；
- 验证：检查 batch、`RawDump/`、candidate CSV 和 sheets，而不是只看终端消息。

当前最可靠的触发方式仍是模拟器中手工执行 `Game -> Dump texture cache`。

### 视频抽帧

- `ExportHoneyVideoFrameSamples.ps1`：`stable`；
- 依赖 FFmpeg；
- 必须显式传入当前 `LocalData/` 路径，不依赖历史 `Resources/VideoRefs` 默认值；
- 重要副作用：会删除目标视频目录中之前的 `frame_*.png`。

示例仅展示参数形式，路径按本机调整：

```powershell
pwsh -File .\Tools\Extraction\Model2\ExportHoneyVideoFrameSamples.ps1 `
  -VideoDir .\LocalData\Raw\VideoRefs `
  -OutputRoot .\LocalData\Captures\Honey\FrameSamplesRaw
```

## 实验和参考工具

- `SplitHoneyTurnaroundSheet.ps1`：`experimental`，必须人工确认检测出的三个视图；
- `BuildHoneyFalseColorUvDebugSet.ps1/.cmd`：`reference`，只辅助材质槽观察，不能恢复原始 UV；
- `MatchNinjaRipperFrameToHoneyTextureSet.ps1`：`reference`；
- `MergeNinjaRipperMeshesByTexture.ps1`：`reference`；
- `HoneyVideoFrameCropConfig.json`：历史裁剪配置，仅供参考。

Ninja Ripper 网格已被证明多为碎片薄片，不能作为 Honey 主模型。

## 已拒绝

- `CropHoneyFrameSamples.ps1`：固定裁剪容易混入 UI、对手或截断角色，改为人工选帧；
- `SendDumpTextureCache.ps1/.cmd`：Win32 消息返回不等于 PNG 生成，改为手工菜单 dump；
- `Experimental/fvipers.lua.disabled`：大范围内存读取曾拖死模拟器，不要重新启用。

## 安全要求

1. 先阅读 [`../../Windows/PowerShell-Runbook.md`](../../Windows/PowerShell-Runbook.md)。
2. 使用 `-LiteralPath`，并确认所有写操作位于工作区或明确的本地数据根目录。
3. 执行前备份不可重新取得的输入。
4. GUI 自动化后检查实际新增文件、数量和时间戳。
5. 生成 manifest 时优先记录逻辑路径和 SHA-256，避免只保存个人绝对路径。
