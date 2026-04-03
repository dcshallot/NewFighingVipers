# Unity Workspace Notes

## Unity Project Location
- 按当前仓库规范，Unity 工程应直接建立在仓库根目录：
  - `C:\Users\dish\projects\NewFighingVipers`
- 也就是说，Unity 生成的 `Assets/`、`Packages/`、`ProjectSettings/` 应该和 `Reference/`、`Resources/`、`Tools/` 并列放在 repo 顶层。
- 不建议再额外套一层 `UnityProject/` 子目录，否则会和现有 `README.md` 里的 Project Structure 约定冲突，也会让 `Reference/` 里的研究资产路径引用变绕。

## Current Honey Texture Inputs

### Canonical grayscale texture set
- 主贴图目录：
  - `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/Main/`
- P2 配色变体目录：
  - `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/ColorAlt_P2/`

### Metadata / mapping docs
- 贴图 manifest：
  - `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/_manifest.csv`
- 当前锁表：
  - `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/_normal_texture_lock.md`
- 第一版部位映射假设表：
  - `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/_part_mapping_v1.md`
- 总览 sheet：
  - `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/_Main_sheet.png`
  - `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/_ColorAlt_P2_sheet.png`

### False-color UV debug set
- 假彩色调试贴图：
  - `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/_LocalScreenshots/FalseColorUvCheck_v1/Textures/`
- 对照表：
  - `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/_LocalScreenshots/FalseColorUvCheck_v1/_false_color_legend.csv`
- 总览图：
  - `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/_LocalScreenshots/FalseColorUvCheck_v1/_false_color_sheet.png`
- 这套 `_LocalScreenshots/` 内容是本地调试资料，默认不进 Git。

## Suggested Initial Unity Folder Layout
- `Assets/Art/Characters/Honey/`
  - Honey 模型、材质、贴图导入后的工作区
- `Assets/Art/Materials/`
  - 通用测试材质
- `Assets/Scenes/`
  - 最小测试场景和后续 arena 场景
- `Assets/Scripts/`
  - 后续角色控制、相机、战斗原型脚本

## Next Unity Tasks
1. 用 Unity Hub 直接把 repo 根目录建成 Unity 工程，不要另起嵌套工程目录。
2. 先搭一个最小材质测试场景：
   - 平面地面
   - 一个测试相机
   - 一个占位灯光
   - 一个用于挂 Honey 模型/材质的测试物体位
3. 把 Honey 模型导入到 `Assets/Art/Characters/Honey/`。
4. 把假彩色调试贴图挂到 Honey 模型材质上，截图观察每个 NormId 颜色落到哪片 UV。
5. 根据截图结果回写：
   - `Reference/.../Honey_Master_TextureSet/_part_mapping_v1.md`
   - `Reference/.../Honey_Master_TextureSet/_normal_texture_lock.md`
6. 当 UV/部位归属基本稳定后，再开始正式颜色还原和 P1/P2 材质拆分。

## Current Caveat
- 现在仓库里还没有 Honey 模型文件，所以已经能生成假彩色贴图，但还不能在 repo 内直接完成“反贴模型看 UV 落点”这一步。
- 如果先拿外部 Honey 模型/临时转换模型进 Unity 测试，建议先把导入路径固定在 `Assets/Art/Characters/Honey/`，不要散落到别的目录。
