import 'package:flutter/material.dart';

enum ResponsiveType { mobile, tablet, desktop }

class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const Responsive({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  static bool isNarrowMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 500;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 850;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 850 &&
      MediaQuery.of(context).size.width < 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  static double width(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double height(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static ResponsiveType getType(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1100) return ResponsiveType.desktop;
    if (w >= 850) return ResponsiveType.tablet;
    return ResponsiveType.mobile;
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    if (size.width >= 1100) {
      return desktop;
    } else if (size.width >= 850 && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}

class ResponsiveSplitView extends StatelessWidget {
  final Widget leftPane;
  final Widget rightPane;
  final int leftFlex;
  final int rightFlex;
  final bool showRightPane;

  const ResponsiveSplitView({
    super.key,
    required this.leftPane,
    required this.rightPane,
    this.leftFlex = 1,
    this.rightFlex = 1,
    this.showRightPane = true,
  });

  @override
  Widget build(BuildContext context) {
    bool isDesktop =
        Responsive.isDesktop(context) || Responsive.isTablet(context);

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: leftFlex, child: leftPane),
          if (showRightPane) const SizedBox(width: 24),
          if (showRightPane) Expanded(flex: rightFlex, child: rightPane),
        ],
      );
    } else {
      return SingleChildScrollView(
        child: Column(
          children: [
            leftPane,
            if (showRightPane) const SizedBox(height: 24),
            if (showRightPane) rightPane,
          ],
        ),
      );
    }
  }
}
