import 'package:flute_core/log/log.dart';
import 'package:soulcast/i18n/strings.g.dart';

import '../api/amap_http_client.dart';
import '../model/agent_tool_config.dart';
import '../model/agent_tool_ids.dart';
import '../model/amap_regeo.dart';
import 'agent_tool.dart';

/// 调用高德逆地理编码 API 将经纬度解析为地址的 Agent 工具。
class ReverseGeocodeTool extends AgentTool {
  const ReverseGeocodeTool({
    required this.resolveAmapKey,
    this.httpGet = amapHttpGet,
  });

  static const toolName = AgentToolIds.reverseGeocode;
  static const amapKeyParam = AgentToolIds.amapKey;

  final String Function() resolveAmapKey;
  final AmapHttpGet httpGet;

  @override
  String get name => toolName;

  @override
  String get displayName => t.agent.reverseGeocode.toolName;

  @override
  String get description => t.agent.reverseGeocode.toolDescription;

  @override
  List<AgentToolSettingField> get settingFields => [
    AgentToolSettingField(
      key: amapKeyParam,
      label: t.agent.reverseGeocode.amapKeyLabel,
      obscureText: true,
      hintText: t.agent.reverseGeocode.amapKeyHint,
    ),
  ];

  @override
  Map<String, dynamic> get parameters => const {
    'type': 'object',
    'properties': <String, dynamic>{
      'latitude': <String, dynamic>{
        'type': 'number',
        'description': 'Latitude in GCJ-02 degrees.',
      },
      'longitude': <String, dynamic>{
        'type': 'number',
        'description': 'Longitude in GCJ-02 degrees.',
      },
      'extensions': <String, dynamic>{
        'type': 'string',
        'enum': <String>[AmapRegeo.extensionsBase, AmapRegeo.extensionsAll],
        'description':
            'Data detail level. Use "base" for address/city components only. '
            'Use "all" when nearby POI/AOI/roads are needed.',
      },
      'radius': <String, dynamic>{
        'type': 'integer',
        'description':
            'Nearby POI search radius in meters (1-3000). '
            'Only useful when extensions is "all". Default 1000.',
      },
    },
    'required': <String>['latitude', 'longitude', 'extensions'],
    'additionalProperties': false,
  };

  @override
  bool get strict => true;

  @override
  Future<Map<String, dynamic>> run(Map<String, dynamic> arguments) async {
    final amapKey = resolveAmapKey().trim();
    if (amapKey.isEmpty) {
      return {
        'status': 'missing_amap_key',
        'message': t.agent.reverseGeocode.missingAmapKeyResult,
      };
    }

    final latitude = _readDouble(arguments['latitude']);
    final longitude = _readDouble(arguments['longitude']);
    final extensions = _readString(arguments['extensions'])?.toLowerCase();
    if (latitude == null ||
        longitude == null ||
        extensions == null ||
        !AmapRegeo.isValidExtensions(extensions)) {
      return {
        'status': 'invalid_arguments',
        'message': t.agent.reverseGeocode.invalidArgumentsResult,
      };
    }

    final radius =
        (_readInt(arguments['radius']) ?? AmapRegeo.defaultRadiusMeters).clamp(
          1,
          3000,
        );

    final uri = AmapRegeo.buildUri(
      amapKey: amapKey,
      longitude: longitude,
      latitude: latitude,
      extensions: extensions,
      radius: radius,
    );

    late final AmapHttpResponse response;
    try {
      response = await httpGet(uri);
    } catch (error, stackTrace) {
      Log.e(
        'ReverseGeocodeTool request failed: $error',
        tag: 'Tool',
        error: error,
        stackTrace: stackTrace,
      );
      return {
        'status': 'request_failed',
        'message': t.agent.reverseGeocode.requestFailedResult,
        'error': '$error',
      };
    }

    final statusCode = response.statusCode;
    if (statusCode < 200 || statusCode >= 300) {
      return {
        'status': 'request_failed',
        'message': t.agent.reverseGeocode.requestFailedResult,
        'httpStatus': statusCode,
      };
    }

    final decoded = response.data;
    if (decoded is! Map) {
      return {
        'status': 'invalid_response',
        'message': t.agent.reverseGeocode.invalidResponseResult,
      };
    }
    final payload = Map<String, dynamic>.from(decoded);

    final apiStatus = '${payload['status'] ?? ''}';
    if (apiStatus != '1') {
      return {
        'status': 'api_error',
        'message': t.agent.reverseGeocode.apiErrorResult,
        'info': payload['info'],
        'infocode': payload['infocode'],
      };
    }

    final regeocode = payload['regeocode'];
    if (regeocode is! Map) {
      return {
        'status': 'invalid_response',
        'message': t.agent.reverseGeocode.invalidResponseResult,
      };
    }

    return {
      'status': 'success',
      'latitude': latitude,
      'longitude': longitude,
      'extensions': extensions,
      'radius': radius,
      'regeocode': Map<String, dynamic>.from(regeocode),
    };
  }

  static double? _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }

  static int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  static String? _readString(Object? value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return null;
  }
}
