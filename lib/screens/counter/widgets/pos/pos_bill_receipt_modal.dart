import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../utils/usb_thermal_printer_service.dart';
import 'controllers/thermal_print_dispatcher.dart';
import 'pos_bill_receipt_footer.dart';
import 'thermal_printer_settings_dialog.dart';

/// Modal dialog that immediately renders the generated 72mm thermal receipt on-screen
/// for cashier verification and provides direct one-click printing across USB, LAN, and Bluetooth.
class PosBillReceiptModal extends StatefulWidget {
  final String orderNumber;
  final String title;
  final Uint8List pdfBytes;
  final Uint8List? kotBytes;
  final String? kotNumber;
  final VoidCallback? onDismiss;

  const PosBillReceiptModal({
    super.key,
    required this.orderNumber,
    required this.title,
    required this.pdfBytes,
    this.kotBytes,
    this.kotNumber,
    this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required String orderNumber,
    required String title,
    required Uint8List pdfBytes,
    Uint8List? kotBytes,
    String? kotNumber,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PosBillReceiptModal(
        orderNumber: orderNumber,
        title: title,
        pdfBytes: pdfBytes,
        kotBytes: kotBytes,
        kotNumber: kotNumber,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  State<PosBillReceiptModal> createState() => _PosBillReceiptModalState();
}

class _PosBillReceiptModalState extends State<PosBillReceiptModal> {
  int _selectedTab = 0; // 0 = Customer Bill, 1 = Kitchen KOT
  bool _isPrinting = false;
  List<UsbPrinterDevice> _usbPrinters = [];
  int _paperWidthMm = 80;
  String _printerMode = 'usb'; // 'usb', 'lan', 'bt'
  String _lanIp = '192.168.1.100';
  String? _btAddress;

  @override
  void initState() {
    super.initState();
    _loadPrinterPreferences();
    _checkUsbPrinters();
  }

  Future<void> _loadPrinterPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mode = prefs.getString('thermal_printer_mode') ?? 'usb';
      final savedWidth = prefs.getInt('usb_thermal_paper_width_mm') ?? 80;
      final ip = prefs.getString('thermal_lan_printer_ip') ?? '192.168.1.100';
      final bt = prefs.getString('thermal_bt_printer_address');
      if (mounted) {
        setState(() {
          _printerMode = mode;
          _paperWidthMm = savedWidth;
          _lanIp = ip;
          _btAddress = bt;
        });
      }
    } catch (_) {}
  }

  Future<void> _setPaperWidthMm(int mm) async {
    setState(() => _paperWidthMm = mm);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('usb_thermal_paper_width_mm', mm);
    } catch (_) {}
  }

  Future<void> _checkUsbPrinters() async {
    if (UsbThermalPrinterService.isSupported) {
      final list = await UsbThermalPrinterService.getConnectedPrinters();
      if (mounted) {
        setState(() => _usbPrinters = list);
      }
    }
  }

  Future<void> _openSettingsDialog() async {
    await ThermalPrinterSettingsDialog.show(context);
    await _loadPrinterPreferences();
    await _checkUsbPrinters();
  }

  Future<void> _handleDirectPrint({required Uint8List bytes}) async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);
    try {
      if (_printerMode == 'usb') {
        await _checkUsbPrinters();
      }
      if (mounted) {
        await ThermalPrintDispatcher.printDirect(
          context: context,
          bytes: bytes,
          mode: _printerMode,
          paperWidthMm: _paperWidthMm,
          lanIp: _lanIp,
          btAddress: _btAddress,
          usbPrinters: _usbPrinters,
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<void> _handleBothDirect() async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);
    try {
      if (_printerMode == 'usb') {
        await _checkUsbPrinters();
      }
      if (mounted) {
        await ThermalPrintDispatcher.printBothDirect(
          context: context,
          billBytes: widget.pdfBytes,
          kotBytes: widget.kotBytes,
          mode: _printerMode,
          paperWidthMm: _paperWidthMm,
          lanIp: _lanIp,
          btAddress: _btAddress,
          usbPrinters: _usbPrinters,
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<void> _handleBothSystemSpooler() async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);
    try {
      await ThermalPrintDispatcher.printBothViaSystemSpooler(
        billBytes: widget.pdfBytes,
        kotBytes: widget.kotBytes,
        orderNumber: widget.orderNumber,
      );
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final hasKot = widget.kotBytes != null;
    final currentDocBytes = (_selectedTab == 1 && hasKot) ? widget.kotBytes! : widget.pdfBytes;

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 480,
          maxHeight: 720,
        ),
        child: Column(
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          size: 22,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Invoice / Token: ${widget.orderNumber}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.tune_rounded, size: 20, color: Color(0xFF0D9488)),
                        tooltip: 'Printer Setup (USB / LAN / BT)',
                        onPressed: _openSettingsDialog,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 22),
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onDismiss?.call();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tab Selector if both Customer Bill and KOT are available
            if (hasKot)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0
                                ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _selectedTab == 0
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Customer Bill',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _selectedTab == 0 ? FontWeight.bold : FontWeight.w500,
                              color: _selectedTab == 0 ? const Color(0xFF10B981) : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1
                                ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _selectedTab == 1
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Kitchen KOT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _selectedTab == 1 ? FontWeight.bold : FontWeight.w500,
                              color: _selectedTab == 1 ? const Color(0xFFF97316) : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // On-screen 72mm Receipt PDF Preview
            Expanded(
              child: PdfPreview(
                key: ValueKey('${widget.orderNumber}_$_selectedTab'),
                build: (format) async => currentDocBytes,
                initialPageFormat: const PdfPageFormat(
                  72 * PdfPageFormat.mm,
                  280 * PdfPageFormat.mm,
                  marginAll: 2.5 * PdfPageFormat.mm,
                ),
                pageFormats: const {
                  '72mm Thermal Roll': PdfPageFormat(
                    72 * PdfPageFormat.mm,
                    280 * PdfPageFormat.mm,
                    marginAll: 2.5 * PdfPageFormat.mm,
                  ),
                },
                allowPrinting: false,
                allowSharing: true,
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
                pdfFileName: _selectedTab == 1
                    ? 'KOT_${widget.orderNumber.replaceAll("#", "")}.pdf'
                    : 'Bill_${widget.orderNumber.replaceAll("#", "")}.pdf',
              ),
            ),

            // Modal Footer Actions
            PosBillReceiptFooter(
              isDark: isDark,
              hasKot: hasKot,
              isPrinting: _isPrinting,
              usbPrinters: _usbPrinters,
              paperWidthMm: _paperWidthMm,
              printerMode: _printerMode,
              onPaperWidthChanged: _setPaperWidthMm,
              onOpenSettings: _openSettingsDialog,
              onClose: () {
                Navigator.pop(context);
                widget.onDismiss?.call();
              },
              onPrintKot: hasKot
                  ? () => ThermalPrintDispatcher.printViaSystemSpooler(
                        bytes: widget.kotBytes!,
                        jobName: 'KOT_${widget.orderNumber.replaceAll("#", "")}',
                      )
                  : null,
              onPrintBill: () => ThermalPrintDispatcher.printViaSystemSpooler(
                bytes: widget.pdfBytes,
                jobName: 'Bill_${widget.orderNumber.replaceAll("#", "")}',
              ),
              onPrintBoth: hasKot ? _handleBothSystemSpooler : null,
              onDirectPrint: hasKot ? _handleBothDirect : () => _handleDirectPrint(bytes: widget.pdfBytes),
            ),
          ],
        ),
      ),
    );
  }
}
