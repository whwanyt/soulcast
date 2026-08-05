/// Agent 文件库中的单个条目（图片或普通文件）。
enum AgentLibraryItemKind { image, file }

/// 位于 [AppDirectories.agent] 下的本地文件元数据。
class AgentLibraryItem {
  const AgentLibraryItem({
    required this.path,
    required this.name,
    required this.bytes,
    required this.modifiedAt,
    required this.kind,
  });

  final String path;
  final String name;
  final int bytes;
  final DateTime modifiedAt;
  final AgentLibraryItemKind kind;

  bool get isImage => kind == AgentLibraryItemKind.image;
}
