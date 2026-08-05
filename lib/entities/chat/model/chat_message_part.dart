/// 工具调用消息片段的执行状态。
enum ChatToolCallPartStatus { running, completed, failed }

/// 图片生成消息片段的执行状态。
enum ChatImagePartStatus { generating, ready, failed }

/// 用户附件类型。
enum ChatAttachmentKind { image, document }

/// 会话消息内按顺序排列的结构化内容片段。
///
/// 助手 turn 使用 reasoning / text / tool_call / image；
/// 用户消息使用 attachment 承载本地附件。
sealed class ChatMessagePart {
  const ChatMessagePart({required this.id});

  final String id;

  String get fingerprint;

  Map<String, dynamic> toJson();

  static ChatMessagePart fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    return switch (type) {
      'reasoning' => ChatReasoningPart(
        id: json['id'] as String,
        content: json['content'] as String? ?? '',
      ),
      'text' => ChatTextPart(
        id: json['id'] as String,
        content: json['content'] as String? ?? '',
      ),
      'tool_call' => ChatToolCallPart(
        id: json['id'] as String,
        toolCallId: json['toolCallId'] as String? ?? json['id'] as String,
        toolName: json['toolName'] as String? ?? '',
        arguments: json['arguments'] as String?,
        result: json['result'] as String?,
        status: ChatToolCallPartStatus.values.firstWhere(
          (value) => value.name == json['status'],
          orElse: () => ChatToolCallPartStatus.completed,
        ),
      ),
      'image' => ChatImagePart(
        id: json['id'] as String,
        status: ChatImagePartStatus.values.firstWhere(
          (value) => value.name == json['status'],
          orElse: () => ChatImagePartStatus.ready,
        ),
        url: json['url'] as String?,
        revisedPrompt: json['revisedPrompt'] as String?,
        errorMessage: json['errorMessage'] as String?,
      ),
      'attachment' => ChatAttachmentPart(
        id: json['id'] as String,
        kind: ChatAttachmentKind.values.firstWhere(
          (value) => value.name == json['kind'],
          orElse: () => ChatAttachmentKind.document,
        ),
        fileName: json['fileName'] as String? ?? '',
        mimeType: json['mimeType'] as String? ?? '',
        localPath: json['localPath'] as String? ?? '',
        byteSize: (json['byteSize'] as num?)?.toInt(),
      ),
      _ => throw FormatException('Unknown chat message part type: $type'),
    };
  }
}

/// 模型推理内容片段。
class ChatReasoningPart extends ChatMessagePart {
  const ChatReasoningPart({required super.id, required this.content});

  final String content;

  @override
  String get fingerprint => 'reasoning:$id:${content.length}:$content';

  @override
  Map<String, dynamic> toJson() {
    return {'type': 'reasoning', 'id': id, 'content': content};
  }

  ChatReasoningPart copyWith({String? content}) {
    return ChatReasoningPart(id: id, content: content ?? this.content);
  }
}

/// 助手可见正文片段。
class ChatTextPart extends ChatMessagePart {
  const ChatTextPart({required super.id, required this.content});

  final String content;

  @override
  String get fingerprint => 'text:$id:${content.length}:$content';

  @override
  Map<String, dynamic> toJson() {
    return {'type': 'text', 'id': id, 'content': content};
  }

  ChatTextPart copyWith({String? content}) {
    return ChatTextPart(id: id, content: content ?? this.content);
  }
}

/// 工具调用参数、结果与执行状态片段。
class ChatToolCallPart extends ChatMessagePart {
  const ChatToolCallPart({
    required super.id,
    required this.toolCallId,
    required this.toolName,
    required this.status,
    this.arguments,
    this.result,
  });

  final String toolCallId;
  final String toolName;
  final ChatToolCallPartStatus status;
  final String? arguments;
  final String? result;

  @override
  String get fingerprint =>
      'tool:$id:$toolName:${status.name}:${arguments?.length ?? 0}:'
      '${result?.length ?? 0}';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'tool_call',
      'id': id,
      'toolCallId': toolCallId,
      'toolName': toolName,
      'status': status.name,
      if (arguments != null) 'arguments': arguments,
      if (result != null) 'result': result,
    };
  }

  ChatToolCallPart copyWith({
    ChatToolCallPartStatus? status,
    String? arguments,
    String? result,
  }) {
    return ChatToolCallPart(
      id: id,
      toolCallId: toolCallId,
      toolName: toolName,
      status: status ?? this.status,
      arguments: arguments ?? this.arguments,
      result: result ?? this.result,
    );
  }
}

/// 图片生成过程与最终资源片段。
class ChatImagePart extends ChatMessagePart {
  const ChatImagePart({
    required super.id,
    required this.status,
    this.url,
    this.revisedPrompt,
    this.errorMessage,
  });

  final ChatImagePartStatus status;
  final String? url;
  final String? revisedPrompt;
  final String? errorMessage;

  bool get hasDisplayUrl {
    final value = url?.trim();
    return value != null && value.isNotEmpty;
  }

  @override
  String get fingerprint =>
      'image:$id:${status.name}:${url ?? ''}:${revisedPrompt ?? ''}:'
      '${errorMessage ?? ''}';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'image',
      'id': id,
      'status': status.name,
      if (url != null) 'url': url,
      if (revisedPrompt != null) 'revisedPrompt': revisedPrompt,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }

  ChatImagePart copyWith({
    ChatImagePartStatus? status,
    Object? url = _unset,
    Object? revisedPrompt = _unset,
    Object? errorMessage = _unset,
  }) {
    return ChatImagePart(
      id: id,
      status: status ?? this.status,
      url: identical(url, _unset) ? this.url : url as String?,
      revisedPrompt: identical(revisedPrompt, _unset)
          ? this.revisedPrompt
          : revisedPrompt as String?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

/// 用户消息中的本地附件片段（图片或基础文档）。
class ChatAttachmentPart extends ChatMessagePart {
  const ChatAttachmentPart({
    required super.id,
    required this.kind,
    required this.fileName,
    required this.mimeType,
    required this.localPath,
    this.byteSize,
  });

  final ChatAttachmentKind kind;
  final String fileName;
  final String mimeType;

  /// 本地绝对路径或 `file://` URI。
  final String localPath;
  final int? byteSize;

  bool get isImage => kind == ChatAttachmentKind.image;

  bool get isDocument => kind == ChatAttachmentKind.document;

  @override
  String get fingerprint =>
      'attachment:$id:${kind.name}:$fileName:$mimeType:$localPath:'
      '${byteSize ?? ''}';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'attachment',
      'id': id,
      'kind': kind.name,
      'fileName': fileName,
      'mimeType': mimeType,
      'localPath': localPath,
      if (byteSize != null) 'byteSize': byteSize,
    };
  }
}

class _Unset {
  const _Unset();
}

const _unset = _Unset();
