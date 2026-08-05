import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/i18n/strings.g.dart';

/// 输入区圆形按钮的统一尺寸。
const mainChatInputButtonSize = 36.0;

/// 输入区左侧的通用圆形图标按钮（加号、工具、MCP、模型等）。
class MainChatInputActionButton extends StatelessWidget {
  const MainChatInputActionButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: mainChatInputButtonSize,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          color: colorScheme.onSurfaceVariant,
          disabledColor: colorScheme.onSurface.withValues(alpha: 0.28),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            backgroundColor: Colors.transparent,
            shape: const CircleBorder(),
          ),
          constraints: const BoxConstraints.tightFor(
            width: mainChatInputButtonSize,
            height: mainChatInputButtonSize,
          ),
        ),
      ),
    );
  }
}

/// 输入区的语音输入开关按钮。
class MainChatInputVoiceButton extends StatelessWidget {
  const MainChatInputVoiceButton({
    super.key,
    required this.isListening,
    required this.enabled,
    required this.onPressed,
  });

  final bool isListening;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: isListening
          ? context.t.main.input.voiceStop
          : context.t.main.input.voice,
      child: SizedBox.square(
        dimension: mainChatInputButtonSize,
        child: IconButton(
          onPressed: enabled ? onPressed : null,
          icon: Icon(
            isListening ? LucideIcons.micOff : LucideIcons.mic,
            size: 18,
          ),
          color: isListening
              ? colorScheme.onPrimary
              : colorScheme.onSurfaceVariant,
          disabledColor: colorScheme.onSurface.withValues(alpha: 0.28),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            backgroundColor: isListening
                ? colorScheme.primary
                : Colors.transparent,
            shape: const CircleBorder(),
          ),
          constraints: const BoxConstraints.tightFor(
            width: mainChatInputButtonSize,
            height: mainChatInputButtonSize,
          ),
        ),
      ),
    );
  }
}

/// 输入区的发送按钮。
class MainChatInputSendButton extends StatelessWidget {
  const MainChatInputSendButton({
    super.key,
    required this.onPressed,
    required this.canSubmit,
  });

  final VoidCallback onPressed;
  final bool canSubmit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: context.t.main.input.send,
      child: AnimatedScale(
        scale: canSubmit ? 1 : 0.96,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: SizedBox.square(
          dimension: mainChatInputButtonSize,
          child: FilledButton(
            onPressed: canSubmit ? onPressed : null,
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              disabledBackgroundColor: colorScheme.onSurface.withValues(
                alpha: 0.1,
              ),
              disabledForegroundColor: colorScheme.onSurface.withValues(
                alpha: 0.32,
              ),
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
              minimumSize: const Size.square(mainChatInputButtonSize),
              fixedSize: const Size.square(mainChatInputButtonSize),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Icon(LucideIcons.arrowUp, size: 18),
          ),
        ),
      ),
    );
  }
}

/// 输入区的停止生成按钮。
class MainChatInputStopButton extends StatelessWidget {
  const MainChatInputStopButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: context.t.main.input.stop,
      child: SizedBox.square(
        dimension: mainChatInputButtonSize,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
            minimumSize: const Size.square(mainChatInputButtonSize),
            fixedSize: const Size.square(mainChatInputButtonSize),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Icon(LucideIcons.square, size: 14),
        ),
      ),
    );
  }
}
