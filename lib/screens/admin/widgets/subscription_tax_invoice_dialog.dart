import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/api_constants.dart';
import '../models/subscription_plan_models.dart';

class SubscriptionTaxInvoiceDialog extends StatelessWidget {
  final SubscriptionInvoiceItem invoice;
  final String? restaurantName;

  const SubscriptionTaxInvoiceDialog({
    super.key,
    required this.invoice,
    this.restaurantName,
  });

  static Future<void> show(
    BuildContext context, {
    required SubscriptionInvoiceItem invoice,
    String? restaurantName,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => SubscriptionTaxInvoiceDialog(
        invoice: invoice,
        restaurantName: restaurantName,
      ),
    );
  }

  Future<void> _printOrDownloadPdf(BuildContext context) async {
    try {
      final doc = pw.Document();
      final baseAmount = (invoice.amount / 1.18);
      final gstAmount = invoice.amount - baseAmount;
      final halfGst = gstAmount / 2;

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('SirfBill Restaurant | Powered By Naiyo24 Private Limited', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 3),
                        pw.Text('CIN: U73100WB2024PTC271832  |  GSTIN: 19AATCM4745N1ZH (West Bengal)', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                        pw.Text('1/30B, Chittaranjan Colony, Baghajatin Colony, Kolkata - 700032', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        pw.Text('Authorized Contact: Debasish Baidya (+91 6289171798)  |  SAC: 998313', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.green50,
                        border: pw.Border.all(color: PdfColors.green700),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Text('ORIGINAL FOR RECIPIENT\nTAX INVOICE', textAlign: pw.TextAlign.center, style: pw.TextStyle(color: PdfColors.green800, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                pw.Divider(thickness: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 12),

                // Invoice Meta
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Invoice No: ${invoice.invoiceId}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                        pw.Text('Invoice Date: ${invoice.date}', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('Payment Reference: ${invoice.paymentReference ?? "N/A"}', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('Gateway: Razorpay (Live Verified)', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Billed To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        pw.Text(restaurantName ?? 'SirfBill Restaurant Partner', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                        pw.Text('Status: ACTIVE / PAID', style: pw.TextStyle(color: PdfColors.green700, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('SAC', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Taxable Value', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('CGST 9%', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('SGST 9%', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Total (INR)', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${invoice.planName}\n(30 Days Restaurant Pro License)', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('998313', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('INR ${baseAmount.toStringAsFixed(2)}', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('INR ${halfGst.toStringAsFixed(2)}', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('INR ${halfGst.toStringAsFixed(2)}', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('INR ${invoice.amount.toStringAsFixed(2)}', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Total Summary
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Container(
                    width: 220,
                    child: pw.Column(
                      children: [
                        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                          pw.Text('Subtotal (Base):', style: const pw.TextStyle(fontSize: 10)),
                          pw.Text('INR ${baseAmount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                        ]),
                        pw.SizedBox(height: 4),
                        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                          pw.Text('Total GST (18% ITC):', style: const pw.TextStyle(fontSize: 10)),
                          pw.Text('INR ${gstAmount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                        ]),
                        pw.Divider(thickness: 1, color: PdfColors.grey300),
                        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                          pw.Text('Total Paid:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                          pw.Text('INR ${invoice.amount.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.green800)),
                        ]),
                      ],
                    ),
                  ),
                ),
                pw.Spacer(),
                pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                pw.Text('This is a computer-generated tax invoice. No signature is required. Thank you for choosing SirfBill.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        name: 'Invoice_${invoice.invoiceId}',
        onLayout: (format) async => doc.save(),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseAmount = (invoice.amount / 1.18);
    final gstAmount = invoice.amount - baseAmount;
    final halfGst = gstAmount / 2;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 36, offset: Offset(0, 12))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                color: const Color(0xFF0C2340),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text('Official Tax Invoice', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              SizedBox(width: 8),
                              Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 16),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('18% GST Compliant · ${invoice.invoiceId}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Invoice Body
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('SirfBill Restaurant | Powered by Naiyo24 Private Limited', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A))),
                            const SizedBox(height: 2),
                            const Text('CIN: U73100WB2024PTC271832 · GSTIN: 19AATCM4745N1ZH (WB)', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                            const SizedBox(height: 1),
                            const Text('1/30B, Chittaranjan Colony, Baghajatin Colony, Kolkata - 700032', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                            const SizedBox(height: 1),
                            const Text('Authorized Signatory: Debasish Baidya (+91 6289171798)', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text('Date: ${invoice.date}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
                              SizedBox(width: 5),
                              Text('PAID / ACTIVE', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Meta box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Payment Reference (UTR / ID)', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(invoice.paymentReference ?? 'N/A', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: Color(0xFF0F172A))),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Gateway', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(invoice.paymentMethod.isNotEmpty ? invoice.paymentMethod : 'RAZORPAY', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3395FF))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Line Items
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          Container(
                            color: const Color(0xFFF1F5F9),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: const Row(
                              children: [
                                Expanded(flex: 3, child: Text('Item & License', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                Expanded(flex: 1, child: Text('SAC', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('Amount (INR)', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(invoice.planName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                      const Text('Unlimited Touch POS, Recipe BOM, KDS & Audits', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                    ],
                                  ),
                                ),
                                const Expanded(flex: 1, child: Text('998313', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Color(0xFF64748B)))),
                                Expanded(flex: 2, child: Text('₹${baseAmount.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Tax breakdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 240,
                          child: Column(
                            children: [
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                const Text('Taxable Base:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                Text('₹${baseAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              ]),
                              const SizedBox(height: 4),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                const Text('CGST (9%):', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                Text('₹${halfGst.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              ]),
                              const SizedBox(height: 4),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                const Text('SGST (9%):', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                Text('₹${halfGst.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              ]),
                              const Divider(height: 16),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                const Text('Total Paid:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                                Text('₹${invoice.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bottom Actions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close', style: TextStyle(color: Color(0xFF64748B))),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            final url = invoice.getViewUrl(ApiConstants.baseUrl);
                            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                          },
                          icon: const Icon(Icons.open_in_new_rounded, size: 14),
                          label: const Text('Open Official Web View', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF3395FF),
                            side: const BorderSide(color: Color(0xFF3395FF)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _printOrDownloadPdf(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.print_rounded, size: 15),
                          label: const Text('Print / Save PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
