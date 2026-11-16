import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../config/api_constants.dart';
import '../models/grn_models.dart';

class GrnDetailsDialog extends StatelessWidget {
  final GrnRecord grn;

  const GrnDetailsDialog({super.key, required this.grn});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final invoiceDateFormat = DateFormat('dd MMM yyyy');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 780,
        constraints: BoxConstraints(maxWidth: 820, maxHeight: MediaQuery.of(context).size.height * 0.88),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.verified_outlined, color: Color(0xFF10B981), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              grn.grnNumber,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('STOCK VERIFIED & INWARDED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Inward Date: ${dateFormat.format(grn.receivedDate)}',
                          style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // 2. Info Grid
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SUPPLIER / VENDOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 3),
                        Text(grn.supplierName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('VENDOR TAX INVOICE #', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 3),
                        Text(grn.supplierInvoiceNo.isNotEmpty ? grn.supplierInvoiceNo : 'N/A', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        if (grn.invoiceDocumentUrl != null && grn.invoiceDocumentUrl!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () => _openInvoiceDocument(context, grn.invoiceDocumentUrl!),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.attachment_rounded, size: 13, color: Color(0xFF3B82F6)),
                                SizedBox(width: 3),
                                Text(
                                  'View Bill Scan',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3B82F6),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('INVOICE DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 3),
                        Text(invoiceDateFormat.format(grn.invoiceDate), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PO REFERENCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 3),
                        Text(grn.poNumber, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Line Items Table
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                            ),
                            child: const Row(
                              children: [
                                Expanded(flex: 4, child: Text('ITEM / COMMODITY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('RECEIVED', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)))),
                                Expanded(flex: 2, child: Text('DOCK REJECTED', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange))),
                                Expanded(flex: 2, child: Text('ACTUAL PRICE', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('GST %', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)))),
                                Expanded(flex: 2, child: Text('LINE TOTAL', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ),
                          ...grn.items.map((item) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border(top: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), width: 0.5)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: Text(item.ingredientName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text('${item.quantityReceived} ${item.unit}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          item.quantityRejected > 0 ? '${item.quantityRejected} ${item.unit}' : '—',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 12, fontWeight: item.quantityRejected > 0 ? FontWeight.bold : FontWeight.normal, color: item.quantityRejected > 0 ? Colors.orange : Colors.grey),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text('₹${item.unitPrice.toStringAsFixed(2)}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text('${item.taxRate.toStringAsFixed(0)}%', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text('₹${item.totalPrice.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                                      ),
                                    ],
                                  ),
                                  if ((item.rejectionReason != null && item.rejectionReason!.isNotEmpty) || (item.batchNumber != null && item.batchNumber!.isNotEmpty) || item.expiryDate != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (item.rejectionReason != null && item.rejectionReason!.isNotEmpty)
                                          Text('Rejection audit: ${item.rejectionReason}', style: const TextStyle(fontSize: 11, color: Colors.orange, fontStyle: FontStyle.italic)),
                                        if (item.batchNumber != null && item.batchNumber!.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Text('Lot: ${item.batchNumber}', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                                        ],
                                        if (item.expiryDate != null) ...[
                                          const SizedBox(width: 8),
                                          Text('Expiry: ${invoiceDateFormat.format(item.expiryDate!)}', style: const TextStyle(fontSize: 11, color: Color(0xFF10B981))),
                                        ],
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    if (grn.remarks.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.notes, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Dock Notes: ${grn.remarks}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey))),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4. Footer & Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('Total Inward Bill Value: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(
                      '₹${grn.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (grn.invoiceDocumentUrl != null && grn.invoiceDocumentUrl!.isNotEmpty) ...[
                      OutlinedButton.icon(
                        onPressed: () => _openInvoiceDocument(context, grn.invoiceDocumentUrl!),
                        icon: const Icon(Icons.picture_as_pdf_outlined, size: 16, color: Color(0xFF3B82F6)),
                        label: const Text('View Vendor Bill', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF3B82F6)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF475569),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openInvoiceDocument(BuildContext context, String url) async {
    try {
      final fullUrl = url.startsWith('http')
          ? url
          : '${ApiConstants.baseUrl}${url.startsWith('/') ? '' : '/'}$url';
      final uri = Uri.parse(fullUrl);
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open document: $e')),
        );
      }
    }
  }
}
