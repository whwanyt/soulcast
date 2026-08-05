# 消息收发与展示全流程

本文描述 SoulCast 聊天消息从发送、模型编排、工具调用，到 UI 展示与持久化的完整方案。分层约束见 [architecture.md](architecture.md)；协作规则见 [AGENTS.md](../AGENTS.md)。

## 目标

- 一次用户提问对应**一轮助手时间线**（Assistant Turn），而不是多条互相替换的气泡。
- 思考、工具调用、正文按时间顺序落在同一条助手消息的 `parts` 中。
- 流式过程中原地更新同一 turn，工具执行时不丢弃已出现的思考。
- 历史会话再次提问时，从 `parts` **回放**完整工具轮次给模型。
- 不做旧消息格式兼容：无 `parts` 的历史数据不保证可读。

## 分层职责

| 层 | 职责 | 关键入口 |
| --- | --- | --- |
| pages | 主聊天页组合输入框与消息列表 | `lib/pages/main/` |
| widgets | 消息列表、各角色气泡、parts 渲染 | `lib/widgets/agent_chat/` |
| features | 发送编排、流式/非流式 completion、工具执行、API 历史展开、记忆更新 | `lib/features/agent/` |
| entities | 消息模型、parts、Isar 实体与仓库 | `lib/entities/chat/` |
| shared | 展示偏好（如是否显示工具消息） | `lib/shared/provider/app_preferences_provider.dart` |

依赖方向仍遵守 FSD：`pages → widgets → features → entities → shared`。

## 数据模型

### 会话消息

`ChatConversationMessage` 是列表中的一行：

| 角色 | 用途 |
| --- | --- |
| `user` | 用户输入；`content` 为正文，本地附件在 `parts`（`ChatAttachmentPart`） |
| `assistant` | 一轮助手回复；展示与工具历史均以 `parts` 为准 |
| `memory` | 记忆快照展示行（不进入模型历史） |

助手消息字段约定：

- `parts`：选中版本的展示与持久化时间线（JSON → `partsJson`）。
- `content`：由 text parts 派生的摘要，用于会话标题、日志，以及无 parts 时的降级回放；**不作为思考/工具步骤的展示源**。
- `versions` / `selectedVersionIndex`：同一回合的多版回复；顶层字段始终等于选中版本。

用户消息字段约定：

- `content`：输入框正文（可为空，若仅发附件）。
- `parts`：`ChatAttachmentPart` 列表（图片 / 基础文档）；落盘于 `AppDirectories.chatAttachments`。
- 发送条件：正文非空 **或** 草稿附件非空。

### Parts 时间线

```text
ChatMessagePart
├─ ChatReasoningPart     # 深度思考（助手）
├─ ChatToolCallPart      # 工具调用（助手）
├─ ChatImagePart         # 生成图片（助手）
├─ ChatTextPart          # 可见正文（助手）
└─ ChatAttachmentPart    # 用户附件（image / document）
```

多轮工具循环时，parts **按轮次追加**到同一助手消息，例如：

```text
[Reasoning₁] → [ToolCall…] → [Image] → [Text₂?]
```

序列化：`encodeChatMessageParts` / `decodeChatMessageParts`，存入 `ChatMessageEntity.partsJson`。

## 发送主流程

入口：`Chat.sendMessage`（`lib/features/chat/provider/chat/chat.dart`）。

```text
用户点输入区「+」→ 底部 Sheet（图片 / 文件库 / 上传附件）→ 导入到 draftAttachments
用户提交（正文和/或附件）
  → 校验（正文或附件非空、未在发送中、已选模型；文档可读）
  → 未选模型：写入 errorMessage，主聊天页 toast 提示后返回
  → 确保会话存在
  → 解析 ChatSettings（供应商 / 模型 / 系统提示词等）
  → 创建 LlmClient（按供应商 `apiMode`：Chat Completions 或 Responses）
  → 创建 user 消息（含 ChatAttachmentPart）并立即落库
  → 清空草稿正文与 draftAttachments，加载会话记忆
  → 创建占位 assistant（空 parts）并立即落库，写入 UI，`isSending = true`
  → 按偏好走流式或非流式
  → 流式：节流 checkpoint 落库；非流式：等待整段返回后一次落库
  → 成功：终态落库助手结果（缺省补 `finishReason=stop`），可选更新记忆 / 标题
  → 调用异常：toast + 将错误文案写入助手消息并落库
  → 中止：保留已生成或空占位助手，标记 `isInterrupted = true` 并落库
```

