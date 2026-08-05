import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/theme/app_ui.dart';

/// 聊天附件入口。
enum MainChatAttachAction { images, fileLibrary, documents }

/// 弹出聊天附件三入口底部面板。
Future<MainChatAttachAction?> showMainChatAttachSheet(BuildContext context) {
  return showModalBottomSheet<MainChatAttachAction>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return const MainChatAttachSheet();
    },
  );
}

/// 横排三个大入口：图片 / 文件库 / 上传附件。
class MainChatAttachSheet extends StatelessWidget {
  const MainChatAttachSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final translations = context.t.main.input.attach;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            translations.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MainChatAttachEntry(
                  icon: LucideIcons.image,
                  label: translations.images,
                  onTap: () =>
                      Navigator.of(context).pop(MainChatAttachAction.images),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MainChatAttachEntry(
                  icon: LucideIcons.folderOpen,
                  label: translations.fileLibrary,
                  onTap: () => Navigator.of(
                    context,
                  ).pop(MainChatAttachAction.fileLibrary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MainChatAttachEntry(
                  icon: LucideIcons.paperclip,
                  label: translations.documents,
                  onTap: () =>
                      Navigator.of(context).pop(MainChatAttachAction.documents),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MainChatAttachEntry extends StatelessWidget {
  const _MainChatAttachEntry({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: SizedBox(
          height: 76,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 28, color: colorScheme.primary),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
