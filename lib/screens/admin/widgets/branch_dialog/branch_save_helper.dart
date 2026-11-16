import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/admin_staff_service.dart';
import '../../../../services/shop_service.dart';

class BranchValidationResult {
  final String? errorMessage;
  final int? targetTabIndex;

  const BranchValidationResult({this.errorMessage, this.targetTabIndex});

  bool get isValid => errorMessage == null;
}

class BranchFormInitializer {
  static void populate({
    required Shop b,
    required TextEditingController descriptionCtrl,
    required TextEditingController addressLine1Ctrl,
    required TextEditingController addressLine2Ctrl,
    required TextEditingController cityCtrl,
    required TextEditingController stateCtrl,
    required TextEditingController pinCodeCtrl,
    required TextEditingController countryCtrl,
    required TextEditingController phoneCtrl,
    required TextEditingController emailCtrl,
    required TextEditingController latLngCtrl,
    required TextEditingController openingTimeCtrl,
    required TextEditingController closingTimeCtrl,
    required TextEditingController gstinCtrl,
    required TextEditingController invoicePrefixCtrl,
    required TextEditingController billNumberFormatCtrl,
    required TextEditingController taxRateCtrl,
    required TextEditingController receiptFooterCtrl,
    required TextEditingController fssaiCtrl,
    required TextEditingController upiIdCtrl,
    required TextEditingController bankAccountNameCtrl,
    required TextEditingController bankNameCtrl,
    required TextEditingController bankAccountCtrl,
    required TextEditingController bankIfscCtrl,
    required TextEditingController bankBranchCtrl,
    required TextEditingController maxDiscountLimitCtrl,
    required TextEditingController maxRefundLimitCtrl,
    required List<String> assignedStaff,
  }) {
    final raw = b.rawJson ?? {};
    final extra = (raw['extra_data'] is Map<String, dynamic>)
        ? raw['extra_data'] as Map<String, dynamic>
        : <String, dynamic>{};

    descriptionCtrl.text = extra['description'] ?? raw['description'] ?? '';

    addressLine1Ctrl.text = extra['address_line1'] ?? raw['address_line1'] ?? b.location;
    addressLine2Ctrl.text = extra['address_line2'] ?? raw['address_line2'] ?? '';
    cityCtrl.text = extra['city'] ?? raw['city'] ?? b.city;
    stateCtrl.text = extra['state'] ?? raw['state'] ?? stateCtrl.text;
    pinCodeCtrl.text = extra['pin_code']?.toString() ?? raw['pin_code']?.toString() ?? '';
    countryCtrl.text = extra['country'] ?? raw['country'] ?? countryCtrl.text;
    phoneCtrl.text = b.contact.replaceAll('+91 ', '').trim();
    emailCtrl.text = extra['email'] ?? raw['email'] ?? '';
    latLngCtrl.text = extra['lat_lng'] ?? raw['lat_lng'] ?? '';

    openingTimeCtrl.text = b.openingTime ?? extra['opening_time'] ?? raw['opening_time'] ?? openingTimeCtrl.text;
    closingTimeCtrl.text = b.closingTime ?? extra['closing_time'] ?? raw['closing_time'] ?? closingTimeCtrl.text;

    gstinCtrl.text = b.gstin ?? extra['gstin'] ?? raw['gstin'] ?? '';
    invoicePrefixCtrl.text = b.invoicePrefix ?? extra['invoice_prefix'] ?? raw['invoice_prefix'] ?? invoicePrefixCtrl.text;
    billNumberFormatCtrl.text = extra['bill_number_format'] ?? raw['bill_number_format'] ?? billNumberFormatCtrl.text;
    if (b.taxRate != null) {
      taxRateCtrl.text = b.taxRate.toString();
    } else if (extra['tax_rate'] != null || raw['tax_rate'] != null) {
      taxRateCtrl.text = (extra['tax_rate'] ?? raw['tax_rate']).toString();
    }
    receiptFooterCtrl.text = extra['receipt_footer'] ?? raw['receipt_footer'] ?? receiptFooterCtrl.text;
    fssaiCtrl.text = b.fssai ?? extra['fssai'] ?? raw['fssai'] ?? '';
    upiIdCtrl.text = extra['upi_id'] ?? raw['upi_id'] ?? '';
    bankAccountNameCtrl.text = b.bankAccountName ?? extra['bank_account_name'] ?? raw['bank_account_name'] ?? extra['ac_holder_name'] ?? '';
    bankNameCtrl.text = extra['bank_name'] ?? raw['bank_name'] ?? '';
    bankAccountCtrl.text = extra['bank_account'] ?? raw['bank_account'] ?? extra['account_number'] ?? '';
    bankIfscCtrl.text = extra['bank_ifsc'] ?? raw['bank_ifsc'] ?? extra['ifsc_code'] ?? '';
    bankBranchCtrl.text = extra['bank_branch'] ?? raw['bank_branch'] ?? '';

    if (extra['assigned_staff'] is List) {
      assignedStaff.clear();
      assignedStaff.addAll(List<String>.from(extra['assigned_staff']));
    } else if (raw['assigned_staff'] is List) {
      assignedStaff.clear();
      assignedStaff.addAll(List<String>.from(raw['assigned_staff']));
    }
    if (extra['max_discount_limit'] != null || raw['max_discount_limit'] != null) {
      maxDiscountLimitCtrl.text = (extra['max_discount_limit'] ?? raw['max_discount_limit']).toString();
    }
    if (extra['max_refund_limit'] != null || raw['max_refund_limit'] != null) {
      maxRefundLimitCtrl.text = (extra['max_refund_limit'] ?? raw['max_refund_limit']).toString();
    }
  }
}

