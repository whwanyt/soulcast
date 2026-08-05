import 'package:flute_core/log/log.dart';
import 'package:soulcast/i18n/strings.g.dart';

import '../api/amap_http_client.dart';
import '../model/agent_tool_config.dart';
import '../model/agent_tool_ids.dart';
import '../model/amap_weather.dart';
import 'agent_tool.dart';

/// 查询高德实时天气并返回结构化展示标签的 Agent 工具。
class ShowWeatherTool extends AgentTool {
  const ShowWeatherTool({
    required this.resolveAmapKey,
    this.httpGet = amapHttpGet,
  });

  static const toolName = AgentToolIds.showWeather;
  static const amapKeyParam = AgentToolIds.amapKey;

  final String Function() resolveAmapKey;
  final AmapHttpGet httpGet;

  @override
  String get name => toolName;

  @override
  String get displayName => t.agent.showWeather.toolName;

  @override
  String get description => t.agent.showWeather.toolDescription;

  @override
  List<AgentToolSettingField> get settingFields => [
    AgentToolSettingField(
      key: amapKeyParam,
      label: t.agent.showWeather.amapKeyLabel,
      obscureText: true,
      hintText: t.agent.showWeather.amapKeyHint,
    ),
  ];

  @override
  Map<String, dynamic> get parameters => const {
    'type': 'object',
    'properties': <String, dynamic>{
      'city': <String, dynamic>{
        'type': 'string',
        'description':
            'AMap city adcode (e.g. 110101). Prefer district-level adcode '
            'from reverse_geocode when available.',
      },
    },
    'required': <String>['city'],
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
        'message': t.agent.showWeather.missingAmapKeyResult,
      };
    }

    final city = _readString(arguments['city']);
    if (city == null) {
      return {
        'status': 'invalid_arguments',
        'message': t.agent.showWeather.invalidArgumentsResult,
      };
    }

    final uri = AmapWeather.buildUri(amapKey: amapKey, city: city);

    late final AmapHttpResponse response;
    try {
      response = await httpGet(uri);
    } catch (error, stackTrace) {
      Log.e(
        'ShowWeatherTool request failed: $error',
        tag: 'Tool',
        error: error,
        stackTrace: stackTrace,
      );
      return {
        'status': 'request_failed',
        'message': t.agent.showWeather.requestFailedResult,
        'error': '$error',
      };
    }

    final statusCode = response.statusCode;
    if (statusCode < 200 || statusCode >= 300) {
      return {
        'status': 'request_failed',
        'message': t.agent.showWeather.requestFailedResult,
        'httpStatus': statusCode,
      };
    }

    final decoded = response.data;
    if (decoded is! Map) {
      return {
        'status': 'invalid_response',
        'message': t.agent.showWeather.invalidResponseResult,
      };
    }
    final payload = Map<String, dynamic>.from(decoded);

    final apiStatus = '${payload['status'] ?? ''}';
    if (apiStatus != '1') {
      return {
        'status': 'api_error',
        'message': t.agent.showWeather.apiErrorResult,
        'info': payload['info'],
        'infocode': payload['infocode'],
      };
    }

    final lives = payload['lives'];
    if (lives is! List || lives.isEmpty || lives.first is! Map) {
      return {
        'status': 'invalid_response',
        'message': t.agent.showWeather.invalidResponseResult,
      };
    }

    final live = AmapWeather.liveFromJson(
      Map<String, dynamic>.from(lives.first as Map),
    );
    if (live == null) {
      return {
        'status': 'invalid_response',
        'message': t.agent.showWeather.invalidResponseResult,
      };
    }

    final withBg = live.copyWith(
      bg: AmapWeather.resolveBg(live.weather, bg: live.bg).name,
    );

    return {
      'status': 'success',
      'city': city,
      'live': withBg.toJson(),
      'markdown': AmapWeather.buildMarkdownTag(withBg),
    };
  }

  static String? _readString(Object? value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (value is num) {
      return '$value';
    }
    return null;
  }
}
