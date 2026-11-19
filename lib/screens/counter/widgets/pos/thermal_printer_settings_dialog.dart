import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../utils/bluetooth_thermal_printer_service.dart';
import '../../../../utils/lan_thermal_printer_service.dart';
import '../../../../utils/usb_thermal_printer_service.dart';

/// Modal dialog allowing cashiers to configure their default thermal receipt printer
/// across USB (OTG), LAN (Wi-Fi / Ethernet), and Bluetooth (BT).
class ThermalPrinterSettingsDialog extends StatefulWidget {
  const ThermalPrinterSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const ThermalPrinterSettingsDialog(),
    );
  }

  @override
  State<ThermalPrinterSettingsDialog> createState() => _ThermalPrinterSettingsDialogState();
}

class _ThermalPrinterSettingsDialogState extends State<ThermalPrinterSettingsDialog> {
  // Mode: 'usb', 'lan', 'bt'
  String _mode = 'usb';
  int _paperWidthMm = 80;
  final TextEditingController _ipController = TextEditingController(text: '192.168.1.100');
  String? _selectedBtAddress;

  List<UsbPrinterDevice> _usbList = [];
  List<BluetoothPrinterDevice> _btList = [];
  bool _isTestingLan = false;
  String? _lanStatusMessage;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _mode = prefs.getString('thermal_printer_mode') ?? 'usb';
      _paperWidthMm = prefs.getInt('usb_thermal_paper_width_mm') ?? 80;
      _ipController.text = prefs.getString('thermal_lan_printer_ip') ?? '192.168.1.100';
      _selectedBtAddress = prefs.getString('thermal_bt_printer_address');
    });

    if (UsbThermalPrinterService.isSupported) {
      final usb = await UsbThermalPrinterService.getConnectedPrinters();
      if (mounted) setState(() => _usbList = usb);
    }

    if (BluetoothThermalPrinterService.isSupported) {
      final bt = await BluetoothThermalPrinterService.getPairedPrinters();
      if (mounted) {
        setState(() {
          _btList = bt;
          if (_selectedBtAddress == null && bt.isNotEmpty) {
            _selectedBtAddress = bt.first.address;
          }
        });
      }
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('thermal_printer_mode', _mode);
    await prefs.setInt('usb_thermal_paper_width_mm', _paperWidthMm);
    await prefs.setString('thermal_lan_printer_ip', _ipController.text.trim());
    if (_selectedBtAddress != null) {
      await prefs.setString('thermal_bt_printer_address', _selectedBtAddress!);
    }
    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Printer settings saved successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _testLanConnection() async {
    setState(() {
      _isTestingLan = true;
      _lanStatusMessage = null;
    });
    final success = await LanThermalPrinterService.testConnection(_ipController.text.trim());
    if (mounted) {
      setState(() {
        _isTestingLan = false;
        _lanStatusMessage = success
            ? 'Connected successfully to printer on Port 9100!'
            : 'Connection failed. Check printer IP & Wi-Fi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.print_rounded, color: Color(0xFF10B981), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Thermal Printer Setup',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Connection Mode Tabs (USB, LAN, BT)
              const Text('Connection Mode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _modeButton('USB (OTG)', 'usb', Icons.usb_rounded),
                  const SizedBox(width: 8),
                  _modeButton('LAN (Wi-Fi)', 'lan', Icons.wifi_rounded),
                  const SizedBox(width: 8),
                  _modeButton('Bluetooth', 'bt', Icons.bluetooth_rounded),
                ],
              ),
              const SizedBox(height: 16),

              // Mode-specific configuration view
              if (_mode == 'usb') ...[
                Text(
                  _usbList.isNotEmpty
                      ? 'Detected USB Printer: ${_usbList.first.displayName}'
                      : 'No USB thermal printer detected. Connect via OTG cable.',
                  style: TextStyle(
                    fontSize: 12,
                    color: _usbList.isNotEmpty ? const Color(0xFF10B981) : Colors.orange,
                  ),
                ),
              ] else if (_mode == 'lan') ...[
                const Text('Printer Local IP Address (Port 9100)', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ipController,
                        decoration: InputDecoration(
                          hintText: 'e.g. 192.168.1.100',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isTestingLan ? null : _testLanConnection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isTestingLan
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Test', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                if (_lanStatusMessage != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _lanStatusMessage!,
                    style: TextStyle(
                      fontSize: 11,
                      color: _lanStatusMessage!.contains('success') ? const Color(0xFF10B981) : Colors.redAccent,
                    ),
                  ),
                ],
              ] else if (_mode == 'bt') ...[
                const Text('Paired Bluetooth Thermal Printer', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 6),
                if (_btList.isEmpty)
                  const Text(
                    'No paired Bluetooth printers found. Please pair in Android Settings first.',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  )
                else
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _btList.any((b) => b.address == _selectedBtAddress) ? _selectedBtAddress : _btList.first.address,
                    isDense: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: _btList.map((dev) {
                      return DropdownMenuItem<String>(
                        value: dev.address,
                        child: Text(dev.displayName, style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedBtAddress = val),
                  ),
              ],

              const SizedBox(height: 16),
              // Paper Width
              const Text('Paper Width Roll', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _paperButton('58mm (2 Inch Mini)', 58),
                  const SizedBox(width: 8),
                  _paperButton('80mm (3 Inch Standard)', 80),
                ],
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _savePreferences,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Save & Apply', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeButton(String title, String modeKey, IconData icon) {
    final isSelected = _mode == modeKey;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _mode = modeKey),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
            border: Border.all(
              color: isSelected ? const Color(0xFF10B981) : Colors.grey.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey),
              const SizedBox(height: 3),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paperButton(String title, int widthMm) {
    final isSelected = _paperWidthMm == widthMm;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _paperWidthMm = widthMm),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0D9488) : Colors.transparent,
            border: Border.all(
              color: isSelected ? const Color(0xFF0D9488) : Colors.grey.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