class BranchSaveHelper {
  static BranchValidationResult validate({
    required String name,
    required String addressLine1,
    required String city,
    required String rawPhone,
    required String gstStatus,
    required String gstin,
    required String fssai,
  }) {
    if (name.isEmpty) {
      return const BranchValidationResult(
        errorMessage: 'Please provide Outlet Name in Section 01.',
        targetTabIndex: 0,
      );
    }
    if (addressLine1.isEmpty || city.isEmpty) {
      return const BranchValidationResult(
        errorMessage: 'Please provide Address Line 1 and City in Section 02.',
        targetTabIndex: 1,
      );
    }
    if (rawPhone.length != 10) {
      return const BranchValidationResult(
        errorMessage: 'Please enter a valid 10-digit Outlet Phone number in Section 02.',
        targetTabIndex: 1,
      );
    }

    if (gstStatus.contains('Registered') || gstStatus.contains('Composition')) {
      if (gstin.isEmpty) {
        return const BranchValidationResult(
          errorMessage: 'Please provide the 15-digit GSTIN number in Section 04.',
          targetTabIndex: 3,
        );
      }
    }
    if (gstin.isNotEmpty) {
      final gstinRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
      if (gstin.length != 15) {
        return BranchValidationResult(
          errorMessage: 'GSTIN must be exactly 15 characters long in Section 04. Current length: ${gstin.length}',
          targetTabIndex: 3,
        );
      } else if (!gstinRegex.hasMatch(gstin)) {
        return const BranchValidationResult(
          errorMessage: 'Invalid GSTIN format in Section 04. Expected standard 15-character format (e.g. 19AAAAA0000A1Z5).',
          targetTabIndex: 3,
        );
      }
    }

    if (fssai.isNotEmpty) {
      if (fssai.length != 14 || !RegExp(r'^[0-9]{14}$').hasMatch(fssai)) {
        return BranchValidationResult(
          errorMessage: 'FSSAI Licence Number must be exactly 14 numeric digits in Section 04. Current length: ${fssai.length}',
          targetTabIndex: 3,
        );
      }
    }

    return const BranchValidationResult();
  }

