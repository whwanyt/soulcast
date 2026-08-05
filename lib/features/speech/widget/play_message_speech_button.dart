import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/i18n/strings.g.dart';

import '../provider/speech_output.dart';

/// 播放或停止一条聊天消息的语音输出动作。
class PlayMessageSpeechButton extends ConsumerWidget {
  const PlayMessageSpeechButton({
    super.key,
    required this.messageId,
    required this.text,
    this.color,
  });

  final String messageId;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trimmedText = text.trim();
    final speechOutput = ref.watch(speechOutputProvider);
    final isPlaying = speechOutput.isPlayingMessage(messageId);
    final translations = context.t.chat;

    return IconButton(
      onPressed: trimmedText.isEmpty
          ? null
          : () {
              ref
                  .read(speechOutputProvider.notifier)
                  .toggle(messageId: messageId, text: trimmedText);
            },
      tooltip: isPlaying ? translations.stopPlayback : translations.play,
      style: IconButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.all(4),
        minimumSize: const Size(36, 36),
        maximumSize: const Size(36, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(
        isPlaying ? LucideIcons.square : LucideIcons.volume2,
        size: 18,
      ),
    );
  }
}
