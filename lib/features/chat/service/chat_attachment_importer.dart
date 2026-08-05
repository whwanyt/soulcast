import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:soulcast/entities/chat/chat.dart';
import 'package:soulcast/shared/storage/app_directories.dart';
import 'package:soulcast/shared/storage/image_file_store.dart';

/// 聊天附件导入失败原因。
enum ChatAttachmentImportFailure {
  unsupportedFormat,
  tooLarge,
  notFound,
  copyFailed,
  readFailed,
}

/// 聊天附件导入异常。
class ChatAttachmentImportException implements Exception {
  const ChatAttachmentImportException(this.failure, {this.fileName});

  final ChatAttachmentImportFailure failure;
  final String? fileName;

  @override
  String toString() =>
      'ChatAttachmentImportException($failure, fileName: $fileName)';
}

/// 将本地图片/文档复制到 [AppDirectories.chatAttachments]。
class ChatAttachmentImporter {
  const ChatAttachmentImporter({this.maxBytes = defaultMaxBytes});

  static const defaultMaxBytes = 10 * 1024 * 1024;
  static const imageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'gif'};
  static const documentExtensions = {'txt', 'md', 'json', 'csv'};

  final int maxBytes;

  /// 系统选图并导入（多选）。
  Future<List<ChatAttachmentPart>> pickImages() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    return importPaths(
      _pathsFromPicker(result),
      kind: ChatAttachmentKind.image,
    );
  }

  /// 系统选文档并导入（多选）。
  Future<List<ChatAttachmentPart>> pickDocuments() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: documentExtensions.toList(),
    );
    return importPaths(
      _pathsFromPicker(result),
      kind: ChatAttachmentKind.document,
    );
  }

  /// 从文件库路径导入一张图片。
  Future<ChatAttachmentPart> importLibraryImage(String sourcePath) async {
    final parts = await importPaths([
      sourcePath,
    ], kind: ChatAttachmentKind.image);
    if (parts.isEmpty) {
      throw const ChatAttachmentImportException(
        ChatAttachmentImportFailure.copyFailed,
      );
    }
    return parts.first;
  }

  /// 将若干本地路径导入为附件。
  Future<List<ChatAttachmentPart>> importPaths(
    List<String> sourcePaths, {
    required ChatAttachmentKind kind,
  }) async {
    if (sourcePaths.isEmpty) {
      return const [];
    }

    final directories = await AppDirectories.resolve();
    await directories.chatAttachments.create(recursive: true);
    final store = ImageFileStore(
      fileNamePrefix: 'attach',
      baseDirectory: directories.chatAttachments,
    );

    final imported = <ChatAttachmentPart>[];
    for (final sourcePath in sourcePaths) {
      final trimmed = sourcePath.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      imported.add(
        await _importOne(
          trimmed,
          kind: kind,
          imageStore: store,
          directories: directories,
        ),
      );
    }
    return imported;
  }

  /// 读取文档附件的 UTF-8 文本。
  Future<String> readDocumentText(ChatAttachmentPart part) async {
    if (!part.isDocument) {
      throw ArgumentError.value(part.kind, 'kind', 'must be document');
    }
    final file = _resolveLocalFile(part.localPath);
    if (file == null || !await file.exists()) {
      throw ChatAttachmentImportException(
        ChatAttachmentImportFailure.notFound,
        fileName: part.fileName,
      );
    }
    try {
      return await file.readAsString();
    } on Object {
      throw ChatAttachmentImportException(
        ChatAttachmentImportFailure.readFailed,
        fileName: part.fileName,
      );
    }
  }

  Future<ChatAttachmentPart> _importOne(
    String sourcePath, {
    required ChatAttachmentKind kind,
    required ImageFileStore imageStore,
    required AppDirectories directories,
  }) async {
    final source = File(sourcePath);
    final fileName = p.basename(sourcePath);
    if (!await source.exists()) {
      throw ChatAttachmentImportException(
        ChatAttachmentImportFailure.notFound,
        fileName: fileName,
      );
    }

    final extension = _extensionOf(fileName);
    _assertAllowedExtension(extension, kind: kind, fileName: fileName);

    final byteSize = await source.length();
    if (byteSize > maxBytes) {
      throw ChatAttachmentImportException(
        ChatAttachmentImportFailure.tooLarge,
        fileName: fileName,
      );
    }

    try {
      final localPath = switch (kind) {
        ChatAttachmentKind.image => (await imageStore.importLocalImage(
          sourcePath,
        )).toString(),
        ChatAttachmentKind.document => await _copyDocument(
          source: source,
          extension: extension,
          directories: directories,
        ),
      };
      return ChatAttachmentPart(
        id: 'attach_${DateTime.now().microsecondsSinceEpoch}',
        kind: kind,
        fileName: fileName,
        mimeType: _mimeTypeFor(extension, kind: kind),
        localPath: localPath,
        byteSize: byteSize,
      );
    } on ChatAttachmentImportException {
      rethrow;
    } on Object {
      throw ChatAttachmentImportException(
        ChatAttachmentImportFailure.copyFailed,
        fileName: fileName,
      );
    }
  }

  Future<String> _copyDocument({
    required File source,
    required String extension,
    required AppDirectories directories,
  }) async {
    final fileName =
        'attach_${DateTime.now().microsecondsSinceEpoch}.$extension';
    final destination = directories.chatAttachmentFile(fileName);
    await source.copy(destination.path);
    return Uri.file(destination.path).toString();
  }

  void _assertAllowedExtension(
    String extension, {
    required ChatAttachmentKind kind,
    required String fileName,
  }) {
    final allowed = switch (kind) {
      ChatAttachmentKind.image => imageExtensions,
      ChatAttachmentKind.document => documentExtensions,
    };
    if (!allowed.contains(extension)) {
      throw ChatAttachmentImportException(
        ChatAttachmentImportFailure.unsupportedFormat,
        fileName: fileName,
      );
    }
  }

  static List<String> _pathsFromPicker(FilePickerResult? result) {
    if (result == null) {
      return const [];
    }
    return [
      for (final file in result.files)
        if (file.path != null && file.path!.trim().isNotEmpty) file.path!,
    ];
  }

  static String _extensionOf(String fileName) {
    final extension = p.extension(fileName).toLowerCase();
    if (extension.startsWith('.')) {
      return extension.substring(1);
    }
    return extension;
  }

  static String _mimeTypeFor(
    String extension, {
    required ChatAttachmentKind kind,
  }) {
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'txt' => 'text/plain',
      'md' => 'text/markdown',
      'json' => 'application/json',
      'csv' => 'text/csv',
      _ =>
        kind == ChatAttachmentKind.image
            ? 'image/jpeg'
            : 'application/octet-stream',
    };
  }

  static File? _resolveLocalFile(String pathOrUri) {
    final trimmed = pathOrUri.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.scheme == 'file') {
      try {
        return File(uri.toFilePath());
      } on UnsupportedError {
        return null;
      }
    }
    return File(trimmed);
  }
}
