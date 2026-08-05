import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:soulcast/entities/ai_provider/ai_provider.dart';
import 'package:soulcast/entities/character/character.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/features/agent/agent.dart';
import 'package:soulcast/features/mcp/mcp.dart';
import 'package:soulcast/features/speech/speech.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/image/image_dominant_color.dart';
import 'package:soulcast/shared/navigation/app_routes.dart';
import 'package:soulcast/shared/provider/avatar_dominant_color_provider.dart';
import 'package:soulcast/shared/theme/app_ui.dart';

import 'widget/main_chat_body.dart';
import 'widget/main_chat_character_background.dart';
import 'widget/main_chat_drawer.dart';
import 'widget/main_chat_input.dart';
import 'widget/main_chat_top_bar.dart';
import 'widget/main_model_selector_sheet.dart';

part 'widget/main_page_actions.dart';

/// 应用主聊天页面，组合会话、模型、工具、MCP 与语音交互。
class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> with _MainPageActions {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).restoreInitialConversation();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(chatProvider.select((state) => state.errorMessage), (
      previous,
      next,
    ) {
      if (next != null && next.isNotEmpty) {
        SmartDialog.showToast(next);
      }
    });

    final chat = ref.watch(chatProvider);
    final conversations = ref.watch(chatConversationsProvider);
    final characters = ref.watch(charactersProvider);
    final models = ref.watch(aiModelsProvider);
    final providers = ref.watch(aiProvidersProvider);
    final speechInput = ref.watch(speechInputProvider);
    final selectedModelLabel = _selectedModelLabel(
      context: context,
      models: models,
      selectedModelId: chat.selectedModelId,
    );
    final isCharacterChat = _isCharacterChat(
      conversations: conversations,
      conversationId: chat.selectedConversationId,
    );
    final characterAvatarUrl = isCharacterChat
        ? _characterAvatarUrl(
            conversations: conversations,
            characters: characters,
            conversationId: chat.selectedConversationId,
          )
        : null;
    final avatarUrl = characterAvatarUrl?.trim();
    final dominantColor = (avatarUrl == null || avatarUrl.isEmpty)
        ? null
        : ref
              .watch(avatarDominantColorProvider(avatarUrl))
              .whenOrNull(data: (color) => color);
    final characterBubbleFill = dominantColor == null
        ? null
        : avatarBubbleFillColor(dominantColor);

    ref.listen<String?>(
      speechInputProvider.select((state) => state.errorMessage),
      (previous, next) {
        if (next != null && next.isNotEmpty) {
          SmartDialog.showToast(next);
        }
      },
    );

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBackground = colorScheme.surfaceContainerLow;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: pageBackground,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor:
            isCharacterChat && (characterAvatarUrl?.trim().isNotEmpty ?? false)
            ? Colors.transparent
            : pageBackground,
        drawerScrimColor: Colors.black.withValues(alpha: 0.36),
        drawer: MainChatDrawer(
          conversations: conversations,
          selectedConversationId: chat.selectedConversationId,
          isEnabled: !chat.isSending,
          onSelected: (conversationId) {
            _unfocusInput();
            ref.read(chatProvider.notifier).selectConversation(conversationId);
          },
          onNewConversation: () {
            _unfocusInput();
            ref.read(chatProvider.notifier).startNewConversation();
          },
          onPinChanged: (conversationId, isPinned) {
            _unfocusInput();
            ref
                .read(chatProvider.notifier)
                .setConversationPinned(
                  conversationId: conversationId,
                  isPinned: isPinned,
                );
          },
          onRenamed: (conversationId, title) async {
            _unfocusInput();
            await ref
                .read(chatProvider.notifier)
                .renameConversation(
                  conversationId: conversationId,
                  title: title,
                );
          },
          onDeleted: (conversationId) {
            _unfocusInput();
            ref.read(chatProvider.notifier).deleteConversation(conversationId);
          },
        ),
        body: Builder(
          builder: (context) {
            final mediaQuery = MediaQuery.of(context);
            final keyboardInset = mediaQuery.viewInsets.bottom;
            final topSafe = mediaQuery.padding.top;
            final bottomSafe = mediaQuery.viewPadding.bottom;

            return Stack(
              children: [
                Positioned.fill(
                  child: MainChatCharacterBackground(
                    avatarUrl: characterAvatarUrl,
                  ),
                ),
                Positioned.fill(
                  child: SafeArea(
                    child: MainChatBody(
                      isLoadingMessages: chat.isLoadingMessages,
                      hasMessages: chat.hasMessages,
                      messages: chat.messages,
                      isSending: chat.isSending,
                      isCharacterChat: isCharacterChat,
                      bubbleFill: characterBubbleFill,
                      keyboardInset: keyboardInset,
                      onContinueReply: () {
                        ref.read(chatProvider.notifier).continueReply();
                      },
                      onRegenerate: () {
                        ref
                            .read(chatProvider.notifier)
                            .regenerateLastAssistant();
                      },
                      onSelectAssistantVersion: (selection) {
                        final (messageId, index) = selection;
                        ref
                            .read(chatProvider.notifier)
                            .selectAssistantVersion(
                              messageId: messageId,
                              index: index,
                            );
                      },
                    ),
                  ),
                ),
                if (isCharacterChat &&
                    (characterAvatarUrl?.trim().isNotEmpty ?? false)) ...[
                  Positioned.fill(
                    child: MainChatCharacterTopFade(
                      avatarUrl: characterAvatarUrl,
                      fadeHeight: topSafe + mainChatCharacterListTopPadding,
                    ),
                  ),
                  Positioned.fill(
                    child: MainChatCharacterBottomFade(
                      avatarUrl: characterAvatarUrl,
                      // 键盘顶起输入区时，渐隐同步加高，避免消息顶到输入框。
                      fadeHeight:
                          (keyboardInset > 0 ? keyboardInset : bottomSafe) +
                          mainChatCharacterListBottomPadding,
                    ),
                  ),
                ],
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: MainChatTopBar(
                    hideBackgroundGradient: isCharacterChat,
                    isInfoEnabled:
                        chat.selectedConversationId != null &&
                        !chat.isLoadingMessages,
                    onMenuPressed: () {
                      _unfocusInput();
                      Scaffold.of(context).openDrawer();
                    },
                    onInfoPressed: () {
                      _unfocusInput();
                      final conversationId = chat.selectedConversationId;
                      if (conversationId != null) {
                        GoRouter.of(
                          context,
                        ).push(AppRoutes.chatInfoLocation(conversationId));
                      }
                    },
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    // resizeToAvoidBottomInset: false 时，手动把输入区顶到键盘上方。
                    padding: EdgeInsets.only(bottom: keyboardInset),
                    child: Builder(
                      builder: (context) {
                        final input = SafeArea(
                          top: false,
                          // 键盘弹起时底部安全区已由 keyboardInset 占据，避免重复留白。
                          bottom: keyboardInset <= 0,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.page,
                              AppSpacing.xl,
                              AppSpacing.page,
                              14,
                            ),
                            child: MainChatInput(
                              enabled: !chat.isLoadingMessages,
                              isSending: chat.isSending,
                              useBlurBackground: isCharacterChat,
                              draftMessage: chat.draftMessage,
                              draftAttachments: chat.draftAttachments,
                              onDraftChanged: (value) {
                                ref
                                    .read(chatProvider.notifier)
                                    .updateDraftMessage(value);
                              },
                              onSubmitted: (value) {
                                _unfocusInput();
                                ref
                                    .read(chatProvider.notifier)
                                    .sendMessage(value);
                              },
                              onStopPressed: () {
                                ref.read(chatProvider.notifier).cancelSending();
                              },
                              onToolsPressed: () {
                                _showToolPanel(context);
                              },
                              onMcpPressed: () {
                                _showMcpPanel(context);
                              },
                              onPickDraftImages: () {
                                return ref
                                    .read(chatProvider.notifier)
                                    .pickDraftImages();
                              },
                              onPickDraftDocuments: () {
                                return ref
                                    .read(chatProvider.notifier)
                                    .pickDraftDocuments();
                              },
                              onImportLibraryImage: (path) {
                                return ref
                                    .read(chatProvider.notifier)
                                    .importDraftLibraryImage(path);
                              },
                              onRemoveDraftAttachment: (attachmentId) {
                                ref
                                    .read(chatProvider.notifier)
                                    .removeDraftAttachment(attachmentId);
                              },
                              modelLabel: selectedModelLabel,
                              onModelPressed: () {
                                _showModelSelector(
                                  context: context,
                                  models: models,
                                  providers: providers,
                                  selectedModelId: chat.selectedModelId,
                                );
                              },
                              isVoiceListening: speechInput.isListening,
                              voicePartialText: speechInput.partialText,
                              onVoicePressed: () async {
                                _unfocusInput();
                                final notifier = ref.read(
                                  speechInputProvider.notifier,
                                );
                                if (speechInput.isListening) {
                                  final text = (await notifier.stopListening())
                                      .trim();
                                  if (text.isEmpty) {
                                    return;
                                  }
                                  final draft = ref
                                      .read(chatProvider)
                                      .draftMessage
                                      .trim();
                                  final next = draft.isEmpty
                                      ? text
                                      : '$draft $text';
                                  await ref
                                      .read(chatProvider.notifier)
                                      .updateDraftMessage(next);
                                  return;
                                }
                                await notifier.toggleListening();
                              },
                            ),
                          ),
                        );

                        if (isCharacterChat) {
                          return input;
                        }

                        final surface = Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow;
                        return DecoratedBox(
                          key: const ValueKey('main_chat_input_gradient'),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                surface,
                                surface,
                                surface.withValues(alpha: 0.88),
                                surface.withValues(alpha: 0.45),
                                surface.withValues(alpha: 0),
                              ],
                              stops: const [0, 0.36, 0.58, 0.8, 1],
                            ),
                          ),
                          child: input,
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
