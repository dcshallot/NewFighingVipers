# Hunyuan3D 历史实验

状态：`experimental`；Honey 多视图生产路线为 `rejected`。该目录属于 `windows-extraction` 的历史重放工具，不是 archive 或当前生产依赖。

## 可复现边界

当前仓库没有固定的 Python、PyTorch、CUDA、vendor commit、模型 snapshot 和历史手工 patch，因此只能部分重放，不能宣称完整可复现。

默认路径已统一为：

- 输入：`LocalData/Incoming/Honey/TurnaroundSplit/`
- 输出：`LocalData/Generated/Hunyuan3D/Honey/`
- cache：`LocalData/Cache/Hunyuan3D/`

Python 和 PowerShell 相对路径均从仓库根解析；输出被限制在 `LocalData/`。实际运行可能联网下载权重、使用大量 GPU/磁盘并覆盖同名中间物。

## 历史结论

- 旧四视图与左右双视图可以生成文件，但几何低于可修门槛；
- Paint 曾技术性跑通，但依赖未提交的环境与 patch；
- 不能作为 Honey game-ready 角色路线。

证据：[`../../../Reference/ResearchNotes/2026-04-05-hunyuan3d-2mv-four-view-two-view-failure.md`](../../../Reference/ResearchNotes/2026-04-05-hunyuan3d-2mv-four-view-two-view-failure.md)。

如果未来测试新模型版本，应建立新的隔离工具和 manifest，不覆盖本历史脚本的结论。
