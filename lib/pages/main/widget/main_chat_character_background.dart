import 'package:flutter/material.dart';
import 'package:soulcast/shared/widgets/app_image_preview.dart';

/// 角色会话聊天页背景：以角色头像铺满。
class MainChatCharacterBackground extends StatelessWidget {
  const MainChatCharacterBackground({required this.avatarUrl, super.key});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim();
    if (url == null || url.isEmpty) {
      return const SizedBox.shrink();
    }

    final localFile = resolveAppImageLocalFile(url);
    if (localFile != null) {
      return Image.file(
        localFile,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }
        return const SizedBox.shrink();
      },
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

/// 顶部消息渐隐：用与全屏一致的头像遮罩盖住列表顶部。
class MainChatCharacterTopFade extends StatelessWidget {
  const MainChatCharacterTopFade({
    required this.avatarUrl,
    this.fadeHeight = 96,
    super.key,
  });

  final String? avatarUrl;
  final double fadeHeight;

  @override
  Widget build(BuildContext context) {
    return _MainChatCharacterEdgeFade(
      avatarUrl: avatarUrl,
      fadeHeight: fadeHeight,
      fromTop: true,
    );
  }
}

/// 底部消息渐隐：用与全屏一致的头像遮罩盖住列表底部。
class MainChatCharacterBottomFade extends StatelessWidget {
  const MainChatCharacterBottomFade({
    required this.avatarUrl,
    this.fadeHeight = 128,
    super.key,
  });

  final String? avatarUrl;
  final double fadeHeight;

  @override
  Widget build(BuildContext context) {
    return _MainChatCharacterEdgeFade(
      avatarUrl: avatarUrl,
      fadeHeight: fadeHeight,
      fromTop: false,
    );
  }
}

class _MainChatCharacterEdgeFade extends StatelessWidget {
  const _MainChatCharacterEdgeFade({
    required this.avatarUrl,
    required this.fadeHeight,
    required this.fromTop,
  });

  final String? avatarUrl;
  final double fadeHeight;
  final bool fromTop;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim();
    if (url == null || url.isEmpty) {
      return const SizedBox.shrink();
    }

    final screenHeight = MediaQuery.sizeOf(context).height;
    final fadeRatio = (fadeHeight / screenHeight).clamp(0.05, 0.5);

    return IgnorePointer(
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) {
          if (fromTop) {
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: const [
                Color(0xFFFFFFFF),
                Color(0xFFFFFFFF),
                Color(0x00FFFFFF),
              ],
              stops: [0, (fadeRatio * 0.45).clamp(0.0, 1.0), fadeRatio],
            ).createShader(bounds);
          }

          final start = (1.0 - fadeRatio).clamp(0.0, 1.0);
          return LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [
              Color(0x00FFFFFF),
              Color(0xFFFFFFFF),
              Color(0xFFFFFFFF),
            ],
            stops: [start, (start + (1.0 - start) * 0.55).clamp(0.0, 1.0), 1],
          ).createShader(bounds);
        },
        child: MainChatCharacterBackground(avatarUrl: url),
      ),
    );
  }
}
