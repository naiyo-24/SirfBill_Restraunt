import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../services/shop_service.dart';
import '../models/inventory_ops_models.dart';
import '../services/procurement_api_service.dart';

class PurchaseOrderPdfHelper {
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  static Future<Map<String, String>> loadActiveProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('assigned_outlet_id') ?? prefs.getString('selected_shop_id');
      final savedName = prefs.getString('assigned_outlet_name');

      final shops = await ShopService.getShops();
      if (shops.isNotEmpty) {
        final match = shops.firstWhere(
          (s) => s.id == savedId,
          orElse: () => shops.first,
        );
        final addr = [match.location, match.city].where((s) => s.trim().isNotEmpty).join(', ');
        return {
          'name': match.name,
          'address': addr,
          'phone': match.contact,
          'gstin': match.gstin ?? '',
        };
      }
      if (savedName != null && savedName.trim().isNotEmpty) {
        return {'name': savedName.trim(), 'address': '', 'phone': '', 'gstin': ''};
      }
    } catch (_) {}
    return {'name': 'Restaurant Procurement', 'address': '', 'phone': '', 'gstin': ''};
  }

  static Future<Uint8List> generatePoPdf(
    PurchaseOrder po, {
    String? restaurantName,
    String? restaurantAddress,
    String? restaurantPhone,
    String? restaurantGstin,
  }) async {
    PurchaseOrder targetPo = po;
    if (targetPo.items.isEmpty && targetPo.id.isNotEmpty) {
      final full = await ProcurementApiService.getPurchaseOrderById(targetPo.id);
      if (full != null && full.items.isNotEmpty) {
        targetPo = full;
      }
    }

    final poName = targetPo.outletName.trim();
    final poAddrParts = [targetPo.outletAddress.trim(), targetPo.outletCity.trim()].where((s) => s.isNotEmpty).toList();
    final poAddress = poAddrParts.join(', ');
    final poPhone = targetPo.outletPhone.trim();
    final poGstin = targetPo.outletGstin.trim();

    Map<String, String> profile = {};
    if (restaurantName == null && (poName.isEmpty || poAddress.isEmpty)) {
      profile = await loadActiveProfile();
    }

    final effectiveName = (restaurantName != null && restaurantName.trim().isNotEmpty)
        ? restaurantName.trim()
        : (poName.isNotEmpty ? poName : (profile['name'] ?? 'Restaurant Procurement'));

    final effectiveAddress = (restaurantAddress != null && restaurantAddress.trim().isNotEmpty)
        ? restaurantAddress.trim()
        : (poAddress.isNotEmpty ? poAddress : (profile['address'] ?? ''));

    final effectivePhone = (restaurantPhone != null && restaurantPhone.trim().isNotEmpty)
        ? restaurantPhone.trim()
        : (poPhone.isNotEmpty ? poPhone : (profile['phone'] ?? ''));

    final effectiveGstin = (restaurantGstin != null && restaurantGstin.trim().isNotEmpty)
        ? restaurantGstin.trim()
        : (poGstin.isNotEmpty ? poGstin : (profile['gstin'] ?? ''));

    final pdf = pw.Document();

    final emeraldPrimary = PdfColor.fromHex('#10B981');
    final darkHeader = PdfColor.fromHex('#0F172A');
    final slateMuted = PdfColor.fromHex('#64748B');
    final lightBg = PdfColor.fromHex('#F8FAFC');
    final borderGray = PdfColor.fromHex('#E2E8F0');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. TOP HEADER (Dynamic Restaurant Profile)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          effectiveName,
                          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: darkHeader),
                        ),
                        if (effectiveAddress.isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          pw.Text(
                            effectiveAddress,
                            style: pw.TextStyle(fontSize: 10, color: slateMuted),
                          ),
                        ],
                        if (effectivePhone.isNotEmpty || effectiveGstin.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            [
                              if (effectivePhone.isNotEmpty) 'Phone: $effectivePhone',
                              if (effectiveGstin.isNotEmpty) 'GSTIN: $effectiveGstin',
                            ].join('  |  '),
                            style: pw.TextStyle(fontSize: 9, color: slateMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: pw.BoxDecoration(
                          color: emeraldPrimary,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                        ),
                        child: pw.Text(
                          'PURCHASE ORDER',
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        targetPo.poNumber,
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: darkHeader),
                      ),
                      pw.Text(
                        'Status: ${targetPo.status.label.toUpperCase()}',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: emeraldPrimary),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 18),
              pw.Divider(color: borderGray, thickness: 1),
              pw.SizedBox(height: 14),

              // 2. VENDOR & DELIVERY DUAL CARDS
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: lightBg,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                        border: pw.Border.all(color: borderGray),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'VENDOR / SUPPLIER',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: emeraldPrimary),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            targetPo.supplierName,
                            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkHeader),
                          ),
                          if (targetPo.supplierPhone.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text('Phone: ${targetPo.supplierPhone}', style: pw.TextStyle(fontSize: 9, color: slateMuted)),
                          ],
                          if (targetPo.supplierEmail.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text('Email: ${targetPo.supplierEmail}', style: pw.TextStyle(fontSize: 9, color: slateMuted)),
                          ],
                          if (targetPo.supplierAddress.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text('Address: ${targetPo.supplierAddress}', style: pw.TextStyle(fontSize: 9, color: slateMuted)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 14),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: lightBg,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                        border: pw.Border.all(color: borderGray),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'ORDER & DISPATCH TIMELINE',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: emeraldPrimary),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Order Date:', style: pw.TextStyle(fontSize: 9, color: slateMuted)),
                              pw.Text(_dateFormat.format(targetPo.orderDate), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                          pw.SizedBox(height: 3),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Expected Delivery:', style: pw.TextStyle(fontSize: 9, color: slateMuted)),
                              pw.Text(_dateFormat.format(targetPo.expectedDeliveryDate), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: darkHeader)),
                            ],
                          ),
                          if (targetPo.notes.isNotEmpty) ...[
                            pw.SizedBox(height: 4),
                            pw.Text('Instructions: ${targetPo.notes}', style: pw.TextStyle(fontSize: 8.5, fontStyle: pw.FontStyle.italic, color: slateMuted)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 18),

              // 3. COMMODITY LINE ITEMS TABLE
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderGray),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Table(
                  border: pw.TableBorder(horizontalInside: pw.BorderSide(color: borderGray, width: 0.5)),
                  columnWidths: const {
                    0: pw.FixedColumnWidth(28),
                    1: pw.FlexColumnWidth(5),
                    2: pw.FlexColumnWidth(2),
                    3: pw.FlexColumnWidth(2),
                    4: pw.FlexColumnWidth(2),
                    5: pw.FlexColumnWidth(2.5),
                  },
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: lightBg),
                      children: [
                        _tableCell('#', isHeader: true, align: pw.TextAlign.center),
                        _tableCell('ITEM / INGREDIENT', isHeader: true),
                        _tableCell('QTY', isHeader: true, align: pw.TextAlign.center),
                        _tableCell('EST. PRICE', isHeader: true, align: pw.TextAlign.right),
                        _tableCell('UNIT', isHeader: true, align: pw.TextAlign.center),
                        _tableCell('TOTAL (INR)', isHeader: true, align: pw.TextAlign.right),
                      ],
                    ),
                    // Rows
                    ...targetPo.items.asMap().entries.map((entry) {
                      final idx = entry.key + 1;
                      final it = entry.value;
                      return pw.TableRow(
                        children: [
                          _tableCell('$idx', align: pw.TextAlign.center),
                          _tableCell(it.ingredientName),
                          _tableCell(it.orderedQty.toStringAsFixed(1), align: pw.TextAlign.center),
                          _tableCell('INR ${it.unitPrice.toStringAsFixed(2)}', align: pw.TextAlign.right),
                          _tableCell(it.uom, align: pw.TextAlign.center),
                          _tableCell('INR ${(it.orderedQty * it.unitPrice).toStringAsFixed(2)}', align: pw.TextAlign.right, isBold: true),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // 4. SUMMARY BOX
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 240,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: lightBg,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      border: pw.Border.all(color: borderGray),
                    ),
                    child: pw.Column(
                      children: [
                        _summaryRow('Total Items:', '${targetPo.items.length} commodities'),
                        pw.SizedBox(height: 4),
                        _summaryRow('PO Base Subtotal:', 'INR ${targetPo.subtotal.toStringAsFixed(2)}'),
                        pw.SizedBox(height: 4),
                        _summaryRow('Invoice Tax / GST:', 'Settled on GRN'),
                        pw.Divider(color: borderGray, thickness: 0.5),
                        _summaryRow('PO ESTIMATED TOTAL:', 'INR ${targetPo.totalAmount.toStringAsFixed(2)}', isTotal: true, color: emeraldPrimary),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),

              // 5. SIGNATORY & FOOTER
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(width: 150, height: 1, color: slateMuted),
                      pw.SizedBox(height: 4),
                      pw.Text('Authorized Kitchen Manager', style: pw.TextStyle(fontSize: 8.5, color: slateMuted)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(width: 150, height: 1, color: slateMuted),
                      pw.SizedBox(height: 4),
                      pw.Text('Vendor Signature / Stamp', style: pw.TextStyle(fontSize: 8.5, color: slateMuted)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Center(
                child: pw.Text(
                  'Computer-generated Purchase Requisition Document | SirfBill Restaurant POS',
                  style: pw.TextStyle(fontSize: 8, color: slateMuted),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _tableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 8.5 : 9,
          fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _summaryRow(String label, String value, {bool isTotal = false, PdfColor? color}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: isTotal ? 9.5 : 8.5,
            fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: isTotal ? 11 : 8.5,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Returns binary PDF bytes directly from backend Weasyprint HTML template with local fallback
  static Future<Uint8List> getPdfBytes(
    PurchaseOrder po, {
    String? restaurantName,
    String? restaurantAddress,
  }) async {
    PurchaseOrder targetPo = po;
    if (targetPo.id.isNotEmpty) {
      final backendPdf = await ProcurementApiService.fetchPurchaseOrderPdf(targetPo.id);
      if (backendPdf != null && backendPdf.isNotEmpty) {
        return backendPdf;
      }
    }
    return generatePoPdf(
      targetPo,
      restaurantName: restaurantName,
      restaurantAddress: restaurantAddress,
    );
  }

  static Future<void> printOrDownloadPo(
    BuildContext context,
    PurchaseOrder po, {
    String? restaurantName,
    String? restaurantAddress,
  }) async {
    final pdfBytes = await getPdfBytes(
      po,
      restaurantName: restaurantName,
      restaurantAddress: restaurantAddress,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: '${po.poNumber}.pdf',
    );
  }

  static Future<void> sharePo(
    PurchaseOrder po, {
    String? restaurantName,
    String? restaurantAddress,
  }) async {
    final pdfBytes = await getPdfBytes(
      po,
      restaurantName: restaurantName,
      restaurantAddress: restaurantAddress,
    );

    await Printing.sharePdf(bytes: pdfBytes, filename: '${po.poNumber}.pdf');
  }

  /// Opens the backend Jinja2 HTML print template directly in browser view
  static Future<bool> openBackendPrintView(String poId, {bool autoprint = true}) async {
    try {
      final url = ProcurementApiService.getPurchaseOrderPrintUrl(poId, autoprint: autoprint);
      final uri = Uri.parse(url);
      return await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (e) {
      debugPrint('[PurchaseOrderPdfHelper] openBackendPrintView error: $e');
      return false;
    }
  }
}