状态拼装始终为：

```text
messages = [...prefixMessages, ...completionResult.messages]
```

其中新发送时 `prefixMessages = 历史 + 本次 user`；继续回复时 `prefixMessages` 含被中断的助手消息。`completionResult.messages` 通常为**一条**带完整 `parts` 的 assistant 消息；投影时复用生成开始时的占位 `id`。

### 请求协议（供应商 `apiMode`）

供应商详情可切换：

| 配置 | 传输 | 杀进程后 |
| --- | --- | --- |
| `apiMode=chatCompletions`（默认） | `/chat/completions` | 无法重连同一请求；标 `isInterrupted`，可「继续回复」重发 |
| `apiMode=responses`，`backgroundEnabled=false`（默认） | `/responses` 同步/流式 | 同 Completions：中断 +「继续回复」 |
| `apiMode=responses` + `backgroundEnabled=true` | `/responses`，`background: true` | 落库 `remoteResponseId`，冷启动后 `retrieve` 轮询取回并续工具轮 |

传输层仍统一为 `LlmClient`（`features/agent/api/`）；编排层不依赖 `openai_dart`。仅开启 background 时才会在拿到 `response.id` 后 checkpoint 到当前助手消息。

### 中途退出与重进

| 退出方式 | 无 background | Responses + background |
| --- | --- | --- |
| 同进程离开主聊天 | keepAlive 续跑；流式 checkpoint | 同左；另有服务端任务 |
| 切换会话 | 中断落盘 + abort | `cancelRemoteResponse`（若有 id）+ 中断落盘；目标会话若有 pending id 则加载后 resume |
| 杀进程 / 冷启动 | 末条无 `finishReason` → `isInterrupted` +「继续回复」 | 末条有 `remoteResponseId` 且无终态 → **自动** `resumePendingRemoteResponse`（轮询取回，UI 显示生成中） |

冷启动：`ChatState` 初始 `isLoadingMessages: true`，避免首帧空引导。清理聊天历史后调用 `restoreInitialConversation(force: true)` 强制重建运行态。

不做旧消息格式兼容。跨进程取回仅在 Responses **且**供应商开启 `backgroundEnabled` 时可用。

### 停止与继续回复

- AI 生成中：输入框可继续编辑；主按钮为「停止」。
- 点停止：中止当前请求；Responses 另调 `cancelRemoteResponse`；保留已生成的助手 turn（含空占位），标记 `isInterrupted = true` 并清空 `remoteResponseId` 后落库；主按钮恢复为「发送」，可发起新一轮。
- 若该中断助手仍是会话最后一条（忽略尾部 `memory`）且未在生成中：气泡右下角显示「继续回复」。
- 点「继续回复」：若仍有可取回的 `remoteResponseId` 则优先 resume；否则同一消息 id / 当前选中版本上续写（API 附加隐藏 continue 提示词）；成功后清除 `isInterrupted`。
- 用户在中断后发送了新消息：旧气泡上的「继续回复」隐藏（仅末尾助手回合可继续）。

### 重新生成与多版本

助手回合（assistant turn）可保留多个回复版本，交互对齐 ChatGPT：

