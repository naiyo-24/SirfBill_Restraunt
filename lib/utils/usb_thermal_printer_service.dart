import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'esc_pos_raster_helper.dart';

/// Represents a USB device discovered on the Android host.
class UsbPrinterDevice {
  final int deviceId;
  final String deviceName;
  final String productName;
  final String manufacturerName;
  final int vendorId;
  final int productId;
  final bool isPrinter;
  final bool hasPermission;

  const UsbPrinterDevice({
    required this.deviceId,
    required this.deviceName,
    required this.productName,
    required this.manufacturerName,
    required this.vendorId,
    required this.productId,
    required this.isPrinter,
    required this.hasPermission,
  });

  factory UsbPrinterDevice.fromMap(Map<dynamic, dynamic> map) {
    return UsbPrinterDevice(
      deviceId: map['deviceId'] as int? ?? 0,
      deviceName: map['deviceName'] as String? ?? '',
      productName: map['productName'] as String? ?? 'USB Printer',
      manufacturerName: map['manufacturerName'] as String? ?? '',
      vendorId: map['vendorId'] as int? ?? 0,
      productId: map['productId'] as int? ?? 0,
      isPrinter: map['isPrinter'] as bool? ?? false,
      hasPermission: map['hasPermission'] as bool? ?? false,
    );
  }

  String get displayName {
    if (productName.isNotEmpty && productName != 'USB Device') return productName;
    if (manufacturerName.isNotEmpty) return '$manufacturerName USB Printer';
    return 'USB Printer ($vendorId:$productId)';
  }
}

/// Direct Android USB OTG Thermal Printer Service.
/// Bypasses the Android Print Spooler to communicate directly with 58mm/80mm POS printers
/// via UsbManager, bulk OUT transfer, and ESC/POS raster formatting.
class UsbThermalPrinterService {
  static const MethodChannel _channel = MethodChannel('com.sirfbill.pos/usb_printer');

  /// Only Android supports direct UsbManager OTG communication.
  static bool get isSupported {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  /// Lists all connected USB devices identified as thermal printers or bulk-out endpoints.
  static Future<List<UsbPrinterDevice>> getConnectedPrinters() async {
    if (!isSupported) return [];
    try {
      final List<dynamic>? list = await _channel.invokeMethod('getUsbDevices');
      if (list == null) return [];
      return list
          .map((item) => UsbPrinterDevice.fromMap(Map<dynamic, dynamic>.from(item as Map)))
          .where((dev) => dev.isPrinter)
          .toList();
    } catch (e) {
      debugPrint('UsbThermalPrinterService.getConnectedPrinters error: $e');
      return [];
    }
  }

  /// Checks if the app currently has permission for a specific USB device.
  static Future<bool> hasPermission(int deviceId) async {
    if (!isSupported) return false;
    try {
      final bool? allowed = await _channel.invokeMethod('hasPermission', {'deviceId': deviceId});
      return allowed ?? false;
    } catch (e) {
      debugPrint('UsbThermalPrinterService.hasPermission error: $e');
      return false;
    }
  }

  /// Requests permission to communicate with a USB device.
  static Future<bool> requestPermission(int deviceId) async {
    if (!isSupported) return false;
    try {
      final bool? granted = await _channel.invokeMethod('requestPermission', {'deviceId': deviceId});
      return granted ?? false;
    } catch (e) {
      debugPrint('UsbThermalPrinterService.requestPermission error: $e');
      return false;
    }
  }

  /// Prints raw ESC/POS byte sequence over USB bulk transfer.
  static Future<bool> printRawBytes(Uint8List bytes, {int? deviceId}) async {
    if (!isSupported) return false;
    try {
      final Map<dynamic, dynamic>? res = await _channel.invokeMethod('printBytes', {
        'deviceId': deviceId,
        'bytes': bytes,
      });
      return res?['success'] == true;
    } catch (e) {
      debugPrint('UsbThermalPrinterService.printRawBytes error: $e');
      return false;
    }
  }

  /// Rasterizes a rendered PDF document to ESC/POS monochrome bitmap and prints it over USB.
  static Future<bool> printPdfDocument({
    required Uint8List pdfBytes,
    int? deviceId,
    int? paperWidthMm,
    int? paperWidthDots,
    bool cutPaper = true,
  }) async {
    if (!isSupported) return false;
    try {
      final dots = paperWidthDots ??
          (paperWidthMm != null ? EscPosRasterHelper.dotsFromMm(paperWidthMm) : 512);
      final escPosBytes = await EscPosRasterHelper.convertPdfToEscPos(
        pdfBytes,
        paperWidthDots: dots,
        cutAfter: cutPaper,
      );
      if (escPosBytes.isEmpty) return false;
      return await printRawBytes(escPosBytes, deviceId: deviceId);
    } catch (e) {
      debugPrint('UsbThermalPrinterService.printPdfDocument error: $e');
      return false;
    }
  }

  /// Prints KOT and Customer Bill sequentially with automatic cut between jobs.
  static Future<bool> printBothSequentially({
    required Uint8List billPdfBytes,
    required Uint8List kotPdfBytes,
    int? deviceId,
    int? paperWidthMm,
    int? paperWidthDots,
  }) async {
    if (!isSupported) return false;
    try {
      final dots = paperWidthDots ??
          (paperWidthMm != null ? EscPosRasterHelper.dotsFromMm(paperWidthMm) : 512);

      // 1. Print KOT first with cut
      final kotSuccess = await printPdfDocument(
        pdfBytes: kotPdfBytes,
        deviceId: deviceId,
        paperWidthDots: dots,
        cutPaper: true,
      );
      if (!kotSuccess) return false;

      // Small pause for printer mechanical cutter
      await Future.delayed(const Duration(milliseconds: 350));

      // 2. Print Customer Bill with cut
      final billSuccess = await printPdfDocument(
        pdfBytes: billPdfBytes,
        deviceId: deviceId,
        paperWidthDots: dots,
        cutPaper: true,
      );
      return billSuccess;
    } catch (e) {
      debugPrint('UsbThermalPrinterService.printBothSequentially error: $e');
      return false;
    }
  }
}
