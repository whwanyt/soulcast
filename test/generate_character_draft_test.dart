import 'package:flutter_test/flutter_test.dart';
import 'package:soulcast/features/manage_character/manage_character.dart';

void main() {
  test('parseGeneratedCharacterDraft accepts full character JSON', () {
    final draft = parseGeneratedCharacterDraft('''
{
  "name": "小夜",
  "description": "古寺里的狐仙巫女。",
  "personality": "表面傲娇，内心温柔。",
  "speechStyle": "自称妾身，叫用户大人。",
  "appearance": "银白狐耳与朱红巫女服。",
  "scenario": "雨夜古寺的灯笼下。",
  "greeting": "……你怎么找到这里来的？",
  "exampleDialogues": "用户：你好。\\n小夜：哼，别靠太近。",
  "hardConstraints": "不主动暴露真实身份。"
}
''');

    expect(draft, isNotNull);
    expect(draft!.name, '小夜');
    expect(draft.description, '古寺里的狐仙巫女。');
    expect(draft.personality, '表面傲娇，内心温柔。');
    expect(draft.speechStyle, '自称妾身，叫用户大人。');
    expect(draft.appearance, '银白狐耳与朱红巫女服。');
    expect(draft.scenario, '雨夜古寺的灯笼下。');
    expect(draft.greeting, '……你怎么找到这里来的？');
    expect(draft.exampleDialogues, '用户：你好。\n小夜：哼，别靠太近。');
    expect(draft.hardConstraints, '不主动暴露真实身份。');
    expect(draft.avatarUrl, isNull);
  });

  test(
    'parseGeneratedCharacterDraft fills missing optional fields as empty',
    () {
      final draft = parseGeneratedCharacterDraft('''
{
  "name": "阿澄"
}
''');

      expect(draft, isNotNull);
      expect(draft!.name, '阿澄');
      expect(draft.description, isEmpty);
      expect(draft.personality, isEmpty);
      expect(draft.speechStyle, isEmpty);
      expect(draft.appearance, isEmpty);
      expect(draft.scenario, isEmpty);
      expect(draft.greeting, isEmpty);
      expect(draft.exampleDialogues, isEmpty);
      expect(draft.hardConstraints, isEmpty);
    },
  );

  test(
    'parseGeneratedCharacterDraft rejects invalid JSON and missing name',
    () {
      expect(parseGeneratedCharacterDraft('{'), isNull);
      expect(parseGeneratedCharacterDraft('[]'), isNull);
      expect(parseGeneratedCharacterDraft('{"description":"only"}'), isNull);
      expect(parseGeneratedCharacterDraft('{"name":"   "}'), isNull);
    },
  );

  test('buildDefaultAvatarPromptText uses appearance only', () {
    expect(buildDefaultAvatarPromptText(appearance: '银白狐耳'), '银白狐耳');
    expect(buildDefaultAvatarPromptText(appearance: '  银白狐耳  '), '银白狐耳');
    expect(buildDefaultAvatarPromptText(appearance: ''), isEmpty);
  });

  test('buildCharacterAvatarImagePrompt wraps user prompt', () async {
    final prompt = await buildCharacterAvatarImagePrompt(
      '银白狐耳与朱红巫女服',
      template:
          'Character portrait avatar, looking at camera, high quality, '
          'single character, clean background.\n{{userPrompt}}',
    );
    expect(prompt, contains('Character portrait avatar'));
    expect(prompt, contains('银白狐耳与朱红巫女服'));
  });
}
