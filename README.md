<p align="center">
  <img src="assets/app_icon.png" alt="SoulCast" width="120" />
</p>

<h1 align="center">SoulCast</h1>

<p align="center">
  <strong>本地优先的 AI 对话与角色扮演客户端</strong>
</p>

<p align="center">
  自备 API Key，即可与助手聊天，或创建角色卡开启沉浸式扮演。<br />
  对话、角色与配置默认保存在本机，无需注册登录。
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter&logoColor=white" alt="Flutter" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" alt="License" /></a>
  <a href="docs/architecture.md"><img src="https://img.shields.io/badge/Architecture-FSD-7B68EE" alt="FSD" /></a>
  <img src="https://img.shields.io/badge/Platform-iOS%20%7C%20Android-lightgrey" alt="Platform" />
</p>

<p align="center">
  <a href="#特性">特性</a> ·
  <a href="#快速开始">快速开始</a> ·
  <a href="#文档">文档</a> ·
  <a href="#开发">开发</a> ·
  <a href="#贡献">贡献</a>
</p>

---

## 特性

| | |
| --- | --- |
| **本地优先** | 会话、角色卡、世界书、供应商配置等数据存于设备本地 |
| **自备模型** | 对接 OpenAI 兼容接口（Chat Completions / Responses），多供应商与多模型 |
| **角色扮演** | 角色卡（人设、场景、开场白）、世界书关键词触发、长期记忆 |
| **角色卡导入** | 支持 JSON / PNG 角色卡导入 |
| **Agent 工具** | 时间、位置、天气、地图、生图等，可按会话开关 |
| **MCP** | 连接外部 MCP 服务器，在对话中调用远程工具 |
| **本地语音** | 基于 [Sherpa-ONNX](https://github.com/k2-fsa/sherpa-onnx) 的 ASR / TTS，模型在设备本地运行 |
| **多语言与主题** | 简体中文 / English，日间 / 夜间模式 |

完整使用说明 → [入门使用教程](docs/user_guide.md)

## 技术栈

| 类别 | 选型 |
| --- | --- |
| 框架 | Flutter / Dart（[FVM](https://fvm.app/) 管理 SDK） |
| 状态 | Riverpod + `riverpod_annotation` |
| 路由 | GoRouter + `go_router_builder` |
| 模型 | Freezed + JSON serialization |
| 本地存储 | Isar |
| UI 反馈 | SmartDialog |
| 基础库 | [`packages/flute_core`](packages/flute_core) |

代码按 [Feature-Sliced Design](docs/architecture.md) 分层组织。

## 快速开始

### 环境要求

- [Flutter](https://docs.flutter.dev/get-started/install)（版本见 [`.fvmrc`](.fvmrc)）
- [FVM](https://fvm.app/)（推荐）
- iOS / Android 模拟器或真机

### 克隆与运行

```bash
git clone https://github.com/whwanyt/soulcast.git
cd soulcast

fvm install
fvm flutter pub get
fvm dart run build_runner build
fvm flutter run
```

> 首次使用请在应用内配置 AI 供应商与模型：**设置 → 供应商配置**。详见 [入门使用教程](docs/user_guide.md)。

## 文档

| 文档 | 说明 |
| --- | --- |
| [入门使用教程](docs/user_guide.md) | 初始化、配置、普通对话与角色扮演 |
| [FSD 架构约束](docs/architecture.md) | 分层、依赖方向、目录落位 |
| [消息收发与展示全流程](docs/chat_message_flow.md) | 发送编排、工具循环、持久化与 UI |
| [文档索引](docs/README.md) | 全部文档入口 |
| [Agent 协作规范](AGENTS.md) | 面向自动化 agent 与协作者的规则 |

## 项目结构

```text
lib/
├── app/         # 启动、全局 provider、路由、主题
├── pages/       # 路由页面与页面组合
├── widgets/     # 跨页面业务展示块
├── features/    # 用户动作与业务流程
├── entities/    # 业务实体与数据源
├── shared/      # 无业务语义的基础设施与通用 UI
├── i18n/        # 多语言资源
└── main.dart
```

依赖方向：

```text
app → pages → widgets → features → entities → shared
```

细则见 [docs/architecture.md](docs/architecture.md)。

## 开发

```bash
# 安装依赖
fvm flutter pub get

# 代码生成（注解 / Freezed / 路由 / i18n 变更后）
fvm dart run build_runner build

# 格式化与静态检查
fvm dart format lib test
fvm dart analyze

# 测试
fvm flutter test
```

> 禁止手动修改生成文件：`*.g.dart`、`*.freezed.dart`、`lib/i18n/strings*.g.dart`。

## 贡献

欢迎 Issue 与 Pull Request。提交前请：

1. 阅读 [AGENTS.md](AGENTS.md) 与 [架构文档](docs/architecture.md)
2. 保持小步、可验证的改动；架构变更请同步更新文档
3. 至少通过 `fvm dart format lib test` 与 `fvm dart analyze`

提交信息格式：

```text
<type>(模块): 中文描述
```

`type`：`feat` · `fix` · `update` · `docs` · `refactor` · `chore`

## License

[Apache License 2.0](LICENSE)
