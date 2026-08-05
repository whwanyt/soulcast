import 'package:flutter_test/flutter_test.dart';
import 'package:soulcast/entities/chat/chat.dart';

void main() {
  test('encode and decode assistant message parts', () {
    const parts = <ChatMessagePart>[
      ChatReasoningPart(id: 'r1', content: '先想清楚'),
      ChatToolCallPart(
        id: 'call_1',
        toolCallId: 'call_1',
        toolName: 'current_time',
        status: ChatToolCallPartStatus.completed,
        arguments: '{}',
        result: '{"ok":true}',
      ),
      ChatTextPart(id: 't1', content: '现在是下午。'),
    ];

    final encoded = encodeChatMessageParts(parts);
    final decoded = decodeChatMessageParts(encoded);

    expect(decoded, hasLength(3));
    expect(decoded[0], isA<ChatReasoningPart>());
    expect((decoded[0] as ChatReasoningPart).content, '先想清楚');
    expect(decoded[1], isA<ChatToolCallPart>());
    expect((decoded[1] as ChatToolCallPart).toolName, 'current_time');
    expect(decoded[2], isA<ChatTextPart>());
    expect((decoded[2] as ChatTextPart).content, '现在是下午。');
  });

  test('assistant factory materializes text part from content', () {
    final message = ChatConversationMessage.assistant(content: '最终回答');

    expect(message.parts, hasLength(1));
    expect(message.parts.single, isA<ChatTextPart>());
    expect((message.parts.single as ChatTextPart).content, '最终回答');
  });

  test('assistant factory keeps explicit parts', () {
    final message = ChatConversationMessage.assistant(
      content: 'ignored-flat-content',
      parts: const [
        ChatReasoningPart(id: 'r', content: '新思考'),
        ChatToolCallPart(
          id: 'c',
          toolCallId: 'c',
          toolName: 'current_time',
          status: ChatToolCallPartStatus.running,
        ),
        ChatTextPart(id: 't', content: '新正文'),
      ],
    );

    expect(message.parts, hasLength(3));
    expect((message.parts[0] as ChatReasoningPart).content, '新思考');
    expect(message.parts[1], isA<ChatToolCallPart>());
    expect((message.parts[2] as ChatTextPart).content, '新正文');
  });

  test('encode and decode ChatAttachmentPart', () {
    const parts = <ChatMessagePart>[
      ChatAttachmentPart(
        id: 'a1',
        kind: ChatAttachmentKind.image,
        fileName: 'photo.png',
        mimeType: 'image/png',
        localPath: 'file:///tmp/photo.png',
        byteSize: 12,
      ),
      ChatAttachmentPart(
        id: 'a2',
        kind: ChatAttachmentKind.document,
        fileName: 'note.txt',
        mimeType: 'text/plain',
        localPath: '/tmp/note.txt',
      ),
    ];

    final decoded = decodeChatMessageParts(encodeChatMessageParts(parts));
    expect(decoded, hasLength(2));
    final image = decoded[0] as ChatAttachmentPart;
    expect(image.kind, ChatAttachmentKind.image);
    expect(image.fileName, 'photo.png');
    expect(image.byteSize, 12);
    final doc = decoded[1] as ChatAttachmentPart;
    expect(doc.kind, ChatAttachmentKind.document);
    expect(doc.localPath, '/tmp/note.txt');
  });

  test('user factory keeps attachment parts', () {
    final message = ChatConversationMessage.user(
      '看看这个',
      parts: const [
        ChatAttachmentPart(
          id: 'a1',
          kind: ChatAttachmentKind.image,
          fileName: 'a.png',
          mimeType: 'image/png',
          localPath: 'file:///tmp/a.png',
        ),
      ],
    );
    expect(message.parts, hasLength(1));
    expect(message.parts.single, isA<ChatAttachmentPart>());
  });

  test('encode and decode ChatImagePart', () {
    const parts = <ChatMessagePart>[
      ChatImagePart(
        id: 'img1',
        status: ChatImagePartStatus.ready,
        url: 'file:///tmp/a.png',
        revisedPrompt: 'a cat',
      ),
      ChatImagePart(id: 'img2', status: ChatImagePartStatus.generating),
      ChatImagePart(
        id: 'img3',
        status: ChatImagePartStatus.failed,
        errorMessage: 'boom',
      ),
    ];

    final decoded = decodeChatMessageParts(encodeChatMessageParts(parts));
    expect(decoded, hasLength(3));

    final ready = decoded[0] as ChatImagePart;
    expect(ready.status, ChatImagePartStatus.ready);
    expect(ready.url, 'file:///tmp/a.png');
    expect(ready.revisedPrompt, 'a cat');

    expect(
      (decoded[1] as ChatImagePart).status,
      ChatImagePartStatus.generating,
    );
    expect((decoded[2] as ChatImagePart).errorMessage, 'boom');
  });
}
