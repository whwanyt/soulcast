part of 'main_chat_drawer_conversation_list.dart';

enum MainChatConversationMenuAction { pin, rename, delete }

RelativeRect mainChatConversationMenuPosition(
  BuildContext context,
  Offset globalPosition,
) {
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final overlaySize = overlay.size;
  final localPosition = overlay.globalToLocal(globalPosition);
  const menuWidth = 176.0;

  final left = (localPosition.dx + 12).clamp(
    12.0,
    overlaySize.width - menuWidth - 12,
  );
  final top = (localPosition.dy - 12).clamp(12.0, overlaySize.height - 112);

  return RelativeRect.fromLTRB(
    left,
    top,
    overlaySize.width - left - menuWidth,
    overlaySize.height - top,
  );
}

PopupMenuItem<MainChatConversationMenuAction> mainChatConversationPopupItem({
  required BuildContext context,
  required MainChatConversationMenuAction value,
  required IconData icon,
  required String label,
  bool isDestructive = false,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  final foreground = isDestructive ? colorScheme.error : colorScheme.onSurface;

  return PopupMenuItem<MainChatConversationMenuAction>(
    value: value,
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: 18),
    child: Row(
      children: [
        Icon(icon, size: 20, color: foreground),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

String mainChatConversationTitle(BuildContext context, String title) {
  return isDefaultChatConversationTitle(title)
      ? context.t.main.newConversation
      : title;
}
