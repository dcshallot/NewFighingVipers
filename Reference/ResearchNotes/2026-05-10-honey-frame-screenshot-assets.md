> **Archived research record.** Paths and statuses below describe the original experiment and may no longer exist. Current facts: [`../../Docs/PROJECT_STATUS.md`](../../Docs/PROJECT_STATUS.md).

# Honey 抽帧 / 截图素材与技术路线索引

日期：2026-05-10

用途：记录 Honey 相关抽帧、截图、贴图 dump、AI 生成模型实验的原始文件位置，并把已经尝试过的技术路线按方法归档。当前不处理这些资产，等用户检查后再决定后续怎么整理、清理或继续实验。

## 方法 1：PC 运行游戏，dump 贴图后反复截图比对

### 路线概述

- 在 PC 上用 SEGA Model 2 Emulator 运行 `fvipers`。
- 用手柄操作 Honey 到目标画面、动作、视角。
- 通过模拟器菜单 `Game -> Dump texture cache` 导出当前纹理缓存。
- 每轮 dump 前隔离或清空 `TEXCACHE`，记录场景、对手、动作、dump 时机。
- 对 dump 出来的混杂 PNG 做去重、分桶、contact sheet 粗筛、放大复查。
- 结合游戏截图反复比较，确认哪些贴图属于 Honey，哪些是 P1/P2 配色变体，哪些是 UI、场景、对手或误匹配。
- `_NinjaRipper` / Noesis 属于同一大方向下的运行时抓取实验：用 Ninja Ripper 从模拟器渲染中抓 `.rip` / `.dds`，再用 Noesis 打开检查；当前结论是 Honey mesh 多为碎片化薄片/条带，不是可直接使用的完整角色模型，只保留为局部轮廓、贴图归属和部件参考。

### 当前结论

- `Dump texture cache` 只能拿到“当时已进入缓存”的贴图，不等于 Honey 全量贴图包。
- dump 出来的 Honey 贴图多为灰度/结构信息，不能直接当最终彩色 albedo。
- 直接从 `fvipers.zip` 解包出完整彩色贴图或模型目前不成立，只能帮助理解 ROM 分区。
- Lua 实时扫 texture RAM 会拖慢或卡住模拟器，没有形成可靠工作流。
- 外部窗口消息自动触发 `Dump texture cache` 的实验是“消息能发出，但没有稳定产出 PNG”，不作为主流程。
- `_NinjaRipper` 直接重建 Honey 角色网格的路线已降级：能抓到 `.rip` / `.dds`，但 mesh 多为碎片化薄片，不适合直接拼成角色。
- 仅凭灰度贴图形状反推 `NormId -> 身体部位 -> UV` 的路线已归档为失败路线，因为缺少原始 UV 闭环验证。

### 原始文件 / 工具位置

- 模拟器与 ROM：
  - `Resources/M2emulator/`
  - `Resources/M2emulator/roms/fvipers.zip`
  - `Resources/M2emulator/TEXCACHE`
- dump / 归档工具：
  - `Tools/Extraction/Model2/WatchTexCacheAndDiff.ps1`
  - `Tools/Extraction/Model2/WatchTexCacheAndDiff.cmd`
  - `Tools/Extraction/Model2/SendDumpTextureCache.ps1`
  - `Tools/Extraction/Model2/Experimental/fvipers.lua`
  - `Tools/Extraction/Model2/Experimental/fvipers.lua.disabled`
- 主要资产位置：
  - `Reference\OriginalAssets\Textures\FightingVipers\Honey\Honey_Master_TextureSet`  
- 相关 notes：
  - `Reference/ResearchNotes/2026-04-02-model2-honey-texture-pipeline-progress.md`
  - `Reference/ResearchNotes/2026-04-03-model2-honey-model-extraction-routes.md`

## 方法 2：游戏视频 / 截图 / AI 生成三身图，再生成模型、贴图、骨骼

### 2.1 视频截图与抽帧

- 从 Honey 视频参考素材中按固定间隔抽帧。
- `ffmpeg-8.1` 是本地 FFmpeg 工具包，不是游戏资产；这里用于把视频参考按间隔抽成 PNG 帧。
- 自动裁剪 Honey 区域曾经尝试过，但因为对手、UI、遮挡、出招姿势导致裁断或混入杂物，已降级。
- 当前更可靠的做法是人工浏览抽帧结果，挑选正面、侧面、背面、轮廓完整、背景干净的参考图。

原始文件 / 工具位置：

- 当前保留的抽帧 / 切分目录：
  - `Reference/Captures/Honey/0videoslice`
  - `Reference/Captures/Honey/1sliced`
  - `Reference/Captures/Honey/TurnaroundSplit`
- 抽帧 / 裁剪 / 切三视图工具：
  - `Resources/ffmpeg-8.1-essentials_build/bin/ffmpeg.exe`
  - `Resources/ffmpeg-8.1-essentials_build`
  - `Tools/Extraction/Model2/ExportHoneyVideoFrameSamples.ps1`
  - `Tools/Extraction/Model2/CropHoneyFrameSamples.ps1`
  - `Tools/Extraction/Model2/HoneyVideoFrameCropConfig.json`
  - `Tools/Extraction/Model2/SplitHoneyTurnaroundSheet.ps1`

