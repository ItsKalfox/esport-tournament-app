require('dotenv').config();

const express = require('express');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

const app = express();
const PORT = process.env.PORT || 3000;

// ─── Middleware ───────────────────────────────────────────────────────────────
app.use(cors());
app.use('/images', express.static(path.join(__dirname, 'uploads')));

// Raw body for Stripe webhook (must be before express.json())
app.use('/stripe/webhook', express.raw({ type: 'application/json' }));
app.use(express.json());

// ─── Image Upload Config ──────────────────────────────────────────────────────
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const folder = req.params.folder || 'general';
    const dir = path.join(__dirname, 'uploads', folder);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `${uuidv4()}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB max
  fileFilter: (req, file, cb) => {
    const allowed = /jpeg|jpg|png|webp|svg/;
    const ext = allowed.test(path.extname(file.originalname).toLowerCase());
    const mime = allowed.test(file.mimetype);
    if (ext && mime) return cb(null, true);
    cb(new Error('Only image files are allowed'));
  },
});

// ─── Health check ─────────────────────────────────────────────────────────────
app.get('/', (req, res) => {
  res.json({
    status: 'ok',
    message: 'Esports Store Server is running',
    version: '1.0.0',
  });
});

// ─── IMAGE ROUTES ─────────────────────────────────────────────────────────────

// Upload single image
// POST /upload/:folder  (folder = 'products' | 'banners' | 'categories')
app.post('/upload/:folder', upload.single('image'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No image uploaded' });
  }

  const folder = req.params.folder;
  const filename = req.file.filename;
const baseUrl = process.env.BASE_URL || `${req.protocol}://${req.get('host')}`;
  const imageUrl = `${baseUrl}/images/${folder}/${filename}`;

  res.json({
    success: true,
    imageUrl,
    filename,
    folder,
  });
});

// Upload multiple images (up to 5)
// POST /upload-multiple/:folder
app.post('/upload-multiple/:folder', upload.array('images', 5), (req, res) => {
  if (!req.files || req.files.length === 0) {
    return res.status(400).json({ error: 'No images uploaded' });
  }

  const folder = req.params.folder;
  const baseUrl = `${req.protocol}://${req.get('host')}`;
  const imageUrls = req.files.map(
    (file) => `${baseUrl}/images/${folder}/${file.filename}`
  );

  res.json({
    success: true,
    imageUrls,
    count: imageUrls.length,
  });
});

// Delete image
// DELETE /image/:folder/:filename
app.delete('/image/:folder/:filename', (req, res) => {
  const filePath = path.join(
    __dirname,
    'uploads',
    req.params.folder,
    req.params.filename
  );

  if (!fs.existsSync(filePath)) {
    return res.status(404).json({ error: 'Image not found' });
  }

  fs.unlinkSync(filePath);
  res.json({ success: true, message: 'Image deleted' });
});

// ─── STRIPE ROUTES ────────────────────────────────────────────────────────────

// Create Payment Intent
// POST /stripe/create-payment-intent
app.post('/stripe/create-payment-intent', async (req, res) => {
  const { amount, currency = 'lkr', orderId, customerEmail } = req.body;

  if (!amount || amount <= 0) {
    return res.status(400).json({ error: 'Invalid amount' });
  }

  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100), // convert to cents
      currency,
      receipt_email: customerEmail,
      metadata: { orderId: orderId || '' },
      automatic_payment_methods: { enabled: true },
    });

    res.json({
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    });
  } catch (err) {
    console.error('Stripe error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// Stripe Webhook — confirms payment server side
// POST /stripe/webhook
app.post('/stripe/webhook', async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

  let event;
  try {
    event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
  } catch (err) {
    console.error('Webhook error:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  if (event.type === 'payment_intent.succeeded') {
    const pi = event.data.object;
    console.log(`✅ Payment succeeded: ${pi.id} | Order: ${pi.metadata.orderId}`);
  
  }

  if (event.type === 'payment_intent.payment_failed') {
    const pi = event.data.object;
    console.log(`❌ Payment failed: ${pi.id} | Order: ${pi.metadata.orderId}`);
  }

  res.json({ received: true });
});

// ─── Error handler ────────────────────────────────────────────────────────────
app.use((err, req, res, next) => {
  console.error(err.message);
  res.status(500).json({ error: err.message });
});

// ─── Start server ─────────────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`\n🚀 Esports Store Server running at http://localhost:${PORT}`);
  console.log(`📁 Images served from: http://localhost:${PORT}/images/`);
  console.log(`💳 Stripe: ${process.env.STRIPE_SECRET_KEY ? '✅ configured' : '❌ missing STRIPE_SECRET_KEY'}\n`);
});