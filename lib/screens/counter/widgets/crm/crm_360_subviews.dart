import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/restaurant_crm_models.dart';
import '../../../../services/restaurant_pos_service.dart';
import '../../../../services/shop_settings_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../utils/pdf_thermal_generator.dart';
import '../pos/pos_bill_receipt_modal.dart';

class CrmOverviewTabView extends StatelessWidget {
  final RestaurantCustomer customer;
  final CustomerInsights? insights;
  final bool isDark;

  const CrmOverviewTabView({
    super.key,
    required this.customer,
    this.insights,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final c = customer;
    final inFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final df = DateFormat('dd MMM yyyy');

    int visits = c.totalVisits;
    double spent = c.totalSpent;
    double aov = c.avgOrderValue;
    DateTime? lastVisit = c.lastVisitAt;
    int loyalty = c.loyaltyPoints;

    if (visits == 0 && insights != null && insights!.recentBills.isNotEmpty) {
      visits = insights!.recentBills.length;
      spent = insights!.recentBills.fold(0.0, (s, b) => s + b.grandTotal);
      aov = visits > 0 ? (spent / visits) : 0.0;
      lastVisit = insights!.recentBills.map((b) => b.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);
      if (insights!.loyaltyBalance > 0) loyalty = insights!.loyaltyBalance;
    }
    if (loyalty == 0 && spent > 0) {
      loyalty = (spent / 50).round();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(child: _buildMetric('Total Visits', '$visits', Icons.calendar_month_rounded, isDark)),
            const SizedBox(width: 8),
            Expanded(child: _buildMetric('Total Spent', inFormat.format(spent), Icons.currency_rupee_rounded, isDark)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildMetric('Avg Ticket (AOV)', inFormat.format(aov), Icons.shopping_bag_outlined, isDark)),
            const SizedBox(width: 8),
            Expanded(child: _buildMetric('Reward Points', '$loyalty pts', Icons.stars_rounded, isDark, color: const Color(0xFF10B981))),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'GUEST DETAILS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        _buildDetailRow('Last Visit', lastVisit != null ? df.format(lastVisit) : 'Never'),
        if (c.dob != null) _buildDetailRow('Birthday', df.format(c.dob!)),
        if (c.anniversary != null) _buildDetailRow('Anniversary', df.format(c.anniversary!)),
        if (c.gstNumber != null && c.gstNumber!.isNotEmpty) _buildDetailRow('Corporate GSTIN', c.gstNumber!),
        _buildDetailRow('Store Credit Limit', inFormat.format(c.creditLimit)),
        if (c.notes.isNotEmpty) _buildDetailRow('Special Notes', c.notes),
      ],
    );
  }

