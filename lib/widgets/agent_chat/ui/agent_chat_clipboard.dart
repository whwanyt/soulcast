import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/i18n/strings.g.dart';

/// 将文本写入剪贴板并弹出统一 toast。
Future<void> agentChatCopyTextToClipboard(
  BuildContext context,
  String text,
) async {
  if (text.isEmpty) {
    return;
  }
  final copiedMessage = context.t.chat.copied;
  await Clipboard.setData(ClipboardData(text: text));
  await SmartDialog.showToast(copiedMessage);
}

/// 块级内容右上角使用的紧凑复制按钮。
class AgentChatCopyIconButton extends StatelessWidget {
  const AgentChatCopyIconButton({
    super.key,
    required this.text,
    this.color,
    this.tooltip,
  });

  final String text;
  final Color? color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final canCopy = text.isNotEmpty;
    return IconButton(
      onPressed: canCopy
          ? () => agentChatCopyTextToClipboard(context, text)
          : null,
      tooltip: tooltip ?? context.t.chat.copy,
      style: IconButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.all(4),
        minimumSize: const Size(28, 28),
        maximumSize: const Size(28, 28),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      icon: const Icon(LucideIcons.copy, size: 14),
    );
  }
}
