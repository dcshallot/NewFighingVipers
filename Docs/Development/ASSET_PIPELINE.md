# Honey 资产管线（重启时适用）

当前项目处于归档状态。本文件只定义未来重启时的阶段和质量 Gate，不声明存在 Unity 工程或活跃制作。

```text
external source / LocalData/Incoming
        ↓ manifest + rights + SHA-256
Character Bible / fixed references
        ↓
ArtSource/Characters/Honey/<Stage>
        ↓ fixed-view QA
Reference/Archive or approved review
        ↓ approved export
future game project
```

## 阶段

- C1：来源、比例、轮廓和设计边界；
- C2：可快速返工的 blockout；
- C3：拓扑和 UV；
- C4：材质；
- C5：骨骼、权重和动作变形；
- C6：引擎导入、性能、来源和 clean-clone 验收。

## 晋级规则

- 只有 manifest 中 rights、availability、hash 完整的来源可作为事实依据；
- AI 结果与原作证据分层；
- 每个阶段输出固定视角、源哈希、reviewer 和 `pass/rework/stop`；
- 修复必须回到可编辑源，不在导出文件上形成不可回写分叉；
- 未通过当前 Gate 不进入下一阶段；
- game-ready 导出必须有源文件、导出参数、哈希、Git/LFS 和独立备份闭环。

## 路径

- 原始外部输入通过 storage key 映射；
- 临时输入和生成物进入 `LocalData/`；
- 正式原创源进入 `ArtSource/`；
- 小型关键评审证据进入 `Reference/Archive/`；
- 未来游戏工程路径在新决策中定义。

仓库与数据规则见 [`ENVIRONMENT.md`](ENVIRONMENT.md)。
