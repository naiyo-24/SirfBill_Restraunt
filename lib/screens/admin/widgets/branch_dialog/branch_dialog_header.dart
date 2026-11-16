import 'package:flutter/material.dart';

class BranchDialogHeader extends StatelessWidget {
  static const defaultTabs = [
    {'num': '01', 'title': 'Basic Info', 'icon': Icons.storefront_rounded},
    {'num': '02', 'title': 'Address & Contact', 'icon': Icons.location_on_rounded},
    {'num': '03', 'title': 'Operating Settings', 'icon': Icons.schedule_rounded},
    {'num': '04', 'title': 'Billing & Tax', 'icon': Icons.receipt_long_rounded},
    {'num': '05', 'title': 'Staff & Roles', 'icon': Icons.badge_rounded},
  ];

  final bool isDark;
  final Color borderColor;
  final Color textColor;
  final Color subtitleColor;
  final bool isEdit;
  final TabController tabController;
  final List<Map<String, dynamic>> tabs;
  final VoidCallback onClose;

  const BranchDialogHeader({
    super.key,
    required this.isDark,
    required this.borderColor,
    required this.textColor,
    required this.subtitleColor,
    required this.isEdit,
    required this.tabController,
    required this.tabs,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Header Title Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.add_business_rounded,
                  color: Color(0xFF6366F1),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit
                          ? 'Edit Outlet / Branch Profile'
                          : 'Configure New Outlet / Branch',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEdit
                          ? 'Update location details, business hours, and operational permissions'
                          : 'Set up multi-location profile, operating schedules, tax rules & staff permissions',
                      style: TextStyle(fontSize: 11.5, color: subtitleColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: Icon(Icons.close_rounded, color: subtitleColor),
                splashRadius: 20,
              ),
            ],
          ),
        ),

        // Steps TabBar
        Container(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          child: TabBar(
            controller: tabController,
            isScrollable: true,
            labelColor: const Color(0xFF6366F1),
            unselectedLabelColor: subtitleColor,
            indicatorColor: const Color(0xFF6366F1),
            indicatorWeight: 3,
            tabAlignment: TabAlignment.start,
            tabs: tabs.map((t) {
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t['num'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                    ),
                    const SizedBox(width: 6),
                    Icon(t['icon'] as IconData, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      t['title'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
