# 版本控制规范

## 仓库职责

本仓库保存当前文档、原创资产、工具和未来 `Game/` Unity 工程。受限原始资料、可再生中间物和第三方依赖只保存在 `LocalData/`。

## 普通 Git

应提交：

- `Docs/`、`README.md`；
- `Reference/Manifests/` 和 `Reference/ResearchNotes/`；
- 自写脚本与示例配置；
- Unity `Assets/` 中的 YAML、代码和所有必要 `.meta`；
- Unity `Packages/manifest.json`、`packages-lock.json` 和 `ProjectSettings/`；
- 小型原创文本或配置资产。

不得提交：

- 密钥、个人绝对路径和 `toolchain.local.toml`；
- Unity cache、IDE 文件和构建输出；
- ROM、dump、原作媒体、第三方包和未审核 AI 输出。

## Git LFS

`.gitattributes` 对 `ArtSource/` 和 `Game/Assets/` 中的正式二进制资产启用 LFS。执行大型资产提交前：

1. 安装并初始化 Git LFS；
2. 确认远端支持 LFS 和 locking；
3. 检查容量、带宽和计费；
4. 用小型测试资产完成 push、fresh clone、lock、unlock；
5. 测试失败前不得上传正式大型资产。

## 分支与提交

- `master` 保持可读取、清单一致和文档链接有效；
- 每个里程碑或明确修复使用独立短分支；
- 不在多个分支并行编辑同一个不可合并文件；
- 提交应同时包含资产变化、manifest 更新和必要评审记录；
- 不提交只有导出没有源文件、或只有源文件没有 manifest 的正式里程碑。

## Tags

建议里程碑 tag：

```text
honey-c2-blockout-v1
honey-c3-retopo-uv-v1
honey-c4-material-v1
honey-c5-rig-v1
honey-c6-game-ready-v1
```

Tag 只在对应 QA 通过、LFS object 已推送并完成独立备份后创建。

## Unity 规则

- 项目根目录为 `Game/`；
- `Game/Assets/`、`Game/Packages/`、`Game/ProjectSettings/` 应纳入版本控制；
- `Library/`、`Temp/`、`Logs/`、`UserSettings/` 和构建输出忽略；
- 必须保留 `.meta`；不要在文件系统外移动已进入 Unity 的资产；
- 稳定导出保持固定路径和文件名。

## 验证

每个里程碑至少检查：

- `git status` 不包含受限或缓存内容；
- `git lfs ls-files` 只列正式原创二进制；
- fresh clone 能拉取所需 LFS object；
- Unity 工程不依赖仓库外绝对路径；
- manifest 中的哈希与当前文件一致。
