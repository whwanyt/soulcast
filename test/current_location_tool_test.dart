import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:soulcast/features/agent_tools/service/current_location_tool.dart';
import 'package:soulcast/features/agent_tools/service/location_permission_dialog.dart';
import 'package:soulcast/features/agent_tools/widget/location_permission_dialog.dart';
import 'package:soulcast/i18n/strings.g.dart';

void main() {
  test('returns the current position when permission is granted', () async {
    final locationService = _FakeLocationService(
      permission: LocationPermission.whileInUse,
    );
    final dialog = _FakeLocationPermissionDialog();
    final tool = CurrentLocationTool(
      locationService: locationService,
      permissionDialog: dialog,
    );

    final result = await tool.run(const {});

    expect(result, {
      'status': 'success',
      'latitude': 31.2304,
      'longitude': 121.4737,
      'accuracyMeters': 8.5,
      'timestamp': '2026-07-13T02:00:00.000Z',
    });
    expect(locationService.positionRequestCount, 1);
    expect(dialog.permissionRequestCount, 0);
  });

  test('guides the user before requesting location permission', () async {
    final locationService = _FakeLocationService(
      permission: LocationPermission.denied,
      requestedPermission: LocationPermission.whileInUse,
    );
    final dialog = _FakeLocationPermissionDialog(allowPermissionRequest: true);
    final tool = CurrentLocationTool(
      locationService: locationService,
      permissionDialog: dialog,
    );

    final result = await tool.run(const {});

    expect(result['status'], 'success');
    expect(dialog.permissionRequestCount, 1);
    expect(locationService.permissionRequestCount, 1);
    expect(locationService.positionRequestCount, 1);
  });

  test(
    'does not request system permission when the guide is cancelled',
    () async {
      final locationService = _FakeLocationService(
        permission: LocationPermission.denied,
      );
      final dialog = _FakeLocationPermissionDialog();
      final tool = CurrentLocationTool(
        locationService: locationService,
        permissionDialog: dialog,
      );

      final result = await tool.run(const {});

      expect(result['status'], 'permission_request_cancelled');
      expect(dialog.permissionRequestCount, 1);
      expect(locationService.permissionRequestCount, 0);
      expect(locationService.positionRequestCount, 0);
    },
  );

  test('guides permanently denied permission to app settings', () async {
    final locationService = _FakeLocationService(
      permission: LocationPermission.deniedForever,
    );
    final dialog = _FakeLocationPermissionDialog(openAppSettings: true);
    final tool = CurrentLocationTool(
      locationService: locationService,
      permissionDialog: dialog,
    );

    final result = await tool.run(const {});

    expect(result['status'], 'permission_denied_forever');
    expect(dialog.appSettingsRequestCount, 1);
    expect(locationService.openAppSettingsCount, 1);
    expect(locationService.positionRequestCount, 0);
  });

  test('guides a disabled location service to system settings', () async {
    final locationService = _FakeLocationService(
      serviceEnabled: false,
      permission: LocationPermission.whileInUse,
    );
    final dialog = _FakeLocationPermissionDialog(openLocationSettings: true);
    final tool = CurrentLocationTool(
      locationService: locationService,
      permissionDialog: dialog,
    );

    final result = await tool.run(const {});

    expect(result['status'], 'location_service_disabled');
    expect(dialog.locationSettingsRequestCount, 1);
    expect(locationService.openLocationSettingsCount, 1);
    expect(locationService.positionRequestCount, 0);
  });

  testWidgets('permission guide works without a BuildContext', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: const Scaffold(), builder: FlutterSmartDialog.init()),
    );
    const dialog = SmartLocationPermissionDialog();

    final resultFuture = dialog.showPermissionRequest();
    await tester.pumpAndSettle();

    expect(find.text(t.agent.currentLocation.permissionDialogTitle), findsOne);
    expect(find.text(t.agent.currentLocation.grantPermission), findsOne);

    await tester.tap(find.text(t.agent.currentLocation.grantPermission));
    await tester.pumpAndSettle();

    expect(await resultFuture, isTrue);
    expect(
      find.text(t.agent.currentLocation.permissionDialogTitle),
      findsNothing,
    );
  });
}

class _FakeLocationService implements LocationService {
  _FakeLocationService({
    this.serviceEnabled = true,
    required this.permission,
    LocationPermission? requestedPermission,
  }) : requestedPermission = requestedPermission ?? permission;

  final bool serviceEnabled;
  final LocationPermission permission;
  final LocationPermission requestedPermission;

  int permissionRequestCount = 0;
  int positionRequestCount = 0;
  int openAppSettingsCount = 0;
  int openLocationSettingsCount = 0;

  @override
  Future<bool> isServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async {
    permissionRequestCount++;
    return requestedPermission;
  }

  @override
  Future<Position> getCurrentPosition() async {
    positionRequestCount++;
    return Position(
      longitude: 121.4737,
      latitude: 31.2304,
      timestamp: DateTime.utc(2026, 7, 13, 2),
      accuracy: 8.5,
      altitude: 12,
      altitudeAccuracy: 2,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  @override
  Future<bool> openAppSettings() async {
    openAppSettingsCount++;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    openLocationSettingsCount++;
    return true;
  }
}

class _FakeLocationPermissionDialog implements LocationPermissionDialog {
  _FakeLocationPermissionDialog({
    this.allowPermissionRequest = false,
    this.openAppSettings = false,
    this.openLocationSettings = false,
  });

  final bool allowPermissionRequest;
  final bool openAppSettings;
  final bool openLocationSettings;

  int permissionRequestCount = 0;
  int appSettingsRequestCount = 0;
  int locationSettingsRequestCount = 0;

  @override
  Future<bool> showPermissionRequest() async {
    permissionRequestCount++;
    return allowPermissionRequest;
  }

  @override
  Future<bool> showOpenAppSettings() async {
    appSettingsRequestCount++;
    return openAppSettings;
  }

  @override
  Future<bool> showServiceDisabled() async {
    locationSettingsRequestCount++;
    return openLocationSettings;
  }
}
