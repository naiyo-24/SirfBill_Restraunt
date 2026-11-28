import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/hardware_product_model.dart';
import '../../../services/hardware/hardware_service.dart';
import '../../home/widgets/hardware_order_inquiry_dialog.dart';
import '../../home/widgets/hardware_store_product_card.dart';
import 'growth_plan_detail_dialog.dart';

class AdminGrowthPlansTab extends StatefulWidget {
  final Color cardBg;
  final Color borderColor;
  final Color textColor;
  final Color subtitleColor;
  final bool isDark;

  const AdminGrowthPlansTab({
    super.key,
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    required this.subtitleColor,
    required this.isDark,
  });

  @override
  State<AdminGrowthPlansTab> createState() => _AdminGrowthPlansTabState();
}

class _AdminGrowthPlansTabState extends State<AdminGrowthPlansTab> {
  List<HardwareProduct> _hardwareProducts = [];
  List<Map<String, dynamic>> _liveInfluencerPlans = [];
  List<Map<String, dynamic>> _liveWebsitePlans = [];
  bool _loadingHardware = true;
  bool _loadingPlans = true;

  static const List<int> _palette = [
    0xFF10B981,
    0xFF3B82F6,
    0xFF8B5CF6,
    0xFFF59E0B,
  ];
  final _inrFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadHardware(), _loadServicePlans()]);
  }

  Future<void> _loadHardware() async {
    try {
      final items = await HardwareService.fetchProducts();
      if (mounted) {
        setState(() {
          _hardwareProducts = items;
          _loadingHardware = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingHardware = false);
    }
  }

  Future<void> _loadServicePlans() async {
    try {
      final raw = await HardwareService.fetchServicePlans();
      final active = raw.where((p) => p['is_active'] != false).toList()
        ..sort((a, b) => ((a['sort_order'] ?? 0) as num).compareTo((b['sort_order'] ?? 0) as num));

      final influencer = <Map<String, dynamic>>[];
      final website = <Map<String, dynamic>>[];

      for (final item in active) {
        final cat = (item['category'] ?? '').toString().toUpperCase();
        final isInfluencer = cat.contains('INFLUENCER');
        final isWebsite = cat.contains('WEBSITE');
        if (!isInfluencer && !isWebsite) continue;

        final target = isInfluencer ? influencer : website;
        final color = _palette[target.length % _palette.length];
        final numPrice = (item['price'] is num)
            ? (item['price'] as num).toDouble()
            : (double.tryParse(item['price']?.toString() ?? '0') ?? 0.0);
        final numOffer = item['offer_price'] != null
            ? ((item['offer_price'] is num)
                ? (item['offer_price'] as num).toDouble()
                : double.tryParse(item['offer_price'].toString()))
            : null;
        final hasOffer = numOffer != null && numOffer > 0 && numOffer < numPrice;
        final activePrice = hasOffer ? numOffer : numPrice;
        final gstApplicable = item['gst_applicable'] == true;

        target.add({
          'id': (item['id'] ?? '').toString(),
          'plan_code': (item['plan_code'] ?? '').toString(),
          'title': (item['name'] ?? '').toString(),
          'price': _inrFormat.format(activePrice),
          if (hasOffer) 'original_price': _inrFormat.format(numPrice),
          if (hasOffer && numPrice > 0)
            'discount_pct': (((numPrice - numOffer) / numPrice) * 100).round(),
          'numeric_price': activePrice,
          if (gstApplicable) 'gst': '+ GST',
          'tag': (item['badge'] ?? 'PLAN').toString(),
          'color': color,
          'features': (item['features'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
          'details': (item['description'] ?? '').toString(),
        });
      }

      if (mounted) {
        setState(() {
          _liveInfluencerPlans = influencer;
          _liveWebsitePlans = website;
          _loadingPlans = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPlans = false);
    }
  }

  static const List<Map<String, dynamic>> _influencerPlans = [
    {
      'title': '1 Influencer',
      'price': '₹5,000',
      'tag': 'STARTER',
      'color': 0xFF10B981,
      'features': ['1 Verified Food Creator Visit', '1 Instagram Reel + 2 Stories', 'Table QR & Location Tagging'],
    },
    {
      'title': '2 Influencers',
      'price': '₹8,000',
      'tag': 'POPULAR',
      'color': 0xFF3B82F6,
      'features': ['2 Verified Food Creators', '2 Reels + 4 Stories Coverage', 'Save ₹2,000 on Bundle'],
    },
    {
      'title': '5 Influencers',
      'price': '₹22,000',
      'tag': 'CITY REACH',
      'color': 0xFF8B5CF6,
      'features': ['5 Local & Micro-Influencers', '5 Reels + Multi-Day Buzz', 'Dedicated Campaign Manager'],
    },
    {
      'title': '11 Influencers',
      'price': '₹50,000',
      'tag': 'MEGA VIRAL',
      'color': 0xFFF59E0B,
      'features': ['11 Top City Food Creators', '11 Reels + Viral Weekend Push', 'Full Analytics & Footfall Boost'],
    },
  ];

  static const List<Map<String, dynamic>> _websitePlans = [
    {
      'title': 'Basic',
      'price': '₹500',
      'gst': '+ GST',
      'tag': 'ESSENTIAL',
      'color': 0xFF10B981,
      'features': ['Restaurant Profile Page', 'Digital Menu & Table QR Link', 'Mobile-Friendly Responsive UI'],
    },
    {
      'title': 'Standard',
      'price': '₹999',
      'gst': '+ GST',
      'tag': 'BEST VALUE',
      'color': 0xFF3B82F6,
      'features': ['Custom Domain Connection', 'Online Menu + Direct Ordering', 'Google Maps & Contact Integration'],
    },
    {
      'title': 'Customized',
      'price': '₹5,999',
      'gst': '(GST)',
      'tag': 'CUSTOM DESIGN',
      'color': 0xFF8B5CF6,
      'features': ['Bespoke Restaurant Branding UI', 'Photo Gallery & Table Booking', 'WhatsApp & Social Integrations'],
    },
    {
      'title': 'Business Plan',
      'price': '₹12,000',
      'gst': '+ GST',
      'tag': 'ENTERPRISE',
      'color': 0xFF6366F1,
      'features': ['Multi-Branch Website Portal', 'SEO Optimization + Speed CDN', 'Priority Support & Updates'],
    },
  ];

  void _openPlanDetails(BuildContext context, String category, Map<String, dynamic> plan) {
    GrowthPlanDetailDialog.show(
      context,
      category: category,
      plan: plan,
      cardBg: widget.cardBg,
      borderColor: widget.borderColor,
      textColor: widget.textColor,
      subtitleColor: widget.subtitleColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF34D399), size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Growth, Website & Hardware Plans',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Boost your restaurant footfall with Influencer Marketing, Official Websites, and Certified POS Hardware.',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFFCBD5E1)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 1: Influencer Plans
          _sectionHeader(
            Icons.campaign_rounded,
            '1. Influencer Marketing Plans',
            'Drive local food lovers & viral reels straight to your tables',
            const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              if (_loadingPlans) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final plans = _liveInfluencerPlans.isNotEmpty ? _liveInfluencerPlans : _influencerPlans;
              final cols = constraints.maxWidth > 1050 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
              return _buildPlanGrid(context, plans, 'Influencer Plan', cols);
            },
          ),
          const SizedBox(height: 28),

          // Section 2: Website Plans
          _sectionHeader(
            Icons.language_rounded,
            '2. Restaurant Website Plans',
            'Launch your restaurant’s own branded website & online menu',
            const Color(0xFF6366F1),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              if (_loadingPlans) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final plans = _liveWebsitePlans.isNotEmpty ? _liveWebsitePlans : _websitePlans;
              final cols = constraints.maxWidth > 1050 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
              return _buildPlanGrid(context, plans, 'Website Plan', cols);
            },
          ),
          const SizedBox(height: 28),

          // Section 3: Certified POS Hardware Store (All Products Grid)
          _sectionHeader(
            Icons.storefront_rounded,
            '3. Certified POS Hardware Store',
            'Thermal printers, cash drawers, KDS displays & barcode scanners',
            const Color(0xFF10B981),
          ),
          const SizedBox(height: 14),
          if (_loadingHardware)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
            )
          else if (_hardwareProducts.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: widget.borderColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.inventory_2_outlined, color: widget.subtitleColor),
                  const SizedBox(width: 10),
                  Text('No hardware products available right now.', style: TextStyle(color: widget.subtitleColor)),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth > 1050 ? 3 : (constraints.maxWidth > 650 ? 2 : 1);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    mainAxisExtent: 275,
                  ),
                  itemCount: _hardwareProducts.length,
                  itemBuilder: (context, idx) => HardwareStoreProductCard(
                    product: _hardwareProducts[idx],
                    isDark: widget.isDark,
                    cardBg: widget.cardBg,
                    textColor: widget.textColor,
                    subtitleColor: widget.subtitleColor,
                    borderColor: widget.borderColor,
                    onInquire: (item) => HardwareOrderInquiryDialog.show(
                      context,
                      item: item,
                      onOpenWhatsApp: (msg) async {
                        await launchUrl(
                          Uri.parse('https://wa.me/918100463128?text=${Uri.encodeComponent(msg)}'),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title, String subtitle, Color accent) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: accent, size: 20),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: widget.textColor)),
            Text(subtitle, style: TextStyle(fontSize: 12, color: widget.subtitleColor)),
          ],
        ),
      ],
    );
  }

  Widget _buildPlanGrid(BuildContext context, List<Map<String, dynamic>> plans, String category, int cols) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 258,
      ),
      itemCount: plans.length,
      itemBuilder: (context, idx) {
        final p = plans[idx];
        final accent = Color(p['color'] as int);
        final gst = (p['gst'] ?? '').toString();
        final features = (p['features'] as List).cast<String>();

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openPlanDetails(context, category, p),
          child: Container(
            padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.borderColor),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(p['tag'].toString(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: accent)),
              ),
              const SizedBox(height: 10),
              Text(p['title'].toString(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: widget.textColor)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(p['price'].toString(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: accent)),
                  if ((p['original_price'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      p['original_price'].toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.subtitleColor,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                  if (gst.isNotEmpty) ...[
                    const SizedBox(width: 5),
                    Text(gst, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: widget.subtitleColor)),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              ...features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded, size: 14, color: accent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(f, style: TextStyle(fontSize: 11.5, color: widget.subtitleColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  )),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _openPlanDetails(context, category, p),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('View Details', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
        );
      },
    );
  }
}
