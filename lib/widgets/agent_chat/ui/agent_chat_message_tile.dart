import 'package:flutter/material.dart';
import 'package:soulcast/entities/chat/chat.dart';

import 'agent_assistant_chat_message_tile.dart';
import 'agent_memory_chat_message_tile.dart';
import 'agent_user_chat_message_tile.dart';

/// 按消息角色分派到用户、助手或记忆消息组件。
class AgentChatMessageTile extends StatelessWidget {
  const AgentChatMessageTile({
    super.key,
    required this.message,
    this.showToolMessages = true,
    this.isActiveTurn = false,
    this.showContinueReply = false,
    this.onContinueReply,
    this.showRegenerate = false,
    this.onRegenerate,
    this.onSelectPreviousVersion,
    this.onSelectNextVersion,
  });

  final ChatConversationMessage message;
  final bool showToolMessages;
  final bool isActiveTurn;
  final bool showContinueReply;
  final VoidCallback? onContinueReply;
  final bool showRegenerate;
  final VoidCallback? onRegenerate;
  final VoidCallback? onSelectPreviousVersion;
  final VoidCallback? onSelectNextVersion;

  @override
  Widget build(BuildContext context) {
    return switch (message.role) {
      ChatConversationRole.user => AgentUserChatMessageTile(message: message),
      ChatConversationRole.assistant => AgentAssistantChatMessageTile(
        message: message,
        showToolMessages: showToolMessages,
        isActiveTurn: isActiveTurn,
        showContinueReply: showContinueReply,
        onContinueReply: onContinueReply,
        showRegenerate: showRegenerate,
        onRegenerate: onRegenerate,
        onSelectPreviousVersion: onSelectPreviousVersion,
        onSelectNextVersion: onSelectNextVersion,
      ),
      ChatConversationRole.memory => AgentMemoryChatMessageTile(
        message: message,
      ),
    };
  }
}
