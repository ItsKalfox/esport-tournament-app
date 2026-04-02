const functions = require("firebase-functions");
const admin = require("firebase-admin");
const stripe = require("stripe");

admin.initializeApp();

// 🔑 Add your Stripe SECRET key in Firebase environment config
// Run: firebase functions:secrets:set STRIPE_SECRET_KEY
// Then paste your sk_test_... key when prompted
const getStripe = () => stripe(process.env.STRIPE_SECRET_KEY);

// ── Create Payment Intent ─────────────────────────────────────────────────────
exports.createPaymentIntent = functions.https.onCall(async (data, context) => {
  // Require authenticated user
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "You must be logged in to make a payment."
    );
  }

  const { amount, currency = "lkr", orderId } = data;

  if (!amount || amount <= 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Invalid payment amount."
    );
  }

  try {
    const paymentIntent = await getStripe().paymentIntents.create({
      amount: Math.round(amount * 100), // Stripe uses smallest currency unit (cents)
      currency,
      metadata: {
        orderId: orderId || "",
        userId: context.auth.uid,
      },
      automatic_payment_methods: { enabled: true },
    });

    return {
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    };
  } catch (error) {
    console.error("Stripe error:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

// ── Stripe Webhook (optional - confirms payment server-side) ──────────────────
exports.stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers["stripe-signature"];
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

  let event;
  try {
    event = getStripe().webhooks.constructEvent(
      req.rawBody,
      sig,
      webhookSecret
    );
  } catch (err) {
    console.error("Webhook signature error:", err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Handle payment confirmed
  if (event.type === "payment_intent.succeeded") {
    const paymentIntent = event.data.object;
    const orderId = paymentIntent.metadata.orderId;

    if (orderId) {
      await admin.firestore().collection("orders").doc(orderId).update({
        status: "processing",
        paymentStatus: "paid",
        paymentIntentId: paymentIntent.id,
        paidAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }

  // Handle payment failed
  if (event.type === "payment_intent.payment_failed") {
    const paymentIntent = event.data.object;
    const orderId = paymentIntent.metadata.orderId;

    if (orderId) {
      await admin.firestore().collection("orders").doc(orderId).update({
        status: "cancelled",
        paymentStatus: "failed",
      });
    }
  }

  res.json({ received: true });
});