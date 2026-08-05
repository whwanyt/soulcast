import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/i18n/strings.g.dart';

/// 根据会话异步状态展示当前会话下拉选择器。
class MainConversationSelector extends StatelessWidget {
  const MainConversationSelector({
    super.key,
    required this.conversations,
    required this.selectedConversationId,
    required this.isEnabled,
    required this.onSelected,
  });

  final AsyncValue<List<ChatConversationEntity>> conversations;
  final String? selectedConversationId;
  final bool isEnabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return conversations.when(
      data: (items) => _MainConversationDropdown(
        conversations: items,
        selectedConversationId: selectedConversationId,
        isEnabled: isEnabled,
        onSelected: onSelected,
      ),
      loading: () =>
          _MainConversationTitle(text: context.t.main.loadingConversations),
      error: (error, stackTrace) =>
          _MainConversationTitle(text: context.t.main.conversationLoadFailed),
    );
  }
}

class _MainConversationDropdown extends StatelessWidget {
  const _MainConversationDropdown({
    required this.conversations,
    required this.selectedConversationId,
    required this.isEnabled,
    required this.onSelected,
  });

  final List<ChatConversationEntity> conversations;
  final String? selectedConversationId;
  final bool isEnabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final selectedId =
        conversations.any(
          (conversation) => conversation.id == selectedConversationId,
        )
        ? selectedConversationId
        : null;

    if (conversations.isEmpty || selectedId == null) {
      return _MainConversationTitle(text: context.t.main.newConversation);
    }

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: selectedId,
        isExpanded: true,
        icon: const Icon(Icons.expand_more_rounded, size: 20),
        style: Theme.of(context).textTheme.titleMedium,
        onChanged: isEnabled
            ? (value) {
                if (value != null) {
                  onSelected(value);
                }
              }
            : null,
        selectedItemBuilder: (context) {
          return conversations.map((conversation) {
            return _MainConversationTitle(
              text: _conversationTitle(context, conversation.title),
            );
          }).toList();
        },
        items: conversations.map((conversation) {
          return DropdownMenuItem<String>(
            value: conversation.id,
            child: SizedBox(
              height: 44,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _conversationTitle(context, conversation.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

String _conversationTitle(BuildContext context, String title) {
  return isDefaultChatConversationTitle(title)
      ? context.t.main.newConversation
      : title;
}

class _MainConversationTitle extends StatelessWidget {
  const _MainConversationTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}
