# SoulCast

项目使用严格 Feature-Sliced Design 架构组织前端代码。

## Tech Stack

- Flutter / Dart
- Riverpod + `riverpod_annotation`
- GoRouter + `go_router_builder`
- Freezed + JSON serialization
- SmartDialog（全局 Toast 与弹窗）
- FVM
- 本地基础能力 package：`packages/flute_core`

## Documentation

- [入门使用教程](docs/user_guide.md)
- [FSD 架构约束](docs/architecture.md)
- [消息收发与展示全流程](docs/chat_message_flow.md)
- [文档索引](docs/README.md)
- [Agent 协作规范](AGENTS.md)

## Project Structure

```text
lib/
  app/                  # app 初始化、全局 provider、router、主题、启动编排
  pages/                # 路由页面与页面组合
  widgets/              # 跨页面、偏业务展示的复合 UI 块
  features/             # 用户动作、业务流程、可复用交互能力
  entities/             # 业务实体、实体模型、实体数据源
  shared/               # 无业务语义的基础设施、通用 UI、工具
  i18n/                 # 多语言资源与生成文件
  main.dart
```

必须遵守层间依赖方向：

```text
app -> pages -> widgets -> features -> entities -> shared
```

补充约定（feature 互引、pages 引用 typed route、`AppPreferences` / `weather_bg` 例外等）见 [docs/architecture.md](docs/architecture.md)。

## Development

安装依赖：

```bash
fvm flutter pub get
```

代码生成：

```bash
fvm dart run build_runner build
```

格式化：

```bash
fvm dart format lib test
```

静态检查：

```bash
fvm dart analyze
```

运行测试：

```bash
fvm flutter test
```

## Architecture Rules

- 页面只做组合，业务动作进入 `features/`。
- 业务模型、实体数据源、实体展示规则进入 `entities/`。
- 跨页面业务展示块进入 `widgets/`。
- 无业务语义的通用组件和工具进入 `shared/`。
- 新 provider 优先使用 `riverpod_annotation`。
- 应用级轻量反馈统一使用 `SmartDialog.showToast`。
- 禁止手动修改 `*.g.dart`、`*.freezed.dart`、`lib/i18n/strings*.g.dart`。
- 修改架构、目录规则、协作规则时，必须同步更新 `docs/architecture.md` 和 `AGENTS.md`。

更完整的规则见 [docs/architecture.md](docs/architecture.md)。

## Commit Message

提交代码时使用以下格式：

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
docs(architecture): 补充 FSD 架构约束
update(docs): 更新项目协作文档
```
