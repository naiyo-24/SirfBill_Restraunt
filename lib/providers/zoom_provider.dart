import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final zoomProvider = NotifierProvider<ZoomNotifier, double>(() {
  return ZoomNotifier();
});

class ZoomNotifier extends Notifier<double> {
  static const String _prefKey = 'app_desktop_zoom_level';
  static const double minZoom = 0.65;
  static const double maxZoom = 1.40;
  static const double step = 0.05;

  @override
  double build() {
    return 1.0;
  }


  Future<void> setZoom(double newZoom) async {
    final clamped = double.parse(newZoom.clamp(minZoom, maxZoom).toStringAsFixed(2));
    if ((clamped - state).abs() > 0.001) {
      state = clamped;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble(_prefKey, clamped);
      } catch (_) {}
    }
  }

  void zoomIn() {
    setZoom(state + step);
  }

  void zoomOut() {
    setZoom(state - step);
  }

  void resetZoom() {
    setZoom(1.0);
  }

  void fitWidth(double currentWidth, {double baseWidth = 1200}) {
    if (currentWidth <= 0 || baseWidth <= 0) return;
    final idealRatio = (currentWidth / baseWidth);
    // If screen is wider than baseWidth, keep at 1.0, otherwise scale down to fit
    final target = idealRatio >= 1.0 ? 1.0 : idealRatio;
    setZoom(target);
  }
}
