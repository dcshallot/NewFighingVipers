# 项目状态

更新日期：2026-09-09

状态：**Archived**

本文件是当前状态的唯一事实源。实验报告保留实验事实，决策页保留历史决策，不应覆盖本页。

## 当前事实

- 2026-09 Mac M4 Blender 自动化测试已完成并归档；
- 本次测试在低人工介入下未达到 Honey 成品门槛；
- 唯一保留模型是 v005 自动化服装 Blockout，不是 game-ready；
- Unity 测试工程已删除，`Game/` 仅为墓碑目录；
- 原始 input 由用户在仓库外保留，仓库只有 manifest；
- 历史 ResearchNotes、Model 2/Hunyuan/Windows 工具仍在；
- 工作区未 commit/push，LFS 远端恢复尚未验证。

## 支持矩阵

| Profile | macOS | Windows | Linux/CI | 状态 |
| --- | --- | --- | --- | --- |
| `archive` | 支持 | 支持 | 支持 | 当前默认 |
| `blender-replay` | Apple Silicon 已验证 | 未验证 | 未验证 | 按需历史重放 |
| `windows-extraction` | 不支持 | 支持 | 不支持 | 按需历史工具 |
| `unity-dev` | dormant | dormant | 不支持 | 未来重启时另行批准 |

## 保留证据

- `ArtSource/Characters/Honey/Blockout/Honey_ClothingBlockout_v005.blend`
- `Reference/Archive/MacBlenderHoneyTest/` 两张评审板
- `Reference/Manifests/` schema v2 清单
- `Docs/MAC_BLENDER_HONEY_AUTOMATION_TEST.md`
- `Reference/ResearchNotes/`
- `Tools/`

## 当前风险

1. v005 尚未形成 Git commit/LFS push/fresh-clone 闭环；
2. 外部 input 依赖用户本地保存，换机器需配置 storage root；
3. Hunyuan 历史环境缺少完整依赖锁，仅可部分重放；
4. Blender replay 只在 Mac Apple Silicon 验证；
5. 项目自有代码和文档许可证尚未由用户选择。

## 重启条件

只有满足以下任一条件才建议重启视觉制作：

- 有许可明确的 production-ready 角色源资产；
- 专用多视图角色到 3D 在相同 Honey 输入上证明可用；
- 有角色美术资源承担脸、发型、服装、拓扑和权重；
- 改为玩法优先，以 placeholder 推进方向 B。

未来重启必须新增决策、启用对应 profile，并重新定义路线图；当前 [`ROADMAP.md`](ROADMAP.md) 仅为归档墓碑。
