part of 'main_chat_drawer_conversation_list.dart';

class MainChatDrawerConversationStatus extends StatelessWidget {
  const MainChatDrawerConversationStatus({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}
