import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/provider/app_preferences_provider.dart';
import 'package:soulcast/shared/theme/app_ui.dart';

/// 应用语言选择页。
class LanguagePage extends ConsumerWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = context.t;
    final selectedLocale = ref.watch(
      appPreferencesProvider.select((state) => state.locale),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          translations.language.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemBuilder: (context, index) {
            final option = appLanguageOptions[index];
            return LanguageOptionTile(
              option: option,
              isSelected: option.locale == selectedLocale,
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemCount: appLanguageOptions.length,
        ),
      ),
    );
  }
}

/// 单个语言选项及当前选中状态。
class LanguageOptionTile extends ConsumerWidget {
  const LanguageOptionTile({
    required this.option,
    required this.isSelected,
    super.key,
  });

  final AppLanguageOption option;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = context.t;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        onTap: () {
          ref.read(appPreferencesProvider.notifier).selectLocale(option.locale);
        },
        leading: Icon(
          Icons.translate_rounded,
          color: isSelected
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
        ),
        title: Text(
          option.localizedName(translations),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          option.localizedName(translations) == option.nativeName
              ? translations.language.current
              : option.nativeName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: isSelected
            ? Semantics(
                label: translations.language.selected,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: colorScheme.primary,
                ),
              )
            : null,
      ),
    );
  }
}
