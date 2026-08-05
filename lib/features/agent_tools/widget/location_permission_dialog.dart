import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:soulcast/i18n/strings.g.dart';

import '../service/location_permission_dialog.dart';

/// 定位权限引导 UI（动作型 dialog）。
class SmartLocationPermissionDialog implements LocationPermissionDialog {
  const SmartLocationPermissionDialog();

  static const _dialogTag = 'current_location_permission_dialog';

  @override
  Future<bool> showPermissionRequest() {
    return _show(
      title: t.agent.currentLocation.permissionDialogTitle,
      message: t.agent.currentLocation.permissionDialogMessage,
      confirmLabel: t.agent.currentLocation.grantPermission,
    );
  }

  @override
  Future<bool> showOpenAppSettings() {
    return _show(
      title: t.agent.currentLocation.settingsDialogTitle,
      message: t.agent.currentLocation.settingsDialogMessage,
      confirmLabel: t.agent.currentLocation.openSettings,
    );
  }

  @override
  Future<bool> showServiceDisabled() {
    return _show(
      title: t.agent.currentLocation.serviceDialogTitle,
      message: t.agent.currentLocation.serviceDialogMessage,
      confirmLabel: t.agent.currentLocation.openLocationSettings,
    );
  }

  Future<bool> _show({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await SmartDialog.show<bool>(
      tag: _dialogTag,
      keepSingle: true,
      clickMaskDismiss: false,
      builder: (_) => AlertDialog(
        title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        content: Text(message, maxLines: 6, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(
            onPressed: () => _dismiss(false),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () => _dismiss(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _dismiss(bool result) {
    SmartDialog.dismiss<bool>(tag: _dialogTag, result: result);
  }
}