| 能力 | 行为 |
| --- | --- |
| 重新生成 | 仅末尾助手回合（忽略尾部 `memory`）；按同一前置用户消息重新请求，**不**走 `resumeAssistant`；新结果 append 为新版本并自动选中 |
| 版本切换 | `← n/m →` 只改 `selectedVersionIndex` 与顶层展示字段；仅末尾助手回合可切换 |
| 继续回复 | 更新**当前选中版本**，不新增版本 |
| 冻结 | 用户发送下一条消息后，该回合不再显示重新生成 / 切换；持久化仍保留全部版本，列表始终渲染选中版 |

数据约定：

- 消息 `id` 为回合稳定 id，不随切换或再生成改变。
- `versions` + `selectedVersionIndex` 存于 `ChatMessageEntity.versionsJson` / `selectedVersionIndex`；顶层 `content` / `parts` / usage 等始终与选中版本同步。
- 重新生成前删除该助手之后的 `memory` 展示行；结构化 `ChatConversationMemory` 不做回滚。
- 再生成开始即落库空占位（覆盖当前回合持久化）；同进程中止且新版无可见内容时，由内存中的再生成上下文恢复版本列表。杀进程后以落库内容为准，不保证保留再生成前的版本。

入口：`Chat.regenerateLastAssistant` / `Chat.selectAssistantVersion`（`lib/features/chat/provider/chat/chat.dart`）。

### 请求消息组装与历史回放

`buildLlmRequestMessages`：

1. 角色卡 `cardSystemPrompt`（若有）→ `system`
2. 世界书 `before_char`（若有）→ `system`
3. 角色卡提示词（角色会话，`ChatSettings.characterPrompt` 非空时）→ `system`
4. 世界书 `after_char`（若有）→ `system`
5. 应用 / 会话系统提示词 → `system`
6. 记忆提示词（若有）→ 额外 `system`
7. 截断后的历史 → `expandConversationMessageToLlm`（`lib/features/chat/service/chat_llm_message_mapper.dart`）
8. 角色卡 `postHistoryInstructions`（若有）→ 历史后的 `system`

### 角色会话与记忆分层

会话是否为角色会话由 `ChatConversationEntity.characterId` 决定，`Chat._resolveChatSettings` 据此拼装：

| 层 | 普通会话 | 角色会话 |
| --- | --- | --- |
| 静态身份 | 无 | 实时读取角色卡渲染为 `characterPrompt`（`buildCharacterSystemPrompt`，含 description 等），不写记忆、不被记忆整理器修改 |
| 世界书 | 无 | 合并角色绑定书与会话 `worldBookIds`，按近期对话关键词匹配并注入 before/after char；不写记忆 |
| 系统提示词 | 会话 → 应用 → 默认三级 | 仅会话级附加提示词（无则为空，不注入默认助手提示词）；角色卡级 `cardSystemPrompt` / `postHistoryInstructions` 另槽位注入 |
| 长期记忆（动态） | 通用长期记忆（用户偏好、背景、长期约定、任务进展） | 关系 / 世界观增量 / 剧情状态 / 偏好 / 约束等演化记忆 |

- 记忆提取与注入按 `ChatSettings.isRolePlay` 分流：`buildChatMemorySystemPrompt` / `buildChatMemoryUpdatePrompt` 使用两套文案。
- `ChatMemoryFactCategory` 已移除 `roleProfile`；固定人设只存在于角色卡，不再进入长期记忆。
- 会话信息页「长期记忆」页签（i18n `main.info.memoriesTab`）即动态记忆条目的管理入口。
- 每个角色会话记忆按 `conversationId` 独立，同一角色的多个会话互不共享。

展开规则：

| 角色 | API 展开 |
| --- | --- |
| `user`（无附件） | `LlmMessage.user(content)` |
| `user`（有附件） | 文档抽文本拼入正文；图片转 base64 data URL → `LlmMessage.user(..., contentParts)` |
| `memory` | 不发送 |
| `assistant`（有 parts） | 按时间线还原工具轮次（见下） |
| `assistant`（无 parts） | 仅 `LlmMessage.assistant(content)` |

用户附件约定：

