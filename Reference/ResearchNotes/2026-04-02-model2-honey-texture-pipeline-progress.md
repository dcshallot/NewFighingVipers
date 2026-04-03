## Model 2 / Honey Texture Pipeline Progress

### Meta
- Date: 2026-04-02
- Topic: Fighting Vipers Model 2 模拟器接入、ROM 解包、Honey 贴图 dump 与整理进展
- Source Type: Emulator / ROM dump / texture cache extraction / local tooling test
- Source Name: SEGA Model 2 Emulator + `fvipers.zip`
- Link: N/A
- Local Path: `Resources/M2emulator/`
- Status: `testing`
- Priority: `high`
- Owner: dish / Codex

### Goal
- 把从“模拟器和 ROM 可运行”到“能稳定拿到 Honey 贴图并整理成可用素材集”的全过程记录下来。
- 明确哪些结论已经验证、哪些方案失败过、哪些地方还需要你后续拍板。

### Context
- 当前目标不是直接拿到原始 3D 源工程，而是先建立一条可重复的研究流程：运行游戏、定向 dump 贴图、筛出 Honey 相关素材、再决定下一步是做模型分件分析还是先解决颜色还原。
- 2026-04-03 范围调整：先补 Honey 常态贴图覆盖并固定主贴图集合，破甲贴图/破甲部件本轮先不做，因为破损状态的部件提取和复原成本明显更高。
- 这份记录只覆盖当前 Model 2 / Honey 贴图阶段，不等于最终美术方案文档。

### Pipeline Rules / Lessons

#### 问题 1：怎样从模拟器里稳定拿到 Honey 贴图？
- 应该怎么做：
  - 用 `EMULATOR.EXE` 正常启动 `fvipers`。
  - 用 Xbox 手柄操作角色，把鼠标和菜单交给模拟器 UI。
  - 在目标画面出现后，用 `Game -> Dump texture cache` 导出当前纹理缓存。
  - 每轮 dump 前先清空/隔离 `TEXCACHE`，并记录“场景、对手、动作、dump 时机”，否则后面会混批次。
- 不应该怎么做：
  - 不要在这台机器上依赖 `Alt` 切菜单焦点；实际会弹 Windows 开始菜单。
  - 不要用“键盘打游戏 + 再点菜单 dump”作为主流程；之前出现过按键后菜单不响应。
  - 不要把 `SendDumpTextureCache.ps1` 当正式方案；目前外部发 `WM_COMMAND 40025` 虽然能发出消息，但没有实际生成 PNG。
- 当前结论：
  - “手柄操作 + 菜单 Dump texture cache”是目前最稳定的短期方案。

#### 问题 2：能不能直接从 `fvipers.zip` 解包出原始模型/彩色贴图？
- 应该怎么做：
  - 可以先把 `fvipers.zip` 解包到 `Resources/M2emulator/roms/fvipers_unpacked`，再结合 MAME 的 `ROM_START(fvipers)` 去判断各 ROM 区块用途。
  - ROM 分组目前按这套理解记录：
    - `maincpu`: `epr-18604d/05d/06d/07d`
    - `main_data`: `mpr-18612/13/14/15` + `epr-18608d/09d/10d/11d`
    - `copro_data`: `mpr-18622/23`
    - `polygons`: `mpr-18616/17/18/19/20/21`
    - `textures`: `mpr-18624/25/26/27`
    - `audiocpu`: `epr-18628`
    - `samples`: `mpr-18629/30/31/32`
- 不应该怎么做：
  - 不要把这些 ROM 文件当成能直接打开的 PNG / WAV / FBX / 源码工程。
  - 不要指望对 `textures` ROM 做简单线性灰度预览就能直接看到完整彩色贴图；实际输出主要是条纹/噪声。
- 当前结论：
  - 静态 ROM 解包目前更适合“理解数据分区”，不适合作为直接资产导出主路径。
  - 按 MAME 渲染代码推测，真正可见 texel 很可能是在运行时进入 `textureram0/1` 后再被使用；这部分仍是后续研究点，不是已完成结论。

