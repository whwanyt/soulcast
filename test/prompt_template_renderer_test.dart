import 'package:flutter_test/flutter_test.dart';
import 'package:soulcast/shared/prompt/prompt.dart';

void main() {
  tearDown(() => PromptCommonTokens.sync(user: ''));

  test('renderPromptTemplate replaces declared tokens', () async {
    final rendered = await renderPromptTemplate('Hello {{name}}.', {
      'name': 'world',
    });
    expect(rendered, 'Hello world.');
  });

  test(
    'renderPromptTemplate falls back when primary template is invalid',
    () async {
      final rendered = await renderPromptTemplate('Hello {{', {
        'name': 'world',
      }, fallbackTemplate: 'Hello {{name}}.');
      expect(rendered, 'Hello world.');
    },
  );

  test('renderPromptTemplate injects common user token', () async {
    PromptCommonTokens.sync(user: '阿明');
    final rendered = await renderPromptTemplate('Hi {{user}}.', const {});
    expect(rendered, 'Hi 阿明.');
  });

  test('assemblePromptTokenValues merges common then business values', () {
    PromptCommonTokens.sync(user: '阿明');
    expect(assemblePromptTokenValues({'name': '小夜'}), {
      'user': '阿明',
      'name': '小夜',
    });
  });
}
