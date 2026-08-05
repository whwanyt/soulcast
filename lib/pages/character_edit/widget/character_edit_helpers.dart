part of '../character_edit_page.dart';

List<AiModelEntity> _enabledTextModels(List<AiModelEntity> models) {
  return models
      .where(
        (model) =>
            model.isEnabled &&
            model.hasInputFormat(AiModelFormatTags.text) &&
            model.hasOutputFormat(AiModelFormatTags.text),
      )
      .toList();
}

List<AiModelEntity> _enabledImageModels(List<AiModelEntity> models) {
  final candidates = models
      .where(
        (model) =>
            model.isEnabled && model.hasOutputFormat(AiModelFormatTags.image),
      )
      .toList();
  candidates.sort(
    (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
  );
  return candidates;
}

AiModelEntity? _findModel(List<AiModelEntity> models, String? modelId) {
  if (modelId == null) {
    return null;
  }
  for (final model in models) {
    if (model.id == modelId) {
      return model;
    }
  }
  return null;
}

AiProviderEntity? _findProvider(
  List<AiProviderEntity> providers,
  String providerId,
) {
  for (final provider in providers) {
    if (provider.id == providerId) {
      return provider;
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
