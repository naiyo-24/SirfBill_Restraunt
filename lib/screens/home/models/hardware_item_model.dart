import 'package:flutter/material.dart';

class HardwareProductItem {
  final String title;
  final String category;
  final String description;
  final String tag;
  final IconData icon;
  final Color accentColor;
  final List<String> specs;

  const HardwareProductItem({
    required this.title,
    required this.category,
    required this.description,
    required this.tag,
    required this.icon,
    required this.accentColor,
    required this.specs,
  });
}

const List<HardwareProductItem> kCertifiedHardwareProducts = [
  HardwareProductItem(
    title: '80mm Thermal KOT & Bill Printer',
    category: 'Printers',
    description: 'Ultra-fast auto-cutter thermal printer with high-speed dispatch for kitchen KOTs and counter bills.',
    tag: 'Best Seller',
    icon: Icons.print_rounded,
    accentColor: Color(0xFF10B981),
    specs: [
      '250mm/s High Speed Printing',
      'USB + LAN (Ethernet) + Bluetooth',
      'Auto-Cutter (1.5 Million Cuts)',
      '100% Plug & Play with SirfBill POS',
    ],
  ),
  HardwareProductItem(
    title: 'All-in-One Dual-Screen Touch POS',
    category: 'POS Terminals',
    description: 'Heavy-duty 15.6" capacitive touchscreen terminal with customer-facing display for billing & orders.',
    tag: 'Flagship',
    icon: Icons.point_of_sale_rounded,
    accentColor: Color(0xFF3B82F6),
    specs: [
      '15.6" Main Touch + 11.6" Guest Screen',
      'Intel / Android High-Performance CPU',
      'Spill & Dust Resistant Restaurant Grade',
      'Pre-installed with SirfBill Restaurant',
    ],
  ),
  HardwareProductItem(
    title: 'Smart Handheld Waiter POS Device',
    category: 'Handhelds',
    description: 'Pocket wireless Android POS with built-in 58mm printer for instant table billing and captain ordering.',
    tag: 'High Mobility',
    icon: Icons.phone_android_rounded,
    accentColor: Color(0xFFF59E0B),
    specs: [
      '5.5" HD Touchscreen Display',
      'Integrated 58mm Thermal Printer',
      'Dual-Band WiFi & 4G SIM Card Support',
      'All-Day 5200mAh Shift Battery',
    ],
  ),
  HardwareProductItem(
    title: 'Heavy-Duty Electronic Cash Drawer',
    category: 'Cash Drawers',
    description: 'Reinforced steel cash drawer with auto-kick RJ11 connector triggered upon bill settlement.',
    tag: 'Secure & Sturdy',
    icon: Icons.archive_rounded,
    accentColor: Color(0xFF8B5CF6),
    specs: [
      '5 Bill Compartments & 8 Coin Slots',
      'RJ11 Auto-Trigger from Thermal Printer',
      '3-Position Key Lock (Manual / Auto)',
      'Heavy-Duty Stainless Steel Roller Rails',
    ],
  ),
  HardwareProductItem(
    title: '2D Hands-Free Barcode & QR Scanner',
    category: 'Scanners',
    description: 'Omnidirectional desktop scanner for rapid QR payments, table token scans, and stock barcode input.',
    tag: 'High Speed',
    icon: Icons.qr_code_scanner_rounded,
    accentColor: Color(0xFFEC4899),
    specs: [
      'Reads 1D & 2D QR Codes on Paper & Screens',
      'Automatic Motion Sensor Trigger',
      'USB Plug & Play with Zero Drivers',
      'Wide Angle 360-Degree Read Range',
    ],
  ),
  HardwareProductItem(
    title: 'Waterproof Kitchen KDS Touch Screen',
    category: 'Kitchen KDS',
    description: 'Wall-mountable high-brightness kitchen monitor built to withstand heat, steam, and oil fumes.',
    tag: 'Kitchen Grade',
    icon: Icons.soup_kitchen_rounded,
    accentColor: Color(0xFFF97316),
    specs: [
      'IP65 Waterproof & Grease-Proof Front',
      '15.6" Full HD Anti-Glare Touch Panel',
      'Standard VESA Wall / Ceiling Mountable',
      'Buzzer Alert on Incoming KOT Orders',
    ],
  ),
];
