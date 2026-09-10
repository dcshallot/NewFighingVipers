> **Archived research record.** Paths and statuses below describe the original experiment and may no longer exist. Current facts: [`../../Docs/PROJECT_STATUS.md`](../../Docs/PROJECT_STATUS.md).

## Research Note

### Meta
- Date: 2026-04-03（2026-04-04 更新）
- Topic: Model 2 Honey 角色模型提取/重建路线，含视频抽帧裁剪、三视图生成、Hunyuan3D 白模输出、Unity 验证
- Source Type: 本地脚本实验记录 + 模型生成/导入测试
- Local Path: `Reference/ResearchNotes/2026-04-03-model2-honey-model-extraction-routes.md`
- Status: `in-progress`
- Priority: `high`
- Owner: dish + Codex

### Goal
- 验证 Honey 在 Model 2 这边到底哪条路线最适合作为“可落地的角色模型重建主线”。

### Context
- 当前目标不是精确逆向 Saturn Model 2 原始角色网格，而是尽快得到一个能在 Unity 里观察比例、轮廓、材质方向、后续可在 Blender 里继续修形/重拓扑/绑定的 Honey 角色基模。

### Findings
- 当前主线：`VideoRefs` 视频录像抽帧 -> 人工选正/侧/背参考图 -> kelingAI生成标准三视图 -> `Hunyuan3D-2mv` 输出白模 GLB -> 删除断开的薄片噪声组件 -> 放入 Unity 检查轮廓。
- 2026-04-04 新对照结论：精选原始截图，优先选背景较干净、四肢轮廓清楚的帧，或先用 AI 做轻度背景过滤后，直接喂 Meshy 生成模型/贴图，当前效果整体**优于**“先让 AI 生成三视图设定图，再把三视图喂给另一轮 AI 建模”的二跳路线；同时**不推荐**“Hunyuan 白模 -> Meshy 再上材质”作为当前主线，因为实测贴图和几何对位容易偏，材质很难贴准。
- 路径 1，视频抽帧：`Tools/Extraction/Model2/ExportHoneyVideoFrameSamples.ps1` 能对 `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/_LocalScreenshots/VideoRefs/` 执行“每 3 秒抽 1 帧”，输出到 `Reference/Captures/Honey/FrameSamplesRaw/`，并生成 `_frame_samples_raw_manifest.csv`。
- 路径 2，人工挑图：自动裁剪不稳定后，改为直接浏览 `Reference/Captures/Honey/FrameSamplesFlat/`，人工挑正面/侧面/背面参考帧，这条方式虽然人工量更高，但对 Honey 和对手同屏、UI 干扰、出招遮挡更稳。
- 路径 3，9张图进可灵https://klingai.com/, prompt'根据这些参考图，生成 Honey 的角色三视图设定图：正面、侧面、背面。要求：自然站立，高清, 手臂T-pose,发辫对称下垂',抽卡3次,选择合适的照片提升清晰度,导出,切开
- 路径 4，三视图输入：已经得到 `Reference/Captures/Honey/TurnaroundSplit/front.png`、`side.png`、`back.png`。其中 `side.png` 侧脸朝画面左侧，更接近“右侧视图”，喂 `Hunyuan3D-2mv` 时需要先水平翻转后作为 `left` 输入。
- 成功路径 5，Hunyuan3D 白模生成：已新增 `Tools/Generation/Hunyuan3D/GenerateHoneyMvGlb.ps1` + `Tools/Generation/Hunyuan3D/GenerateHoneyMvGlb.py`，本地 clone 官方仓库到 `Tools/Generation/Hunyuan3D/vendor/Hunyuan3D-2`，在该 venv 下可生成 `Assets/Generated/Hunyuan3D/HoneyFloodfill128Clean/Honey_white_mv.glb`。
- 成功路径 6，白模噪声清理：`Hunyuan3D-2mv` 原始白模里出现 6 个断开的 mesh component，其中 5 个是头顶/脚下附近的极薄浮动平面噪声；脚本已加入“默认只保留最大主体 component”的后处理，清理后 `Honey_white_mv.glb` 只剩 1 个主体组件，原始版本备份为 `Honey_white_mv_raw.glb`。

