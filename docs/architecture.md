# FSD Architecture

本文档定义 Flutter 前端的 Feature-Sliced Design 架构约束。后续新增、迁移、review 都必须按本文档执行。

## 核心原则

- 严格按 FSD 分层组织代码。
- 上层可以依赖下层，下层禁止依赖上层。
- 同层 slice 默认隔离：禁止互相引用内部实现；`features` 之间仅允许经公开入口协作（见「Feature 同层依赖」）。
- 每个 slice 必须通过公开入口导出可复用 API。
- 页面只做组合，业务动作进入 `features/`，业务模型进入 `entities/`，基础能力进入 `shared/`。

## 必备目录

目标结构如下：

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

历史 `starter/`、`shared/router/` 等 app 层能力已收敛到 `lib/app/`。后续新增 app 层代码必须继续放入 `lib/app/`，不得重新扩大历史目录职责。

## FSD 层职责

| 层 | 目录 | 职责 |
| --- | --- | --- |
| app | `lib/app/` | 应用启动、全局路由、主题、根 ProviderScope、全局初始化 |
| pages | `lib/pages/` | 路由级页面、页面布局、页面私有状态和组合 |
| widgets | `lib/widgets/` | 跨页面复用的业务展示块，不承载业务动作 |
| features | `lib/features/` | 用户动作和业务流程，例如收藏、播放、解锁、登录 |
| entities | `lib/entities/` | 业务实体模型、实体数据源、实体级展示规则 |
| shared | `lib/shared/` | 无业务语义的组件、工具、基础设施适配 |

## 依赖方向

层间唯一允许的依赖方向：

```text
app -> pages -> widgets -> features -> entities -> shared
```

同层可以依赖下层，也可以跳过中间层直接依赖更底层。例如：

- `pages/main` 可以依赖 `features/agent`、`entities/chat`、`shared/widgets`。
- `entities/chat` 只能依赖 `shared` 或第三方基础 package。

### Feature 同层依赖（项目约定）

相对严格 FSD「同层完全隔离」，本项目**允许** `features/<A>` 依赖 `features/<B>`，但必须同时满足：

1. 只通过对方公开入口（`features/<B>/<B>.dart`），禁止打到 `provider/`、`service/`、`api/` 等内部路径。
2. 有明确协作关系，避免无必要的横向耦合；优先把共享模型下沉到 `entities/` 或 `shared/`。

当前允许的示例：

- `features/manage_ai_provider` → `features/agent`（远程模型拉取等）
- `features/chat` → `features/mcp`（会话内分发 MCP 工具）
- `features/chat` → `features/agent_tools`（本地工具列表与执行）
- `features/chat` / `features/agent_tools` → `features/agent/llm.dart`（LLM 传输与 `ChatSettings`）
- `features/manage_character` → `features/agent/llm.dart` + `features/agent_tools`（AI 生成角色卡文本与头像）
- `features/transfer_character` → `features/manage_character`（角色卡 JSON/PNG 文件导入落库）
- `features/transfer_character` → `features/manage_world_book`（导入卡片内嵌世界书时建独立世界书并绑 primary）
- `features/manage_world_book` → `entities/character` / `entities/chat`（删除世界书时清理角色与会话引用）
- `features/agent/agent.dart` 作为兼容门面 re-export `chat` + `agent_tools` + `llm`（pages / widgets 可继续只依赖门面）

禁止形成环：若 A 依赖 B，则 B 不得再依赖 A。  
因此 `chat` / `agent_tools` **不得** import `features/agent/agent.dart` 门面（门面已 re-export 二者），应使用 `features/agent/llm.dart`。

### 路由 typed route 例外

层方向写明 `app -> pages`，但 `go_router_builder` 的 typed route class 定义在 `app/router/`。因此：

- **允许** `pages/*` import `package:soulcast/app/router/app_router.dart`（或同目录生成文件）仅用于导航跳转。
- **禁止** page / feature / widget 从 `app/` 引入启动编排、主题实现、全局 bootstrap 等非路由能力。
- path 字符串常量优先走 `shared/navigation/`；属于 feature 的跳转动作应封装在 feature 内，避免多处硬编码 path。

禁止（除上述路由例外外）：

