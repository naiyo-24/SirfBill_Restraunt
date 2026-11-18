// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
// ignore: deprecated_member_use
import 'dart:html' as html;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> _ensureRazorpayReady() async {
  // 1. Ensure official checkout.js is in DOM
  if (html.document.querySelector('script[src*="checkout.razorpay.com"]') == null) {
    final script = html.ScriptElement()
      ..src = 'https://checkout.razorpay.com/v1/checkout.js'
      ..type = 'text/javascript';
    html.document.head?.children.add(script);
    await script.onLoad.first;
  }

  // 2. Fallback dynamic DOM listener in case index.html was cached by Chrome
  if (html.document.getElementById('sirfbill_rzp_dynamic_bridge') == null) {
    final inlineScript = html.ScriptElement()
      ..id = 'sirfbill_rzp_dynamic_bridge'
      ..text = '''
      (function() {
        if (window._sirfbill_bridge_ready) return;
        window._sirfbill_bridge_ready = true;
        window.addEventListener('sirfbill_launch_razorpay', function(e) {
          try {
            var raw = e.detail;
            var options = {};
            if (typeof raw === 'string') {
              try { options = JSON.parse(raw); } catch (pErr) { options = {}; }
            } else if (raw && typeof raw === 'object') {
              options = raw;
            }
            if (!window.Razorpay) {
              window.dispatchEvent(new CustomEvent('sirfbill_razorpay_dismiss', {
                detail: JSON.stringify({ error: 'Razorpay SDK not loaded' })
              }));
              return;
            }
            var key = (options.key && String(options.key).trim().length > 0)
              ? String(options.key).trim()
              : 'rzp_live_ReRSf5hDkv7b7S';
            var parsedAmount = Number(options.amount) || 299;
            var paise = Math.round(parsedAmount * 100);

            var rzp = new window.Razorpay({
              key: key,
              amount: paise,
              currency: options.currency || 'INR',
              name: options.name || 'SirfBill Technologies',
              description: options.description || 'SirfBill Restaurant Pro License',
              image: options.image || 'favicon.png',
              order_id: (options.orderId && String(options.orderId).trim().length > 0) ? String(options.orderId).trim() : undefined,
              prefill: {
                name: options.userName || 'Restaurant Admin',
                email: options.userEmail || 'admin@sirfbill.com',
                contact: options.userContact || '9876543210'
              },
              theme: { color: options.themeColor || '#0C2340' },
              modal: {
                backdropclose: false,
                escape: true,
                ondismiss: function() {
                  window.dispatchEvent(new CustomEvent('sirfbill_razorpay_dismiss'));
                }
              },
              handler: function(response) {
                window.dispatchEvent(new CustomEvent('sirfbill_razorpay_success', {
                  detail: JSON.stringify({
                    payment_id: response.razorpay_payment_id || '',
                    order_id: response.razorpay_order_id || (options.orderId || ''),
                    signature: response.razorpay_signature || ''
                  })
                }));
              }
            });
            rzp.on('payment.failed', function(resp) {
              var desc = (resp && resp.error && resp.error.description) ? resp.error.description : 'Failed';
              window.dispatchEvent(new CustomEvent('sirfbill_razorpay_dismiss', {
                detail: JSON.stringify({ error: desc })
              }));
            });
            rzp.open();
          } catch (err) {
            window.dispatchEvent(new CustomEvent('sirfbill_razorpay_dismiss', {
              detail: JSON.stringify({ error: String(err) })
            }));
          }
        });
      })();
      ''';
    html.document.head?.children.add(inlineScript);
  }
}

Future<Map<String, String>?> launchOfficialRazorpay({
  required double amount,
  required String planName,
  String? orderId,
  String? userName,
  String? userEmail,
  String? userContact,
}) async {
  final keyId = dotenv.env['RAZORPAY_KEY_ID']?.trim().isNotEmpty == true
      ? dotenv.env['RAZORPAY_KEY_ID']!.trim()
      : 'rzp_live_ReRSf5hDkv7b7S';
  final completer = Completer<Map<String, String>?>();

  await _ensureRazorpayReady();

  StreamSubscription? successSub;
  StreamSubscription? dismissSub;

  void cleanup() {
    successSub?.cancel();
    dismissSub?.cancel();
  }

  successSub = html.window.on['sirfbill_razorpay_success'].listen((html.Event e) {
    cleanup();
    if (!completer.isCompleted) {
      if (e is html.CustomEvent && e.detail != null) {
        try {
          final detail = e.detail;
          Map<String, dynamic> data = {};
          if (detail is String) {
            data = Map<String, dynamic>.from(jsonDecode(detail) as Map);
          } else if (detail is Map) {
            data = Map<String, dynamic>.from(detail);
          }
          completer.complete({
            'payment_id': data['payment_id']?.toString() ?? '',
            'order_id': data['order_id']?.toString() ?? '',
            'signature': data['signature']?.toString() ?? '',
          });
          return;
        } catch (_) {}
      }
      completer.complete({'payment_id': 'pay_verified'});
    }
  });

  dismissSub = html.window.on['sirfbill_razorpay_dismiss'].listen((html.Event e) {
    cleanup();
    if (!completer.isCompleted) {
      completer.complete(null);
    }
  });

  final eventData = {
    'key': keyId,
    'amount': amount,
    'name': 'SirfBill Technologies',
    'description': planName,
    if (orderId != null && orderId.isNotEmpty) 'orderId': orderId,
    'userName': userName ?? 'Restaurant Admin',
    'userEmail': userEmail ?? 'admin@sirfbill.com',
    'userContact': userContact ?? '9876543210',
    'themeColor': '#0C2340',
  };

  html.window.dispatchEvent(html.CustomEvent(
    'sirfbill_launch_razorpay',
    detail: jsonEncode(eventData),
  ));

  Timer(const Duration(minutes: 10), () {
    cleanup();
    if (!completer.isCompleted) {
      completer.complete(null);
    }
  });

  return completer.future;
}
