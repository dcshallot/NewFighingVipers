## Research Note

### Meta
- Date: 2026-04-06
- Topic: Meshy 单图路线补充观察: 外部正面单体参考图虽然姿势不一致, 但生成效果明显更好
- Source Type: 本地 Meshy 结果观察
- Source Name: Meshy single-image test + external front-facing character reference
- Link:
- Local Path: `Reference/ResearchNotes/2026-04-06-meshy-single-front-reference-observation.md`
- Status: `done`
- Priority: `high`
- Owner: dish + Codex

### Goal
- 记录一条和 2026-04-05 Hunyuan3D-2mv 失败结论相对照的重要补充: 对 Honey 来说, 输入图质量和主体完整性可能比“和现有截图姿势一致”更关键。

### Context
- 2026-04-05 已确认: 当前 Honey 截图上, `Hunyuan3D-2mv` 的四视图白模和两视图白模都不可用, 可直接判定为失败路线。
- 本轮补充观察来自另一条输入策略: 使用网上找到的一张“正面、单体、主体完整”的角色参考图走 `Meshy` 单图生成。
- 这张图的人物姿势与当前手头所有 Honey 截图都不一致, 因而它并不是严格意义上的“同姿势配套参考”。

### Findings
- 即使姿势与现有截图全部不一致, 这张外部正面单体图在 `Meshy` 单图路线上的结果依然明显更好。
- 这说明对当前任务来说, `Meshy` 很可能更吃“单体清晰、轮廓完整、遮挡少、细节集中”的输入条件, 而不是强依赖与截图组姿势一致。
- 反过来看, 当前 Honey 截图虽然更贴近原角色, 但由于姿势大、信息分裂、视角间一致性差, 对生成器并不友好。
- 因此不能再把“姿势不一致”单独当成否掉外部参考图的充分理由; 至少在 `Meshy` 单图路线里, 它未必是主导问题。

### Evidence
- 本地相关 `Meshy` 产物目录:
  - `Assets/Generated/Meshy/CrimsonValkyrieBiped/`
- 对照失败路线:
  - `Assets/Generated/Hunyuan3D/HoneySelected4/Honey_white_mv.glb`
  - `Assets/Generated/Hunyuan3D/HoneySelectedLeftRight2View/Honey_white_mv.glb`

### Relevance to Prototype
- Input strategy:
  - 后续若继续试 `Meshy`, 应优先寻找“单体、正面、轮廓完整、背景干净”的强输入图, 而不是优先坚持使用当前这组动作截图。
- Model generation:
  - `Meshy` 单图在当前观察下, 至少表现出比 `Hunyuan3D-2mv` 两视图 / 四视图更高的可用性上限。
- Reference policy:
  - 可以接受“姿势不一致但主体表达强”的外部参考图进入实验池, 前提是明确它服务于建模质量验证, 不是用于严格还原动作。

### Risks / Gaps
- 当前只记录到结论和本地产物目录, 原始外部参考图的来源 URL / 本地归档路径尚未一并记下。
- 这条结论目前仍是“对当前 Honey 试验的经验判断”, 不是对所有角色或所有输入类型都成立的普遍规律。

### Decision
- Use / Maybe / Reject: `Use`
- Reason:
  - 这条观察直接改变后续输入筛选标准。
  - 对当前项目而言, 它比继续重复喂低质量截图更有行动价值。

### Next Action
- [ ] 若继续走 `Meshy`, 优先收集或制作更强的单图正面参考, 再做下一轮对照。
- [ ] 把本次使用的外部正面参考图源头补归档, 避免后续只剩生成结果、没有输入证据。
- [ ] 后续评估时, 单独区分“姿势还原度”与“模型可用度”, 不再把两者混成一个标准。

### Follow-up Files
- `Assets/Generated/Meshy/CrimsonValkyrieBiped/`
- `Reference/ResearchNotes/2026-04-05-hunyuan3d-2mv-four-view-two-view-failure.md`
- `Reference/ResearchNotes/2026-04-04-meshy-honey-unity-route.md`

### Notes
- 这条补充的关键不在于“网上图更像 Honey”, 而在于“即便姿势不一致, 只要输入图足够像一个完整、清晰、可解释的角色单体, `Meshy` 单图依然能给出更像样的结果”。