- 图片：`jpg/jpeg/png/webp/gif`，Completions / Responses 多模态发出。
- 文档：仅 `txt/md/json/csv`（不做 PDF）；本地 UTF-8 读入后以 fenced 文本块注入。
- 入口：输入区 `+` → Sheet（系统选图 / 文件库选图 / 上传文档）。

助手 parts → 领域 LLM 消息：

```text
跳过 ChatReasoningPart
连续 ChatToolCallPart(completed/failed)
  → LlmMessage.assistant(content: 此前正文?, toolCalls: [...])
  → LlmMessage.tool(toolCallId, result) × N
剩余 ChatTextPart / ready ChatImagePart（markdown）
  → LlmMessage.assistant(content: 正文)
跳过 status=running 的工具步骤（避免伪造空结果）
```

当前请求内的实时工具循环仍通过可变 `requestMessages` 追加 `assistant(toolCalls)` + `tool`；与历史回放使用同一语义。传输层经 `LlmClient`（`features/agent/api/` 中的 OpenAI 兼容 adapter）发出；`service/` 编排层不依赖 `openai_dart`。`contentParts` 在 Completions / Responses mapper 中映射为 multipart / `input_image`。

## 编排：Assistant Turn + 工具循环

核心：`ChatService`（`lib/features/chat/service/chat/chat_service.dart`）。

常量：工具轮次上限来自设置 `maxToolRounds`（开启时为 N，关闭为不限制）。

### 非流式 `createCompletion`

```text
requestMessages = build(...)
for round in 0..max-1:
  response = completion(requestMessages)
  roundParts = 本轮 reasoning + text（有 tool_calls 时允许无正文）
  if 无 tool_calls:
    提交 committedParts + roundParts → 返回单条 assistant
  else:
    执行工具 → committedParts += roundParts + tool parts
    requestMessages += assistant(toolCalls) + tool results
    继续下一轮
超出轮次 → 追加错误 TextPart，标记 isToolCallsExceeded
```

### 流式 `createCompletionStream`

与非流式相同 turn 语义，但每轮会多次 `yield`：

```text
同一 turnId，复用同一 assistant 消息 id
  ├─ 流式 delta：yield [assistant(parts = committed + 本轮进行中 parts)]
  ├─ 若需要工具：
  │    yield 工具 running
  │    执行工具
  │    yield 工具 completed/failed，并 commit 本轮 parts
  │    带着 toolCalls 进入下一轮 API
  └─ 无工具：commit 后 yield 最终结果并结束
```

要点：

- 思考与正文以稳定 part id（如 `${turnId}_r$round` / `${turnId}_t$round`）原地增长。
- 仅 `tool_calls`、无正文时**不**写入「模型没有返回文本内容」占位。
- 中止（`LlmAbortedException`）时：流式中间态可能已在内存中，但**仅成功结束后**才把本轮助手结果写入 Isar。

## 持久化

| 时机 | 写入内容 |
| --- | --- |
| 发送开始 | 立即保存 user 消息；若 `titleOrigin == pending` 且标题仍为默认「新会话」，用首条用户消息截断作临时标题 |
| 流式 / 非流式成功结束 | 保存 `completionResult.messages`（助手 turn，含 versions） |
| 重新生成开始 | 删除助手后的 `memory` 行（`deleteMessages`） |
| 版本切换 | 更新该助手 turn 的选中版本 |
| 记忆更新成功 | 可能追加 `memory` 消息 |
| 自动标题成功 | 更新会话 `title`，并将 `titleOrigin` 设为 `generated` |

仓库：`ChatRepository.saveMessages` → `ChatMessageEntity`（含 `partsJson`、`versionsJson`、`selectedVersionIndex`）。

### 会话标题（`titleOrigin`）

对齐常见 AI 客户端：普通会话在首轮助手成功后用 LLM 生成一次短标题；用户改过则永不覆盖。

| `titleOrigin` | 含义 |
| --- | --- |
| `pending` | 可自动生成（含首条用户消息临时截断） |
| `generated` | 已由 LLM 生成，不再自动改写 |
| `manual` | 用户重命名或角色会话固定角色名，永不自动改写 |

