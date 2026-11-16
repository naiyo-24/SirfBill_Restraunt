import 'package:flutter/material.dart';
import '../models/inventory_models.dart';

class IngredientCategoryDropdown extends StatelessWidget {
  final List<IngredientCategory> categories;
  final String selectedCategory;
  final ValueChanged<String?> onChanged;

  const IngredientCategoryDropdown({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final validCategory = categories.any((c) => c.id == selectedCategory)
        ? selectedCategory
        : (categories.isNotEmpty ? categories.first.id : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: validCategory,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: categories.isEmpty ? 'No Categories Configured' : 'Select Category',
          ),
          items: categories
              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, style: const TextStyle(fontSize: 13))))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class IngredientSupplierDropdown extends StatelessWidget {
  final List<Supplier> suppliers;
  final String selectedSupplier;
  final ValueChanged<String?> onChanged;

  const IngredientSupplierDropdown({
    super.key,
    required this.suppliers,
    required this.selectedSupplier,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final validSupplier = suppliers.any((s) => s.id == selectedSupplier)
        ? selectedSupplier
        : (suppliers.isNotEmpty ? suppliers.first.id : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Primary Supplier', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: validSupplier,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: suppliers.isEmpty ? 'No Suppliers Added' : 'Select Supplier',
          ),
          items: suppliers
              .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, style: const TextStyle(fontSize: 13))))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class IngredientUomDropdown extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String?> onChanged;

  const IngredientUomDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const units = ['KG', 'G', 'L', 'ML', 'PCS', 'DOZ', 'BAG', 'BOX'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: units
              .map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 13))))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
