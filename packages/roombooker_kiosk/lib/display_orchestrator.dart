import 'dart:async';
import 'package:flutter/material.dart';
import 'package:roombooker_kiosk/display_wrapper.dart';

class DisplayInfo {
  final int displayId;
  final String name;
  final bool isValid;

  DisplayInfo({required this.displayId, required this.name, required this.isValid});

  factory DisplayInfo.fromMap(Map<dynamic, dynamic> map) {
    return DisplayInfo(
      displayId: map['displayId'] as int,
      name: map['name'] as String,
      isValid: map['isValid'] as bool,
    );
  }
}

class DisplayOrchestrator extends ChangeNotifier {
  final DisplayWrapper _wrapper;
  List<DisplayInfo> _displays = [];
  List<DisplayInfo> get displays => _displays;

  DisplayInfo? get secondaryDisplay => _displays.length > 1 ? _displays[1] : null;

  DisplayOrchestrator({DisplayWrapper? wrapper})
      : _wrapper = wrapper ?? StubDisplayWrapper() {
    refresh();
  }

  Future<void> refresh() async {
    try {
      final List result = await _wrapper.getDisplays();
      _displays = result.map((m) => DisplayInfo.fromMap(m as Map)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error getting displays: $e');
    }
  }

  Future<void> showOnStage(String routerName, {Map<String, dynamic>? arguments}) async {
    final display = secondaryDisplay;
    if (display != null) {
      try {
        await _wrapper.showPresentationDisplay(
          displayId: display.displayId,
          routerName: routerName,
          arguments: arguments,
        );
      } catch (e) {
        debugPrint('Failed to show on stage: $e');
      }
    }
  }
}
