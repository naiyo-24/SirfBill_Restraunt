import 'package:flutter/material.dart';
import '../models/inventory_models.dart';

class TransferItemInput {
  Ingredient? ingredient;
  final TextEditingController qtyCtrl = TextEditingController();
  String inputUom = 'PURCHASE';

  double get quantity => double.tryParse(qtyCtrl.text.trim()) ?? 0.0;
}

class TransferLineItemCard extends StatelessWidget {
  final int index;
  final TransferItemInput item;
  final List<Ingredient> ingredients;
  final bool isDark;
  final Color borderColor;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const TransferLineItemCard({
    super.key,
    required this.index,
    required this.item,
    required this.ingredients,
    required this.isDark,
    required this.borderColor,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 480;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: isSmall ? _buildStackedLayout() : _buildInlineLayout(),
        );
      },
    );
  }

  Widget _buildStackedLayout() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<Ingredient>(
                initialValue: item.ingredient,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Select Commodity *', isDense: true),
                items: ingredients
                    .map((ing) => DropdownMenuItem(value: ing, child: Text('${ing.name} (${ing.formattedStock})', overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (val) {
                  item.ingredient = val;
                  onChanged();
                },
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: item.qtyCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Qty (${item.inputUom == 'PURCHASE' ? item.ingredient?.purchaseUom ?? 'UOM' : item.ingredient?.recipeUom ?? 'UOM'})',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: DropdownButton<String>(
                value: item.inputUom,
                isDense: true,
                isExpanded: true,
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem(value: 'PURCHASE', child: Text(item.ingredient?.purchaseUom ?? 'Purchase', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'RECIPE', child: Text(item.ingredient?.recipeUom ?? 'Recipe', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (val) {
                  if (val != null) {
                    item.inputUom = val;
                    onChanged();
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInlineLayout() {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: DropdownButtonFormField<Ingredient>(
            initialValue: item.ingredient,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Select Commodity *', isDense: true),
            items: ingredients
                .map((ing) => DropdownMenuItem(value: ing, child: Text('${ing.name} (${ing.formattedStock})', overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (val) {
              item.ingredient = val;
              onChanged();
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: TextField(
            controller: item.qtyCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Qty (${item.inputUom == 'PURCHASE' ? item.ingredient?.purchaseUom ?? 'UOM' : item.ingredient?.recipeUom ?? 'UOM'})',
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: DropdownButton<String>(
            value: item.inputUom,
            isDense: true,
            isExpanded: true,
            underline: const SizedBox(),
            items: [
              DropdownMenuItem(value: 'PURCHASE', child: Text(item.ingredient?.purchaseUom ?? 'Purchase', overflow: TextOverflow.ellipsis)),
              DropdownMenuItem(value: 'RECIPE', child: Text(item.ingredient?.recipeUom ?? 'Recipe', overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (val) {
              if (val != null) {
                item.inputUom = val;
                onChanged();
              }
            },
          ),
        ),
        IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
        ),
      ],
    );
  }
}