  Widget _buildMetric(String label, String value, IconData icon, bool isDark, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? const Color(0xFF3B82F6)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class CrmTopDishesTabView extends StatelessWidget {
  final List<CustomerTopDish> topDishes;
  final bool isDark;

  const CrmTopDishesTabView({super.key, required this.topDishes, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (topDishes.isEmpty) {
      return const Center(child: Text('No item order history recorded yet'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: topDishes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final d = topDishes[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text('#${i + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.itemName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    if (d.variantName != null && d.variantName!.isNotEmpty)
                      Text(d.variantName!, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${d.orderCount} ordered', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  Text('₹${d.totalSpent.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class CrmRecentBillsTabView extends StatelessWidget {
  final List<CustomerRecentBill> recentBills;
  final bool isDark;

  const CrmRecentBillsTabView({super.key, required this.recentBills, required this.isDark});

  static Future<void> _openBillDetails(BuildContext context, CustomerRecentBill bill) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening receipt for ${bill.orderNumber}...'),
        duration: const Duration(milliseconds: 900),
      ),
    );

    Uint8List? thermalPdfBytes;
    if (bill.orderId.isNotEmpty) {
      try {
        thermalPdfBytes = await RestaurantPosService.fetchBackendBillPdfBytes(bill.orderId);
      } catch (e) {
        debugPrint('Error fetching backend bill: $e');
      }
    }

    if (thermalPdfBytes == null) {
      Map<String, dynamic>? shopSettings;
      try {
        shopSettings = await ShopSettingsService.getSettings();
      } catch (_) {}

      final authName = await AuthService.getUserName();
      final shopName = (shopSettings?['shop_name']?.toString().trim().isNotEmpty ?? false)
          ? shopSettings!['shop_name'].toString()
          : ((authName != null && authName.trim().isNotEmpty) ? authName : 'SirfBill Restaurant');
      final address = shopSettings?['address']?.toString() ?? 'Restaurant Counter';
      final phone = shopSettings?['phone']?.toString() ?? shopSettings?['mobile']?.toString() ?? '';
      final shopGstNo = shopSettings?['gst_number']?.toString() ?? shopSettings?['gstin']?.toString() ?? '';
      final upiId = shopSettings?['upi_id']?.toString() ?? '';

      final subtotal = bill.grandTotal / 1.05;
      final gst = bill.grandTotal - subtotal;

      try {
        thermalPdfBytes = await PdfThermalGenerator.generateThermalBill(
          items: [
            {
              'name': 'Culinary Dining Ticket',
              'quantity': bill.itemsCount > 0 ? bill.itemsCount : 1,
              'price': subtotal,
              'total': subtotal,
              'gst': 5.0,
              'discount': 0.0,
            }
          ],
          subtotal: subtotal,
          discount: 0.0,
          tax: gst,
          grandTotal: bill.grandTotal,
          roundedTotal: bill.grandTotal.roundToDouble(),
          invoiceNumber: bill.orderNumber,
          customerName: 'Valued Guest',
          customerPhone: '',
          shopName: shopName,
          address: address,
          phone: phone,
          shopGstNo: shopGstNo,
          upiId: upiId,
          billingDate: bill.createdAt,
        );
      } catch (genErr) {
        debugPrint('Local thermal bill generator error: $genErr');
      }
    }

    if (context.mounted && thermalPdfBytes != null) {
      await PosBillReceiptModal.show(
        context,
        orderNumber: bill.orderNumber,
        title: 'Tax Invoice Receipt',
        pdfBytes: thermalPdfBytes,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (recentBills.isEmpty) {
      return const Center(child: Text('No recent dining bills found'));
    }

    final df = DateFormat('dd MMM yyyy, hh:mm a');

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: recentBills.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final b = recentBills[i];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openBillDetails(ctx, b),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155).withValues(alpha: 0.6) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF3B82F6), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.orderNumber, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        Text(df.format(b.createdAt), style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2).format(b.grandTotal),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                      Text('${b.paymentMethod.toUpperCase()} • ${b.status.toUpperCase()}', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class CrmKhataTabView extends StatelessWidget {
  final RestaurantCustomer customer;
  final List<KhataLedgerEntry> ledger;
  final bool isDark;
  final VoidCallback onSettleKhata;
  final VoidCallback onAdjustLoyalty;

  const CrmKhataTabView({
    super.key,
    required this.customer,
    required this.ledger,
    required this.isDark,
    required this.onSettleKhata,
    required this.onAdjustLoyalty,
  });

  @override
  Widget build(BuildContext context) {
    final c = customer;
    final hasDue = c.creditBalance > 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: hasDue ? const Color(0xFFEF4444).withValues(alpha: 0.1) : const Color(0xFF10B981).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: hasDue ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasDue ? 'KHATA OUTSTANDING DUE' : 'KHATA ALL SETTLED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: hasDue ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${c.creditBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: hasDue ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    ),
                  ),
                  Text('Credit Limit: ₹${c.creditLimit.toStringAsFixed(0)}', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                ],
              ),
              if (hasDue)
                ElevatedButton(
                  onPressed: onSettleKhata,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text('Settle Dues'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF59E0B))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('LOYALTY REWARDS BALANCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFF59E0B))),
                  const SizedBox(height: 2),
                  Text('${c.loyaltyPoints} Points', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFF59E0B))),
                ],
              ),
              OutlinedButton(
                onPressed: onAdjustLoyalty,
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFF59E0B), side: const BorderSide(color: Color(0xFFF59E0B)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('Adjust Points'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'STORE CREDIT LEDGER AUDIT',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        if (ledger.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('No credit transactions recorded yet')),
          )
        else
          ...ledger.map((e) {
            final isDebit = e.entryType == 'DEBIT';
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.referenceType, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      Text(DateFormat('dd MMM yyyy, hh:mm a').format(e.createdAt), style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isDebit ? "+" : "-"}₹${e.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isDebit ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        ),
                      ),
                      Text('Bal: ₹${e.balanceAfter.toStringAsFixed(2)}', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
