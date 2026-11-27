import 'package:flutter/material.dart';
import 'dish_network_image.dart';

class CustomerDishDetailSheet extends StatefulWidget {
  final Map<String, dynamic> item;
  final int initialQuantity;
  final ValueChanged<int> onQuantityChanged;

  const CustomerDishDetailSheet({
    super.key,
    required this.item,
    required this.initialQuantity,
    required this.onQuantityChanged,
  });

  static void show(
    BuildContext context, {
    required Map<String, dynamic> item,
    required int initialQuantity,
    required ValueChanged<int> onQuantityChanged,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomerDishDetailSheet(
        item: item,
        initialQuantity: initialQuantity,
        onQuantityChanged: onQuantityChanged,
      ),
    );
  }

  @override
  State<CustomerDishDetailSheet> createState() => _CustomerDishDetailSheetState();
}

class _CustomerDishDetailSheetState extends State<CustomerDishDetailSheet> {
  late int _qty;

  @override
  void initState() {
    super.initState();
    _qty = widget.initialQuantity > 0 ? widget.initialQuantity : 1;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final name = item['name']?.toString() ?? 'Food Item';
    final price = double.tryParse((item['price'] ?? 0).toString()) ?? 0.0;
    final itemType = (item['item_type'] ?? '').toString().toUpperCase();
    final isVeg = item['is_veg'] == true || itemType == 'VEG';
    final isEgg = itemType == 'EGG';
    final desc = item['description']?.toString() ?? '';
    final badge = item['badge']?.toString() ?? '';
    final prepStation = item['prep_station']?.toString() ?? '';
    final category = item['category_name']?.toString() ?? '';
    final imageUrl = item['image_url']?.toString();
    final typeColor = isVeg
        ? const Color(0xFF16A34A)
        : (isEgg ? const Color(0xFFD97706) : const Color(0xFFDC2626));

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: SizedBox(
                          width: double.infinity,
                          height: 220,
                          child: (imageUrl != null && imageUrl.isNotEmpty)
                              ? buildDishNetworkImage(
                                  imageUrl: imageUrl,
                                  width: double.infinity,
                                  height: 220,
                                  placeholderBuilder: () => _buildPlaceholder(name),
                                )
                              : _buildPlaceholder(name),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => Navigator.pop(context),
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(Icons.close_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ),
                      if (badge.isNotEmpty)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 13, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  badge.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          border: Border.all(color: typeColor, width: 1.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(color: typeColor, shape: BoxShape.circle),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                          ),
                        ),
                      if (prepStation.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            prepStation,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${price.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      desc,
                      style: const TextStyle(fontSize: 13.5, color: Color(0xFF475569), height: 1.5),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_rounded, size: 18),
                          onPressed: () {
                            if (_qty > 1) setState(() => _qty--);
                          },
                        ),
                        Text(
                          '$_qty',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_rounded, size: 18),
                          onPressed: () => setState(() => _qty++),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onQuantityChanged(_qty);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Add Item • ₹${(price * _qty).toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String name) {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu_rounded, size: 44, color: Color(0xFF94A3B8)),
            const SizedBox(height: 8),
            Text(name, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
