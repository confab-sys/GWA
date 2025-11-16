import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

Future<String> getDeviceId() async {
  final plugin = DeviceInfoPlugin();
  if (kIsWeb) {
    final info = await plugin.webBrowserInfo;
    final ua = info.userAgent ?? 'web';
    return 'web:${ua.hashCode}';
  }
  try {
    if (Platform.isAndroid) {
      final info = await plugin.androidInfo;
      final id = info.id;
      return 'android:$id';
    } else if (Platform.isIOS) {
      final info = await plugin.iosInfo;
      final id = info.identifierForVendor ?? 'ios';
      return 'ios:$id';
    } else if (Platform.isWindows) {
      final info = await plugin.windowsInfo;
      final id = info.deviceId;
      return 'windows:$id';
    } else if (Platform.isMacOS) {
      final info = await plugin.macOsInfo;
      final id = info.systemGUID;
      return 'macos:$id';
    } else if (Platform.isLinux) {
      final info = await plugin.linuxInfo;
      final id = info.machineId;
      return 'linux:$id';
    }
  } catch (_) {}
  return 'unknown';
}