import 'package:flutter/services.dart';
import '../models.dart';

typedef VolumeButtonPressedCallback = void Function({required bool isVolumeUp});

class HardwareButtonService {
  static const MethodChannel platform = MethodChannel('com.timelog/volume_buttons');

  static void initialize({
    required bool Function() shouldHandle,
    required VolumeButtonPressedCallback onButtonPressed,
  }) {
    platform.setMethodCallHandler((call) async {
      if (!shouldHandle()) return;
      if (call.method == 'volumeUp') {
        onButtonPressed(isVolumeUp: true);
      } else if (call.method == 'volumeDown') {
        onButtonPressed(isVolumeUp: false);
      }
    });
  }

  static void dispose() {
    platform.setMethodCallHandler(null);
  }

  static Future<void> setInterceptPhysicalButtons(bool intercept) async {
    try {
      await platform.invokeMethod('setInterceptVolumeButtons', {'intercept': intercept});
    } catch (_) {
      // Ignorar en plataformas que no lo soporten o si el canal no está listo
    }
  }

  static void triggerHaptic({
    required bool enabled,
    required HapticLevel level,
  }) {
    if (!enabled) return;
    switch (level) {
      case HapticLevel.light:
        HapticFeedback.lightImpact();
        break;
      case HapticLevel.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticLevel.heavy:
        HapticFeedback.heavyImpact();
        break;
    }
  }
}
