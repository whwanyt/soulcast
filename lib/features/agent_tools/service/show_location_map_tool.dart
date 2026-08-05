import 'package:soulcast/i18n/strings.g.dart';

import '../model/agent_tool_config.dart';
import '../model/agent_tool_ids.dart';
import '../model/amap_static_map.dart';
import 'agent_tool.dart';

/// 生成高德静态地图展示标签的 Agent 工具。
class ShowLocationMapTool extends AgentTool {
  const ShowLocationMapTool({required this.resolveAmapKey});

  static const toolName = AgentToolIds.showLocationMap;
  static const amapKeyParam = AgentToolIds.amapKey;

  final String Function() resolveAmapKey;

  @override
  String get name => toolName;

  @override
  String get displayName => t.agent.showLocationMap.toolName;

  @override
  String get description => t.agent.showLocationMap.toolDescription;

  @override
  List<AgentToolSettingField> get settingFields => [
    AgentToolSettingField(
      key: amapKeyParam,
      label: t.agent.showLocationMap.amapKeyLabel,
      obscureText: true,
      hintText: t.agent.showLocationMap.amapKeyHint,
    ),
  ];

  @override
  Map<String, dynamic> get parameters => const {
    'type': 'object',
    'properties': <String, dynamic>{
      'latitude': <String, dynamic>{
        'type': 'number',
        'description': 'Latitude in WGS84 / GCJ-02 degrees.',
      },
      'longitude': <String, dynamic>{
        'type': 'number',
        'description': 'Longitude in WGS84 / GCJ-02 degrees.',
      },
      'zoom': <String, dynamic>{
        'type': 'integer',
        'description': 'Map zoom level from 1 to 17. Use 10 if unsure.',
      },
    },
    'required': <String>['latitude', 'longitude', 'zoom'],
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
        'message': t.agent.showLocationMap.missingAmapKeyResult,
      };
    }

    final latitude = _readDouble(arguments['latitude']);
    final longitude = _readDouble(arguments['longitude']);
    if (latitude == null || longitude == null) {
      return {
        'status': 'invalid_arguments',
        'message': t.agent.showLocationMap.invalidArgumentsResult,
      };
    }

    final zoom =
        _readInt(arguments['zoom'])?.clamp(1, 17) ?? AmapStaticMap.defaultZoom;
    final markdown = AmapStaticMap.buildMarkdownTag(
      latitude: latitude,
      longitude: longitude,
      zoom: zoom,
    );

    return {
      'status': 'success',
      'latitude': latitude,
      'longitude': longitude,
      'zoom': zoom,
      'markdown': markdown,
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
}
