import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../config/api_client.dart';
import '../../config/api_constants.dart';
import '../../models/restaurant_pos_models.dart';

/// Handles generation of official customer tax invoice PDF (72mm thermal)
class RestaurantBillPdfGenerator {
  /// Generates a single standalone 72mm PDF for the Customer Tax Invoice.
  static Future<Uint8List> generateBillPdf({
    required String orderNumber,
    required String orderType,
    String? tableLabel,
    String? customerName,
    String? customerPhone,
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

    // Resolve Logo Image for Bill
    pw.ImageProvider? billLogo;
    if (logoBytes != null) {
      billLogo = pw.MemoryImage(logoBytes);
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
          billLogo = pw.MemoryImage(Uint8List.fromList(res.data));
        }
      } catch (_) {}
    }

    final time = (timestamp ?? DateTime.now()).toLocal();
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    final formattedTime =
        '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $amPm - ${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}';

    // Consolidate identical items
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

    final double cgstVal = tax > 0 ? (tax / 2) : 0.0;
    final double sgstVal = tax > 0 ? (tax / 2) : 0.0;
    final int totalBillQty = consolidatedItems.fold<int>(0, (sum, ci) => sum + ci.quantity);
    final billHeightMm = (135.0 + (consolidatedItems.length * 8.5) + (upiId.isNotEmpty ? 35.0 : 0.0)).clamp(150.0, 390.0);
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
                  width: 44,
                  height: 44,
                  margin: const pw.EdgeInsets.only(bottom: 3),
                  child: pw.Image(billLogo, fit: pw.BoxFit.contain),
                ),
              ],
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
                  pw.Text('GRAND TOTAL:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Rs. ${grandTotal.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('PAID AMOUNT:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Rs. ${grandTotal.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Divider(thickness: 1.0),
              pw.SizedBox(height: 5),

              // Footer
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
                style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'Powered By Naiyo24 Pvt. Ltd.',
                style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 3),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
