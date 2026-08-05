import 'package:flutter/material.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/widgets/app_text_field.dart';

/// 展示编辑用户昵称的底部面板，确认后返回规范化文本（空串表示清除）。
Future<String?> showSettingsUserNicknameSheet({
  required BuildContext context,
  required String initialValue,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return SettingsUserNicknameSheet(initialValue: initialValue);
    },
  );
}

/// 设置页用户昵称编辑底部面板。
class SettingsUserNicknameSheet extends StatefulWidget {
  const SettingsUserNicknameSheet({super.key, required this.initialValue});

  final String initialValue;

  @override
  State<SettingsUserNicknameSheet> createState() =>
      _SettingsUserNicknameSheetState();
}

class _SettingsUserNicknameSheetState extends State<SettingsUserNicknameSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final translations = context.t.settings;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            translations.userNicknameSheetTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _controller,
            autofocus: true,
            maxLength: 48,
            textInputAction: TextInputAction.done,
            labelText: translations.userNickname,
            hintText: translations.userNicknameHint,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(
                    context.t.common.cancel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(
                    context.t.common.save,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _save() {
    Navigator.of(context).pop(_controller.text.trim());
  }
}
