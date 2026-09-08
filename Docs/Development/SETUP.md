# 开发环境

## 环境模型

项目采用 **Mac-first、Windows 辅助**：

- Mac M4 是方向 C 的正式角色生产、Unity 日常验证和未来方向 B 开发环境；
- Windows 只在缺少原作证据时执行 Model 2/Noesis/Ninja Ripper 提取，并在方向 B 负责 Windows Player、DirectX、手柄和目标硬件验证；
- CUDA/Hunyuan3D 是可选历史实验，不属于 C0～C6 必需环境。

## 固定工具链

| 工具 | 版本基线 | 必需性 | 用途 |
| --- | --- | --- | --- |
| macOS | Apple Silicon / arm64 | 主环境必需 | 正式制作平台 |
| Python | 3.11+ | 必需 | 环境检查与跨平台工具 |
| Git | 2.30+ | 必需 | 文本和项目版本控制 |
| Git LFS | 3.0+ | 必需 | 原创大型美术资产 |
| FFmpeg | 6.0+ | 必需 | 视频与图像参考处理 |
| Blender | 4.5 LTS | 必需 | 建模、拓扑、UV、绑定、导出 |
| Unity | 6000.4.1f1 Apple Silicon | C6 前必需 | URP 角色验证和未来方向 B |
| PowerShell | 7+ | Windows 辅助 | Model 2 脚本 |
| NVIDIA CUDA | 未固定 | 可选 | 仅历史 Hunyuan 实验 |

Unity 或 Blender 的版本变化必须先更新 `Docs/DECISIONS.md`；不要由个人静默升级工作文件。

## Mac M4 设置

### 1. 安装基础工具

安装下列 Apple Silicon 原生版本：

- Git；
- Git LFS；
- Python 3.11 或更高版本；
- FFmpeg 6 或更高版本；
- Blender 4.5 LTS；
- Unity Hub 和 Unity `6000.4.1f1` Apple Silicon Editor。

Unity 只需桌面开发基础模块。方向 C 不需要 Android、iOS、WebGL 或 Windows 构建模块。

### 2. 初始化本地配置

从仓库根目录复制示例：

```bash
cp Tools/Environment/toolchain.example.toml Tools/Environment/toolchain.local.toml
```

只有工具不在 `PATH` 或标准应用目录时才修改 `[commands]`。本地文件被 Git 忽略，可以包含绝对路径；不要把个人路径写回示例配置。

### 3. 检查环境

```bash
python3 Tools/Environment/check_environment.py
```

只检查环境和小型 manifest，不下载、不安装、不修改配置、不递归扫描 `LocalData/`。输出只显示逻辑工具名和结果，不打印个人绝对路径。

结果含义：

- `PASS`：必需项满足基线；
- `WARN`：可选能力缺少，或安装存在但未验证精确版本；
- `FAIL`：方向 C 的必需项缺少或版本过低；
- 退出码 `0` 表示没有必需项失败，`1` 表示存在必需项失败，`2` 表示配置无法读取。

可指定其他配置：

```bash
python3 Tools/Environment/check_environment.py --config Tools/Environment/toolchain.example.toml
```

### 4. Git LFS 远端预检

在首次提交大型资产前单独完成：

1. 确认远端 LFS 容量、带宽和费用；
2. 确认 `git lfs lock/unlock` 可用；
3. 用无版权风险的小测试文件完成 push 和 fresh clone；
4. 验证另一工作区能够拉取并打开；
5. 删除测试资产并保留验证记录。

环境检查只验证 Git LFS 客户端，不会连接远端或创建 lock。

## Unity URP 工程初始化

当前 `Game/` 只有规则说明，不是 Unity 工程。为避免 Unity Hub 因非空目录再次创建嵌套工程：

1. 使用固定 Editor 在仓库外创建临时 URP 项目；
2. 关闭 Unity；
3. 只将 `Assets/`、`Packages/`、`ProjectSettings/` 移入 `Game/`；
4. 不复制 `Library/`、`Temp/`、`Logs/`、`UserSettings/` 和 IDE 文件；
5. 从 Hub 使用 `Add project from disk` 打开 `Game/`；
6. 确认 `ProjectSettings/ProjectVersion.txt` 为批准版本；
7. 将 `Game/README.md` 的规则保留在项目根目录；
8. 提交 Unity 文本配置和 `.meta`，二进制角色资产按 LFS 规则管理。

C6 前只创建 Honey 固定验证场景，不扩展战斗系统。

## Blender 设置

- 使用 Blender 4.5 LTS；
- 单位为 Metric，导出前应用 transform；
- 第三方插件必须登记版本、来源和许可证；
- 正式自动化优先使用 Blender 内置 Python；
- 外部纹理使用相对路径或打包前检查，禁止个人绝对路径进入主文件；
- `.blend` 编辑前使用 LFS lock。

## Windows 辅助环境

按需安装：

- PowerShell 7+；
- FFmpeg；
- Model 2 Emulator 与合法取得的本地游戏数据；
- Noesis/Ninja Ripper，仅在定向调查时使用；
- 与 Mac 相同版本的 Unity，用于后续 Windows 验证。

所有提取输入和输出进入 `LocalData/`。运行前阅读：

- `Tools/Extraction/Model2/README.md`
- `Tools/Windows/PowerShell-Runbook.md`
- `Tools/tool-manifest.csv`

Windows 环境缺失不会阻塞方向 C。方向 B 发布候选必须补 Windows Player、DirectX、手柄和性能验证。

## 干净环境复现检查

C0/C6 评审时按顺序执行：

1. fresh clone 仓库；
2. 安装固定版本工具，不恢复个人 cache；
3. 创建本地 TOML；
4. 运行环境检查；
5. 拉取 Git LFS 正式资产；
6. 打开 Blender 主文件，确认无丢失依赖；
7. 打开 `Game/`，确认 Unity 自动重建 cache；
8. 重复 Honey 导出和固定场景导入；
9. 对照 manifest 哈希和 QA。

## 常见问题

- **Mac 没有 CUDA**：正常；Hunyuan 不是必需项。
- **Windows 工具显示不可用**：在 Mac 上正常，不影响方向 C。
- **Unity 工程不存在**：C0 整理阶段允许；进入 C6 前必须初始化。
- **Blender/Unity 不在 PATH**：在本地 TOML 配置命令路径，或安装到标准应用目录。
- **Git LFS 已安装但远端未知**：客户端检查可通过，但大型资产仍不得上传，直到完成远端预检。
