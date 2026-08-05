import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/entities/world_book/world_book.dart';
import 'package:soulcast/features/manage_world_book/manage_world_book.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/theme/app_ui.dart';
import 'package:soulcast/shared/widgets/app_text_field.dart';

/// 单条世界书条目编辑页。
class WorldBookEntryEditPage extends ConsumerStatefulWidget {
  const WorldBookEntryEditPage({
    required this.worldBookId,
    this.entryId,
    super.key,
  });

  final String worldBookId;
  final String? entryId;

  @override
  ConsumerState<WorldBookEntryEditPage> createState() =>
      _WorldBookEntryEditPageState();
}

class _WorldBookEntryEditPageState
    extends ConsumerState<WorldBookEntryEditPage> {
  final _nameController = TextEditingController();
  final _keysController = TextEditingController();
  final _secondaryKeysController = TextEditingController();
  final _contentController = TextEditingController();
  final _priorityController = TextEditingController(text: '10');
  final _orderController = TextEditingController(text: '100');
  var _enabled = true;
  var _constant = false;
  var _selective = false;
  var _position = WorldBookPosition.beforeChar;
  var _initialized = false;
  var _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _keysController.dispose();
    _secondaryKeysController.dispose();
    _contentController.dispose();
    _priorityController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  void _syncFromEntry(WorldBookEntryEntity entry) {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _nameController.text = entry.name;
    _keysController.text = entry.keys.join(', ');
    _secondaryKeysController.text = entry.secondaryKeys.join(', ');
    _contentController.text = entry.content;
    _priorityController.text = '${entry.priority}';
    _orderController.text = '${entry.insertionOrder}';
    _enabled = entry.enabled;
    _constant = entry.constant;
    _selective = entry.selective;
    _position = entry.position == 'after_char'
        ? WorldBookPosition.afterChar
        : WorldBookPosition.beforeChar;
  }

  @override
  Widget build(BuildContext context) {
    final translations = context.t.worldBookEntryEdit;
    final entryId = widget.entryId;
    if (entryId != null) {
      final entriesAsync = ref.watch(
        worldBookEntriesProvider(widget.worldBookId),
      );
      entriesAsync.whenData((entries) {
        for (final entry in entries) {
          if (entry.id == entryId) {
            _syncFromEntry(entry);
            break;
          }
        }
      });
    } else {
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          entryId == null ? translations.createTitle : translations.editTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (entryId != null)
            IconButton(
              tooltip: translations.delete,
              onPressed: _isSaving ? null : _delete,
              icon: const Icon(LucideIcons.trash2),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isSaving) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.md,
                AppSpacing.page,
                24,
              ),
              children: [
                AppTextField(
                  controller: _nameController,
                  enabled: !_isSaving,
                  labelText: translations.nameLabel,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _keysController,
                  enabled: !_isSaving,
                  labelText: translations.keysLabel,
                  hintText: translations.keysHint,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _secondaryKeysController,
                  enabled: !_isSaving,
                  labelText: translations.secondaryKeysLabel,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _contentController,
                  enabled: !_isSaving,
                  minLines: 4,
                  maxLines: 12,
                  textInputAction: TextInputAction.newline,
                  labelText: translations.contentLabel,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(translations.enabled),
                  value: _enabled,
                  onChanged: _isSaving
                      ? null
                      : (value) => setState(() => _enabled = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(translations.constant),
                  value: _constant,
                  onChanged: _isSaving
                      ? null
                      : (value) => setState(() => _constant = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(translations.selective),
                  value: _selective,
                  onChanged: _isSaving
                      ? null
                      : (value) => setState(() => _selective = value),
                ),
                SegmentedButton<WorldBookPosition>(
                  segments: [
                    ButtonSegment(
                      value: WorldBookPosition.beforeChar,
                      label: Text(translations.positionBefore),
                    ),
                    ButtonSegment(
                      value: WorldBookPosition.afterChar,
                      label: Text(translations.positionAfter),
                    ),
                  ],
                  selected: {_position},
                  onSelectionChanged: _isSaving
                      ? null
                      : (values) => setState(() => _position = values.first),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _priorityController,
                        enabled: !_isSaving,
                        keyboardType: TextInputType.number,
                        labelText: translations.priorityLabel,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _orderController,
                        enabled: !_isSaving,
                        keyboardType: TextInputType.number,
                        labelText: translations.orderLabel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                8,
                AppSpacing.page,
                12,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: Text(translations.save),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _splitCsv(String source) {
    return source
        .split(RegExp(r'[,，]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _save() async {
    final translations = context.t.worldBookEntryEdit;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(manageWorldBookServiceProvider)
          .saveEntry(
            WorldBookEntry(
              id: widget.entryId ?? '',
              worldBookId: widget.worldBookId,
              name: _nameController.text.trim(),
              keys: _splitCsv(_keysController.text),
              secondaryKeys: _splitCsv(_secondaryKeysController.text),
              content: _contentController.text,
              enabled: _enabled,
              constant: _constant,
              selective: _selective,
              insertionOrder: int.tryParse(_orderController.text.trim()) ?? 100,
              priority: int.tryParse(_priorityController.text.trim()) ?? 10,
              position: _position,
            ),
          );
      if (!mounted) {
        return;
      }
      SmartDialog.showToast(translations.saved);
      Navigator.of(context).maybePop();
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _delete() async {
    final entryId = widget.entryId;
    if (entryId == null) {
      return;
    }
    final translations = context.t.worldBookEntryEdit;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(translations.deleteTitle),
          content: Text(translations.deleteMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.t.common.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.t.common.delete),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    await ref.read(manageWorldBookServiceProvider).deleteEntry(entryId);
    if (!mounted) {
      return;
    }
    SmartDialog.showToast(translations.deleted);
    Navigator.of(context).maybePop();
  }
}
