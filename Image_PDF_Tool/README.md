# 图片转PDF工具箱

这是一个 HarmonyOS 元服务项目，产品名称为“图片转PDF工具箱”。核心功能只围绕图片转 PDF：选择图片、管理排序、设置 PDF 参数、生成 PDF、查看结果和保存最近记录。

## 目录结构

```text
.
├─ Application/       # HarmonyOS 元服务应用工程
├─ CloudProgram/      # 原端云示例保留资源，当前主流程不依赖后端
└─ README.md
```

## 开发环境

- DevEco Studio
- HarmonyOS SDK
- AppGallery Connect / AGC 云服务环境

打开项目时，建议使用 DevEco Studio 打开 `Application/` 目录。

## 功能说明

- 首页：展示产品入口、功能卡片、最近生成记录
- 图片管理：支持多选图片、拍照添加、继续添加、删除、清空、上移、下移
- PDF 设置：支持文件名、A4/原图尺寸、适配方式、方向、边距、质量、单图单页
- 生成进度：显示处理进度和失败重试弹窗
- 结果页：显示文件名、大小、路径、页数，并提供预览、分享、保存到用户选择位置、继续转换、返回首页入口
- 最近记录：使用 Preferences 保留最近 10 条生成记录

## 主要代码目录

```text
Application/entry/src/main/ets/
├─ entryability/
│  └─ EntryAbility.ets
├─ pages/
│  ├─ Index.ets
│  ├─ ImageManagerPage.ets
│  ├─ PdfSettingPage.ets
│  ├─ GeneratePage.ets
│  └─ ResultPage.ets
├─ components/
│  ├─ AppHeader.ets
│  ├─ FeatureCard.ets
│  ├─ ImageItemCard.ets
│  ├─ PrimaryButton.ets
│  ├─ EmptyView.ets
│  ├─ SettingItem.ets
│  └─ RecentPdfCard.ets
├─ model/
├─ service/
└─ utils/
```

## PDF 生成说明

`PdfGenerateService` 已完成完整业务封装：

```text
Application/entry/src/main/ets/service/PdfGenerateService.ets
```

当前实现会在应用沙箱目录生成一个合法 PDF 占位文件，用于跑通完整页面流程。后续如果接入 HarmonyOS PDF 绘制能力，只需要替换该服务内部的 TODO 部分：

- decode image to pixelMap
- calculate page size
- draw image into PDF page
- write PDF to sandbox file
- return output path

## 签名文件说明

当前应用签名配置位于：

```text
Application/build-profile.json5
```

为了避免换电脑后本机绝对路径失效，建议把签名文件放在应用工程内的本地目录中：

```text
Application/
└─ signing/
   ├─ release.p12
   ├─ release.cer
   └─ release-profile.p7b
```

然后在 `Application/build-profile.json5` 中使用相对路径：

```json5
"certpath": "./signing/release.cer",
"profile": "./signing/release-profile.p7b",
"storeFile": "./signing/release.p12"
```

注意：正式签名文件只用于本地构建和发布，不建议提交到 GitHub、Gitee 等远程仓库。

建议在 `.gitignore` 中忽略：

```gitignore
signing/
*.p12
*.p7b
*.cer
```

如果以后需要在其他电脑构建，不需要重新申请签名，只需要把同一套 `p12 / cer / p7b` 文件安全地复制到 `Application/signing/` 目录即可。已经上架的应用应尽量沿用同一套发布签名，否则可能影响后续版本更新。

## 运行说明

1. 使用 DevEco Studio 打开 `Application/`。
2. 确认 `Application/build-profile.json5` 中签名配置可用。
3. 选择 entry 模块运行到 HarmonyOS 真机或模拟器。
4. 首页点击“选择图片”，按流程完成 PDF 生成。

当前元服务使用系统图片 Picker 和应用沙箱目录保存文件，不需要传统读写存储权限。

## 常见问题

- 换电脑构建失败：检查签名文件是否放到 `Application/signing/`，并确认 `build-profile.json5` 使用相对路径。
- 最近记录为空：完成一次生成后才会出现记录。
- 预览/分享提示未接入：主流程已生成文件，系统级预览和分享面板可在 `ResultPage` 中继续接入；“保存到本地”已使用系统文档保存 Picker。
- 命令行 hvigor 构建失败：请确认 DevEco Studio / Hvigor 版本支持项目 `modelVersion`。

## 云侧工程

云侧资源位于 `CloudProgram/`，包括：

- `clouddb/`：Cloud DB 对象类型和数据
- `cloudfunctions/`：云函数代码
- `cloud-config.json`：云侧配置

安装云侧依赖：

```powershell
cd CloudProgram
npm install
```

## 参考文档

- [HarmonyOS 端云一体化开发文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/agc-harmonyos-clouddev-overview)
