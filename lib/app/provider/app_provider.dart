import 'dart:ui';
import 'package:flute_core/log/log.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_provider.g.dart';
part 'app_provider.freezed.dart';

/// 维护屏幕尺寸、安全区与像素密度等全局显示信息。
@Riverpod(keepAlive: true)
class App extends _$App {
  @override
  AppModel build() {
    return AppModel.init();
  }

  void init(BuildContext context) {
    final MediaQueryData mediaQueryData = MediaQuery.of(context);
    double pixelRatio = mediaQueryData.devicePixelRatio;
    Size size = mediaQueryData.size;
    double width = size.width;
    double height = size.height;
    double statusBarHeight = mediaQueryData.padding.top;
    double bottomBarHeight = mediaQueryData.padding.bottom;
    state = state.copyWith(
      pixelRatio: pixelRatio,
      width: width,
      height: height,
      statusBarHeight: statusBarHeight,
      bottomBarHeight: bottomBarHeight,
    );
    Log.d("App update: ${state.toJson()}");
  }
}

/// 当前 Flutter View 的显示参数快照。
@freezed
@JsonSerializable()
class AppModel with _$AppModel {
  @override
  final double pixelRatio;
  @override
  final double width;
  @override
  final double height;
  @override
  final double statusBarHeight;
  @override
  final double bottomBarHeight;
  @override
  final bool isDarkMode;

  Size get size => Size(width, height);

  const AppModel({
    required this.pixelRatio,
    required this.width,
    required this.height,
    required this.statusBarHeight,
    required this.bottomBarHeight,
    required this.isDarkMode,
  });

  factory AppModel.fromJson(Map<String, dynamic> json) =>
      _$AppModelFromJson(json);

  Map<String, dynamic> toJson() => _$AppModelToJson(this);

  factory AppModel.init() {
    FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;
    final MediaQueryData mediaQueryData = MediaQueryData.fromView(view);
    double pixelRatio = mediaQueryData.devicePixelRatio;
    Size size = view.physicalSize / pixelRatio;
    double width = size.width;
    double height = size.height;
    double statusBarHeight = mediaQueryData.padding.top;
    double bottomBarHeight = mediaQueryData.padding.bottom;

    return AppModel(
      pixelRatio: pixelRatio,
      width: width,
      height: height,
      statusBarHeight: statusBarHeight,
      bottomBarHeight: bottomBarHeight,
      isDarkMode: false,
    );
  }
}
