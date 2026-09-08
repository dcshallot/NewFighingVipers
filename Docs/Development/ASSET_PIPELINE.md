# Honey 资产生产流程

正式资产只能沿下列单向流程晋级：

```text
LocalData/Raw + LocalData/Captures
        ↓ 来源登记与筛选
Reference/Manifests + CHARACTER_BIBLE
        ↓
ArtSource/Characters/Honey/<Stage>
        ↓ 固定评审
ArtSource/Characters/Honey/Review/<Milestone>
        ↓ 批准导出
Game/Assets/Characters/Honey
```

不得从 `LocalData/Generated/` 直接复制到 `Game/` 并绕过来源、可编辑性和 QA。

## 阶段目录

- `Blockout/`：比例、轮廓和分件；
- `Sculpt/`：高模细节，不直接导入游戏；
- `Retopo/`：游戏拓扑；
- `Texture/`：可编辑贴图源和 bake 配置；
- `Rig/`：骨架、权重和变形测试；
- `Export/`：批准导出前的暂存；
- `Review/`：C2～C6 固定评审快照。

空目录不依赖 Git 保存；具体结构和命名见 `ArtSource/Characters/Honey/README.md`。

## 1. 参考登记

1. 将原始参考放入 `LocalData/Raw/` 或 `LocalData/Captures/`。
2. 计算 SHA-256。
3. 在 `honey-reference-manifest.csv` 登记来源、逻辑路径、权利状态和允许用途。
4. 只有 `decision=adopted` 且权利状态满足项目目标的参考才能成为正式设计依据。
5. 将观察结论写入 Character Bible；不要把受限二进制复制到 `Docs/`。

## 2. 工作源文件

- 新阶段从最近一次批准文件创建，不从任意 AI 输出继续堆叠；
- `.blend` 使用 `Honey_<Stage>_vNNN.blend`；
- 每个阶段只有一名 owner；协作前获取 LFS lock；
- 自动保存、cache、临时 bake 和批量 render 留在被忽略目录；
- 外部插件、字体、brush 和材质库必须登记版本与许可。

## 3. 评审

每个里程碑输出固定内容：

- 正、侧、背、左右 3/4；
- 游戏默认镜头；
- 当前阶段特定检查图；
- 已填写的 `QA_CHECKLIST.md` 副本；
- 源文件和输出 SHA-256；
- reviewer、结论和问题 owner。

评审结论只有：

- `pass`：允许进入下一阶段；
- `rework`：留在当前阶段；
- `stop`：证据或技术路线存在阻塞，停止继续投入。

## 4. 导出到 Unity

- 只从批准的 `Honey_Master.blend` 和批准 collection 导出；
- 使用固定文件名 `Honey.fbx`；
- 导出参数、Blender 版本和哈希写入 asset manifest；
- Unity 中的 `.meta`、材质、Prefab、Avatar、Animator 和验证场景一并纳入 Git；
- 二进制模型与纹理由 LFS 管理；
- 在干净 checkout 中重复导出／导入后才可通过 C6。

## 5. 返工

- Unity 问题先判断属于源模型、导出还是导入配置；
- 禁止只在导出 FBX 上做不可回写修补；
- 所有修复回到对应工作源文件；
- 新导出覆盖固定名称，由 Git/LFS 保存历史；
- manifest 更新新哈希和评审结论。

## 禁止事项

- 提交 ROM、dump、原作视频或来源不明图片；
- 将 AI atlas、Meshy/Hunyuan 输出直接标记为 game-ready；
- 将下载的第三方模型伪装为原创 LFS 资产；
- 在 C1 未冻结前进行高成本细节制作；
- 在 C6 前扩展完整战斗功能。
