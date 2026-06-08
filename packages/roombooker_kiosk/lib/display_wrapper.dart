import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract class DisplayWrapper {
  Future<List<dynamic>> getDisplays();
  Future<void> showPresentationDisplay({
    required int displayId,
    required String routerName,
    Map<String, dynamic>? arguments,
  });
}

class MethodChannelDisplayWrapper implements DisplayWrapper {
  static const MethodChannel _channel = MethodChannel('org.goforthtech.roombooker_kiosk/display');

  @override
  Future<List<dynamic>> getDisplays() async {
    try {
      final List? displays = await _channel.invokeMethod('getDisplays');
      return displays ?? [];
    } catch (e) {
      debugPrint('Error listing displays: $e');
      return [];
    }
  }

  @override
  Future<void> showPresentationDisplay({
    required int displayId,
    required String routerName,
    Map<String, dynamic>? arguments,
  }) async {
    try {
      await _channel.invokeMethod('showOnDisplay', {
        'displayId': displayId,
        'routerName': routerName,
        'arguments': arguments,
      });
    } catch (e) {
      debugPrint('Error showing presentation display: $e');
    }
  }
}

class StubDisplayWrapper implements DisplayWrapper {
  @override
  Future<List<dynamic>> getDisplays() async => [];

  @override
  Future<void> showPresentationDisplay({
    required int displayId,
    required String routerName,
    Map<String, dynamic>? arguments,
  }) async {
    debugPrint('STUB: showPresentationDisplay on $displayId');
  }
}