规则摘要：

- 新建普通会话：`新会话` + `pending`；角色会话：角色名 + `manual`。
- 用户非空重命名 → `manual`；清空标题/清空消息 → `新会话` + `pending`。
- 成功完成后由 `ChatTitleUpdateService` 生成标题；`characterId != null` 或非 `pending` 时跳过。
- 生成失败静默保留临时标题；下次成功完成且仍为 `pending` 时可重试。

加载会话：按 `createdAt` 排序还原 `ChatConversationMessage` 列表；助手 UI 直接读 `parts`。

## UI 展示

### 列表

`AgentChatMessageList`：

- 接收 `isSending`：末尾助手回合在发送中视为 **active turn**（忽略尾部 `memory`）。
- 按角色过滤：`memory` 受偏好开关控制；`user` / `assistant` 始终显示。
- 助手气泡内的 `ChatToolCallPart` 受「工具消息」开关过滤。
- 跟随底部滚动用 `streamFingerprint`（含 versions / 选中索引）检测最后一条变化。
- 列表 `onItemKey` / 气泡 `ValueKey` 只用稳定的 `message.id`；禁止把 fingerprint 当 key，否则流式增高时高度缓存失效并与 `keepPosition`/`jumpToBottom` 互相拉扯导致闪烁。
- 末尾助手回合未在发送中时：展示「重新生成」；多版本时另展示 `← n/m →`；中断时另展示「继续回复」。

### 助手气泡时间线

`AgentAssistantChatMessageTile` 按 `parts` 顺序渲染：

| Part | 组件 | 交互 |
| --- | --- | --- |
| `ChatReasoningPart` | `AgentChatMessageReasoningBlock` | active turn 时自动展开，结束后自动收起；用户仍可手动切换 |
| `ChatToolCallPart` | `AgentChatToolCallPartBlock` | 折叠头「工具: name · 状态」；`running` 显示进度指示 |
| `ChatTextPart` | Markdown 正文 | 直接展示；支持标准 `![](url)` 图片，以及 `<amap_map lat lng zoom />`、`<amap_weather … />` 自定义标签 |

深度思考与工具步骤使用同一套折叠头样式。气泡底部操作条承载版本切换 / 重新生成 / 继续回复。

### 工具配置

工具开启状态与扩展参数持久化在独立 Isar 表 `AgentToolConfigEntity`（一行一工具，`id = toolName`，`paramsJson` 为开放 Map）。运行时由 `agentToolConfigsProvider` 合并默认值并过滤 `agentToolsProvider`。

- **开关**：聊天页底部 `AgentToolPanel` 仅控制启用/禁用。
- **扩展参数**：设置 › 工具配置（`AgentToolSettingsPage`）编辑，如高德 Key。

MCP 远程工具与本地 `AgentTool` **分离**：配置在 `entities/mcp_server`，连接与调用在 `features/mcp`，设置页为「MCP 服务器」。聊天页底部 MCP 面板（`McpToolPanel`）只读 `mcpDiscoveredToolsProvider`（与设置页同源、不混入本地工具），仅控制单个远程工具启用/禁用；打开时若列表为空会再 `syncEnabledServers`。`ChatService` 将 `mcpToolsProvider` 的定义一并发给模型；执行时 `mcp__{serverId}__{tool}` 走 `McpToolRunner`，其余走本地 `AgentTool`。

展示位置工具 `show_location_map`：AI 传入坐标后返回不含 key 的 `markdown` 标签；UI 渲染时从该工具的 `params.amapKey` 拼高德静态地图 URL。密钥不进入会话与工具结果。

展示天气工具 `show_weather`：按城市 adcode 调用高德 `v3/weather/weatherInfo` 查询实况；成功后返回不含 key 的 `markdown` 标签（`<amap_weather … />`），模型须原样写入正文，UI 直接渲染天气卡片。本工具的 `params.amapKey` 与其他高德工具独立配置。

