import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/hardware/hardware_service.dart';
import 'growth_plan_card.dart';
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
  List<Map<String, dynamic>> _liveInfluencerPlans = [];
  List<Map<String, dynamic>> _liveWebsitePlans = [];
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
    _loadServicePlans();
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
        final hasOffer = numOffer != null && numOffer >= 0 && numOffer < numPrice;
        final activePrice = hasOffer ? numOffer : numPrice;
        final gstApplicable = item['gst_applicable'] == true && activePrice > 0;

        target.add({
          'id': (item['id'] ?? '').toString(),
          'plan_code': (item['plan_code'] ?? '').toString(),
          'title': (item['name'] ?? '').toString(),
          'price': activePrice == 0 ? 'FREE' : _inrFormat.format(activePrice),
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
          // Executive Hero Banner with Right-Side Glass Stats
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0B1120), Color(0xFF1E1B4B), Color(0xFF064E3B)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.24),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -40,
                    top: -40,
                    child: Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF34D399).withValues(alpha: 0.22),
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
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF10B981).withValues(alpha: 0.28),
                                    const Color(0xFF6366F1).withValues(alpha: 0.25),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                              ),
                              child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF34D399), size: 30),
                            ),
                            const SizedBox(width: 18),
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
                                      'SIRFBILL GROWTH SUITE',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Color(0xFF6EE7B7)),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Growth & Website Plans',
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.4),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Scale your restaurant footfall with verified Influencer Reels & high-converting Official Websites.',
                                    style: TextStyle(fontSize: 12.5, color: Color(0xFFCBD5E1)),
                                  ),
                                ],
                              ),
                            ),
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
                                    _heroStat('500+', 'Outlets Scaled'),
                                    _heroDivider(),
                                    _heroStat('24h', 'Fast Launch'),
                                    _heroDivider(),
                                    _heroStat('100%', 'Verified ROI'),
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
          ),
          const SizedBox(height: 28),

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
        ],
      ),
    );
  }

  Widget _heroStat(String value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF34D399))),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFFCBD5E1))),
        ],
      ),
    );
  }

  Widget _heroDivider() {
    return Container(height: 28, width: 1, color: Colors.white.withValues(alpha: 0.16));
  }

  Widget _sectionHeader(IconData icon, String title, String subtitle, Color accent) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent.withValues(alpha: 0.18), accent.withValues(alpha: 0.06)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, color: accent, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: widget.textColor, letterSpacing: -0.2)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12, color: widget.subtitleColor)),
            ],
          ),
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
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 310,
      ),
      itemCount: plans.length,
      itemBuilder: (context, idx) => GrowthPlanCard(
        plan: plans[idx],
        category: category,
        index: idx,
        cardBg: widget.cardBg,
        borderColor: widget.borderColor,
        textColor: widget.textColor,
        subtitleColor: widget.subtitleColor,
        isDark: widget.isDark,
        onTap: () => _openPlanDetails(context, category, plans[idx]),
      ),
    );
  }
}
