# AGENTS.md

本文件适用于整个仓库。任何自动化编码 agent 或协作开发者在修改本项目时，都必须遵守这里的规则。

## Working Language

- 面向用户的说明默认使用中文。
- 代码命名遵守 Dart/Flutter 习惯，文件和目录使用 `snake_case`。
- 提交信息使用中文描述，格式见本文末尾。

## First Principles

- 先阅读当前代码和文档，再动手修改。
- 优先保持小步、局部、可验证的改动。
- 不要重写用户已有改动，不要删除未明确要求删除的文件。
- 不要手动修改生成文件。
- 架构相关改动必须同步更新文档。
- 不做旧数据 / 旧格式兼容与迁移回退。模型、持久化与 UI 一律以当前结构为准；本地历史数据不保证可读，必要时清空后重建。禁止为旧字段、旧消息形态新增合成、回退或双读路径。

## Required Architecture

项目严格遵守 Feature-Sliced Design。完整规则见 [docs/architecture.md](docs/architecture.md)。

必须使用以下层级：

```text
lib/
  app/
  pages/
  widgets/
  features/
  entities/
  shared/
  i18n/
```

层间唯一允许的依赖方向：

```text
app -> pages -> widgets -> features -> entities -> shared
```

项目约定补充（完整说明见 [docs/architecture.md](docs/architecture.md)）：

- 允许 `features` 之间通过公开 barrel 协作（禁止内部路径、禁止环依赖）。
- 允许 `pages` 为跳转 import `app/router` 的 typed route；不得借此依赖 app 其它能力。
- `AppPreferences` 可承载全局 runtime + 需启动恢复的会话偏好；`weather_bg` 短期可留在 shared，中期迁出。
- 本地业务路径一律经 `AppDirectories`（禁止在其它文件硬编码/拼接子目录）；AI 生图与角色头像统一落 `generatedImages`；聊天用户附件落 `chatAttachments`。

放置规则：

- 应用启动、全局路由、主题、全局 provider：`lib/app/`
- 路由页面、页面布局、页面私有状态：`lib/pages/<page>/`
- 跨页面业务展示块：`lib/widgets/<widget>/`
- 播放、收藏、解锁、登录、详情跳转等用户动作：`lib/features/<feature>/`
- 业务实体、实体数据源、实体展示规则：`lib/entities/<entity>/`
- 无业务语义的组件、工具、基础设施适配：`lib/shared/`（含上述 AppPreferences / weather_bg 例外）

禁止：

- 禁止跳过 `features/`，把业务动作写进 page widget。
- 禁止跨 page 引用对方的 `widget/` 或 `provider/` 内部文件。
- 禁止 `features` 依赖 `pages` 或 `widgets`。
- 禁止 `entities` 依赖 `features`、`widgets`、`pages`。
- 禁止 `shared` 依赖任何业务层。
- 禁止把仅某一 feature 使用的第三方 SDK 适配放进 `shared/`（应进对应 feature 的 `api/`）。

## Slice Public API

可复用 slice 必须提供公开入口：

```text
features/<feature>/<feature>.dart
entities/<entity>/<entity>.dart
widgets/<widget>/<widget>.dart
```

外部引用只能 import 公开入口，不得直接 import 内部实现文件。Feature barrel 应只导出稳定协作面，不导出具体 Tool / HTTP / SDK 客户端实现；细则见 architecture 文档。

## Flutter And Riverpod Rules

- 页面入口优先使用 `StatelessWidget` 或 `ConsumerWidget`。
- 只有动画、controller 生命周期、焦点管理等 Flutter 层状态才使用 `StatefulWidget`。
- 页面布局状态放在 `pages/<page>/provider/`。
- 业务动作状态放在 `features/<feature>/provider/`。
- 实体数据状态放在 `entities/<entity>/repository/` 或 `entities/<entity>/provider/`。
- 全局运行状态放在 `app/provider/` 或 `shared/provider/`。
- 新 provider 优先使用 `riverpod_annotation`。
- 需要跨页面保留的状态使用 `@Riverpod(keepAlive: true)`。

## UI Rules

- 应用级轻量反馈统一使用 `SmartDialog.showToast`，禁止新增 `ScaffoldMessenger.showSnackBar` 或 `showSnackBar`。
- `FlutterSmartDialog.init()` 只在 `lib/app/` 的根应用入口注册；独立 package 使用时必须在自身 `pubspec.yaml` 声明直接依赖。
- 长文本必须设置 `maxLines` 和 `TextOverflow.ellipsis`。
- 列表卡片必须声明稳定宽高，避免图片加载和文案变化引发布局跳动。
- 图片组件必须有 placeholder 和 error 状态。
- 页面私有 widget 使用页面名前缀，例如 `HomeSwiperLayout`。
- feature widget 使用动作名前缀，例如 `PlayDramaButton`。
- 通用基础 UI 放 `shared/widgets/`，不得依赖业务实体。

## Generated Files

禁止手动修改：

- `*.g.dart`
- `*.freezed.dart`
- `lib/i18n/strings*.g.dart`

修改源文件后按需运行代码生成：

```bash
fvm dart run build_runner build
```

## Testing Rules

- 不要编写 Isar 相关测试，包括直接打开、初始化、依赖 native core、访问 collection、验证 schema 或仓库持久化。
- 涉及 Isar 持久化的数据结构，优先测试不依赖 Isar 的状态流转、provider 交互、UI 行为或外层调用边界。

## Common Commands

安装依赖：

```bash
fvm flutter pub get
```

格式化：

```bash
fvm dart format lib test
```

静态检查：

```bash
fvm dart analyze
```

测试：

```bash
fvm flutter test
```

## Documentation Updates

以下改动必须同步更新文档：

- 架构分层、依赖方向、目录落位变化：更新 `docs/architecture.md`。
- agent 工作方式、验证命令、提交规则变化：更新 `AGENTS.md`。
- 项目入口说明、文档索引、常用命令变化：更新 `README.md`。

## Git Rules

提交信息格式：

```text
<type>(模块): 中文描述
```

常用 `type`：

- `feat`：新增功能
- `fix`：修复问题
- `update`：更新已有能力或文档
- `docs`：仅文档变更
- `refactor`：重构
- `chore`：工程配置、依赖、脚手架等维护工作

示例：

```text
feat(home): 新增首页横图推荐布局
docs(architecture): 补充 FSD 架构约束
update(docs): 更新项目协作文档
```

提交前检查：

- `git status --short`
- 确认没有误提交生成文件或无关文件。
- 至少运行 `fvm dart format lib test` 和 `fvm dart analyze`，除非只改文档。
