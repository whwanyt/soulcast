part of 'chat.dart';

/// Chat notifier 的模型配置解析与工具选择。
mixin _ChatGenerationSettings on _ChatController {
  Future<ChatSettings?> _resolveChatSettings({
    required String modelId,
    required String conversationId,
  }) async {
    try {
      final repository = await ref.read(aiProviderRepositoryProvider.future);
      final providerSettings = resolveProviderClientSettings(
        repository: repository,
        modelId: modelId,
      );
      if (providerSettings == null) {
        final model = repository.getModel(modelId);
        if (model == null || !model.isEnabled) {
          Log.d('Chat send blocked: model unavailable: $modelId', tag: 'Chat');
          state = state.copyWith(errorMessage: t.chat.error.missingModel);
          return null;
        }
        Log.d(
          'Chat send blocked: provider unavailable: ${model.providerId}',
          tag: 'Chat',
        );
        state = state.copyWith(errorMessage: t.chat.error.missingProvider);
        return null;
      }

      final chatRepository = await ref.read(chatRepositoryProvider.future);
      final conversation = chatRepository.getConversation(conversationId);
      final conversationSystemPrompt = conversation?.systemPrompt?.trim();
      final preferences = ref.read(appPreferencesProvider);
      final appSystemPrompt = await renderPromptTemplate(
        effectivePromptTemplate(
          id: PromptId.appSystem,
          customPrompts: preferences.customPrompts,
          t: t,
        ),
        const {},
        fallbackTemplate: defaultPromptTemplate(t, PromptId.appSystem),
      );

      String? characterPrompt;
      String? cardSystemPrompt;
      String? loreBeforeChar;
      String? loreAfterChar;
      String? postHistoryInstructions;
      final characterId = conversation?.characterId;
      CharacterEntity? character;
      if (characterId != null) {
        final characterRepository = await ref.read(
          characterRepositoryProvider.future,
        );
        character = characterRepository.getCharacter(characterId);
        if (character != null) {
          characterPrompt = await buildCharacterSystemPrompt(
            character,
            template: effectivePromptTemplate(
              id: PromptId.characterRolePlay,
              customPrompts: preferences.customPrompts,
              t: t,
            ),
            fallbackTemplate: defaultPromptTemplate(
              t,
              PromptId.characterRolePlay,
            ),
          );
          final cardSystem = character.cardSystemPrompt.trim();
          if (cardSystem.isNotEmpty) {
            cardSystemPrompt = cardSystem;
          }
          final postHistory = character.postHistoryInstructions.trim();
          if (postHistory.isNotEmpty) {
            postHistoryInstructions = postHistory;
          }
        }
      }

      final worldBookIds = <String>[];
      if (character != null) {
        worldBookIds.addAll(character.boundWorldBookIds);
      }
      for (final id in conversation?.worldBookIds ?? const <String>[]) {
        final trimmed = id.trim();
        if (trimmed.isNotEmpty && !worldBookIds.contains(trimmed)) {
          worldBookIds.add(trimmed);
        }
      }
      if (worldBookIds.isNotEmpty) {
        final worldBookRepository = await ref.read(
          worldBookRepositoryProvider.future,
        );
        final books = worldBookRepository.getWorldBookSnapshots(worldBookIds);
        final lore = const CharacterBookResolver().resolveAll(
          books: books,
          messages: state.messages,
        );
        if (lore.beforeChar.trim().isNotEmpty) {
          loreBeforeChar = lore.beforeChar.trim();
        }
        if (lore.afterChar.trim().isNotEmpty) {
          loreAfterChar = lore.afterChar.trim();
        }
      }
      final isRolePlay = characterPrompt != null;
      final memoryInjectId = isRolePlay
          ? PromptId.memoryInjectRolePlay
          : PromptId.memoryInjectNormal;

      // 角色会话：会话级提示词只作为附加规则，角色卡不进 systemPrompt。
      // 普通会话：沿用会话 -> 应用 -> 默认的三级优先级。
      final String? systemPrompt;
      if (conversationSystemPrompt != null &&
          conversationSystemPrompt.isNotEmpty) {
        systemPrompt = await renderPromptTemplate(
          conversationSystemPrompt,
          const {},
        );
      } else if (isRolePlay) {
        systemPrompt = null;
      } else {
        systemPrompt = appSystemPrompt;
      }
      final settings = providerSettings.copyWith(
        systemPrompt: systemPrompt,
        cardSystemPrompt: cardSystemPrompt,
        loreBeforeChar: loreBeforeChar,
        characterPrompt: characterPrompt,
        loreAfterChar: loreAfterChar,
        postHistoryInstructions: postHistoryInstructions,
        memoryInjectTemplate: effectivePromptTemplate(
          id: memoryInjectId,
          customPrompts: preferences.customPrompts,
          t: t,
        ),
        memoryInjectFallbackTemplate: defaultPromptTemplate(t, memoryInjectId),
        temperature: preferences.effectiveTemperature,
        topP: preferences.effectiveTopP,
        topK: preferences.effectiveTopK,
        maxContextMessages: preferences.effectiveContextMessageLimit,
        maxToolRounds: preferences.effectiveToolCallRoundsLimit,
      );

      if (!settings.hasApiKey) {
        Log.d(
          'Chat send blocked: missing provider API key: ${settings.providerId}',
          tag: 'Chat',
        );
        state = state.copyWith(errorMessage: t.chat.error.missingApiKey);
        return null;
      }

      return settings;
    } catch (error, stackTrace) {
      Log.e(
        'Chat settings resolve failed: $error',
        tag: 'Chat',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(errorMessage: error.toString());
      return null;
    }
  }

  bool _hasConfiguredImageModel() {
    final config = ref.read(
      agentToolConfigsProvider,
    )[AgentToolIds.generateImage];
    final modelId =
        config?.stringParam(AgentToolIds.imageModelId)?.trim() ?? '';
    return modelId.isNotEmpty;
  }

  Future<bool> _selectedModelSupportsImageInput() async {
    final modelId = state.selectedModelId;
    if (modelId == null) {
      return false;
    }
    final repository = await ref.read(aiProviderRepositoryProvider.future);
    final model = repository.getModel(modelId);
    if (model == null) {
      return false;
    }
    return model.hasInputFormat(AiModelFormatTags.image);
  }

  /// 续写走普通对话；新发/重生成则看用户正文是否含 `@创建图片`。
  bool _shouldUseImageMode({
    required ChatConversationMessage userMessage,
    required String? continueUserPrompt,
  }) {
    if (continueUserPrompt != null && continueUserPrompt.trim().isNotEmpty) {
      return false;
    }
    return ChatCreateImageMention.contains(userMessage.content);
  }

  List<AgentTool> _toolsForRequest({required bool imageMode}) {
    if (!imageMode) {
      return ref.read(agentToolsProvider);
    }
    // 图片模式只需要 generate_image（内部 createImage），不附带其它聊天工具。
    final available = ref.read(availableAgentToolsProvider);
    return [
      for (final tool in available)
        if (tool.name == AgentToolIds.generateImage) tool,
    ];
  }
}
