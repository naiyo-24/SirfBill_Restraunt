import 'package:flutter/material.dart';

class PoLineItemInput {
  String? ingredientId;
  String? ingredientName;
  final TextEditingController qtyController = TextEditingController(text: '10');
  final TextEditingController priceController = TextEditingController(text: '0');
  String unit = 'KG';
  double taxRate = 0.0; // Standard GST: 0%, 5%, 12%, 18%, 28%

  PoLineItemInput();

  double get quantity => double.tryParse(qtyController.text) ?? 0.0;
  double get unitPrice => double.tryParse(priceController.text) ?? 0.0;
  double get subtotal => quantity * unitPrice;
  double get taxAmount => (subtotal * (taxRate / 100.0));
  double get totalPrice => subtotal + taxAmount;

  void dispose() {
    qtyController.dispose();
    priceController.dispose();
  }
}
