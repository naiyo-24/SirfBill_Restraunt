import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'esc_pos_raster_helper.dart';

/// Represents a paired Bluetooth device.
class BluetoothPrinterDevice {
  final String name;
  final String address;
  final int type;

  const BluetoothPrinterDevice({
    required this.name,
    required this.address,
    required this.type,
  });

  factory BluetoothPrinterDevice.fromMap(Map<dynamic, dynamic> map) {
    return BluetoothPrinterDevice(
      name: map['name'] as String? ?? 'Bluetooth Printer',
      address: map['address'] as String? ?? '',
      type: map['type'] as int? ?? 0,
    );
  }

  String get displayName => name.isNotEmpty ? name : 'BT Printer ($address)';
}

/// Service to discover paired Bluetooth thermal receipt printers and print ESC/POS bytes
/// directly over RFCOMM SPP socket.
class BluetoothThermalPrinterService {
  static const MethodChannel _channel = MethodChannel('com.sirfbill.pos/bluetooth_printer');

  static bool get isSupported {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  static Future<bool> hasPermission() async {
    if (!isSupported) return false;
    try {
      final bool? allowed = await _channel.invokeMethod('hasPermission');
      return allowed ?? false;
    } catch (e) {
      debugPrint('BluetoothThermalPrinterService.hasPermission error: $e');
      return false;
    }
  }

  static Future<bool> requestPermission() async {
    if (!isSupported) return false;
    try {
      final bool? granted = await _channel.invokeMethod('requestPermission');
      return granted ?? false;
    } catch (e) {
      debugPrint('BluetoothThermalPrinterService.requestPermission error: $e');
      return false;
    }
  }

  /// Lists all paired Bluetooth devices on the Android device.
  static Future<List<BluetoothPrinterDevice>> getPairedPrinters() async {
    if (!isSupported) return [];
    try {
      final bool allowed = await hasPermission();
      if (!allowed) {
        final granted = await requestPermission();
        if (!granted) return [];
      }

      final List<dynamic>? list = await _channel.invokeMethod('getBondedDevices');
      if (list == null) return [];
      return list
          .map((item) => BluetoothPrinterDevice.fromMap(Map<dynamic, dynamic>.from(item as Map)))
          .toList();
    } catch (e) {
      debugPrint('BluetoothThermalPrinterService.getPairedPrinters error: $e');
      return [];
    }
  }

  /// Sends raw ESC/POS bytes over Bluetooth SPP socket to the device MAC address.
  static Future<bool> printRawBytes(String address, Uint8List bytes) async {
    if (!isSupported || address.isEmpty || bytes.isEmpty) return false;
    try {
      final Map<dynamic, dynamic>? res = await _channel.invokeMethod('printBytes', {
        'address': address,
        'bytes': bytes,
      });
      return res?['success'] == true;
    } catch (e) {
      debugPrint('BluetoothThermalPrinterService.printRawBytes error: $e');
      return false;
    }
  }

  /// Rasterizes PDF to ESC/POS and prints it over Bluetooth.
  static Future<bool> printPdfDocument({
    required String address,
    required Uint8List pdfBytes,
    int paperWidthMm = 58,
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
      return await printRawBytes(address, escPosBytes);
    } catch (e) {
      debugPrint('BluetoothThermalPrinterService.printPdfDocument error: $e');
      return false;
    }
  }

  /// Prints KOT and Customer Bill sequentially over Bluetooth with cut in between.
  static Future<bool> printBothSequentially({
    required String address,
    required Uint8List billPdfBytes,
    required Uint8List kotPdfBytes,
    int paperWidthMm = 58,
    int? paperWidthDots,
  }) async {
    if (!isSupported) return false;
    try {
      final dots = paperWidthDots ?? EscPosRasterHelper.dotsFromMm(paperWidthMm);

      final kotSuccess = await printPdfDocument(
        address: address,
        pdfBytes: kotPdfBytes,
        paperWidthDots: dots,
        cutPaper: true,
      );
      if (!kotSuccess) return false;

      await Future.delayed(const Duration(milliseconds: 400));

      final billSuccess = await printPdfDocument(
        address: address,
        pdfBytes: billPdfBytes,
        paperWidthDots: dots,
        cutPaper: true,
      );
      return billSuccess;
    } catch (e) {
      debugPrint('BluetoothThermalPrinterService.printBothSequentially error: $e');
      return false;
    }
  }
}
