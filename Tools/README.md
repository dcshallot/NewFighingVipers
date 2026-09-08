# Tools

本目录保存自写工具和可复盘包装脚本。工具是否存在不代表它属于正式生产链，使用前必须检查 `tool-manifest.csv` 的状态、副作用和证据。

## 状态

- `stable`：在记录环境中验证过，满足输入前提时可用；
- `experimental`：可复盘，但输出或环境尚不稳定；
- `rejected`：已证明不适合当前目标，不应重新作为默认路线；
- `reference`：只保留方法、局部分析或横向参考价值。

完整清单：[`tool-manifest.csv`](tool-manifest.csv)

## 正式方向 C 工具

方向 C 的必需主工具是 Blender、Unity、Python、FFmpeg、Git 和 Git LFS。当前仓库内工具主要服务于环境检查和历史资料研究；没有任何图生 3D 脚本可以直接产出 game-ready Honey。

环境检查：

```bash
python3 Tools/Environment/check_environment.py
```

## Model 2 / Honey 提取

入口：[`Extraction/Model2/README.md`](Extraction/Model2/README.md)

- Windows-only；
- 只在 C1 发现明确参考缺口时定向运行；
- ROM、模拟器、dump 和截图输出进入 `LocalData/`；
- GUI 命令必须通过实际输出文件验证副作用。

## Hunyuan3D

入口：[`Generation/Hunyuan3D/README.md`](Generation/Hunyuan3D/README.md)

当前 Honey 多视图路线已拒绝。脚本保留用于复盘，不是 Mac M4 或方向 C 的必需环境。

## Windows 通用规则

- [`Windows/PowerShell-Runbook.md`](Windows/PowerShell-Runbook.md)：路径安全、编码、GUI 副作用验证和图像处理规则。
- `Windows/Run-OpenKeeper-DK2.ps1`：横向研究参考，可能联网、clone、写配置和启动程序，不属于 Fighting Vipers 生产链。

## 使用原则

1. 先运行只读环境检查。
2. 显式传入路径，不依赖历史默认绝对路径。
3. 将输入和输出放到 `LocalData/`，不要写入正式资产目录。
4. 对会移动、删除、覆盖、联网或长时间运行的工具先阅读 manifest。
5. 同时验证进程退出码和目标文件，不以“命令返回成功”代替产出验收。
6. 新工具必须先登记平台、依赖、输入、输出、副作用和证据，再进入 stable。
