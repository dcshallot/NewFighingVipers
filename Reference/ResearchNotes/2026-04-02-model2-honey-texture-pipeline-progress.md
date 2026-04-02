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
  - 为了补完整度，应该专门 dump 背身、侧身、倒地、起身、跳跃、破甲前后、INTRO/胜利特写等不同状态。
- 不应该怎么做：
  - 不要以为单次 dump 就包含 Honey 全部身体部件。
  - 不要只用开场动画素材做最终战斗模型判断；INTRO 展示资产和实战模型可能不完全一致。
  - 不要只按“屏幕上当时看见了什么”理解 dump 结果；有些未正面显示但已加载的部件也可能被导出。
- 当前结论：
  - 这条 dump 路线适合“逐步拼全 Honey 贴图集合”，但完整性要靠多场景、多动作、多轮交叉验证。

#### 问题 5：怎样从混杂 dump 里整理出 Honey 主贴图集？
- 应该怎么做：
  - 先从明确是 Honey 的场景里人工筛一版候选集，再用镜像局 `Honey P1 vs Honey P2` 做交叉确认。
  - 对 P1/P2 成对纹理按 `NormId` 归并：例如 `19104012` 和 `9104012` 视为同一逻辑贴图位，优先保留主版本，再把灰度不同的 P2 版本单独存为颜色变体。
  - 保留 manifest，记录每张主贴图来自哪些原始 dump 文件，避免后面找不到来源。
- 不应该怎么做：
  - 不要把所有 dump PNG 直接堆到一个目录里当“最终 Honey 贴图集”；里面会混入 UI、场景、对手和重复件。
  - 不要把 P1/P2 所有文件无差别混合；有些是完全重复，有些是同形不同配色，后续用途不同。
- 当前结论：
  - 已整理出的主输出是：
    - `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/Main`
    - `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/ColorAlt_P2`
    - `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/_manifest.csv`
    - `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/_Main_sheet.png`
  - 当前数量：
    - `Main`: 21 张
    - `ColorAlt_P2`: 3 张
  - 当前分类统计：
    - Face: 1 张主贴图 + 1 张 P2 配色变体
    - Hair: 3 张主贴图 + 2 张 P2 配色变体
    - Body_Clothes: 16 张主贴图
    - Ornament: 1 张主贴图

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

### Windows Command Invocation Notes

#### 哪些经验对后续整个项目有通用性？
- 有通用性，应该沉淀到项目级 runbook 的：
  - PowerShell 读中文文档要显式 `-Encoding UTF8`
  - `foreach (...) { ... }` 后面如果要继续接管道，外面要包 `& { ... }`
  - 递归删除/清空目录前，必须先校验解析后的绝对路径仍在项目工作区下
  - 对 GUI 程序发命令后，不能只看“调用返回成功”，必须再检查输出目录/文件时间戳等真实副作用
  - 接手柄/USB 设备时，要同时查 Windows 设备枚举和 XInput DLL，而不是只改模拟器配置
- 这些通用规则已整理到：
  - `Tools/Windows/PowerShell-Runbook.md`

#### 哪些经验只属于本次 Model 2 / Fighting Vipers 研究，不适合写成项目通用规则？
- `WM_COMMAND 40025` 是 Model 2 Emulator 菜单项 `Dump texture cache` 的特定命令 ID，这不是通用 Windows 自动化规则。
- `SendDumpTextureCache.ps1` 在这次实验里“消息能发出但不生成 PNG”，这个结论只说明“这台模拟器/这个菜单项不能这么自动化”，不能直接推广成“所有 GUI 程序都不能发窗口消息”。
- `scripts/fvipers.lua` 没能稳定形成自动 dump 流程，这个问题也更像 Model 2 Emulator 自己的脚本加载/执行特性，不是 PowerShell 通用问题。
- “键盘操作后菜单 dump 失灵，但改手柄后可用”是当前模拟器和输入焦点组合下的专项绕法，也不该写成所有 Windows GUI 程序通用规则。

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

### Relevance to Prototype
- Gameplay:
  - 暂时还没进入帧数据/招式判定复刻，这一阶段主要解决素材来源和可重复提取流程。
- Animation:
  - Honey INTRO 和演示对战可以作为动作观察参考，但还没开始系统化拆动作。
