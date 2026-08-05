import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import 'app_directories.dart';

/// 从远端 URL 下载图片字节；可注入以便单测。
typedef DownloadImageBytes = Future<List<int>> Function(Uri url);

/// 将本地、远端或 base64 图片统一持久化到 generatedImages。
class ImageFileStore {
  const ImageFileStore({
    required this.fileNamePrefix,
    this.baseDirectory,
    this.downloadBytes,
  }) : assert(fileNamePrefix != '');

  final String fileNamePrefix;
  final Directory? baseDirectory;
  final DownloadImageBytes? downloadBytes;

  Future<Uri> importLocalImage(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw ArgumentError.value(sourcePath, 'sourcePath', 'file not found');
    }

    final extension = _normalizeExtension(p.extension(source.path));
    final destination = await _newFile(extension);
    await source.copy(destination.path);
    return Uri.file(destination.path);
  }

  Future<Uri> saveB64Json(String b64Json) async {
    final trimmed = b64Json.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(b64Json, 'b64Json', 'must not be empty');
    }
    return saveBytes(Uint8List.fromList(base64Decode(trimmed)));
  }

  Future<Uri> saveFromUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(url, 'url', 'must not be empty');
    }
    final uri = Uri.parse(trimmed);
    if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw ArgumentError.value(url, 'url', 'must be an http(s) URL');
    }

    final downloader = downloadBytes ?? _defaultDownloadBytes;
    final bytes = await downloader(uri);
    if (bytes.isEmpty) {
      throw StateError('Downloaded image is empty: $trimmed');
    }
    return saveBytes(Uint8List.fromList(bytes));
  }

  Future<Uri> saveBytes(Uint8List bytes) async {
    if (bytes.isEmpty) {
      throw ArgumentError.value(bytes, 'bytes', 'must not be empty');
    }

    final destination = await _newFile('.${_detectExtension(bytes)}');
    await destination.writeAsBytes(bytes, flush: true);
    return Uri.file(destination.path);
  }

  Future<File> _newFile(String extension) async {
    if (fileNamePrefix.contains('/') || fileNamePrefix.contains('\\')) {
      throw ArgumentError.value(
        fileNamePrefix,
        'fileNamePrefix',
        'must not contain path separators',
      );
    }
    final fileName =
        '${fileNamePrefix}_${DateTime.now().microsecondsSinceEpoch}$extension';
    final override = baseDirectory;
    if (override != null) {
      await override.create(recursive: true);
      return AppDirectories.fileIn(override, fileName);
    }

    final directories = await AppDirectories.resolve();
    await directories.generatedImages.create(recursive: true);
    return directories.generatedImageFile(fileName);
  }

  static Future<List<int>> _defaultDownloadBytes(Uri url) async {
    final response = await Dio().getUri<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data == null || data.isEmpty) {
      throw StateError('Empty response body from $url');
    }
    return data;
  }

  static String _normalizeExtension(String extension) {
    final lower = extension.toLowerCase();
    switch (lower) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.webp':
      case '.gif':
      case '.heic':
      case '.heif':
        return lower;
      default:
        return '.jpg';
    }
  }

  static String _detectExtension(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'png';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'jpg';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'webp';
    }
    if (bytes.length >= 6 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46) {
      return 'gif';
    }
    return 'png';
  }
}
