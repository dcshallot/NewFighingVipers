# Honey ArtSource

此目录只保存经授权的原创 Honey 工作源文件和批准评审快照。大型二进制文件由 Git LFS 管理。

## 逻辑结构

```text
Blockout/   C2 比例、轮廓和分件
Sculpt/     高模细节
Retopo/     游戏拓扑和 UV
Texture/    可编辑纹理源与 bake 配置
Rig/        骨架、权重和变形测试
Export/     待验证导出
Review/     C2～C6 批准快照
```

实际空目录在首次产生资产时创建，不使用无意义占位文件。

## 命名

- 工作文件：`Honey_<Stage>_vNNN.blend`
- 批准主文件：`Honey_Master.blend`
- 固定导出：`Honey.fbx`
- 评审目录：`Review/CN_<YYYY-MM-DD>/`，其中 `CN` 为 C2～C6

## 规则

1. 开工前确认当前 milestone 和 owner。
2. 编辑不可合并文件前取得 LFS lock。
3. 外部依赖、来源和许可证进入 manifest。
4. cache、autosave、AI variation 和失败 bake 不进入此目录。
5. 只有通过评审的导出才能进入 `Game/Assets/Characters/Honey/`。
6. 每个里程碑同步更新 `honey-asset-manifest.csv` 和独立备份。

详见：

- `Docs/Development/ASSET_PIPELINE.md`
- `Docs/Development/ART_ASSET_MANAGEMENT.md`
- `Docs/Production/Honey/ASSET_SPEC.md`