- `shared` import `entities`、`features`、`widgets`、`pages`、`app`。
- `entities` import `features`、`widgets`、`pages`、`app`。
- `features` import `widgets`、`pages`、`app`。
- `widgets` import `pages`、`app`。
- `pages/<slice>` import 另一个 page slice 的内部文件。
- 任意 slice 直接 import 其他 slice 的 `src/`、`widget/`、`provider/`、`service/`、`api/` 等内部目录。

## Slice 公开入口

可被外部引用的 slice 必须提供公开入口：

```text
features/agent/agent.dart          # 兼容门面（re-export chat + agent_tools + llm）
features/agent/llm.dart            # LLM 传输专用入口（供同层 feature 协作）
features/chat/chat.dart
features/agent_tools/agent_tools.dart
entities/chat/chat.dart
widgets/agent_chat/agent_chat.dart
```

外部只能 import 公开入口：

```dart
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/features/agent/agent.dart';
// 或按职责直接依赖：
import 'package:soulcast/features/chat/chat.dart';
import 'package:soulcast/features/agent_tools/agent_tools.dart';
```

禁止外部直接 import 内部文件：

```dart
// forbidden
import 'package:soulcast/features/chat/provider/chat/chat.dart';
```

### Feature 职责（agent / chat / agent_tools）

| Slice | 职责 |
| --- | --- |
| `features/chat` | 会话编排：`Chat` provider、`ChatService`、记忆整理、角色提示词 |
| `features/agent_tools` | 本地 `AgentTool` 注册与设置 UI；高德 HTTP / 天气地图工具与 markdown 协议模型 |
| `features/agent` | LLM 传输（`openai_dart`：Chat Completions / Responses）、远程模型拉取、`ChatSettings`；`agent.dart` 兼容门面 |

### Feature barrel 公开面

`features/<feature>/<feature>.dart` 应导出**稳定协作面**，避免把实现细节漏到全仓库。

允许导出：

- 对外状态入口（如 `chatProvider`、`availableAgentToolsProvider`）
- 跨 slice 需要的状态 / 配置模型（如 `ChatState`、工具配置 DTO）
- 动作型 UI 入口（如 `AgentToolPanel`）
- 展示层需要的协议型模型（如高德天气 / 地图 markdown 标签解析，供 `widgets/agent_chat` 使用）
- `features/agent/llm.dart`：`LlmClient` 工厂、`ChatSettings`、远程模型服务

禁止新增导出（应留在 feature 内部，或仅测试直接引用）：

- 具体 `*Tool` 实现类、HTTP / SDK 客户端（`api/` 内实现）
- LLM 传输适配细节（`openai_*`、`amap_http_client` 等）
- 仅 feature 内部使用的 service 实现文件

中期目标：pages / widgets 逐步改为直接依赖 `chat` / `agent_tools` / `llm`，再收缩 `agent.dart` 门面。

## Pages 层约束

页面 slice 结构：

```text
pages/<page_name>/
  <page_name>_page.dart
  provider/
  widget/
```

职责：

- `*_page.dart` 是页面入口，只负责页面级布局与组合。
- 页面私有状态放 `provider/`。
- 页面私有组件放 `widget/`。
- 页面内触发的业务动作必须委托给 `features/`。

示例：

```text
pages/home/
  home_page.dart
  provider/
  widget/
    home_swiper_layout.dart
    home_horizontal_row.dart
```

约束：

- `pages/home` 可以组合 `features`、`entities`、`shared`。
- `pages/home/widget` 里的组件不得被 `pages/recommendation` 直接引用。
- 当某个页面私有组件需要被多个页面复用时，必须移动到 `widgets/` 或 `features/`，不能跨 page import。

## Features 层约束

`features/` 是必备层。所有用户动作、业务流程和可复用交互都必须放入 features。

feature slice 结构：

```text
features/<feature_name>/
  <feature_name>.dart
  provider/
  widget/
  model/
  service/
  api/                 # 可选：外部后端 / SDK 适配
```

按需创建子目录，不要求每个 feature 都包含全部子目录。

各段职责：

| 目录 | 职责 |
| --- | --- |
| `provider/` | 该业务动作的 Riverpod 状态与对外动作入口 |
| `widget/` | 动作型 UI（按钮、表单、操作面板） |
| `model/` | feature 内 DTO / 状态模型（含编排用的协议级 DTO） |
| `service/` | 业务编排与用例（工具循环、记忆更新等），不直接依赖第三方 SDK |
| `api/` | 外部 HTTP / SDK 适配（Port 实现、请求映射）；第三方客户端 SDK 只允许出现在此目录 |

