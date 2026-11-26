import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../config/api_constants.dart';
import '../../../../models/restaurant_pos_models.dart';
import '../../../../services/inventory_service.dart';

class TableQrDialog extends StatefulWidget {
  final DiningTable table;
  final String? outletId;

  const TableQrDialog({
    super.key,
    required this.table,
    this.outletId,
  });

  static void show(BuildContext context, DiningTable table, {String? outletId}) {
    showDialog(
      context: context,
      builder: (ctx) => TableQrDialog(table: table, outletId: outletId),
    );
  }

  @override
  State<TableQrDialog> createState() => _TableQrDialogState();
}

class _TableQrDialogState extends State<TableQrDialog> {
  String? _resolvedOutletId;
  late TextEditingController _hostController;
  bool _isEditingHost = false;

  @override
  void initState() {
    super.initState();
    String defaultHost = Uri.base.origin;
    // If opened on localhost in browser, auto-resolve to LAN Wi-Fi IP so phones can connect
    if (Uri.base.host == 'localhost' || Uri.base.host == '127.0.0.1') {
      try {
        final apiUri = Uri.parse(ApiConstants.baseUrl);
        if (apiUri.host.isNotEmpty && apiUri.host != 'localhost' && apiUri.host != '127.0.0.1') {
          final scheme = Uri.base.scheme.isNotEmpty ? Uri.base.scheme : 'http';
          final port = Uri.base.hasPort ? ':${Uri.base.port}' : '';
          defaultHost = '$scheme://${apiUri.host}$port';
        }
      } catch (_) {}
    }
    _hostController = TextEditingController(text: defaultHost);
    _resolveOutletId();
  }

  @override
  void dispose() {
    _hostController.dispose();
    super.dispose();
  }

  Future<void> _resolveOutletId() async {
    final oid = widget.outletId ?? await InventoryService.getShopId();
    if (mounted) setState(() => _resolvedOutletId = oid);
  }

  String get _currentHost {
    final t = _hostController.text.trim();
    return t.isEmpty ? Uri.base.origin : t.replaceAll(RegExp(r'/+$'), '');
  }

  String get _orderUrl {
    final base = _currentHost;
    final oid = _resolvedOutletId ?? '';
    return '$base/#/table-order?outlet_id=$oid&table_id=${widget.table.id}';
  }

  String get _qrImageUrl {
    final encoded = Uri.encodeComponent(_currentHost);
    return '${ApiConstants.baseUrl}/api/restaurant/tables/${widget.table.id}/qr-image?base_url=$encoded';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final isLocalhost = _currentHost.contains('localhost') || _currentHost.contains('127.0.0.1');

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        width: 460,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF10B981), size: 22),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Table ${widget.table.label} QR Standee',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
                          ),
                          Text(
                            widget.table.floor.isNotEmpty ? widget.table.floor : 'Dining Table',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Network host mode banner
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isLocalhost
                      ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                      : const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isLocalhost
                        ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                        : const Color(0xFF10B981).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isLocalhost ? Icons.warning_amber_rounded : Icons.wifi_rounded,
                      size: 18,
                      color: isLocalhost ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isLocalhost
                            ? 'Warning: "localhost" cannot be opened by mobile phones. Change to Wi-Fi IP to scan.'
                            : 'Mobile Scannable: Using Wi-Fi IP for direct phone camera access.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isLocalhost ? const Color(0xFFEF4444) : const Color(0xFF047857),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _isEditingHost = !_isEditingHost),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          _isEditingHost ? 'DONE' : 'CHANGE IP',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isLocalhost ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_isEditingHost) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _hostController,
                  decoration: InputDecoration(
                    labelText: 'Server Host / Wi-Fi IP Address',
                    labelStyle: const TextStyle(fontSize: 12),
                    hintText: 'http://192.168.0.159:53270',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],

              const SizedBox(height: 14),

              // QR Code Presentation Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _qrImageUrl,
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) {
                          final fallback = 'https://api.qrserver.com/v1/create-qr-code/?size=220x220&data=${Uri.encodeComponent(_orderUrl)}';
                          return Image.network(fallback, width: 200, height: 200);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, size: 14, color: Color(0xFF64748B)),
                        SizedBox(width: 5),
                        Text('Scan with Phone Camera to Order Food', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Ordering Link Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _orderUrl,
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF6366F1)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _orderUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Table ordering link copied to clipboard!'),
                            backgroundColor: Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.copy_rounded, size: 16, color: Color(0xFF6366F1)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final oid = _resolvedOutletId ?? '';
                        Navigator.of(context).pop();
                        context.push('/table-order?outlet_id=$oid&table_id=${widget.table.id}');
                      },
                      icon: const Icon(Icons.restaurant_menu_rounded, size: 16),
                      label: const Text('Open Customer Menu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6366F1),
                        side: const BorderSide(color: Color(0xFF6366F1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final uri = Uri.parse(_qrImageUrl);
                        launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.print_rounded, size: 16),
                      label: const Text('Print Standee', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
