import 'dart:convert';

import 'package:isar_plus/isar_plus.dart';

import '../agent_tool_config_entity.dart';

/// Agent 工具配置的 Isar 读写仓库。
class AgentToolConfigRepository {
  const AgentToolConfigRepository(this._isar);

  final Isar _isar;

  List<AgentToolConfigEntity> getAll() {
    return _isar.collection<String, AgentToolConfigEntity>().where().findAll();
  }

  AgentToolConfigEntity? getById(String toolName) {
    return _isar.collection<String, AgentToolConfigEntity>().get(toolName);
  }

  AgentToolConfigEntity upsert({
    required String toolName,
    required bool enabled,
    required Map<String, dynamic> params,
  }) {
    final now = DateTime.now();
    final paramsJson = jsonEncode(params);
    late AgentToolConfigEntity entity;
    _isar.write((isar) {
      final collection = isar.collection<String, AgentToolConfigEntity>();
      final existing = collection.get(toolName);
      entity =
          existing?.copyWith(
            enabled: enabled,
            paramsJson: paramsJson,
            updatedAt: now,
          ) ??
          AgentToolConfigEntity(
            id: toolName,
            enabled: enabled,
            paramsJson: paramsJson,
            updatedAt: now,
          );
      collection.put(entity);
    });
    return entity;
  }

  static Map<String, dynamic> decodeParams(String paramsJson) {
    if (paramsJson.trim().isEmpty) {
      return const {};
    }
    final decoded = jsonDecode(paramsJson);
    if (decoded is! Map) {
      return const {};
    }
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }
}