逆地理编码工具 `reverse_geocode`：调用高德 `v3/geocode/regeo`，将经纬度转为结构化地址；`extensions=base` 仅基础地址，`extensions=all` 额外返回附近 POI/AOI。本工具的 `params.amapKey` 与 `show_location_map` 独立配置，互不共用。

生成图片工具 `generate_image`：调用 OpenAI 兼容 Images API（`LlmClient.createImage` → `OpenAIClient.images.generate`）。本地 `AiModelEntity` 需在供应商详情标注 `outputFormats` 含 `image`；工具设置 `params.imageModelId` 从这类模型中选择（存实体 id）。运行时用该实体的 API `model` 调接口，API Key / Base URL 取自**该模型所属供应商**。成功时返回可展示的 `url`（及兼容用的 `markdown`）；响应优先使用远端 `url`，若仅有 `b64_json` 则落盘并以 `file://` 返回。

**图片模式（创建图片插件）**：输入框键入 `@` 弹出插件菜单，选择「创建图片」后插入并高亮**当前语言**的路由关键字（`@` + `main.input.createImagePlugin`，如中文 `@创建图片`、英文 `@Create image`；`nf_extended_text_field`）。发送时：

1. 若正文包含任一已支持语言的路由关键字则走图片路径；否则普通对话。
2. 发送前校验已配置 `imageModelId`，否则 toast 拦截。
3. **不请求聊天模型、不使用 `tool_choice`**；直接 `GenerateImageTool` → `createImage` → `images.generate`。
4. 从正文 `strip` 掉路由关键字后的剩余文本作为图像 prompt；用户气泡仍完整展示含关键字的原文（关键字蓝色高亮）。
5. 写入 `ChatImagePart`（`generating` 为「正在创建图片」占位卡，再 `ready`/`failed`）。

未含关键字时，聊天模型仍可在 `toolChoice: auto` 下调用 `generate_image`；成功同样注入 `ChatImagePart`。

### 其他角色

- 用户：纯文本 `content`
- 记忆：解码后的记忆摘要 / 事实

## 端到端时序（流式 + 工具）

```text
用户
  │  sendMessage
  ▼
Chat provider
  │  保存 user，isSending=true
  ▼
ChatService.createCompletionStream
  │
  ├─ Round 1 流式
  │    yield assistant{ Reasoning₁ , Text₁? }
  │    UI：深度思考自动展开
  │
  ├─ Round 1 需要工具
  │    yield … + ToolCall(running)     ← 进度指示
  │    本地名 → AgentTool.run
  │    mcp__* → McpToolRunner.callTool（features/mcp，与 AgentTool 分离）
  │    yield … + ToolCall(completed)   ← Reasoning₁ 仍在 parts 中
  │
  ├─ Round 2 流式
  │    yield … + Reasoning₂? + Text₂
  │    UI：同一气泡内继续追加
  │
  └─ 结束
       Chat 落库 assistant
       可选更新记忆
       isSending=false → 思考自动收起
```

下一轮用户提问时，历史助手 turn 经 `expandConversationMessageToLlm` 还原为 tool 轮次再请求模型。

## 关键文件索引

