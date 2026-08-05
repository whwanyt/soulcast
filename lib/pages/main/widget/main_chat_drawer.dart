import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/pages/main/widget/main_chat_drawer_conversation_list.dart';
import 'package:soulcast/shared/navigation/app_routes.dart';
import 'package:soulcast/shared/theme/app_ui.dart';

/// 主页面会话抽屉，提供新建、选择与会话管理动作。
class MainChatDrawer extends StatelessWidget {
  const MainChatDrawer({
    super.key,
    required this.conversations,
    required this.selectedConversationId,
    required this.isEnabled,
    required this.onSelected,
    required this.onNewConversation,
    required this.onPinChanged,
    required this.onRenamed,
    required this.onDeleted,
  });

  final AsyncValue<List<ChatConversationEntity>> conversations;
  final String? selectedConversationId;
  final bool isEnabled;
  final ValueChanged<String> onSelected;
  final VoidCallback onNewConversation;
  final void Function(String conversationId, bool isPinned) onPinChanged;
  final Future<void> Function(String conversationId, String title) onRenamed;
  final ValueChanged<String> onDeleted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.82,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MainChatDrawerHeader(),
              const SizedBox(height: 16),
              MainChatDrawerActionList(
                isEnabled: isEnabled,
                onNewConversation: onNewConversation,
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  context.t.main.recent.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: MainChatDrawerConversationList(
                  conversations: conversations,
                  selectedConversationId: selectedConversationId,
                  isEnabled: isEnabled,
                  onSelected: onSelected,
                  onPinChanged: onPinChanged,
                  onRenamed: onRenamed,
                  onDeleted: onDeleted,
                ),
              ),
              const SizedBox(height: 10),
              Divider(
                height: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.55),
              ),
              const SizedBox(height: 10),
              const MainChatDrawerFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

class MainChatDrawerHeader extends StatelessWidget {
  const MainChatDrawerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            context.t.appName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        ),
        AppFloatingIconButton(
          tooltip: context.t.common.search,
          icon: LucideIcons.search,
          onPressed: () {},
        ),
      ],
    );
  }
}

class MainChatDrawerActionList extends StatelessWidget {
  const MainChatDrawerActionList({
    super.key,
    required this.isEnabled,
    required this.onNewConversation,
  });

  final bool isEnabled;
  final VoidCallback onNewConversation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MainChatDrawerActionItem(
          icon: LucideIcons.squarePen,
          label: context.t.main.newChat,
          onTap: isEnabled
              ? () {
                  Navigator.of(context).pop();
                  onNewConversation();
                }
              : null,
        ),
        MainChatDrawerActionItem(
          icon: LucideIcons.users,
          label: context.t.main.characters,
          onTap: () {
            final router = GoRouter.of(context);
            Navigator.of(context).pop();
            router.push(AppRoutes.characterManagement);
          },
        ),
        MainChatDrawerActionItem(
          icon: LucideIcons.folderOpen,
          label: context.t.main.fileLibrary,
          onTap: () {
            final router = GoRouter.of(context);
            Navigator.of(context).pop();
            router.push(AppRoutes.fileLibrary);
          },
        ),
      ],
    );
  }
}

class MainChatDrawerActionItem extends StatelessWidget {
  const MainChatDrawerActionItem({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: SizedBox(
            height: 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox.square(
                  dimension: 28,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadii.xs),
                    ),
                    child: Icon(icon, size: 18, color: colorScheme.onSurface),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainChatDrawerFooter extends StatelessWidget {
  const MainChatDrawerFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: MainChatDrawerActionItem(
        icon: LucideIcons.settings,
        label: context.t.common.settings,
        onTap: () {
          final router = GoRouter.of(context);
          Navigator.of(context).pop();
          router.push(AppRoutes.settings);
        },
      ),
    );
  }
}
