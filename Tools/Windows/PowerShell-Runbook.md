# PowerShell / Windows Command Runbook

## Scope
这份文档只记录“对后续整个项目都有复用价值”的 Windows / PowerShell 调用规则。

不放在这里的内容：
- Model 2 Emulator 的具体菜单 ID、ROM 行为、Lua 脚本加载问题
- 某一次临时实验脚本的失败细节

这些专项内容应该留在 `Reference/ResearchNotes/` 对应研究笔记里。

## 1. 路径和文件操作

### 应该怎么做
- 优先使用 `-LiteralPath` 处理本地路径，避免文件名里的 `[`、`]`、`*` 等字符被当成通配符。
- 递归删除/清空目录前，先把目标路径 `Resolve-Path` + `GetFullPath()`，再检查它是否仍在项目工作区下面。
- 清空“后续还要继续写入的输出目录”时，优先删目录内容，保留目录壳。
- 统计目录内容时，用 `Get-ChildItem -Recurse -File` + `Measure-Object`，不要只看顶层文件。

### 不应该怎么做
- 不要对未校验过的拼接路径直接 `Remove-Item -Recurse -Force`。
- 不要跨 shell 组合删除命令，例如先用 PowerShell 枚举路径，再拼字符串交给 `cmd /c` 删除。
- 不要误删原始输入包；中间产物目录和原始资源包应该分开命名、分开存放。

### 推荐模板
```powershell
$ErrorActionPreference = 'Stop'
$workspaceRoot = [System.IO.Path]::GetFullPath('C:\Users\dish\projects\NewFighingVipers\')
$target = 'C:\Users\dish\projects\NewFighingVipers\Resources\M2emulator\TEXCACHE'

$resolved = [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $target).Path)
if (-not $resolved.StartsWith($workspaceRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to operate outside workspace: $resolved"
}

Get-ChildItem -LiteralPath $resolved -Force | Remove-Item -Recurse -Force
```

## 2. 文本编码

### 应该怎么做
- 读取包含中文的 Markdown / 文本文件时，显式指定 `-Encoding UTF8`。
- 写项目文档时，统一按 UTF-8 处理。

### 不应该怎么做
- 不要直接依赖 PowerShell 默认编码去读中文文档；在本机上已经出现过 `Get-Content` 输出乱码，但 `Get-Content -Encoding UTF8` 正常。

### 推荐模板
```powershell
Get-Content -Path 'C:\path\file.md' -Encoding UTF8 -Raw
Get-Content -Path 'C:\path\file.md' -Encoding UTF8 -Tail 40
```

## 3. PowerShell 管道和对象输出

### 应该怎么做
- 如果要把 `foreach` 生成的对象继续接管道，外面包一层脚本块：`& { foreach (...) { ... } } | Format-Table`。
- 想保留结构化数据时，优先输出 `[PSCustomObject]`，最后再 `Format-Table` / `Format-List`。
- 路径很长或列很多时，用 `Format-List` 或 `Select-Object -ExpandProperty FullName`，不要只看 `Format-Table` 默认截断后的显示。

### 不应该怎么做
- 不要直接写 `foreach (...) { ... } | Format-Table`；PowerShell 里这会报 `An empty pipe element is not allowed.`。
- 不要把 `Format-Table` 的视觉输出当成后续可继续处理的数据源；格式化应该尽量放在命令末尾。

### 推荐模板
```powershell
& {
    foreach ($file in Get-ChildItem -LiteralPath 'C:\path' -File) {
        [PSCustomObject]@{
            Name = $file.Name
            Length = $file.Length
        }
    }
} | Format-Table -AutoSize
```

## 4. GUI 程序和副作用验证

### 应该怎么做
- 调用 GUI 程序、窗口消息、模拟器菜单命令后，不要只看“命令返回成功”，还要立刻检查目标副作用是否真的发生。
- 如果目标是导出文件，就直接检查输出目录里的新增文件数、时间戳、文件名。
- 对这类 GUI 自动化，先写最小可验证脚本，再逐步扩大动作范围。

### 不应该怎么做
- 不要把 `PostMessage` / `SendMessageTimeout` 成功返回，直接等同于“应用内部功能真的执行成功”。
- 不要在没有副作用验证的情况下，把 GUI 消息注入脚本纳入正式流程。

### 本项目里的例子
- 对 Model 2 Emulator 发 `WM_COMMAND 40025` 时，消息调用层面可以成功返回，但 `TEXCACHE` 没有新 PNG 生成。
- 结论是：这类 GUI 注入脚本最多算“实验线索”，不能直接升格成可用 pipeline。

## 5. 硬件/系统状态查询

### 应该怎么做
- 接手柄、USB 设备这类硬件时，用 `Get-PnpDevice` / `Get-CimInstance Win32_PnPEntity` 验证 Windows 是否真的识别到设备。
- 同时检查应用依赖的 DLL 是否存在，例如 XInput 相关 DLL。

### 不应该怎么做
- 不要只凭“设备灯亮了/插上了”判断模拟器一定能读到输入。
- 不要只改应用配置，不查系统层是否已识别设备。

