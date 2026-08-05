import 'package:flutter/material.dart';

/// 应用修复动作回调接口
abstract class AppFixAction {
  const AppFixAction();

  /// 修复失败回调
  void onFixError(BuildContext context, Object error, StackTrace trace);

  /// 修复成功回调
  void onFixSuccess(BuildContext context);
}
