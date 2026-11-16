// ignore_for_file: avoid_web_libraries_in_flutter
// ignore: deprecated_member_use
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

TargetPlatform getSafeWebPlatform() {
  try {
    final platform = html.window.navigator.platform?.toLowerCase() ?? '';
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    if (platform.contains('mac') || userAgent.contains('mac')) {
      return TargetPlatform.macOS;
    }
    if (platform.contains('win') || userAgent.contains('win')) {
      return TargetPlatform.windows;
    }
    if (platform.contains('linux') || userAgent.contains('linux')) {
      return TargetPlatform.linux;
    }
    if (userAgent.contains('iphone') || userAgent.contains('ipad')) {
      return TargetPlatform.iOS;
    }
    if (userAgent.contains('android')) {
      return TargetPlatform.android;
    }
  } catch (_) {}
  return TargetPlatform.macOS;
}
