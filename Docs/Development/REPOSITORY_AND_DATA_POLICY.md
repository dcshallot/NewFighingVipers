# 仓库与数据策略

## 四层数据

| 层 | 示例 | 存储 |
| --- | --- | --- |
| 项目事实 | 文档、manifest、脚本、小型评审图 | 普通 Git |
| 正式二进制 | 原创 `.blend/.fbx/.psd/.spp` | Git LFS |
| 本地／受限／可再生 | ROM、dump、视频、截图、AI 批量输出、cache | `LocalData/`，不进 Git/LFS |
| 外部原始 input | 用户保留的视频和图片 | storage key + 本地 TOML + manifest 哈希 |

小型归档评审 JPG 进入普通 Git；这与大型里程碑源资产使用 LFS 不冲突。

## Git 与 LFS

- 文档、CSV/TOML、源代码和 Unity YAML（未来重启时）使用普通 Git；
- `.blend`、`.fbx` 和大型原创纹理使用 LFS；不可合并源文件设为 lockable；
- ROM、原作媒体、第三方包、抓取数据和来源不明内容不得进入 LFS；
- Git LFS 不是备份。长期保存必须验证 push、fresh clone 和独立备份恢复；
- 当前 v005 尚未 commit/push，manifest 如实保留 `uncommitted` 与 `lfs-configured-not-pushed`。

## 路径规则

- 仓库内路径统一 POSIX 相对路径；
- 本机绝对路径只允许出现在被忽略的 `toolchain.local.toml`；
- `LocalData/` 是唯一默认写入根；脚本不得默认写 `Assets/`、`Resources/` 或 `Reference/Captures/`；
- 外部文件使用 `storage_key + relative_path`，不能把任何个人主目录绝对路径写入 manifest；
- 删除、移动、覆盖或联网必须在 tool manifest 声明，并要求显式参数。

## 外部数据

`vf-assets-input` 由本地 TOML 的 `external_source_root` 解析。仓库仅保存原文件名、大小和 SHA-256。换机器时映射新的根目录，不修改 manifest。

## 生命周期

- 工作版本可使用 `Honey_<Stage>_vNNN.blend`；
- 归档模型和评审图必须登记 SHA-256；
- 可再生 render、autosave、cache 和失败中间物及时清理；
- 已删除历史资产保留 ID、原哈希和 `deleted` availability；
- 进入正式制作前，必须建立 commit/tag、LFS push 与独立备份闭环。

## 备份与交接

1. 关闭 DCC，清理绝对路径和无用数据块；
2. 更新 manifest；
3. 验证 SHA-256 和 LFS 属性；
4. 获得用户授权后提交和推送；
5. 在第二个工作区 fresh clone；
6. 打开文件并重新校验；
7. 将不可再生源文件另存独立备份。

## 禁止事项

- 将外部受限 input 复制进 Git；
- 用 manifest 伪装不存在或未验证的文件；
- 将 AI 输出直接标记为原作证据或 game-ready；
- 在 archive profile 中要求安装大型 DCC；
- 历史脚本默认覆盖归档证据。
