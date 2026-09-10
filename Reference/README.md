# Reference

本目录保存研究证据的索引，而不是可直接发布的原作资产。

## 导航

- [`Archive/`](Archive/)：进入 Git 的小型关键视觉证据。
- [`Manifests/`](Manifests/)：来源、外部 input、选帧、资产与哈希索引。字段规则见 [`Manifests/README.md`](Manifests/README.md)。
- [`ResearchNotes/`](ResearchNotes/)：按日期保存的历史调查与实验记录。

## 历史路径声明

`ResearchNotes/` 正文按实验发生时的路径和环境保留。其中的 `Assets/`、`Resources/`、`Reference/Captures/`、`Reference/OriginalAssets/` 等路径可能已不存在，不能代表当前仓库状态。

当前事实以 [`../Docs/PROJECT_STATUS.md`](../Docs/PROJECT_STATUS.md) 为准；Mac Blender 测试结论以 [`../Docs/MAC_BLENDER_HONEY_AUTOMATION_TEST.md`](../Docs/MAC_BLENDER_HONEY_AUTOMATION_TEST.md) 为准。

## 受限与外部数据

ROM、视频、截图、dump、第三方包和 AI 批量输出不进入本目录。外部 input 由 storage key 和本地 TOML 映射，文件完整性由 manifest 的大小和 SHA-256 校验。
