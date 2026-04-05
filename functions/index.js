const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const stripe = require("stripe");
const fetch = require("node-fetch");

initializeApp();

// Explicitly define the secret for Stripe
const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");
const groqApiKey = defineSecret("GROQ_API_KEY");

exports.createPaymentIntent = onRequest({
  cors: true,
  secrets: [stripeSecretKey],
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

    // Resolve the secret value at runtime (await to be safe)
    const stripeSecret = await stripeSecretKey.value();
    const stripeClient = stripe(stripeSecret);
    // Log the Stripe account id to help debug account/key mismatches
    try {
      const account = await stripeClient.accounts.retrieve();
      console.log('Stripe account id:', account.id);
    } catch (acctErr) {
      console.warn('Could not retrieve Stripe account id:', acctErr?.message || acctErr);
    }
    console.log('Stripe client initialized');
    console.log('Creating payment intent for amount:', amount, 'currency:', currency);

    const paymentIntent = await stripeClient.paymentIntents.create({
      amount: Math.round(amount * 100),
      currency: currency.toLowerCase(),
      metadata: {
        orderId: orderId || '',
        userId,
      },
      automatic_payment_methods: { enabled: true },
    });

    console.log('Payment intent created:', paymentIntent.id);
    console.log('Client secret prefix:', paymentIntent.client_secret?.substring(0, 20));

    res.json({
      result: {
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
      }
    });
  } catch (error) {
    console.error('Stripe error:', error?.message || error);
    console.error('Full error object:', error);

    // If it's a Stripe error, include its type/code to help debugging
    const stripeError = {
      message: error?.message || 'Unknown error',
      type: error?.type || null,
      code: error?.code || null,
      raw: error?.raw || null,
    };

    const status = (error?.statusCode && Number(error.statusCode)) || 500;
    res.status(status).json({ error: stripeError });
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

  // Ensure GROQ API key secret is available
  const groqKey = await groqApiKey.value();
  if (!groqKey) {
    res.status(500).json({ error: 'GROQ_API_KEY environment variable not configured' });
    return;
  }

  try {
    const message = req.body?.message ?? req.body?.data?.message;

    if (!message || typeof message !== 'string') {
      res.status(400).json({ error: 'Message is required' });
      return;
    }

    const groqResponse = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${groqKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'llama-3.1-8b-instant',
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