| 路径 | 说明 |
| --- | --- |
| `lib/features/chat/provider/chat/chat.dart` | 发送、中止、状态与落库时机 |
| `lib/features/chat/service/chat/chat_service.dart` | completion / stream / 工具循环 / parts 组装 |
| `lib/features/chat/service/chat_llm_message_mapper.dart` | 历史消息 → 领域 LLM 请求展开（含工具回放） |
| `lib/features/agent/api/llm_client.dart` | LLM 传输层 Port（含 `createImage`） |
| `lib/features/agent/api/openai_compatible_llm_client.dart` | OpenAI 兼容 adapter（按 `apiMode` 分支 Completions / Responses；与 mapper 为唯一允许依赖 `openai_dart` 处） |
| `lib/features/agent/api/openai_responses_mapper.dart` | Responses 请求/流式/retrieve 映射 |
| `lib/features/agent/api/openai_llm_mapper.dart` | 领域 DTO ↔ openai_dart |
| `lib/features/agent/model/llm_image_*.dart` | Images API 领域请求/响应 |
| `lib/features/agent_tools/service/generate_image_tool.dart` | `generate_image` 工具（`images.generate`） |
| `lib/entities/chat/model/chat_message_part.dart` | parts 模型（含 `ChatImagePart`） |
| `lib/widgets/agent_chat/ui/agent_chat_image_part_block.dart` | 助手气泡图片卡片 / 分享 |
| `lib/pages/main/widget/main_chat_input.dart` | 输入栏 `@` 插件菜单 + ExtendedTextField |
| `lib/features/chat/model/chat_create_image_mention.dart` | 国际化路由关键字检测与 strip |
| `lib/features/agent_tools/service/agent_tool.dart` 等 | `AgentTool` 实现 |
| `lib/features/mcp/` | MCP Client（连接、远程工具目录、callTool） |
| `lib/features/agent/model/llm_*.dart` | LLM 协议 DTO（编排与 api 共用） |
| `lib/features/agent_tools/model/amap_*.dart` | 高德 markdown tag / URL 辅助（展示与工具共用） |
| `lib/features/manage_ai_provider/` | 供应商 / 模型 CRUD 与远程模型拉取 |
| `lib/features/manage_character/` | 角色 CRUD、收藏与删除级联清理关联会话 |
| `lib/features/transfer_character/` | SillyTavern 角色卡 JSON/PNG 文件导入 |
| `lib/features/chat/service/character_prompt_builder.dart` | 角色卡渲染为角色会话系统提示词 |
| `lib/features/chat/service/character_book_resolver.dart` | 多本世界书关键词匹配与 before/after 注入文本 |
| `lib/entities/character/` | 角色静态人设与绑定 id |
| `lib/entities/world_book/` | 独立世界书 / 条目模型与 Isar 仓库 |
| `lib/features/agent_tools/provider/agent_tools.dart` | 本地工具目录、配置 provider、启用过滤 |
| `lib/entities/agent_tool/` | 本地工具配置 Isar 实体与仓库 |
| `lib/entities/mcp_server/` | MCP Server 配置 Isar 实体与仓库 |
| `lib/pages/mcp_settings/` | MCP 服务器设置页 |
| `lib/entities/chat/model/chat_conversation_message.dart` | 会话消息 |
| `lib/entities/chat/model/chat_message_part.dart` | parts 类型 |
| `lib/entities/chat/helper/chat_message_part_codec.dart` | parts JSON |
| `lib/entities/chat/chat_message_entity.dart` | Isar 实体 |
| `lib/widgets/agent_chat/ui/agent_chat_message_list.dart` | 列表与过滤 |
| `lib/widgets/agent_chat/ui/agent_assistant_chat_message_tile.dart` | 助手时间线 |
| `lib/widgets/agent_chat/ui/agent_chat_tool_call_part_block.dart` | 工具步骤 UI |
| `lib/widgets/agent_chat/ui/agent_chat_message_shared.dart` | 气泡、折叠头、思考块、Markdown |
| `test/chat_llm_message_mapper_test.dart` | 工具轮次回放单测 |

## 约束摘要

1. 助手展示唯一来源是 `parts`，禁止再从扁平字段合成思考/工具 UI。
2. 新写入的助手消息必须带完整 `parts`；`content` 只做派生摘要。
3. 历史 API 回放必须走 `expandConversationMessageToLlm`，不得只发扁平 `content` 而丢掉工具轮次。
4. 不做旧数据兼容与迁移回退（见 `AGENTS.md` First Principles）；已移除独立 `tool` 消息角色。
5. 应用级 Toast 使用 `SmartDialog`；聊天列表变更检测需覆盖 parts 流式更新。
6. 架构或本流程变更时，同步更新本文与 `architecture.md` 中的 Chat 消息模型章节。
