import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../utils/usb_thermal_printer_service.dart';
import 'pos_bill_receipt_footer.dart';

/// Modal dialog that immediately renders the generated 72mm thermal receipt on-screen
/// for cashier verification and provides direct one-click printing, separate KOT printing,
/// or sequential "Print Both (Auto-Cut)" printing.
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

  @override
  void initState() {
    super.initState();
    _loadPaperWidthPref();
    _checkUsbPrinters();
  }

  Future<void> _loadPaperWidthPref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt('usb_thermal_paper_width_mm') ?? 80;
      if (mounted) setState(() => _paperWidthMm = saved);
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

  Future<void> _printDocument({required Uint8List bytes, required String jobName}) async {
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

  Future<void> _printViaUsb({required Uint8List bytes}) async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);
    try {
      final success = await UsbThermalPrinterService.printPdfDocument(
        pdfBytes: bytes,
        paperWidthMm: _paperWidthMm,
        cutPaper: true,
      );
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Receipt printed via USB thermal printer!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('USB Print failed. Check OTG cable & printer power.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('USB print error: $e');
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<void> _printBothViaUsb() async {
    if (_isPrinting) return;
    if (widget.kotBytes == null) {
      await _printViaUsb(bytes: widget.pdfBytes);
      return;
    }
    setState(() => _isPrinting = true);
    try {
      final success = await UsbThermalPrinterService.printBothSequentially(
        billPdfBytes: widget.pdfBytes,
        kotPdfBytes: widget.kotBytes!,
        paperWidthMm: _paperWidthMm,
      );
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Both KOT and Bill printed via USB!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('USB Print failed. Check connection.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('USB print both error: $e');
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  /// Option A: Prints KOT first (Job 1 -> printer auto-cuts paper), then Customer Bill (Job 2 -> printer auto-cuts paper)
  Future<void> _printBothSequentially() async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);
    try {
      if (widget.kotBytes != null) {
        final kotJob = 'KOT_${widget.orderNumber.replaceAll("#", "")}';
        await _printDocument(bytes: widget.kotBytes!, jobName: kotJob);
        await Future.delayed(const Duration(milliseconds: 600));
      }
      final billJob = 'Bill_${widget.orderNumber.replaceAll("#", "")}';
      await _printDocument(bytes: widget.pdfBytes, jobName: billJob);
    } catch (e) {
      debugPrint('Error printing both receipts: $e');
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
                      if (UsbThermalPrinterService.isSupported)
                        IconButton(
                          icon: const Icon(Icons.usb_rounded, size: 20, color: Color(0xFF0D9488)),
                          tooltip: 'Scan USB Thermal Printers',
                          onPressed: _checkUsbPrinters,
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
              onPaperWidthChanged: _setPaperWidthMm,
              onClose: () {
                Navigator.pop(context);
                widget.onDismiss?.call();
              },
              onPrintKot: hasKot
                  ? () => _printDocument(
                        bytes: widget.kotBytes!,
                        jobName: 'KOT_${widget.orderNumber.replaceAll("#", "")}',
                      )
                  : null,
              onPrintBill: () => _printDocument(
                bytes: widget.pdfBytes,
                jobName: 'Bill_${widget.orderNumber.replaceAll("#", "")}',
              ),
              onPrintBoth: hasKot ? _printBothSequentially : null,
              onUsbPrint: () async {
                await _checkUsbPrinters();
                if (_usbPrinters.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No USB thermal printer detected. Please connect printer via OTG adapter.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                  return;
                }
                if (hasKot) {
                  await _printBothViaUsb();
                } else {
                  await _printViaUsb(bytes: widget.pdfBytes);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
