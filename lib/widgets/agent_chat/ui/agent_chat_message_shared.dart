import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/theme/app_ui.dart';
import 'agent_chat_bubble_style.dart';
import 'agent_chat_markdown.dart';

export 'agent_chat_markdown.dart';

const agentChatAssistantMessageBackground = Color(0x00FFFFFF);

/// 角色会话下按主色亮度选择可读的正文/标签色。
AgentChatMessageTileConfig resolveAgentChatMessageConfig(
  BuildContext context,
  AgentChatMessageTileConfig config,
) {
  final fill = AgentChatBubbleStyle.bubbleFillOf(context);
  if (fill == null) {
    return config;
  }

  // 暗色底上标签原先过淡，需更贴近正文；亮色底保持次级对比。
  final isLightFill = fill.computeLuminance() > 0.55;
  final onBubble = isLightFill
      ? const Color(0xE6000000)
      : const Color(0xF2FFFFFF);
  final onBubbleMuted = isLightFill
      ? const Color(0x99000000)
      : const Color(0xE6FFFFFF);

  return AgentChatMessageTileConfig(
    label: config.label,
    icon: config.icon,
    backgroundColor: fill,
    contentColor: onBubble,
    labelColor: onBubbleMuted,
  );
}

/// 不同消息角色共用的气泡视觉配置。
class AgentChatMessageTileConfig {
  const AgentChatMessageTileConfig({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.contentColor,
    required this.labelColor,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color contentColor;
  final Color labelColor;
}

/// 生成消息正文的统一文本样式。
TextStyle? agentChatMessageContentStyle(
  ThemeData theme,
  AgentChatMessageTileConfig config,
) {
  return theme.textTheme.bodyLarge?.copyWith(
    color: config.contentColor,
    height: 1.5,
    letterSpacing: -0.1,
  );
}

/// 生成推理内容的统一文本样式。
TextStyle? agentChatMessageReasoningStyle(
  ThemeData theme,
  AgentChatMessageTileConfig config,
) {
  return theme.textTheme.bodyMedium?.copyWith(
    color: config.labelColor,
    height: 1.45,
  );
}

/// 约束消息宽度并按角色对齐的通用气泡容器。
class AgentChatMessageBubble extends StatelessWidget {
  const AgentChatMessageBubble({
    super.key,
    required this.isUser,
    required this.config,
    required this.child,
  });

  final bool isUser;
  final AgentChatMessageTileConfig config;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * (isUser ? 0.82 : 0.94),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: config.backgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppRadii.lg),
                topRight: const Radius.circular(AppRadii.lg),
                bottomLeft: Radius.circular(isUser ? AppRadii.lg : AppRadii.xs),
                bottomRight: Radius.circular(
                  isUser ? AppRadii.xs : AppRadii.lg,
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isUser ? 14 : 4,
                isUser ? 11 : 4,
                isUser ? 14 : 4,
                isUser ? 11 : 4,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// 消息气泡顶部的角色图标与名称。
class AgentChatMessageRoleLabel extends StatelessWidget {
  const AgentChatMessageRoleLabel({super.key, required this.config});

  final AgentChatMessageTileConfig config;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(config.icon, size: 12, color: config.labelColor),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            config.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: config.labelColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
  }
}

/// 推理与工具详情共用的可折叠标题栏。
class AgentChatMessageCollapsibleHeader extends StatelessWidget {
  const AgentChatMessageCollapsibleHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.isExpanded,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Color color;
  final bool isExpanded;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: color,
      fontWeight: FontWeight.w700,
      height: 1.2,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.xs),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle,
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 6), trailing!],
              const SizedBox(width: 4),
              Icon(
                isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                size: 14,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 自动跟随生成状态展开或收起的推理内容块。
class AgentChatMessageReasoningBlock extends StatefulWidget {
  const AgentChatMessageReasoningBlock({
    super.key,
    required this.content,
    required this.style,
    this.isActive = false,
  });

  final String content;
  final TextStyle? style;

  /// 当前助手轮仍在生成时为 true：自动展开；结束后自动收起。
  final bool isActive;

  @override
  State<AgentChatMessageReasoningBlock> createState() =>
      _AgentChatMessageReasoningBlockState();
}

class _AgentChatMessageReasoningBlockState
    extends State<AgentChatMessageReasoningBlock> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isActive;
  }

  @override
  void didUpdateWidget(covariant AgentChatMessageReasoningBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _isExpanded = widget.isActive;
    }
  }

  @override
  Widget build(BuildContext context) {
    final headerColor =
        widget.style?.color ?? Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AgentChatMessageCollapsibleHeader(
          icon: LucideIcons.brainCircuit,
          title: AgentChatBubbleStyle.isCharacterChatOf(context)
              ? context.t.chat.characterReasoningTitle
              : context.t.chat.reasoningTitle,
          color: headerColor,
          isExpanded: _isExpanded,
          onTap: _toggleExpanded,
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          AgentChatMessageThemedMarkdown(
            data: widget.content,
            style: widget.style,
            textScaler: MediaQuery.textScalerOf(context),
          ),
        ],
      ],
    );
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
  }
}
