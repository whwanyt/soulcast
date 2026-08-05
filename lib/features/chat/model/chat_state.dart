import 'package:soulcast/entities/chat/chat.dart';

class _Unset {
  const _Unset();
}

const _unset = _Unset();

/// 聊天 feature 的页面无关运行状态。
class ChatState {
  const ChatState({
    this.messages = const [],
    this.selectedConversationId,
    this.selectedModelId,
    this.isLoadingMessages = false,
    this.isSending = false,
    this.errorMessage,
    this.lastUsage,
    this.draftMessage = '',
    this.draftAttachments = const [],
  });

  final List<ChatConversationMessage> messages;
  final String? selectedConversationId;
  final String? selectedModelId;
  final bool isLoadingMessages;
  final bool isSending;
  final String? errorMessage;
  final ChatUsageSnapshot? lastUsage;
  final String draftMessage;
  final List<ChatAttachmentPart> draftAttachments;

  bool get hasMessages => messages.isNotEmpty;

  bool get hasDraftAttachments => draftAttachments.isNotEmpty;

  bool get canSubmitDraft {
    return draftMessage.trim().isNotEmpty || draftAttachments.isNotEmpty;
  }

  /// 仅在目标会话当前被选中时清空其运行态消息。
  ChatState clearedConversationMessages(String conversationId) {
    if (selectedConversationId != conversationId) {
      return this;
    }
    return copyWith(
      messages: const [],
      draftMessage: '',
      draftAttachments: const [],
      isSending: false,
      errorMessage: null,
      lastUsage: null,
    );
  }

  ChatState copyWith({
    List<ChatConversationMessage>? messages,
    Object? selectedConversationId = _unset,
    Object? selectedModelId = _unset,
    bool? isLoadingMessages,
    bool? isSending,
    Object? errorMessage = _unset,
    Object? lastUsage = _unset,
    String? draftMessage,
    List<ChatAttachmentPart>? draftAttachments,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      selectedConversationId: selectedConversationId == _unset
          ? this.selectedConversationId
          : selectedConversationId as String?,
      selectedModelId: selectedModelId == _unset
          ? this.selectedModelId
          : selectedModelId as String?,
      isLoadingMessages: isLoadingMessages ?? this.isLoadingMessages,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
      lastUsage: lastUsage == _unset
          ? this.lastUsage
          : lastUsage as ChatUsageSnapshot?,
      draftMessage: draftMessage ?? this.draftMessage,
      draftAttachments: draftAttachments ?? this.draftAttachments,
    );
  }
}
