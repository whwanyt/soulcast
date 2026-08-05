import 'dart:io';

import 'package:path_provider/path_provider.dart';

class Utils {
  static Future<String> createTempDir({required String dir}) async {
    Directory directory = await getTempDirectory(dir);
    if (!(await directory.exists())) {
      directory.create(recursive: true);
    }
    return directory.path;
  }

  static Future<Directory> getTempDirectory(String dir) async {
    final storage = await getApplicationCacheDirectory();
    Directory directory = Directory('${storage.path}/$dir');
    return directory;
  }
}
