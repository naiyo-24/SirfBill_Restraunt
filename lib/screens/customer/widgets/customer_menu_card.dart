import 'package:flutter/material.dart';
import 'dish_network_image.dart';

class CustomerMenuCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback? onTap;

  const CustomerMenuCard({
    super.key,
    required this.item,
    required this.quantity,
    required this.onQuantityChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = item['name']?.toString() ?? 'Food Item';
    final price = double.tryParse((item['price'] ?? 0).toString()) ?? 0.0;
    final itemType = (item['item_type'] ?? '').toString().toUpperCase();
    final isVeg = item['is_veg'] == true || itemType == 'VEG';
    final isEgg = itemType == 'EGG';
    final desc = item['description']?.toString() ?? '';
    final badge = item['badge']?.toString() ?? '';
    final prepStation = item['prep_station']?.toString() ?? '';
    final imageUrl = item['image_url']?.toString();

    final typeColor = isVeg
        ? const Color(0xFF16A34A)
        : (isEgg ? const Color(0xFFD97706) : const Color(0xFFDC2626));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: quantity > 0
              ? const Color(0xFF10B981).withValues(alpha: 0.45)
              : const Color(0xFFE2E8F0),
          width: quantity > 0 ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Veg/Non-Veg + Badge + Name + Price + Description + Station
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // FSSAI-style Veg/Non-Veg/Egg square indicator
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        border: Border.all(color: typeColor, width: 1.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: typeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    if (badge.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 11, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(
                              badge.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '₹${price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (prepStation.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          prepStation,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      height: 1.35,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Right: Dish Image + Floating ADD / Stepper
          SizedBox(
            width: 96,
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      width: 96,
                      height: 92,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: const Color(0xFFF1F5F9),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: (imageUrl != null && imageUrl.isNotEmpty)
                          ? buildDishNetworkImage(
                              imageUrl: imageUrl,
                              width: 96,
                              height: 92,
                              placeholderBuilder: () => _buildPlaceholder(name),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: _buildPlaceholder(name),
                            ),
                    ),
                    Positioned(
                      bottom: -12,
                      child: quantity == 0
                          ? Material(
                              color: Colors.white,
                              elevation: 3,
                              shadowColor: Colors.black.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                onTap: () => onQuantityChanged(1),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 82,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF10B981),
                                      width: 1.2,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'ADD +',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      color: Color(0xFF059669),
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Material(
                              color: const Color(0xFF059669),
                              elevation: 3,
                              shadowColor: const Color(0xFF059669).withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 84,
                                height: 32,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    InkWell(
                                      onTap: () => onQuantityChanged(quantity - 1),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                        child: Icon(Icons.remove_rounded, size: 15, color: Colors.white),
                                      ),
                                    ),
                                    Text(
                                      '$quantity',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => onQuantityChanged(quantity + 1),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                        child: Icon(Icons.add_rounded, size: 15, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildPlaceholder(String name) {
    return Container(
      width: 96,
      height: 92,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.restaurant_menu_rounded, color: Color(0xFF94A3B8), size: 26),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              name.split(' ').first,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
