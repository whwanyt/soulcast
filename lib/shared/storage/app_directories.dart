import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 应用本地目录约定与解析入口。
///
/// Documents / Cache / Support 下的业务子目录与其下文件路径，统一从此处获取。
/// 禁止在其余文件中硬编码或拼接业务子目录（如 `agent/generated_images`）。
class AppDirectories {
  AppDirectories({
    required this.documents,
    required this.cache,
    required this.support,
  });

  final Directory documents;
  final Directory cache;

  /// Application Support 根目录（与 Documents 平级，不挂在 Documents 下）。
  final Directory support;

  /// 相对 Documents 的子路径约定。
  static const logsRelativePath = 'logs';
  static const isarRelativePath = 'isar';
  static const filesRelativePath = 'files';
  static const agentRelativePath = 'agent';
  static const generatedImagesRelativePath =
      '$agentRelativePath/generated_images';
  static const chatAttachmentsRelativePath =
      '$agentRelativePath/chat_attachments';

  /// 相对 Support 的子路径约定。
  static const modelsRelativePath = 'models/sherpa';
  static const ttsReferenceRelativePath = 'tts_reference';

  Directory get logs => _documentsChild(logsRelativePath);

  Directory get isar => _documentsChild(isarRelativePath);

  Directory get files => _documentsChild(filesRelativePath);

  /// Ai生成的所有文件存储目录
  Directory get agent => _documentsChild(agentRelativePath);

  /// AI 生成图与角色头像等本地图片统一目录。
  Directory get generatedImages => _documentsChild(generatedImagesRelativePath);

  /// 聊天用户附件（图片与基础文档）目录。
  Directory get chatAttachments => _documentsChild(chatAttachmentsRelativePath);

  /// Sherpa 模型目录（Support 下，非 Documents）。
  Directory get models => _supportChild(modelsRelativePath);

  /// Pocket TTS 自定义参考音频目录。
  Directory get ttsReference => _supportChild(ttsReferenceRelativePath);

  /// 在 [generatedImages] 下构造文件；[fileName] 仅为文件名，不得含路径分隔符。
  File generatedImageFile(String fileName) => fileIn(generatedImages, fileName);

  /// 在 [chatAttachments] 下构造文件；[fileName] 仅为文件名，不得含路径分隔符。
  File chatAttachmentFile(String fileName) => fileIn(chatAttachments, fileName);

  /// 在已解析目录下构造文件；[fileName] 仅为文件名，不得含路径分隔符。
  static File fileIn(Directory directory, String fileName) {
    _assertBareFileName(fileName);
    return File('${directory.path}/$fileName');
  }

  Directory _documentsChild(String relativePath) =>
      Directory('${documents.path}/$relativePath');

  Directory _supportChild(String relativePath) =>
      Directory('${support.path}/$relativePath');

  static void _assertBareFileName(String fileName) {
    if (fileName.isEmpty || fileName.contains('/') || fileName.contains(r'\')) {
      throw ArgumentError.value(
        fileName,
        'fileName',
        'must be a bare file name without path separators',
      );
    }
  }

  static Future<AppDirectories>? _resolved;

  /// 解析并缓存应用目录根。
  static Future<AppDirectories> resolve() {
    return _resolved ??= _resolve();
  }

  static Future<AppDirectories> _resolve() async {
    final documents = await getApplicationDocumentsDirectory();
    final cache = await getApplicationCacheDirectory();
    final support = await getApplicationSupportDirectory();
    return AppDirectories(documents: documents, cache: cache, support: support);
  }

  /// 测试场景重置缓存。
  static void resetForTest() {
    _resolved = null;
  }
}
