## Unity Hub / Editor Installation Log

### Meta
- Date: 2026-04-03
- Topic: Unity Hub / Unity Editor 安装与 NewFighingVipers 仓库根目录工程初始化
- Source Type: Official documentation / local repo notes / assistant-user setup log
- Source Name: Unity Hub docs + Unity Support + `Assets/README.md`
- Link: https://docs.unity.com/hub/install-hub ; https://docs.unity.com/hub/add-editor ; https://support.unity.com/hc/en-us/articles/205637449-How-do-I-download-Unity- ; https://unity.com/releases/editor/whats-new/6000.4.1f1
- Local Path: `Assets/README.md`
- Status: `testing`
- Priority: `high`
- Owner: dish / Codex

### Goal
- 记录第一次安装 Unity Hub / Unity Editor 并把本仓库初始化成 Unity 工程的实际操作顺序、关键选择、踩坑风险和后续验证点。

### Context
- 这是第一次配置 Unity，本轮目标不是直接做角色/材质开发，而是先把 Unity 编辑器和工程结构搭起来。
- `Assets/README.md` 明确要求 Unity 工程直接建在仓库根目录 `C:\Users\dish\projects\NewFighingVipers`，不要再套一层 `UnityProject/`。
- 当前仓库已有 `Assets/`，但还没有 `ProjectSettings/ProjectVersion.txt` 和 `Packages/`，说明 Unity 工程尚未完成初始化。

### Findings
- Unity Hub 安装入口应以官方文档为准：
  - `https://docs.unity.com/hub/install-hub`
  - Windows/macOS 安装细节页：`https://docs.unity.com/hub/install-hub-win-mac`
- Unity Editor 应通过 Unity Hub 的 `Installs -> Install Editor` 安装：
  - `https://docs.unity.com/hub/add-editor`
- 官方文档对 Editor 版本选择的口径是优先用 `Official releases` 里的 LTS 版本作为稳定项目基础；`Pre-releases` 不是当前首选。
- Unity Support 的下载说明补充了一个实操点：先有 Unity ID，Hub 登录后再装 Editor；如果安装失败，可以先取消可选模块，只装 Editor 主体，模块后面再补。
- 对当前项目的初始工程模板，先选 `3D (Core)` 更适合后续做最小角色/材质测试场景。
- 当前不建议一开始就勾 Android/iOS/WebGL 等额外平台模块，先把 Windows 本地编辑器和基础工程跑起来，减少首次安装变量。
- 如果 Unity Hub 因为“目标目录已存在/非空”不允许直接在仓库根目录创建项目，不要自行改成 `UnityProject/` 子目录；应先暂停并记录 Hub 的原始提示，再决定是走“Add/open existing folder”还是其他安全初始化方案。
- 本次实际装到的 Editor 版本是 `6000.4.1f1`，`ProjectVersion.txt` 中对应 `m_EditorVersionWithRevision: 6000.4.1f1 (8535861f39e1)`；Unity 官方 release 页面显示该版本发布日期为 2026-03-18。
- 本次实际选的模板是 `High Definition 3D`，而不是前面建议的 `3D (Core)`；这意味着初始工程会带 HDRP 相关资源和设置，后续如果只是做角色材质/UV 验证，可能会比 Built-in/URP 模板更重。
- 这次 Hub 默认在仓库根目录下创建了嵌套目录 `My project/`，而不是直接把 repo 根目录本身初始化成 Unity 工程；该目录下已有 `Assets/`、`Packages/`、`ProjectSettings/`、`Library/`、`Logs/`、`Temp/`、`UserSettings/`、`.vscode/`、`*.csproj`、`*.slnx`，递归文件数约 `42509`。
- 为避免把 Unity 缓存和误建的嵌套工程整包带进 Git，已先在 repo 根目录 `.gitignore` 增加 Unity 生成物规则，并临时忽略 `/My project/`。

### Evidence
- Screenshots: 待补。建议安装过程中遇到关键选项页或报错页时截图留存。
- Video captures: N/A
- Extracted files: 待 Unity 初始化后检查是否生成 `ProjectSettings/ProjectVersion.txt`、`Packages/manifest.json`、`Assets/Scenes/` 等文件/目录。
- Tool output:
  - `Get-Content Assets\README.md -Encoding UTF8` 已确认工程根目录约束和建议目录结构。
  - `Get-Content ProjectSettings\ProjectVersion.txt` 当前报 `Cannot find path`，说明工程还没初始化。
- Comparison notes:
  - 本地 `Assets/README.md` 的目录约束与 Unity Hub 默认“新建项目时创建新目录”习惯可能冲突，所以这一步要特别记录 Hub 的实际行为。

