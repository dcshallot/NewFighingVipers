## Research Note

### Meta
- Date: 2026-04-05
- Topic: Hunyuan3D-2mv 对 Honey 四视图/双侧视图白模实验失败归档
- Source Type: 本地生成实验记录
- Source Name: `Tools/Generation/Hunyuan3D/GenerateHoneyMvGlb.py` + 本地输入图
- Link:
- Local Path: `Reference/ResearchNotes/2026-04-05-hunyuan3d-2mv-four-view-two-view-failure.md`
- Status: `done`
- Priority: `high`
- Owner: dish + Codex

### Goal
- 记录 2026-04-05 这轮 Hunyuan3D-2mv 白模实验的实际结论，避免重复投入时间到同类输入。

### Context
- 本轮先扩展了本地包装脚本，使其支持：
  - `front/left/back/right` 四视图输入
  - 仅 `left/right` 双视图输入
- 目标不是验证脚本能不能跑通，而是验证结果是否达到“可继续修”的最低质量门槛。

### Findings
- 四视图版本跑通了，但结果不可用。
  - 输出路径：`Assets/Generated/Hunyuan3D/HoneySelected4/Honey_white_mv.glb`
  - Manifest：`Assets/Generated/Hunyuan3D/HoneySelected4/Honey_mv_generation_manifest.json`
  - 耗时约 `251.93s`
  - 失败原因不是单纯崩溃，而是生成质量太差，形体失真严重。
- 双视图版本也跑通了，但结果同样不可用。
  - 输出路径：`Assets/Generated/Hunyuan3D/HoneySelectedLeftRight2View/Honey_white_mv.glb`
  - Manifest：`Assets/Generated/Hunyuan3D/HoneySelectedLeftRight2View/Honey_mv_generation_manifest.json`
  - 耗时约 `188.57s`
  - 即使只保留一致性较高的 `left/right` 两张图，白模仍然达不到可接受水平。
- 结论可以直接定性为：
  - 这两条结果都不行。
  - 质量属于“丧尸水平”，不值得进入 Blender 清理、重拓扑或贴图阶段。

### Evidence
- 输入图：
  - `Reference/Captures/Honey/TurnaroundSelected4/left.png`
  - `Reference/Captures/Honey/TurnaroundSelected4/right.png`
  - 之前四视图尝试还包含 `front.png` / `back.png`
- 生成输出：
  - `Assets/Generated/Hunyuan3D/HoneySelected4/Honey_white_mv.glb`
  - `Assets/Generated/Hunyuan3D/HoneySelectedLeftRight2View/Honey_white_mv.glb`
- 预处理视图：
  - `Assets/Generated/Hunyuan3D/HoneySelected4/preprocessed_views/`
  - `Assets/Generated/Hunyuan3D/HoneySelectedLeftRight2View/preprocessed_views/`

### Relevance to Prototype
- Art / Model:
  - 当前这类 AI 多视图白模结果不能作为 Honey 主模型路线。
- Texture / Material:
  - 白模都站不住，后续贴图没有继续投入价值。
- Extraction pipeline:
  - 这条路线应降级为“已验证失败”的分支，不再反复尝试同类图组。

### Risks / Gaps
- 本结论针对的是当前这批 Honey 输入图和当前 Hunyuan3D-2mv 路线，不等于“任何角色、任何输入都必定失败”。
- 但对当前项目来说，已经足够说明它不是值得继续押注的主线方案。

### Decision
- Use / Maybe / Reject: `Reject`
- Reason:
  - 四视图不行。
  - 双视图也不行。
  - 两条结果都已经低于“值得继续修”的最低门槛。

### Next Action
- [ ] 不再继续用同类 Honey 截图重复喂 `Hunyuan3D-2mv` 试白模。
- [ ] 把重心转回更可控的路线：原始资源研究、Meshy 对照、或手工/半手工建模路径。

### Follow-up Files
- `Tools/Generation/Hunyuan3D/GenerateHoneyMvGlb.py`
- `Tools/Generation/Hunyuan3D/GenerateHoneyMvGlb.ps1`
- `Assets/Generated/Hunyuan3D/HoneySelected4/Honey_white_mv.glb`
- `Assets/Generated/Hunyuan3D/HoneySelectedLeftRight2View/Honey_white_mv.glb`

### Notes
- 本次归档的核心不是“技术上跑不起来”，而是“跑得出来，但成品差到应直接判死”。
