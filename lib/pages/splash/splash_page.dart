import 'dart:ui' show lerpDouble;

import 'package:flute_core/app/app_start_state.dart';
import 'package:flute_core/app/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soulcast/app/router/app_router.dart';
import 'package:soulcast/i18n/strings.g.dart';
import 'package:soulcast/shared/provider/app_preferences_provider.dart';
import 'package:soulcast/shared/theme/app_ui.dart';

/// 展示应用初始化状态并在成功后进入主页面的启动页。
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  static const _logoSize = 96.0;
  static const _revealDuration = Duration(milliseconds: 1000);
  static const _statusFadeDuration = Duration(milliseconds: 300);

  late final AnimationController _revealController;
  late final AnimationController _statusFadeController;
  late final Animation<double> _revealProgress;
  late final Animation<double> _logoTurns;
  late final Animation<double> _statusFade;

  bool _enteringMain = false;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: _revealDuration,
    );
    _statusFadeController = AnimationController(
      vsync: this,
      duration: _statusFadeDuration,
    );

    final revealCurved = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeInOutCubic,
    );
    _revealProgress = revealCurved;
    _logoTurns = Tween<double>(begin: 0, end: 1).animate(revealCurved);
    _statusFade = CurvedAnimation(
      parent: _statusFadeController,
      curve: Curves.easeOut,
    );

    _revealController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _statusFadeController.forward();
        _tryEnterMain();
      }
    });
    _revealController.forward();
  }

  @override
  void dispose() {
    _revealController.dispose();
    _statusFadeController.dispose();
    super.dispose();
  }

  Future<void> _tryEnterMain() async {
    if (_enteringMain || !_revealController.isCompleted) {
      return;
    }
    if (ref.read(appStartStateProvider) is! AppStartSuccess) {
      return;
    }
    _enteringMain = true;
    await ref.read(appPreferencesProvider.notifier).restore();
    if (!mounted) {
      return;
    }
    const MainRoute().go(context);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AppStartState>(appStartStateProvider, (previous, next) {
      if (next is AppStartSuccess) {
        _tryEnterMain();
      }
    });

    final startState = ref.watch(appStartStateProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isFailed = startState is AppStartFailed;
    final screen = MediaQuery.sizeOf(context);
    final coverSide =
        (screen.width > screen.height ? screen.width : screen.height) * 2;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: _logoSize,
                        height: _logoSize,
                        child: AnimatedBuilder(
                          animation: _revealProgress,
                          builder: (context, child) {
                            final t = _revealProgress.value;
                            final side = lerpDouble(coverSide, _logoSize, t)!;
                            final radius = lerpDouble(
                              coverSide / 2,
                              AppRadii.xl,
                              t,
                            )!;
                            return Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                OverflowBox(
                                  minWidth: side,
                                  maxWidth: side,
                                  minHeight: side,
                                  maxHeight: side,
                                  child: SizedBox(
                                    width: side,
                                    height: side,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(
                                          radius,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                child!,
                              ],
                            );
                          },
                          child: RotationTransition(
                            turns: _logoTurns,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadii.xl),
                              child: Image.asset(
                                'assets/page_app_icon.png',
                                width: _logoSize,
                                height: _logoSize,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) =>
                                    const SizedBox.square(dimension: _logoSize),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        t.appName,
                        style: textTheme.headlineMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            FadeTransition(
              opacity: _statusFade,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  0,
                  AppSpacing.xxl,
                  AppSpacing.xl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StartStatusText(state: startState),
                    const SizedBox(height: AppSpacing.md),
                    if (!isFailed)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartStatusText extends StatelessWidget {
  const _StartStatusText({required this.state});

  final AppStartState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
    );
    final failedStyle = textStyle?.copyWith(color: colorScheme.error);

    return switch (state) {
      AppStartFailed() => Text(
        context.t.splash.failed,
        style: failedStyle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
      AppLoadDone() => Text(
        context.t.splash.entering,
        style: textStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
      AppStartSuccess() => Text(
        context.t.splash.done,
        style: textStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
      _ => Text(
        context.t.splash.starting,
        style: textStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    };
  }
}
