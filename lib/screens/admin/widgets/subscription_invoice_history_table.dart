import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/api_constants.dart';
import '../models/subscription_plan_models.dart';

class SubscriptionInvoiceHistoryTable extends StatelessWidget {
  final List<SubscriptionInvoiceItem> invoices;
  final bool isDark;
  final Color borderColor;
  final Color textColor;
  final Color subtitleColor;
  final String? branchName;

  const SubscriptionInvoiceHistoryTable({
    super.key,
    required this.invoices,
    required this.isDark,
    required this.borderColor,
    required this.textColor,
    required this.subtitleColor,
    this.branchName,
  });

  Future<void> _openInvoiceView(SubscriptionInvoiceItem inv) async {
    final uri = Uri.parse(inv.getViewUrl(ApiConstants.baseUrl));
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openInvoicePdf(SubscriptionInvoiceItem inv) async {
    final uri = Uri.parse(inv.getPdfUrl(ApiConstants.baseUrl));
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 14, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF6366F1), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        branchName != null && branchName!.isNotEmpty
                            ? 'Subscription & Tax Invoices • $branchName'
                            : 'Subscription & Tax Invoices',
                        style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: textColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                child: const Text('18% GST Compliant', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (invoices.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 36, color: subtitleColor.withValues(alpha: 0.4)),
                  const SizedBox(height: 8),
                  Text(
                    branchName != null && branchName!.isNotEmpty
                        ? 'No Invoices for "$branchName"'
                        : 'No Invoices Recorded Yet',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 3),
                  Text('GST tax invoices will appear here automatically upon branch license renewal.', style: TextStyle(fontSize: 11.5, color: subtitleColor)),
                ],
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 38,
                dataRowMinHeight: 44,
                dataRowMaxHeight: 50,
                columnSpacing: 22,
                columns: ['Invoice #', 'Date', 'Plan & Cycle', 'Amount', 'Payment Ref', 'Status', 'Tax Invoice']
                    .map((h) => DataColumn(label: Text(h, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))))
                    .toList(),
                rows: invoices.map((inv) => DataRow(
                  onSelectChanged: (_) => _openInvoiceView(inv),
                  cells: [
                    DataCell(InkWell(
                      onTap: () => _openInvoiceView(inv),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.open_in_new_rounded, size: 12, color: Color(0xFF3395FF)),
                        const SizedBox(width: 4),
                        Text(inv.invoiceId, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF3395FF), decoration: TextDecoration.underline)),
                      ]),
                    )),
                    DataCell(Text(inv.date.split("T")[0], style: const TextStyle(fontSize: 12))),
                    DataCell(Text(inv.planName, style: const TextStyle(fontSize: 12))),
                    DataCell(Text('₹${inv.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataCell(Text(inv.paymentReference?.isNotEmpty == true ? inv.paymentReference! : inv.paymentMethod, style: const TextStyle(fontSize: 11, fontFamily: 'monospace'))),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                      child: Text(inv.status, style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
                    )),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.visibility_rounded, size: 12),
                          label: const Text('View', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF10B981),
                            side: const BorderSide(color: Color(0xFF10B981)),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: () => _openInvoiceView(inv),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF3395FF)),
                          tooltip: 'Download Vector PDF',
                          onPressed: () => _openInvoicePdf(inv),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    )),
                  ],
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