### 2.2 可灵 / Seedance / Kling 生成三视图或三身图

- 之前使用过游戏截图作为输入，尝试让可灵生成 Honey 的角色三视图设定图。
- 记下过的 prompt 方向是：根据参考图生成 Honey 正面、侧面、背面三视图；自然站立；高清；T-pose；发辫对称下垂。
- 产物再切成 `front / side / back`，作为 Hunyuan3D 或 Meshy 的输入。
- 问题是：二跳路线会引入 AI 补脑，三视图姿势、比例、发束、裙摆可能不一致，后续白模和贴图会被污染。

原始文件 / 输出位置：

- 三视图切分输出：
  - `Reference/Captures/Honey/TurnaroundSplit/front.png`
  - `Reference/Captures/Honey/TurnaroundSplit/side.png`
  - `Reference/Captures/Honey/TurnaroundSplit/back.png`
- 当前目录内还保留：
  - `Reference/Captures/Honey/TurnaroundSplit`

### 2.3 Hunyuan3D-2mv 白模路线

- 输入 `front / left / back` 等多视图，生成 Honey 白模 GLB。
- 本地脚本已经能跑通，包括 side 图左右翻转、FloodFill 背景处理、长水平参考线清理、只保留最大连通 mesh component。
- 最可用输出曾是 `HoneyFloodfill128Clean/Honey_white_mv.glb`，用于 Unity 检查轮廓和体块。
- 四视图、左右双视图等后续实验也能跑出文件，但质量明显不可用，已归档为失败分支。
- 这条失败结论只针对当前 Honey 输入图和当前 Hunyuan3D-2mv 路线；对本项目来说，不再继续用同类截图重复尝试四视图 / 左右双视图白模。

原始文件 / 工具 / 输出位置：

- 生成工具：
  - `Tools/Generation/Hunyuan3D/GenerateHoneyMvGlb.ps1`
  - `Tools/Generation/Hunyuan3D/GenerateHoneyMvGlb.py`
  - `Tools/Generation/Hunyuan3D/vendor/Hunyuan3D-2`
- 主要白模输出：
  - `Assets/Generated/Hunyuan3D/HoneyFloodfill128Clean/Honey_white_mv.glb`
  - `Assets/Generated/Hunyuan3D/HoneyFloodfill128Clean/Honey_white_mv_raw.glb`
  - `Assets/Generated/Hunyuan3D/HoneyFloodfill128Clean/Honey_mv_generation_manifest.json`
  - `Assets/Generated/Hunyuan3D/HoneyFloodfill128Clean/preprocessed_views`
- 失败 / 对照输出：
  - `Assets/Generated/Hunyuan3D/HoneySelected4`

### 2.4 Hunyuan3D Paint 贴图路线

- 在 Hunyuan 白模上继续跑 Hunyuan3D Paint，尝试把三视图颜色烘到 GLB。
- 技术上已经手工跑通，产出了 textured GLB、baseColor atlas、三向渲染图。
- 但 atlas 黑白噪声、边缘脏、几何错误被烤色放大，当前不能直接作为游戏资产。
- 这条路线只适合作为对照实验，不建议作为当前主线。

输出位置：

- `Assets/Generated/Hunyuan3D/HoneyFloodfill128Clean/Honey_textured_mv_manual.glb`
- `Assets/Generated/Hunyuan3D/HoneyFloodfill128Clean/Honey_textured_mv_manual_baseColor.png`
- `Assets/Generated/Hunyuan3D/HoneyFloodfill128Clean/Honey_textured_mv_manual_render.png`
- `Assets/Generated/Hunyuan3D/HoneyFloodfill128Clean/Honey_textured_mv_manual_render_y000.png`
- `Assets/Generated/Hunyuan3D/HoneyFloodfill128Clean/Honey_textured_mv_manual_render_y090.png`
- `Assets/Generated/Hunyuan3D/HoneyFloodfill128Clean/Honey_textured_mv_manual_render_y180.png`

### 2.5 Meshy 白模 / 贴图 / rig 路线

- Meshy 路线目标是一次性生成 mesh、texture、rig，再进 Unity 验证。
- 已评估过两类输入：
  - 截图或可灵三视图输入 Meshy：可跑通，但观感偏粗糙，适合快速原型，不适合直接作为最终资产。
  - 单张正面、主体完整、背景干净的外部参考图输入 Meshy：效果明显更好，说明输入图质量和主体完整性比姿势完全一致更关键。
- Meshy 生成后优先导出 FBX，检查材质、骨骼、Humanoid Avatar、基础动作变形。
- 首轮 Meshy rig 的 Unity Avatar 映射曾经全绿，但导出的自带 clip 是 0 帧，动作验收仍需要重新导出带关键帧动作，或走 Mixamo。