#### 问题 3：能不能用 Lua 自动 dump texture RAM？
- 应该怎么做：
  - 如果后续继续研究 Lua，只能先从极小范围、低频率、可验证的探针脚本开始，先确认这个模拟器版本到底会不会加载 `scripts/fvipers.lua`。
  - 当前实验脚本已归档到 `Tools/Extraction/Model2/Experimental/`；如果要再次测试模拟器自动加载，需要临时拷回 `Resources/M2emulator/scripts/`。
- 不应该怎么做：
  - 不要再用“运行中逐 DWORD 大范围扫 texture RAM”的 Lua 脚本；之前已经把模拟器主线程拖到无响应。
  - 不要在 Lua 脚本加载机制没确认前，把自动 dump 当主流程依赖。
- 当前结论：
  - 当前版本下 Lua 自动脚本还没形成可靠工作流，短期先放弃，主流程仍走手动菜单 dump。

#### 问题 4：`Dump texture cache` 导出的到底是不是 Honey 全量贴图？
- 应该怎么做：
  - 把它理解为“当前已经进入纹理缓存的贴图集合”，而不是“角色完整贴图包”。
  - 为了筛 Honey，应该固定 Honey 不变，换对手/场景/动作多轮 dump，再找反复出现的纹理。
  - 为了补完整度，应该专门 dump 背身、侧身、倒地、起身、跳跃、INTRO/胜利特写等常态/非破甲状态。
  - 破甲前后贴图本轮先不纳入补覆盖范围；先把常态主集合固定下来，避免破损部件把分类和命名体系提前搞复杂。
- 不应该怎么做：
  - 不要以为单次 dump 就包含 Honey 全部身体部件。
  - 不要只用开场动画素材做最终战斗模型判断；INTRO 展示资产和实战模型可能不完全一致。
  - 不要只按“屏幕上当时看见了什么”理解 dump 结果；有些未正面显示但已加载的部件也可能被导出。
- 当前结论：
  - 这条 dump 路线适合“逐步拼全 Honey 常态贴图集合”，但完整性要靠多场景、多动作、多轮交叉验证；破甲专用贴图当前明确延期。

#### 问题 5：怎样从混杂 dump 里整理出 Honey 主贴图集？
- 应该怎么做：
  - 主数据结构固定为 `Main/` + `ColorAlt_P2/` + `_manifest.csv` + sheet + lock 文档，不要每来一批 dump 就改目录结构。
  - 每轮新 dump 先和现有 `_manifest.csv` 做 `ContentHash` / `NormId` / `LooseSlotId` 对比，分成 `ExactDuplicate`、`SameNormIdNewContent`、`SameTail6NewPrefix`、`NewNormId` 四类，再生成 review sheet 给人工复核。
  - P1/P2 镜像局、左右侧面对称动作、背面站立/倒地这些 dump 都可以作为“角色归属和配色槽位”的交叉证据，但最后是否入库仍以人工看图 + 来源可追溯为准。
  - 对 P1/P2 成对纹理按 `NormId` 优先归并到主贴图位；主版本放 `Main/`，同槽位但灰度不同的 P2 变体放 `ColorAlt_P2/`，来源全部写回 `_manifest.csv` 的 `SourceFiles`。
  - 本地候选 CSV、自动归档 dump、review sheet 只是一轮筛选的中间产物，收敛后可以整批清理，不进 Git。
- 不应该怎么做：
  - 不要把所有 dump PNG 直接堆到一个目录里当“最终 Honey 贴图集”；里面会混入 UI、场景、对手和重复件。
  - 不要把 P1/P2 所有文件无差别混合；有些是完全重复，有些是同形不同配色，后续用途不同。
  - 不要把 `SameNormIdNewContent` 或 `SameTail6NewPrefix` 自动当成“旧槽位新变体可直接覆盖”；`90C6012_30F6FF69.png`、`C106013 -> 8106013` 这类 UI/logo 误撞已经出现过。
  - 不要只看小尺寸 contact sheet 就直接入库；耳朵、细发束、衣身亮面、花边竖条这类灰度小件要放大复查。
