part of 'main_chat_drawer_conversation_list.dart';

class MainChatDrawerConversationItem extends StatelessWidget {
  const MainChatDrawerConversationItem({
    super.key,
    required this.conversation,
    required this.isSelected,
    required this.isEnabled,
    required this.onSelected,
    required this.onPinChanged,
    required this.onRenamed,
    required this.onDeleted,
  });

  final ChatConversationEntity conversation;
  final bool isSelected;
  final bool isEnabled;
  final ValueChanged<String> onSelected;
  final void Function(String conversationId, bool isPinned) onPinChanged;
  final Future<void> Function(String conversationId, String title) onRenamed;
  final ValueChanged<String> onDeleted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected
          ? colorScheme.surfaceContainerHighest
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        onTap: isEnabled
            ? () {
                Navigator.of(context).pop();
                onSelected(conversation.id);
              }
            : null,
        onLongPress: isEnabled
            ? () {
                _showConversationMenu(
                  context,
                  _conversationItemMenuAnchor(context),
                );
              }
            : null,
        child: SizedBox(
          height: 44,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      mainChatConversationTitle(context, conversation.title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isEnabled
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withValues(alpha: 0.38),
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox.square(
                    dimension: 18,
                    child: AnimatedOpacity(
                      opacity: conversation.isPinned ? 1 : 0,
                      duration: const Duration(milliseconds: 160),
                      child: Icon(
                        LucideIcons.pin,
                        size: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showConversationMenu(
    BuildContext context,
    Offset globalPosition,
  ) async {
    final selectedAction = await showMenu<MainChatConversationMenuAction>(
      context: context,
      menuPadding: EdgeInsets.zero,
      position: mainChatConversationMenuPosition(context, globalPosition),
      color: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      items: [
        mainChatConversationPopupItem(
          context: context,
          value: MainChatConversationMenuAction.pin,
          icon: conversation.isPinned ? LucideIcons.pinOff : LucideIcons.pin,
          label: conversation.isPinned
              ? context.t.main.conversationMenu.unpin
              : context.t.main.conversationMenu.pin,
        ),
        mainChatConversationPopupItem(
          context: context,
          value: MainChatConversationMenuAction.rename,
          icon: LucideIcons.penLine,
          label: context.t.main.conversationMenu.rename,
        ),
        mainChatConversationPopupItem(
          context: context,
          value: MainChatConversationMenuAction.delete,
          icon: LucideIcons.trash2,
          label: context.t.main.conversationMenu.delete,
          isDestructive: true,
        ),
      ],
    );
    if (!context.mounted) {
      return;
    }

    switch (selectedAction) {
      case MainChatConversationMenuAction.pin:
        onPinChanged(conversation.id, !conversation.isPinned);
      case MainChatConversationMenuAction.rename:
        await _showRenameSheet(context);
      case MainChatConversationMenuAction.delete:
        final confirmed = await _confirmDeleteConversation(context);
        if (confirmed && context.mounted) {
          onDeleted(conversation.id);
        }
      case null:
        break;
    }
  }

  Future<bool> _confirmDeleteConversation(BuildContext context) async {
    final t = context.t.main.conversationMenu;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            t.deleteConfirmTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          content: Text(t.deleteConfirmMessage),
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
                t.deleteConfirm,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
    return confirmed == true;
  }

  Offset _conversationItemMenuAnchor(BuildContext context) {
    final renderBox = context.findRenderObject()! as RenderBox;
    return renderBox.localToGlobal(Offset(renderBox.size.width, 0));
  }

  Future<void> _showRenameSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return MainChatConversationRenameSheet(
          initialTitle: isDefaultChatConversationTitle(conversation.title)
              ? ''
              : conversation.title,
          onSave: (title) => onRenamed(conversation.id, title),
        );
      },
    );
  }
}
