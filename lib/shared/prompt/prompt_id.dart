/// 可配置提示词标识，与偏好持久化 key、i18n 默认模板一一对应。
enum PromptId {
  appSystem('appSystem'),
  characterRolePlay('characterRolePlay'),
  memoryInjectNormal('memoryInjectNormal'),
  memoryInjectRolePlay('memoryInjectRolePlay'),
  memoryUpdateSystem('memoryUpdateSystem'),
  memoryUpdateUserNormal('memoryUpdateUserNormal'),
  memoryUpdateUserRolePlay('memoryUpdateUserRolePlay'),
  titleSystem('titleSystem'),
  titleUser('titleUser'),
  generateCharacterSystem('generateCharacterSystem'),
  generateCharacterUser('generateCharacterUser'),
  avatarImageWrap('avatarImageWrap');

  const PromptId(this.storageKey);

  final String storageKey;

  static PromptId? tryParse(String value) {
    for (final id in PromptId.values) {
      if (id.storageKey == value || id.name == value) {
        return id;
      }
    }
    return null;
  }

  /// 设置列表展示顺序：应用级置顶，其后为业务提示词。
  static const listOrder = <PromptId>[
    PromptId.appSystem,
    PromptId.characterRolePlay,
    PromptId.memoryInjectNormal,
    PromptId.memoryInjectRolePlay,
    PromptId.memoryUpdateSystem,
    PromptId.memoryUpdateUserNormal,
    PromptId.memoryUpdateUserRolePlay,
    PromptId.titleSystem,
    PromptId.titleUser,
    PromptId.generateCharacterSystem,
    PromptId.generateCharacterUser,
    PromptId.avatarImageWrap,
  ];
}
