part of 'agent_chat_markdown.dart';

/// 解析并渲染聊天 Markdown 中的高德天气标签。
class _AgentChatAmapWeatherMd extends InlineMd {
  @override
  bool get inline => false;

  @override
  RegExp get exp => AmapWeather.tagPattern;

  @override
  InlineSpan span(BuildContext context, String text, GptMarkdownConfig config) {
    final match = exp.firstMatch(text);
    final live = AmapWeather.parseTagAttributes(match?.group(1) ?? '');
    if (live == null) {
      return TextSpan(text: text, style: config.style);
    }

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: _AgentChatAmapWeatherView(live: live),
    );
  }
}

class _AgentChatAmapWeatherView extends StatelessWidget {
  const _AgentChatAmapWeatherView({required this.live});

  static const double _cardHeight = 148;

  final AmapWeatherLive live;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chrome = AgentChatMarkdownChrome(colorScheme);
    final translations = context.t.agent.showWeather;
    final textTheme = Theme.of(context).textTheme;
    final weatherType = AmapWeather.resolveBg(live.weather, bg: live.bg);
    final location = [
      if (live.province.isNotEmpty) live.province,
      if (live.city.isNotEmpty && live.city != live.province) live.city,
    ].join(' · ');
    final metaParts = <String>[
      if (live.windDirection.isNotEmpty || live.windPower.isNotEmpty)
        [
          if (live.windDirection.isNotEmpty) live.windDirection,
          if (live.windPower.isNotEmpty)
            translations.windPowerLabel(value: live.windPower),
        ].join(' '),
      if (live.humidity.isNotEmpty)
        translations.humidityLabel(value: live.humidity),
    ];

    const primaryText = Colors.white;
    final secondaryText = Colors.white.withValues(alpha: 0.85);
    final tertiaryText = Colors.white.withValues(alpha: 0.72);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return SizedBox(
            width: double.infinity,
            height: _cardHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: chrome.radius,
                border: Border.all(color: chrome.divider),
              ),
              child: ClipRRect(
                borderRadius: chrome.radius,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    WeatherBg(
                      weatherType: weatherType,
                      width: width,
                      height: _cardHeight,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.18),
                            Colors.black.withValues(alpha: 0.42),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (location.isNotEmpty)
                            Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.labelMedium?.copyWith(
                                color: secondaryText,
                              ),
                            ),
                          if (location.isNotEmpty)
                            const SizedBox(height: AppSpacing.xs),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${live.temperature}°',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.headlineMedium?.copyWith(
                                  color: primaryText,
                                  fontWeight: FontWeight.w700,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    live.weather,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.titleMedium?.copyWith(
                                      color: primaryText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (metaParts.isNotEmpty)
                            Text(
                              metaParts.join(' · '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: secondaryText,
                              ),
                            ),
                          if (live.reportTime.isNotEmpty) ...[
                            if (metaParts.isNotEmpty)
                              const SizedBox(height: AppSpacing.xs),
                            Text(
                              translations.reportTimeLabel(
                                value: live.reportTime,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.labelSmall?.copyWith(
                                color: tertiaryText,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
