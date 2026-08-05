import 'package:flute_core/storage/storage.dart';
import 'package:flutter/material.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:soulcast/shared/model/app_preferences_entity.dart';
import 'package:soulcast/shared/prompt/prompt.dart';
import 'package:soulcast/shared/provider/app_preferences_isar_provider.dart';
import 'package:soulcast/shared/repository/app_preferences_repository.dart';
import 'package:soulcast/shared/theme/app_boot_appearance.dart';

part 'app_preferences_provider.g.dart';
part 'app_preferences_options.dart';
part 'app_preferences_state.dart';
part 'app_preferences_restore.dart';
part 'app_preferences_appearance_actions.dart';
part 'app_preferences_chat_actions.dart';
part 'app_preferences_speech_actions.dart';

const appPreferencesThemeModeKey = 'app.preferences.theme_mode';
const appPreferencesLocaleKey = 'app.preferences.locale';

/// 管理应用偏好运行态，并将每项修改同步至持久化仓库。
abstract class _AppPreferencesController extends _$AppPreferences {
  Future<AppPreferencesRepository> _repository() async {
    final isar = await ref.read(appPreferencesIsarProvider.future);
    return AppPreferencesRepository(isar);
  }
}

@Riverpod(keepAlive: true)
class AppPreferences extends _AppPreferencesController
    with
        _AppPreferencesRestore,
        _AppPreferencesAppearanceActions,
        _AppPreferencesChatActions,
        _AppPreferencesSpeechActions {
  @override
  AppPreferencesState build() {
    return AppPreferencesState(
      themeMode: AppThemeModePreference.system,
      locale: LocaleSettings.currentLocale,
      responseMode: ChatResponseModePreference.stream,
    );
  }
}

class _Unset {
  const _Unset();
}

const _unset = _Unset();
