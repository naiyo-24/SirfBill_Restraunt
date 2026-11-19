import 'package:flutter/material.dart';
import '../../../../utils/usb_thermal_printer_service.dart';

/// Footer action buttons bar for [PosBillReceiptModal].
class PosBillReceiptFooter extends StatelessWidget {
  final bool isDark;
  final bool hasKot;
  final bool isPrinting;
  final List<UsbPrinterDevice> usbPrinters;
  final int paperWidthMm;
  final ValueChanged<int>? onPaperWidthChanged;
  final VoidCallback onClose;
  final VoidCallback? onPrintKot;
  final VoidCallback onPrintBill;
  final VoidCallback? onPrintBoth;
  final VoidCallback? onUsbPrint;

  const PosBillReceiptFooter({
    super.key,
    required this.isDark,
    required this.hasKot,
    required this.isPrinting,
    required this.usbPrinters,
    this.paperWidthMm = 80,
    this.onPaperWidthChanged,
    required this.onClose,
    this.onPrintKot,
    required this.onPrintBill,
    this.onPrintBoth,
    this.onUsbPrint,
  });

  Widget _buildPaperTab(String label, int mm) {
    final isSelected = paperWidthMm == mm;
    return InkWell(
      onTap: () => onPaperWidthChanged?.call(mm),
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D9488) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF0F172A)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (UsbThermalPrinterService.isSupported)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            color: const Color(0xFF0D9488).withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.usb_rounded, size: 16, color: Color(0xFF0D9488)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    usbPrinters.isNotEmpty
                        ? 'USB: ${usbPrinters.first.displayName}'
                        : 'USB Thermal Mode',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0D9488),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onPaperWidthChanged != null) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPaperTab('58mm (2")', 58),
                        _buildPaperTab('80mm (3")', 80),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: onClose,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Close', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                if (hasKot && onPrintKot != null) ...[
                  OutlinedButton.icon(
                    onPressed: isPrinting ? null : onPrintKot,
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
                  onPressed: isPrinting ? null : onPrintBill,
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
                if (hasKot && onPrintBoth != null) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: isPrinting ? null : onPrintBoth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    icon: isPrinting
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
                if (UsbThermalPrinterService.isSupported && onUsbPrint != null) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: isPrinting ? null : onUsbPrint,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.usb_rounded, size: 15),
                    label: Text(
                      hasKot ? 'USB Both' : 'USB Print',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