约束：

- feature 可以依赖 `entities` 和 `shared`。
- feature 可通过公开入口依赖其他 feature（规则见上文「Feature 同层依赖」）；`service/` 不得直接依赖第三方 SDK，SDK 只出现在本 feature 的 `api/`。
- feature 不得依赖 `pages` 或 `widgets`。
- feature 中的 widget 是动作型 UI，例如按钮、表单、操作面板。
- feature provider 只维护该业务动作所需状态，不维护页面布局状态。
- 仅本 feature 使用的外部协议适配放在该 feature 的 `api/`，不得塞进 `service/` 与业务编排混放。
- 无业务语义、可被多 feature 复用的基建适配才进入 `shared/`；LLM（`openai_dart`）留在 `features/agent/api/`，高德 HTTP（`dio`）留在 `features/agent_tools/api/`，MCP 适配留在 `features/mcp/api/`。

## Widgets 层约束

`widgets/` 存放跨页面复用的业务展示块。它比 `features` 更高层，但不承载业务动作。

适合放入 `widgets/` 的内容：

- 跨页面复用的聊天消息块（如 `widgets/agent_chat`）
- 跨页面复用的业务展示区块

不适合放入 `widgets/` 的内容：

- 发送、工具开关、供应商导入等用户动作，必须进入 `features/`。
- 无业务语义的纯 UI 基础组件，必须进入 `shared/widgets/`。

widget slice 结构：

```text
widgets/<widget_name>/
  <widget_name>.dart
  ui/
  model/
```

页面私有展示块留在 `pages/<page>/widget/`；仅当多个 page 复用时再上移到 `widgets/`。

## Entities 层约束

实体 slice 结构：

```text
entities/<entity_name>/
  <entity_name>.dart                 # public API
  <entity_name>_entity.dart          # entity model
  repository/
  provider/
  helper/                            # 可选：实体展示/编解码规则
```

当前示例：

```text
entities/chat/
  chat.dart
  chat_message_entity.dart
  repository/
  helper/

entities/ai_provider/
  ai_provider.dart
  ai_provider_entity.dart
  repository/
  provider/

entities/agent_tool/
  agent_tool.dart
  agent_tool_config_entity.dart
  repository/
  provider/

entities/mcp_server/
  mcp_server.dart
  mcp_server_config_entity.dart
  repository/
  provider/

entities/character/
  character.dart
  character_entity.dart
  repository/
  provider/

entities/world_book/
  world_book.dart
  world_book_entity.dart
  world_book_entry_entity.dart
  model/                 # WorldBook / WorldBookEntry
  helper/                # 酒馆 character_book JSON 编解码与映射
  repository/
  provider/
```

MCP 说明：

- `entities/mcp_server` 持久化外部 MCP Server 配置（URL、Bearer、启用状态、按工具禁用列表）。
- `features/mcp` 负责 StreamableHTTP 连接、`tools/list` / `tools/call`，并通过公开入口暴露 `McpRemoteTool` / `McpToolRunner`。
- `features/transfer_mcp` 负责 `mcpServers` JSON 导入导出（仅 `streamable_http`；可选 `headers.Authorization` → Bearer）。
- MCP **不**实现 `AgentTool`，**不**写入 `entities/agent_tool` 或 `AgentToolPanel`；与本地工具是两条独立管道。
- `features/chat` 的 `ChatService` 同时接收本地 tools 与 MCP tools，按 `mcp__` 前缀分发执行。

角色会话说明：

