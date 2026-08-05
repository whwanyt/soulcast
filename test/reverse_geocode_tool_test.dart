import 'package:flutter_test/flutter_test.dart';
import 'package:soulcast/features/agent/agent.dart';
import 'package:soulcast/features/agent_tools/api/amap_http_client.dart';
import 'package:soulcast/features/agent_tools/service/reverse_geocode_tool.dart';

void main() {
  test('builds regeo uri with longitude,latitude and extensions', () {
    final uri = AmapRegeo.buildUri(
      amapKey: 'secret-key',
      longitude: 116.481488,
      latitude: 39.990464,
      extensions: AmapRegeo.extensionsAll,
      radius: 1000,
    );

    expect(uri.host, 'restapi.amap.com');
    expect(uri.path, '/v3/geocode/regeo');
    expect(uri.queryParameters['location'], '116.481488,39.990464');
    expect(uri.queryParameters['extensions'], 'all');
    expect(uri.queryParameters['radius'], '1000');
    expect(uri.queryParameters['key'], 'secret-key');
    expect(uri.queryParameters['output'], 'JSON');
  });

  test('returns regeocode when base request succeeds', () async {
    Uri? requested;
    final tool = ReverseGeocodeTool(
      resolveAmapKey: () => 'test-key',
      httpGet: (uri) async {
        requested = uri;
        return _jsonResponse({
          'status': '1',
          'info': 'OK',
          'infocode': '10000',
          'regeocode': {
            'formatted_address': '北京市朝阳区望京街道方恒国际中心B座',
            'addressComponent': {'province': '北京市', 'district': '朝阳区'},
          },
        });
      },
    );

    final result = await tool.run(const {
      'latitude': 39.990464,
      'longitude': 116.481488,
      'extensions': 'base',
    });

    expect(result['status'], 'success');
    expect(result['extensions'], 'base');
    expect(result['radius'], 1000);
    expect(
      (result['regeocode'] as Map)['formatted_address'],
      '北京市朝阳区望京街道方恒国际中心B座',
    );
    expect(requested?.queryParameters['extensions'], 'base');
    expect(requested?.queryParameters['key'], 'test-key');
  });

  test('passes radius when extensions is all', () async {
    Uri? requested;
    final tool = ReverseGeocodeTool(
      resolveAmapKey: () => 'test-key',
      httpGet: (uri) async {
        requested = uri;
        return _jsonResponse({
          'status': '1',
          'regeocode': {
            'formatted_address': '测试地址',
            'pois': [
              {'name': '方恒国际中心B座'},
            ],
          },
        });
      },
    );

    final result = await tool.run(const {
      'latitude': 39.990464,
      'longitude': 116.481488,
      'extensions': 'all',
      'radius': 500,
    });

    expect(result['status'], 'success');
    expect(result['radius'], 500);
    expect(requested?.queryParameters['extensions'], 'all');
    expect(requested?.queryParameters['radius'], '500');
    expect(((result['regeocode'] as Map)['pois'] as List).length, 1);
  });

  test('fails when amap key is missing', () async {
    final tool = ReverseGeocodeTool(resolveAmapKey: () => '  ');

    final result = await tool.run(const {
      'latitude': 39.990464,
      'longitude': 116.481488,
      'extensions': 'base',
    });

    expect(result['status'], 'missing_amap_key');
  });

  test('fails when extensions is invalid', () async {
    final tool = ReverseGeocodeTool(resolveAmapKey: () => 'test-key');

    final result = await tool.run(const {
      'latitude': 39.990464,
      'longitude': 116.481488,
      'extensions': 'full',
    });

    expect(result['status'], 'invalid_arguments');
  });

  test('returns api_error when amap status is not 1', () async {
    final tool = ReverseGeocodeTool(
      resolveAmapKey: () => 'test-key',
      httpGet: (uri) async {
        return _jsonResponse({
          'status': '0',
          'info': 'INVALID_USER_KEY',
          'infocode': '10001',
        });
      },
    );

    final result = await tool.run(const {
      'latitude': 39.990464,
      'longitude': 116.481488,
      'extensions': 'base',
    });

    expect(result['status'], 'api_error');
    expect(result['infocode'], '10001');
  });
}

AmapHttpResponse _jsonResponse(
  Map<String, Object?> body, {
  int statusCode = 200,
}) {
  return AmapHttpResponse(statusCode: statusCode, data: body);
}
