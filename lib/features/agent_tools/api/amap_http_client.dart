import 'package:dio/dio.dart';

/// 高德 REST 请求结果（不向外暴露 Dio 类型）。
class AmapHttpResponse {
  const AmapHttpResponse({required this.statusCode, this.data});

  final int statusCode;
  final Object? data;
}

/// 高德 REST GET 请求 Port。
typedef AmapHttpGet = Future<AmapHttpResponse> Function(Uri uri);

/// 默认高德 HTTP GET；`validateStatus` 放行全部状态码，由调用方判失败。
Future<AmapHttpResponse> amapHttpGet(Uri uri) async {
  final response = await Dio().getUri<dynamic>(
    uri,
    options: Options(validateStatus: (_) => true),
  );
  return AmapHttpResponse(
    statusCode: response.statusCode ?? 0,
    data: response.data,
  );
}
