## Research Note

### Meta
- Date: 2026-04-04
- Topic: Meshy 三视图自动建模/贴图/骨骼作为 Honey -> Unity 替代路线评估
- Source Type: 官方文档调研 + 本地 Hunyuan / texture / extraction 实验归档
- Source Name: Meshy Help Center, Adobe Mixamo Help, local scripts and generated assets
- Link: [Meshy Multi-View](https://help.meshy.ai/en/articles/12634481-how-to-use-multi-view), [Meshy Image to 3D](https://help.meshy.ai/en/articles/9996860-how-to-use-the-image-to-3d-feature), [Meshy upload model for animation](https://help.meshy.ai/en/articles/9992032-is-it-possible-to-upload-my-existing-model-for-animation), [Mixamo rig custom character](https://helpx.adobe.com/creative-cloud/help/mixamo-rigging-animation.html)
- Local Path: `Reference/ResearchNotes/2026-04-04-meshy-honey-unity-route.md`
- Status: `todo`
- Priority: `high`
- Owner: dish + Codex

### Goal
- 评估是否可以把当前 Honey 三视图路线从“本地 Hunyuan3D 白模 + 手工修贴图/骨骼”替换为“Meshy 云端一站式生成 mesh / texture / rig，再进 Unity 验证”。
- 明确如果 Meshy 自带 rig 或动作不够用，是否能用 Mixamo 补人形动作，以及这条链路离“Unity 可用角色”还差哪些手工步骤。

### Context
- 本地 `Hunyuan3D-2mv` 已经能从 `front/left/back` 参考图生成 `Honey_white_mv.glb`，但白模仍有背部“翅膀状”脏几何，且 `Hunyuan3D Paint` 虽然已跑通，当前 `Honey_textured_mv_manual.glb` 的贴图 atlas 噪声明显，不能直接当成游戏资产。
- 从 Unity 目标倒推，最难补的其实不是“有没有一个大致像 Honey 的壳”，而是“拓扑是否适合变形、贴图是否干净、骨骼/权重是否能直接跑动作”。因此需要单独评估 Meshy 是否能一次性把这三项拉到比当前 Hunyuan 路线更接近可用的水平。

### Meshy 替代路线方案
- 输入准备：继续沿用当前三视图素材逻辑，优先使用单角色、干净背景、姿势一致的 `front.png / side.png / back.png`，其中 side 仍要注意左右朝向是否与平台期望一致。
- 生成白模：按 Meshy 官方文档，`Image to 3D` + `Meshy 6` 可开启 `Multi-view`，在初始图之外再补最多 3 张不同角度参考图；对 Honey 这类人形角色，优先开 `Pose = T-Pose` 或 `A-Pose`，避免拿战斗截图里的大动作直接生成。
- 拓扑整理：Meshy 官方建议先 `Remesh` 再 `Texture`，因为先减面/重网格有利于更干净的 UV 和贴图输出；如果目标是 Unity 动画角色，优先对比 `Low Poly / Remesh` 后的边流质量，而不是只看高模正面像不像。
- 生成贴图：在 Meshy 里对选中的 mesh 执行 `Texture`，导出时重点检查 baseColor atlas 是否比 Hunyuan Paint 更干净，脸、发梢、裙边、蕾丝边缘是否还有黑噪/糊边。
- 自动骨骼与动作：Meshy Help Center 说明上传/生成的模型可以进 `Animate` 面板做 rigging 和动画；若 Meshy 动作库或 rig 质量不够，则导出 FBX 后上传 Mixamo 做自动 rig 和动作套用。
- Unity 导入：优先导出 `FBX` 做动画角色验证，导出时确保纹理已 embed；如果只验证静态外观，也可以先导 `GLB`。Unity 侧导入后检查材质、法线方向、骨骼层级、Humanoid Avatar 映射、基础 idle/run/hit 动作播放和裙子/双马尾穿模。

### Mixamo 补动作的可行性边界
- Adobe 官方文档确认 Mixamo 可上传 `FBX / OBJ / ZIP` 做自动 rig；若用 FBX，要打开 `Embed media` 才能带纹理；若用 OBJ，需要把 `.obj + .mtl + textures` 打包成 ZIP 上传。
- Mixamo 适合补“标准人形骨架 + 通用动作库”，但它不会替你解决 Honey 双马尾、裙摆、宽袖口、蕾丝挂件这类非标准飘件的额外骨骼和物理，也不会自动修好坏拓扑或坏权重。
- 因此更现实的定位是：先用 Meshy/Mixamo 快速拿到一个能进 Unity 跑 Humanoid 动作的原型，再在 Blender 里手工补裙子/头发权重、必要时加额外骨骼或拆成独立物理部件。

### Unity 可用性验收标准
- 静态外观：正/侧/背轮廓接近 Honey，脸、双马尾、裙摆、靴子、袖口没有明显拓扑爆裂或多余大块几何。
- 贴图质量：baseColor atlas 没有大面积黑白噪块，脸部和轮廓边缘没有明显脏烤色，颜色风格至少接近当前参考图或可接受为后续手修底稿。
- 骨骼质量：FBX 导入 Unity 后骨骼层级正常，能建立 Humanoid Avatar 或至少稳定播放导入动作，肩肘膝基础关节不塌陷。
- 变形质量：idle / walk / run / kick 这类基础动作下，裙子、双马尾、袖口没有严重拉伸穿模；如果这些部位坏得很明显，则 Meshy/Mixamo 只能算“快速占位原型”，不能算最终角色路线。

### 当前风险 / 可能失败点
- Meshy Multi-View 官方文档写明该功能只在 `Meshy 6` 下可用，且目前面向 `Pro / Studio` 计划；如果账号/套餐不满足，三视图实验会先被平台能力卡住。
- 云端生成对输入图一致性很敏感；如果三视图姿势、比例、发束垂落方向、裙摆轮廓不一致，平台可能像 Hunyuan 一样在背面/侧面补脑出错误结构。
- AI 自动贴图大概率仍不是 Model 2 原始贴图还原；如果目标是“更像原作材质”，现有 dump 出来的 `Honey_Master_TextureSet` 仍然更适合作为颜色/花纹参考，而不是完全丢掉。
- 云平台路线存在素材上传和授权边界问题；如果后续要把游戏截图或参考图批量传到 Meshy，需要单独评估项目使用范围和平台条款，避免把这条实验直接等同于可发布资产生产流程。

### 基于现有 texture / extraction 线，已额外完成的工作
- Texture dump 主集合整理：通过 Model 2 Emulator 的 `Dump texture cache` 路线，已经把 Honey 常态主贴图集合收敛到 `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/Main` 和 `ColorAlt_P2`，并保留 `_manifest.csv`、`_Main_sheet.png`、`_ColorAlt_P2_sheet.png` 作为索引和人工复核入口；当前结论是这些 PNG 主要还是灰度/结构/alpha 线索，不能直接当最终 albedo。
- Texture 半自动归档工具：已补 `Tools/Extraction/Model2/WatchTexCacheAndDiff.ps1/.cmd` 做 TEXCACHE 监听、按 `ContentHash / NormId / SameTail6NewPrefix / LooseSlotId` 做候选分类和提示；`SendDumpTextureCache.ps1/.cmd` 也已做过外部菜单命令注入实验，但“消息能发出却不稳定产 PNG”，因此保留为降级路径，不当主流程。
- Video frame extraction：已补 `Tools/Extraction/Model2/ExportHoneyVideoFrameSamples.ps1` 从 `VideoRefs` 按固定间隔抽帧输出到 `Reference/Captures/Honey/FrameSamplesRaw/`，并生成 `_frame_samples_raw_manifest.csv`，用于人工挑 front/side/back 参考帧。
- 批量裁剪与三视图切分：已补 `Tools/Extraction/Model2/CropHoneyFrameSamples.ps1` + `HoneyVideoFrameCropConfig.json` 做按视频归一化裁剪，但因 UI/对手/截断问题已降级；后续改为人工挑图后，用 `Tools/Extraction/Model2/SplitHoneyTurnaroundSheet.ps1` 把三视图设定图切成 `front.png / side.png / back.png`。
- Ninja Ripper 对照路线：已补 `Tools/Extraction/Model2/MatchNinjaRipperFrameToHoneyTextureSet.ps1` 和 `MergeNinjaRipperMeshesByTexture.ps1` 做纹理/mesh 归并对照，但实际 `.rip` 多为碎片化薄片网格，不适合直接拼出 Honey 主体模型，因此这条线目前只保留为局部部件和贴图归属参考。
- UV/部位归属辅助：已补 `Tools/Extraction/Model2/BuildHoneyFalseColorUvDebugSet.ps1/.cmd` 做 false-color 调试素材，用于辅助判断灰度贴图块和部位/UV 的对应关系；但“仅凭灰度贴图形状反推 NormId -> 身体部位 -> UV”这条路已经在 `2026-04-03-model2-honey-model-extraction-routes.md` 附录 A 标记为失败路线。
- Hunyuan 白模生成链路：已补 `Tools/Generation/Hunyuan3D/GenerateHoneyMvGlb.py` 和 `.ps1`，可从三视图生成 `Assets/Generated/Hunyuan3D/HoneyFloodfill128Clean/Honey_white_mv.glb`，包括 side 图左右翻转、FloodFill 背景清理、长水平参考线清理、只保留最大连通 mesh component、导出 preprocessed views 和 generation manifest。
- Hunyuan Paint 工程化尝试：已手工编译并安装 `custom_rasterizer_kernel.pyd` 和 `mesh_processor.pyd`，绕过 VS/MSVC 环境和 `setup.py` 卡住问题；已让 `Hunyuan3DPaintPipeline` 从本地 HuggingFace snapshot 加载并跑通三视图贴图，产出 `Honey_textured_mv_manual.glb` 和三向渲染预览图，但贴图 atlas 噪声重、边缘脏、几何错误仍会被烤色放大，因此当前结论是“链路跑通，但成品贴图不可直接用”。

### 2026-04-04 Meshy 首轮实操补充
- 三视图输入检查：`front.png / side.png / back.png` 均存在且单张小于 20 MB；Meshy 里主图优先放 `front.png`，`side/back` 作为 Multi-View 补充图，`side.png` 的左右朝向需人工再确认。
- Remesh 选择：本轮优先按 `Target Polycount = Fixed`、`Topology = Quad`、`Polycount = 100K` 跑动画候选网格；在生成结果里优先选 `faces ~99k / vertices ~71k` 这一版继续 `Texture/Rig`，`faces ~434k` 高模仅保留对照，`Printable` 版本先不走 Unity 骨骼路线。
- 导出与落盘：Meshy rig 后优先下载 `FBX`，`Single File = On`、`With Skin = On`；如要保留干净母模型，可额外导一份 `Animation Added = Off`。本地建议解压到 `Assets/Generated/Meshy/CrimsonValkyrieBiped/`，该目录已被 `.gitignore` 覆盖。
- Unity 导入静态检查：选中 FBX 后在 `Rig` 页设 `Animation Type = Humanoid`、`Avatar Definition = Create From This Model` 并 `Apply`，再进 `Configure...` 检查骨骼 Mapping；本轮 Avatar 映射为全绿。材质显示方面，在 `Materials` 页执行 `Extract Textures...` 和 `Extract Materials...` 到同一 Meshy 目录后，Scene 里已能看到带颜色贴图的静态模型。
- 当前动画卡点：FBX 自带 clip `Armature|Armature|clip0|baselayer` 在 Unity 里被提示长度为 0 帧，属于空动画，暂时无法用于变形验收；下一步若要测动作，需要回 Meshy Animate 明确导出带关键帧的动作，或把当前 FBX 上传 Mixamo 套 `Idle/Walk` 后再回 Unity 验证。

### 2026-04-04 首轮结论与下一轮无 Blender 路线
- 首轮最优：精选图截+去背景直接入 Meshy目前最优, 输入图经验：原始截图只要主体清晰，正面细节保真度可以很高，但背景杂音、UI 残留、边缘噪点会明显诱发白模毛刺和额外错误几何；针对性补一张反面/背面图对“另一面补脑”有帮助。优先使用背景干净、四肢轮廓清楚、遮挡少、人物边缘完整的图。
- 对照1(最早)：`截图/可灵三原图 -> Meshy 白模/贴图/rig -> Unity` 这条链路可行，Humanoid 骨架也能过，但当前模型观感偏粗糙、失真较明显，更适合快速原型，不适合直接升级为最终资产主线。
- 对照2: 截图-可灵三原图, `三原图 Hunyuan 白模 + 三原图 Meshy Texture` 的结果，观感略好于“三原图 Meshy 直接白模+贴图”路线，但细节仍明显不如“Meshy 只传单张截图”那版；单图输入的主要问题是背面/侧面信息缺失，容易在另一面补脑失败。
- 约束条件：下一轮暂时不考虑 Blender 手工 retopo / 权重 / 重烘焙，不走“手搓修模”方案，只比较输入图生成器、白模生成器、云端贴图/rig 组合。

- 方案 A（优先级最高）：`Flux.2 或 Midjourney v6.1+ 标准三视图 -> Hunyuan3D-2mv 白模 -> Meshy Texture/Rig -> Unity`。目标是利用更稳定的正交三视图提高输入质量，同时保留 Hunyuan 可能更好的白模形体，再让 Meshy 只补贴图和骨骼；关键验证点是 Meshy 能否在“不强制洗粗 Hunyuan 形体”的前提下完成 texture/rig。
- 方案 B：`Flux.2 或 Midjourney v6.1+ 标准三视图 -> Meshy 白模/贴图/rig -> Unity`。目标是排除“首轮 Meshy 效果差只是因为可灵三视图输入不够标准”的可能性，重测 Meshy 自身上限。

- 方案 D：`可灵 prompt 强约束升级 -> Hunyuan / Meshy 双分支对照 -> Unity`。保留可灵，但把 prompt 往标准角色设定图方向收紧，同一组三视图分别喂 Hunyuan 和 Meshy 做横向对比。


### Decision
- Use / Maybe / Reject: `Maybe`
- Reason: Meshy 路线值得马上做一次对照实验，因为它理论上比本地 Hunyuan 更接近“mesh + texture + rig 一次到 Unity”。但在真正看到 Honey 这种双马尾/裙摆角色的拓扑、贴图和权重质量之前，不能把它直接升级为主线；尤其 Mixamo 只能补通用人形动作，不能默认解决裙子和头发。

### Next Action
- [ ] 先测“截图原图去背景后直喂 Meshy”路线：优先保留单图输入的高细节优势，同时通过更干净的抠图/背景剔除，观察侧背面补全和整体贴图是否比当前结果更稳。
- [ ] 优先跑方案 A：用 `Flux.2 / Midjourney v6.1+` 生成更标准的 Honey 三视图，再走 `Hunyuan3D-2mv 白模 -> Meshy Texture/Rig -> Unity`，重点确认 Meshy 是否能直接接 Hunyuan 白模并保留形体质量。
- [ ] 并行跑方案 B：同一套 `Flux.2 / Midjourney` 三视图直接喂 Meshy Multi-View，判断首轮粗糙/失真是输入图问题还是 Meshy 白模上限问题。
- [ ] 方案 C/D 作为后续对照：分别测试“视频截图轻修 -> Hunyuan -> Meshy”和“可灵强约束三视图 -> Hunyuan/Meshy 双分支”。
- [ ] 每条路线都把 FBX/GLB 导入 Unity，按“外观/贴图/骨骼/基础动作变形”四项验收标准截图和打分。
- [ ] 如果 Meshy 自带 rig 不够用，导出 FBX 上传 Mixamo，套 2-3 个基础动作后再回 Unity 验证肩、髋、膝、裙子、双马尾的变形情况。
- [ ] 如果 Meshy 白模不如 Hunyuan，但 Meshy texture/rig 可用，则优先推进 “Hunyuan 白模 + Meshy 后处理” 混血路线。
- [ ] 如果 Meshy 白模、贴图、rig 都不稳定，则保留为占位原型路线，不替换当前 Hunyuan + Blender 手修主线。

### Follow-up Files
- `Reference/Captures/Honey/TurnaroundSplit/front.png`
- `Reference/Captures/Honey/TurnaroundSplit/side.png`
- `Reference/Captures/Honey/TurnaroundSplit/back.png`
- `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/`
- `Reference/ResearchNotes/2026-04-02-model2-honey-texture-pipeline-progress.md`
- `Reference/ResearchNotes/2026-04-03-model2-honey-model-extraction-routes.md`
- `Tools/Extraction/Model2/`
- `Tools/Generation/Hunyuan3D/GenerateHoneyMvGlb.py`
- `Tools/Generation/Hunyuan3D/GenerateHoneyMvGlb.ps1`
- `Assets/Generated/Hunyuan3D/HoneyFloodfill128Clean/Honey_white_mv.glb`
- `Assets/Generated/Hunyuan3D/HoneyFloodfill128Clean/Honey_textured_mv_manual.glb`

### Notes
- Meshy Multi-View 文档要点：最多额外补 3 张参考图；图片格式支持 `png/jpg/jpeg/webp`，单张最大 20 MB；Multi-View 仅 `Meshy 6` 支持，当前只对 `Pro / Studio` 计划开放。
- Meshy Image to 3D 文档要点：角色推荐 `T-Pose` 用于 rigging/animation；官方建议 `Remesh before texturing` 以降低面数并得到更干净贴图。
- Mixamo 文档要点：可上传 `FBX / OBJ / ZIP`，FBX 需 `Embed media` 才能带纹理，OBJ 若要带贴图需连同 `.mtl + textures` 一起打 ZIP；自动 rig 后可直接在 Mixamo 套动作并下载。
