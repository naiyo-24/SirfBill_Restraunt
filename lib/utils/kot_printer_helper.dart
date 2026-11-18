import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/restaurant_pos_models.dart';

import 'combined_bill_pdf_generator.dart';

class KotPrinterHelper {
  /// Generates clean 72mm thermal receipt bytes for Kitchen Order Ticket (prevents right side cutting)
  static Future<Uint8List> generateKotPdf({
    required String kotNumber,
    required String orderNumber,
    required String orderType,
    String? tableLabel,
    String? floor,
    String? customerName,
    String? orderNotes,
    required List<PosCartItem> items,
    DateTime? timestamp,
  }) async {
    final pdf = pw.Document();
    final time = (timestamp ?? DateTime.now()).toLocal();
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    final formattedTime =
        '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $amPm - ${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}';

    // Consolidate identical items in the KOT
    final List<PosCartItem> consolidatedItems = [];
    for (final it in items) {
      final idx = consolidatedItems.indexWhere((c) =>
          c.item.name == it.item.name && (c.notes ?? '') == (it.notes ?? ''));
      if (idx >= 0) {
        consolidatedItems[idx] = consolidatedItems[idx].copyWith(
          quantity: consolidatedItems[idx].quantity + it.quantity,
        );
      } else {
        consolidatedItems.add(it);
      }
    }

    // Calculate dynamic height based on content to avoid massive empty paper roll
    // 72mm width with 2.5mm margins to fit inside 80mm printable width and prevent right margin clipping
    final calculatedHeightMm = (85.0 + (consolidatedItems.length * 9.0)).clamp(100.0, 300.0);
    final pageFormat = PdfPageFormat(72 * PdfPageFormat.mm, calculatedHeightMm * PdfPageFormat.mm, marginAll: 2.5 * PdfPageFormat.mm);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  '*** KITCHEN ORDER TICKET ***',
                  style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Center(
                child: pw.Text(
                  kotNumber,
                  style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Order: $orderNumber [${orderType.toUpperCase()}]',
                  style: const pw.TextStyle(fontSize: 9.5),
                ),
              ),
              if (tableLabel != null && tableLabel.isNotEmpty) ...[
                pw.SizedBox(height: 3),
                pw.Center(
                  child: pw.Text(
                    'TABLE: $tableLabel ${floor != null ? "($floor)" : ""}',
                    style: pw.TextStyle(fontSize: 12.5, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Time: $formattedTime', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('Server: POS', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              if (customerName != null && customerName.isNotEmpty)
                pw.Text('Guest: $customerName', style: const pw.TextStyle(fontSize: 8)),
              if (orderNotes != null && orderNotes.isNotEmpty)
                pw.Text('Note: $orderNotes', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 4),

              // Items table
              pw.Row(
                children: [
                  pw.Expanded(flex: 2, child: pw.Text('QTY', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 8, child: pw.Text('ITEM DESCRIPTION', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold))),
                ],
              ),
              pw.SizedBox(height: 3),
              ...consolidatedItems.map((it) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              '${it.quantity}x',
                              style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Expanded(
                            flex: 8,
                            child: pw.Text(
                              it.item.name,
                              style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      if (it.notes != null && it.notes!.isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 14),
                          child: pw.Text(
                            '** ${it.notes} **',
                            style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic),
                          ),
                        ),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 5),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.Center(
                child: pw.Text(
                  'Total Items: ${consolidatedItems.fold<int>(0, (sum, i) => sum + i.quantity)}',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 6),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Direct System Print Dialog using browser/native print manager
  static Future<void> printKotDirectly({
    required BuildContext context,
    required String kotNumber,
    required String orderNumber,
    required String orderType,
    String? tableLabel,
    String? floor,
    String? customerName,
    String? orderNotes,
    required List<PosCartItem> items,
    DateTime? timestamp,
  }) async {
    final pdfBytes = await generateKotPdf(
      kotNumber: kotNumber,
      orderNumber: orderNumber,
      orderType: orderType,
      tableLabel: tableLabel,
      floor: floor,
      customerName: customerName,
      orderNotes: orderNotes,
      items: items,
      timestamp: timestamp,
    );

    final heightMm = (85.0 + (items.length * 9.0)).clamp(100.0, 300.0);
    final thermal72mm = PdfPageFormat(72 * PdfPageFormat.mm, heightMm * PdfPageFormat.mm, marginAll: 2.5 * PdfPageFormat.mm);

    await Printing.layoutPdf(
      name: 'KOT_${orderNumber.replaceAll("#", "")}',
      format: thermal72mm,
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
  }

  /// Delegates to CombinedBillPdfGenerator so this file stays cleanly under 500 lines!
  static Future<Uint8List> generateCombinedTakeawayPdf({
    required String kotNumber,
    required String orderNumber,
    required String orderType,
    String? tableLabel,
    String? floor,
    String? customerName,
    String? customerPhone,
    String? orderNotes,
    required List<PosCartItem> items,
    required double subtotal,
    required double discount,
    required double tax,
    required double grandTotal,
    required String shopName,
    required String address,
    required String phone,
    required String shopGstNo,
    String fssaiNo = '',
    String upiId = '',
    String? logoUrl,
    Uint8List? logoBytes,
    DateTime? timestamp,
  }) {
    return CombinedBillPdfGenerator.generateCombinedTakeawayPdf(
      kotNumber: kotNumber,
      orderNumber: orderNumber,
      orderType: orderType,
      tableLabel: tableLabel,
      floor: floor,
      customerName: customerName,
      customerPhone: customerPhone,
      orderNotes: orderNotes,
      items: items,
      subtotal: subtotal,
      discount: discount,
      tax: tax,
      grandTotal: grandTotal,
      shopName: shopName,
      address: address,
      phone: phone,
      shopGstNo: shopGstNo,
      fssaiNo: fssaiNo,
      upiId: upiId,
      logoUrl: logoUrl,
      logoBytes: logoBytes,
      timestamp: timestamp,
    );
  }
}
