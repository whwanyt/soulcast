import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soulcast/shared/widgets/app_text_field.dart';

void main() {
  testWidgets('AppTextField supports shared decoration and validation', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        home: Scaffold(
          body: Form(
            key: formKey,
            child: AppTextField(
              labelText: '名称',
              hintText: '请输入名称',
              prefixIcon: const Icon(Icons.edit),
              validator: (value) =>
                  value?.trim().isEmpty ?? true ? '不能为空' : null,
            ),
          ),
        ),
      ),
    );

    final textField = tester.widget<TextField>(find.byType(TextField));
    // InputDecorator 合并 theme 后的生效边框在 InputDecorationTheme；
    // TextField.decoration.border 可能仍为 null，因此同时校验 theme。
    final themeBorder =
        Theme.of(
              tester.element(find.byType(TextField)),
            ).inputDecorationTheme.border!
            as OutlineInputBorder;
    expect(themeBorder.borderRadius, BorderRadius.circular(8));
    expect(textField.decoration?.labelText, '名称');
    expect(find.text('名称'), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsOneWidget);

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('不能为空'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Soulcast');
    expect(formKey.currentState!.validate(), isTrue);
  });
}
