# AGENTS.md

本文件用于固定本仓库的开发规范。后续 Codex 或其他自动化开发助手在修改本项目时，必须优先遵守这里的约束。

## 项目定位

- 项目名称：图片转PDF工具箱
- 项目类型：HarmonyOS 元服务，不是普通 App
- 技术栈：ArkTS、ArkUI、Stage 模型、HarmonyOS 元服务工程
- 核心功能：只做图片转 PDF
- 不要扩展 PDF 合并、PDF 拆分、Word 转 PDF、PDF 压缩等其它功能
- 默认本地处理，不依赖后端接口

## 目录约定

主要工程位于：

```text
Application/
```

核心代码位于：

```text
Application/entry/src/main/ets/
├─ pages/
├─ components/
├─ model/
├─ service/
└─ utils/
```

页面职责：

- `pages/Index.ets`：首页、选择入口、最近记录
- `pages/ImageManagerPage.ets`：图片列表、删除、清空、排序、继续添加
- `pages/PdfSettingPage.ets`：PDF 参数设置
- `pages/GeneratePage.ets`：生成进度与失败重试
- `pages/ResultPage.ets`：结果展示、保存、继续转换、返回首页

服务职责：

- `ImagePickerService.ets`：系统图片选择、拍照添加、图片基础信息读取
- `PdfGenerateService.ets`：PDF 生成封装
- `FileSaveService.ets`：沙箱路径与系统文档保存 Picker
- `RecordStorageService.ets`：最近生成记录持久化
- `ConvertSessionService.ets`：页面间转换会话状态

## UI 规范

- 风格：简洁办公风
- 主色：`#2F80ED`
- 辅助色：`#00B894`
- 背景色：`#F5F7FA`
- 卡片背景：`#FFFFFF`
- 标题颜色：`#1F2937`
- 正文颜色：`#4B5563`
- 弱文字颜色：`#9CA3AF`
- 页面左右边距：`16vp`
- 卡片圆角：`16vp`
- 主按钮高度：`48vp`
- 主按钮圆角：`24vp`

不要把页面做成只有几个按钮的粗糙 Demo。按钮、卡片、空状态、加载状态、弹窗都应完整。

## 业务规则

- 图片最多 100 张
- 没有选择图片时，下一步必须禁用
- 删除单张图片前必须确认
- 清空全部前必须确认
- 生成 PDF 时禁止重复点击
- 文件名为空时必须提示
- 最近生成记录最多保存 10 条
- 新记录放在最前面
- 换页排序当前使用上移/下移，后续可替换为拖拽，但不要破坏 `order` 刷新逻辑

## PDF 生成规则

`PdfGenerateService.generatePdf(...)` 是唯一 PDF 生成入口。

当前实现可以使用占位 PDF 跑通流程，但接口必须保持稳定：

```ts
generatePdf(
  context,
  images,
  setting,
  onProgress
)
```

后续替换真实 PDF 生成能力时，只改 `PdfGenerateService` 内部，不要让页面直接操作 PDF 绘制逻辑。

真实实现应按以下顺序接入：

- decode image to pixelMap
- calculate page size
- draw image into PDF page
- write PDF to sandbox file
- return output path

## 权限与文件

- 优先使用系统 Picker 选择图片，不主动申请传统媒体读写权限
- 生成文件先保存到应用沙箱目录
- 用户点击保存时，使用系统文档保存 Picker
- 不要把正式签名文件提交到仓库
- 签名文件建议放在 `Application/signing/`
- `Application/.gitignore` 必须忽略：

```gitignore
/.codegenie
signing/
*.p12
*.p7b
*.cer
```

## 构建验证

优先使用当前机器的 DevEco 工具链验证：

```powershell
& "D:\DevEco Studio\tools\node\node.exe" "D:\DevEco Studio\tools\hvigor\bin\hvigorw.js" --mode module -p module=entry@default -p product=default -p requiredDeviceType=phone assembleHap --analyze=normal --parallel --incremental --daemon
```

如果 `D:\DevEco Studio` 不存在，再尝试其它 DevEco 安装路径。

构建成功但出现以下 warning 时，不要当成阻塞错误：

- `Function may throw exceptions. Special handling is required.`
- `showToast has been deprecated.`
- `showDialog has been deprecated.`
- `export struct ... component preview mode` 相关提示

真正需要修复的是 `ArkTS Compiler Error` 或打包、签名失败。

## 修改原则

- 不要改回云开发 Demo 首页
- 不要引入后端依赖
- 不要新增与图片转 PDF 无关的功能
- 不要删除旧云侧资源，除非用户明确要求
- 不要提交 DevEco 生成的本地目录、缓存、签名文件
- 修改后优先跑构建验证
