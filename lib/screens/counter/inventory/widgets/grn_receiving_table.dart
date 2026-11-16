import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/grn_models.dart';

class GrnReceivingTable extends StatefulWidget {
  final List<GrnItemInput> items;
  final bool isDark;
  final VoidCallback onItemChanged;

  const GrnReceivingTable({
    super.key,
    required this.items,
    required this.isDark,
    required this.onItemChanged,
  });

  @override
  State<GrnReceivingTable> createState() => _GrnReceivingTableState();
}

class _GrnReceivingTableState extends State<GrnReceivingTable> {
  final Set<int> _expandedRows = {};
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.35) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 5, child: Text('ITEM / COMMODITY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                SizedBox(width: 8),
                Expanded(flex: 2, child: Text('ORDERED', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                SizedBox(width: 8),
                Expanded(flex: 2, child: Text('RECEIVED QTY', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)))),
                SizedBox(width: 8),
                Expanded(flex: 2, child: Text('ACTUAL PRICE (₹)', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                SizedBox(width: 8),
                Expanded(flex: 2, child: Text('INVOICE GST %', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)))),
                SizedBox(width: 8),
                Expanded(flex: 3, child: Text('LINE TOTAL (₹)', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                SizedBox(width: 32),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: widget.items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final isExpanded = _expandedRows.contains(idx);
                final hasRejection = item.quantityRejected > 0;
                final hasBatch = item.batchController.text.trim().isNotEmpty || item.expiryDate != null;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasRejection
                          ? Colors.orange.withValues(alpha: 0.5)
                          : isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.ingredientName,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (hasRejection || hasBatch)
                                    Row(
                                      children: [
                                        if (hasRejection)
                                          Text(
                                            'Rejected: ${item.quantityRejected} ${item.unit}',
                                            style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                                          ),
                                        if (hasRejection && hasBatch) const Text(' • ', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                        if (hasBatch)
                                          Text(
                                            'Batch: ${item.batchController.text.isNotEmpty ? item.batchController.text : "Tracked"}',
                                            style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
                                          ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${item.orderedQty.toStringAsFixed(1)} ${item.unit}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: item.receivedQtyController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                onChanged: (_) => widget.onItemChanged(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: item.unitPriceController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                  isDense: true,
                                  prefixText: '₹ ',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                onChanged: (_) => widget.onItemChanged(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<double>(
                                initialValue: item.taxRate,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 0.0, child: Text('0%', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 5.0, child: Text('5%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                  DropdownMenuItem(value: 12.0, child: Text('12%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                  DropdownMenuItem(value: 18.0, child: Text('18%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                  DropdownMenuItem(value: 28.0, child: Text('28%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                ],
                                onChanged: (v) {
                                  item.taxRate = v ?? 0.0;
                                  widget.onItemChanged();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: Text(
                                '₹${item.totalPrice.toStringAsFixed(0)}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isExpanded ? Icons.expand_less : Icons.expand_more,
                                size: 18,
                                color: (hasRejection || hasBatch) ? const Color(0xFF10B981) : Colors.grey,
                              ),
                              tooltip: 'Quality Control, Rejection & Batch (FEFO)',
                              onPressed: () {
                                setState(() {
                                  if (isExpanded) {
                                    _expandedRows.remove(idx);
                                  } else {
                                    _expandedRows.add(idx);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      if (isExpanded)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                            border: Border(top: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), width: 0.5)),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 110,
                                child: TextFormField(
                                  controller: item.rejectedQtyController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    labelText: 'Dock Rejected',
                                    isDense: true,
                                    suffixText: item.unit,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                  onChanged: (_) {
                                    widget.onItemChanged();
                                    setState(() {});
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: item.rejectionReasonController,
                                  style: const TextStyle(fontSize: 12),
                                  decoration: InputDecoration(
                                    labelText: 'Rejection Reason (Audit Trail)',
                                    hintText: 'e.g. Broken seal, temperature breach',
                                    isDense: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: item.batchController,
                                  style: const TextStyle(fontSize: 12),
                                  decoration: InputDecoration(
                                    labelText: 'Batch / Lot #',
                                    hintText: 'e.g. BATCH-NOV16',
                                    isDense: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 10),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: item.expiryDate ?? DateTime.now().add(const Duration(days: 30)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 1800)),
                                  );
                                  if (picked != null) {
                                    setState(() => item.expiryDate = picked);
                                    widget.onItemChanged();
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.event_available, size: 14, color: Color(0xFF10B981)),
                                      const SizedBox(width: 4),
                                      Text(
                                        item.expiryDate != null ? _dateFormat.format(item.expiryDate!) : 'Expiry (FEFO)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: item.expiryDate != null ? FontWeight.bold : FontWeight.normal,
                                          color: item.expiryDate != null ? const Color(0xFF10B981) : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
