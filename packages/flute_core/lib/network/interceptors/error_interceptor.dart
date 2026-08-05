import 'package:dio/dio.dart';
import 'package:flute_core/log/log.dart';
import '../exceptions/network_exception.dart';

/// 错误处理拦截器
/// 统一处理网络请求中的错误，提供友好的错误信息
class ErrorInterceptor extends Interceptor {
  /// 是否显示错误提示
  final bool showErrorToast;

  /// 构造函数
  /// [showErrorToast] 是否显示错误提示
  const ErrorInterceptor({this.showErrorToast = true});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 创建统一的网络异常
    final networkException = NetworkException.fromDioException(err);

    // 记录错误日志
    _logError(networkException);

    // 显示错误提示（可选）
    if (showErrorToast) {
      _showErrorMessage(networkException.message);
    }

    // 继续传递错误
    super.onError(err, handler);
  }

  /// 记录错误日志
  /// [exception] 网络异常
  void _logError(NetworkException exception) {
    // 这里可以集成日志系统，如Sentry、Firebase Crashlytics等
    Log.e('Network Error: ${exception.toString()}');
  }

  /// 显示错误消息
  /// [message] 错误消息
  void _showErrorMessage(String message) {
    // 这里可以集成Toast或Snackbar显示错误信息
    // 例如：Fluttertoast.showToast(msg: message);
    Log.e('Error Message: $message');
  }
}
