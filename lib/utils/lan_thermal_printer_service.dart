import 'dart:io';
import 'package:flutter/foundation.dart';
import 'esc_pos_raster_helper.dart';

/// Service to communicate directly with LAN / Ethernet / Wi-Fi Network Thermal POS Printers
/// via raw TCP socket on Port 9100 (standard POS JetDirect port).
/// Works cross-platform on Android, Windows, macOS, and Linux without native plugins.
class LanThermalPrinterService {
  static const int defaultPort = 9100;

  /// Web browsers do not allow raw TCP sockets due to sandbox restrictions.
  static bool get isSupported => !kIsWeb;

  /// Tests if a thermal printer is reachable at the given IP address and port.
  static Future<bool> testConnection(String ip, {int port = defaultPort}) async {
    if (!isSupported || ip.trim().isEmpty) return false;
    Socket? socket;
    try {
      socket = await Socket.connect(ip.trim(), port, timeout: const Duration(seconds: 3));
      return true;
    } catch (e) {
      debugPrint('LanThermalPrinterService connection test failed to $ip:$port -> $e');
      return false;
    } finally {
      try {
        await socket?.close();
      } catch (_) {}
    }
  }

  /// Sends raw ESC/POS byte sequence over TCP to the network printer.
  static Future<bool> printRawBytes(
    String ip,
    Uint8List bytes, {
    int port = defaultPort,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (!isSupported || ip.trim().isEmpty || bytes.isEmpty) return false;
    Socket? socket;
    try {
      socket = await Socket.connect(ip.trim(), port, timeout: timeout);
      socket.add(bytes);
      await socket.flush();
      return true;
    } catch (e) {
      debugPrint('LanThermalPrinterService printRawBytes error to $ip:$port -> $e');
      return false;
    } finally {
      try {
        await socket?.close();
      } catch (_) {}
    }
  }

  /// Converts rendered PDF to ESC/POS raster and prints it over LAN socket.
  static Future<bool> printPdfDocument({
    required String ip,
    required Uint8List pdfBytes,
    int port = defaultPort,
    int paperWidthMm = 80,
    int? paperWidthDots,
    bool cutPaper = true,
  }) async {
    if (!isSupported) return false;
    try {
      final dots = paperWidthDots ?? EscPosRasterHelper.dotsFromMm(paperWidthMm);
      final escPosBytes = await EscPosRasterHelper.convertPdfToEscPos(
        pdfBytes,
        paperWidthDots: dots,
        cutAfter: cutPaper,
      );
      if (escPosBytes.isEmpty) return false;
      return await printRawBytes(ip, escPosBytes, port: port);
    } catch (e) {
      debugPrint('LanThermalPrinterService printPdfDocument error: $e');
      return false;
    }
  }

  /// Prints KOT and Customer Bill sequentially over LAN with automatic cut in between.
  static Future<bool> printBothSequentially({
    required String ip,
    required Uint8List billPdfBytes,
    required Uint8List kotPdfBytes,
    int port = defaultPort,
    int paperWidthMm = 80,
    int? paperWidthDots,
  }) async {
    if (!isSupported) return false;
    try {
      final dots = paperWidthDots ?? EscPosRasterHelper.dotsFromMm(paperWidthMm);

      // 1. Print KOT first with cut
      final kotSuccess = await printPdfDocument(
        ip: ip,
        pdfBytes: kotPdfBytes,
        port: port,
        paperWidthDots: dots,
        cutPaper: true,
      );
      if (!kotSuccess) return false;

      // Small pause for printer mechanical cutter
      await Future.delayed(const Duration(milliseconds: 350));

      // 2. Print Customer Bill with cut
      final billSuccess = await printPdfDocument(
        ip: ip,
        pdfBytes: billPdfBytes,
        port: port,
        paperWidthDots: dots,
        cutPaper: true,
      );
      return billSuccess;
    } catch (e) {
      debugPrint('LanThermalPrinterService printBothSequentially error: $e');
      return false;
    }
  }
}
