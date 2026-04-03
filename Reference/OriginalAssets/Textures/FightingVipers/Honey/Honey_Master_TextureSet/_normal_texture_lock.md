# Honey Normal Texture Lock

## Scope
- 只锁 Honey 常态/非破甲贴图。
- 破甲贴图、破损部件、破甲状态切换素材本轮全部延期，不进入当前 canonical 集合。
- 当前 canonical 集合以本目录下 `Main/`、`ColorAlt_P2/`、`_manifest.csv`、`_Main_sheet.png`、`_ColorAlt_P2_sheet.png` 为准。

## Lock Rules
- `Main/` 里每个 `NormId` 只保留 1 张主版本贴图，优先保留 P1/主配色来源。
- `ColorAlt_P2/` 只存与 `Main/` 同 `NormId` 但内容 hash 不同的 P2 配色变体。
- 现阶段不重命名已入库 PNG，先保持 `SourceId_DumpHash.png` 文件名稳定，避免丢失原始来源线索。
- 新补 dump 进来后，先按 `NormId + ContentHash` 去重，再决定是否升格为 `Main` 或 `ColorAlt_P2`。

## Current Locked Set

### Face
| NormId | Main | P2 Alt | Size | Current Read |
| --- | --- | --- | --- | --- |
| `8926009` | `Main/Face/8926009_DB3BD774.png` | - | 64x64 | 侧眼/眉弓高光变体，尾 6 位和 `A926009` 对槽，但当前先按独立 NormId 锁入，精确挂接待 UV 对照 |
| `A0D4008` | `Main/Face/1A0D4008_1C1C23BC.png` | - | 32x64 | 耳朵侧面贴图，具体左右耳挂接待模型/UV 对照 |
| `A906009` | `Main/Face/1A906009_995D71F.png` | - | 64x64 | 侧脸嘴唇/口部贴图，来自 P1/P2 侧面对称七动作 dump，具体朝向待模型/UV 对照 |
| `A926009` | `Main/Face/1A926009_D90EE8A8.png` | - | 64x64 | 侧脸眼睛/眼睑贴图，来自 P1/P2 侧面对称七动作 dump，具体朝向待模型/UV 对照 |
| `E884008` | `Main/Face/E884008_143B065B.png` | - | 32x64 | 与 `A0D4008` 内容一致的耳朵贴图重复槽位，先保留 NormId 线索 |
| `9104012` | `Main/Face/S1_Intro_19104012_A8276D0E.png` | `ColorAlt_P2/Face/P2_9104012_8D904D01.png` | 128x128 | 正脸/脸部主贴图 |

### Hair
| NormId | Main | P2 Alt | Size | Current Read |
| --- | --- | --- | --- | --- |
| `8106013` | `Main/Hair/S1_Intro_18106013_EF10EDC5.png` | `ColorAlt_P2/Hair/P2_8106013_C9A09A3B.png` | 256x128 | 刘海/前发片 |
| `9144012` | `Main/Hair/S1_Intro_19144012_CBAC6FE1.png` | `ColorAlt_P2/Hair/P2_9144012_4D731AE8.png` | 128x128 | 侧发/肩侧发片 |
| `B044012` | `Main/Hair/S3_SideAtk_1B044012_E377B60D.png` | - | 128x128 | 大束侧发或马尾发片，精确挂接点待模型/UV 对照 |
| `C00600A` | `Main/Hair/C00600A_C582F84.png` | - | 128x64 | 黑色侧后发束/发梢块，和 `D00600A` 形状连续，疑似另一层背发或偏移角度发束 |
| `C80600A` | `Main/Hair/C80600A_79838537.png` | - | 128x64 | 黑色细碎发束/发梢块，疑似背侧或侧后发 |
| `D00600A` | `Main/Hair/D00600A_7145C309.png` | - | 128x64 | 黑色细碎发束/发梢块，疑似另一侧背发 |
| `E84600A` | `Main/Hair/1E84600A_D2FAD9E9.png` | - | 128x64 | 黑色弧形发束块，虽然尾 6 位和 `B84600A` 重合，但视觉上更像发束而不是花边饰件，先归入 Hair |