- 当前结论：
  - 当前主集合已收敛到 `Main=39`、`ColorAlt_P2=4`；分类统计为 Face `6+1`、Hair `7+2`、Body_Clothes `24+1`、Ornament `2+0`。
  - “前大段背面站立 + 末段倒地”那批安全并入 10 张 `Main` + 1 张 `ColorAlt_P2`，主要补到躯干曲面块、耳朵、黑色发束、额外花边饰件；这批躯干块先不强行写死前后归属，交给后续 UV 对照。
  - “P1 红 vs P2 蓝、左右侧面对称、七动作序列”那批安全并入 5 张 `Main`，主要补到侧脸眼嘴、侧身上衣面片、细长花边条、V 形系带块。
  - `WatchTexCacheAndDiff.ps1` 已补 `SameTail6NewPrefix` / `LooseSlotId` / `LooseSlotNormIds` 提示；`HoneyRun01` 自动归档这轮又保守补进 3 张 `Main`：`8926009`、`C00600A`、`E84600A`。
  - 当前最值得继续沿用的是“manifest 对比 -> 候选分桶 -> contact sheet 粗筛 -> 放大复查 -> 高置信再入库 -> 清理本地中间产物”的流程。

#### 问题 6：为什么现在贴图是黑白的，能不能直接拿来做最终材质？
- 应该怎么做：
  - 现阶段先把这些灰度图当“结构/alpha/UV 线索”使用。
  - 如果下一步要追求原版配色，就要单独研究 palette、材质色、顶点色/光照与当前 dump 图之间的关系，并拿游戏截图对照验证。
- 不应该怎么做：
  - 不要把这些黑白 PNG 直接当最终彩色 albedo。
  - 不要在颜色来源没搞清楚前，默认“贴图文件本身就应该带完整颜色”。
- 当前结论：
  - 当前 Honey 贴图集已经适合进入“部件归类/建模参考/UV 线索分析”，但还不适合直接进入最终材质还原。

### Findings
- Model 2 模拟器菜单自带的 `Dump texture cache` 目前是最可用的贴图提取入口。
- “键盘操作游戏 + 鼠菜点菜单 dump”容易触发菜单无响应；“手柄操作游戏 + 鼠标点菜单 dump”目前可用。
- 从静态 ROM 直接还原可见纹理这条路暂时没有成功；运行时 texture cache dump 更现实。
- 当前拿到的 Honey 贴图已经足够开始做“模型部件/UV 对应关系分析”，但还不适合直接当最终彩色材质。
- 当前 dump 出来的 PNG 基本是黑白/灰度外观，说明它更像亮度/索引/alpha 形状信息，不是最终上色后的完整材质。
- Honey P1/P2 镜像局对“确认哪些贴图属于 Honey、哪些是配色变体、哪些是重复件”很有帮助。
- 2026-04-03 新一批“前大段背面站立 + 末段倒地” dump 里，已人工筛进 10 张 `Main` + 1 张 `ColorAlt_P2`；明显文字/场景杂图和低置信 `SameNormIdNewContent` 候选暂时不进主集合。
- 2026-04-03 新一批“Honey P1 红 vs P2 蓝，左右侧面对称，站立/跳跃/蹲/倒地/受击飞起/受击漂浮/踢击” dump 里，已保守筛进 5 张 `Main`，优先补到侧脸眼嘴和侧身衣片/饰条；疑似发束/衣片但挂接关系不稳的候选先不收。
- 2026-04-03 `HoneyRun01` 自动归档脚本可用，已验证“手动打 + 手动点 Dump，脚本自动搬运 TEXCACHE、生成候选 CSV 和分页 sheet”这条半自动流程；同时新增了 `SameTail6NewPrefix` 归并提示，靠它又保守补进 3 张 `Main`。
- “你截图、我对比验证”这条人工校验回路已经实际跑过一轮，不是待办项。你已补的截图覆盖了 P1 红的侧背大跨步、正背上半身、倒地侧后低视角、高踢露鞋底、双腿朝上倒地、手套/袖口近景、靴前单腿站立，以及 P2 蓝的侧背/侧面站姿。
- 这批截图主要解决了 6 类贴图归属问题：靴筒黑竖条在“正前方中线”而不是内侧、后背亮色中线 + 黑背片 + 扣件关系、白翅膀根部位置、后发多束尖发的方向、裙摆白花边一圈和裙底黑白结构、黑手套护套 + 白蕾丝袖口 + 上臂黑环分割。
- 从截图工作量上看，当前“能支撑 `_part_mapping_v1.md` 第一版归属判断”的关键视角已经基本覆盖；后续不再需要继续大批量截图，只在假彩色 UV 验证卡住某一块时，再按部位定向补 1-2 组截图。

