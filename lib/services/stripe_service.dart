import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter/material.dart';

class StripeService {
  static const String _publishableKey =
      'pk_test_51TFI36FovDiZH4SL5c7kkzysskCQLqjEazH7bqDHFlegKvRXGePz5GXq1vcO9V82ZCCQzo25zJXmORaRdrvJK85p00QPgonLDm';

  // 🔧 Change this to your server URL when deploying to Render.com
  // Local development (real device): 'http://YOUR_PC_IP:3000'
  // Local development (emulator):    'http://10.0.2.2:3000'
  // Production:                       'https://your-app.onrender.com'
  static const String _serverUrl = 'http://192.168.8.100:3000';

  static void init() {
    Stripe.publishableKey = _publishableKey;
    Stripe.merchantIdentifier = 'esports_store';
  }

  // ── Create Payment Intent via Express server ──────────────────────────────
  Future<String?> createPaymentIntent({
    required double amount,
    required String orderId,
    required String customerEmail,
    String currency = 'lkr',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_serverUrl/stripe/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount,
          'currency': currency,
          'orderId': orderId,
          'customerEmail': customerEmail,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['clientSecret'] as String?;
      } else {
        debugPrint('Server error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error creating payment intent: $e');
      return null;
    }
  }

  // ── Present Stripe Payment Sheet ──────────────────────────────────────────
  Future<PaymentResult> presentPaymentSheet({
    required double amount,
    required String orderId,
    required String customerEmail,
  }) async {
    try {
      // 1. Get client secret from Express server
      final clientSecret = await createPaymentIntent(
        amount: amount,
        orderId: orderId,
        customerEmail: customerEmail,
      );

      if (clientSecret == null) {
        return PaymentResult.failed(
          'Could not connect to payment server. Please try again.',
        );
      }

      // 2. Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Esports Store',
          style: ThemeMode.dark,
          returnURL: 'esports://stripe-redirect',
          billingDetails: BillingDetails(email: customerEmail),
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFFF0A500),
              background: Color(0xFF161616),
              componentBackground: Color(0xFF1A1A1A),
              componentText: Colors.white,
              primaryText: Colors.white,
              secondaryText: Color(0xFF999999),
              placeholderText: Color(0xFF555555),
              icon: Color(0xFFF0A500),
              componentBorder: Color(0xFF2A2A2A),
            ),
            shapes: PaymentSheetShape(borderRadius: 10),
          ),
          billingDetailsCollectionConfiguration:
              const BillingDetailsCollectionConfiguration(
                name: CollectionMode.automatic,
                email: CollectionMode.automatic,
              ),
        ),
      );

      // 3. Present payment sheet to user
      await Stripe.instance.presentPaymentSheet();

      return PaymentResult.success(clientSecret);
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return PaymentResult.cancelled();
      }
      return PaymentResult.failed(e.error.localizedMessage ?? 'Payment failed');
    } catch (e) {
      debugPrint('Payment error: $e');
      return PaymentResult.failed('Something went wrong. Please try again.');
    }
  }

  // ── Upload image to Express server ────────────────────────────────────────
  static Future<String?> uploadImage({
    required List<int> imageBytes,
    required String filename,
    required String folder, // 'products' | 'banners' | 'categories'
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_serverUrl/upload/$folder'),
      );
      request.files.add(
        http.MultipartFile.fromBytes('image', imageBytes, filename: filename),
      );
      final response = await request.send();
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body);
      return data['imageUrl'] as String?;
    } catch (e) {
      debugPrint('Image upload error: $e');
      return null;
    }
  }
}

// ── Payment Result ────────────────────────────────────────────────────────────
class PaymentResult {
  final PaymentStatus status;
  final String? clientSecret;
  final String? errorMessage;

  PaymentResult._({required this.status, this.clientSecret, this.errorMessage});

  factory PaymentResult.success(String clientSecret) => PaymentResult._(
    status: PaymentStatus.success,
    clientSecret: clientSecret,
  );

  factory PaymentResult.failed(String message) =>
      PaymentResult._(status: PaymentStatus.failed, errorMessage: message);

  factory PaymentResult.cancelled() =>
      PaymentResult._(status: PaymentStatus.cancelled);

  bool get isSuccess => status == PaymentStatus.success;
  bool get isCancelled => status == PaymentStatus.cancelled;
  bool get isFailed => status == PaymentStatus.failed;
}

enum PaymentStatus { success, failed, cancelled }
