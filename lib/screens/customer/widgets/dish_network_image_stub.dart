import 'package:flutter/material.dart';

Widget buildDishNetworkImage({
  required String imageUrl,
  required double width,
  required double height,
  required Widget Function() placeholderBuilder,
}) {
  return Image.network(
    imageUrl,
    width: width,
    height: height,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => placeholderBuilder(),
  );
}
