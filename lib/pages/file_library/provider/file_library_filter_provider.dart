import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:soulcast/i18n/strings.g.dart';

part 'file_library_filter_provider.g.dart';

/// 文件库页支持的本地筛选维度。
enum FileLibraryFilter {
  all,
  images,
  files;

  String label(Translations translations) {
    return switch (this) {
      FileLibraryFilter.all => translations.fileLibrary.filter.all,
      FileLibraryFilter.images => translations.fileLibrary.filter.images,
      FileLibraryFilter.files => translations.fileLibrary.filter.files,
    };
  }
}

/// 管理文件库页当前选中的筛选条件。
@riverpod
class FileLibraryFilterController extends _$FileLibraryFilterController {
  @override
  FileLibraryFilter build() {
    return FileLibraryFilter.all;
  }

  void select(FileLibraryFilter filter) {
    if (state == filter) {
      return;
    }

    state = filter;
  }
}
