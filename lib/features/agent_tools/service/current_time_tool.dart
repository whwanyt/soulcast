import 'package:soulcast/i18n/strings.g.dart';

import '../model/agent_tool_ids.dart';
import 'agent_tool.dart';

/// 返回设备本地时间与时区信息的 Agent 工具。
class CurrentTimeTool extends AgentTool {
  const CurrentTimeTool();

  static const toolName = AgentToolIds.currentTime;

  @override
  String get name => toolName;

  @override
  String get displayName => t.agent.currentTimeToolName;

  @override
  String get description => t.agent.currentTimeToolDescription;

  @override
  Map<String, dynamic> get parameters => const {
    'type': 'object',
    'properties': <String, dynamic>{},
    'required': <String>[],
    'additionalProperties': false,
  };

  @override
  bool get strict => true;

  @override
  Future<Map<String, dynamic>> run(Map<String, dynamic> arguments) async {
    final now = DateTime.now();
    final utc = now.toUtc();
    return {
      'localIso8601': now.toIso8601String(),
      'utcIso8601': utc.toIso8601String(),
      'timeZoneName': now.timeZoneName,
      'timeZoneOffsetMinutes': now.timeZoneOffset.inMinutes,
      'timestampMilliseconds': now.millisecondsSinceEpoch,
    };
  }
}