- `entities/character` 维护静态角色卡（人格、说话风格、场景、绝对禁区、多开场白、角色卡级 system/post-history、`primaryWorldBookId` / `extraWorldBookIds` 等），是不被记忆整理器修改的静态身份层。
- `entities/world_book` 维护独立世界书与条目；角色与会话仅保存绑定 id。匹配与注入由 `features/chat` 的 `CharacterBookResolver` 在发送时实时完成（多源合并顺序：角色 primary → extras → 会话 `worldBookIds`；支持 scanDepth / tokenBudget / constant / selective / before_char|after_char / 可选递归扫描）。
- `entities/chat` 的 `ChatConversationEntity.characterId` 关联角色；`null` 表示普通会话，创建后不可更改。会话可另绑 `worldBookIds`。
- 角色管理动作（新增 / 编辑 / AI 辅助生成 / 收藏 / 删除并级联删除关联会话）落在 `features/manage_character`；从角色卡创建并选中角色会话由 `features/chat` 的 `Chat` provider 承担（`startConversationForCharacter`，可传入选定开场白）。
- 世界书 CRUD 与删除级联清理落在 `features/manage_world_book`。
- SillyTavern `chara_card_v2` 的 JSON / PNG（`chara` 文本块）文件导入落在 `features/transfer_character`；导入时将卡片内嵌 book 建成独立世界书并设为 primary。页面只负责 FilePicker 与 toast。
- 世界书 UI：`pages/world_book_settings`（库列表）、`pages/world_book_edit`（书元数据 + 条目列表）、`pages/world_book_entry_edit`（单条编辑）、`pages/character_world_books`（角色多本绑定）；会话信息页可增删会话级绑定。
- Agent 文件库浏览（扫描 `AppDirectories.agent` 下图片与文件）落在 `features/browse_file_library`；页面组合在 `pages/file_library`。跨模块选图使用公开入口 `showFileLibraryImagePicker`（底部 Sheet）。

约束：

- entity model 使用不可变结构，当前项目优先 `freezed` + `json_serializable`。
- 页面不得复制 mock 数据。
- 外部引用实体时只 import `entities/<entity>/<entity>.dart` 公开入口。
- 实体展示规则、编解码优先沉淀到 `entities/<entity>/helper/`。
- 网络或本地数据源应进入 entity data source/repository，不直接散落在 pages。

## Chat 消息模型

助手消息以 `parts` 时间线为唯一展示与持久化结构（思考 / 工具调用 / 正文）。

完整收发与展示流程见 [chat_message_flow.md](chat_message_flow.md)。

约束：

- 会话角色仅为 `user` / `assistant` / `memory`；工具步骤只存在于助手 `parts`，不再使用独立 `tool` 消息行。
- 助手思考与正文以 `parts` 为准（`ChatReasoningPart` / `ChatTextPart` / `ChatToolCallPart`）；UI 只渲染 `parts`。
- `content` 仅作派生摘要（会话标题、日志等），不得再作为思考/工具步骤的展示源。
- 发往模型的历史必须通过 `expandConversationMessageToLlm` 从 `parts` 还原工具轮次。
- 助手消息可用 `isInterrupted` 标记用户停止；仅会话最后一条中断消息展示「继续回复」。
- 不做旧消息格式兼容：无 `partsJson` 的历史数据不保证可读，不写迁移或双读逻辑。

## Shared 层约束

`shared/` 默认只放无业务语义的基础能力：

```text
shared/
  widgets/        # 通用 UI，如图片、加载、空状态
  provider/       # 全局 app runtime 状态（如偏好）
  model/          # 全局无业务实体（如 AppPreferences）
  navigation/     # 路由 path 常量等导航基建
  repository/     # 全局仓储适配（若有）
  storage/        # Isar 等本地存储基建
  theme/          # 间距、圆角、颜色 token
  utils/          # 通用工具函数（按需）
  constants/      # 通用常量（按需）
```

禁止把仅某一 feature 使用的第三方 SDK 适配（例如 `openai_dart`、`mcp_dart`、高德 Dio 客户端）放进 `shared/`；此类适配属于对应 feature 的 `api/`。

### AppDirectories（本地路径唯一入口）

`shared/storage/app_directories.dart` 是 Documents / Cache / Support 下业务子目录与其下文件路径的**唯一约定入口**。

约束：

- 业务本地目录（如 `logs`、`isar`、`files`、`agent/generated_images`、`agent/chat_attachments`、语音模型目录等）必须在 `AppDirectories` 声明相对路径常量与 getter。
- 其它模块禁止硬编码或自行拼接业务子目录（例如直接写 `'agent/generated_images'`、`'character/avatars'`）。
- 需要落盘文件时：先通过 `AppDirectories.resolve()` 取目录，再用 `generatedImageFile` / `chatAttachmentFile` / `fileIn` 等 API 构造文件路径；调用方只传裸文件名，不得夹带路径分隔符。
- 通用图片导入、下载、base64 解码与格式识别统一使用 `shared/storage/image_file_store.dart`；调用 feature 仅配置文件名前缀，不重复实现落盘逻辑。
- AI 生成图与角色头像统一落在 `generatedImages`（相对 Documents：`agent/generated_images`），不另建头像专用目录。
- 聊天用户附件落在 `chatAttachments`（相对 Documents：`agent/chat_attachments`）；存储扫描的「文件」分类计入该目录，清理「文件」时一并清空。
- 新增业务目录时只改 `AppDirectories`，再在使用处引用 getter；存储扫描、清理等也只认此处暴露的目录。

