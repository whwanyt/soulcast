import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'repository.dart';
import 'action/app_start_action.dart';
import 'widgets/app_start_scope.dart';

/// 应用启动混入类
mixin AppStarter<T> implements AppStartAction<T> {
  /// 应用Widget
  Widget get app;

  /// 启动仓库
  AppStartRepository<T> get repository;

  List<ProviderObserver>? get observers;
  List<Override>? get overrides;
  Duration? Function(int, Object)? get retry;

  /// 运行应用
  void run(List<String> args) {
    runZonedGuarded(_runApp, onGlobalError);
  }

  /// 启动应用
  void _runApp() {
    runApp(
      AppStartScope<T>(
        repository: repository,
        appStartAction: this,
        overrides: overrides,
        observers: observers,
        retry: retry,
        child: app,
      ),
    );
  }

  /// 全局错误处理
  void onGlobalError(Object error, StackTrace stack) {
    // 处理全局错误
  }
}
