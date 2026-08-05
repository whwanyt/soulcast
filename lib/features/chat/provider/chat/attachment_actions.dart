part of 'chat.dart';

/// Chat notifier 的草稿附件选择与导入能力。
mixin _ChatAttachmentActions on _ChatController {
  ChatAttachmentImporter get _attachmentImporter => ChatAttachmentImporter();

  Future<void> pickDraftImages() async {
    try {
      final parts = await _attachmentImporter.pickImages();
      if (parts.isEmpty) {
        return;
      }
      _appendDraftAttachments(parts);
    } on ChatAttachmentImportException catch (error) {
      state = state.copyWith(errorMessage: _chatAttachmentErrorMessage(error));
    } catch (error, stackTrace) {
      Log.e(
        'Chat pick draft images failed: $error',
        tag: 'Chat',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        errorMessage: t.main.input.attach.copyFailed(fileName: ''),
      );
    }
  }

  Future<void> pickDraftDocuments() async {
    try {
      final parts = await _attachmentImporter.pickDocuments();
      if (parts.isEmpty) {
        return;
      }
      _appendDraftAttachments(parts);
    } on ChatAttachmentImportException catch (error) {
      state = state.copyWith(errorMessage: _chatAttachmentErrorMessage(error));
    } catch (error, stackTrace) {
      Log.e(
        'Chat pick draft documents failed: $error',
        tag: 'Chat',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        errorMessage: t.main.input.attach.copyFailed(fileName: ''),
      );
    }
  }

  Future<void> importDraftLibraryImage(String sourcePath) async {
    try {
      final part = await _attachmentImporter.importLibraryImage(sourcePath);
      _appendDraftAttachments([part]);
    } on ChatAttachmentImportException catch (error) {
      state = state.copyWith(errorMessage: _chatAttachmentErrorMessage(error));
    } catch (error, stackTrace) {
      Log.e(
        'Chat import library image failed: $error',
        tag: 'Chat',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        errorMessage: t.main.input.attach.copyFailed(fileName: ''),
      );
    }
  }

  void removeDraftAttachment(String attachmentId) {
    final next = [
      for (final part in state.draftAttachments)
        if (part.id != attachmentId) part,
    ];
    if (next.length == state.draftAttachments.length) {
      return;
    }
    state = state.copyWith(draftAttachments: next);
  }

  void _appendDraftAttachments(List<ChatAttachmentPart> parts) {
    if (parts.isEmpty) {
      return;
    }
    state = state.copyWith(
      draftAttachments: [...state.draftAttachments, ...parts],
      errorMessage: null,
    );
  }
}

String _chatAttachmentErrorMessage(ChatAttachmentImportException error) {
  final fileName = error.fileName?.trim().isNotEmpty == true
      ? error.fileName!
      : 'file';
  final attach = t.main.input.attach;
  return switch (error.failure) {
    ChatAttachmentImportFailure.unsupportedFormat => attach.unsupportedFormat(
      fileName: fileName,
    ),
    ChatAttachmentImportFailure.tooLarge => attach.tooLarge(fileName: fileName),
    ChatAttachmentImportFailure.notFound => attach.notFound(fileName: fileName),
    ChatAttachmentImportFailure.copyFailed => attach.copyFailed(
      fileName: fileName,
    ),
    ChatAttachmentImportFailure.readFailed => attach.readFailed(
      fileName: fileName,
    ),
  };
}
