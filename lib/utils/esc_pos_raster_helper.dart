import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:printing/printing.dart';

/// Helper to convert standard rendered PDF receipt documents or Images
/// into ESC/POS raster bit image commands (`GS v 0`) for direct USB thermal printing.
class EscPosRasterHelper {
  // Standard ESC/POS Commands
  static const List<int> cmdInit = [0x1B, 0x40]; // ESC @ (Initialize printer)
  static const List<int> cmdFeedLines = [0x1B, 0x64, 0x03]; // ESC d 3 (Feed 3 lines before cut)
  static const List<int> cmdPartialCut = [0x1D, 0x56, 0x42, 0x00]; // GS V 66 0 (Feed & partial cut)

  /// Translates paper width in mm (58mm or 80mm) to safe physical dots.
  /// 58mm = 384 dots (48 bytes/row).
  /// 80mm = 512 dots (64 bytes/row, universal safe width for 80mm POS printers).
  static int dotsFromMm(int paperWidthMm) {
    if (paperWidthMm <= 58) return 384;
    return 512;
  }

  /// Converts rendered PDF pages into a complete ESC/POS byte sequence.
  /// Automatically trims bottom blank paper waste and centers within safe printable margins.
  static Future<Uint8List> convertPdfToEscPos(
    Uint8List pdfBytes, {
    int paperWidthDots = 512,
    double dpi = 203.0,
    bool cutAfter = true,
  }) async {
    final List<int> totalBytes = [];
    totalBytes.addAll(cmdInit);

    try {
      final rasterStream = Printing.raster(pdfBytes, dpi: dpi);
      await for (final page in rasterStream) {
        final pngBytes = await page.toPng();
        final img.Image? decoded = img.decodeImage(pngBytes);
        if (decoded != null) {
          final rasterData = convertImageToEscPosRaster(
            decoded,
            paperWidthDots: paperWidthDots,
            includeInitAndCut: false,
          );
          totalBytes.addAll(rasterData);
        }
      }

      totalBytes.addAll(cmdFeedLines);
      if (cutAfter) {
        totalBytes.addAll(cmdPartialCut);
      }
    } catch (e) {
      debugPrint('Error converting PDF to ESC/POS: $e');
    }

    return Uint8List.fromList(totalBytes);
  }

  /// Scans from bottom up and crops out all empty trailing white space
  /// so thermal rolls don't waste 10-30 cm of blank paper.
  static img.Image trimBottomBlankSpace(img.Image image, {int bottomPaddingDots = 16}) {
    final int width = image.width;
    final int height = image.height;
    int lastContentY = 0;

    for (int y = height - 1; y >= 0; y--) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        final a = pixel.a;
        if (a > 30) {
          final double alphaNorm = a / 255.0;
          final double r = (pixel.r * alphaNorm) + (255 * (1.0 - alphaNorm));
          final double g = (pixel.g * alphaNorm) + (255 * (1.0 - alphaNorm));
          final double b = (pixel.b * alphaNorm) + (255 * (1.0 - alphaNorm));
          final double lum = 0.299 * r + 0.587 * g + 0.114 * b;
          if (lum < 225) {
            lastContentY = y;
            break;
          }
        }
      }
      if (lastContentY > 0) break;
    }

    if (lastContentY > 0 && lastContentY < height - 1) {
      final int targetHeight = (lastContentY + bottomPaddingDots).clamp(1, height);
      return img.copyCrop(image, x: 0, y: 0, width: width, height: targetHeight);
    }
    return image;
  }

  /// Converts an [img.Image] into ESC/POS `GS v 0` raster bitmap byte sequences.
  /// Centers content with safe side margins so the right side is never cut off.
  /// Slices vertically in bands of 240 rows to avoid thermal printer buffer overflow.
  static Uint8List convertImageToEscPosRaster(
    img.Image image, {
    int paperWidthDots = 512,
    bool includeInitAndCut = true,
  }) {
    final List<int> bytes = [];
    if (includeInitAndCut) {
      bytes.addAll(cmdInit);
    }

    // 1. Trim bottom blank white space from the rendered receipt
    final img.Image trimmed = trimBottomBlankSpace(image);

    // 2. Center content within printable area with safe side margins
    // to guarantee the right column (Qty, Rate, Total) is never cut off
    const int sideMarginDots = 6;
    final int activeWidth = (paperWidthDots - (sideMarginDots * 2)).clamp(100, paperWidthDots);
    final int targetHeight = ((trimmed.height * activeWidth) / trimmed.width).round();
    final img.Image scaled = img.copyResize(trimmed, width: activeWidth, height: targetHeight);

    final int width = paperWidthDots;
    final int height = targetHeight;
    final int bytesPerRow = (width + 7) ~/ 8;

    // 3. Slice vertically into bands of up to 240 rows per GS v 0 packet
    const int maxSliceHeight = 240;
    int currentY = 0;

    while (currentY < height) {
      final int sliceH = (height - currentY > maxSliceHeight) ? maxSliceHeight : (height - currentY);

      // GS v 0 m xL xH yL yH
      final int xL = bytesPerRow & 0xFF;
      final int xH = (bytesPerRow >> 8) & 0xFF;
      final int yL = sliceH & 0xFF;
      final int yH = (sliceH >> 8) & 0xFF;

      bytes.addAll([0x1D, 0x76, 0x30, 0x00, xL, xH, yL, yH]);

      for (int y = 0; y < sliceH; y++) {
        final int actualY = currentY + y;
        for (int byteIdx = 0; byteIdx < bytesPerRow; byteIdx++) {
          int byteVal = 0;
          for (int bit = 0; bit < 8; bit++) {
            final int pixelX = (byteIdx * 8) + bit;

            // Inside active content area (between side margins)
            if (pixelX >= sideMarginDots && pixelX < (sideMarginDots + activeWidth)) {
              final int scaledX = pixelX - sideMarginDots;
              if (scaledX < scaled.width && actualY < scaled.height) {
                final pixel = scaled.getPixel(scaledX, actualY);
                final a = pixel.a;
                if (a > 30) {
                  final double alphaNorm = a / 255.0;
                  final double r = (pixel.r * alphaNorm) + (255 * (1.0 - alphaNorm));
                  final double g = (pixel.g * alphaNorm) + (255 * (1.0 - alphaNorm));
                  final double b = (pixel.b * alphaNorm) + (255 * (1.0 - alphaNorm));
                  final double lum = 0.299 * r + 0.587 * g + 0.114 * b;

                  // Threshold: luminance < 190 counts as black dot (thermal burn)
                  if (lum < 190) {
                    byteVal |= (1 << (7 - bit));
                  }
                }
              }
            }
          }
          bytes.add(byteVal);
        }
      }

      currentY += sliceH;
    }

    if (includeInitAndCut) {
      bytes.addAll(cmdFeedLines);
      bytes.addAll(cmdPartialCut);
    }

    return Uint8List.fromList(bytes);
  }
}