输出位置：

- `Assets/Generated/Meshy/CrimsonValkyrieBiped`
- `Assets/Generated/Meshy/Meshy_AI_keling_filtered_honey_biped`

相关 notes：

- `Reference/ResearchNotes/2026-04-04-meshy-honey-unity-route.md`
- `Reference/ResearchNotes/2026-04-06-meshy-single-front-reference-observation.md`

### 2.6 Mixamo / Unity 骨骼与动作验证

- 如果 Meshy 自带 rig 或动作库不够用，可导出 FBX 上传 Mixamo，套 Idle / Walk 等基础动作后再回 Unity。
- Mixamo 可处理标准人形骨架，但不能自动解决 Honey 双马尾、裙摆、袖口、蕾丝挂件等非标准部件的权重和物理。
- Unity 侧重点检查：
  - FBX 材质和贴图是否正常。
  - Rig 是否能设为 Humanoid。
  - Avatar mapping 是否完整。
  - idle / walk / run / kick 等动作下肩、髋、膝、裙子、双马尾是否明显塌陷或穿模。

Unity / 资产位置：

- `Assets/Generated/Meshy/CrimsonValkyrieBiped`
- `Assets/Generated/Meshy/Meshy_AI_keling_filtered_honey_biped`
- `Assets/Generated/Hunyuan3D/HoneyFloodfill128Clean/Honey_white_mv.glb`
- `Assets/Scenes/HoneyMaterialTest.unity`
- `Assets/Scenes/HoneyMaterialTest`

## 方法 3：OpenKeeper 作为老游戏新框架运行 / 高清材质可行性参考

### 路线概述

- OpenKeeper 不是 Fighting Vipers 资产路线，而是一个横向参考项目。
- 研究目的：观察一个老商业游戏能否通过“原版安装目录 + 开源重实现引擎 + 新渲染框架”运行起来，并评估这类项目对高清材质、资产转换、现代工具链接入的参考价值。
- 本地测试对象是 Dungeon Keeper 2 + OpenKeeper，用来验证这种工作流是否具备现实参考意义。

### 当前结论

- OpenKeeper 能读取本机 Dungeon Keeper 2 安装目录，并能把游戏跑起来。
- 但功能完成度远不到“可以正常玩”的程度，不适合作为可玩体验参考。
- 高清材质 / 素材替换方向没有继续深入实验；当前只保留为“老游戏资源接入现代开源引擎”的技术参考。
- 这条路线不改变本项目方向，不代表从 Fighting Vipers 转向 Dungeon Keeper 2。

### 测试环境 / Requirements

- Windows 本机环境。
- 原版 Dungeon Keeper 2 安装目录：
  - `C:/Program Files (x86)/Steam/steamapps/common/Dungeon Keeper 2`
- OpenKeeper checkout：
  - `Reference/OriginalAssets/OpenKeeper`
- 运行辅助脚本：
  - `Tools/Windows/Run-OpenKeeper-DK2.ps1`
- Java / Gradle：
  - 需要 JDK 25+ 在 `PATH` 上可用。
  - 需要 `java` 和 `javac` 都能被找到，只有 JRE 不够。
  - 本地用过的 JDK 路径示例：`C:/Program Files/Eclipse Adoptium/jdk-25.0.3.9-hotspot/bin`
  - OpenKeeper 当前 `build.gradle` 使用 `JavaLanguageVersion.of(25)`。
  - Gradle wrapper：`Reference/OriginalAssets/OpenKeeper/gradle/wrapper/gradle-wrapper.properties`，版本 `9.2.1`。
- 引擎 / 依赖：
  - OpenKeeper 使用 Java + jMonkeyEngine。
  - 当前本地 checkout 的 `build.gradle` 里 `jmonkeyengine_version = '3.8.0-stable'`。
  - Gradle 会从 Maven Central、Sonatype、JitPack 等仓库拉依赖；首次构建需要网络或已有缓存。

### 原始文件 / 工具位置

- OpenKeeper 项目：
  - `Reference/OriginalAssets/OpenKeeper`
  - `Reference/OriginalAssets/OpenKeeper/build.gradle`
  - `Reference/OriginalAssets/OpenKeeper/openkeeper.properties`
  - `Reference/OriginalAssets/OpenKeeper/assets`
  - `Reference/OriginalAssets/OpenKeeper/assets/Converted`
- DK2 原始资产来源：
  - `C:/Program Files (x86)/Steam/steamapps/common/Dungeon Keeper 2`
- 本地运行脚本：
  - `Tools/Windows/Run-OpenKeeper-DK2.ps1`
- README 记录：
  - `README.md`

## 当前待用户决定

- 这些素材目录暂时只记录，不移动、不清理、不批处理。
- 用户检查后决定：
  - 哪些截图 / 抽帧要保留为长期参考。
  - 哪些 AI 生成中间产物可以清理。
  - 后续要继续押注 Model 2 原始资源研究、Meshy 单图路线、标准三视图路线，还是改成手工 / 半手工建模路线。
