# Game

此目录预留给独立的 Unity 6 URP 工程。

## C6 前允许范围

- Honey 模型、材质、Avatar 和 Animator 导入；
- 固定灯光、相机和角色验证场景；
- idle、walk、hit、kick 变形测试；
- 单角色 CPU、GPU 和内存基线；
- 可重复导入和打包验证。

## C6 前不允许扩展

- 完整战斗状态机；
- 招式表、AI、联网和正式 UI；
- 多角色生产；
- 破甲系统；
- 大规模场景或内容管线。

## 版本控制

初始化工程后应提交：

- `Assets/` 与所有 `.meta`；
- `Packages/manifest.json` 和 `packages-lock.json`；
- `ProjectSettings/`。

不得提交 `Library/`、`Temp/`、`Logs/`、`UserSettings/` 和构建输出。大型原创模型与纹理由 Git LFS 管理。

正式基线：Unity `6000.4.1f1` Apple Silicon + URP。若无法复现，先在 `Docs/DECISIONS.md` 新增替代决策。
