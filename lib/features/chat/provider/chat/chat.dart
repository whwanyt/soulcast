import 'dart:async';
import 'dart:convert';
import 'package:soulcast/features/agent/llm.dart';

import 'package:flute_core/log/log.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:soulcast/entities/ai_provider/ai_provider.dart';
import 'package:soulcast/entities/character/character.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/entities/world_book/world_book.dart';
import 'package:soulcast/features/mcp/mcp.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/prompt/prompt.dart';
import 'package:soulcast/shared/provider/app_preferences_provider.dart';

import 'package:soulcast/features/agent_tools/agent_tools.dart';

import '../../model/chat_completion_result.dart';
import '../../model/chat_create_image_mention.dart';
import '../../model/chat_state.dart';
import '../../service/character_book_resolver.dart';
import '../../service/character_prompt_builder.dart';
import '../../service/chat_attachment_importer.dart';
import '../chat_memory_update_service.dart';
import '../chat_service.dart';
import '../chat_title_update_service.dart';

part 'chat.g.dart';
part 'types.dart';
part 'internal.dart';
part 'conversation_actions.dart';
part 'conversation_creation_actions.dart';
part 'conversation_settings_actions.dart';
part 'conversation_management_actions.dart';
part 'conversation_clear_actions.dart';
part 'attachment_actions.dart';
part 'send_actions.dart';
part 'generation_settings.dart';
part 'generation_projection.dart';
part 'generation_failure_actions.dart';
part 'generation_persistence_actions.dart';
part 'generation_delivery_actions.dart';
part 'generation_actions.dart';
part 'regenerate_actions.dart';
part 'memory_actions.dart';
part 'title_actions.dart';

/// Chat Notifier 共享字段与跨 mixin 协作契约（仅本库使用）。
abstract class _ChatController extends _$Chat {
  Completer<void>? _abortCompleter;
  int _loadSerial = 0;
  _AssistantRegenerateContext? _activeRegenerate;

  /// 当前生成绑定的会话；写 UI 时必须与 [ChatState.selectedConversationId] 对齐。
  String? _activeRunConversationId;

  /// 本轮生成开始时落库的占位助手，用于稳定 message id。
  ChatConversationMessage? _activePlaceholderAssistant;

  DateTime? _lastStreamCheckpointAt;

  // --- implemented by _ChatInternal ---
  void _abortRequest();
  bool _isConversationFocused(String conversationId);
  Future<String?> _ensureSelectedConversationId();
  Future<void> _saveMessages(
    String conversationId,
    List<ChatConversationMessage> messages,
  );
  Future<void> _clearStoredMessages(String conversationId);
  Future<void> _deleteStoredMessages({
    required String conversationId,
    required List<String> ids,
  });
  Future<void> _saveDraftMessage(String conversationId, String draftMessage);
  Future<void> _saveSelectedConversation(String conversationId);
  List<ChatConversationMessage> _reconcileLoadedMessages(
    List<ChatConversationMessage> messages,
  );

  // --- implemented by _ChatSendActions ---
  void _clearErrorMessage();
  Future<void> resumePendingRemoteResponse();
  Future<void> _runAssistantGeneration({
    required String conversationId,
    required List<ChatConversationMessage> prefixMessages,
    required ChatConversationMessage userMessage,
    required ChatConversationMessage? resumeAssistant,
    required String? continueUserPrompt,
    required _AssistantRegenerateContext? regenerate,
  });
  Future<void> _persistInterruptedAssistant(
    String conversationId, {
    List<ChatConversationMessage>? sourceMessages,
  });

  // --- implemented by _ChatRegenerateActions ---
  ChatConversationMessage _assistantFromVersions({
    required String turnId,
    required DateTime createdAt,
    required List<ChatAssistantMessageVersion> versions,
    required int selectedVersionIndex,
  });
  _LastAssistantTurn? _resolveLastAssistantTurn(
    List<ChatConversationMessage> messages,
  );
  Future<void> _restoreRegenerateTurnOnFailure({
    required String conversationId,
    required String errorMessage,
  });

  // --- implemented by _ChatMemoryActions ---
  Future<ChatConversationMemory> _loadMemory(String conversationId);
  Future<void> _updateMemoryAfterCompletion({
    required LlmClient client,
    required ChatSettings settings,
    required String conversationId,
    required ChatConversationMemory memory,
    required ChatConversationMessage userMessage,
    required ChatCompletionResult completionResult,
  });

  // --- implemented by _ChatTitleActions ---
  Future<void> _updateTitleAfterCompletion({
    required LlmClient client,
    required ChatSettings settings,
    required String conversationId,
    required ChatConversationMessage userMessage,
    required ChatCompletionResult completionResult,
  });
}

@Riverpod(keepAlive: true)
/// 应用级聊天运行态与用户动作入口。
class Chat extends _ChatController
    with
        _ChatInternal,
        _ChatConversationActions,
        _ChatConversationCreationActions,
        _ChatConversationSettingsActions,
        _ChatConversationManagementActions,
        _ChatConversationClearActions,
        _ChatAttachmentActions,
        _ChatGenerationSettings,
        _ChatSendActions,
        _ChatGenerationProjection,
        _ChatGenerationFailureActions,
        _ChatGenerationPersistenceActions,
        _ChatGenerationDeliveryActions,
        _ChatGenerationActions,
        _ChatRegenerateActions,
        _ChatMemoryActions,
        _ChatTitleActions {
  @override
  ChatState build() {
    ref.onDispose(_abortRequest);
    Log.d('Chat provider initialized', tag: 'Chat');
    // 冷启动先进入 loading，避免首帧空引导闪屏。
    return const ChatState(isLoadingMessages: true);
  }
}
