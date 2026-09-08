# 美术资产管理

## 四层模型

| 层 | 内容 | 存储 |
| --- | --- | --- |
| 项目事实 | 规格、QA、manifest、脚本、Unity YAML | 普通 Git |
| 正式二进制 | 原创 `.blend/.fbx`、批准纹理和里程碑评审 | Git LFS |
| 本地受限／高噪声 | ROM、dump、原作参考、第三方包、AI 批量输出、cache | `LocalData/`，不进 Git/LFS |
| 灾备 | 正式主文件和必要本地资料的独立副本 | NAS/对象存储/云盘，服务待定 |

## Git LFS 规则

- LFS 只保存经授权的原创正式资产和批准导出；
- `.blend`、`.spp`、`.psd`、`.fbx` 等不可合并文件设置 `lockable`；
- 修改前执行 `git lfs lock <path>`，交付后执行 `git lfs unlock <path>`；
- 一个角色的同一阶段只设一个 owner；
- 首次上传大文件前验证远端 LFS 容量、计费、锁定和下载恢复；
- 若远端不支持锁定，以 owner 清单和短生命周期分支替代，但不得并行修改同一文件。

## 版本命名

工作过程：

```text
Honey_Blockout_v001.blend
Honey_Blockout_v002.blend
Honey_Retopology_v001.blend
```

批准主文件与游戏导出：

```text
Honey_Master.blend
Honey.fbx
```

工作文件使用版本号便于阶段比较；稳定导出不带版本号，避免 Unity GUID 和 Prefab 引用漂移。正式历史由 Git/LFS、manifest 和里程碑 tag 共同管理。

## 保存策略

- 不提交每次自动保存和每个尝试版本；
- 每个阶段保留当前可编辑主文件；
- C2～C6 各保留一个批准快照；
- 临时 bake、render、AI variation 和失败输出保存在 `LocalData/Generated/` 或被忽略的工作目录；
- 只有评审所需的最小输出才晋级 LFS。

## Manifest 闭环

`honey-asset-manifest.csv` 记录：

- asset ID 和阶段；
- 源逻辑路径与批准导出；
- SHA-256；
- owner 和 reviewer；
- LFS/lock 状态；
- 评审结论；
- Git commit/tag；
- 发布状态。

manifest 不替代 Git 历史，但负责证明某次评审对应哪个源文件和导出。

## 备份

Git LFS 不是备份。最低要求：

- 正式主文件在 Git LFS 远端之外至少有一份独立副本；
- C2～C6 通过后同步备份；
- 每个里程碑抽查一次从备份恢复文件并验证 SHA-256；
- 本地受限参考若无法重新取得，应加密备份，但不得因此上传到项目 Git；
- 备份介质、位置和访问人不写入公开仓库，只记录是否已完成。

## 交接

交接一个二进制资产时必须：

1. 保存并关闭 DCC；
2. 清理无用数据块和外部绝对路径；
3. 更新 asset manifest；
4. 提交源文件及必要依赖；
5. 推送 LFS object；
6. 由接收者拉取并打开验证；
7. 解锁或转移 owner。

## 禁止进入 LFS

- ROM、模拟器、游戏原始包；
- 原作截图、视频和 texture dump；
- Ninja Ripper/Noesis 抓取；
- 第三方 checkout、模型或材质库；
- 来源不清的同人图；
- AI 批量生成和失败实验；
- Unity `Library/`、Blender cache 和自动保存。