  static Map<String, dynamic> buildExtraData({
    required String outletType,
    required String description,
    required String addressLine1,
    required String addressLine2,
    required String state,
    required String pinCode,
    required String country,
    required String email,
    required String latLng,
    required String timeZone,
    required String currency,
    required String openingTime,
    required String closingTime,
    required String weeklyClosing,
    required bool enableDineIn,
    required bool enableTakeaway,
    required bool enableDelivery,
    required String gstStatus,
    required String gstin,
    required String invoicePrefix,
    required String billNumberFormat,
    required double taxRate,
    required String rounding,
    required String receiptFooter,
    required String fssai,
    required String upiId,
    required String bankAccountName,
    required String bankName,
    required String bankAccount,
    required String bankIfsc,
    required String bankBranch,
    required String? managerId,
    required List<String> assignedStaff,
    required bool allowMultiOutlet,
    required double maxDiscountLimit,
    required double maxRefundLimit,
    required String? logoUrl,
  }) {
    return <String, dynamic>{
      'outlet_type': outletType,
      'description': description,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'state': state,
      'pin_code': pinCode,
      'country': country,
      'email': email,
      'lat_lng': latLng,
      'time_zone': timeZone,
      'currency': currency,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'weekly_closing': weeklyClosing,
      'enable_dine_in': enableDineIn,
      'enable_takeaway': enableTakeaway,
      'enable_delivery': enableDelivery,
      'gst_status': gstStatus,
      'gstin': gstin,
      'invoice_prefix': invoicePrefix,
      'bill_number_format': billNumberFormat,
      'tax_rate': taxRate,
      'rounding': rounding,
      'receipt_footer': receiptFooter,
      'fssai': fssai,
      'upi_id': upiId,
      'bank_account_name': bankAccountName,
      'bank_name': bankName,
      'bank_account': bankAccount,
      'bank_ifsc': bankIfsc,
      'bank_branch': bankBranch,
      'manager_id': managerId,
      'assigned_staff': assignedStaff,
      'allow_multi_outlet': allowMultiOutlet,
      'max_discount_limit': maxDiscountLimit,
      'max_refund_limit': maxRefundLimit,
      'logo_url': logoUrl,
    };
  }

  static Future<void> saveBranch({
    required Shop? existingBranch,
    required String name,
    required String code,
    required String formattedAddress,
    required String city,
    required String formattedPhone,
    required String status,
    required bool isPrimary,
    required Map<String, dynamic> extraData,
  }) async {
    if (existingBranch != null) {
      await ShopService.updateShop(
        id: existingBranch.id,
        name: name,
        code: code.isNotEmpty ? code : existingBranch.code,
        address: formattedAddress,
        city: city,
        contactNumber: formattedPhone,
        status: status,
        isPrimary: isPrimary,
        extraData: extraData,
      );
    } else {
      final newShop = await ShopService.createShop(
        name: name,
        code: code.isNotEmpty
            ? code
            : 'OUT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        address: formattedAddress,
        city: city,
        contactNumber: formattedPhone,
        status: status,
        isPrimary: isPrimary,
        extraData: extraData,
      );

      // Automatically provision station logins for POS, Kitchen, Inventory, CRM, Waiter
      final cleanCode = newShop.code.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
      final stations = [
        {'key': 'pos', 'role': 'cashier', 'user': 'pos_$cleanCode@sirfbill.com', 'title': 'POS Cashier'},
        {'key': 'kitchen', 'role': 'chef', 'user': 'kitchen_$cleanCode@sirfbill.com', 'title': 'Kitchen KDS'},
        {'key': 'inventory', 'role': 'inventory', 'user': 'inventory_$cleanCode@sirfbill.com', 'title': 'Inventory Manager'},
        {'key': 'crm', 'role': 'manager', 'user': 'crm_$cleanCode@sirfbill.com', 'title': 'Store CRM & Reports'},
        {'key': 'waiter', 'role': 'waiter', 'user': 'waiter_$cleanCode@sirfbill.com', 'title': 'Waiter Captain'},
      ];

      final prefs = await SharedPreferences.getInstance();
      final outletPrefix = 'outlet_cred_${newShop.id}_';

      for (final station in stations) {
        try {
          await prefs.setString('$outletPrefix${station['key']}_user', station['user']!);
          await prefs.setString('$outletPrefix${station['key']}_pass', '123456');

          await AdminStaffService.createStaffUser(
            username: station['user']!,
            password: '123456',
            name: '${newShop.name} ${station['title']}',
            role: station['role']!,
            branchId: newShop.id,
          );
        } catch (_) {
          // Silently continue if backend already provisions or stores locally
        }
      }
    }
  }
}
