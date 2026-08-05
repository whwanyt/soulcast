import 'dart:io';

import 'package:dio/dio.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:soulcast/i18n/strings.g.dart';

/// 打开全屏图片预览，支持左右切换与保存到相册。
Future<void> showAppImagePreview(
  BuildContext context, {
  required List<String> urls,
  int initialIndex = 0,
}) {
  final cleaned = [
    for (final url in urls)
      if (url.trim().isNotEmpty) url.trim(),
  ];
  if (cleaned.isEmpty) {
    return Future<void>.value();
  }
  final index = initialIndex.clamp(0, cleaned.length - 1);

  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      opaque: true,
      barrierDismissible: true,
      barrierColor: Colors.black,
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: _AppImagePreviewPage(urls: cleaned, initialIndex: index),
        );
      },
    ),
  );
}

class _AppImagePreviewPage extends StatefulWidget {
  const _AppImagePreviewPage({required this.urls, required this.initialIndex});

  final List<String> urls;
  final int initialIndex;

  @override
  State<_AppImagePreviewPage> createState() => _AppImagePreviewPageState();
}

class _AppImagePreviewPageState extends State<_AppImagePreviewPage> {
  late final ExtendedPageController _pageController;
  late int _currentIndex;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = ExtendedPageController(initialPage: widget.initialIndex);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: const [SystemUiOverlay.bottom],
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _saveCurrent() async {
    if (_saving) {
      return;
    }
    final translations = t.agent.generateImage;
    final url = widget.urls[_currentIndex];
    setState(() => _saving = true);
    try {
      final allowed = await _ensureGalleryPermission();
      if (!allowed) {
        await SmartDialog.showToast(translations.savePermissionDenied);
        return;
      }

      final localFile = resolveAppImageLocalFile(url);
      if (localFile != null) {
        final result = await ImageGallerySaverPlus.saveFile(localFile.path);
        if (!_isSaveSuccess(result)) {
          await SmartDialog.showToast(translations.saveFailed);
          return;
        }
        await SmartDialog.showToast(translations.savedToGallery);
        return;
      }

      final dir = await getTemporaryDirectory();
      final ext = _guessExtension(url);
      final path =
          '${dir.path}/soulcast_preview_${DateTime.now().microsecondsSinceEpoch}$ext';
      await Dio().download(url, path);
      final result = await ImageGallerySaverPlus.saveFile(path);
      if (!_isSaveSuccess(result)) {
        await SmartDialog.showToast(translations.saveFailed);
        return;
      }
      await SmartDialog.showToast(translations.savedToGallery);
    } catch (_) {
      await SmartDialog.showToast(translations.saveFailed);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final translations = t.agent.generateImage;
    final total = widget.urls.length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Material(
        color: Colors.black,
        child: ExtendedImageSlidePage(
          slideAxis: SlideAxis.vertical,
          slideType: SlideType.onlyImage,
          child: ColoredBox(
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ExtendedImageGesturePageView.builder(
                  controller: _pageController,
                  itemCount: total,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  canScrollPage: (gestureDetails) {
                    return (gestureDetails?.totalScale ?? 1.0) <= 1.0;
                  },
                  itemBuilder: (context, index) {
                    return _PreviewImage(url: widget.urls[index]);
                  },
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Row(
                        children: [
                          _PreviewActionButton(
                            tooltip: t.common.cancel,
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: LucideIcons.x,
                          ),
                          Expanded(
                            child: total > 1
                                ? Text(
                                    '${_currentIndex + 1} / $total',
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          _PreviewActionButton(
                            tooltip: translations.save,
                            onPressed: _saving ? null : _saveCurrent,
                            icon: LucideIcons.download,
                            busy: _saving,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewActionButton extends StatelessWidget {
  const _PreviewActionButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    this.busy = false,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _PreviewImage extends StatelessWidget {
  const _PreviewImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final localFile = resolveAppImageLocalFile(url);

    Widget? loadStateChanged(ExtendedImageState state) {
      switch (state.extendedImageLoadState) {
        case LoadState.loading:
          return const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white70,
              ),
            ),
          );
        case LoadState.failed:
          return Center(
            child: Text(
              t.agent.generateImage.imageLoadFailed,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          );
        case LoadState.completed:
          return null;
      }
    }

    if (localFile != null) {
      return ExtendedImage.file(
        localFile,
        fit: BoxFit.contain,
        mode: ExtendedImageMode.gesture,
        enableSlideOutPage: true,
        initGestureConfigHandler: (_) => GestureConfig(
          inPageView: true,
          initialScale: 1,
          minScale: 1,
          maxScale: 4,
          animationMaxScale: 4.5,
          cacheGesture: false,
        ),
        loadStateChanged: loadStateChanged,
      );
    }

    return ExtendedImage.network(
      url,
      fit: BoxFit.contain,
      mode: ExtendedImageMode.gesture,
      enableSlideOutPage: true,
      cache: true,
      initGestureConfigHandler: (_) => GestureConfig(
        inPageView: true,
        initialScale: 1,
        minScale: 1,
        maxScale: 4,
        animationMaxScale: 4.5,
        cacheGesture: false,
      ),
      loadStateChanged: loadStateChanged,
    );
  }
}

/// 解析本地图片路径（file URI 或绝对路径）。
File? resolveAppImageLocalFile(String url) {
  final trimmed = url.trim();
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
  if (trimmed.startsWith('/')) {
    return File(trimmed);
  }
  return null;
}

Future<bool> _ensureGalleryPermission() async {
  if (Platform.isIOS) {
    var status = await Permission.photosAddOnly.status;
    if (!status.isGranted && !status.isLimited) {
      status = await Permission.photosAddOnly.request();
    }
    return status.isGranted || status.isLimited;
  }
  if (Platform.isAndroid) {
    var status = await Permission.storage.status;
    if (status.isDenied) {
      status = await Permission.storage.request();
    }
    // Android 10+ 写入 MediaStore 通常无需存储权限；拒绝时仍尝试保存。
    return true;
  }
  return true;
}

bool _isSaveSuccess(dynamic result) {
  if (result is Map) {
    final success = result['isSuccess'];
    if (success is bool) {
      return success;
    }
  }
  return result != null;
}

String _guessExtension(String url) {
  final uri = Uri.tryParse(url);
  final path = uri?.path ?? url;
  final dot = path.lastIndexOf('.');
  if (dot >= 0 && dot < path.length - 1) {
    final ext = path.substring(dot).toLowerCase();
    if (ext.length <= 5 && RegExp(r'^\.[a-z0-9]+$').hasMatch(ext)) {
      return ext;
    }
  }
  return '.png';
}