- Unity 侧验证：工程是 Unity `6000.4.1f1` + HDRP；当前 `Packages/manifest.json` 里尚未包含 glTF 导入包，所以 `.glb` 导入建议先在 Package Manager 里安装 `com.unity.cloud.gltfast`，然后对 `Assets/Generated/Hunyuan3D/HoneyFloodfill128Clean/Honey_white_mv.glb` 右键 `Reimport` 或重新拖入 Scene。

### 失败/降级路径
- 失败/降级路径 1，Ninja Ripper 直接重建角色网格：从 `EMULATOR.EXE` 抓到过 `681` 个 `.rip` 和 `183` 个 `.dds`，Noesis 可以打开 `.rip`，但 Honey 相关 mesh 大多是碎片化薄片/条带，不是可直接拼成角色的完整网格；合并 `Tex_0080_0.dds` 对应 face mesh 后，`_raw.obj` / `_pwdiv.obj` 仍接近薄片碎网格，说明空间组装和原始部件变换不适合作为当前主线。结论：Ninja Ripper 只保留做贴图归属、局部轮廓、部件参考，不当直接建模主线。
- 失败/降级路径 2，批量自动裁剪 Honey 区域：`Tools/Extraction/Model2/CropHoneyFrameSamples.ps1` + `Tools/Extraction/Model2/HoneyVideoFrameCropConfig.json` 虽然能按每视频一套归一化裁剪框输出 `Reference/Captures/Honey/FrameSamplesCropped/`，但不少帧会把对手/UI 裁进去或把 Honey 裁断；因此这条“批量裁 Honey 区域”路线已降级，当前优先直接用 `FrameSamplesFlat/` 人工挑帧。
- 失败/降级路径 3，`rembg` 自动抠背景：`BackgroundMode Auto/Hunyuan` 虽然能下载 `u2net.onnx` 并抠掉参考线，但对 `back.png` 这种 T-pose 水平伸手背面图，手臂容易被误抠成半透明/缺失；因此当前生成白模时优先用 `-BackgroundMode FloodFill -FloodfillThreshold 128`，再用“长水平灰线段清理 + 只保留主体 mesh component”兜底。
- 失败/降级路径 4，Hunyuan3D 贴图 GLB：`Hunyuan3DPaintPipeline` 的模型权重已能下载，Python import 也能通过，但 texgen 初始化时缺 `custom_rasterizer` 扩展；本机当前没有 `cl.exe` / VS Build Tools，无法编译 `hy3dgen/texgen/custom_rasterizer` 和 `hy3dgen/texgen/differentiable_renderer`，所以 `Honey_textured_mv.glb` 暂时没产出。结论：短期先以白模 + Unity 灰材质验证体块，贴图路线待安装 MSVC 工具链后再继续。
- 失败/降级路径 5，Saturn/community 现成模型直接替换：只能做比例和结构参考，不能默认 UV、拓扑、材质分区能直接对上当前 `Honey_Master_TextureSet`，因此不作为当前主线。
- 失败路径 6，`honey-part-mapping-v1`：这条路线尝试“只根据灰度贴图形状 + 少量截图 + P1/P2 变体关系，直接建立 `NormId -> 身体部位 -> 置信度` 映射，再反推模型分件/UV”。结论是目前不成功，不作为建模主线。主要原因是很多 64x128 竖条和躯干曲面贴图存在明显串位风险，且当前 Hunyuan3D 白模/现成模型都没有与这些 `NormId` 一致的原始 UV，可验证性不足；该结果仅保留为失败路径归档和少量局部语义线索，压缩见本文附录 A。

### Evidence
- Screenshots:
  - `Assets/Generated/Hunyuan3D/HoneyFloodfill128Clean/preprocessed_views/_contact_sheet.png`
  - `Assets/Generated/Hunyuan3D/Honey/preprocessed_views/_contact_sheet.png`
- Video captures:
  - `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/_LocalScreenshots/VideoRefs/`
  - `Reference/Captures/Honey/FrameSamplesRaw/`
  - `Reference/Captures/Honey/FrameSamplesFlat/`
