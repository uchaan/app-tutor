import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

Future<String> getDeviceUniqueId() async {
  var deviceIdentifier = 'unknown';
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    deviceIdentifier = androidInfo.id!;
  } else if (Platform.isIOS) {
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    deviceIdentifier = iosInfo.identifierForVendor!;
  }
  print(deviceIdentifier);

  return deviceIdentifier;
}
