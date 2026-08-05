import 'dart:convert';
import 'dart:io';

import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/features/agent/llm.dart';
import 'package:soulcast/features/chat/service/chat_attachment_importer.dart';
import 'package:soulcast/shared/widgets/app_image_preview.dart';

/// 将会话消息展开为 LLM 请求历史。
///
/// 助手消息按 `parts` 还原工具轮次：
/// `assistant(toolCalls)` + `tool` 结果 + 最终正文；思考 parts 不发送。
/// 用户附件：文档抽文本拼入正文，图片转 data URL 多模态片段。
Future<List<LlmMessage>> expandConversationMessageToLlm(
  ChatConversationMessage message,
) async {
  return switch (message.role) {
    ChatConversationRole.user => [await _expandUserMessage(message)],
    ChatConversationRole.assistant => _expandAssistantMessage(message),
    ChatConversationRole.memory => const <LlmMessage>[],
  };
}

Future<LlmMessage> _expandUserMessage(ChatConversationMessage message) async {
  final attachments = [
    for (final part in message.parts)
      if (part is ChatAttachmentPart) part,
  ];
  if (attachments.isEmpty) {
    return LlmMessage.user(message.content);
  }

  final textSections = <String>[
    if (message.content.trim().isNotEmpty) message.content.trim(),
  ];
  final imageParts = <LlmContentPart>[];
  final importer = ChatAttachmentImporter();

  for (final attachment in attachments) {
    switch (attachment.kind) {
      case ChatAttachmentKind.document:
        try {
          final text = await importer.readDocumentText(attachment);
          textSections.add(_documentContextText(attachment.fileName, text));
        } on Object {
          textSections.add(
            _documentContextText(
              attachment.fileName,
              '[Failed to read attachment]',
            ),
          );
        }
      case ChatAttachmentKind.image:
        final dataUrl = await _imageDataUrl(attachment);
        if (dataUrl != null) {
          imageParts.add(LlmImageUrlContentPart(dataUrl));
        } else {
          textSections.add(
            '[Image attachment unavailable: ${attachment.fileName}]',
          );
        }
    }
  }

  final text = textSections.join('\n\n');
  if (imageParts.isEmpty) {
    return LlmMessage.user(text);
  }

  return LlmMessage.user(
    text,
    contentParts: [
      if (text.isNotEmpty) LlmTextContentPart(text),
      ...imageParts,
    ],
  );
}

String _documentContextText(String fileName, String body) {
  return 'Attached file `$fileName`:\n```\n$body\n```';
}

Future<String?> _imageDataUrl(ChatAttachmentPart attachment) async {
  final file = resolveAppImageLocalFile(attachment.localPath);
  if (file == null || !await file.exists()) {
    return null;
  }
  try {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      return null;
    }
    final mime = attachment.mimeType.trim().isNotEmpty
        ? attachment.mimeType.trim()
        : 'image/jpeg';
    return 'data:$mime;base64,${base64Encode(bytes)}';
  } on FileSystemException {
    return null;
  }
}

List<LlmMessage> _expandAssistantMessage(ChatConversationMessage message) {
  if (message.parts.isEmpty) {
    final content = message.content.trim();
    if (content.isEmpty) {
      return const [];
    }
    return [LlmMessage.assistant(content: content)];
  }

  final result = <LlmMessage>[];
  final textBuffer = <String>[];
  final toolBuffer = <ChatToolCallPart>[];

  void flushTools() {
    if (toolBuffer.isEmpty) {
      return;
    }

    final text = textBuffer.join('\n\n').trim();
    textBuffer.clear();
    result.add(
      LlmMessage.assistant(
        content: text.isEmpty ? null : text,
        toolCalls: [
          for (final part in toolBuffer)
            LlmToolCall(
              id: part.toolCallId,
              name: part.toolName,
              arguments: part.arguments?.trim().isNotEmpty == true
                  ? part.arguments!
                  : '{}',
            ),
        ],
      ),
    );
    for (final part in toolBuffer) {
      result.add(
        LlmMessage.tool(
          toolCallId: part.toolCallId,
          content: part.result ?? '',
        ),
      );
    }
    toolBuffer.clear();
  }

  void flushText() {
    final text = textBuffer.join('\n\n').trim();
    textBuffer.clear();
    if (text.isNotEmpty) {
      result.add(LlmMessage.assistant(content: text));
    }
  }

  for (final part in message.parts) {
    switch (part) {
      case ChatReasoningPart():
        break;
      case ChatTextPart(:final content):
        if (content.trim().isEmpty) {
          break;
        }
        if (toolBuffer.isNotEmpty) {
          flushTools();
        }
        textBuffer.add(content);
      case final ChatToolCallPart toolPart:
        // 未完成的工具步骤不回放，避免伪造空结果污染上下文。
        if (toolPart.status != ChatToolCallPartStatus.running) {
          toolBuffer.add(toolPart);
        }
      case final ChatImagePart imagePart:
        final imageText = _imagePartContextText(imagePart);
        if (imageText == null) {
          break;
        }
        if (toolBuffer.isNotEmpty) {
          flushTools();
        }
        textBuffer.add(imageText);
      case ChatAttachmentPart():
        // 用户附件不应出现在助手消息；忽略以免污染回放。
        break;
    }
  }

  if (toolBuffer.isNotEmpty) {
    flushTools();
  }
  flushText();
  return result;
}

String? _imagePartContextText(ChatImagePart part) {
  return switch (part.status) {
    ChatImagePartStatus.ready when part.hasDisplayUrl =>
      '![generated image](${part.url})',
    ChatImagePartStatus.ready => null,
    ChatImagePartStatus.generating => null,
    ChatImagePartStatus.failed => null,
  };
}
