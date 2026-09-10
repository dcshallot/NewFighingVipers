# Tools

工具是否存在不代表它属于当前生产链。权威状态、副作用和 profile 见 [`tool-manifest.csv`](tool-manifest.csv)。

## Profiles

| Profile | 入口 | 用途 |
| --- | --- | --- |
| `archive` | `Environment/check_environment.py` | 三平台文档、manifest、哈希、链接和 LFS 规则审计 |
| `blender-replay` | `Blender/` | Mac 上重放 2026-09 Blender/MPFB 测试 |
| `windows-extraction` | `Extraction/Model2/`、`Windows/`、`Generation/Hunyuan3D/` | 按需历史提取与实验 |
| `unity-dev` | 无当前工程 | 未来重启后定义 |

```bash
python3 Tools/Environment/bootstrap.py
python3 Tools/Environment/check_environment.py --profile archive
```

## 状态

- `stable`：在声明 profile 中验证；
- `experimental`：部分可重放，输出或环境不稳定；
- `rejected`：结论为不可用，仅保留失败证据；
- `reference`：历史方法或局部参考，不是当前生产路线。

## 安全规则

1. 默认写入 `LocalData/`；
2. 归档证据只能显式指定新输出，禁止默认覆盖；
3. 输入输出、联网、删除、移动和覆盖必须先查看 manifest；
4. GUI 命令必须验证真实文件副作用；
5. 新工具必须登记 profile、平台、依赖、副作用、网络和可复现性；
6. 历史 Hunyuan 路线缺少完整依赖锁，不得标为 fully reproducible。

专项说明：

- [`Extraction/Model2/README.md`](Extraction/Model2/README.md)
- [`Generation/Hunyuan3D/README.md`](Generation/Hunyuan3D/README.md)
- [`Windows/PowerShell-Runbook.md`](Windows/PowerShell-Runbook.md)