- Extracted files:
  - `Reference/Captures/Honey/TurnaroundSplit/front.png`
  - `Reference/Captures/Honey/TurnaroundSplit/side.png`
  - `Reference/Captures/Honey/TurnaroundSplit/back.png`
  - `Assets/Generated/Hunyuan3D/HoneyFloodfill128Clean/Honey_white_mv.glb`
  - `Assets/Generated/Hunyuan3D/HoneyFloodfill128Clean/Honey_white_mv_raw.glb`
- Tool output:
  - `Reference/Captures/Honey/FrameSamplesRaw/_frame_samples_raw_manifest.csv`
  - `Reference/Captures/Honey/TurnaroundSplit/_turnaround_split_manifest.csv`
  - `Assets/Generated/Hunyuan3D/HoneyFloodfill128Clean/Honey_mv_generation_manifest.json`
  - 本次白模 mesh 统计：清理前 `part_count=6, vertices=369287, faces=738618`；清理后 `part_count=1, vertices=195651, faces=391366`
- Comparison notes:
  - `Honey_white_mv_raw.glb` 用于对照原始 2mv 输出里的头顶/脚下浮动薄片噪声。
  - `Honey_white_mv.glb` 是当前供 Unity 检查轮廓的清理版白模。

### Relevance to Prototype
- Gameplay: 当前仅用于角色体块和站姿轮廓验证，还不能直接进入可操作角色逻辑。
- Animation: 白模无骨骼、无 skin weights，后续必须在 Blender 做重拓扑、关节切分、骨架绑定、权重。
- Art / Model: `Hunyuan3D-2mv` 白模路线已证明能快速得到 Honey 轮廓基模，但拓扑偏高面数，且细节仍需人工修。
- Texture / Material: Ninja Ripper 贴图可继续做部件颜色/花纹参考，但自动贴图 GLB 因 `custom_rasterizer` 未编译暂时阻塞。
- Audio: N/A
- Extraction pipeline: 视频抽帧 + 人工挑帧 + 三视图生成 + 2mv 白模这条链路已跑通；Ninja Ripper 直接 mesh 重建和批量自动裁剪已降级。
- UI / Presentation: Unity HDRP 里可先用 `HDRP/Lit` 灰色材质检查白模体块，等贴图路线恢复后再替换。

### Risks / Gaps
- 当前白模来自 AI 重建，不是 Saturn 原始拓扑；即使轮廓接近，也不能默认关节线、边流、UV 适合动画和近景。
- 清理策略是“只保留最大 mesh component”，如果后续生成结果把翅膀/头发/装饰拆成独立组件，可能被误删；必要时要加组件白名单或阈值规则。
- FloodFill 背景清理对浅灰参考线是启发式规则，仍可能在手套高光、翅膀浅色边缘附近引入轻微误删。
- `FrameSamplesFlat/` 人工挑图主观性较强，若正/侧/背三视图姿态不一致，会直接污染 2mv 输出。
- 贴图路线依赖本机安装 MSVC/Build Tools 并成功编译 texgen CUDA 扩展，目前仍未验证。

### Decision
- Use / Maybe / Reject: `Use`
- Reason: 当前更推荐把“视频参考 -> 人工精选干净截图/轻度 AI 去背景 -> 直接喂 Meshy 出模型/贴图/rig -> Unity 检查”提到优先级更高的位置，因为实测细节保留和整体观感好于“先 AI 生三视图再 AI 建模”的二跳路线；原来的“标准三视图 -> Hunyuan3D-2mv 白模”仍可作为白模对照分支，但短期**不推荐**再走 “Hunyuan 白模 -> Meshy 上材质”，因为贴图对位误差明显。Ninja Ripper 直接 mesh 重建、批量自动裁剪、rembg 自动抠背景、未编译 texgen 贴图都已验证存在明确问题，不作为当前第一优先级主线。

### Next Action
- [ ] 在 Unity 里 Reimport `Assets/Generated/Hunyuan3D/HoneyFloodfill128Clean/Honey_white_mv.glb`，用灰材质检查体块、比例、异常破面、正反面问题。
- [ ] 安装 Visual Studio Build Tools / MSVC `cl.exe`，编译 `hy3dgen/texgen/custom_rasterizer` 和 `hy3dgen/texgen/differentiable_renderer`，恢复 `Honey_textured_mv.glb` 贴图生成路线。
- [ ] 在 Blender 里对清理版白模做比例修正、减面/重拓扑、部件拆分、骨架绑定测试。
- [ ] 如果 2mv 白模仍有由参考线/抠图导致的形体噪声，改用手工透明底三视图或重画干净 Turnaround。

