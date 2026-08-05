import 'package:flute_core/log/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:soulcast/entities/agent_tool/agent_tool.dart';
import 'package:soulcast/entities/ai_provider/ai_provider.dart';
import 'package:soulcast/shared/storage/isar_database.dart';
import 'package:soulcast/features/agent/llm.dart';

import '../model/agent_tool_config.dart';
import '../service/agent_tool.dart';
import '../service/current_location_tool.dart';
import '../service/current_time_tool.dart';
import '../service/generate_image_tool.dart';
import '../service/reverse_geocode_tool.dart';
import '../service/show_location_map_tool.dart';
import '../service/show_weather_tool.dart';
import '../widget/location_permission_dialog.dart';

part 'agent_tools.g.dart';

/// 组装应用支持的全部本地 Agent 工具及其运行时依赖。
@Riverpod(keepAlive: true)
List<AgentTool> availableAgentTools(Ref ref) {
  return [
    const CurrentTimeTool(),
    const CurrentLocationTool(
      permissionDialog: SmartLocationPermissionDialog(),
    ),
    ShowLocationMapTool(
      resolveAmapKey: () {
        final config = ref.read(
          agentToolConfigsProvider,
        )[ShowLocationMapTool.toolName];
        return config?.stringParam(ShowLocationMapTool.amapKeyParam) ?? '';
      },
    ),
    ReverseGeocodeTool(
      resolveAmapKey: () {
        final config = ref.read(
          agentToolConfigsProvider,
        )[ReverseGeocodeTool.toolName];
        return config?.stringParam(ReverseGeocodeTool.amapKeyParam) ?? '';
      },
    ),
    ShowWeatherTool(
      resolveAmapKey: () {
        final config = ref.read(
          agentToolConfigsProvider,
        )[ShowWeatherTool.toolName];
        return config?.stringParam(ShowWeatherTool.amapKeyParam) ?? '';
      },
    ),
    GenerateImageTool(
      resolveImageModel: () async {
        final config = ref.read(
          agentToolConfigsProvider,
        )[GenerateImageTool.toolName];
        final modelId =
            config?.stringParam(GenerateImageTool.imageModelIdParam) ?? '';
        if (modelId.isEmpty) {
          return null;
        }
        final repository = await ref.read(aiProviderRepositoryProvider.future);
        return repository.getModel(modelId);
      },
      resolveClientSettings: (modelId) async {
        final repository = await ref.read(aiProviderRepositoryProvider.future);
        return resolveProviderClientSettings(
          repository: repository,
          modelId: modelId,
        );
      },
    ),
  ];
}

/// 管理 Agent 工具配置，并串行同步到本地仓库。
@Riverpod(keepAlive: true)
class AgentToolConfigs extends _$AgentToolConfigs {
  /// 防止启动 restore 的异步结果覆盖用户已写入的新状态。
  int _epoch = 0;

  /// 串行化落库，避免 TextField 连续 onChanged 并发写入乱序覆盖。
  Future<void> _persistQueue = Future<void>.value();

  @override
  Map<String, AgentToolConfig> build() {
    return {
      for (final tool in ref.read(availableAgentToolsProvider))
        tool.name: const AgentToolConfig(enabled: true),
    };
  }

  Future<void> restore() async {
    final epoch = _epoch;
    try {
      final repository = await _repository();
      if (epoch != _epoch) {
        return;
      }
      final storedById = {
        for (final entity in repository.getAll()) entity.id: entity,
      };
      final tools = ref.read(availableAgentToolsProvider);
      final next = <String, AgentToolConfig>{
        for (final tool in tools)
          tool.name:
              _configFromEntity(storedById[tool.name]) ??
              state[tool.name] ??
              const AgentToolConfig(enabled: true),
      };
      if (epoch != _epoch) {
        return;
      }
      state = next;
      Log.d(
        'Agent tool configs restored: stored=${storedById.length}, '
        'tools=${next.length}',
        tag: 'AgentTool',
      );
    } catch (error, stackTrace) {
      Log.e(
        'Agent tool configs restore failed: $error',
        tag: 'AgentTool',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void setEnabled(String toolName, {required bool isEnabled}) {
    final current = state[toolName];
    if (current == null || current.enabled == isEnabled) {
      return;
    }
    final updated = current.copyWith(enabled: isEnabled);
    _epoch++;
    state = {...state, toolName: updated};
    _enqueuePersist(toolName);
  }

  void setParam(String toolName, String key, String value) {
    final current = state[toolName];
    if (current == null) {
      return;
    }
    final nextParams = Map<String, dynamic>.from(current.params);
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      nextParams.remove(key);
    } else {
      nextParams[key] = trimmed;
    }
    final updated = current.copyWith(params: nextParams);
    if (updated.enabled == current.enabled &&
        _paramsEquals(updated.params, current.params)) {
      return;
    }
    _epoch++;
    state = {...state, toolName: updated};
    _enqueuePersist(toolName);
  }

  void _enqueuePersist(String toolName) {
    _persistQueue = _persistQueue
        .then((_) => _persistLatest(toolName))
        .catchError((Object error, StackTrace stackTrace) {
          Log.e(
            'Agent tool config persist queue error: tool=$toolName, error=$error',
            tag: 'AgentTool',
            error: error,
            stackTrace: stackTrace,
          );
        });
  }

  Future<void> _persistLatest(String toolName) async {
    final config = state[toolName];
    if (config == null) {
      return;
    }
    try {
      final repository = await _repository();
      // 再次读取，确保写入的是队列执行到此刻的最新内存态。
      final latest = state[toolName] ?? config;
      repository.upsert(
        toolName: toolName,
        enabled: latest.enabled,
        params: latest.params,
      );
      Log.d(
        'Agent tool config persisted: tool=$toolName, '
        'enabled=${latest.enabled}, params=${latest.params.keys.toList()}',
        tag: 'AgentTool',
      );
    } catch (error, stackTrace) {
      Log.e(
        'Agent tool config persist failed: tool=$toolName, error=$error',
        tag: 'AgentTool',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<AgentToolConfigRepository> _repository() async {
    final isar = await ref.read(appIsarProvider.future);
    return AgentToolConfigRepository(isar);
  }

  static bool _paramsEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  static AgentToolConfig? _configFromEntity(AgentToolConfigEntity? entity) {
    if (entity == null) {
      return null;
    }
    return AgentToolConfig(
      enabled: entity.enabled,
      params: AgentToolConfigRepository.decodeParams(entity.paramsJson),
    );
  }
}

/// 返回当前已启用、可暴露给模型的本地 Agent 工具。
@Riverpod(keepAlive: true)
List<AgentTool> agentTools(Ref ref) {
  final configs = ref.watch(agentToolConfigsProvider);
  return ref
      .watch(availableAgentToolsProvider)
      .where((tool) => configs[tool.name]?.enabled ?? true)
      .toList(growable: false);
}
