import 'package:flutter/material.dart';

/// Luxury executive hero banner for the Certified POS Hardware Store.
class AdminHardwareHeroBanner extends StatelessWidget {
  final int totalCount;

  const AdminHardwareHeroBanner({
    super.key,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF064E3B), Color(0xFF0F172A), Color(0xFF022C22)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF064E3B).withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Ambient Radial Glow
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF34D399).withValues(alpha: 0.28),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 760;
                  return Row(
                    children: [
                      // Glowing Storefront Icon
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF10B981).withValues(alpha: 0.32),
                              const Color(0xFF059669).withValues(alpha: 0.20),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.storefront_rounded, color: Color(0xFF34D399), size: 32),
                      ),
                      const SizedBox(width: 18),

                      // Title & Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.45)),
                              ),
                              child: const Text(
                                'OFFICIAL HARDWARE STORE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: Color(0xFF6EE7B7),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Certified POS Hardware Store',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Commercial thermal printers, dual-screen POS, cash drawers & KDS displays pre-configured for SirfBill.',
                              style: TextStyle(fontSize: 12.5, color: Color(0xFFCBD5E1)),
                            ),
                          ],
                        ),
                      ),

                      // Glass Metrics Pill on wide screens
                      if (wide) ...[
                        const SizedBox(width: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _stat('$totalCount Devices', 'Certified Catalog'),
                              _divider(),
                              _stat('1 Year', 'Express Replacement'),
                              _divider(),
                              _stat('Plug & Play', 'Zero Setup Drivers'),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF34D399))),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFFCBD5E1))),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(height: 28, width: 1, color: Colors.white.withValues(alpha: 0.16));
  }
}