### Windows Command Invocation Notes

#### 哪些经验对后续整个项目有通用性？
- 有通用性，应该沉淀到项目级 runbook 的：
  - PowerShell 读中文文档要显式 `-Encoding UTF8`
  - `foreach (...) { ... }` 后面如果要继续接管道，外面要包 `& { ... }`
  - 递归删除/清空目录前，必须先校验解析后的绝对路径仍在项目工作区下
  - 对 GUI 程序发命令后，不能只看“调用返回成功”，必须再检查输出目录/文件时间戳等真实副作用
  - 接手柄/USB 设备时，要同时查 Windows 设备枚举和 XInput DLL，而不是只改模拟器配置
  - PowerShell 里做 PNG 尺寸读取、拼图、contact sheet 这类图像批处理时，要先 `Add-Type -AssemblyName System.Drawing`，并且每轮先用小批量/单页验证脚本输出真实落盘，再扩到全量。
  - 分页处理数组时，优先用 `Select-Object -Skip/-First`，不要手写可能越界或退化成标量/空对象的区间切片。
  - `Image.FromFile(...)` 前先 `Test-Path`，`.Save(...)` 后立刻 `Get-Item` / `Test-Path` 验证结果；不要只相信 `Write-Host` 打印出来的路径。
- 这些通用规则已整理到：
  - `Tools/Windows/PowerShell-Runbook.md`

#### 哪些经验只属于本次 Model 2 / Fighting Vipers 研究，不适合写成项目通用规则？
- `WM_COMMAND 40025` 是 Model 2 Emulator 菜单项 `Dump texture cache` 的特定命令 ID，这不是通用 Windows 自动化规则。
- `SendDumpTextureCache.ps1` 在这次实验里“消息能发出但不生成 PNG”，这个结论只说明“这台模拟器/这个菜单项不能这么自动化”，不能直接推广成“所有 GUI 程序都不能发窗口消息”。
- `scripts/fvipers.lua` 没能稳定形成自动 dump 流程，这个问题也更像 Model 2 Emulator 自己的脚本加载/执行特性，不是 PowerShell 通用问题。
- “键盘操作后菜单 dump 失灵，但改手柄后可用”是当前模拟器和输入焦点组合下的专项绕法，也不该写成所有 Windows GUI 程序通用规则。
- `NormId` 只能作为 Honey dump 里的“候选归并线索”，不能单独决定一张图是不是 Honey 或是不是 P2 变体；这是当前 Model 2 TEXCACHE 数据特性，不是通用文件整理规则。
- 尾 6 位槽位匹配同样只能当候选线索，不能自动等价归并；`C106013 -> 8106013` 这种 logo 误撞已经出现过。

