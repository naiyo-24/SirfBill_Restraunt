// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

final Set<String> _registeredViewTypes = <String>{};

Widget buildDishNetworkImage({
  required String imageUrl,
  required double width,
  required double height,
  required Widget Function() placeholderBuilder,
}) {
  final viewType = 'dish-img-${imageUrl.hashCode}';
  if (!_registeredViewTypes.contains(viewType)) {
    _registeredViewTypes.add(viewType);
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final img = html.ImageElement()
        ..src = imageUrl
        ..setAttribute('loading', 'lazy')
        ..setAttribute('decoding', 'async')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.borderRadius = '14px'
        ..style.display = 'block';
      return img;
    });
  }

  return SizedBox(
    width: width,
    height: height,
    child: HtmlElementView(viewType: viewType),
  );
}
