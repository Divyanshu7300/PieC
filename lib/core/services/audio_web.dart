// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

void playPlatformTone(double frequency, double durationSeconds, String type, double volume) {
  try {
    js.context.callMethod('playSpatialTone', [frequency, durationSeconds, type, volume]);
  } catch (_) {}
}
