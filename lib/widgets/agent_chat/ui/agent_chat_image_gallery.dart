import 'package:flutter/material.dart';
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/shared/widgets/app_image_preview.dart';

final _markdownImagePattern = RegExp(r'!\[[^\]]*\]\(([^)\s]+)\)');

/// 按消息顺序收集会话中可预览的图片 URL（生图 ready + 正文 Markdown 图）。
List<String> collectConversationImageUrls(
  Iterable<ChatConversationMessage> messages,
) {
  final urls = <String>[];
  for (final message in messages) {
    for (final part in message.parts) {
      switch (part) {
        case ChatImagePart(:final status, :final url)
            when status == ChatImagePartStatus.ready:
          final trimmed = url?.trim() ?? '';
          if (trimmed.isNotEmpty) {
            urls.add(trimmed);
          }
        case ChatAttachmentPart(:final kind, :final localPath)
            when kind == ChatAttachmentKind.image:
          final trimmed = localPath.trim();
          if (trimmed.isNotEmpty) {
            urls.add(trimmed);
          }
        case ChatTextPart(:final content):
          for (final match in _markdownImagePattern.allMatches(content)) {
            final imageUrl = match.group(1)?.trim() ?? '';
            if (imageUrl.isNotEmpty) {
              urls.add(imageUrl);
            }
          }
        default:
          break;
      }
    }
    // 无 parts 时退回 content 里的 markdown 图（兼容旧消息）。
    if (message.parts.isEmpty) {
      for (final match in _markdownImagePattern.allMatches(message.content)) {
        final imageUrl = match.group(1)?.trim() ?? '';
        if (imageUrl.isNotEmpty) {
          urls.add(imageUrl);
        }
      }
    }
  }
  return urls;
}

/// 向消息树下发当前会话可预览图集。
class AgentChatImagePreviewScope extends InheritedWidget {
  const AgentChatImagePreviewScope({
    super.key,
    required this.imageUrls,
    required super.child,
  });

  final List<String> imageUrls;

  static AgentChatImagePreviewScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AgentChatImagePreviewScope>();
  }

  /// 打开预览；无图集时退化为单图。
  static Future<void> openPreview(BuildContext context, String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return Future<void>.value();
    }
    final scope = maybeOf(context);
    final urls = scope?.imageUrls ?? const <String>[];
    if (urls.isEmpty) {
      return showAppImagePreview(context, urls: [trimmed]);
    }
    final index = urls.indexOf(trimmed);
    return showAppImagePreview(
      context,
      urls: urls,
      initialIndex: index >= 0 ? index : 0,
    );
  }

  @override
  bool updateShouldNotify(AgentChatImagePreviewScope oldWidget) {
    if (identical(imageUrls, oldWidget.imageUrls)) {
      return false;
    }
    if (imageUrls.length != oldWidget.imageUrls.length) {
      return true;
    }
    for (var i = 0; i < imageUrls.length; i++) {
      if (imageUrls[i] != oldWidget.imageUrls[i]) {
        return true;
      }
    }
    return false;
  }
}