### Setup Plan / Decisions
- 第 1 步：安装 Unity Hub，使用 Unity ID 登录。
- 第 2 步：在 Hub 里安装一个 LTS 版 Unity Editor，优先只装 Editor 主体，暂不加移动端/主机平台模块。
- 第 3 步：尝试把 `C:\Users\dish\projects\NewFighingVipers` 直接初始化为 Unity 工程，模板先用 `3D (Core)`。
- 第 4 步：工程打开后按 `Assets/README.md` 建立初始目录：
  - `Assets/Art/Characters/Honey/`
  - `Assets/Art/Materials/`
  - `Assets/Scenes/`
  - `Assets/Scripts/`
- 第 5 步：搭一个最小测试场景，先只放地面、相机、灯光、Honey 测试挂点。

### Interaction Log
- 2026-04-03：用户提出“根据 `Assets\README.md` 先教我配置 Unity，我从来没搞过”。
- 2026-04-03：Codex 读取 `Assets/README.md` 和仓库根目录，确认 Unity 工程应建在 repo 根目录，且当前缺少 `ProjectSettings/ProjectVersion.txt`，说明还未初始化 Unity 工程。
- 2026-04-03：Codex 参考 Unity 官方文档，给出首次安装顺序：先装 Unity Hub，再通过 Hub 安装 LTS Editor，再用 `3D (Core)` 模板初始化工程，并提醒不要一开始乱勾 Android/iOS 模块。
- 2026-04-03：用户要求把安装交互记录参考相关文档写入 `ResearchNotes`，并表示现在开始安装。
- 2026-04-03：用户实际安装了 Unity `6000.4.1f1`，参考 release 页面 `https://unity.com/releases/editor/whats-new/6000.4.1f1#notes`，并在新建项目时选择了 `High Definition 3D` 模板。
- 2026-04-03：用户反馈工程目录还没按预期建立，但 Git 已出现巨量新增文件。Codex 检查后确认 Unity Hub 生成了嵌套 `My project/` 工程目录，且该目录下有大量 `Library/`/`Temp/` 等缓存文件；随后先更新 repo 根目录 `.gitignore` 屏蔽 Unity 生成物和 `/My project/`。

### Relevance to Prototype
- Gameplay: 先满足后续最小测试场景和角色控制脚本开发前置条件。
- Animation: 先不涉及。
- Art / Model: 后续 Honey 模型和材质导入路径要固定在 `Assets/Art/Characters/Honey/`。
- Texture / Material: 后续假彩色 UV 调试材质测试依赖 Unity 工程先建好。
- Audio: 先不涉及。
- Extraction pipeline: 本轮只负责把 Unity 工作区准备好，方便后续把 `Reference/OriginalAssets/...` 的研究结果接入编辑器验证。
- UI / Presentation: 先不涉及。

### Risks / Gaps
- Unity Hub 对“在已有非空目录里直接新建项目”的处理方式还没实测，可能会卡在工程初始化这一步。
- 虽然当前已确认 Editor 版本是 `6000.4.1f1`，但还没验证这个版本 + HDRP 模板是否适合后续 Model 2 角色材质/UV 调试；Unity 6000.4.1f1 官方 release notes 里还列有一条与 URP/HDRP 模板版本相关的已知问题 `UUM-137426`，后续若模板资源异常需要回查。
- 当前 Hub 已经生成了嵌套 `My project/`，这和 `Assets/README.md` 的“Unity 工程直接建在 repo 根目录”要求不一致；后续需要决定是重建工程、迁移 `My project/` 内的有效项目文件，还是用 Hub 的其他入口重新绑定仓库根目录。
- 还未验证这台机器是否有 Unity license / firewall / file-system permission 相关弹窗或拦截。
- 仓库根目录仍未生成 `ProjectSettings/` 和 `Packages/`，所以按当前 repo 结构要求来说，根目录工程仍未完成初始化；目前生成的只是嵌套 `My project/` 下的一套 Unity 工程。

### Decision
- Use / Maybe / Reject: Use
- Reason: 先按 Unity 官方 Hub 安装流程 + 本仓库 `Assets/README.md` 的根目录约束执行，边安装边记录实际界面和异常，再根据 Hub 对非空目录的行为决定初始化方式。

### Next Action
- [ ] 用户先完成 Unity Hub 安装和登录，并回报是否遇到账号、网络、防火墙或权限弹窗。
- [x] 用户在 Hub 里开始安装 LTS Editor，并回报具体版本号与是否勾选了额外模块。
- [ ] 如果 Hub 在仓库根目录创建项目时报“目录非空”或类似错误，先截图/抄原文，再更新本笔记并调整初始化方案。
- [ ] 决定如何处理当前误建的 `My project/`：如果确认不要这层嵌套，优先只迁移必要的 `Packages/`、`ProjectSettings/`、`Assets` 内容，不要把 `Library/`、`Temp/`、`Logs/` 一起搬回 repo 根目录。

### Follow-up Files
- `Assets/README.md`
- `ProjectSettings/ProjectVersion.txt`（待生成）
- `Packages/manifest.json`（待生成）

### Notes
- 这份笔记会随着用户实际安装反馈继续追加，优先记录“点了什么、看到什么提示、为什么这么选、最后生成了哪些 Unity 工程文件”。