### Body / Clothes
| NormId | Main | P2 Alt | Size | Current Read |
| --- | --- | --- | --- | --- |
| `8086012` | `Main/Body_Clothes/S1_Intro_18086012_57325629.png` | - | 128x128 | 裙摆/布料花边块 |
| `80C6012` | `Main/Body_Clothes/S1_Intro_180C6012_2AADE22B.png` | - | 128x128 | 花边布料块 |
| `90C6012` | `Main/Body_Clothes/S1_Intro_190C6012_70195C43.png` | - | 128x128 | 布料褶皱 + 花边块 |
| `A024011` | `Main/Body_Clothes/1A024011_69BEAF41.png` | - | 64x128 | 竖向衣身/腰侧条带，精确部位待 UV 对照 |
| `A044011` | `Main/Body_Clothes/1A044011_361B28F.png` | - | 64x128 | 竖向衣身条带，精确部位待 UV 对照 |
| `A064011` | `Main/Body_Clothes/1A064011_902BB083.png` | - | 64x128 | 竖向衣身边缘块，精确部位待 UV 对照 |
| `A084012` | `Main/Body_Clothes/A084012_A91CC84B.png` | - | 128x128 | 躯干/衣身曲面过渡块；本批来源主要是背面站立，具体前后挂接待 UV 对照 |
| `B004011` | `Main/Body_Clothes/1B004011_A7FE080B.png` | - | 64x128 | 竖向衣身边缘块，精确部位待 UV 对照 |
| `B024011` | `Main/Body_Clothes/1B024011_FC9E8F47.png` | - | 64x128 | 侧腰/腰带边缘块，精确部位待 UV 对照 |
| `B0C4011` | `Main/Body_Clothes/1B0C4011_D7F2316B.png` | - | 64x128 | 侧身上衣/躯干面片，带扣件高光边，来自 P1/P2 侧面对称七动作 dump，精确挂接待 UV 对照 |
| `B084012` | `Main/Body_Clothes/S3_SideAtk_1B084012_91377994.png` | - | 128x128 | 衣身扣件/上身结构块，精确部位待 UV 对照 |
| `B144012` | `Main/Body_Clothes/S1_Intro_B144012_30C584D6.png` | - | 128x128 | 上身高光块，精确部位待 UV 对照 |
| `C004011` | `Main/Body_Clothes/1C004011_3E62E965.png` | - | 64x128 | 竖向衣身条带，精确部位待 UV 对照 |
| `C024011` | `Main/Body_Clothes/1C024011_646971D7.png` | - | 64x128 | 腰带/衣身连接块，精确部位待 UV 对照 |
| `C054010` | `Main/Body_Clothes/1C054010_E2EB3C6D.png` | - | 32x128 | 细长花边/链条状竖条装饰件，来自 P1/P2 侧面对称七动作 dump，疑似侧身边缘或腰侧挂件 |
| `C084012` | `Main/Body_Clothes/1C084012_92ED9642.png` | `ColorAlt_P2/Body_Clothes/C084012_F753BC1F.png` | 128x128 | 躯干下段/衣身曲面块；`ColorAlt_P2` 为同槽位灰度变体，具体前后挂接待 UV 对照 |
| `C0C6012` | `Main/Body_Clothes/1C0C6012_C202B3F.png` | - | 128x128 | V 形系带/扣件布料块，来自 P1/P2 侧面对称七动作 dump，疑似胸衣或侧腰结构件 |
| `C106012` | `Main/Body_Clothes/1C106012_3D6AB115.png` | - | 128x128 | 纵向扣件/系带细节块，疑似衣身中轴或侧边装饰 |
| `D004012` | `Main/Body_Clothes/S1_Intro_1D004012_AF325A14.png` | - | 128x128 | 背带/上身连接块 |
| `D044012` | `Main/Body_Clothes/S1_Intro_1D044012_53BBD44A.png` | - | 128x128 | 胸前衣身主块 |
| `D084012` | `Main/Body_Clothes/1D084012_F84F5770.png` | - | 128x128 | 躯干中线/腹背过渡块，具体前后挂接待 UV 对照 |
| `D0C6012` | `Main/Body_Clothes/S1_Intro_1D0C6012_230550FE.png` | - | 128x128 | 胸前下缘/衣身曲面块 |
| `E044012` | `Main/Body_Clothes/E044012_11D409BF.png` | - | 128x128 | 躯干大面积高光块；本批来源主要是背面站立/末段倒地，具体前后挂接待 UV 对照 |
| `F044012` | `Main/Body_Clothes/S3_SideAtk_1F044012_8775D2A4.png` | - | 128x128 | 上身/背侧大块，精确部位待 UV 对照 |

### Ornament
| NormId | Main | P2 Alt | Size | Current Read |
| --- | --- | --- | --- | --- |
| `B04600A` | `Main/Ornament/S1_Intro_1B04600A_B7E22954.png` | - | 128x64 | 花边饰件/装饰片 |
| `B84600A` | `Main/Ornament/1B84600A_3C0FDEC1.png` | - | 128x64 | 新补花边饰件块，形状接近衣摆/腰饰装饰片 |