### 推荐模板
```powershell
Get-PnpDevice -PresentOnly |
    Where-Object {
        $_.FriendlyName -match 'Xbox|Controller|Gamepad|XInput' -or
        $_.InstanceId -match 'VID_045E'
    } |
    Select-Object Status,Class,FriendlyName,InstanceId |
    Format-Table -AutoSize

Get-ChildItem 'C:\Windows\System32\xinput*.dll','C:\Windows\SysWOW64\xinput*.dll' |
    Select-Object FullName,Length |
    Format-Table -AutoSize
```

## 6. 实验脚本分层

### 应该怎么做
- 把“一次性验证脚本”和“正式可复用工具脚本”分开。
- 实验脚本如果已经证明不可用，要么删除，要么在研究笔记里明确标注“为什么失败、不要再照这个方向重复试错”。
- 正式工具脚本才放到稳定目录，并补用途说明、输入输出说明、失败条件说明。

### 不应该怎么做
- 不要把失败实验脚本悄悄留在工作目录里，却没有任何文档说明；后面很容易被误当成可用工具继续踩坑。
- 不要把“对某个模拟器版本刚好有效”的脚本，直接写成项目通用规则。

## 7. 这份 Runbook 和研究笔记怎么分工

### 放在本 Runbook 的内容
- PowerShell 语法/编码/路径安全规则
- Windows 设备查询方式
- GUI 命令调用后必须验证副作用这一类通用原则

### 放在 `Reference/ResearchNotes` 的内容
- Model 2 Emulator 的菜单 bug、XInput 绕法、Lua 脚本加载问题
- `fvipers.zip` ROM 分区判断
- `Dump texture cache` 对 Honey 贴图提取的实际表现

### 当前建议
- 以后如果是“所有项目都会复用的 Windows 命令规范”，补到本文件。
- 如果是“Fighting Vipers / Model 2 这条研究线特有的坑和判断”，补到对应研究笔记，不要混进本文件。

## 8. PNG / 图像批处理脚本

### 应该怎么做
- PowerShell 里只要用到 `[System.Drawing.Image]`、`[System.Drawing.Bitmap]`、`[System.Drawing.Graphics]`，脚本开头先显式 `Add-Type -AssemblyName System.Drawing`。
- 先拿 1 张图或 1 页 contact sheet 做最小验证，确认尺寸读取、拼图、`.Save()` 和输出路径都真的成功，再扩到全量批处理。
- `Image.FromFile(...)` 前先 `Test-Path -LiteralPath`，缺文件就明确报错或跳过，不要让后续 `DrawImage()` 继续吃到旧的 `$img` 对象/空对象。
- `.Save(...)` 后立刻 `Get-Item` / `Test-Path` 验证输出文件真实存在，不要只看 `Write-Host` 打印了路径。
- 分页处理数组时，优先用 `Select-Object -Skip/-First`；如果确实要按索引切片，先把输入包成 `@(...)` 并自己校验边界。
- 生成 sheet 时，把文件名、尺寸、分类状态直接画到图上，后面人工筛图会比“图片和列表分开对照”更稳。

### 不应该怎么做
- 不要在没 `Add-Type -AssemblyName System.Drawing` 的情况下直接调用 `[System.Drawing.Image]::FromFile(...)`；PowerShell 会报 `Unable to find type [System.Drawing.Image]`。
- 不要用可能越界的 `$items[$i..([Math]::Min(...))]` 直接分页；当集合为空、只有 1 个元素、或区间边界不对时，后续很容易退化成空对象/标量并触发一串难看的空引用错误。
- 不要把“脚本打印了输出路径”当成“文件一定保存成功”；这次 contact sheet 脚本就出现过路径打印了，但目录里实际没有 PNG。
- 不要在 `FromFile()` 失败后继续对 `$img` / `$g` / `$bmp` 调 `DrawImage()`、`DrawString()`、`Dispose()`；要么提前 `throw`，要么每轮都重新初始化并做空值保护。

### 推荐模板
```powershell
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'

$files = @(Get-ChildItem -LiteralPath 'C:\path\input' -File -Filter '*.png' | Sort-Object Name)
$pageSize = 30
$page = $files | Select-Object -Skip 0 -First $pageSize

$tileW = 180
$tileH = 190
$cols = 5
$rows = [int][Math]::Max(1, [Math]::Ceiling($page.Count / [double]$cols))

$bmp = [System.Drawing.Bitmap]::new([int]($tileW * $cols), [int]($tileH * $rows))
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::Black)

foreach ($file in $page) {
    if (-not (Test-Path -LiteralPath $file.FullName)) {
        throw "Missing image: $($file.FullName)"
    }

    $img = [System.Drawing.Image]::FromFile($file.FullName)
    try {
        # Draw image and labels here.
    } finally {
        $img.Dispose()
    }
}

$outPath = 'C:\path\output\sheet.png'
$bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()

if (-not (Test-Path -LiteralPath $outPath)) {
    throw "Expected output image was not created: $outPath"
}
```
