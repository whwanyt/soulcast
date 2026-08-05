import 'package:geolocator/geolocator.dart';
import 'package:soulcast/i18n/strings.g.dart';

import '../model/agent_tool_ids.dart';
import 'agent_tool.dart';
import 'location_permission_dialog.dart';

/// 获取设备当前位置的 Agent 工具，包含服务与权限引导流程。
class CurrentLocationTool extends AgentTool {
  const CurrentLocationTool({
    this.locationService = const GeolocatorLocationService(),
    required this.permissionDialog,
  });

  static const toolName = AgentToolIds.currentLocation;

  final LocationService locationService;
  final LocationPermissionDialog permissionDialog;

  @override
  String get name => toolName;

  @override
  String get displayName => t.agent.currentLocation.toolName;

  @override
  String get description => t.agent.currentLocation.toolDescription;

  @override
  Map<String, dynamic> get parameters => const {
    'type': 'object',
    'properties': <String, dynamic>{},
    'required': <String>[],
    'additionalProperties': false,
  };

  @override
  bool get strict => true;

  @override
  Future<Map<String, dynamic>> run(Map<String, dynamic> arguments) async {
    if (!await locationService.isServiceEnabled()) {
      final shouldOpenSettings = await permissionDialog.showServiceDisabled();
      if (shouldOpenSettings) {
        await locationService.openLocationSettings();
      }
      return {
        'status': 'location_service_disabled',
        'message': t.agent.currentLocation.serviceDisabledResult,
      };
    }

    var permission = await locationService.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      final shouldRequest = await permissionDialog.showPermissionRequest();
      if (!shouldRequest) {
        return {
          'status': 'permission_request_cancelled',
          'message': t.agent.currentLocation.permissionCancelledResult,
        };
      }
      permission = await locationService.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      final shouldOpenSettings = await permissionDialog.showOpenAppSettings();
      if (shouldOpenSettings) {
        await locationService.openAppSettings();
      }
      return {
        'status': 'permission_denied_forever',
        'message': t.agent.currentLocation.permissionDeniedForeverResult,
      };
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      return {
        'status': 'permission_denied',
        'message': t.agent.currentLocation.permissionDeniedResult,
      };
    }

    final position = await locationService.getCurrentPosition();
    return {
      'status': 'success',
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracyMeters': position.accuracy,
      'timestamp': position.timestamp.toUtc().toIso8601String(),
    };
  }
}

/// 位置服务 Port，便于隔离 Geolocator SDK 与测试权限分支。
abstract interface class LocationService {
  Future<bool> isServiceEnabled();

  Future<LocationPermission> checkPermission();

  Future<LocationPermission> requestPermission();

  Future<Position> getCurrentPosition();

  Future<bool> openAppSettings();

  Future<bool> openLocationSettings();
}

/// 基于 Geolocator 的位置服务实现。
class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  @override
  Future<Position> getCurrentPosition() => Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 15),
    ),
  );

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
