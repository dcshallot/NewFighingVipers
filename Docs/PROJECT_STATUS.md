# 项目状态

更新日期：2026-09-08

## 当前结论

项目正从研究归档转为正式制作仓库。当前唯一生产目标是 **Honey 正常状态高清角色**，阶段为 **C0：基线整理中**。方向 B 尚未准入。

## 当前 checkout 中存在

- 7 份日期研究笔记及其模板、指南；
- Model 2/Honey 提取与图像处理脚本；
- Hunyuan3D 包装脚本；
- Windows PowerShell 通用经验和 OpenKeeper 横向参考脚本；
- 新的正式文档、清单和环境基线。

## 当前 checkout 中不存在

- 可打开的 Unity 工程；
- Honey 可投产 `.blend`、`.fbx` 或材质；
- 历史 `HoneyMaterialTest` 场景；
- ROM、模拟器、视频、截图、texture dump；
- `Honey_Master_TextureSet` 的历史 PNG 和 manifest；
- Hunyuan/Meshy 生成模型；
- Ninja Ripper/Noesis 抓取；
- Hunyuan vendor、模型权重和 CUDA 环境。

研究笔记中以现在时描述的上述内容均是**历史本机状态**，不是当前仓库事实。

## 可继承成果

1. Model 2 菜单手动 dump 曾是最可靠的 texture cache 入口。
2. Honey 常态贴图历史集合曾整理为 39 张 Main + 4 张 P2 变体，但当前文件不可验证。
3. texture dump 主要提供灰度结构、alpha 和 UV 线索，不能作为最终彩色贴图。
4. Ninja Ripper 捕获网格碎片化，不适合作为完整角色源模型。
5. Hunyuan3D 四视图和双视图生成成功但质量被拒绝。
6. Meshy 输入实验说明清晰完整的单图可能优于不一致多视图，但不构成正式生产路线。
7. Humanoid 映射通过不代表动画和复杂服装变形合格。

## 当前缺口

- C1 可追溯的 Honey 参考资料未重新登记和冻结；
- `CHARACTER_BIBLE.md` 中比例、颜色和分件仍待证据填充；
- 没有原创 blockout、拓扑、UV、材质、骨架或权重；
- 没有正式 Unity URP 验证工程；
- Git LFS 远端容量、锁定支持和独立备份尚未验证；
- Windows 辅助环境和本地受限素材不在当前 Mac checkout；
- 发布授权范围尚未确定，当前工作只能视为研究和原型准备。

## 风险

| 风险 | 等级 | 应对 |
| --- | --- | --- |
| 参考素材来源或使用边界不清 | 阻塞 | 未登记 `rights_status` 的资料不得进入正式资产 |
| AI 输出改变关键设计 | 高 | 与来源证据分层，AI 只作可编辑辅助 |
| 二进制源文件无法合并 | 高 | LFS locking、单阶段单 owner、里程碑快照 |
| 历史笔记被误当当前方案 | 高 | 当前决策只认 `Docs/`，研究笔记标为历史证据 |
| Unity/Blender 版本漂移 | 中 | 固定版本；变化必须新增决策记录 |
| Windows-only 提取阻塞 Mac | 低 | 提取按需进行，不纳入 C0～C6 日常硬依赖 |

## 下一阶段

C0 完成后进入 C1：

1. 重新收集并登记 Honey 正常状态参考；
2. 计算 SHA-256，填写来源和权利状态；
3. 对照 Saturn、Model 2 截图和视频；
4. 填充角色比例、轮廓、分件、颜色和材质；
5. 冻结 `CHARACTER_BIBLE.md` 后再开始 C2 blockout。