## Coverage Gaps To Fill Next
- “背面站立 + 末段倒地”以及“P1 红 vs P2 蓝侧面对称七动作”这两批都已做第一轮入库复查；起身、胜利动作、INTRO 特写这些常态状态还没单独做系统化补 dump 复查。
- 鞋、手臂/手套、腿部/袜子、背侧衣身、头发背侧、耳侧/饰件挂接这些部位是否已经被当前 39 张主贴图完整覆盖，仍需模型/UV 对照后确认。
- 当前 `Body_Clothes` 里多张 64x128 竖条贴图已经锁入主集合，但精确挂接部位还没和模型 UV 一一对应，后续要补“NormId -> 部位名 -> 材质槽”映射表。
- 颜色还原/palette 提取后置；当前先按灰度结构贴图固定 canonical 文件集合和缺口清单。

## Current Batch Screening Notes
- `TEXCACHE_20260403_BackStandThenKnockdown`：筛出 20 张完全重复、178 张新 `NormId`、7 张同 `NormId` 新内容；已晋级进 canonical 集合 10 张 `Main` + 1 张 `ColorAlt_P2`，主要补躯干曲面块、耳朵、背/侧发束、额外花边饰件。
- `TEXCACHE_20260403_SideActionsSevenState`：Honey P1 红 vs P2 蓝、左右侧面对称、动作序列为站立/跳跃/蹲/倒地/受击飞起/受击漂浮/踢击；筛出 44 张完全重复、130 张新 `NormId`、0 张同 `NormId` 新内容；本轮先保守晋级 5 张 `Main`，对应侧脸眼嘴、侧身上衣面片、细长花边条、V 形系带块。
- `_IncomingDumpAuto/HoneyRun01`：多批自动归档里反复出现一类“尾 6 位和旧槽位一致，但完整 NormId 前缀不同”的候选；脚本已新增 `SameTail6NewPrefix` 状态和 `LooseSlotId/LooseSlotNormIds` 字段。这类匹配只能做候选线索，不能自动入库，例如 `8926009 -> A926009` 是高置信侧眼变体，但 `C106013 -> 8106013` 实际是 logo 杂图。
- 本轮从 `_IncomingDumpAuto/HoneyRun01` 保守新增 3 张 `Main`：`8926009` 侧眼变体、`C00600A` 黑色发束、`E84600A` 黑色弧形发束。
- 暂不收：`90C6012_30F6FF69.png` 这类明显文字/场景杂图，以及 `B004011_47D4838D.png`、`A044011_B48B8358.png`、`A064011_ECD4675C.png`、`A024011_B0D4126.png`、`B024011_C3C56DB9.png`、`F044012_5E8B928C.png` 这批同 `NormId` 但视觉内容和现有 Honey 主贴图差异过大的低置信候选；先留在 `_candidate_texcache_report.csv` 和 `_candidate_review/` 里备查，不直接污染主集合。
- 侧面对称七动作这一批里，`E84600A_3D0F93B2.png` / `1E84600A_D2FAD9E9.png`、`E004012_205FB8F5.png` / `1E004012_512F4E56.png`、`F004011_AA848AF.png` / `1F004011_489EFB8B.png`、`C066011_B9A9F794.png` / `1C066011_B9A9F794.png` 这些虽然形状像头发/衣片/饰件，但当前挂接位置和 P1/P2 关系都不够稳，先留在 `_candidate_texcache_sideactions_20260403.csv` 和 `_candidate_review_sideactions_20260403/` 里，不进主集合。

## Explicitly Deferred
- 破甲前/破甲后专用贴图 dump。
- 破损部件分件复原。
- 破甲状态机、破甲耐久、破甲视觉切换接入。

## Next Actions
- [ ] 下一轮手动 dump 优先补“起身、胜利动作、INTRO 特写/全身”和“鞋/腿/手臂更清楚的侧背视角”，继续保持不抓破甲。
- [ ] 新 dump 回来后，按 `NormId + ContentHash` 与 `_manifest.csv` 对照，决定新增/替换/归入 P2 变体。
- [ ] 建一版 `NormId -> 疑似身体部位 -> 材质槽 -> 覆盖状态` 映射表，优先解决 `Body_Clothes` 里 64x128 竖条块的挂接关系。
- [ ] 常态贴图集合稳定后，再单独开新文档重启破甲贴图研究。
