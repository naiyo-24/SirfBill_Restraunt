import 'package:flutter/material.dart';

class GrnItemInput {
  final String ingredientId;
  final String ingredientName;
  final String? poItemId;
  final double orderedQty;
  final String unit;

  final TextEditingController receivedQtyController;
  final TextEditingController rejectedQtyController = TextEditingController(text: '0');
  final TextEditingController unitPriceController;
  final TextEditingController batchController = TextEditingController();
  final TextEditingController rejectionReasonController = TextEditingController();

  DateTime? expiryDate;
  double taxRate = 0.0; // GST %: 0%, 5%, 12%, 18%, 28%

  GrnItemInput({
    required this.ingredientId,
    required this.ingredientName,
    this.poItemId,
    required this.orderedQty,
    required this.unit,
    double initialUnitPrice = 0.0,
    this.expiryDate,
  })  : receivedQtyController = TextEditingController(
          text: orderedQty > 0
              ? (orderedQty == orderedQty.roundToDouble()
                  ? orderedQty.toInt().toString()
                  : orderedQty.toStringAsFixed(1))
              : '1.0',
        ),
        unitPriceController = TextEditingController(
          text: initialUnitPrice > 0
              ? (initialUnitPrice == initialUnitPrice.roundToDouble()
                  ? initialUnitPrice.toInt().toString()
                  : (initialUnitPrice < 0.01
                      ? initialUnitPrice.toStringAsFixed(4)
                      : initialUnitPrice.toStringAsFixed(2)))
              : '0',
        );

  double get quantityReceived => double.tryParse(receivedQtyController.text) ?? 0.0;
  double get quantityRejected => double.tryParse(rejectedQtyController.text) ?? 0.0;
  double get unitPrice => double.tryParse(unitPriceController.text) ?? 0.0;

  double get subtotal => quantityReceived * unitPrice;
  double get taxAmount => subtotal * (taxRate / 100.0);
  double get totalPrice => subtotal + taxAmount;

  void dispose() {
    receivedQtyController.dispose();
    rejectedQtyController.dispose();
    unitPriceController.dispose();
    batchController.dispose();
    rejectionReasonController.dispose();
  }
}

class GrnItemRecord {
  final String id;
  final String grnId;
  final String ingredientId;
  final String ingredientName;
  final String? poItemId;
  final double quantityReceived;
  final double quantityRejected;
  final String? rejectionReason;
  final String unit;
  final double unitPrice;
  final double taxRate;
  final double taxAmount;
  final double totalPrice;
  final String? batchNumber;
  final DateTime? expiryDate;

  const GrnItemRecord({
    required this.id,
    this.grnId = '',
    required this.ingredientId,
    required this.ingredientName,
    this.poItemId,
    required this.quantityReceived,
    this.quantityRejected = 0.0,
    this.rejectionReason,
    required this.unit,
    required this.unitPrice,
    this.taxRate = 0.0,
    this.taxAmount = 0.0,
    required this.totalPrice,
    this.batchNumber,
    this.expiryDate,
  });

  factory GrnItemRecord.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic v, [double def = 0.0]) {
      if (v == null) return def;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? def;
    }

    final expStr = json['expiry_date'];
    final exp = expStr != null ? DateTime.tryParse(expStr.toString()) : null;

    return GrnItemRecord(
      id: json['id']?.toString() ?? '',
      grnId: json['grn_id']?.toString() ?? '',
      ingredientId: json['ingredient_id']?.toString() ?? '',
      ingredientName: json['ingredient_name']?.toString() ?? 'Ingredient',
      poItemId: json['po_item_id']?.toString(),
      quantityReceived: parseNum(json['quantity_received']),
      quantityRejected: parseNum(json['quantity_rejected']),
      rejectionReason: json['rejection_reason']?.toString(),
      unit: json['unit']?.toString() ?? 'KG',
      unitPrice: parseNum(json['unit_price']),
      taxRate: parseNum(json['tax_rate']),
      taxAmount: parseNum(json['tax_amount']),
      totalPrice: parseNum(json['total_price']),
      batchNumber: json['batch_number']?.toString(),
      expiryDate: exp,
    );
  }
}

class GrnRecord {
  final String id;
  final String outletId;
  final String tenantId;
  final String grnNumber;
  final String poNumber;
  final String? poId;
  final String supplierId;
  final String supplierName;
  final String supplierInvoiceNo;
  final String? invoiceDocumentUrl;
  final DateTime invoiceDate;
  final DateTime receivedDate;
  final double totalAmount;
  final String paymentStatus;
  final List<GrnItemRecord> items;
  final String remarks;

  const GrnRecord({
    required this.id,
    this.outletId = '',
    this.tenantId = '',
    required this.grnNumber,
    required this.poNumber,
    this.poId,
    this.supplierId = '',
    required this.supplierName,
    required this.supplierInvoiceNo,
    this.invoiceDocumentUrl,
    required this.invoiceDate,
    required this.receivedDate,
    required this.totalAmount,
    this.paymentStatus = 'UNPAID',
    this.items = const [],
    this.remarks = '',
  });

  factory GrnRecord.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic v, [double def = 0.0]) {
      if (v == null) return def;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? def;
    }

    final invDateStr = json['invoice_date'] ?? json['created_at'];
    final invDate = invDateStr != null ? DateTime.tryParse(invDateStr.toString()) ?? DateTime.now() : DateTime.now();

    final recDateStr = json['created_at'] ?? json['received_date'];
    final recDate = recDateStr != null ? DateTime.tryParse(recDateStr.toString()) ?? DateTime.now() : DateTime.now();

    final List rawItems = json['items'] is List ? json['items'] : [];
    final items = rawItems.map((it) => GrnItemRecord.fromJson(Map<String, dynamic>.from(it))).toList();

    return GrnRecord(
      id: json['id']?.toString() ?? '',
      outletId: json['outlet_id']?.toString() ?? '',
      tenantId: json['tenant_id']?.toString() ?? '',
      grnNumber: json['grn_number']?.toString() ?? 'GRN-001',
      poNumber: json['po_number']?.toString() ?? 'Direct Inward',
      poId: json['po_id']?.toString(),
      supplierId: json['supplier_id']?.toString() ?? '',
      supplierName: json['supplier_name']?.toString() ?? 'Vendor',
      supplierInvoiceNo: json['supplier_invoice_no']?.toString() ?? 'N/A',
      invoiceDocumentUrl: json['invoice_document_url']?.toString(),
      invoiceDate: invDate,
      receivedDate: recDate,
      totalAmount: parseNum(json['total_amount']),
      paymentStatus: json['payment_status']?.toString() ?? 'UNPAID',
      items: items,
      remarks: json['remarks']?.toString() ?? '',
    );
  }
}
