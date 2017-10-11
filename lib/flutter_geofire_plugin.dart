import 'dart:async';

import 'package:flutter/services.dart';

class FlutterGeofirePlugin {
  static const MethodChannel _channel =
      const MethodChannel('flutter_geofire_plugin');

  static Future<String> get platformVersion =>
      _channel.invokeMethod('getPlatformVersion');
}
