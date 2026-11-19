import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../config/api_client.dart';
import '../../config/api_constants.dart';
import '../../models/restaurant_pos_models.dart';
import 'thermal_logo_enhancer.dart';

class CombinedBillPdfGenerator {
  /// Generates a single combined 72mm PDF containing Page 1 (KOT for Kitchen) and Page 2 (Final Customer Bill).
  /// Sized specifically with 72mm width and 2.5mm margins to prevent clipping/cutting on 80mm thermal printers.
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
  }) async {
    final pdf = pw.Document();

    // Resolve & Enhance Logo Image for Monochrome Thermal Bill
    pw.ImageProvider? billLogo;
    if (logoBytes != null) {
      final enhancedBytes = ThermalLogoEnhancer.enhanceForThermal(logoBytes);
      billLogo = pw.MemoryImage(enhancedBytes);
    } else if (logoUrl != null && logoUrl.trim().isNotEmpty) {
      try {
        final fullLogoUrl = logoUrl.startsWith('http')
            ? logoUrl
            : '${ApiConstants.baseUrl}${logoUrl.startsWith('/') ? '' : '/'}$logoUrl';
        final res = await ApiClient().dio.get(
          fullLogoUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        if (res.statusCode == 200 && res.data != null) {
          final rawBytes = Uint8List.fromList(res.data);
          final enhancedBytes = ThermalLogoEnhancer.enhanceForThermal(rawBytes);
          billLogo = pw.MemoryImage(enhancedBytes);
        }
      } catch (_) {}
    }
    final time = (timestamp ?? DateTime.now()).toLocal();
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    final formattedTime =
        '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $amPm - ${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}';

    // 1. Consolidate identical items
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

    final kotHeightMm = (85.0 + (consolidatedItems.length * 9.0)).clamp(100.0, 300.0);
    // 72mm width with 2.5mm margins to prevent cutting on right edge
    final kotPageFormat = PdfPageFormat(72 * PdfPageFormat.mm, kotHeightMm * PdfPageFormat.mm, marginAll: 2.5 * PdfPageFormat.mm);

    // PAGE 1: KITCHEN ORDER TICKET (KOT)
    pdf.addPage(
      pw.Page(
        pageFormat: kotPageFormat,
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
                  pw.Text('Type: ${orderType.toUpperCase()}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
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
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text(
                  '--- KITCHEN COPY ---',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                ),
              ),
            ],
          );
        },
      ),
    );

    // PAGE 2: TAX INVOICE / OFFICIAL CUSTOMER BILL
    final double cgstVal = tax > 0 ? (tax / 2) : 0.0;
    final double sgstVal = tax > 0 ? (tax / 2) : 0.0;
    final int totalBillQty = consolidatedItems.fold<int>(0, (sum, ci) => sum + ci.quantity);
    final double rawTotal = subtotal - discount + tax;
    final double roundOffVal = (grandTotal - rawTotal).abs() < 0.005 ? 0.0 : (grandTotal - rawTotal);
    final String roundOffStr = roundOffVal == 0.0
        ? 'Rs. 0.00'
        : (roundOffVal > 0 ? '+Rs. ${roundOffVal.toStringAsFixed(2)}' : '-Rs. ${(-roundOffVal).toStringAsFixed(2)}');
    final billHeightMm = (160.0 + (consolidatedItems.length * 8.5) + (upiId.isNotEmpty ? 35.0 : 0.0)).clamp(175.0, 420.0);
    // 72mm width with 2.5mm margins to prevent cutting on right edge
    final billPageFormat = PdfPageFormat(72 * PdfPageFormat.mm, billHeightMm * PdfPageFormat.mm, marginAll: 2.5 * PdfPageFormat.mm);

    pdf.addPage(
      pw.Page(
        pageFormat: billPageFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (billLogo != null) ...[
                pw.Container(
                  width: 140,
                  height: 65,
                  margin: const pw.EdgeInsets.only(bottom: 3),
                  child: pw.Image(billLogo, fit: pw.BoxFit.contain),
                ),
              ],

              // 1. Outlet Name
              pw.Text(
                shopName.toUpperCase(),
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              if (address.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  address,
                  style: const pw.TextStyle(fontSize: 7.5),
                  textAlign: pw.TextAlign.center,
                ),
              ],
              if (phone.isNotEmpty) ...[
                pw.SizedBox(height: 1),
                pw.Text(
                  'Tel: $phone',
                  style: const pw.TextStyle(fontSize: 7.5),
                  textAlign: pw.TextAlign.center,
                ),
              ],
              if (shopGstNo.isNotEmpty) ...[
                pw.SizedBox(height: 1),
                pw.Text(
                  'GSTIN: $shopGstNo',
                  style: const pw.TextStyle(fontSize: 7.5),
                  textAlign: pw.TextAlign.center,
                ),
              ],
              if (fssaiNo.isNotEmpty) ...[
                pw.SizedBox(height: 1),
                pw.Text(
                  'FSSAI: $fssaiNo',
                  style: const pw.TextStyle(fontSize: 7.5),
                  textAlign: pw.TextAlign.center,
                ),
              ],
              pw.SizedBox(height: 3),
              pw.Divider(thickness: 0.8),
              pw.Center(
                child: pw.Text(
                  'TAX INVOICE',
                  style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Divider(thickness: 0.8),
              pw.SizedBox(height: 2),

              // Metadata Block
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Bill No: $orderNumber', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    tableLabel != null && tableLabel.isNotEmpty
                        ? 'Table: $tableLabel'
                        : (orderType.toUpperCase() == 'DINE_IN' ? 'Table: Dine-in' : 'Table: Takeaway'),
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 1.5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Type: ${orderType.toUpperCase()}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Date: $formattedTime', style: const pw.TextStyle(fontSize: 7.5)),
                ],
              ),
              if (customerName != null && customerName.isNotEmpty && customerName != 'Walk-in') ...[
                pw.SizedBox(height: 1.5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Customer: $customerName', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                    if (customerPhone != null && customerPhone.isNotEmpty)
                      pw.Text('Phone: $customerPhone', style: const pw.TextStyle(fontSize: 7.5)),
                  ],
                ),
              ],
              pw.SizedBox(height: 3),
              pw.Divider(thickness: 0.8),

              // Items table
              pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(5.0),
                  1: const pw.FlexColumnWidth(1.6),
                  2: const pw.FlexColumnWidth(2.3),
                  3: const pw.FlexColumnWidth(2.5),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text('ITEM', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                      pw.Text('QTY', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                      pw.Text('RATE', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                      pw.Text('TOTAL', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  ...consolidatedItems.map((ci) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                          child: pw.Text(ci.item.name, style: const pw.TextStyle(fontSize: 7.5)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                          child: pw.Text('${ci.quantity}', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7.5)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                          child: pw.Text(ci.item.price.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 7.5)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                          child: pw.Text(ci.totalPrice.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 7.5)),
                        ),
                      ],
                    );
                  }),
                ],
              ),

              pw.Divider(thickness: 0.8),
              pw.SizedBox(height: 2),

              // Summary Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Qty:', style: const pw.TextStyle(fontSize: 7.5)),
                  pw.Text('$totalBillQty', style: const pw.TextStyle(fontSize: 7.5)),
                ],
              ),
              pw.SizedBox(height: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 7.5)),
                  pw.Text('Rs. ${subtotal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 7.5)),
                ],
              ),
              if (discount > 0) ...[
                pw.SizedBox(height: 1),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Discount:', style: const pw.TextStyle(fontSize: 7.5)),
                    pw.Text('-Rs. ${discount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 7.5)),
                  ],
                ),
              ],
              if (tax > 0) ...[
                pw.SizedBox(height: 1),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('CGST (2.5%):', style: const pw.TextStyle(fontSize: 7.5)),
                    pw.Text('Rs. ${cgstVal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 7.5)),
                  ],
                ),
                pw.SizedBox(height: 1),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('SGST (2.5%):', style: const pw.TextStyle(fontSize: 7.5)),
                    pw.Text('Rs. ${sgstVal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 7.5)),
                  ],
                ),
              ],
              pw.SizedBox(height: 2),
              pw.Divider(thickness: 1.0),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Round Off:', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(roundOffStr, style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.SizedBox(height: 1.5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL INVOICE BILL:', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Rs. ${grandTotal.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Divider(thickness: 1.0),
              pw.SizedBox(height: 5),

              // Footer matching official receipt
              pw.Text(
                'THANK YOU FOR DINING\nWITH US!',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 1),
              pw.Text(
                'Please visit again',
                style: const pw.TextStyle(fontSize: 7),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Sirfbill',
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 1),
              pw.Text(
                'Powered By Naiyo24 Pvt. Ltd.',
                style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 25), // Space in the bottom before thermal cutter cut
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
