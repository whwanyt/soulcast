import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:soulcast/i18n/strings.g.dart';

part 'character_management_filter_provider.g.dart';

/// 角色管理页支持的本地筛选维度。
enum CharacterManagementFilter {
  all,
  favorites,
  recent;

  String label(Translations translations) {
    return switch (this) {
      CharacterManagementFilter.all =>
        translations.characterManagement.filter.all,
      CharacterManagementFilter.favorites =>
        translations.characterManagement.filter.favorites,
      CharacterManagementFilter.recent =>
        translations.characterManagement.filter.recent,
    };
  }
}

/// 管理角色管理页当前选中的筛选条件。
@riverpod
class CharacterManagementFilterController
    extends _$CharacterManagementFilterController {
  @override
  CharacterManagementFilter build() {
    return CharacterManagementFilter.all;
  }

  void select(CharacterManagementFilter filter) {
    if (state == filter) {
      return;
    }

    state = filter;
  }
}
