import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import '../providers.dart';
import '../repository.dart';
import '../action/app_start_action.dart';

/// 应用启动作用域Widget
class AppStartScope<S> extends StatelessWidget {
  final AppStartRepository<S> repository;
  final AppStartAction<S> appStartAction;
  final int minStartDurationMs;
  final Widget child;
  final List<ProviderObserver>? observers;
  final List<Override>? overrides;
  final Duration? Function(int, Object)? retry;

  const AppStartScope({
    super.key,
    required this.repository,
    required this.appStartAction,
    required this.child,
    this.observers,
    this.overrides,
    this.retry,
    this.minStartDurationMs = 600,
  });

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      observers: observers,
      overrides: [
        appStartConfigProvider.overrideWithValue(
          AppStartConfig<S>(
            repository: repository,
            startAction: appStartAction,
            minStartDurationMs: minStartDurationMs,
          ),
        ),
        ...overrides ?? [],
      ],
      retry: retry,
      child: child,
    );
  }
}
