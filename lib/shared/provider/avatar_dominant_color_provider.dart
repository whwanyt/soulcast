import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soulcast/shared/image/image_dominant_color.dart';

/// 按头像 URL 缓存提取到的主色（不含透明度）。
final avatarDominantColorProvider = FutureProvider.autoDispose
    .family<Color?, String>((ref, avatarUrl) async {
      return extractImageDominantColor(avatarUrl);
    });
