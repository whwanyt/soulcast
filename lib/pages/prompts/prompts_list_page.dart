import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/app/router/app_router.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/prompt/prompt.dart';
import 'package:soulcast/shared/theme/app_ui.dart';
import 'package:soulcast/shared/widgets/settings/settings.dart';

/// 可配置提示词列表页。
class PromptsListPage extends StatelessWidget {
  const PromptsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerLow,
        title: Text(
          translations.prompts.listTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.md,
            AppSpacing.page,
            AppSpacing.xxl,
          ),
          children: [
            SettingsGroup(
              children: [
                for (final id in PromptId.listOrder)
                  SettingsListTile(
                    onTap: () =>
                        PromptEditRoute(promptId: id.storageKey).push(context),
                    leading: LucideIcons.filePenLine,
                    title: promptListTitle(translations, id),
                    subtitle: promptListSubtitle(translations, id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
