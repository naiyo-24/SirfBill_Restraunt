import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../../../../utils/bluetooth_thermal_printer_service.dart';
import '../../../../../utils/lan_thermal_printer_service.dart';
import '../../../../../utils/usb_thermal_printer_service.dart';

/// Central dispatcher for thermal receipt printing across USB, LAN, and Bluetooth.
class ThermalPrintDispatcher {
  /// Standard OS Print Spooler print (Windows / macOS / Chrome / Android Print Spooler).
  static Future<void> printViaSystemSpooler({
    required Uint8List bytes,
    required String jobName,
  }) async {
    const format = PdfPageFormat(
      72 * PdfPageFormat.mm,
      280 * PdfPageFormat.mm,
      marginAll: 2.5 * PdfPageFormat.mm,
    );
    await Printing.layoutPdf(
      name: jobName,
      format: format,
      onLayout: (PdfPageFormat f) async => bytes,
    );
  }

  /// System Spooler sequential print (KOT first, then Bill).
  static Future<void> printBothViaSystemSpooler({
    required Uint8List billBytes,
    required Uint8List? kotBytes,
    required String orderNumber,
  }) async {
    final cleanOrder = orderNumber.replaceAll("#", "");
    if (kotBytes != null) {
      await printViaSystemSpooler(bytes: kotBytes, jobName: 'KOT_$cleanOrder');
      await Future.delayed(const Duration(milliseconds: 600));
    }
    await printViaSystemSpooler(bytes: billBytes, jobName: 'Bill_$cleanOrder');
  }

  /// Direct hardware thermal print (bypasses OS spooler) via LAN, Bluetooth, or USB.
  static Future<bool> printDirect({
    required BuildContext context,
    required Uint8List bytes,
    required String mode, // 'usb', 'lan', 'bt'
    required int paperWidthMm,
    required String lanIp,
    String? btAddress,
    List<UsbPrinterDevice> usbPrinters = const [],
  }) async {
    bool success = false;
    String targetLabel = 'Thermal Printer';

    if (mode == 'lan') {
      targetLabel = 'LAN Printer ($lanIp)';
      success = await LanThermalPrinterService.printPdfDocument(
        ip: lanIp,
        pdfBytes: bytes,
        paperWidthMm: paperWidthMm,
        cutPaper: true,
      );
    } else if (mode == 'bt') {
      var addr = btAddress;
      if (addr == null || addr.isEmpty) {
        final btList = await BluetoothThermalPrinterService.getPairedPrinters();
        if (btList.isNotEmpty) addr = btList.first.address;
      }
      if (addr == null || addr.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No Bluetooth printer selected. Please configure in Setup.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return false;
      }
      targetLabel = 'Bluetooth Printer';
      success = await BluetoothThermalPrinterService.printPdfDocument(
        address: addr,
        pdfBytes: bytes,
        paperWidthMm: paperWidthMm,
        cutPaper: true,
      );
    } else {
      // USB mode
      targetLabel = 'USB Printer';
      if (usbPrinters.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No USB thermal printer detected. Connect via OTG or switch mode in Setup.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return false;
      }
      success = await UsbThermalPrinterService.printPdfDocument(
        pdfBytes: bytes,
        paperWidthMm: paperWidthMm,
        cutPaper: true,
      );
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Receipt printed via $targetLabel!' : 'Print failed. Check $targetLabel connection.'),
          backgroundColor: success ? const Color(0xFF10B981) : Colors.redAccent,
        ),
      );
    }
    return success;
  }

  /// Direct sequential hardware thermal print (KOT -> Cut -> Bill -> Cut).
  static Future<bool> printBothDirect({
    required BuildContext context,
    required Uint8List billBytes,
    required Uint8List? kotBytes,
    required String mode,
    required int paperWidthMm,
    required String lanIp,
    String? btAddress,
    List<UsbPrinterDevice> usbPrinters = const [],
  }) async {
    if (kotBytes == null) {
      return printDirect(
        context: context,
        bytes: billBytes,
        mode: mode,
        paperWidthMm: paperWidthMm,
        lanIp: lanIp,
        btAddress: btAddress,
        usbPrinters: usbPrinters,
      );
    }

    bool success = false;
    String targetLabel = 'Thermal Printer';

    if (mode == 'lan') {
      targetLabel = 'LAN Printer ($lanIp)';
      success = await LanThermalPrinterService.printBothSequentially(
        ip: lanIp,
        billPdfBytes: billBytes,
        kotPdfBytes: kotBytes,
        paperWidthMm: paperWidthMm,
      );
    } else if (mode == 'bt') {
      var addr = btAddress;
      if (addr == null || addr.isEmpty) {
        final btList = await BluetoothThermalPrinterService.getPairedPrinters();
        if (btList.isNotEmpty) addr = btList.first.address;
      }
      if (addr == null || addr.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No Bluetooth printer selected. Please configure in Setup.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return false;
      }
      targetLabel = 'Bluetooth Printer';
      success = await BluetoothThermalPrinterService.printBothSequentially(
        address: addr,
        billPdfBytes: billBytes,
        kotPdfBytes: kotBytes,
        paperWidthMm: paperWidthMm,
      );
    } else {
      targetLabel = 'USB Printer';
      if (usbPrinters.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No USB thermal printer detected. Connect via OTG or switch mode in Setup.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return false;
      }
      success = await UsbThermalPrinterService.printBothSequentially(
        billPdfBytes: billBytes,
        kotPdfBytes: kotBytes,
        paperWidthMm: paperWidthMm,
      );
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Both KOT & Bill printed via $targetLabel!' : 'Print failed. Check $targetLabel.'),
          backgroundColor: success ? const Color(0xFF10B981) : Colors.redAccent,
        ),
      );
    }
    return success;
  }
}
