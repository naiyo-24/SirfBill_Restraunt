import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class SignatureDrawController extends ChangeNotifier {
  final List<List<Offset>> _strokes = [];
  bool get isEmpty => _strokes.isEmpty;

  void startStroke(Offset point) {
    _strokes.add([point]);
    notifyListeners();
  }

  void addPoint(Offset point) {
    if (_strokes.isEmpty) {
      _strokes.add([point]);
    } else {
      _strokes.last.add(point);
    }
    notifyListeners();
  }

  void clear() {
    _strokes.clear();
    notifyListeners();
  }

  Future<String?> toPngBase64({double width = 320, double height = 120}) async {
    if (_strokes.isEmpty) return null;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (final stroke in _strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(stroke.first, 1.25, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
      } else {
        final path = Path();
        path.moveTo(stroke.first.dx, stroke.first.dy);
        for (int i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;
    final bytes = byteData.buffer.asUint8List();
    return 'data:image/png;base64,${base64Encode(bytes)}';
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;

  _SignaturePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(stroke.first, 1.25, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
      } else {
        final path = Path();
        path.moveTo(stroke.first.dx, stroke.first.dy);
        for (int i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}

class SignatureDrawBox extends StatelessWidget {
  final String title;
  final String subtitle;
  final SignatureDrawController controller;
  final double height;

  const SignatureDrawBox({
    super.key,
    required this.title,
    this.subtitle = 'Sign using mouse or finger / touch',
    required this.controller,
    this.height = 110,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
            TextButton.icon(
              onPressed: controller.clear,
              icon: const Icon(Icons.refresh_rounded, size: 14, color: Colors.grey),
              label: const Text('Clear', style: TextStyle(fontSize: 11, color: Colors.grey)),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              const Positioned(
                bottom: 8,
                left: 12,
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 12, color: Color(0xFFCBD5E1)),
                    SizedBox(width: 4),
                    Text('X ................................................................', style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 11, letterSpacing: 2)),
                  ],
                ),
              ),
              ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (details) => controller.startStroke(details.localPosition),
                    onPanUpdate: (details) => controller.addPoint(details.localPosition),
                    child: CustomPaint(
                      painter: _SignaturePainter(controller._strokes),
                      size: Size.infinite,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
