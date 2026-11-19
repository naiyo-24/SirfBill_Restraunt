import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

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
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onDismiss?.call();
                    },
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onDismiss?.call();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Close', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  if (hasKot) ...[
                    OutlinedButton.icon(
                      onPressed: _isPrinting
                          ? null
                          : () => _printDocument(
                                bytes: widget.kotBytes!,
                                jobName: 'KOT_${widget.orderNumber.replaceAll("#", "")}',
                              ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF97316),
                        side: const BorderSide(color: Color(0xFFF97316)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.soup_kitchen_rounded, size: 15),
                      label: const Text('Print KOT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton.icon(
                    onPressed: _isPrinting
                        ? null
                        : () => _printDocument(
                              bytes: widget.pdfBytes,
                              jobName: 'Bill_${widget.orderNumber.replaceAll("#", "")}',
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.print_rounded, size: 15),
                    label: const Text('Print Bill', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  if (hasKot) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isPrinting ? null : _printBothSequentially,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      icon: _isPrinting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.content_cut_rounded, size: 15),
                      label: const Text(
                        'Print Both (Cut)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
