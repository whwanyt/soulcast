part of '../chat_info_page.dart';

/// 组合会话基础设置与长期事实编辑，并统一提交变更。
class ChatInfoPageEditor extends StatefulWidget {
  const ChatInfoPageEditor({
    super.key,
    required this.conversationTitle,
    required this.conversationSystemPrompt,
    required this.appSystemPrompt,
    required this.worldBooksSummary,
    required this.memory,
    required this.isSaving,
    required this.onSave,
    required this.onSystemPromptSave,
    required this.onWorldBooksEdited,
    required this.onConversationClear,
    this.character,
    this.onEditCharacter,
  });

  final String conversationTitle;
  final String? conversationSystemPrompt;
  final String appSystemPrompt;
  final String worldBooksSummary;
  final ChatConversationMemory memory;
  final bool isSaving;
  final CharacterEntity? character;
  final VoidCallback? onEditCharacter;
  final Future<void> Function(String summary, List<ChatMemoryFact> facts)
  onSave;
  final Future<void> Function(String? systemPrompt) onSystemPromptSave;
  final VoidCallback onWorldBooksEdited;
  final Future<void> Function() onConversationClear;

  @override
  State<ChatInfoPageEditor> createState() => _ChatInfoPageEditorState();
}

class _ChatInfoPageEditorState extends State<ChatInfoPageEditor> {
  late String _summary;
  late String? _conversationSystemPrompt;
  late List<_FactDraft> _facts;

  @override
  void initState() {
    super.initState();
    _syncFromWidget();
  }

  @override
  void didUpdateWidget(ChatInfoPageEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.memory != widget.memory ||
        oldWidget.conversationSystemPrompt != widget.conversationSystemPrompt) {
      _syncFromWidget();
    }
  }

  void _syncFromWidget() {
    _summary = widget.memory.summary;
    _conversationSystemPrompt = _normalizeOptionalText(
      widget.conversationSystemPrompt,
    );
    _facts = widget.memory.facts.map(_FactDraft.fromFact).toList();
  }

  @override
  Widget build(BuildContext context) {
    final translations = context.t.main.info;
    final colorScheme = Theme.of(context).colorScheme;
    final isSaving = widget.isSaving;

    final character = widget.character;
    final onEditCharacter = widget.onEditCharacter;

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (character != null && onEditCharacter != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: ChatInfoCharacterCard(
                character: character,
                onEdit: onEditCharacter,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Icon(LucideIcons.brain, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.conversationTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          TabBar(
            tabs: [
              Tab(text: translations.basicConfigTab),
              Tab(text: translations.memoriesTab),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _BasicConfigTab(
                  summary: _summary,
                  conversationSystemPrompt: _conversationSystemPrompt,
                  appSystemPrompt: widget.appSystemPrompt,
                  worldBooksSummary: widget.worldBooksSummary,
                  isEnabled: !isSaving,
                  onSummaryEdited: _showSummarySheet,
                  onSystemPromptEdited: _showSystemPromptSheet,
                  onWorldBooksEdited: widget.onWorldBooksEdited,
                  onConversationClear: _confirmClearConversation,
                ),
                _FactsTab(
                  facts: _facts,
                  isEnabled: !isSaving,
                  onFactAdded: () => _showFactSheet(),
                  onFactEdited: (index) => _showFactSheet(index: index),
                  onFactDeleted: _removeFact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeFact(int index) async {
    setState(() {
      _facts = [..._facts]..removeAt(index);
    });
    await _saveCurrentMemory();
    if (!mounted) {
      return;
    }
    _showToast(context.t.main.info.saved);
  }

  Future<void> _saveSummary(String summary) async {
    setState(() => _summary = summary.trim());
    await _saveCurrentMemory();
    if (!mounted) {
      return;
    }
    _showToast(context.t.main.info.saved);
  }

  Future<void> _showSummarySheet() async {
    final summary = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return _TextEditorSheet(
          title: context.t.main.info.editSummary,
          labelText: context.t.main.info.summaryLabel,
          hintText: context.t.main.info.summaryHint,
          initialText: _summary,
          minLines: 8,
          maxLines: 14,
        );
      },
    );
    if (summary == null || !mounted) {
      return;
    }
    await _saveSummary(summary);
  }

  Future<void> _showSystemPromptSheet() async {
    final systemPrompt = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return _TextEditorSheet(
          title: context.t.main.info.editSystemPrompt,
          labelText: context.t.main.info.systemPromptLabel,
          hintText: context.t.main.info.systemPromptHint,
          initialText: _conversationSystemPrompt ?? '',
          fallbackText: widget.appSystemPrompt,
          minLines: 8,
          maxLines: 14,
        );
      },
    );
    if (systemPrompt == null || !mounted) {
      return;
    }
    final normalizedPrompt = _normalizeOptionalText(systemPrompt);
    setState(() => _conversationSystemPrompt = normalizedPrompt);
    await widget.onSystemPromptSave(normalizedPrompt);
    if (!mounted) {
      return;
    }
    _showToast(context.t.main.info.saved);
  }

  Future<void> _confirmClearConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            context.t.main.info.clearConversationTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          content: Text(context.t.main.info.clearConversationMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                context.t.common.cancel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                context.t.main.info.clearConversationConfirm,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }

    await widget.onConversationClear();
    if (!mounted) {
      return;
    }
    _showToast(context.t.main.info.conversationCleared);
  }

  Future<void> _showFactSheet({int? index}) async {
    final draft = index == null ? null : _facts[index];
    final savedDraft = await showModalBottomSheet<_FactDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return _FactEditorSheet(initialFact: draft);
      },
    );
    if (savedDraft == null || !mounted) {
      return;
    }

    setState(() {
      if (index == null) {
        _facts = [..._facts, savedDraft];
      } else {
        _facts = [..._facts]..[index] = savedDraft;
      }
    });
    await _saveCurrentMemory();
    if (!mounted) {
      return;
    }
    _showToast(context.t.main.info.saved);
  }

  Future<void> _saveCurrentMemory() {
    return widget.onSave(
      _summary,
      _facts
          .map((draft) => draft.toFact())
          .where((fact) => fact.content.trim().isNotEmpty)
          .toList(),
    );
  }

  void _showToast(String message) => SmartDialog.showToast(message);
}
