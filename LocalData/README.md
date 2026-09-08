# LocalData

此目录保存不会进入 Git 或 Git LFS 的本地内容。除本说明外，目录内所有文件默认被忽略。

建议结构：

```text
Raw/          ROM、原始下载、Model 2 dump
Captures/     截图、视频和抽帧
Generated/    AI 输出、临时 bake 和批量试验
ThirdParty/   模拟器、Noesis、Ninja Ripper、第三方 checkout
Cache/        模型权重、下载缓存、转换缓存
Autosave/     DCC 自动保存和恢复文件
```

## 规则

- 不存放唯一一份正式原创主文件；正式主文件进入 `ArtSource/` 并另行备份。
- 原始资料使用逻辑路径和 SHA-256 登记在 `Reference/Manifests/`。
- 不在公开文档中记录密钥、账号、真实备份位置或不必要的个人绝对路径。
- 从本目录晋级的任何原创派生资产必须经过来源审核、可编辑性检查和 QA。
- 删除前先确认文件可重新获取或已有独立备份。
