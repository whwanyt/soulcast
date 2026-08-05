import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_start_state.dart';
import '../providers.dart';

/// 应用启动状态监听器Widget
class AppStartListener<S> extends ConsumerWidget {
  final Widget child;

  const AppStartListener({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appStartConfigProvider) as AppStartConfig<S>;

    ref.listen<AppStartState>(appStartStateProvider, (previous, next) {
      if (next is AppLoadDone<S>) {
        config.startAction.onLoaded(context, ref, next.cost, next.data);
      } else if (next is AppStartSuccess<S>) {
        config.startAction.onStartSuccess(context, ref, next.data);
      } else if (next is AppStartFailed<S>) {
        config.startAction.onStartError(context, ref, next.error, next.trace);
      }
    });
    return child;
  }
}
