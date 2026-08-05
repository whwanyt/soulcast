import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/provider/app_preferences_provider.dart';
import 'package:soulcast/shared/theme/app_ui.dart';

/// 控制工具调用消息和记忆消息可见性的设置页。
class MessageDisplaySettingsPage extends ConsumerWidget {
  const MessageDisplaySettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = context.t.messageDisplaySettings;
    final showToolMessages = ref.watch(
      appPreferencesProvider.select((state) => state.showToolMessages),
    );
    final showMemoryMessages = ref.watch(
      appPreferencesProvider.select((state) => state.showMemoryMessages),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          translations.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            MessageDisplaySwitchTile(
              title: translations.toolMessages,
              value: showToolMessages,
              onChanged: (value) {
                ref
                    .read(appPreferencesProvider.notifier)
                    .saveShowToolMessages(value);
              },
            ),
            const SizedBox(height: 10),
            MessageDisplaySwitchTile(
              title: translations.memoryMessages,
              value: showMemoryMessages,
              onChanged: (value) {
                ref
                    .read(appPreferencesProvider.notifier)
                    .saveShowMemoryMessages(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 消息类型显示开关行。
class MessageDisplaySwitchTile extends StatelessWidget {
  const MessageDisplaySwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadii.md),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
