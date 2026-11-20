import 'package:flutter/material.dart';
import '../../../../models/restaurant_executive_report_models.dart';

class ProcurementGstTab extends StatelessWidget {
  final ProcurementReport? report;
  final bool isLoading;

  const ProcurementGstTab({
    super.key,
    required this.report,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
    }

    if (report == null) {
      return const Center(child: Text('No procurement data available for this period'));
    }

    final r = report!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return ListView(
          padding: EdgeInsets.all(isMobile ? 12 : 20),
          children: [
            // Row 1: High Level Spend & Tax KPIs
            _buildSpendKpis(r, isDark, isMobile),
            const SizedBox(height: 16),

            // Row 2: Input GST Tax Slabs (5%, 12%, 18%)
            _buildGstSlabsRow(r, isDark, isMobile),
            const SizedBox(height: 16),

            // Row 3: Unpaid Payables Aging Brackets
            _buildAgingBuckets(r, isDark, isMobile),
            const SizedBox(height: 16),

            // Row 4: Supplier Purchase Ledger
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'VENDOR PURCHASE & INPUT TAX REGISTER (${r.suppliers.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const Divider(height: 1),

                  if (r.suppliers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text('No vendor purchase invoices recorded for this period')),
                    )
                  else if (isMobile)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: r.suppliers.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
                      itemBuilder: (ctx, i) => _buildMobileSupplierCard(r.suppliers[i], isDark),
                    )
                  else
                    _buildDesktopTable(r.suppliers, isDark),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpendKpis(ProcurementReport r, bool isDark, bool isMobile) {
    final kpis = [
      _buildCard('TOTAL PURCHASES', '₹${r.totalPurchaseSpend.toStringAsFixed(0)}', 'Net raw ingredient spend', const Color(0xFF3B82F6), isDark),
      _buildCard('INPUT GST CLAIMED', '₹${r.totalInputGstPaid.toStringAsFixed(0)}', 'ITC credit offset', const Color(0xFF10B981), isDark),
      _buildCard('UNPAID PAYABLES', '₹${r.totalUnpaidPayables.toStringAsFixed(0)}', 'Outstanding vendor dues', const Color(0xFFEF4444), isDark),
    ];

    if (isMobile) {
      return Column(children: kpis.map((k) => Padding(padding: const EdgeInsets.only(bottom: 8), child: k)).toList());
    }

    return Row(children: kpis.map((k) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: k))).toList());
  }

  Widget _buildGstSlabsRow(ProcurementReport r, bool isDark, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('INPUT TAX CREDIT (ITC) BY TAX SLAB', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildSlabItem('GST 5% Slab', '₹${r.gst5Total.toStringAsFixed(2)}', Colors.teal, isDark)),
              Expanded(child: _buildSlabItem('GST 12% Slab', '₹${r.gst12Total.toStringAsFixed(2)}', Colors.indigo, isDark)),
              Expanded(child: _buildSlabItem('GST 18% Slab', '₹${r.gst18Total.toStringAsFixed(2)}', Colors.deepPurple, isDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlabItem(String label, String value, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _buildAgingBuckets(ProcurementReport r, bool isDark, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('UNPAID GRN PAYABLES AGING ANALYSIS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Row(
            children: r.agingBuckets.map((b) {
              final isOld = b.agingBracket.contains('30');
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isOld
                        ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isOld ? const Color(0xFFEF4444) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.agingBracket, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isOld ? const Color(0xFFEF4444) : Colors.grey.shade500)),
                      const SizedBox(height: 2),
                      Text('₹${b.unpaidAmount.toStringAsFixed(0)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: isOld ? const Color(0xFFEF4444) : null)),
                      Text('${b.invoiceCount} invoices', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String label, String value, String sub, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey.shade500)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          Text(sub, style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(List<ProcurementSupplierSummary> suppliers, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
        columns: const [
          DataColumn(label: Text('SUPPLIER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('GSTIN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('GRN COUNT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('NET PURCHASE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('TAX PAID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('TOTAL AMOUNT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('PAID AMOUNT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('UNPAID BALANCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
        ],
        rows: suppliers.map((s) {
          final hasDue = s.unpaidBalance > 0;
          return DataRow(
            cells: [
              DataCell(Text(s.supplierName, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(s.gstin ?? 'N/A', style: TextStyle(fontSize: 11, color: Colors.grey.shade600))),
              DataCell(Text('${s.grnCount}')),
              DataCell(Text('₹${s.netPurchaseAmount.toStringAsFixed(2)}')),
              DataCell(Text('₹${s.totalTaxPaid.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF10B981)))),
              DataCell(Text('₹${s.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700))),
              DataCell(Text('₹${s.paidAmount.toStringAsFixed(2)}')),
              DataCell(
                Text(
                  '₹${s.unpaidBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: hasDue ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileSupplierCard(ProcurementSupplierSummary s, bool isDark) {
    final hasDue = s.unpaidBalance > 0;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.supplierName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              Text(
                '₹${s.unpaidBalance.toStringAsFixed(0)} Due',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: hasDue ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'GSTIN: ${s.gstin ?? "N/A"} • ${s.grnCount} GRNs • Total: ₹${s.totalAmount.toStringAsFixed(0)} (Tax: ₹${s.totalTaxPaid.toStringAsFixed(0)})',
            style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
