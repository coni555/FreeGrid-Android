import 'package:flutter/services.dart';

class FreeGridPlatform {
  const FreeGridPlatform._();

  static const _channel = MethodChannel('cn.conilab.freegrid/platform');

  static Future<String> appVersion() async {
    final version = await _channel.invokeMethod<String>('getAppVersion');
    return version ?? '—';
  }

  static Future<bool> openExternalUrl(Uri url) async {
    final opened = await _channel.invokeMethod<bool>('openExternalUrl', {
      'url': url.toString(),
    });
    return opened ?? false;
  }
}
