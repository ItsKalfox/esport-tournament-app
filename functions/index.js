const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const stripe = require("stripe");

initializeApp();

exports.createPaymentIntent = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be logged in to make a payment.");
  }

  const { amount, currency = "lkr", orderId } = request.data;

  if (!amount || amount <= 0) {
    throw new HttpsError("invalid-argument", "Invalid payment amount.");
  }

  const stripeClient = stripe(process.env.STRIPE_SECRET_KEY);

  try {
    const paymentIntent = await stripeClient.paymentIntents.create({
      amount: Math.round(amount * 100),
      currency,
      metadata: {
        orderId: orderId || "",
        userId: request.auth.uid,
      },
      automatic_payment_methods: { enabled: true },
    });

    return {
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    };
  } catch (error) {
    console.error("Stripe error:", error);
    throw new HttpsError("internal", error.message);
  }
});