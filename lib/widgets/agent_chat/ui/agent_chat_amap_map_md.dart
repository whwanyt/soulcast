part of 'agent_chat_markdown.dart';

/// 解析并渲染聊天 Markdown 中的高德静态地图标签。
class _AgentChatAmapMapMd extends InlineMd {
  @override
  bool get inline => false;

  @override
  RegExp get exp => AmapStaticMap.tagPattern;

  @override
  InlineSpan span(BuildContext context, String text, GptMarkdownConfig config) {
    final match = exp.firstMatch(text);
    final attrs = AmapStaticMap.parseTagAttributes(match?.group(1) ?? '');
    if (attrs == null) {
      return TextSpan(text: text, style: config.style);
    }

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: _AgentChatAmapMapView(
        latitude: attrs.latitude,
        longitude: attrs.longitude,
        zoom: attrs.zoom,
      ),
    );
  }
}

class _AgentChatAmapMapView extends ConsumerWidget {
  const _AgentChatAmapMapView({
    required this.latitude,
    required this.longitude,
    required this.zoom,
  });

  final double latitude;
  final double longitude;
  final int zoom;

  static const _aspectRatio = 750 / 300;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final chrome = AgentChatMarkdownChrome(colorScheme);
    final amapKey = ref
        .watch(agentToolConfigsProvider)[AgentToolIds.showLocationMap]
        ?.stringParam(AgentToolIds.amapKey);
    final translations = context.t.agent.showLocationMap;

    if (amapKey == null || amapKey.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: DecoratedBox(
          decoration: chrome.panel(),
          child: SizedBox(
            width: double.infinity,
            height: 96,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(
                  translations.missingAmapKeyDisplay,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final imageUrl = AmapStaticMap.buildImageUrl(
      latitude: latitude,
      longitude: longitude,
      amapKey: amapKey,
      zoom: zoom,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: ClipRRect(
        borderRadius: chrome.radius,
        child: AspectRatio(
          aspectRatio: _aspectRatio,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => DecoratedBox(
              decoration: BoxDecoration(color: chrome.surface),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            errorWidget: (context, url, error) => DecoratedBox(
              decoration: BoxDecoration(color: chrome.surface),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Text(
                    translations.mapLoadFailed,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
