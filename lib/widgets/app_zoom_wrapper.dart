import 'package:flutter/material.dart';

/// AppZoomWrapper passes through the native UI at 100% scale.
/// Floating zoom overlay and screen scaling options have been disabled.
class AppZoomWrapper extends StatelessWidget {
  final Widget child;
  const AppZoomWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
