import 'package:flutter/material.dart';
import 'package:palette_generator_master/palette_generator_master.dart';
import 'package:soulcast/shared/widgets/app_image_preview.dart';

/// 从图片 URL（本地 file / 网络）提取主色；失败返回 `null`。
Future<Color?> extractImageDominantColor(String url) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final provider = _imageProviderFor(trimmed);
  if (provider == null) {
    return null;
  }

  try {
    final palette = await PaletteGeneratorMaster.fromImageProvider(
      provider,
      size: const Size(120, 120),
      maximumColorCount: 16,
      generateHarmony: false,
    );

    return palette.dominantColor?.color ??
        palette.vibrantColor?.color ??
        (palette.paletteColors.isEmpty
            ? null
            : palette.paletteColors.first.color);
  } catch (_) {
    return null;
  }
}

ImageProvider? _imageProviderFor(String url) {
  final localFile = resolveAppImageLocalFile(url);
  if (localFile != null) {
    return FileImage(localFile);
  }

  final uri = Uri.tryParse(url);
  if (uri != null && (uri.isScheme('http') || uri.isScheme('https'))) {
    return NetworkImage(url);
  }

  return null;
}

/// 角色会话气泡：主色叠加透明度。
const kAvatarBubbleFillAlpha = 0.72;

Color avatarBubbleFillColor(Color dominant) {
  return dominant.withValues(alpha: kAvatarBubbleFillAlpha);
}
