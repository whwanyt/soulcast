import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 带加载占位和失败状态的网络封面图。
class CoverWidget extends StatelessWidget {
  const CoverWidget({super.key, this.imageUrl, this.fit});

  /// 图片地址；为空时显示通用占位内容。
  final String? imageUrl;

  /// 图片在可用空间内的缩放方式。
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) {
      return const Placeholder();
    }
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: fit,
      placeholder: (context, url) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Theme.of(context).colorScheme.surfaceContainer,
        alignment: Alignment.center,
        child: Icon(Icons.error),
      ),
    );
  }
}
