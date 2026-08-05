/// 应用状态数据模型
class AppState {
  final int modeType;

  const AppState(this.modeType);

  /// 创建副本
  AppState copyWith({int? modeType}) {
    return AppState(modeType ?? this.modeType);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppState && other.modeType == modeType;
  }

  @override
  int get hashCode => modeType.hashCode;
}
