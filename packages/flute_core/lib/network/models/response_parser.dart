import 'package:dio/dio.dart';
import 'api_response.dart';

/// 响应解析器抽象类
/// 定义统一的响应解析接口，支持不同实体类型的响应结构
abstract class ResponseParser<T> {
  /// 从Dio响应解析为ApiResponse
  /// [response] Dio响应对象
  /// 返回解析后的ApiResponse对象
  ApiResponse<T> parseResponse(Response response);

  /// 解析响应数据
  /// [data] 响应数据
  /// 返回解析后的实体对象
  T? parseData(dynamic data);
}

/// 默认响应解析器
/// 提供标准的JSON响应解析实现
class DefaultResponseParser<T> extends ResponseParser<T> {
  /// 数据解析函数
  final T? Function(dynamic data)? dataParser;

  /// 构造函数
  /// [dataParser] 自定义数据解析函数
  DefaultResponseParser({this.dataParser});

  /// 创建处理response.data的默认解析器
  /// 专门用于提取response.data并包裹到ApiResponse中
  factory DefaultResponseParser.forResponseData() {
    return DefaultResponseParser<T>(dataParser: (data) => data as T?);
  }

  @override
  ApiResponse<T> parseResponse(Response response) {
    final responseData = response.data;
    return ApiResponse<T>(
      statusCode: response.statusCode ?? 200,
      message: 'Success',
      data: parseData(responseData),
      success: true,
      headers: response.headers,
    );
  }

  @override
  T? parseData(dynamic data) {
    if (dataParser != null) {
      return dataParser!(data);
    }
    return data as T?;
  }
}

/// 列表响应解析器
/// 专门处理列表类型的响应数据
class ListResponseParser<T> extends ResponseParser<List<T>> {
  /// 单个项目解析函数
  final T Function(dynamic item) itemParser;

  /// 数据解析函数（可选，用于处理整个响应数据）
  final List<T>? Function(dynamic data)? dataParser;

  /// 构造函数
  /// [itemParser] 单个项目解析函数
  /// [dataParser] 自定义数据解析函数
  ListResponseParser({required this.itemParser, this.dataParser});

  @override
  ApiResponse<List<T>> parseResponse(Response response) {
    final responseData = response.data;
    return ApiResponse<List<T>>(
      statusCode: response.statusCode ?? 200,
      message: 'Success',
      data: parseData(responseData),
      success: true,
      headers: response.headers,
    );
  }

  @override
  List<T>? parseData(dynamic data) {
    if (dataParser != null) {
      return dataParser!(data);
    }

    if (data is List) {
      return data.map((item) => itemParser(item)).toList();
    }
    return null;
  }
}
