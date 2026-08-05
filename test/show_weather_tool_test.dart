import 'package:flutter_test/flutter_test.dart';
import 'package:soulcast/features/agent/agent.dart';
import 'package:soulcast/features/agent_tools/api/amap_http_client.dart';
import 'package:soulcast/features/agent_tools/service/show_weather_tool.dart';
import 'package:soulcast/shared/widgets/weather_bg/weather_bg.dart';

void main() {
  test('builds weather uri with city adcode', () {
    final uri = AmapWeather.buildUri(amapKey: 'secret-key', city: '110101');

    expect(uri.host, 'restapi.amap.com');
    expect(uri.path, '/v3/weather/weatherInfo');
    expect(uri.queryParameters['city'], '110101');
    expect(uri.queryParameters['extensions'], 'base');
    expect(uri.queryParameters['key'], 'secret-key');
    expect(uri.queryParameters['output'], 'JSON');
  });

  test('builds and parses markdown tag with bg', () {
    const live = AmapWeatherLive(
      province: '北京',
      city: '东城区',
      adcode: '110101',
      weather: '晴',
      temperature: '35',
      windDirection: '西南',
      windPower: '4',
      humidity: '51',
      reportTime: '2026-07-15 15:03:06',
      bg: 'sunny',
    );

    final markdown = AmapWeather.buildMarkdownTag(live);
    expect(markdown.contains('key='), isFalse);
    expect(markdown, contains('weather="晴"'));
    expect(markdown, contains('temperature="35"'));
    expect(markdown, contains('bg="sunny"'));

    final parsed = AmapWeather.parseTagAttributes(
      AmapWeather.tagPattern.firstMatch(markdown)!.group(1)!,
    );
    expect(parsed, isNotNull);
    expect(parsed!.city, '东城区');
    expect(parsed.weather, '晴');
    expect(parsed.temperature, '35');
    expect(parsed.reportTime, '2026-07-15 15:03:06');
    expect(parsed.bg, 'sunny');
  });

  test('resolveBg prefers explicit bg over weather text', () {
    expect(AmapWeather.resolveBg('晴', bg: 'thunder'), WeatherType.thunder);
    expect(AmapWeather.resolveBg('晴'), WeatherType.sunny);
    expect(AmapWeather.resolveBg('雷阵雨'), WeatherType.thunder);
    expect(AmapWeather.resolveBg('未知'), WeatherType.cloudy);
  });

  test('WeatherType.tryParse accepts enum names', () {
    expect(WeatherType.tryParse('sunny'), WeatherType.sunny);
    expect(WeatherType.tryParse('lightRainy'), WeatherType.lightRainy);
    expect(WeatherType.tryParse('nope'), isNull);
    expect(WeatherType.tryParse(''), isNull);
  });

  test('returns live weather markdown when request succeeds', () async {
    Uri? requested;
    final tool = ShowWeatherTool(
      resolveAmapKey: () => 'test-key',
      httpGet: (uri) async {
        requested = uri;
        return _jsonResponse(uri, {
          'status': '1',
          'count': '1',
          'info': 'OK',
          'infocode': '10000',
          'lives': [
            {
              'province': '北京',
              'city': '东城区',
              'adcode': '110101',
              'weather': '晴',
              'temperature': '35',
              'winddirection': '西南',
              'windpower': '4',
              'humidity': '51',
              'reporttime': '2026-07-15 15:03:06',
            },
          ],
        });
      },
    );

    final result = await tool.run(const {'city': '110101'});

    expect(result['status'], 'success');
    expect(result['city'], '110101');
    expect((result['live'] as Map)['weather'], '晴');
    expect((result['live'] as Map)['bg'], 'sunny');
    expect(
      result['markdown'],
      contains('<amap_weather province="北京" city="东城区"'),
    );
    expect(result['markdown'], contains('bg="sunny"'));
    expect(result['markdown'].toString().contains('key='), isFalse);
    expect(requested?.queryParameters['city'], '110101');
    expect(requested?.queryParameters['key'], 'test-key');
  });

  test('fails when amap key is missing', () async {
    final tool = ShowWeatherTool(resolveAmapKey: () => '  ');

    final result = await tool.run(const {'city': '110101'});

    expect(result['status'], 'missing_amap_key');
  });

  test('fails when city is empty', () async {
    final tool = ShowWeatherTool(resolveAmapKey: () => 'test-key');

    final result = await tool.run(const {'city': '  '});

    expect(result['status'], 'invalid_arguments');
  });

  test('returns api_error when amap status is not 1', () async {
    final tool = ShowWeatherTool(
      resolveAmapKey: () => 'test-key',
      httpGet: (uri) async {
        return _jsonResponse(uri, {
          'status': '0',
          'info': 'INVALID_USER_KEY',
          'infocode': '10001',
        });
      },
    );

    final result = await tool.run(const {'city': '110101'});

    expect(result['status'], 'api_error');
    expect(result['infocode'], '10001');
  });

  test('returns invalid_response when lives is empty', () async {
    final tool = ShowWeatherTool(
      resolveAmapKey: () => 'test-key',
      httpGet: (uri) async {
        return _jsonResponse(uri, {'status': '1', 'lives': <Object>[]});
      },
    );

    final result = await tool.run(const {'city': '110101'});

    expect(result['status'], 'invalid_response');
  });
}

AmapHttpResponse _jsonResponse(Uri _, Map<String, dynamic> data) {
  return AmapHttpResponse(statusCode: 200, data: data);
}