### AppPreferences（全局 runtime + 会话偏好）

`shared/model/app_preferences_entity.dart` 与 `shared/provider/app_preferences_provider.dart` 承载：

- 应用级偏好：主题、语言、locale
- 与聊天相关、但需跨页面 / 启动恢复的 runtime：当前会话 id、customPrompts（可配置提示词模板）、temperature / topP / topK、context / tool rounds、memory 频率、responseMode 等

主题与语言的启动时机应对齐：`initApp` 读到 Isar 偏好后立刻 `LocaleSettings.setLocale`，并同步写入 `shared/theme/app_boot_appearance.dart` 的 `AppBootAppearance.themeMode`；根 `MaterialApp` 监听该 notifier，避免开屏整段停留在默认浅色。Riverpod `AppPreferences.restore()` 仍负责完整偏好灌入。

原生开屏（`flutter_native_splash`）在 `Application.run` 里 `preserve`，直到上述 boot 主题写入并完成下一帧后再 `remove`，避免主题种子就绪前露出默认浅色 Flutter 首帧；启动失败路径也必须 `remove`，防止卡死在原生开屏。

这是对「shared 无业务语义」的**有意放宽**：上述字段属于全局持久化的 app runtime，而不是某个 page 私有状态。新增同类字段时：

- 确需跨 feature / 启动恢复 → 可继续放 `AppPreferences`
- 仅某一 feature 使用且无需全局恢复 → 放到对应 `features/` 或 `entities/`，不要继续塞进 shared

### `weather_bg`（短期例外）

`shared/widgets/weather_bg/` 是偏视觉效果的天气背景组件，当前主要服务 `widgets/agent_chat` 的天气卡片。

- **短期**：允许留在 `shared/widgets/`，视为可复用视觉包，不得在其中依赖 `features/` / `entities/`。
- **中期**：迁到 `widgets/weather_bg` 或并入 `widgets/agent_chat`，避免 shared 继续堆积领域视觉资产。

## App 层约束

app 层负责项目组装：

```text
app/
  router/
  provider/
  theme/
  bootstrap/
```

约束：

- 全局路由配置属于 app 层。
- App 启动、初始化、全局监听属于 app 层。
- `main.dart` 只负责调用 app 入口。
- 历史 `starter/` 和 `shared/router/` 目录已迁移到 app 层，新代码不得重新引入这些历史目录。

## Riverpod 约束

Provider 放置规则：

- 页面布局状态：`pages/<page>/provider/`
- 业务动作状态：`features/<feature>/provider/`
- 实体数据状态：`entities/<entity>/repository/` 或 `entities/<entity>/provider/`
- 全局运行状态：`app/provider/` 或 `shared/provider/`

使用规则：

- 新 provider 优先使用 `riverpod_annotation`。
- provider 文件必须包含对应 `part '<file>.g.dart';`。
- 需要跨页面保留的状态使用 `@Riverpod(keepAlive: true)`。
- provider 维护状态和业务动作，不写复杂 UI 构建逻辑。
- 页面切换状态、筛选条件、滚动分类等不得放入 widget 普通字段。

## Routing 约束

当前路由使用 `go_router_builder` typed route。

约束：

- 新路由必须添加 typed route class；定义与生成代码放在 `app/router/`。
- route build 只返回页面入口 widget。
- 首页、推荐、收藏、我的属于 `MainPage` tab 管理，不单独注册顶级路由，除非需要深链。
- 详情页、播放页、登录页等可独立访问页面必须注册 route。
- 跳转动作如“打开详情”属于 feature 时，跳转入口应通过 feature 封装，不在多个 widget 中散落路径字符串。
- `pages` 引用 typed route 的例外见上文「路由 typed route 例外」。

## UI 约束

