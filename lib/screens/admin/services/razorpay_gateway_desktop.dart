import 'dart:async';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';

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
  HttpServer? server;

  try {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;

    server.listen((HttpRequest request) async {
      final uri = request.uri;
      if (uri.path == '/') {
        request.response
          ..headers.contentType = ContentType.html
          ..write(_generateRazorpayHtml(
            keyId: keyId,
            amount: amount,
            planName: planName,
            orderId: orderId,
            port: port,
            userName: userName ?? 'Restaurant Admin',
            userEmail: userEmail ?? 'admin@sirfbill.com',
            userContact: userContact ?? '9876543210',
          ));
        await request.response.close();
      } else if (uri.path == '/callback') {
        final paymentId = uri.queryParameters['payment_id'] ?? '';
        final rzpOrderId = uri.queryParameters['order_id'] ?? (orderId ?? '');
        final signature = uri.queryParameters['signature'] ?? '';

        request.response
          ..headers.contentType = ContentType.html
          ..write('''
<!DOCTYPE html>
<html>
<head><title>Payment Successful - SirfBill</title><meta charset="utf-8"></head>
<body style="font-family: sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; background: #0F172A; color: white; text-align: center;">
  <div style="background: #1E293B; padding: 40px; border-radius: 16px; border: 1px solid #334155; max-width: 420px;">
    <div style="color: #10B981; font-size: 52px; margin-bottom: 12px;">✓</div>
    <h2 style="margin: 0 0 8px 0;">Payment Authorized!</h2>
    <p style="color: #94A3B8; font-size: 13px; margin: 0 0 16px 0;">Payment Reference: <code style="color: #38BDF8;">$paymentId</code></p>
    <p style="color: #CBD5E1; font-size: 13px;">Your SirfBill Restaurant subscription is now active.<br>You can safely return to the application.</p>
  </div>
</body>
</html>
''');
        await request.response.close();
        if (!completer.isCompleted) {
          completer.complete({
            'payment_id': paymentId,
            'order_id': rzpOrderId,
            'signature': signature,
          });
        }
        await server?.close();
      } else if (uri.path == '/dismiss') {
        request.response
          ..headers.contentType = ContentType.html
          ..write('<html><body><script>window.close();</script>Payment Cancelled</body></html>');
        await request.response.close();
        if (!completer.isCompleted) {
          completer.complete(null);
        }
        await server?.close();
      }
    });

    final checkoutUrl = 'http://127.0.0.1:$port/';
    await launchUrl(Uri.parse(checkoutUrl), mode: LaunchMode.externalApplication);

    Timer(const Duration(minutes: 10), () {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
      server?.close();
    });

    return await completer.future;
  } catch (e) {
    server?.close();
    return null;
  }
}

String _generateRazorpayHtml({
  required String keyId,
  required double amount,
  required String planName,
  String? orderId,
  required int port,
  required String userName,
  required String userEmail,
  required String userContact,
}) {
  final paise = (amount * 100).round();
  final orderField = (orderId != null && orderId.isNotEmpty) ? 'order_id: "$orderId",' : '';

  return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Razorpay Secure Checkout - SirfBill</title>
  <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
</head>
<body style="background: #0C2340; color: white; display: flex; align-items: center; justify-content: center; height: 100vh; font-family: sans-serif; margin: 0;">
  <div style="text-align: center; padding: 20px;">
    <h2>Opening Razorpay Secure Gateway...</h2>
    <p style="color: #94A3B8; font-size: 14px;">Please complete the payment in the official Razorpay window.</p>
  </div>
  <script>
    var rzp = new Razorpay({
      key: "$keyId",
      amount: $paise,
      currency: "INR",
      name: "SirfBill Technologies",
      description: "$planName",
      $orderField
      prefill: {
        name: "$userName",
        email: "$userEmail",
        contact: "$userContact"
      },
      theme: { color: "#0C2340" },
      modal: {
        ondismiss: function() {
          window.location.href = "http://127.0.0.1:$port/dismiss";
        }
      },
      handler: function(response) {
        var url = "http://127.0.0.1:$port/callback?payment_id=" + encodeURIComponent(response.razorpay_payment_id || "");
        if (response.razorpay_order_id) url += "&order_id=" + encodeURIComponent(response.razorpay_order_id);
        if (response.razorpay_signature) url += "&signature=" + encodeURIComponent(response.razorpay_signature);
        window.location.href = url;
      }
    });
    rzp.open();
  </script>
</body>
</html>
''';
}
