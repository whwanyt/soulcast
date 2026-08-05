import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 应用启动动作回调接口
abstract class AppStartAction<S> {
  const AppStartAction();

  /// 初始化加载失败回调
  void onStartError(
    BuildContext context,
    WidgetRef ref,
    Object error,
    StackTrace trace,
  );

  /// 初始化加载成功回调
  void onLoaded(BuildContext context, WidgetRef ref, int cost, S state);

  /// 初始化成功且达到最低延迟时间回调
  void onStartSuccess(BuildContext context, WidgetRef ref, S state);
}
