const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const stripe = require("stripe");
const fetch = require("node-fetch");

initializeApp();

// Explicitly define the secret
const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");
const groqApiKey = defineSecret("GROQ_API_KEY");

exports.createPaymentIntent = onRequest({
  cors: true,
  secrets: [stripeSecretKey],  // ← tell Firebase to inject this secret
}, async (req, res) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    res.status(204).send('');
    return;
  }

  res.set('Access-Control-Allow-Origin', '*');

  try {
    // Verify auth token if provided
    const authHeader = req.headers.authorization;
    let userId = 'guest';

    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split('Bearer ')[1];
      try {
        const decoded = await getAuth().verifyIdToken(token);
        userId = decoded.uid;
      } catch (e) {
        console.log('Token verification failed:', e.message);
      }
    }

    const { data } = req.body;
    const { amount, currency = 'lkr', orderId } = data || req.body;

    if (!amount || amount <= 0) {
      res.status(400).json({ error: 'Invalid amount' });
      return;
    }

    // Use the secret value
    const stripeClient = stripe(stripeSecretKey.value());

    const paymentIntent = await stripeClient.paymentIntents.create({
      amount: Math.round(amount * 100),
      currency,
      metadata: {
        orderId: orderId || '',
        userId,
      },
      automatic_payment_methods: { enabled: true },
    });

    res.json({
      result: {
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
      }
    });
  } catch (error) {
    console.error('Stripe error:', error);
    res.status(500).json({ error: error.message });
  }
});

exports.groqChat = onRequest({
  cors: true,
  secrets: [groqApiKey],
}, async (req, res) => {
  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    res.status(204).send('');
    return;
  }

  res.set('Access-Control-Allow-Origin', '*');

  try {
    const { message } = req.body;

    if (!message || typeof message !== 'string') {
      res.status(400).json({ error: 'Message is required' });
      return;
    }

    const groqResponse = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${groqApiKey.value()}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'llama-3.1-70b-versatile',
        messages: [
          {
            role: 'system',
            content: 'You are a helpful esports assistant for a tournament app. You help users with tournament information, gaming strategies, team info, and general gaming questions. Be friendly and concise.'
          },
          {
            role: 'user',
            content: message
          }
        ],
        temperature: 0.7,
        max_tokens: 1024,
      }),
    });

    if (!groqResponse.ok) {
      const errorData = await groqResponse.text();
      console.error('Groq API error:', errorData);
      throw new Error(`Groq API error: ${groqResponse.status}`);
    }

    const groqData = await groqResponse.json();
    const reply = groqData.choices?.[0]?.message?.content || 'Sorry, I could not generate a response.';

    res.json({ response: reply });
  } catch (error) {
    console.error('Groq chat error:', error);
    res.status(500).json({ error: error.message });
  }
});