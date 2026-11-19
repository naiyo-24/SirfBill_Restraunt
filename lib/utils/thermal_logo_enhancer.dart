import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Utility class to enhance restaurant logos for 80mm/72mm thermal receipt printing.
/// 
/// Thermal receipt printers are 1-bit monochrome (strictly black or white).
/// Standard colored logos (red, blue, gold, yellow, green) often print very faint
/// or completely disappear because their luminance gets dithered into invisible dots.
/// 
/// This helper:
/// 1. Flattens transparent backgrounds onto pure white (eliminates black box bugs).
/// 2. Autocrops empty white/transparent outer margins so the logo graphic can be enlarged
///    to fill the header width without wasting any blank vertical space.
/// 3. Applies a steep thermal contrast curve to deepen colored graphics and text into solid,
///    crisp black dots while keeping the background pure paper white.
class ThermalLogoEnhancer {
  static Uint8List enhanceForThermal(Uint8List rawBytes) {
    try {
      final img.Image? original = img.decodeImage(rawBytes);
      if (original == null) return rawBytes;

      final int width = original.width;
      final int height = original.height;

      // 1. Scan for bounding box of actual artwork (non-white, non-transparent)
      int minX = width;
      int minY = height;
      int maxX = 0;
      int maxY = 0;
      bool hasContent = false;

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final pixel = original.getPixel(x, y);
          final a = pixel.a;
          if (a > 25) {
            final double alphaNorm = a / 255.0;
            final double r = (pixel.r * alphaNorm) + (255 * (1.0 - alphaNorm));
            final double g = (pixel.g * alphaNorm) + (255 * (1.0 - alphaNorm));
            final double b = (pixel.b * alphaNorm) + (255 * (1.0 - alphaNorm));
            final double lum = 0.299 * r + 0.587 * g + 0.114 * b;

            if (lum < 240) {
              hasContent = true;
              if (x < minX) minX = x;
              if (x > maxX) maxX = x;
              if (y < minY) minY = y;
              if (y > maxY) maxY = y;
            }
          }
        }
      }

      // Crop excess empty margin around the artwork so logo appears significantly bigger
      img.Image cropped = original;
      if (hasContent && minX < maxX && minY < maxY) {
        const int pad = 4;
        final cropX = (minX - pad).clamp(0, width - 1);
        final cropY = (minY - pad).clamp(0, height - 1);
        final cropW = (maxX - minX + (pad * 2)).clamp(1, width - cropX);
        final cropH = (maxY - minY + (pad * 2)).clamp(1, height - cropY);
        cropped = img.copyCrop(original, x: cropX, y: cropY, width: cropW, height: cropH);
      }

      final int cW = cropped.width;
      final int cH = cropped.height;
      final img.Image enhanced = img.Image(width: cW, height: cH, numChannels: 1);

      // 2. High-contrast thermal curve:
      // Darkens all colored lines, symbols, and text to solid black (lum <= 170 -> 0)
      for (int y = 0; y < cH; y++) {
        for (int x = 0; x < cW; x++) {
          final p = cropped.getPixel(x, y);
          final a = p.a;
          if (a <= 25) {
            enhanced.setPixelRgb(x, y, 255, 255, 255);
            continue;
          }

          final double alphaNorm = a / 255.0;
          final double r = (p.r * alphaNorm) + (255 * (1.0 - alphaNorm));
          final double g = (p.g * alphaNorm) + (255 * (1.0 - alphaNorm));
          final double b = (p.b * alphaNorm) + (255 * (1.0 - alphaNorm));
          final double lum = 0.299 * r + 0.587 * g + 0.114 * b;

          if (lum >= 238) {
            enhanced.setPixelRgb(x, y, 255, 255, 255);
          } else if (lum <= 170) {
            // Colors like red, dark green, blue, brown, gold become solid deep black
            enhanced.setPixelRgb(x, y, 0, 0, 0);
          } else {
            // Anti-aliased edge smoothing
            final double factor = (lum - 170) / (238 - 170);
            final int gray = (factor * 255).round().clamp(0, 255);
            enhanced.setPixelRgb(x, y, gray, gray, gray);
          }
        }
      }

      return Uint8List.fromList(img.encodePng(enhanced));
    } catch (_) {
      return rawBytes;
    }
  }
}
