import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart' as vib;

const _desktopPlatforms = {TargetPlatform.linux, TargetPlatform.macOS, TargetPlatform.windows};

Future<void> vibrateShort() async {
  if (_desktopPlatforms.contains(defaultTargetPlatform)) return;
  try {
    if (await vib.Vibration.hasVibrator()) {
      await vib.Vibration.vibrate(duration: 50);
    }
  } catch (e) {
    debugPrint('Vibration impossible: $e');
  }
}
