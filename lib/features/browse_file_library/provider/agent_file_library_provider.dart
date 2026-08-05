import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/agent_library_item.dart';
import '../service/agent_library_deleter.dart';
import '../service/agent_library_scanner.dart';

part 'agent_file_library_provider.g.dart';

/// 扫描 Agent 文件库所需的扫描器。
@Riverpod(keepAlive: true)
AgentLibraryScanner agentLibraryScanner(Ref ref) {
  return const AgentLibraryScanner();
}

/// 删除 Agent 文件库文件所需的删除器。
@Riverpod(keepAlive: true)
AgentLibraryDeleter agentLibraryDeleter(Ref ref) {
  return const AgentLibraryDeleter();
}

/// Agent 目录下的图片与文件列表，按修改时间倒序。
@riverpod
class AgentFileLibrary extends _$AgentFileLibrary {
  @override
  Future<List<AgentLibraryItem>> build() {
    return ref.read(agentLibraryScannerProvider).scan();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// 删除指定文件并刷新列表。
  Future<void> deleteItem(AgentLibraryItem item) async {
    await ref.read(agentLibraryDeleterProvider).delete(item.path);
    await refresh();
  }
}