### Follow-up Files
- `Reference/ResearchNotes/2026-04-03-honey-video-frame-crop-pipeline.md`
- `Tools/Extraction/Model2/ExportHoneyVideoFrameSamples.ps1`
- `Tools/Extraction/Model2/CropHoneyFrameSamples.ps1`
- `Tools/Extraction/Model2/HoneyVideoFrameCropConfig.json`
- `Tools/Extraction/Model2/SplitHoneyTurnaroundSheet.ps1`
- `Tools/Generation/Hunyuan3D/GenerateHoneyMvGlb.ps1`
- `Tools/Generation/Hunyuan3D/GenerateHoneyMvGlb.py`

### Notes
- 本笔记已把 `Reference/ResearchNotes/2026-04-03-honey-video-frame-crop-pipeline.md` 的抽帧/裁剪流程并入“成功路径/失败路径”总结。
- 旧版文件内容在 PowerShell 默认编码下显示为乱码，本次直接重写为 UTF-8 中文结构化笔记。
- https://huggingface.co/tencent/Hunyuan3D-2mv

### 2026-04-04 Update - Hunyuan3D Paint 手工跑通，但贴图质量暂不可用
- 白模输入确认：本次 Paint 没有重新生成白模，而是直接复用 `Assets/Generated/Hunyuan3D/HoneyFloodfill128Clean/Honey_white_mv.glb`。
- 今日新增产物：`Assets/Generated/Hunyuan3D/HoneyFloodfill128Clean/Honey_textured_mv_manual.glb`、`Honey_textured_mv_manual_baseColor.png`、`Honey_textured_mv_manual_render_y000.png`、`Honey_textured_mv_manual_render_y090.png`、`Honey_textured_mv_manual_render_y180.png`。
- texgen 扩展编译过程：旧的 `setup.py install` 长时间卡住，不是正常编译慢，而是当前 PowerShell 环境里存在 `Path/PATH` 重复键，venv Python 会再拉起系统 Python 子进程，导致 ninja 构建链路跑偏；改成拆细后的手工编译/链接后，分别生成 `custom_rasterizer_kernel.pyd` 和 `mesh_processor.pyd` 并手工放入 `Tools/Generation/Hunyuan3D/vendor/Hunyuan3D-2/.venv/Lib/site-packages/`。
- 编译细节：`grid_neighbor.cpp`、`rasterizer.cpp`、`mesh_processor.cpp` 用 MSVC `cl.exe` 编译；`rasterizer_gpu.cu` 用 `nvcc` 编译时，CUDA 12.1 + MSVC 14.44 需要额外加 `-allow-unsupported-compiler` 和 `_ALLOW_COMPILER_AND_STL_VERSION_MISMATCH` 绕过版本检查；链接 `custom_rasterizer_kernel.pyd` 时遇到过 `LNK1104: 无法打开文件 msvcprt.lib`，补 MSVC/Windows Kits `/LIBPATH` 后解决。
- Paint pipeline 加载过程：`Hunyuan3DPaintPipeline.from_pretrained('tencent/Hunyuan3D-2')` 在当前受限网络环境下不能直接在线取权重，改为读取本地 snapshot `Tools/Generation/Hunyuan3D/cache/huggingface/hub/models--tencent--Hunyuan3D-2/snapshots/9cd649ba6913f7a852e3286bad86bfa9a2d83dcf`；同时显式设置 `HF_HOME` 和 `HF_MODULES_CACHE` 指向仓库内 cache，避免写 `C:\Users\dish\.cache\huggingface\modules` 触发权限问题。
- torch/transformers 兼容问题：当前 venv 的 `torch==2.5.1+cu121` 会被 `transformers` 的 `check_torch_load_is_safe` 拦住 `.bin` 权重加载，手工 monkeypatch `transformers.utils.import_utils.check_torch_load_is_safe` 和 `transformers.modeling_utils.check_torch_load_is_safe` 后可加载本地 Paint pipeline。
- 多视图贴图输入改造：为了让 Paint 尽量复用 2mv 的三视图输入，已改 `Tools/Generation/Hunyuan3D/GenerateHoneyMvGlb.py` 支持 `--texture-input-mode front-left-back`，并把 `hy3dgen/texgen/utils/multiview_utils.py` 里的 `camera_info_ref` 从写死 `[[0]]` 改为按输入参考图数量生成 `[list(range(num_ref))]`。
- 本次手工运行结果：调用 `pipe(mesh, image=[front, left, back])` 成功导出 `Honey_textured_mv_manual.glb`，单次贴图生成耗时约 384 秒；该 GLB 不是空壳，mesh 约 `302560` 顶点、`391366` 面，`PBRMaterial.baseColorTexture` 存在，贴图尺寸 `2048x2048`。
- 贴图质量验收：导出的 `Honey_textured_mv_manual_baseColor.png` atlas 上黑/白噪声碎块很多，UV 岛分布很碎；用 `trimesh.Scene.save_image()` 渲染正/侧/背预览后，能看到红裙、黑发、靴子等颜色确实贴上了，但脸部、发梢、轮廓边缘有明显黑噪点，背部两片白色“翅膀状”结构更像白模几何本身错误，不是单纯贴图问题。
- 额外依赖：为了渲染预览，在 Hunyuan venv 里安装了 `pyglet-1.5.31`；未安装前 `trimesh.Scene.save_image()` 会报 `ModuleNotFoundError: No module named 'pyglet'`。
- 当前结论：`AI 三视图 -> Hunyuan3D-2mv 白模 -> Hunyuan3D Paint 贴图` 这条链路已经技术性跑通，但今天这版贴图质量仍不能直接用于游戏资产；短期不建议把 Paint 结果当成可用成品贴图，只适合继续做对照实验，例如同一白模下对比 `front` 单图 vs `front-left-back` 三图、先重做更干净白模再 Paint、或回到 Model 2 原始贴图提取路线做材质参考。

