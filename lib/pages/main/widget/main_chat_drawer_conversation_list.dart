import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/theme/app_ui.dart';
import 'package:soulcast/shared/widgets/app_text_field.dart';

part 'main_chat_drawer_conversation_item.dart';
part 'main_chat_drawer_conversation_status.dart';
part 'main_chat_conversation_rename_sheet.dart';
part 'main_chat_conversation_menu.dart';

/// 会话抽屉中的会话列表，包含加载/空态与置顶、重命名、删除等菜单动作。
class MainChatDrawerConversationList extends StatelessWidget {
  const MainChatDrawerConversationList({
    super.key,
    required this.conversations,
    required this.selectedConversationId,
    required this.isEnabled,
    required this.onSelected,
    required this.onPinChanged,
    required this.onRenamed,
    required this.onDeleted,
  });

  final AsyncValue<List<ChatConversationEntity>> conversations;
  final String? selectedConversationId;
  final bool isEnabled;
  final ValueChanged<String> onSelected;
  final void Function(String conversationId, bool isPinned) onPinChanged;
  final Future<void> Function(String conversationId, String title) onRenamed;
  final ValueChanged<String> onDeleted;

  @override
  Widget build(BuildContext context) {
    return conversations.when(
      data: (items) {
        if (items.isEmpty) {
          return MainChatDrawerConversationStatus(
            text: context.t.main.noConversations,
          );
        }

        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final conversation = items[index];
            return MainChatDrawerConversationItem(
              conversation: conversation,
              isSelected: conversation.id == selectedConversationId,
              isEnabled: isEnabled,
              onSelected: onSelected,
              onPinChanged: onPinChanged,
              onRenamed: onRenamed,
              onDeleted: onDeleted,
            );
          },
        );
      },
      loading: () => MainChatDrawerConversationStatus(
        text: context.t.main.loadingConversations,
      ),
      error: (error, stackTrace) => MainChatDrawerConversationStatus(
        text: context.t.main.conversationLoadFailed,
      ),
    );
  }
}
