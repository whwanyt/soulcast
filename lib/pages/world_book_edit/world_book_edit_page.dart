import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/app/router/app_router.dart';
import 'package:soulcast/entities/world_book/world_book.dart';
import 'package:soulcast/features/manage_world_book/manage_world_book.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/theme/app_ui.dart';
import 'package:soulcast/shared/widgets/app_text_field.dart';

/// 世界书元数据编辑 + 条目列表（点条目进独立编辑页）。
class WorldBookEditPage extends ConsumerStatefulWidget {
  const WorldBookEditPage({this.worldBookId, super.key});

  final String? worldBookId;

  @override
  ConsumerState<WorldBookEditPage> createState() => _WorldBookEditPageState();
}

class _WorldBookEditPageState extends ConsumerState<WorldBookEditPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _scanDepthController = TextEditingController(text: '50');
  final _tokenBudgetController = TextEditingController(text: '2000');
  var _recursiveScanning = false;
  var _initialized = false;
  var _isSaving = false;
  String? _worldBookId;

  @override
  void initState() {
    super.initState();
    _worldBookId = widget.worldBookId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _scanDepthController.dispose();
    _tokenBudgetController.dispose();
    super.dispose();
  }

  void _syncFromBook(WorldBookEntity book) {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _worldBookId = book.id;
    _nameController.text = book.name;
    _descriptionController.text = book.description;
    _scanDepthController.text = '${book.scanDepth}';
    _tokenBudgetController.text = '${book.tokenBudget}';
    _recursiveScanning = book.recursiveScanning;
  }

  @override
  Widget build(BuildContext context) {
    final translations = context.t.worldBookEdit;
    final worldBookId = _worldBookId;
    final booksAsync = ref.watch(worldBooksProvider);
    if (worldBookId != null) {
      booksAsync.whenData((books) {
        for (final book in books) {
          if (book.id == worldBookId) {
            _syncFromBook(book);
            break;
          }
        }
      });
    } else {
      _initialized = true;
    }

    final entriesAsync = worldBookId == null
        ? const AsyncValue<List<WorldBookEntryEntity>>.data([])
        : ref.watch(worldBookEntriesProvider(worldBookId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          worldBookId == null
              ? translations.createTitle
              : translations.editTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (worldBookId != null)
            IconButton(
              tooltip: translations.addEntry,
              onPressed: _isSaving
                  ? null
                  : () => WorldBookEntryEditRoute(
                      worldBookId: worldBookId,
                    ).push(context),
              icon: const Icon(LucideIcons.plus),
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
                  hintText: translations.nameHint,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _descriptionController,
                  enabled: !_isSaving,
                  minLines: 2,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  labelText: translations.descriptionLabel,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _scanDepthController,
                  enabled: !_isSaving,
                  keyboardType: TextInputType.number,
                  labelText: translations.scanDepthLabel,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _tokenBudgetController,
                  enabled: !_isSaving,
                  keyboardType: TextInputType.number,
                  labelText: translations.tokenBudgetLabel,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    translations.recursiveScanning,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  value: _recursiveScanning,
                  onChanged: _isSaving
                      ? null
                      : (value) => setState(() => _recursiveScanning = value),
                ),
                const SizedBox(height: 8),
                Text(
                  translations.entriesSection,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                if (worldBookId == null)
                  Text(
                    translations.saveFirstForEntries,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  entriesAsync.when(
                    data: (entries) {
                      if (entries.isEmpty) {
                        return Text(
                          translations.emptyEntries,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        );
                      }
                      return Column(
                        children: [
                          for (final entry in entries)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                entry.name.trim().isEmpty
                                    ? (entry.keys.isEmpty
                                          ? translations.untitledEntry
                                          : entry.keys.join(', '))
                                    : entry.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                entry.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: const Icon(LucideIcons.chevronRight),
                              onTap: () => WorldBookEntryEditRoute(
                                worldBookId: worldBookId,
                                entryId: entry.id,
                              ).push(context),
                            ),
                        ],
                      );
                    },
                    loading: () => const LinearProgressIndicator(minHeight: 2),
                    error: (error, _) => Text(
                      '$error',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
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
                  child: Text(
                    translations.save,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final translations = context.t.worldBookEdit;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      SmartDialog.showToast(translations.nameRequired);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final book = await ref
          .read(manageWorldBookServiceProvider)
          .saveWorldBook(
            worldBookId: _worldBookId,
            name: name,
            description: _descriptionController.text,
            scanDepth: int.tryParse(_scanDepthController.text.trim()) ?? 50,
            tokenBudget:
                int.tryParse(_tokenBudgetController.text.trim()) ?? 2000,
            recursiveScanning: _recursiveScanning,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _worldBookId = book.id;
        _initialized = true;
      });
      SmartDialog.showToast(translations.saved);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