- 应用级轻量反馈统一调用 `SmartDialog.showToast`，不得使用 `ScaffoldMessenger.showSnackBar` 或 `showSnackBar`。
- `FlutterSmartDialog.init()` 属于全局 UI 初始化，只能在 `lib/app/` 的根应用入口注册；page、feature 和 entity 不得重复初始化。
- 独立 package 内调用 `SmartDialog` 时，必须在该 package 的 `pubspec.yaml` 声明 `flutter_smart_dialog` 直接依赖，禁止依赖主应用透传。
- 长文本必须设置 `maxLines` 和 `TextOverflow.ellipsis`。
- 列表卡片必须声明稳定宽高，避免图片加载或文案变化引发布局跳动。
- 图片组件必须有 placeholder 和 error 状态。
- 页面组件优先 `StatelessWidget` 或 `ConsumerWidget`。
- 只有本地动画、controller 生命周期、焦点管理等 Flutter 层状态才使用 `StatefulWidget`。
- 页面私有 widget 使用页面名前缀，例如 `HomeSwiperLayout`。
- feature widget 使用动作名前缀，例如 `PlayDramaButton`。

## 生成文件约束

以下文件禁止手动修改：

- `*.g.dart`
- `*.freezed.dart`
- `lib/i18n/strings*.g.dart`

修改源文件后运行：

```bash
fvm dart run build_runner build
fvm dart format lib
fvm dart analyze
```

普通 widget 改动至少运行：

```bash
fvm dart format lib
fvm dart analyze
```

## 命名约束

- 目录和文件：`snake_case`
- 类、enum：`UpperCamelCase`
- 页面：`<Name>Page`
- entity：`<Name>Entity`
- feature 公开入口：`features/<feature>/<feature>.dart`
- widget 公开入口：`widgets/<widget>/<widget>.dart`
- mock data source：`Mock<Name>DataSource`
- provider 生成类使用业务名，例如 `MainTab`、`PlayDrama`

## 新功能落位规则

新增代码时按顺序判断：

1. 是应用初始化、全局路由、主题或根状态吗？放 `app/`。
2. 是路由页面或页面私有布局吗？放 `pages/<page>/`。
3. 是跨页面复用的业务展示块吗？放 `widgets/<widget>/`。
4. 是用户动作或业务流程吗？放 `features/<feature>/`。
5. 是业务实体、实体数据源或实体展示规则吗？放 `entities/<entity>/`。
6. 是无业务语义的基础组件、工具或适配吗？放 `shared/`。

## 禁止事项

- 禁止跳过 `features/`，把播放、收藏、解锁、登录等业务动作写在 page widget 中。
- 禁止跨 page 引用对方的内部 widget/provider。
- 禁止 feature 依赖 page 或 widget。
- 禁止 entity 依赖 feature、page 或 widget。
- 禁止 shared 依赖任何业务层。
- 禁止手动编辑生成文件。
- 禁止在 `build` 方法中硬编码大段 mock 数据。
- 禁止无明确复用前提创建过度抽象。

## 当前项目整改方向

已完成（结构向）：

- `Chat` provider / `ChatService` 按用例拆分，并迁入 `features/chat`（`provider/chat/`、`service/chat/`）。
- 本地工具与高德适配迁入 `features/agent_tools`；`features/agent` 收缩为 LLM 传输 + 兼容门面。
- 三大 UI 巨石拆分：`provider_detail`、`chat_info`、`agent_chat_markdown`。
- 高德 Dio、`mcp_dart`、`openai_dart` 等第三方适配收敛到对应 feature 的 `api/`。

短期：

- 页面私有 UI 留在 `pages/<page>/widget/`（如 `main`、`provider_detail`、`chat_info`）。
- 聊天展示复用块留在 `widgets/agent_chat/`；发送 / 工具 / 供应商管理动作留在 `features/`。
- 第三方 SDK 适配只进对应 feature 的 `api/`（如 `openai_dart`、`mcp_dart`、高德 HTTP）。
- pages / widgets 逐步改为直接依赖 `features/chat`、`features/agent_tools`、`features/agent/llm.dart`。
- 可选：继续拆分仍偏大的 page 私有 UI（`character_management`、`main_chat_drawer`、`settings_page`）。

中期：

- 继续保持路由代码在 `app/router/`，启动编排在 `app/bootstrap/`。
- 收缩并最终移除 `agent.dart` 兼容门面（见上文 barrel 约定），避免导出具体 Tool / HTTP 实现。
- 将 `weather_bg` 迁出 shared；评估 `AppPreferences` 中纯 agent 字段是否下沉。
- 将仍落在 page 内的业务写操作继续下沉到 `features/`。
