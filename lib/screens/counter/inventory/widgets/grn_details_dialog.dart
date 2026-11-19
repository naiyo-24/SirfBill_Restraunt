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
    final isMobile = MediaQuery.of(context).size.width < 650;
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final invoiceDateFormat = DateFormat('dd MMM yyyy');

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 40, vertical: isMobile ? 12 : 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 780,
        constraints: BoxConstraints(maxWidth: 820, maxHeight: MediaQuery.of(context).size.height * 0.90),
        padding: EdgeInsets.all(isMobile ? 14 : 24),
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
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.verified_outlined, color: Color(0xFF10B981), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              grn.grnNumber,
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isMobile) ...[
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
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Inward Date: ${dateFormat.format(grn.receivedDate)}',
                        style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // 2. Info Grid
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildInfoItem('SUPPLIER / VENDOR', grn.supplierName)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildInfoItem('PO REFERENCE', grn.poNumber, valueColor: const Color(0xFF3B82F6))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _buildInvoiceItem(context, grn)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildInfoItem('INVOICE DATE', invoiceDateFormat.format(grn.invoiceDate))),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: _buildInfoItem('SUPPLIER / VENDOR', grn.supplierName)),
                        Expanded(child: _buildInvoiceItem(context, grn)),
                        Expanded(child: _buildInfoItem('INVOICE DATE', invoiceDateFormat.format(grn.invoiceDate))),
                        Expanded(child: _buildInfoItem('PO REFERENCE', grn.poNumber, valueColor: const Color(0xFF3B82F6))),
                      ],
                    ),
            ),
            const SizedBox(height: 14),

            // 3. Line Items Table
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isMobile)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: 580,
                          child: _buildTableContainer(isDark, invoiceDateFormat),
                        ),
                      )
                    else
                      _buildTableContainer(isDark, invoiceDateFormat),
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
            const SizedBox(height: 14),

            // 4. Footer & Close
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Inward Bill Value: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('₹${grn.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (grn.invoiceDocumentUrl != null && grn.invoiceDocumentUrl!.isNotEmpty) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _openInvoiceDocument(context, grn.invoiceDocumentUrl!),
                            icon: const Icon(Icons.picture_as_pdf_outlined, size: 14, color: Color(0xFF3B82F6)),
                            label: const Text('Vendor Bill', style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6), fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF3B82F6)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF475569),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
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

  Widget _buildTableContainer(bool isDark, DateFormat invoiceDateFormat) {
    return Container(
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
                Expanded(flex: 2, child: Text('REJECTED', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange))),
                Expanded(flex: 2, child: Text('PRICE', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('GST %', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)))),
                Expanded(flex: 2, child: Text('TOTAL', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
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
                        child: Text(item.ingredientName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
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
    );
  }

  Widget _buildInfoItem(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor), overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildInvoiceItem(BuildContext context, GrnRecord grn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('VENDOR TAX INVOICE #', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 3),
        Text(grn.supplierInvoiceNo.isNotEmpty ? grn.supplierInvoiceNo : 'N/A', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
        if (grn.invoiceDocumentUrl != null && grn.invoiceDocumentUrl!.isNotEmpty) ...[
          const SizedBox(height: 3),
          InkWell(
            onTap: () => _openInvoiceDocument(context, grn.invoiceDocumentUrl!),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.attachment_rounded, size: 12, color: Color(0xFF3B82F6)),
                SizedBox(width: 2),
                Text('Scan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6), decoration: TextDecoration.underline)),
              ],
            ),
          ),
        ],
      ],
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
