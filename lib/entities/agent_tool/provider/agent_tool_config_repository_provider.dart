import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../repository/agent_tool_config_repository.dart';
import 'isar_provider.dart';

part 'agent_tool_config_repository_provider.g.dart';

/// 提供基于共享 Isar 实例的 Agent 工具配置仓库。
@Riverpod(keepAlive: true)
Future<AgentToolConfigRepository> agentToolConfigRepository(Ref ref) async {
  final isar = await ref.watch(agentToolIsarProvider.future);
  return AgentToolConfigRepository(isar);
}