#### 这部分后续应该怎么维护？
- 如果后面又遇到 PowerShell 语法、路径安全、编码、设备查询、GUI 副作用验证这类跨工具都通用的问题，优先补到 `Tools/Windows/PowerShell-Runbook.md`。
- 如果是某个模拟器、某个 ROM、某个角色素材提取阶段特有的坑，继续补在本研究笔记或同目录下新建专项笔记，不要污染通用 runbook。

### Evidence
- ROM:
  - `Resources/M2emulator/roms/fvipers.zip`
  - `Resources/M2emulator/roms/fvipers_unpacked`
- Emulator config / tooling:
  - `Resources/M2emulator/EMULATOR.INI`
  - `Tools/Extraction/Model2/SendDumpTextureCache.ps1`
  - `Tools/Extraction/Model2/WatchTexCacheAndDiff.ps1`
  - `Tools/Extraction/Model2/WatchTexCacheAndDiff.cmd`
  - `Tools/Extraction/Model2/Experimental/fvipers.lua`
  - `Tools/Extraction/Model2/Experimental/fvipers.lua.disabled`
  - `Tools/Extraction/Model2/Experimental/fvipers_script_probe.txt`
  - `Resources/M2emulator/CFG/fvipers.input.keyboard-backup-20260402-222157`
- Raw dump:
  - `Resources/M2emulator/TEXCACHE`
  - `Honey_P1P2_MirrorMatch_2224/RawDump` 已清理，仅在 `_manifest.csv` 的 `HistoricalSource/...` 字段保留历史来源标识
- Curated texture outputs:
  - `Honey_TextureSet_S1_S3` 已清理，仅保留历史来源标识
  - `TEXCACHE_SORTED/Honey_Selected_Textures` 已清理，仅保留历史来源标识
  - `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/Main`
  - `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/ColorAlt_P2`
  - `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/_manifest.csv`
  - `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/_Main_sheet.png`
  - `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/_ColorAlt_P2_sheet.png`
  - `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/_normal_texture_lock.md`
  - `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/_part_mapping_v1.md`
  - `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/_LocalScreenshots/VideoRefs/` 本地截图参考目录，仅本机保留，不进 Git

### Relevance to Prototype
- Gameplay:
  - 暂时还没进入帧数据/招式判定复刻，这一阶段主要解决素材来源和可重复提取流程。
- Animation:
  - Honey INTRO 和演示对战可以作为动作观察参考，但还没开始系统化拆动作。
- Art / Model:
  - `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/Main` 已经可以作为后续 Honey 低模分件、轮廓和 UV 分析的输入。
- `_part_mapping_v1.md` 已经整理出第一版 `NormId -> 疑似部位 -> 置信度 -> 证据 -> 待验证点`，当前粗分 `High 11 / Mid 23 / Low 5`，可直接作为假彩色 UV 验证的工作清单。
- Texture / Material:
  - 当前贴图能看结构，但颜色未还原；不能直接当最终彩色贴图。
- Audio:
  - 已识别 `samples` ROM 区域，但还没开始声音提取验证。
- Extraction pipeline:
  - 目前可用主路径是“手柄操作到目标画面 -> 菜单 Dump texture cache -> 清理/归类/去重”。
  - Lua 自动 dump 和外部菜单命令注入这两条路目前都不稳定，不建议作为主路径。
- UI / Presentation:
  - dump 里有时会混入 UI/logo/场景纹理，所以每次整理时仍需要人工或规则筛选。

### Current Status / Decisions / Next Plan

#### 现状
- Honey 常态贴图主集合已收敛到 `Main=39`、`ColorAlt_P2=4`，破甲贴图仍明确延期。
- `_part_mapping_v1.md` 已建立，当前粗分 `High 11 / Mid 23 / Low 5`，可以直接作为下一轮 UV 验证清单。
- 半自动流程 `WatchTexCacheAndDiff.ps1` 可用，但继续大批量 dump 的边际收益已经下降；现在主线已经从“补 PNG 数量”转成“确认 NormId 到模型 UV/部位的挂接关系”。
- `Honey_Master_TextureSet` 里的本地候选/自动归档中间产物已清理，只保留 canonical 集合和 `_LocalScreenshots/VideoRefs/`。

