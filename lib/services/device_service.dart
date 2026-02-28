// Create a Flutter service class called DeviceService.
// Requirements:
// - Use device_info_plus
// - Use package_info_plus
// - Get Android device model
// - Get OS version
// - Get unique device ID using androidId
// - Get app version
// - Return Map<String, dynamic> containing:
//   device_id, device_model, os_version, app_version
// - Handle PlatformException properly
// - Must work only for Android (B2B app)
// - Return fallback values if error occurs
import 'package:device_info_plus/device_info_plus.dart';
import 'package:android_id/android_id.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class DeviceService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final _androidIdPlugin = AndroidId();

  Future<Map<String, dynamic>> getDeviceInfo() async {
    String deviceId = 'unknown';
    String deviceModel = 'unknown';
    String osVersion = 'unknown';
    String appVersion = 'unknown';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceId = await _androidIdPlugin.getId() ?? 'unknown';
        deviceModel = androidInfo.model ?? 'unknown';
        osVersion = 'Android ${androidInfo.version.release}';
      }

      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;
    } on PlatformException catch (e) {
      // Log the error or handle it as needed
    }

    return {
      'device_id': deviceId,
      'device_model': deviceModel,
      'os_version': osVersion,
      'app_version': appVersion,
    };
  }
}
