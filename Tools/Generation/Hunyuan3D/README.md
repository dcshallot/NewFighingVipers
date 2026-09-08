# Hunyuan3D 历史实验

状态：**脚本 experimental；Honey 多视图生产路线 rejected**。

`GenerateHoneyMvGlb.py` 和 `GenerateHoneyMvGlb.ps1` 用于复盘历史多视图预处理、白模、贴图和 GLB 导出实验。它们不属于方向 C 的正式生产链，也不是 Mac M4 的必需环境。

## 历史结论

- 四视图和左右双视图都能生成文件；
- 几何质量低于“值得进入 Blender 清理”的门槛；
- Paint 管线曾技术性跑通，但依赖未提交的 vendor 修改、本地模型 snapshot 和编译扩展；
- 当前仓库没有 vendor、模型权重、requirements lock 或历史输出，因此无法从 checkout 完整复现；
- 详见 [`../../../Reference/ResearchNotes/2026-04-05-hunyuan3d-2mv-four-view-two-view-failure.md`](../../../Reference/ResearchNotes/2026-04-05-hunyuan3d-2mv-four-view-two-view-failure.md)。

## 环境边界

- 历史默认环境为 Windows/Linux + NVIDIA CUDA；
- Apple Silicon/MPS 未验证；
- CUDA、PyTorch、`hy3dgen`、vendor checkout、权重和 MSVC/nvcc 扩展均为可选实验依赖；
- 环境健康检查缺少这些依赖时只给出可选项提示，不阻塞 C0～C6。

## 副作用

Python 入口可能：

- 创建本地 cache；
- 下载模型权重；
- 运行高成本 GPU 推理；
- 覆盖预处理图、GLB 和 JSON manifest；
- 在只做 `--prepare-only` 时仍导入部分重量级依赖。

运行前必须使用 `LocalData/Generated/` 作为输出，且不得将结果直接晋级 `ArtSource/` 或 `Game/`。

## 如果重新实验

只有新模型能力、输入证据或明确问题足以推翻历史结论时才建立新实验。必须：

1. 固定 Python、PyTorch、CUDA、Hunyuan commit 和模型 snapshot；
2. 记录输入和工具 SHA-256；
3. 保存完整参数和环境；
4. 将“运行成功”和“质量通过”分开判断；
5. 使用固定正侧背评审；
6. 结果仍只作 Blender 体块参考，除非通过完整资产规格和 QA。

正式替代路线是 Blender 手工／半手工 blockout、重拓扑、UV、材质、绑定与权重。
