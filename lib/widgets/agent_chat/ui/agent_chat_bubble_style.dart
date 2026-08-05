import 'package:flutter/material.dart';

/// 角色会话消息气泡表面样式。
class AgentChatBubbleStyle extends InheritedWidget {
  const AgentChatBubbleStyle({
    required this.isCharacterChat,
    required this.bubbleFill,
    required super.child,
    super.key,
  });

  /// 是否为角色会话。
  final bool isCharacterChat;

  /// 已含透明度的气泡填充色；`null` 表示使用默认主题色。
  final Color? bubbleFill;

  static AgentChatBubbleStyle? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AgentChatBubbleStyle>();
  }

  static bool isCharacterChatOf(BuildContext context) {
    return maybeOf(context)?.isCharacterChat ?? false;
  }

  static Color? bubbleFillOf(BuildContext context) {
    return maybeOf(context)?.bubbleFill;
  }

  @override
  bool updateShouldNotify(AgentChatBubbleStyle oldWidget) {
    return isCharacterChat != oldWidget.isCharacterChat ||
        bubbleFill != oldWidget.bubbleFill;
  }
}
