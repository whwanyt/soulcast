part of 'chat_service.dart';

/// 生图工具结果到聊天消息片段的映射。
mixin _ChatImageResultMapper {
  /// 从 generate_image 工具结果提取 [ChatImagePart]。
  List<ChatMessagePart> _imagePartsFromToolResults({
    required List<_ToolCallResult> toolResults,
    required String turnId,
    required int round,
  }) {
    final parts = <ChatMessagePart>[];
    var index = 0;
    for (final result in toolResults) {
      if (result.part.toolName != AgentToolIds.generateImage) {
        continue;
      }
      final imagePart = _imagePartFromGenerateImageResult(
        toolPart: result.part,
        id: '${turnId}_img${round}_$index',
      );
      if (imagePart != null) {
        parts.add(imagePart);
        index += 1;
      }
    }
    return parts;
  }

  ChatImagePart? _imagePartFromGenerateImageResult({
    required ChatToolCallPart toolPart,
    required String id,
  }) {
    final raw = toolPart.result;
    if (raw == null || raw.trim().isEmpty) {
      if (toolPart.status == ChatToolCallPartStatus.failed) {
        return ChatImagePart(
          id: id,
          status: ChatImagePartStatus.failed,
          errorMessage: t.agent.generateImage.requestFailedResult,
        );
      }
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      final map = Map<String, dynamic>.from(decoded);
      final status = map['status'] as String?;
      final url = (map['url'] as String?)?.trim();
      final revisedPrompt = (map['revisedPrompt'] as String?)?.trim();
      final message = (map['message'] as String?)?.trim();

      if (status == 'success' && url != null && url.isNotEmpty) {
        return ChatImagePart(
          id: id,
          status: ChatImagePartStatus.ready,
          url: url,
          revisedPrompt: revisedPrompt == null || revisedPrompt.isEmpty
              ? null
              : revisedPrompt,
        );
      }

      return ChatImagePart(
        id: id,
        status: ChatImagePartStatus.failed,
        errorMessage: message == null || message.isEmpty
            ? t.agent.generateImage.requestFailedResult
            : message,
      );
    } catch (_) {
      if (toolPart.status == ChatToolCallPartStatus.failed) {
        return ChatImagePart(
          id: id,
          status: ChatImagePartStatus.failed,
          errorMessage: t.agent.generateImage.requestFailedResult,
        );
      }
      return null;
    }
  }

  bool _hasReadyImagePart(List<ChatMessagePart> parts) {
    return parts.any(
      (part) =>
          part is ChatImagePart && part.status == ChatImagePartStatus.ready,
    );
  }

  /// 已有 [ChatImagePart] 时去掉正文里的 markdown 图片，避免重复展示。
  List<ChatMessagePart> _sanitizeTextPartsWhenImagePresent(
    List<ChatMessagePart> parts, {
    required bool hasReadyImage,
  }) {
    if (!hasReadyImage) {
      return parts;
    }
    final imageMarkdown = RegExp(r'!\[[^\]]*\]\([^)]*\)');
    final result = <ChatMessagePart>[];
    for (final part in parts) {
      if (part is! ChatTextPart) {
        result.add(part);
        continue;
      }
      final cleaned = part.content
          .replaceAll(imageMarkdown, '')
          .replaceAll(RegExp(r'\n{3,}'), '\n\n')
          .trim();
      if (cleaned.isEmpty) {
        continue;
      }
      result.add(part.copyWith(content: cleaned));
    }
    return result;
  }
}