### Appendix A - `honey-part-mapping-v1` 压缩归档（失败路径）
- 来源：由 `2026-04-03-honey-part-mapping-v1.md` 压缩合并进本文，原独立笔记删除以避免重复维护。
- 结论：这是一条**不成功的路径**。它可以提供少量“这张贴图大概像脸/发/裙摆/扣件”的人工线索，但不能直接产出可靠的 `NormId -> 模型部件 -> UV` 映射，因此不作为 Honey 建模主线。
- 为什么不成功：
  - 贴图本身是灰度结构/高光形状，颜色和材质层不完整，很多细长条块/曲面块靠肉眼很难唯一定位。
  - `A024011 / A044011 / C004011 / C054010` 这类竖条组，和 `A084012 / C084012 / D084012 / E044012 / F044012` 这类躯干曲面组，存在大量“看起来像，但无法确认挂到靴子/背带/腰侧/袖口哪一片 UV”的情况。
  - 当前最可用的 `Hunyuan3D-2mv` 白模不是原始 Model 2 拓扑和 UV；Saturn/community 现成模型也不能默认和 `Honey_Master_TextureSet` 一一对槽，所以缺少可闭环验证的目标网格。
- 可保留的压缩线索：
  - 高置信部位：`9104012` 正脸，`8106013` 刘海，`9144012` 侧发，`8086012 / 80C6012 / 90C6012` 裙摆花边/褶皱，`D044012` 胸前衣身，`D004012` 后背上身/背带扣件，`B04600A` 白色蕾丝饰件。
  - 中低置信高风险组：`A024011 / A044011 / C004011 / C054010` 竖条，`B024011 / C024011 / C106012 / D004012` 扣件/连接件，`B04600A / B84600A` 蕾丝饰件归属，`C00600A / C80600A / D00600A / E84600A / B044012` 后发层次和左右侧归属。
- 后续使用规则：
  - 这些映射只能当“局部部件语义提示”和“人工检查清单”，不能当自动 UV 绑定依据。
  - 建模主线仍以“视频参考 -> 三视图 -> Hunyuan3D 白模 -> Blender 修形/重拓扑/绑定”为主；若后续恢复原始 UV 级别验证，再重新开新文档做 `NormId -> UV 槽位` 正式映射。
