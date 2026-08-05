# Lumiscene Docs

这里集中维护项目文档。新增架构约束、协作规则或开发流程时，应先更新对应文档，再调整代码。

## Documents

- [入门使用教程](user_guide.md)：从产品使用角度介绍初始化、基础配置、普通 AI 对话与角色扮演。
- [FSD Architecture](architecture.md)：项目分层、依赖方向、目录落位、Riverpod 和 UI 约束。
- [消息收发与展示全流程](chat_message_flow.md)：发送编排、工具循环、parts 时间线、持久化与 UI 展示。
- [Agent Guide](../AGENTS.md)：面向自动化编码 agent 和协作开发者的工作规则。
- [Project README](../README.md)：开源项目介绍、特性、快速开始与贡献说明。

## Maintenance Rules

- 架构规则变更必须更新 `architecture.md`。
- agent 行为、提交、验证、生成文件规则变更必须更新 `AGENTS.md`。
- 项目入口说明、常用命令、文档索引变更必须更新根目录 `README.md`。
- 文档中的目录和命令必须与当前项目实际结构保持一致。
- 项目明确不做旧数据 / 旧格式兼容；相关约束见 `AGENTS.md` 与 `architecture.md` 的 Chat 消息模型章节。
