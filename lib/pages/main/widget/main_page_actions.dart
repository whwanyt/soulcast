part of '../main_page.dart';

mixin _MainPageActions on ConsumerState<MainPage> {
  String _selectedModelLabel({
    required BuildContext context,
    required AsyncValue<List<AiModelEntity>> models,
    required String? selectedModelId,
  }) {
    if (selectedModelId == null) {
      return context.t.main.modelSelector.noModelSelected;
    }

    final model = models.whenOrNull(
      data: (items) => _findModel(items, selectedModelId),
    );
    return model?.name ?? context.t.main.modelSelector.noModelSelected;
  }

  Future<void> _showModelSelector({
    required BuildContext context,
    required AsyncValue<List<AiModelEntity>> models,
    required AsyncValue<List<AiProviderEntity>> providers,
    required String? selectedModelId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return MainModelSelectorSheet(
          models: models,
          providers: providers,
          selectedModelId: selectedModelId,
          onModelSelected: (modelId) {
            Navigator.of(sheetContext).pop();
            ref.read(chatProvider.notifier).setConversationModel(modelId);
          },
          onManageProviders: () {
            Navigator.of(sheetContext).pop();
            GoRouter.of(context).push(AppRoutes.providerSettings);
          },
        );
      },
    );
  }

  Future<void> _showToolPanel(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => const AgentToolPanel(),
    );
  }

  Future<void> _showMcpPanel(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => const McpToolPanel(),
    );
  }

  AiModelEntity? _findModel(List<AiModelEntity> models, String modelId) {
    for (final model in models) {
      if (model.id == modelId) {
        return model;
      }
    }
    return null;
  }

  String? _characterAvatarUrl({
    required AsyncValue<List<ChatConversationEntity>> conversations,
    required AsyncValue<List<CharacterEntity>> characters,
    required String? conversationId,
  }) {
    if (conversationId == null) {
      return null;
    }

    final conversation = conversations.whenOrNull(
      data: (items) => _findConversation(items, conversationId),
    );
    final characterId = conversation?.characterId;
    if (characterId == null) {
      return null;
    }

    return characters.whenOrNull(
      data: (items) => _findCharacter(items, characterId)?.avatarUrl,
    );
  }

  bool _isCharacterChat({
    required AsyncValue<List<ChatConversationEntity>> conversations,
    required String? conversationId,
  }) {
    if (conversationId == null) {
      return false;
    }

    final conversation = conversations.whenOrNull(
      data: (items) => _findConversation(items, conversationId),
    );
    return conversation?.characterId != null;
  }

  ChatConversationEntity? _findConversation(
    List<ChatConversationEntity> conversations,
    String conversationId,
  ) {
    for (final conversation in conversations) {
      if (conversation.id == conversationId) {
        return conversation;
      }
    }
    return null;
  }

  CharacterEntity? _findCharacter(
    List<CharacterEntity> characters,
    String characterId,
  ) {
    for (final character in characters) {
      if (character.id == characterId) {
        return character;
      }
    }
    return null;
  }

  void _unfocusInput() {
    FocusManager.instance.primaryFocus?.unfocus();
  }
}
