import 'dart:convert';

import 'package:isar_plus/isar_plus.dart';

import '../mcp_server_config_entity.dart';

/// MCP Server 配置的 Isar 读写仓库。
class McpServerConfigRepository {
  const McpServerConfigRepository(this._isar);

  final Isar _isar;

  List<McpServerConfigEntity> getAll() {
    return _sort(
      _isar.collection<String, McpServerConfigEntity>().where().findAll(),
    );
  }

  Stream<List<McpServerConfigEntity>> watchAll() {
    return _isar
        .collection<String, McpServerConfigEntity>()
        .where()
        .watch(fireImmediately: true)
        .map(_sort);
  }

  McpServerConfigEntity? getById(String serverId) {
    return _isar.collection<String, McpServerConfigEntity>().get(serverId);
  }

  McpServerConfigEntity upsert({
    String? serverId,
    required String name,
    required String url,
    bool? enabled,
    String? bearerToken,
    List<String>? disabledToolNames,
  }) {
    final now = DateTime.now();
    final id = serverId ?? createServerId();
    late McpServerConfigEntity entity;
    _isar.write((isar) {
      final collection = isar.collection<String, McpServerConfigEntity>();
      final existing = collection.get(id);
      final nextDisabled = disabledToolNames == null
          ? (existing?.disabledToolNamesJson ?? '[]')
          : encodeDisabledToolNames(disabledToolNames);
      entity =
          existing?.copyWith(
            name: name.trim(),
            url: _normalizeUrl(url),
            enabled: enabled ?? existing.enabled,
            bearerToken: bearerToken?.trim() ?? existing.bearerToken,
            disabledToolNamesJson: nextDisabled,
            updatedAt: now,
          ) ??
          McpServerConfigEntity(
            id: id,
            name: name.trim(),
            url: _normalizeUrl(url),
            enabled: enabled ?? true,
            bearerToken: bearerToken?.trim() ?? '',
            disabledToolNamesJson: nextDisabled,
            createdAt: now,
            updatedAt: now,
          );
      collection.put(entity);
    });
    return entity;
  }

  bool delete(String serverId) {
    var deleted = false;
    _isar.write((isar) {
      deleted = isar.collection<String, McpServerConfigEntity>().delete(
        serverId,
      );
    });
    return deleted;
  }

  String createServerId() {
    return 'mcp_${DateTime.now().microsecondsSinceEpoch}';
  }

  static List<String> decodeDisabledToolNames(String json) {
    if (json.trim().isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(json);
    if (decoded is! List) {
      return const [];
    }
    return [
      for (final item in decoded)
        if (item != null) item.toString(),
    ];
  }

  static String encodeDisabledToolNames(List<String> names) {
    return jsonEncode(names);
  }

  static String _normalizeUrl(String url) {
    return url.trim();
  }

  static List<McpServerConfigEntity> _sort(List<McpServerConfigEntity> items) {
    final sorted = [...items]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted;
  }
}
