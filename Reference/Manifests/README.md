# Manifest Schema v2

返回 [`Reference/README.md`](../README.md)。

本目录是来源、选帧、资产和工具元数据的机器可读事实层。所有 CSV 使用 UTF-8、LF、首列 `schema_version=2`，ID 在各自命名空间内唯一。

## 通用规则

- 路径一律使用相对仓库根或相对逻辑 storage key 的 POSIX 路径，不写个人绝对路径。
- SHA-256 非空时必须为 64 位小写十六进制。
- `availability` 枚举：`local`、`external`、`missing`、`deleted`、`not-applicable`。
- `local` 表示当前仓库中存在并应校验；`external` 表示由本机配置映射；`missing/deleted` 是历史事实，不应伪装成错误路径。
- URL 只记录来源，不在离线 doctor 中联网验证。
- 历史 ID 和哈希不得重编号或改写。

## Storage keys

| storage key | 含义 | 解析方式 |
| --- | --- | --- |
| `repo` | 仓库内文件 | 相对仓库根 |
| `local-data` | 被忽略的本地数据 | 相对 `LocalData/` |
| `vf-assets-input` | 用户保留的外部原始 input | 相对本地 TOML 的 `external_source_root` |
| `web` | 仅 URL 来源 | 不解析本地路径 |
| `unknown` | 历史来源未知 | 不解析 |

## `honey-reference-manifest.csv`

`source_id` 是来源包主键。`parent_source_id` 可表示来源派生关系。`storage_key + relative_path` 描述位置；`availability` 描述是否可取。

## `honey-intake-2026-09-09.csv`

`intake_id` 是单文件主键，`parent_source_id` 必须指向 reference manifest。`original_name` 保留原文件名；`relative_path` 用于从外部数据根恢复。

## `honey-p1-selected-views.csv`

`reference_id` 是选帧记录主键；`parent_source_id` 指向 reference manifest；`intake_id` 指向 intake manifest。`selection_status` 与 `availability` 分开：一张图可以仍是 `selected`，但只在外部存储中可用。

## `honey-asset-manifest.csv`

分别记录：

- `source_path/source_sha256/source_availability`
- `review_artifact_path/review_sha256/review_availability`
- `approved_export_path/approved_export_sha256/export_availability`

评审图不再冒充批准导出。归档删除的源文件保留原哈希和 `deleted` 状态。

## `Tools/tool-manifest.csv`

工具清单使用同一 schema 版本。`profiles` 可为逗号分隔的 profile；`archive_only`、`destructive`、`network_access` 必须为 `true/false`。工具状态只允许 `stable/experimental/rejected/reference`。

## 验证

```bash
python3 Tools/Environment/check_environment.py --profile archive
python3 Tools/Environment/check_environment.py --profile archive --json
```

如果配置了 `external_source_root`，doctor 会按 intake 的文件名、大小和 SHA-256 验证外部 input；默认 archive 检查不扫描大型外部目录。