#### 主要问题 / 风险
- 最大短板是 `Body_Clothes / Hair` 里多张条块贴图到底挂 Honey 模型哪一片 UV。
- 特别是 `A024011 / A044011 / C004011 / C054010` 这组竖条类贴图，虽然已经知道靴子黑竖条在靴筒正前方，但还没拆清哪张贴靴前、哪张贴背带/腰侧/袖套。
- `NormId` 精确匹配、尾 6 位松匹配、`SameNormIdNewContent`、`SameTail6NewPrefix` 都只能当候选线索，不能自动决定入库或槽位归属。
- 当前 dump 出来的 Honey 贴图仍是灰度外观，颜色来源很可能还依赖 palette、材质色、顶点色或光照；所以还不能直接当最终 albedo。
- `Dump texture cache` 只能拿到“当时已加载”的贴图，不保证全量；菜单响应和输入焦点问题也只是靠手柄流程绕过，没有从根上解决。

#### 已定决策
- 继续把 `Dump texture cache` 作为短期主提取路径，但不再把“继续大批量 dump”当当前主线。
- `Honey_Master_TextureSet` 继续作为 Honey 常态贴图主集合，主数据结构固定为 `Main/`、`ColorAlt_P2/`、`_manifest.csv`、`_Main_sheet.png`、`_ColorAlt_P2_sheet.png`、`_normal_texture_lock.md`、`_part_mapping_v1.md`。
- 破甲贴图、破损部件、破甲系统接入本轮继续后置。
- Lua 实时扫 texture RAM 和 `SendDumpTextureCache.ps1` 外部菜单注入都不作为当前正式流程。
- 颜色还原/palette 研究后置到“UV/部位挂接基本稳定之后”。

#### 待拍板决策
- 后续建模路线：严格按原版低模分件复刻，还是只借原版比例造型、拓扑按现代 Unity 角色流程重建。
- Model 2 模拟器后续主要作为视觉参考工具，还是继续投入时间做更深的 ROM/运行时数据提取。

#### 下一步计划
- 先按 `_part_mapping_v1.md` 做假彩色 UV 验证，优先攻靴前竖条、后背中线、裙摆花边、手套袖口、后发束。
- 根据假彩色结果回写 `_part_mapping_v1.md` 和 `_normal_texture_lock.md`，把 `Mid/Low` 项逐步收敛成确定映射。
- 如果某块在假彩色验证时仍缺视角或缺贴图，再回到 `_LocalScreenshots/VideoRefs/` 或小批量 dump 做定向补充。
- UV/部位挂接稳定后，再单独启动 palette/颜色还原研究；破甲仍继续后置。

#### 本地中间产物管理规则
- 截图资料、自动归档 dump、候选 CSV、review sheet 只做本地分析用，不进入 Git；`.gitignore` 已覆盖 `_IncomingDump/`、`_IncomingDumpAuto/`、`_LocalScreenshots/`、`_candidate_review*/`、`_candidate_texcache_*.csv`。
- 每轮筛选收敛后，只保留 canonical 结果和研究笔记；本地中间目录可以整批清掉。
- 清理时不要删 `Main/`、`ColorAlt_P2/`、manifest、sheet、lock、mapping 文档。

### Follow-up Files
- `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/_normal_texture_lock.md`
- `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/_part_mapping_v1.md`
- `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/_manifest.csv`
- `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/_Main_sheet.png`
- `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/_ColorAlt_P2_sheet.png`
- `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/Main`
- `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/ColorAlt_P2`
  - `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/_LocalScreenshots/VideoRefs/` 本地截图参考目录，仅本机保留

### Notes
- 当前文档里的“推测/判断”已经尽量和“已验证事实”分开写；尤其是颜色还原、texture RAM 来源、palette 依赖这些部分，目前都应该视为后续研究假设，而不是最终结论。