- Art / Model:
  - `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/Main` 已经可以作为后续 Honey 低模分件、轮廓和 UV 分析的输入。
- Texture / Material:
  - 当前贴图能看结构，但颜色未还原；不能直接当最终彩色贴图。
- Audio:
  - 已识别 `samples` ROM 区域，但还没开始声音提取验证。
- Extraction pipeline:
  - 目前可用主路径是“手柄操作到目标画面 -> 菜单 Dump texture cache -> 清理/归类/去重”。
  - Lua 自动 dump 和外部菜单命令注入这两条路目前都不稳定，不建议作为主路径。
- UI / Presentation:
  - dump 里有时会混入 UI/logo/场景纹理，所以每次整理时仍需要人工或规则筛选。

### Risks / Gaps
- 颜色问题未解决：
  - 当前 dump 出来的 Honey 贴图是黑白/灰度效果，真实颜色很可能还依赖 palette、材质色、顶点色或光照。
- 完整性问题未完全验证：
  - `Dump texture cache` 只能拿到“当时已加载”的贴图，不保证 Honey 背面、鞋底、破甲后部件、特殊动作部件都已经覆盖。
- 自动化程度不足：
  - 现在仍然依赖手动到目标画面再点菜单 dump，流程可用但不够自动化。
- 模拟器行为不稳定点仍存在：
  - 菜单响应和输入焦点问题没有从根上修掉，只是通过手柄操作绕过去。
- ROM/渲染格式理解还不完整：
  - 已借助 MAME 代码做过初步判断，但还没有把 palette/texture RAM/多边形引用关系彻底串起来。

### Decision
- Use / Maybe / Reject:
  - Use: 继续把 `Dump texture cache` 作为短期主提取路径。
  - Use: 保留 `Honey_Master_TextureSet` 作为当前 Honey 贴图主集合。
  - Maybe: 后续继续研究 palette/材质颜色还原，如果成本太高，再改成“灰度贴图 + 游戏截图手工定色”的路线。
  - Reject for now: 不再用 Lua 重扫 texture RAM 的方式做实时 dump。
  - Reject for now: 不把 `SendDumpTextureCache.ps1` 当正式流程，因为目前发命令后没有实际输出 PNG。
- Reason:
  - 当前目标是先稳定推进 Honey 资产研究；可重复、低风险的流程优先级高于一次性“完美自动化”。

### Pending Decisions
- 决策 1：下一步先攻“颜色还原/palette 提取”，还是先用现有黑白贴图做“模型分件和 UV 对应分析”？
- 决策 2：Honey 的完整贴图覆盖范围，是否要继续补 dump？
  - 例如：背身、倒地、跳跃、破甲前后、胜利动作、特写镜头。
- 决策 3：后续建模路线是“严格按原版分件/低模风格复刻”，还是“只借原版比例和造型，拓扑按现代 Unity 角色流程重建”？
- 决策 4：Model 2 模拟器只作为视觉参考工具，还是继续投入时间做更深的 ROM/运行时数据提取？

### Recommended Next Action
- [ ] 你先看这份记录，确认下一步优先级：先解决颜色，还是先做 Honey 分件/UV 分析。
- [ ] 如果优先补完整度，下一轮 dump 建议固定 Honey，分别补以下状态：
  - 正面站立、背面站立、侧面站立
  - 跳跃/下蹲
  - 倒地/起身
  - 破甲前/破甲后
  - 胜利动作/INTRO 特写
- [ ] 如果优先解决颜色，下一轮就专门研究 palette/材质色来源，并和同一帧游戏截图做对照。
- [ ] 如果优先进入建模准备，就基于 `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/Main` 先整理一版 Honey 模型分件表和疑似缺失部位清单。

### Follow-up Files
- `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/_manifest.csv`
- `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/_Main_sheet.png`
- `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/Main`
- `Reference/OriginalAssets/Textures/FightingVipers/Honey/Honey_Master_TextureSet/ColorAlt_P2`

### Notes
- 当前文档里的“推测/判断”已经尽量和“已验证事实”分开写；尤其是颜色还原、texture RAM 来源、palette 依赖这些部分，目前都应该视为后续研究假设，而不是最终结论。
