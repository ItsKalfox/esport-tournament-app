import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter/material.dart';

class StripeService {
  static const String _publishableKey =
      'pk_test_51TFI36FovDiZH4SL5c7kkzysskCQLqjEazH7bqDHFlegKvRXGePz5GXq1vcO9V82ZCCQzo25zJXmORaRdrvJK85p00QPgonLDm';

  static void init() {
    Stripe.publishableKey = _publishableKey;
    Stripe.merchantIdentifier = 'esports_store';
  }

  // ── Create Payment Intent via Firebase Cloud Function ─────────────────────
  Future<String?> createPaymentIntent({
    required double amount,
    required String orderId,
    String currency = 'lkr',
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'createPaymentIntent',
      );
      final result = await callable.call({
        'amount': amount,
        'currency': currency,
        'orderId': orderId,
      });
      return result.data['clientSecret'] as String?;
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
      // 1. Get client secret from Firebase Cloud Function
      final clientSecret = await createPaymentIntent(
        amount: amount,
        orderId: orderId,
      );

      if (clientSecret == null) {
        return PaymentResult.failed(
          'Could not initialize payment. Please try again.',
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

      // 3. Present payment sheet
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
