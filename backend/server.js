require('dotenv').config();
const dns = require('dns');
if (dns.setDefaultResultOrder) {
  dns.setDefaultResultOrder('ipv4first');
}
const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');
const multer = require('multer');
const connectDB = require('./config/db');

// Models
const OtpVerification = require('./models/OtpVerification');
const User = require('./models/User');
const Profile = require('./models/Profile');
const nodemailer = require('nodemailer');
const MatrimonialProfile = require('./models/MatrimonialProfile');
const { MatrimonialRequest, MatrimonialShortlist, MatrimonialEvent, SuccessStory } = require('./models/MatrimonialCollections');

// Self-healing database sync to copy users between 'users' and 'directory' collections (using email)
const syncCollections = async () => {
  try {
    const dirUsers = await User.DirectoryUser.find({});
    for (const dirUser of dirUsers) {
      if (!dirUser.email) continue;
      const exists = await User.findOne({ email: dirUser.email.toLowerCase().trim() });
      if (!exists) {
        console.log(`Sync: Copying ${dirUser.fullName} to 'users' collection...`);
        const newUser = new User({
          fullName: dirUser.fullName,
          email: dirUser.email.toLowerCase().trim(),
        });
        await newUser.save();
      }
    }
    console.log('Sync: Collections synchronization complete.');
  } catch (err) {
    console.error('Error in syncCollections:', err);
  }
};

mongoose.connection.once('open', async () => {
  console.log('MongoDB connection open. Running collections sync and matrimonial seeding...');
  await syncCollections();
  await seedMatrimonialData();
});
const Campaign = require('./models/Campaign');
const CampaignCategory = require('./models/CampaignCategory');
const CampaignRegistration = require('./models/CampaignRegistration');
const Notification = require('./models/Notification');

const app = express();

// Connect to MongoDB setup in startServer()


// Ensure upload directory exists
const uploadDir = path.join(__dirname, 'uploads', 'campaigns');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Middleware
app.use(cors());
app.use(express.json({ limit: '100mb' }));
app.use(express.urlencoded({ limit: '100mb', extended: true }));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Logger middleware for debugging request inputs
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// Welcome root route
app.get('/', (req, res) => {
  res.json({
    message: 'KutumbSetu Backend REST API is running!',
    timestamp: new Date().toISOString(),
    env_diagnostics: {
      SMTP_HOST_SET: !!process.env.SMTP_HOST,
      SMTP_PORT_SET: !!process.env.SMTP_PORT,
      SMTP_SECURE_SET: !!process.env.SMTP_SECURE,
      SMTP_USER_SET: !!process.env.SMTP_USER,
      SMTP_PASS_SET: !!process.env.SMTP_PASS,
      SMTP_HOST: process.env.SMTP_HOST || 'smtp.ethereal.email (fallback)',
      SMTP_PORT: process.env.SMTP_PORT || 'not-set',
      SMTP_SECURE: process.env.SMTP_SECURE || 'not-set',
      SMTP_USER_MASKED: process.env.SMTP_USER ? `${process.env.SMTP_USER.slice(0, 3)}...${process.env.SMTP_USER.slice(-8)}` : 'none',
      NODE_ENV: process.env.NODE_ENV || 'development'
    }
  });
});

// Helper to build transport configuration dynamically from environment variables
const getTransportConfig = () => {
  const isGmail = (process.env.SMTP_HOST || '').includes('gmail.com');
  // Default to secure SSL port 465 for Gmail on production servers to prevent port 587 blockages
  const defaultPort = isGmail ? 465 : 587;
  const port = parseInt(process.env.SMTP_PORT || defaultPort);
  const secure = process.env.SMTP_SECURE === 'true' || port === 465;

  return {
    host: process.env.SMTP_HOST || 'smtp.ethereal.email',
    port: port,
    secure: secure,
    auth: {
      user: process.env.SMTP_USER || 'test@ethereal.email',
      pass: process.env.SMTP_PASS || 'testpassword',
    },
    tls: {
      rejectUnauthorized: false,
      minVersion: 'TLSv1.2',
    },
  };
};

// Test SMTP connection and return direct error message
app.get('/test-smtp', async (req, res) => {
  try {
    const transportConfig = getTransportConfig();
    const testTransporter = nodemailer.createTransport(transportConfig);
    await testTransporter.verify();
    return res.json({
      success: true,
      message: 'SMTP connection verified successfully!',
      configUsed: {
        host: transportConfig.host,
        port: transportConfig.port,
        secure: transportConfig.secure,
        user: transportConfig.auth.user ? `${transportConfig.auth.user.slice(0, 3)}...${transportConfig.auth.user.slice(-8)}` : 'none'
      }
    });
  } catch (err) {
    return res.status(500).json({
      success: false,
      message: 'SMTP connection failed',
      error: err.message,
      code: err.code,
      command: err.command,
      configAttempted: {
        host: process.env.SMTP_HOST || 'not-set',
        port: process.env.SMTP_PORT || 'not-set',
        secure: process.env.SMTP_SECURE || 'not-set'
      },
      stack: err.stack
    });
  }
});

// Endpoint to retrieve the latest OTP for testing on pre-built APKs
app.get('/api/auth/get-latest-otp/:email', async (req, res) => {
  try {
    const email = req.params.email.toLowerCase().trim();
    const latestOtpDoc = await OtpVerification.findOne({ email });
    if (!latestOtpDoc) {
      return res.status(404).json({ success: false, message: 'No OTP found for this email address.' });
    }
    return res.json({
      success: true,
      email: email,
      otp: latestOtpDoc.otp,
      expiresAt: latestOtpDoc.expiresAt
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Server error retrieving OTP.' });
  }
});

// Nodemailer configuration
const transportConfig = getTransportConfig();
const transporter = nodemailer.createTransport(transportConfig);

// Helper: Send OTP Email
const sendOtpEmail = (email, name, otp) => {
  const emailHtml = `
      <div style="font-family: 'Poppins', 'Inter', sans-serif; max-width: 600px; margin: 0 auto; background-color: #ffffff; border: 1px solid #e2e8f0; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);">
        <!-- Saffron Top Banner -->
        <div style="background: linear-gradient(135deg, #e67e22, #1b4f72); padding: 24px; text-align: center; color: #ffffff;">
          <h1 style="margin: 0; font-size: 28px; font-weight: bold; letter-spacing: 1px;">KutumbSetu</h1>
          <p style="margin: 4px 0 0 0; font-size: 14px; opacity: 0.9;">कुटुम्बસેતુ • Family & Community Network</p>
        </div>
        
        <!-- Email Body -->
        <div style="padding: 32px; color: #1a202c; line-height: 1.6;">
          <h2 style="margin-top: 0; font-size: 20px; font-weight: 700; color: #1b4f72;">Hello ${name || 'User'},</h2>
          <p style="font-size: 15px; margin-bottom: 24px;">Please use the secure One-Time Password (OTP) below to complete your authentication. This code is valid for <strong>5 minutes</strong>.</p>
          
          <!-- OTP Display Box -->
          <div style="text-align: center; margin: 32px 0;">
            <div style="display: inline-block; padding: 16px 40px; background-color: #fff8e7; border: 2px dashed #e67e22; border-radius: 12px;">
              <span style="font-size: 36px; font-weight: 800; letter-spacing: 6px; color: #e67e22; font-family: monospace;">${otp}</span>
            </div>
          </div>
          
          <p style="font-size: 13px; color: #718096; margin-bottom: 24px;"><em>Security Warning: If you did not request this OTP, please ignore this email or contact support if you suspect unauthorized access. Do not share this OTP code with anyone.</em></p>
          
          <hr style="border: 0; border-top: 1px solid #edf2f7; margin: 24px 0;" />
          
          <p style="font-size: 12px; color: #a0aec0; text-align: center; margin: 0;">This is an automated system message. Please do not reply directly to this email.</p>
        </div>
        
        <!-- Footer -->
        <div style="background-color: #f7fafc; padding: 16px; text-align: center; font-size: 11px; color: #718096; border-top: 1px solid #edf2f7;">
          © 2026 KutumbSetu Community Management System. All rights reserved.
        </div>
      </div>
    `;

  const resendApiKey = process.env.RESEND_API_KEY;

  if (resendApiKey) {
    // Send email using Resend API over HTTPS (Bypasses Render's port blockage)
    const https = require('https');
    
    const postData = JSON.stringify({
      from: 'KutumbSetu <onboarding@resend.dev>',
      to: email.toLowerCase().trim(),
      subject: 'KutumbSetu - Your Email Verification OTP',
      html: emailHtml
    });

    const options = {
      hostname: 'api.resend.com',
      path: '/emails',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${resendApiKey}`,
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        if (res.statusCode === 200 || res.statusCode === 201) {
          console.log(`[Resend SUCCESS] OTP email sent to ${email} (StatusCode: ${res.statusCode})`);
        } else {
          console.error(`[Resend ERROR] Failed to send email (StatusCode: ${res.statusCode}):`, data);
        }
      });
    });

    req.on('error', (e) => {
      console.error('[Resend Request Error] Failed to send email:', e);
    });

    req.write(postData);
    req.end();
  } else {
    // Fallback to standard SMTP Nodemailer config (Local testing)
    const mailOptions = {
      from: '"KutumbSetu Portal" <no-reply@kutumbsetu.org>',
      to: email.toLowerCase().trim(),
      subject: 'KutumbSetu - Your Email Verification OTP',
      html: emailHtml
    };

    transporter.sendMail(mailOptions, (error, info) => {
      if (error) {
        console.error(`[Nodemailer ERROR] Failed to send OTP to ${email}:`, error);
      } else {
        console.log(`[Nodemailer SUCCESS] OTP email sent to ${email}: ${info.messageId}`);
      }
    });
  }
};

// Configure Multer for File Uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.jpg';
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, `banner-${uniqueSuffix}${ext}`);
  },
});

const fileFilter = (req, file, cb) => {
  const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Unsupported file format. Please upload JPG, PNG, or WEBP images.'), false);
  }
};

const upload = multer({
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: fileFilter,
});

// Seed Initial Categories if Database is Empty
const seedDefaultCategories = async () => {
  try {
    const count = await CampaignCategory.countDocuments();
    if (count === 0) {
      const defaultCategories = [
        { name: 'Blood Donation', slug: 'blood-donation', icon: 'water_drop', description: 'Blood drive and donation drives' },
        { name: 'Education', slug: 'education', icon: 'school', description: 'Education support and student aid' },
        { name: 'Medical Help', slug: 'medical-help', icon: 'local_hospital', description: 'Medical aid and healthcare support' },
        { name: 'Community Welfare', slug: 'community-welfare', icon: 'groups', description: 'Community growth and development' },
        { name: 'Disaster Relief', slug: 'disaster-relief', icon: 'warning', description: 'Emergency and disaster relief' },
        { name: 'Religious/Community Events', slug: 'religious-community-events', icon: 'event', description: 'Cultural and community gatherings' },
        { name: 'Social Cause', slug: 'social-cause', icon: 'volunteer_activism', description: 'Social awareness and upliftment' },
        { name: 'Other', slug: 'other', icon: 'category', description: 'Miscellaneous community initiatives' },
      ];
      await CampaignCategory.insertMany(defaultCategories);
      console.log('Seeded initial campaign categories successfully.');
    }
  } catch (error) {
    console.error('Error seeding categories:', error);
  }
};


// Helper: Generate a random 6-digit OTP
const generateRandomOtp = () => {
  const digits = '0123456789';
  let otp = '';
  for (let i = 0; i < 6; i++) {
    otp += digits[Math.floor(Math.random() * 10)];
  }
  return otp;
};

// Helper: Generate Unique Registration Number
const generateRegistrationNumber = () => {
  const randomNum = Math.floor(100000 + Math.random() * 900000);
  return `KS-REG-${randomNum}`;
};

// ==========================================
// 1. AUTHENTICATION & USER APIS
// ==========================================

/**
 * @route   POST /api/auth/send-email-otp
 * @desc    Generate and save a 6-digit temporary OTP for an email address
 * @access  Public
 */
app.post('/api/auth/send-email-otp', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ success: false, message: 'Email address is required.' });
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ success: false, message: 'Invalid email address format.' });
    }

    const targetEmail = email.toLowerCase().trim();
    const otp = generateRandomOtp();

    // Check rate limit/cooldown
    const latestOtpDoc = await OtpVerification.findOne({ email: targetEmail });
    if (latestOtpDoc) {
      const now = new Date();
      // 1 minute cooldown
      const diffMs = now.getTime() - latestOtpDoc.lastResentAt.getTime();
      if (diffMs < 60 * 1000) {
        return res.status(429).json({ success: false, message: `Please wait ${Math.ceil((60 * 1000 - diffMs) / 1000)} seconds before requesting a new OTP.` });
      }

      // Max 5 resends
      if (latestOtpDoc.resends >= 5) {
        return res.status(429).json({ success: false, message: 'Maximum OTP request limit reached. Please try again after 15 minutes.' });
      }
    }

    const createdAt = new Date();
    const expiresAt = new Date(createdAt.getTime() + 5 * 60 * 1000); // 5 min expiry

    if (latestOtpDoc) {
      latestOtpDoc.otp = otp;
      latestOtpDoc.resends += 1;
      latestOtpDoc.lastResentAt = createdAt;
      latestOtpDoc.expiresAt = expiresAt;
      latestOtpDoc.attempts = 0; // reset attempts
      await latestOtpDoc.save();
    } else {
      const newOtpDoc = new OtpVerification({
        email: targetEmail,
        otp,
        resends: 0,
        lastResentAt: createdAt,
        createdAt,
        expiresAt,
      });
      await newOtpDoc.save();
    }

    console.log(`Saved OTP ${otp} for email ${targetEmail}. Expires at ${expiresAt}`);

    // Asynchronously send the email
    sendOtpEmail(targetEmail, null, otp);

    return res.status(200).json({
      success: true,
      otp: otp, // Return OTP in response so frontend can show a developer dialog if email is blocked/failed
    });
  } catch (error) {
    console.error('Error in send-email-otp:', error);
    return res.status(500).json({ success: false, message: 'Server error. Failed to generate OTP.' });
  }
});

/**
 * @route   POST /api/auth/send-email-otp
 * @desc    Generate and save a 6-digit temporary OTP for an email address
 * @access  Public
 */
app.post('/api/auth/send-email-otp', async (req, res) => {
  try {
    const { phone } = req.body;
    if (!phone) {
      return res.status(400).json({ success: false, message: 'Phone number is required.' });
    }
    
    // Support email-otp redirect if phone is passed as an email address
    if (phone.includes('@')) {
      req.body.email = phone;
      // Handle email OTP generation manually
      const targetEmail = phone.toLowerCase().trim();
      const otp = generateRandomOtp();
      const createdAt = new Date();
      const expiresAt = new Date(createdAt.getTime() + 5 * 60 * 1000);

      let latestOtpDoc = await OtpVerification.findOne({ email: targetEmail });
      if (latestOtpDoc) {
        latestOtpDoc.otp = otp;
        latestOtpDoc.lastResentAt = createdAt;
        latestOtpDoc.expiresAt = expiresAt;
        await latestOtpDoc.save();
      } else {
        latestOtpDoc = new OtpVerification({
          email: targetEmail,
          otp,
          lastResentAt: createdAt,
          createdAt,
          expiresAt,
        });
        await latestOtpDoc.save();
      }
      sendOtpEmail(targetEmail, null, otp);
      return res.status(200).json({ success: true, otp });
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ success: false, message: 'Invalid email address format.' });
    }

    const targetEmail = email.toLowerCase().trim();
    const otp = generateRandomOtp();
    const createdAt = new Date();
    const expiresAt = new Date(createdAt.getTime() + 5 * 60 * 1000); // 5 min expiry

    // Find and delete any previous OTP for the phone to avoid duplicates
    await OtpVerification.deleteMany({ phone: sanitizedPhone });

    const otpDoc = new OtpVerification({
      phone: sanitizedPhone,
      otp,
      createdAt,
      expiresAt,
    });
    await otpDoc.save();

    console.log(`Saved OTP ${otp} for phone ${sanitizedPhone}`);
    return res.status(200).json({ success: true, otp });
  } catch (error) {
    console.error('Error in send-email-otp:', error);
    return res.status(500).json({ success: false, message: 'Server error. Failed to generate OTP.' });
  }
});

// Alias route to preserve old code if referenced
app.post('/api/auth/send-otp', async (req, res) => {
  const { phone } = req.body;
  // If phone looks like an email or if phone is passed, adapt it
  if (phone && phone.includes('@')) {
    req.body.email = phone;
    return app._router.handle({ method: 'POST', url: '/api/auth/send-email-otp', body: req.body }, res);
  }
  // If phone is standard phone number, simulate response for backward-compatibility
  return res.status(200).json({ success: true });
});

/**
 * @route   POST /api/auth/verify-email-otp
 * @desc    Verify email OTP code
 * @access  Public
 */
app.post('/api/auth/verify-email-otp', async (req, res) => {
  try {
    const { email, otp } = req.body;

    if (!email || !otp) {
      return res.status(400).json({ success: false, message: 'Email and OTP code are required.' });
    }

    const targetEmail = email.toLowerCase().trim();
    const latestOtpDoc = await OtpVerification.findOne({ email: targetEmail });

    if (!latestOtpDoc) {
      return res.status(400).json({ success: false, message: 'Invalid OTP. Please request a new one.' });
    }

    // Expiry check
    if (new Date() > latestOtpDoc.expiresAt) {
      return res.status(400).json({ success: false, message: 'OTP has expired. Please request a new one.' });
    }

    // Brute force check: max 5 verification attempts
    if (latestOtpDoc.attempts >= 5) {
      return res.status(400).json({ success: false, message: 'Too many invalid attempts. This OTP is locked. Please request a new one.' });
    }

    // Match check
    if (latestOtpDoc.otp !== otp.trim()) {
      latestOtpDoc.attempts += 1;
      await latestOtpDoc.save();
      return res.status(400).json({ success: false, message: 'Invalid OTP code. Please check and try again.' });
    }

    // Successfully verified: delete document to prevent reuse
    await OtpVerification.deleteOne({ _id: latestOtpDoc._id });
    
    // Look up if user is already registered (using email or phone)
    let user = await User.findOne({ email: targetEmail });
    if (!user && targetEmail.includes('@')) {
      // Look up via profile
      const profile = await Profile.findOne({ email: targetEmail });
      if (profile) {
        user = await User.findById(profile.userId);
      }
    }

    return res.status(200).json({
      success: true,
      userExists: !!user,
      user: user || null,
    });
  } catch (error) {
    console.error('Error in verify-email-otp:', error);
    return res.status(500).json({ success: false, message: 'Server error verifying OTP.' });
  }
});

/**
 * @route   POST /api/auth/verify-otp
 * @desc    Verify phone OTP or email OTP (hybrid verify)
 * @access  Public
 */
app.post('/api/auth/verify-email-otp', async (req, res) => {
  try {
    const { phone, otp } = req.body;
    if (!phone || !otp) {
      return res.status(400).json({ success: false, message: 'Phone number and OTP code are required.' });
    }

    // Support email OTP verify redirection
    if (phone.includes('@')) {
      const targetEmail = phone.toLowerCase().trim();
      const latestOtpDoc = await OtpVerification.findOne({ email: targetEmail });
      if (!latestOtpDoc || latestOtpDoc.otp !== otp.trim()) {
        return res.status(400).json({ success: false, message: 'Invalid OTP' });
      }
      if (new Date() > latestOtpDoc.expiresAt) {
        return res.status(400).json({ success: false, message: 'OTP expired.' });
      }
      await OtpVerification.deleteOne({ _id: latestOtpDoc._id });
      const user = await User.findOne({ email: targetEmail });
      return res.status(200).json({
        success: true,
        isExistingUser: !!user,
        userExists: !!user,
        user: user || null,
      });
    }

    const sanitizedPhone = phone.replace(/\s+/g, '').trim();
    const latestOtpDoc = await OtpVerification.findOne({ phone: sanitizedPhone }).sort({ createdAt: -1 });

    if (!latestOtpDoc || latestOtpDoc.otp !== otp.trim()) {
      return res.status(400).json({ success: false, message: 'Invalid OTP' });
    }

    if (new Date() > latestOtpDoc.expiresAt) {
      return res.status(400).json({ success: false, message: 'OTP expired. Please request again.' });
    }

    await OtpVerification.deleteOne({ _id: latestOtpDoc._id });

    // Look up if user is already registered (either by phone in Profile, or phone in User, or email)
    let user = await User.findOne({ phoneNumber: sanitizedPhone });
    if (!user) {
      const profile = await Profile.findOne({ phoneNumber: sanitizedPhone });
      if (profile) {
        user = await User.findById(profile.userId);
      }
    }

    return res.status(200).json({
      success: true,
      isExistingUser: !!user,
      userExists: !!user,
      user: user || null,
    });
  } catch (error) {
    console.error('Error in verify-otp:', error);
    return res.status(500).json({ success: false, message: 'Server error verifying OTP.' });
  }
});

/**
 * @route   POST /api/auth/admin-login
 * @desc    Log in as admin using Username and Password
 * @access  Public
 */
app.post('/api/auth/admin-login', async (req, res) => {
  try {
    const { username, password } = req.body;
    const adminUsername = process.env.ADMIN_USERNAME || 'admin';
    const adminPassword = process.env.ADMIN_PASSWORD || 'admin123';

    if (username === adminUsername && password === adminPassword) {
      let adminUser = await User.findOne({ email: 'admin@kutumbsetu.org' });
      if (!adminUser) {
        adminUser = new User({
          fullName: 'System Admin',
          email: 'admin@kutumbsetu.org',
          role: 'admin',
          isApproved: true,
        });
        await adminUser.save();
      }
      return res.status(200).json({
        success: true,
        user: adminUser,
      });
    } else {
      return res.status(401).json({
        success: false,
        message: 'Invalid Admin username or password.',
      });
    }
  } catch (error) {
    console.error('Error in admin-login:', error);
    return res.status(500).json({ success: false, message: 'Server error logging in admin.' });
  }
});

/**
 * @route   GET /api/admin/pending-users
 * @desc    Get all users pending approval
 * @access  Admin
 */
app.get('/api/admin/pending-users', async (req, res) => {
  try {
    const pendingUsers = await User.find({ isApproved: false, role: 'user' });
    return res.status(200).json({
      success: true,
      users: pendingUsers,
    });
  } catch (error) {
    console.error('Error fetching pending users:', error);
    return res.status(500).json({ success: false, message: 'Server error fetching pending users.' });
  }
});

/**
 * @route   PATCH /api/admin/approve-user/:id
 * @desc    Approve a pending user
 * @access  Admin
 */
app.patch('/api/admin/approve-user/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const user = await User.findByIdAndUpdate(id, { isApproved: true }, { new: true });
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }
    return res.status(200).json({
      success: true,
      message: 'User approved successfully.',
      user,
    });
  } catch (error) {
    console.error('Error approving user:', error);
    return res.status(500).json({ success: false, message: 'Server error approving user.' });
  }
});

// Alias verify-otp
app.post('/api/auth/verify-otp', async (req, res) => {
  const { phone, otp } = req.body;
  if (phone && phone.includes('@')) {
    req.body.email = phone;
    // Redirect to verify-email-otp logic manually
    const targetEmail = phone.toLowerCase().trim();
    const latestOtpDoc = await OtpVerification.findOne({ email: targetEmail });
    if (!latestOtpDoc) {
      return res.status(400).json({ success: false, message: 'Invalid OTP' });
    }
    if (latestOtpDoc.otp !== otp.trim()) {
      return res.status(400).json({ success: false, message: 'Invalid OTP' });
    }
    await OtpVerification.deleteOne({ _id: latestOtpDoc._id });
    return res.status(200).json({ success: true });
  }
  return res.status(200).json({ success: true });
});

/**
 * @route   POST /api/users/register
 * @desc    Register a new user and create their Profile
 * @access  Public
 */
app.post('/api/users/register', async (req, res) => {
  try {
    const {
      fullName,
      email,
      phoneNumber,
      surname,
      fatherName,
      gender,
      dateOfBirth,
      nativePlace,
      address,
      city,
      state,
      maritalStatus,
      occupation,
      profilePhoto,
      role,
    } = req.body;

    if (!fullName) {
      return res.status(400).json({
        success: false,
        message: 'Required registration field: fullName is missing.',
      });
    }

    // Check duplicate by email
    let targetEmail = '';
    if (email) {
      targetEmail = email.toLowerCase().trim();
      const existingUser = await User.findOne({ email: targetEmail });
      if (existingUser) {
        return res.status(400).json({
          success: false,
          message: 'Email address already registered. Please proceed to login.',
        });
      }
    }

    // Check duplicate by phone number
    let sanitizedPhone = '';
    if (phoneNumber) {
      sanitizedPhone = phoneNumber.replace(/\s+/g, '').trim();
      const existingUser = await User.findOne({ phoneNumber: sanitizedPhone });
      if (existingUser) {
        return res.status(400).json({
          success: false,
          message: 'Phone number already registered. Please login.',
        });
      }
      
      const existingProfile = await Profile.findOne({ phoneNumber: sanitizedPhone });
      if (existingProfile) {
        return res.status(400).json({
          success: false,
          message: 'Phone number already registered. Please login.',
        });
      }
    }


    // Create and save new user record
    const newUser = new User({
      fullName: fullName.trim(),
      email: targetEmail || undefined,
      phoneNumber: sanitizedPhone || undefined,
      role: role && ['admin', 'organizer', 'user'].includes(role) ? role : 'user',
    });

    const savedUser = await newUser.save();
    console.log(`Successfully registered new user: ${savedUser.fullName}`);

    // If phone number is provided, check if it matches a directory member
    let profileCreated = false;
    if (sanitizedPhone) {
      const db = mongoose.connection.db;
      const directoryMember = await db.collection('directory').findOne({
        $or: [
          { phoneNumber: sanitizedPhone },
          { phoneNumber: phoneNumber.trim() }
        ]
      });

      if (directoryMember) {
        console.log(`Matching directory member found: ${directoryMember.fullName}. Linking and copying profile details...`);
        const newProfile = new Profile({
          userId: savedUser._id,
          gender: directoryMember.gender || gender || 'Male',
          dateOfBirth: directoryMember.dateOfBirth || dateOfBirth || '',
          phoneNumber: directoryMember.phoneNumber || sanitizedPhone,
          profilePhoto: directoryMember.profilePhoto || profilePhoto || '',
          bloodGroup: directoryMember.bloodGroup || '',
          village: directoryMember.nativePlace || directoryMember.village || nativePlace || '',
          city: directoryMember.city || city || '',
          state: directoryMember.state || state || '',
          address: directoryMember.address || address || '',
          qualification: directoryMember.education || directoryMember.qualification || '',
          profession: directoryMember.occupation || directoryMember.profession || occupation || '',
          fatherName: directoryMember.fatherName || fatherName || '',
          motherName: directoryMember.motherName || '',
          grandfather: directoryMember.grandfather || '',
          grandmother: directoryMember.grandmother || '',
          nana: directoryMember.nana || '',
          nani: directoryMember.nani || '',
          bio: directoryMember.bio || '',
          familyId: directoryMember.familyId || '',
          relationshipToHead: directoryMember.relationshipToHead || 'Other',
          familyHeadPhone: directoryMember.familyHeadPhone || '',
          spouseName: directoryMember.spouseName || '',
          isDeceased: directoryMember.isDeceased || false,
        });
        await newProfile.save();
        profileCreated = true;
        console.log(`Successfully created linked profile for ${savedUser.fullName}`);
      }
    }

    // Create default profile if not linked to directory member
    if (!profileCreated) {
      const newProfile = new Profile({
        userId: savedUser._id,
        gender: gender || 'Male',
        dateOfBirth: dateOfBirth || '',
        phoneNumber: sanitizedPhone || '',
        profilePhoto: profilePhoto || '',
        bloodGroup: '',
        village: nativePlace || '',
        city: city || '',
        state: state || '',
        address: address || '',
        qualification: '',
        profession: occupation || '',
        fatherName: fatherName || '',
        motherName: '',
        grandfather: '',
        grandmother: '',
        nana: '',
        nani: '',
        bio: '',
        familyId: '',
        relationshipToHead: 'Other',
        familyHeadPhone: '',
        spouseName: '',
        isDeceased: false,
      });
      await newProfile.save();
      console.log(`Successfully created profile for ${savedUser.fullName}`);
    }

    return res.status(201).json({
      success: true,
      user: savedUser,
    });
  } catch (error) {
    console.error('Error in register:', error);
    return res.status(500).json({ success: false, message: 'Server error. User registration failed.' });
  }
});



/**
 * @route   GET /api/users/profile/:identifier
 * @desc    Fetch a user profile by email or phone number (hybrid lookup)
 * @access  Public
 */
app.get('/api/users/profile/:identifier', async (req, res) => {
  try {
    const { identifier } = req.params;
    if (!identifier) {
      return res.status(400).json({ success: false, message: 'Identifier is required.' });
    }

    const cleanId = identifier.trim();
    let user = null;
    let profile = null;

    if (cleanId.includes('@')) {
      user = await User.findOne({ email: cleanId.toLowerCase() });
      if (user) {
        profile = await Profile.findOne({ userId: user._id });
      }
    } else {
      const sanitizedPhone = cleanId.replace(/\s+/g, '');
      profile = await Profile.findOne({ phoneNumber: sanitizedPhone });
      if (profile) {
        user = await User.findById(profile.userId);
      } else {
        user = await User.findOne({ phoneNumber: sanitizedPhone });
      }
    }

    if (!user) {
      return res.status(404).json({ success: false, message: 'User profile not found.' });
    }

    if (!profile) {
      // Return user with empty profile fields so frontend knows it is not completed
      return res.status(200).json({
        success: true,
        user: {
          _id: user._id,
          fullName: user.fullName,
          email: user.email,
          phoneNumber: '',
          gender: 'Male',
          dateOfBirth: '',
          nativePlace: '',
          address: '',
          city: '',
          state: '',
          maritalStatus: 'Single',
          occupation: '',
          education: '',
          bloodGroup: '',
          profilePhoto: '',
          familyId: '',
          familyName: '',
          relationshipToHead: 'Other',
          motherName: '',
          spouseName: '',
          familyHeadPhone: '',
          fatherName: '',
          grandfather: '',
          grandmother: '',
          nana: '',
          nani: '',
          bio: '',
        }
      });
    }

    // Merge User & Profile details
    const mergedUser = {
      _id: user._id,
      fullName: user.fullName,
      email: user.email,
      phoneNumber: profile.phoneNumber,
      gender: profile.gender,
      dateOfBirth: profile.dateOfBirth,
      nativePlace: profile.village,
      address: profile.address,
      city: profile.city,
      state: profile.state,
      maritalStatus: profile.maritalStatus || 'Single',
      occupation: profile.profession,
      education: profile.qualification || profile.education || '',
      bloodGroup: profile.bloodGroup,
      profilePhoto: profile.profilePhoto,
      familyId: profile.familyId,
      familyName: profile.familyName || '',
      relationshipToHead: profile.relationshipToHead || 'Other',
      motherName: profile.motherName || '',
      spouseName: profile.spouseName || '',
      familyHeadPhone: profile.familyHeadPhone || '',
      fatherName: profile.fatherName || '',
      grandfather: profile.grandfather || '',
      grandmother: profile.grandmother || '',
      nana: profile.nana || '',
      nani: profile.nani || '',
      bio: profile.bio || '',
      isDeceased: profile.isDeceased || false,
      willingToDonateBlood: profile.willingToDonateBlood || false,
    };

    return res.status(200).json({ success: true, user: mergedUser });
  } catch (error) {
    console.error('Error fetching profile details:', error);
    return res.status(500).json({ success: false, message: 'Server error fetching profile.' });
  }
});

/**
 * @route   POST /api/users/profile
 * @desc    Save or update user profile completion details in MongoDB
 * @access  Public
 */
app.post('/api/users/profile', async (req, res) => {
  try {
    const {
      userId,
      gender,
      dateOfBirth,
      phoneNumber,
      profilePhoto,
      profilePhotoBase64,
      bloodGroup,
      village,
      city,
      state,
      address,
      qualification,
      college,
      profession,
      fatherName,
      motherName,
      grandfather,
      grandmother,
      nana,
      nani,
      bio,
      familyId,
      relationshipToHead,
      familyHeadPhone,
      spouseName,
      isDeceased,
      willingToDonateBlood
    } = req.body;

    if (!userId || !gender || !dateOfBirth || !phoneNumber || !city) {
      return res.status(400).json({
        success: false,
        message: 'Required profile completion fields (userId, gender, dateOfBirth, phoneNumber, city) are missing.',
      });
    }

    const validUserId = await getValidUserId(userId);
    let profile = await Profile.findOne({ userId: validUserId });

    let finalFamilyId = '';
    if (profile && profile.familyId) {
      finalFamilyId = profile.familyId;
    } else {
      const user = await User.findById(validUserId);
      const name = user ? user.fullName : '';
      finalFamilyId = await generateUniqueFamilyId(name);
    }

    let finalProfilePhoto = profilePhoto;
    if (profilePhotoBase64 && profilePhotoBase64.trim().length > 0) {
      try {
        const base64Data = profilePhotoBase64.replace(/^data:image\/\w+;base64,/, "");
        const buffer = Buffer.from(base64Data, 'base64');
        const uploadsDir = path.join(__dirname, 'uploads');
        if (!fs.existsSync(uploadsDir)) {
          fs.mkdirSync(uploadsDir, { recursive: true });
        }
        const filename = `user-photo-${validUserId}-${Date.now()}.jpg`;
        const filepath = path.join(uploadsDir, filename);
        fs.writeFileSync(filepath, buffer);
        finalProfilePhoto = `/uploads/${filename}`;
        console.log(`Saved user profile photo to: ${finalProfilePhoto}`);
      } catch (err) {
        console.error('Error writing user profile photo:', err);
      }
    }

    const profileData = {
      userId: validUserId,
      gender,
      dateOfBirth,
      phoneNumber: phoneNumber.replace(/\s+/g, '').trim(),
      profilePhoto: finalProfilePhoto || '',
      bloodGroup: bloodGroup || '',
      village: village || '',
      city,
      state: state || '',
      address: address || '',
      qualification: qualification || '',
      college: college || '',
      profession: profession || '',
      fatherName: fatherName || '',
      motherName: motherName || '',
      grandfather: grandfather || '',
      grandmother: grandmother || '',
      nana: nana || '',
      nani: nani || '',
      bio: bio || '',
      familyId: finalFamilyId,
      relationshipToHead: relationshipToHead || 'Other',
      familyHeadPhone: familyHeadPhone || '',
      spouseName: spouseName || '',
      isDeceased: isDeceased || false,
      willingToDonateBlood: willingToDonateBlood === true || willingToDonateBlood === 'true',
    };

    if (profile) {
      profile = await Profile.findOneAndUpdate({ userId: validUserId }, profileData, { new: true });
      console.log(`Updated profile for userId: ${validUserId}`);
    } else {
      profile = new Profile(profileData);
      await profile.save();
      console.log(`Created profile for userId: ${validUserId}`);
    }

    return res.status(200).json({
      success: true,
      profile,
    });
  } catch (error) {
    console.error('Error saving profile details:', error);
    return res.status(500).json({ success: false, message: 'Server error saving profile.' });
  }
});

/**
 * @route   GET /api/users/all
 * @desc    Fetch all profiles merged with user details for Directory Module
 */
app.get('/api/users/all', async (req, res) => {
  try {
    const profiles = await Profile.find({}).populate('userId');
    const mergedList = profiles.map(p => {
      if (!p.userId) return null;
      
      const willing = p.willingToDonateBlood || false;
      return {
        _id: p.userId._id,
        fullName: p.userId.fullName,
        email: p.userId.email,
        phoneNumber: p.phoneNumber,
        gender: p.gender,
        dateOfBirth: p.dateOfBirth,
        nativePlace: p.village,
        address: p.address,
        city: p.city,
        state: p.state,
        occupation: p.profession,
        education: p.qualification + (p.college ? ' (' + p.college + ')' : ''),
        bloodGroup: willing ? p.bloodGroup : '',
        profilePhoto: p.profilePhoto,
        familyId: p.familyId,
        relationshipToHead: p.relationshipToHead,
        motherName: p.motherName,
        spouseName: p.spouseName,
        familyHeadPhone: p.familyHeadPhone,
        fatherName: p.fatherName,
        isDeceased: p.isDeceased || false,
        willingToDonateBlood: willing,
      };
    }).filter(Boolean);

    return res.status(200).json({ success: true, users: mergedList });
  } catch (error) {
    console.error('Error fetching all users directory:', error);
    return res.status(500).json({ success: false, message: 'Server error fetching directory.' });
  }
});

/**
 * @route   GET /api/family/my-tree
 * @desc    Fetch family members in a tree structure
 * @access  Protected (by custom x-user-phone or x-user-email headers)
 */
/**
 * @route   POST /api/family/add-member
 * @desc    Add a custom relation/member to the user's profile addedMembers array
 * @access  Public
 */
app.post('/api/family/add-member', async (req, res) => {
  try {
    const { userId, name, relation, isDeceased } = req.body;
    if (!userId || !name || !relation) {
      return res.status(400).json({ success: false, message: 'Required fields (userId, name, relation) are missing.' });
    }

    const validUserId = await getValidUserId(userId);
    const profile = await Profile.findOne({ userId: validUserId });
    if (!profile) {
      return res.status(404).json({ success: false, message: 'Profile not found. Complete profile first.' });
    }

    profile.addedMembers = profile.addedMembers || [];
    profile.addedMembers.push({
      name: name.trim(),
      relation: relation.trim(),
      isDeceased: isDeceased || false
    });
    await profile.save();

    return res.status(200).json({
      success: true,
      message: 'Family relation added successfully!',
      addedMembers: profile.addedMembers
    });
  } catch (error) {
    console.error('Error adding family member:', error);
    return res.status(500).json({ success: false, message: 'Server error adding family member.' });
  }
});

/**
 * @route   GET /api/family/my-tree
 * @desc    Fetch family members in a tree structure
 * @access  Protected (by custom x-user-phone or x-user-email headers)
 */
app.get('/api/family/my-tree', async (req, res) => {
  try {
    const userPhone = req.headers['x-user-phone'];
    const userEmail = req.headers['x-user-email'];

    let profile = null;
    if (userEmail) {
      const user = await User.findOne({ email: userEmail.toLowerCase().trim() });
      if (user) {
        profile = await Profile.findOne({ userId: user._id }).populate('userId');
      }
    } else if (userPhone) {
      profile = await Profile.findOne({ phoneNumber: userPhone.replace(/\s+/g, '').trim() }).populate('userId');
    }

    if (!profile) {
      return res.status(404).json({ success: false, message: 'User profile not found. Please complete profile details first.' });
    }

    const familyId = profile.familyId;
    let familyProfiles = [];
    if (familyId) {
      familyProfiles = await Profile.find({ familyId }).populate('userId');
    }

    // Helper to make a node matching tree data structure requirements
    const makeNode = (p) => {
      if (!p || !p.userId) return null;
      return {
        id: p.userId._id.toString(),
        name: p.userId.fullName,
        photo: p.profilePhoto || '',
        relation: p.relationshipToHead || 'Unknown',
        isDeceased: p.isDeceased || false,
        parentId: null,
        children: []
      };
    };

    const makeVirtualNode = (id, name, relation) => {
      return {
        id,
        name,
        photo: '',
        relation,
        isDeceased: false,
        parentId: null,
        children: []
      };
    };

    // Group actual registered members by relation
    let gf = null, gm = null, father = null, mother = null, self = null, spouse = null;
    let fil = null, mil = null;
    const sons = [], daughters = [], uncles = [], aunts = [], cousins = [], siblings = [], sibsInLaw = [], nephews = [], nieces = [], guardians = [], unknowns = [];

    familyProfiles.forEach(p => {
      if (!p.userId) return;
      const rel = (p.relationshipToHead || '').trim().toLowerCase();
      if (rel === 'grandfather') gf = p;
      else if (rel === 'grandmother') gm = p;
      else if (rel === 'father') father = p;
      else if (rel === 'mother') mother = p;
      else if (rel === 'self') self = p;
      else if (rel === 'wife' || rel === 'husband' || rel === 'spouse') spouse = p;
      else if (rel === 'father-in-law') fil = p;
      else if (rel === 'mother-in-law') mil = p;
      else if (rel === 'son') sons.push(p);
      else if (rel === 'daughter') daughters.push(p);
      else if (rel === 'uncle') uncles.push(p);
      else if (rel === 'aunt') aunts.push(p);
      else if (rel === 'cousin') cousins.push(p);
      else if (rel === 'brother' || rel === 'sister') siblings.push(p);
      else if (rel === 'brother-in-law' || rel === 'sister-in-law') sibsInLaw.push(p);
      else if (rel === 'nephew') nephews.push(p);
      else if (rel === 'niece') nieces.push(p);
      else if (rel === 'guardian') guardians.push(p);
      else unknowns.push(p);
    });

    if (!self) {
      self = profile;
    }

    const selfNode = makeNode(self);
    if (!selfNode) {
      return res.status(404).json({ success: false, message: 'Could not resolve self node.' });
    }

    // Helper to get actual node or create virtual node from profile text fields
    const getOrCreateNode = (relationKey, actualProfile, nameFromSelf, virtualRelationName) => {
      let cleanName = nameFromSelf ? nameFromSelf.trim() : '';
      if (cleanName.toLowerCase() === 'none' || cleanName.toLowerCase() === 'no' || cleanName.toLowerCase() === 'nil') {
        cleanName = '';
      }
      const hasNameFromSelf = cleanName.length > 0;
      const isDummy = actualProfile && actualProfile.userId && actualProfile.userId.email && actualProfile.userId.email.includes('_demo_');
      
      if (hasNameFromSelf) {
        const selfNameClean = cleanName.toLowerCase();
        const actualNameClean = (actualProfile && actualProfile.userId && actualProfile.userId.fullName) ? actualProfile.userId.fullName.trim().toLowerCase() : '';
        
        if (actualProfile && !isDummy && (actualNameClean.includes(selfNameClean) || selfNameClean.includes(actualNameClean))) {
          return makeNode(actualProfile);
        }
        return makeVirtualNode(`${selfNode.id}-virtual-${relationKey}`, cleanName, virtualRelationName);
      }
      
      if (actualProfile && !isDummy) {
        return makeNode(actualProfile);
      }
      return null;
    };

    let gfNode = getOrCreateNode('grandfather', gf, self.grandfather, 'Grandfather');
    let gmNode = getOrCreateNode('grandmother', gm, self.grandmother, 'Grandmother');
    let fNode = getOrCreateNode('father', father, self.fatherName, 'Father');
    let mNode = getOrCreateNode('mother', mother, self.motherName, 'Mother');
    let nanaNode = getOrCreateNode('nana', null, self.nana, 'Nana');
    let naniNode = getOrCreateNode('nani', null, self.nani, 'Nani');
    let spouseNode = getOrCreateNode('spouse', spouse, self.spouseName, 'Spouse');
    
    // Also ignore dummy/demo in-laws
    const isFilDummy = fil && fil.userId && fil.userId.email && fil.userId.email.includes('_demo_');
    const isMilDummy = mil && mil.userId && mil.userId.email && mil.userId.email.includes('_demo_');
    const filNode = (fil && !isFilDummy) ? makeNode(fil) : null;
    const milNode = (mil && !isMilDummy) ? makeNode(mil) : null;

    // Map of nodes for quick reference
    const allNodesMap = {};
    if (selfNode) allNodesMap[selfNode.id] = selfNode;

    // Process custom addedMembers from profile
    const addedMembers = self.addedMembers || [];
    addedMembers.forEach((m, index) => {
      const n = {
        id: `${selfNode.id}-added-${index}`,
        name: m.name,
        photo: '',
        relation: m.relation,
        isDeceased: m.isDeceased || false,
        parentId: null,
        children: []
      };

      const rel = m.relation.trim().toLowerCase();
      if (rel === 'son') sons.push(n);
      else if (rel === 'daughter') daughters.push(n);
      else if (rel === 'brother' || rel === 'sister') siblings.push(n);
      else if (rel === 'uncle') uncles.push(n);
      else if (rel === 'aunt') aunts.push(n);
      else if (rel === 'cousin') cousins.push(n);
      else if (rel === 'brother-in-law' || rel === 'sister-in-law') sibsInLaw.push(n);
      else if (rel === 'nephew') nephews.push(n);
      else if (rel === 'niece') nieces.push(n);
      else if (rel === 'father' && !fNode) fNode = n;
      else if (rel === 'mother' && !mNode) mNode = n;
      else if (rel === 'grandfather' && !gfNode) gfNode = n;
      else if (rel === 'grandmother' && !gmNode) gmNode = n;
      else if (rel === 'nana' && !nanaNode) nanaNode = n;
      else if (rel === 'nani' && !naniNode) naniNode = n;
      else if ((rel === 'spouse' || rel === 'wife' || rel === 'husband') && !spouseNode) spouseNode = n;
      else unknowns.push(n);
    });

    // Map actual profiles to tree nodes, mixing in custom added nodes
    const selfUserIdStr = self.userId ? self.userId._id.toString() : '';
    const sonNodes = sons.map(s => s.userId ? makeNode(s) : s).filter(Boolean).filter(s => s.id !== selfUserIdStr);
    const daughterNodes = daughters.map(d => d.userId ? makeNode(d) : d).filter(Boolean).filter(d => d.id !== selfUserIdStr);
    const siblingNodes = siblings.map(s => s.userId ? makeNode(s) : s).filter(Boolean);
    const uncleNodes = uncles.map(u => u.userId ? makeNode(u) : u).filter(Boolean);
    const auntNodes = aunts.map(a => a.userId ? makeNode(a) : a).filter(Boolean);
    const cousinNodes = cousins.map(c => c.userId ? makeNode(c) : c).filter(Boolean);
    const sibsInLawNodes = sibsInLaw.map(s => s.userId ? makeNode(s) : s).filter(Boolean);
    const nephewNodes = nephews.map(n => n.userId ? makeNode(n) : n).filter(Boolean);
    const nieceNodes = nieces.map(n => n.userId ? makeNode(n) : n).filter(Boolean);
    const guardianNodes = guardians.map(g => g.userId ? makeNode(g) : g).filter(Boolean);
    const unknownNodes = unknowns.map(u => u.userId ? makeNode(u) : u).filter(Boolean);

    // Register all nodes in map
    const registerInMap = (n) => { if (n) allNodesMap[n.id] = n; };
    registerInMap(spouseNode);
    registerInMap(fNode);
    registerInMap(mNode);
    registerInMap(gfNode);
    registerInMap(gmNode);
    registerInMap(nanaNode);
    registerInMap(naniNode);
    registerInMap(filNode);
    registerInMap(milNode);
    sonNodes.forEach(registerInMap);
    daughterNodes.forEach(registerInMap);
    siblingNodes.forEach(registerInMap);
    uncleNodes.forEach(registerInMap);
    auntNodes.forEach(registerInMap);
    cousinNodes.forEach(registerInMap);
    sibsInLawNodes.forEach(registerInMap);
    nephewNodes.forEach(registerInMap);
    nieceNodes.forEach(registerInMap);
    guardianNodes.forEach(registerInMap);
    unknownNodes.forEach(registerInMap);

    // Spouse pairs mapping (Husband <-> Wife connected side-by-side with blue line)
    if (gfNode && gmNode) {
      gfNode.children.push(gmNode);
      gmNode.parentId = gfNode.id;
    }
    if (nanaNode && naniNode) {
      nanaNode.children.push(naniNode);
      naniNode.parentId = nanaNode.id;
    }
    if (fNode && mNode) {
      fNode.children.push(mNode);
      mNode.parentId = fNode.id;
    }
    if (selfNode && spouseNode) {
      selfNode.children.push(spouseNode);
      spouseNode.parentId = selfNode.id;
    }

    // Paternal line descendants (Midpoint to Father & Uncles)
    if (gfNode) {
      if (fNode) {
        gfNode.children.push(fNode);
        fNode.parentId = gfNode.id;
      }
      uncleNodes.forEach(un => {
        gfNode.children.push(un);
        un.parentId = gfNode.id;
      });
    } else if (gmNode) {
      if (fNode) {
        gmNode.children.push(fNode);
        fNode.parentId = gmNode.id;
      }
      uncleNodes.forEach(un => {
        gmNode.children.push(un);
        un.parentId = gmNode.id;
      });
    }

    // Maternal line descendants (Midpoint to Mother)
    if (nanaNode) {
      if (mNode) {
        nanaNode.children.push(mNode);
        mNode.parentId = nanaNode.id;
      }
    } else if (naniNode) {
      if (mNode) {
        naniNode.children.push(mNode);
        mNode.parentId = naniNode.id;
      }
    }

    // Parent midpoint down to Self & Siblings
    if (fNode) {
      fNode.children.push(selfNode);
      selfNode.parentId = fNode.id;
      siblingNodes.forEach(sib => {
        fNode.children.push(sib);
        sib.parentId = fNode.id;
      });
    } else if (mNode) {
      mNode.children.push(selfNode);
      selfNode.parentId = mNode.id;
      siblingNodes.forEach(sib => {
        mNode.children.push(sib);
        sib.parentId = mNode.id;
      });
    }

    // Self midpoint down to Children
    sonNodes.forEach(s => {
      selfNode.children.push(s);
      s.parentId = selfNode.id;
    });
    daughterNodes.forEach(d => {
      selfNode.children.push(d);
      d.parentId = selfNode.id;
    });
    guardianNodes.forEach(g => {
      selfNode.children.push(g);
      g.parentId = selfNode.id;
    });
    unknownNodes.forEach(u => {
      selfNode.children.push(u);
      u.parentId = selfNode.id;
    });

    // Sibling descendants
    if (siblingNodes.length > 0) {
      const mainSib = siblingNodes[0];
      nephewNodes.forEach(nep => {
        mainSib.children.push(nep);
        nep.parentId = mainSib.id;
      });
      nieceNodes.forEach(nie => {
        mainSib.children.push(nie);
        nie.parentId = mainSib.id;
      });
    }

    // In-laws descendants
    if (filNode) {
      if (milNode) {
        filNode.children.push(milNode);
        milNode.parentId = filNode.id;
      }
      if (spouseNode) {
        filNode.children.push(spouseNode);
        spouseNode.parentId = filNode.id;
      }
      sibsInLawNodes.forEach(sl => {
        filNode.children.push(sl);
        sl.parentId = filNode.id;
      });
    } else if (milNode) {
      if (spouseNode) {
        milNode.children.push(spouseNode);
        spouseNode.parentId = milNode.id;
      }
      sibsInLawNodes.forEach(sl => {
        milNode.children.push(sl);
        sl.parentId = milNode.id;
      });
    }

    // Uncles descendants
    if (uncleNodes.length > 0) {
      const mainUncle = uncleNodes[0];
      if (auntNodes.length > 0) {
        mainUncle.children.push(auntNodes[0]);
        auntNodes[0].parentId = mainUncle.id;
      }
      cousinNodes.forEach(c => {
        mainUncle.children.push(c);
        c.parentId = mainUncle.id;
      });
    }

    // Root node selection
    let root = null;
    if (gfNode || gmNode || nanaNode || naniNode) {
      // Create virtual ancestors root to tie both paternal & maternal grandparents symmetrically
      const ancestors = makeVirtualNode('virtual-ancestors', 'Ancestors', 'Ancestors');
      if (gfNode) {
        ancestors.children.push(gfNode);
        gfNode.parentId = ancestors.id;
      }
      if (nanaNode) {
        ancestors.children.push(nanaNode);
        nanaNode.parentId = ancestors.id;
      }
      root = ancestors;
    } else if (fNode) {
      root = fNode;
    } else if (mNode) {
      root = mNode;
    } else {
      root = selfNode;
    }

    return res.status(200).json({
      success: true,
      tree: root
    });
  } catch (error) {
    console.error('Error generating family tree:', error);
    return res.status(500).json({ success: false, message: 'Server error generating family tree.' });
  }
});

// ==========================================
// MATRIMONIAL MODULE ENDPOINTS
// ==========================================

// Helper: Calculate age from DOB
const calculateAge = (dob) => {
  const diffMs = Date.now() - new Date(dob).getTime();
  const ageDt = new Date(diffMs);
  return Math.abs(ageDt.getUTCFullYear() - 1970);
};

// 1. Create or Update Matrimonial Profile
app.post('/api/matrimonial/profile', async (req, res) => {
  try {
    const {
      userId, name, gender, dob, heightCm, weightKg, bloodGroup,
      maritalStatus, education, occupation, company, annualIncome,
      village, city, familyInformation, lifestyle, partnerPreferences,
      visibilitySettings, profilePhoto, introductionVideo,
      profilePhotoBase64, introductionVideoBase64
    } = req.body;

    if (!userId || !name || !gender || !dob || !heightCm || !weightKg) {
      return res.status(400).json({ success: false, message: 'Missing required profile fields.' });
    }

    // Handle base64 uploads
    let finalProfilePhoto = profilePhoto;
    if (profilePhotoBase64 && profilePhotoBase64.trim().length > 0) {
      try {
        const base64Data = profilePhotoBase64.replace(/^data:image\/\w+;base64,/, "");
        const buffer = Buffer.from(base64Data, 'base64');
        const uploadsDir = path.join(__dirname, 'uploads');
        if (!fs.existsSync(uploadsDir)) {
          fs.mkdirSync(uploadsDir, { recursive: true });
        }
        const filename = `matrimony-photo-${userId}-${Date.now()}.jpg`;
        const filepath = path.join(uploadsDir, filename);
        fs.writeFileSync(filepath, buffer);
        finalProfilePhoto = `/uploads/${filename}`;
        console.log(`Saved matrimonial profile photo to: ${finalProfilePhoto}`);
      } catch (err) {
        console.error('Error writing profile photo file:', err);
      }
    }

    let finalIntroductionVideo = introductionVideo;
    if (introductionVideoBase64 && introductionVideoBase64.trim().length > 0) {
      try {
        const base64Data = introductionVideoBase64.replace(/^data:video\/\w+;base64,/, "");
        const buffer = Buffer.from(base64Data, 'base64');
        const uploadsDir = path.join(__dirname, 'uploads');
        if (!fs.existsSync(uploadsDir)) {
          fs.mkdirSync(uploadsDir, { recursive: true });
        }
        const filename = `matrimony-video-${userId}-${Date.now()}.mp4`;
        const filepath = path.join(uploadsDir, filename);
        fs.writeFileSync(filepath, buffer);
        finalIntroductionVideo = `/uploads/${filename}`;
        console.log(`Saved matrimonial intro video to: ${finalIntroductionVideo}`);
      } catch (err) {
        console.error('Error writing introduction video file:', err);
      }
    }

    let profile = await MatrimonialProfile.findOne({ userId });
    
    const profileData = {
      userId,
      name,
      gender,
      dob: new Date(dob),
      heightCm,
      weightKg,
      bloodGroup,
      maritalStatus,
      education,
      occupation,
      company,
      annualIncome,
      village,
      city,
      familyInformation,
      lifestyle,
      partnerPreferences,
      visibilitySettings,
      profilePhoto: finalProfilePhoto,
      introductionVideo: finalIntroductionVideo,
      updatedDate: new Date()
    };

    if (profile) {
      profile = await MatrimonialProfile.findOneAndUpdate({ userId }, profileData, { new: true });
      console.log(`Updated matrimonial profile for user ID: ${userId}`);
    } else {
      profile = new MatrimonialProfile(profileData);
      await profile.save();
      console.log(`Created matrimonial profile for user ID: ${userId}`);
    }

    return res.status(200).json({ success: true, profile });
  } catch (error) {
    console.error('Error saving matrimonial profile:', error);
    return res.status(500).json({ success: false, message: 'Server error saving matrimonial profile.' });
  }
});

// 2. Fetch Matrimonial Profile by User ID (applies masking based on visibility settings / requests)
app.get('/api/matrimonial/profile/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const requesterId = req.query.requesterId;

    const profile = await MatrimonialProfile.findOne({ userId }).populate('userId');
    if (!profile) {
      return res.status(404).json({ success: false, message: 'Matrimonial profile not found.' });
    }

    const doc = profile.toObject();

    // Fetch the User Profile containing phoneNumber and address
    const userProfile = await Profile.findOne({ userId });
    const userDoc = doc.userId;

    doc.mobileNumber = userProfile ? userProfile.phoneNumber : '';
    doc.emailAddress = userDoc ? userDoc.email : '';
    doc.fullAddressText = userProfile ? (userProfile.address || '') : '';

    // Check connection status
    let connectionStatus = 'None';
    if (requesterId) {
      const requestDoc = await MatrimonialRequest.findOne({
        $or: [
          { senderId: requesterId, receiverId: userId },
          { senderId: userId, receiverId: requesterId }
        ]
      });
      if (requestDoc) {
        connectionStatus = requestDoc.status;
      }
    }
    doc.connectionStatus = connectionStatus;

    const isOwnProfile = requesterId && requesterId.toString() === userId.toString();
    
    if (!isOwnProfile && connectionStatus !== 'Accepted') {
      // Clear/Mask all fields except name and basic ids
      doc.gender = '';
      doc.dateOfBirth = '';
      doc.dob = '';
      doc.heightCm = 0;
      doc.weightKg = 0;
      doc.maritalStatus = '';
      doc.religion = '';
      doc.caste = '';
      doc.subCaste = '';
      doc.gothra = '';
      doc.motherTongue = '';
      doc.education = '';
      doc.occupation = '';
      doc.company = '';
      doc.annualIncome = 0;
      doc.village = '';
      doc.city = '';
      doc.workingCountry = '';
      doc.description = '';
      doc.partnerExpectations = '';
      doc.partnerExpectationsHobbies = [];
      doc.additionalPhotos = [];
      doc.socialLinks = { showSocialLinks: false, instagramUrl: '', facebookUrl: '' };
      doc.mobileNumber = '';
      doc.emailAddress = '';
      doc.fullAddressText = '';
      doc.profilePhoto = '';
      doc.introductionVideo = '';
      doc.lifestyle = {};
      doc.partnerPreferences = {};
      doc.familyInformation = {};
    } else {
      // Mask fields based on visibility settings
      if (!isOwnProfile) {
        if (!doc.visibilitySettings || !doc.visibilitySettings.showPhone) {
          doc.mobileNumber = doc.mobileNumber ? doc.mobileNumber.substring(0, 6) + '••••' : '';
        }
        if (!doc.visibilitySettings || !doc.visibilitySettings.showAddress) {
          doc.fullAddressText = '••••••••••••';
        }
        if (!doc.visibilitySettings || !doc.visibilitySettings.showEmail) {
          doc.emailAddress = '••••@••••.•••';
        }
      }
    }

    return res.status(200).json({ success: true, profile: doc });
  } catch (error) {
    console.error('Error fetching matrimonial profile details:', error);
    return res.status(500).json({ success: false, message: 'Server error retrieving profile.' });
  }
});

// 3. List Matrimonial Profiles (supports search, filters, matching AI)
app.get('/api/matrimonial/profiles', async (req, res) => {
  try {
    const {
      search, ageMin, ageMax, heightMin, heightMax, village, city,
      occupation, education, incomeMin, incomeMax, maritalStatus, gender,
      requesterId, page = 1, limit = 10, weightMin, weightMax, workLocation
    } = req.query;

    const query = { profileStatus: 'Approved' };

    // Apply filters
    if (gender) query.gender = gender;
    
    // Requester check: hide own profile from lists
    if (requesterId) {
      query.userId = { $ne: requesterId };
    }

    if (ageMin || ageMax) {
      const dateMin = new Date();
      const dateMax = new Date();
      if (ageMin) dateMax.setFullYear(dateMax.getFullYear() - parseInt(ageMin));
      if (ageMax) dateMin.setFullYear(dateMin.getFullYear() - parseInt(ageMax) - 1);
      
      query.dob = {};
      if (ageMin) query.dob.$lte = dateMax;
      if (ageMax) query.dob.$gte = dateMin;
    }

    if (heightMin || heightMax) {
      query.heightCm = {};
      if (heightMin) query.heightCm.$gte = parseInt(heightMin);
      if (heightMax) query.heightCm.$lte = parseInt(heightMax);
    }

    if (weightMin || weightMax) {
      query.weightKg = {};
      if (weightMin) query.weightKg.$gte = parseInt(weightMin);
      if (weightMax) query.weightKg.$lte = parseInt(weightMax);
    }

    if (workLocation) {
      query.workingCountry = new RegExp(workLocation, 'i');
    }

    if (incomeMin || incomeMax) {
      query.annualIncome = {};
      if (incomeMin) query.annualIncome.$gte = parseFloat(incomeMin);
      if (incomeMax) query.annualIncome.$lte = parseFloat(incomeMax);
    }

    if (maritalStatus) query.maritalStatus = maritalStatus;
    if (village) query.village = new RegExp(village, 'i');
    if (city) query.city = new RegExp(city, 'i');
    if (occupation) query.occupation = new RegExp(occupation, 'i');
    if (education) query.education = new RegExp(education, 'i');

    if (search) {
      const searchRegex = new RegExp(search, 'i');
      query.$or = [
        { name: searchRegex },
        { village: searchRegex },
        { city: searchRegex },
        { education: searchRegex },
        { occupation: searchRegex }
      ];
    }

    const skipIndex = (parseInt(page) - 1) * parseInt(limit);
    const profiles = await MatrimonialProfile.find(query)
      .skip(skipIndex)
      .limit(parseInt(limit))
      .sort({ createdDate: -1 });

    const totalCount = await MatrimonialProfile.countDocuments(query);

    // Calculate match percentage dynamically relative to requester preferences
    let requesterPref = null;
    if (requesterId) {
      const reqProf = await MatrimonialProfile.findOne({ userId: requesterId });
      if (reqProf && reqProf.partnerPreferences) {
        requesterPref = reqProf.partnerPreferences;
      }
    }

    // Fetch accepted connection requests once for masking logic
    let acceptedUserIds = new Set();
    let sentReqMap = {};
    if (requesterId) {
      const acceptedReqDocs = await MatrimonialRequest.find({
        status: 'Accepted',
        $or: [
          { senderId: requesterId },
          { receiverId: requesterId }
        ]
      });
      acceptedReqDocs.forEach(reqDoc => {
        acceptedUserIds.add(reqDoc.senderId.toString());
        acceptedUserIds.add(reqDoc.receiverId.toString());
      });

      const allUserReqs = await MatrimonialRequest.find({
        $or: [
          { senderId: requesterId },
          { receiverId: requesterId }
        ]
      });
      allUserReqs.forEach(reqDoc => {
        const otherId = reqDoc.senderId.toString() === requesterId.toString() 
          ? reqDoc.receiverId.toString() 
          : reqDoc.senderId.toString();
        sentReqMap[otherId] = reqDoc.status;
      });
    }

    const listWithMatch = profiles.map(p => {
      const doc = p.toObject();
      doc.age = calculateAge(doc.dob);
      
      // AI Matching Logic
      let matchScore = 70; // default base match
      if (requesterPref) {
        if (doc.age >= (requesterPref.ageMin || 18) && doc.age <= (requesterPref.ageMax || 60)) {
          matchScore += 8;
        } else {
          matchScore -= 5;
        }
        if (doc.heightCm >= (requesterPref.heightMin || 120) && doc.heightCm <= (requesterPref.heightMax || 220)) {
          matchScore += 8;
        }
        if (requesterPref.education && doc.education && doc.education.toLowerCase().includes(requesterPref.education.toLowerCase())) {
          matchScore += 6;
        }
        if (requesterPref.occupation && doc.occupation && doc.occupation.toLowerCase().includes(requesterPref.occupation.toLowerCase())) {
          matchScore += 4;
        }
        if (requesterPref.city && doc.city && doc.city.toLowerCase().includes(requesterPref.city.toLowerCase())) {
          matchScore += 2;
        }
        if (requesterPref.village && doc.village && doc.village.toLowerCase().includes(requesterPref.village.toLowerCase())) {
          matchScore += 2;
        }
      }
      doc.match = Math.min(Math.max(matchScore, 50), 98); // clamp between 50 and 98

      // Apply Request-based detail masking
      const uIdStr = doc.userId ? doc.userId.toString() : '';
      const isOwnProfile = requesterId && requesterId.toString() === uIdStr;
      const isAccepted = isOwnProfile || (requesterId && acceptedUserIds.has(uIdStr));
      doc.connectionStatus = sentReqMap[uIdStr] || 'None';

      if (!isOwnProfile && !isAccepted) {
        doc.gender = '';
        doc.dateOfBirth = '';
        doc.dob = '';
        doc.heightCm = 0;
        doc.weightKg = 0;
        doc.maritalStatus = '';
        doc.religion = '';
        doc.caste = '';
        doc.subCaste = '';
        doc.gothra = '';
        doc.motherTongue = '';
        doc.education = '';
        doc.occupation = '';
        doc.company = '';
        doc.annualIncome = 0;
        doc.village = '';
        doc.city = '';
        doc.workingCountry = '';
        doc.description = '';
        doc.partnerExpectations = '';
        doc.partnerExpectationsHobbies = [];
        doc.additionalPhotos = [];
        doc.socialLinks = { showSocialLinks: false, instagramUrl: '', facebookUrl: '' };
        doc.mobileNumber = '';
        doc.emailAddress = '';
        doc.fullAddressText = '';
        doc.profilePhoto = '';
        doc.introductionVideo = '';
        doc.lifestyle = {};
        doc.partnerPreferences = {};
        doc.familyInformation = {};
      }

      return doc;
    });

    return res.status(200).json({
      success: true,
      profiles: listWithMatch,
      total: totalCount,
      page: parseInt(page),
      limit: parseInt(limit)
    });
  } catch (error) {
    console.error('Error fetching matrimonial profiles:', error);
    return res.status(500).json({ success: false, message: 'Server error listing profiles.' });
  }
});

// 4. Send interest request
app.post('/api/matrimonial/request', async (req, res) => {
  try {
    const { senderId, receiverId } = req.body;
    if (!senderId || !receiverId) {
      return res.status(400).json({ success: false, message: 'Sender and Receiver IDs are required.' });
    }

    if (senderId === receiverId) {
      return res.status(400).json({ success: false, message: 'Cannot send request to yourself.' });
    }

    // Check existing request
    const existing = await MatrimonialRequest.findOne({ senderId, receiverId });
    if (existing) {
      return res.status(400).json({ success: false, message: 'Request already exists.' });
    }

    const newRequest = new MatrimonialRequest({ senderId, receiverId });
    await newRequest.save();

    return res.status(201).json({ success: true, message: 'Interest request sent successfully.' });
  } catch (error) {
    console.error('Error sending matrimonial request:', error);
    return res.status(500).json({ success: false, message: 'Server error sending request.' });
  }
});

// 5. Respond to connection request
app.post('/api/matrimonial/request/respond', async (req, res) => {
  try {
    const { requestId, status } = req.body;
    if (!requestId || !status) {
      return res.status(400).json({ success: false, message: 'Request ID and response status are required.' });
    }

    const request = await MatrimonialRequest.findById(requestId);
    if (!request) {
      return res.status(404).json({ success: false, message: 'Request not found.' });
    }

    request.status = status;
    await request.save();

    return res.status(200).json({ success: true, message: `Request successfully ${status.toLowerCase()}.`, request });
  } catch (error) {
    console.error('Error responding to request:', error);
    return res.status(500).json({ success: false, message: 'Server error responding to request.' });
  }
});

// 6. Get Sent and Received requests
app.get('/api/matrimonial/requests', async (req, res) => {
  try {
    const { userId } = req.query;
    if (!userId) {
      return res.status(400).json({ success: false, message: 'User ID is required.' });
    }

    const sent = await MatrimonialRequest.find({ senderId: userId }).populate('receiverId');
    const received = await MatrimonialRequest.find({ receiverId: userId }).populate('senderId');

    return res.status(200).json({ success: true, sent, received });
  } catch (error) {
    console.error('Error getting requests:', error);
    return res.status(500).json({ success: false, message: 'Server error retrieving requests.' });
  }
});

// 7. Add/remove from Shortlist
app.post('/api/matrimonial/shortlist', async (req, res) => {
  try {
    const { userId, shortlistedUserId } = req.body;
    if (!userId || !shortlistedUserId) {
      return res.status(400).json({ success: false, message: 'User ID and Shortlisted User ID are required.' });
    }

    const existing = await MatrimonialShortlist.findOne({ userId, shortlistedUserId });
    if (existing) {
      await MatrimonialShortlist.deleteOne({ _id: existing._id });
      return res.status(200).json({ success: true, shortlisted: false, message: 'Removed from shortlist.' });
    }

    const shortDoc = new MatrimonialShortlist({ userId, shortlistedUserId });
    await shortDoc.save();

    return res.status(200).json({ success: true, shortlisted: true, message: 'Added to shortlist.' });
  } catch (error) {
    console.error('Error in shortlist toggler:', error);
    return res.status(500).json({ success: false, message: 'Server error toggling shortlist.' });
  }
});

// 8. Fetch shortlisted profiles
app.get('/api/matrimonial/shortlisted', async (req, res) => {
  try {
    const { userId } = req.query;
    if (!userId) {
      return res.status(400).json({ success: false, message: 'User ID is required.' });
    }

    const list = await MatrimonialShortlist.find({ userId });
    const shortlistedIds = list.map(item => item.shortlistedUserId);
    
    const profiles = await MatrimonialProfile.find({ userId: { $in: shortlistedIds } });
    
    const formatted = profiles.map(p => {
      const doc = p.toObject();
      doc.age = calculateAge(doc.dob);
      doc.match = 85; // mock match for shortlisted
      return doc;
    });

    return res.status(200).json({ success: true, profiles: formatted });
  } catch (error) {
    console.error('Error retrieving shortlisted profiles:', error);
    return res.status(500).json({ success: false, message: 'Server error fetching shortlists.' });
  }
});

// 9. Fetch events
app.get('/api/matrimonial/events', async (req, res) => {
  try {
    const events = await MatrimonialEvent.find({}).sort({ date: 1 });
    return res.status(200).json({ success: true, events });
  } catch (error) {
    console.error('Error fetching marriage events:', error);
    return res.status(500).json({ success: false, message: 'Server error fetching events.' });
  }
});

// 10. Fetch success stories
app.get('/api/matrimonial/success-stories', async (req, res) => {
  try {
    const stories = await SuccessStory.find({}).sort({ marriageDate: -1 });
    return res.status(200).json({ success: true, stories });
  } catch (error) {
    console.error('Error fetching success stories:', error);
    return res.status(500).json({ success: false, message: 'Server error fetching stories.' });
  }
});

// ==========================================
// SEEDING MATRIMONIAL DATA
// ==========================================
const seedMatrimonialData = async () => {
  try {
    const profileCount = await MatrimonialProfile.countDocuments({});
    if (profileCount === 0) {
      console.log('Seeding matrimonial profiles...');
      const users = await User.find({});
      if (users.length === 0) {
        console.log('Seeding: No users in DB. Skipping matrimonial seeding.');
        return;
      }
      
      const samplePhotos = {
        'Male': ['avatar_male_1', 'avatar_male_2'],
        'Female': ['avatar_female_1', 'avatar_generic']
      };

      for (let i = 0; i < users.length; i++) {
        const u = users[i];
        
        // Let's seed for some users to simulate realistic profiles (e.g. 80%)
        if (i % 5 === 0) continue; 
        
        const gender = u.gender || 'Male';
        const photoList = samplePhotos[gender] || ['avatar_generic'];
        const profilePhoto = u.profilePhoto || photoList[i % photoList.length];
        
        const age = 22 + (i % 15);
        const dobDate = new Date();
        dobDate.setFullYear(dobDate.getFullYear() - age);

        const matrimonialProfile = new MatrimonialProfile({
          userId: u._id,
          name: u.fullName + (u.surname ? ' ' + u.surname : ''),
          gender: gender,
          dob: dobDate,
          heightCm: gender === 'Male' ? 168 + (i % 12) : 155 + (i % 12),
          weightKg: gender === 'Male' ? 62 + (i % 20) : 48 + (i % 18),
          bloodGroup: u.bloodGroup || 'B+',
          maritalStatus: 'Never Married',
          education: u.education || 'B.E. Computer Engineering',
          occupation: u.occupation || 'Software Architect',
          company: 'Samaj Tech Solutions',
          annualIncome: 450000 + (i % 10) * 150000,
          village: u.nativePlace || 'Karamsad',
          city: u.city || 'Vadodara',
          familyInformation: {
            fatherName: u.fatherName || 'Maheshbhai ' + (u.surname || 'Chauhan'),
            motherName: u.motherName || 'Kiranben ' + (u.surname || 'Chauhan'),
            grandfather: 'Dahyalalbhai ' + (u.surname || 'Chauhan'),
            grandmother: 'Kamlaben ' + (u.surname || 'Chauhan'),
            nana: 'Ramanlal Patel',
            nani: 'Lilaben Patel',
            familyOccupation: 'Agriculture & Business'
          },
          lifestyle: {
            languages: ['Gujarati', 'Hindi', 'English'],
            hobbies: ['Reading', 'Traveling', 'Music', 'Cooking'],
            diet: 'Vegetarian',
            smoking: 'No',
            drinking: 'No'
          },
          partnerPreferences: {
            ageMin: gender === 'Male' ? age - 5 : age - 2,
            ageMax: gender === 'Male' ? age + 2 : age + 5,
            heightMin: gender === 'Male' ? 150 : 165,
            heightMax: gender === 'Male' ? 175 : 195,
            education: 'Graduate',
            occupation: 'Any',
            city: u.city || 'Vadodara',
            village: u.nativePlace || 'Karamsad'
          },
          visibilitySettings: {
            showPhone: true,
            showAddress: true,
            showEmail: false
          },
          profilePhoto: profilePhoto,
          introductionVideo: 'https://assets.mixkit.co/videos/preview/mixkit-dramatic-waterfall-in-forest-42289-large.mp4',
          profileStatus: 'Approved'
        });
        await matrimonialProfile.save();
      }
      console.log('Seeding: Matrimonial profiles successfully seeded.');
    }

    const eventCount = await MatrimonialEvent.countDocuments({});
    if (eventCount === 0) {
      console.log('Seeding matrimonial events...');
      const sampleEvents = [
        {
          title: 'Samuh Lagna Sammelan',
          date: new Date('2026-07-18T10:00:00.000Z'),
          location: 'Samaj Hall, Vadodara, Gujarat',
          description: 'Grand community mass marriage event. Registrations open for brides and grooms.'
        },
        {
          title: 'Matrimonial Meet 2026',
          date: new Date('2026-08-09T09:00:00.000Z'),
          location: 'Community Grounds, Ahmedabad, Gujarat',
          description: 'A platform for eligible youths and their families to meet and interact face-to-face.'
        },
        {
          title: 'Community Matrimonial Gathering',
          date: new Date('2026-08-24T11:00:00.000Z'),
          location: 'Royal Plaza, Surat, Gujarat',
          description: 'Interactive introduction program and family counseling sessions.'
        }
      ];
      for (const e of sampleEvents) {
        const ev = new MatrimonialEvent(e);
        await ev.save();
      }
      console.log('Seeding: Matrimonial events successfully seeded.');
    }

    const storyCount = await SuccessStory.countDocuments({});
    if (storyCount === 0) {
      console.log('Seeding matrimonial success stories...');
      const sampleStories = [
        {
          coupleName: 'Priya ❤️ Rohan',
          marriageDate: new Date('2026-02-12T00:00:00.000Z'),
          photo: 'avatar_female_1',
          description: 'We found each other through KutumbSetu Matrimonial in November 2025. With our families\' blessings, we got married in February 2026. Thank you KutumbSetu!'
        },
        {
          coupleName: 'Nikita ❤️ Krupal',
          marriageDate: new Date('2025-11-23T00:00:00.000Z'),
          photo: 'avatar_generic',
          description: 'KutumbSetu helped us bridge the distance between Mumbai and Vadodara. Highly recommended for trusted community matchmaking.'
        }
      ];
      for (const s of sampleStories) {
        const st = new SuccessStory(s);
        await st.save();
      }
      console.log('Seeding: Matrimonial success stories successfully seeded.');
    }
  } catch (err) {
    console.error('Error seeding matrimonial data:', err);
  }
};

// Serving Static Uploads for Posts and Reels
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir);
}
app.use('/uploads', express.static(uploadsDir));

// Import Community Models
const Post = require('./models/Post');
const Reel = require('./models/Reel');

// Helper to get valid user ID and generate unique family ID
const getValidUserId = async (id) => {
  if (mongoose.Types.ObjectId.isValid(id)) {
    return new mongoose.Types.ObjectId(id);
  }
  const firstUser = await User.findOne({});
  if (firstUser) {
    return firstUser._id;
  }
  return new mongoose.Types.ObjectId();
};

const generateFamilyId = (fullName, dob) => {
  const parts = (fullName || '').trim().split(/\s+/);
  const firstName = parts[0] || 'KU';
  const surname = parts.length > 1 ? parts[parts.length - 1] : 'SE';

  const fCode = firstName.substring(0, 2).toUpperCase().padEnd(2, 'X');
  const sCode = surname.substring(0, 2).toUpperCase().padEnd(2, 'X');

  let yearDigits = '99';
  if (dob && dob.length >= 4) {
    const match = dob.match(/^(\d{4})/);
    if (match) {
      yearDigits = match[1].substring(2);
    }
  } else {
    yearDigits = Math.floor(Math.random() * 90 + 10).toString();
  }

  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let randomStr = '';
  for (let i = 0; i < 2; i++) {
    randomStr += chars.charAt(Math.floor(Math.random() * chars.length));
  }

  return `${fCode}${sCode}${yearDigits}${randomStr}`;
};

const generateUniqueFamilyId = async (fullName) => {
  const parts = (fullName || '').trim().split(/\s+/);
  const firstName = parts[0] || 'KUTUMB';
  const lastName = parts.length > 1 ? parts[parts.length - 1] : 'SETU';

  const cleanFirst = firstName.replace(/[^a-zA-Z]/g, '').toUpperCase();
  const cleanLast = lastName.replace(/[^a-zA-Z]/g, '').toUpperCase();

  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let isUnique = false;
  let familyId = '';
  
  while (!isUnique) {
    let randomStr = '';
    for (let i = 0; i < 4; i++) {
      randomStr += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    familyId = `${cleanFirst}-${cleanLast}-${randomStr}`;
    
    // Check if this familyId already exists in Profile collection
    const existing = await Profile.findOne({ familyId });
    if (!existing) {
      isUnique = true;
    }
  }
  
  return familyId;
};

// --- COMMUNITY POSTS ENDPOINTS ---

// Fetch all posts (sorted by newest first)
app.get('/api/community/posts', async (req, res) => {
  try {
    const posts = await Post.find({}).sort({ createdAt: -1 });
    return res.status(200).json({ success: true, posts });
  } catch (err) {
    console.error('Error fetching posts:', err);
    return res.status(500).json({ success: false, message: 'Failed to fetch posts.' });
  }
});

// Fetch posts for a specific user
app.get('/api/community/posts/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const posts = await Post.find({ userId }).sort({ createdAt: -1 });
    return res.status(200).json({ success: true, posts });
  } catch (err) {
    console.error('Error fetching user posts:', err);
    return res.status(500).json({ success: false, message: 'Failed to fetch user posts.' });
  }
});

// Fetch reels for a specific user
app.get('/api/community/reels/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const reels = await Reel.find({ userId }).sort({ createdAt: -1 });
    return res.status(200).json({ success: true, reels });
  } catch (err) {
    console.error('Error fetching user reels:', err);
    return res.status(500).json({ success: false, message: 'Failed to fetch user reels.' });
  }
});

// Create new post
app.post('/api/community/posts', async (req, res) => {
  try {
    const { userId, content, mediaBase64 } = req.body;
    if (!userId || !content) {
      return res.status(400).json({ success: false, message: 'UserId and content are required.' });
    }
    const validUserId = await getValidUserId(userId);
    const user = await User.findById(validUserId);
    const authorName = user ? user.fullName : 'Rajeshbhai Chauhan';

    let mediaUrl = '';
    if (mediaBase64) {
      const buffer = Buffer.from(mediaBase64, 'base64');
      const filename = `post-${Date.now()}-${Math.round(Math.random() * 1E9)}.jpg`;
      const filepath = path.join(uploadsDir, filename);
      fs.writeFileSync(filepath, buffer);
      mediaUrl = `/uploads/${filename}`;
    }

    const init = authorName.split(' ').map(n => n[0]).join('').toUpperCase();
    const colors = ['#F57C00', '#0288D1', '#2E7D32', '#C2185B', '#E67E22', '#1B4F72'];
    const avatarColor = colors[Math.floor(Math.random() * colors.length)];

    const newPost = new Post({
      userId: validUserId,
      authorName: authorName,
      avatarText: init.substring(0, 2),
      avatarColor,
      content,
      mediaUrl,
    });

    const savedPost = await newPost.save();
    return res.status(201).json({ success: true, post: savedPost });
  } catch (err) {
    console.error('Error creating post:', err);
    return res.status(500).json({ success: false, message: 'Failed to create post.' });
  }
});

// Fetch a single post by ID
app.get('/api/community/posts/:id', async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) {
      return res.status(404).json({ success: false, message: 'Post not found.' });
    }
    return res.status(200).json({ success: true, post });
  } catch (err) {
    console.error('Error fetching single post:', err);
    return res.status(500).json({ success: false, message: 'Failed to fetch post.' });
  }
});

// Fetch a single reel by ID
app.get('/api/community/reels/:id', async (req, res) => {
  try {
    const reel = await Reel.findById(req.params.id);
    if (!reel) {
      return res.status(404).json({ success: false, message: 'Reel not found.' });
    }
    return res.status(200).json({ success: true, reel });
  } catch (err) {
    console.error('Error fetching single reel:', err);
    return res.status(500).json({ success: false, message: 'Failed to fetch reel.' });
  }
});

// Render share preview page for a post
app.get('/share/post/:id', async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);
    if (!post) {
      return res.status(404).send('Post not found');
    }
    
    const baseUrl = `${req.protocol}://${req.get('host')}`;
    const mediaUrl = post.mediaUrl 
      ? (post.mediaUrl.startsWith('http') ? post.mediaUrl : `${baseUrl}${post.mediaUrl}`) 
      : '';
      
    res.send(`
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>KutumbSetu Post by ${post.authorName}</title>
        <!-- Open Graph Meta Tags for rich messaging previews -->
        <meta property="og:title" content="KutumbSetu Post by ${post.authorName}">
        <meta property="og:description" content="${post.content.replace(/"/g, '&quot;')}">
        \${mediaUrl ? \`<meta property="og:image" content="\${mediaUrl}">\` : ''}
        <meta property="og:type" content="article">
        <meta property="og:site_name" content="KutumbSetu">
        <style>
          @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Outfit:wght@500;700;800&display=swap');
          body {
            font-family: 'Inter', sans-serif;
            background: linear-gradient(135deg, #fff3e0 0%, #eceff1 100%);
            margin: 0;
            padding: 24px 16px;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            color: #1a202c;
          }
          .app-logo {
            font-family: 'Outfit', sans-serif;
            font-size: 28px;
            font-weight: 800;
            background: linear-gradient(135deg, #e67e22, #1b4f72);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 24px;
            letter-spacing: 0.5px;
          }
          .card {
            background: rgba(255, 255, 255, 0.85);
            backdrop-filter: blur(12px);
            -webkit-backdrop-filter: blur(12px);
            border: 1px solid rgba(255, 255, 255, 0.5);
            border-radius: 20px;
            max-width: 500px;
            width: 100%;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.05);
            overflow: hidden;
            transition: transform 0.3s ease;
          }
          .header {
            padding: 20px;
            display: flex;
            align-items: center;
            border-bottom: 1px solid rgba(0,0,0,0.05);
          }
          .avatar {
            width: 44px;
            height: 44px;
            border-radius: 50%;
            background: ${post.avatarColor || '#0288D1'};
            color: white;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            font-size: 16px;
            font-family: 'Outfit', sans-serif;
            margin-right: 14px;
            box-shadow: 0 4px 10px rgba(0,0,0,0.1);
          }
          .author-info {
            display: flex;
            flex-direction: column;
          }
          .author {
            font-weight: 700;
            color: #2d3748;
            font-size: 16px;
          }
          .tag {
            font-size: 11px;
            color: #718096;
            margin-top: 2px;
          }
          .content {
            padding: 20px;
            font-size: 15px;
            line-height: 1.6;
            color: #2d3748;
            white-space: pre-wrap;
          }
          .media-container {
            position: relative;
            width: 100%;
            background: #f7fafc;
            display: flex;
            justify-content: center;
            align-items: center;
            overflow: hidden;
          }
          .media {
            width: 100%;
            max-height: 380px;
            object-fit: cover;
            display: block;
          }
          .footer {
            padding: 24px 20px;
            text-align: center;
            background: rgba(255,255,255,0.4);
            border-top: 1px solid rgba(0,0,0,0.03);
          }
          .btn {
            display: inline-block;
            background: linear-gradient(135deg, #e67e22, #d35400);
            color: white;
            padding: 14px 32px;
            border-radius: 30px;
            text-decoration: none;
            font-weight: 700;
            font-size: 15px;
            font-family: 'Outfit', sans-serif;
            box-shadow: 0 6px 20px rgba(230, 126, 34, 0.4);
            transition: all 0.2s ease;
            animation: pulse 2s infinite;
          }
          .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(230, 126, 34, 0.5);
          }
          @keyframes pulse {
            0% { transform: scale(1); }
            50% { transform: scale(1.03); }
            100% { transform: scale(1); }
          }
        </style>
        <script>
          window.onload = function() {
            setTimeout(function() {
              window.location.href = "kutumbsetu://post/${post._id}";
            }, 500);
          };
        </script>
      </head>
      <body>
        <div class="app-logo">KutumbSetu</div>
        <div class="card">
          <div class="header">
            <div class="avatar">${post.avatarText || 'U'}</div>
            <div class="author-info">
              <div class="author">${post.authorName}</div>
              <div class="tag">Shared from KutumbSetu Feed</div>
            </div>
          </div>
          <div class="content">${post.content}</div>
          \${post.mediaUrl ? \`
            <div class="media-container">
              <img class="media" src="\${post.mediaUrl}" alt="Post Media">
            </div>
          \` : ''}
          <div class="footer">
            <a class="btn" href="kutumbsetu://post/${post._id}">Open in KutumbSetu App</a>
          </div>
        </div>
      </body>
      </html>
    `);
  } catch (err) {
    console.error('Error rendering post share page:', err);
    res.status(500).send('Server Error');
  }
});

// Render share preview page for a reel
app.get('/share/reel/:id', async (req, res) => {
  try {
    const reel = await Reel.findById(req.params.id);
    if (!reel) {
      return res.status(404).send('Reel not found');
    }
    
    const baseUrl = `${req.protocol}://${req.get('host')}`;
    const videoUrl = reel.videoUrl 
      ? (reel.videoUrl.startsWith('http') ? reel.videoUrl : `${baseUrl}${reel.videoUrl}`) 
      : '';
      
    res.send(`
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>KutumbSetu Reel by ${reel.authorName}</title>
        <meta property="og:title" content="KutumbSetu Reel by ${reel.authorName}">
        <meta property="og:description" content="${reel.caption.replace(/"/g, '&quot;')}">
        <meta property="og:type" content="video.other">
        <meta property="og:site_name" content="KutumbSetu">
        <style>
          @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Outfit:wght@500;700;800&display=swap');
          body {
            font-family: 'Inter', sans-serif;
            background: linear-gradient(135deg, #1b4f72 0%, #121212 100%);
            margin: 0;
            padding: 24px 16px;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            color: #ffffff;
          }
          .app-logo {
            font-family: 'Outfit', sans-serif;
            font-size: 28px;
            font-weight: 800;
            background: linear-gradient(135deg, #e67e22, #3498db);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 24px;
            letter-spacing: 0.5px;
          }
          .card {
            background: rgba(30, 41, 59, 0.7);
            backdrop-filter: blur(16px);
            -webkit-backdrop-filter: blur(16px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 20px;
            max-width: 500px;
            width: 100%;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
            overflow: hidden;
          }
          .header {
            padding: 20px;
            display: flex;
            align-items: center;
            border-bottom: 1px solid rgba(255,255,255,0.08);
          }
          .avatar {
            width: 44px;
            height: 44px;
            border-radius: 50%;
            background: ${reel.avatarColor || '#0288D1'};
            color: white;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            font-size: 16px;
            font-family: 'Outfit', sans-serif;
            margin-right: 14px;
            box-shadow: 0 4px 10px rgba(0,0,0,0.3);
          }
          .author-info {
            display: flex;
            flex-direction: column;
          }
          .author {
            font-weight: 700;
            color: #ffffff;
            font-size: 16px;
          }
          .tag {
            font-size: 11px;
            color: #94a3b8;
            margin-top: 2px;
          }
          .content {
            padding: 20px;
            font-size: 15px;
            line-height: 1.6;
            color: #e2e8f0;
            white-space: pre-wrap;
          }
          .video-container {
            position: relative;
            width: 100%;
            background: #000000;
            display: flex;
            justify-content: center;
            align-items: center;
            overflow: hidden;
          }
          .media-video {
            width: 100%;
            max-height: 450px;
            display: block;
          }
          .footer {
            padding: 24px 20px;
            text-align: center;
            background: rgba(15, 23, 42, 0.4);
            border-top: 1px solid rgba(255,255,255,0.05);
          }
          .btn {
            display: inline-block;
            background: linear-gradient(135deg, #e67e22, #d35400);
            color: white;
            padding: 14px 32px;
            border-radius: 30px;
            text-decoration: none;
            font-weight: 700;
            font-size: 15px;
            font-family: 'Outfit', sans-serif;
            box-shadow: 0 6px 20px rgba(230, 126, 34, 0.4);
            transition: all 0.2s ease;
            animation: pulse 2s infinite;
          }
          .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(230, 126, 34, 0.5);
          }
          @keyframes pulse {
            0% { transform: scale(1); }
            50% { transform: scale(1.03); }
            100% { transform: scale(1); }
          }
        </style>
        <script>
          window.onload = function() {
            setTimeout(function() {
              window.location.href = "kutumbsetu://reel/${reel._id}";
            }, 500);
          };
        </script>
      </head>
      <body>
        <div class="app-logo">KutumbSetu</div>
        <div class="card">
          <div class="header">
            <div class="avatar">${reel.avatarText || 'U'}</div>
            <div class="author-info">
              <div class="author">${reel.authorName}</div>
              <div class="tag">Shared from KutumbSetu Reels</div>
            </div>
          </div>
          <div class="content">${reel.caption}</div>
          \${videoUrl ? \`
            <div class="video-container">
              <video class="media-video" controls autoplay muted loop>
                <source src="\${videoUrl}" type="video/mp4">
                Your browser does not support the video tag.
              </video>
            </div>
          \` : ''}
          <div class="footer">
            <a class="btn" href="kutumbsetu://reel/${reel._id}">Open in KutumbSetu App</a>
          </div>
        </div>
      </body>
      </html>
    `);
  } catch (err) {
    console.error('Error rendering reel share page:', err);
    res.status(500).send('Server Error');
  }
});

// Toggle Post Like
app.post('/api/community/posts/:id/like', async (req, res) => {
  try {
    const { id } = req.params;
    const { userId } = req.body;
    if (!userId) {
      return res.status(400).json({ success: false, message: 'UserId is required.' });
    }
    const post = await Post.findById(id);
    if (!post) {
      return res.status(404).json({ success: false, message: 'Post not found.' });
    }

    const index = post.likes.indexOf(userId);
    if (index === -1) {
      post.likes.push(userId);
    } else {
      post.likes.splice(index, 1);
    }

    await post.save();
    return res.status(200).json({ success: true, likesCount: post.likes.length, isLiked: index === -1 });
  } catch (err) {
    console.error('Error liking post:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
});

// Comment on Post
app.post('/api/community/posts/:id/comment', async (req, res) => {
  try {
    const { id } = req.params;
    const { userId, content } = req.body;
    if (!userId || !content) {
      return res.status(400).json({ success: false, message: 'UserId and content are required.' });
    }
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }
    const post = await Post.findById(id);
    if (!post) {
      return res.status(404).json({ success: false, message: 'Post not found.' });
    }

    post.comments.push({
      userId,
      authorName: user.fullName,
      content,
    });

    await post.save();
    return res.status(201).json({ success: true, comments: post.comments });
  } catch (err) {
    console.error('Error commenting on post:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
});


// --- COMMUNITY REELS ENDPOINTS ---

// Fetch all reels (sorted by newest first)
app.get('/api/community/reels', async (req, res) => {
  try {
    const reels = await Reel.find({}).sort({ createdAt: -1 });
    return res.status(200).json({ success: true, reels });
  } catch (err) {
    console.error('Error fetching reels:', err);
    return res.status(500).json({ success: false, message: 'Failed to fetch reels.' });
  }
});

// Create new reel
app.post('/api/community/reels', async (req, res) => {
  try {
    const { userId, caption, videoBase64 } = req.body;
    if (!userId || !caption || !videoBase64) {
      return res.status(400).json({ success: false, message: 'UserId, caption, and video are required.' });
    }
    const validUserId = await getValidUserId(userId);
    const user = await User.findById(validUserId);
    const authorName = user ? user.fullName : 'Rajeshbhai Chauhan';

    const buffer = Buffer.from(videoBase64, 'base64');
    const filename = `reel-${Date.now()}-${Math.round(Math.random() * 1E9)}.mp4`;
    const filepath = path.join(uploadsDir, filename);
    fs.writeFileSync(filepath, buffer);
    const videoUrl = `/uploads/${filename}`;

    const init = authorName.split(' ').map(n => n[0]).join('').toUpperCase();
    const colors = ['#F57C00', '#0288D1', '#2E7D32', '#C2185B', '#E67E22', '#1B4F72'];
    const avatarColor = colors[Math.floor(Math.random() * colors.length)];

    const newReel = new Reel({
      userId: validUserId,
      authorName: authorName,
      avatarText: init.substring(0, 2),
      avatarColor,
      caption,
      videoUrl,
      audioTrack: `Original Audio - ${authorName}`,
    });

    const savedReel = await newReel.save();
    return res.status(201).json({ success: true, reel: savedReel });
  } catch (err) {
    console.error('Error creating reel:', err);
    return res.status(500).json({ success: false, message: 'Failed to create reel.' });
  }
});

// Toggle Reel Like
app.post('/api/community/reels/:id/like', async (req, res) => {
  try {
    const { id } = req.params;
    const { userId } = req.body;
    if (!userId) {
      return res.status(400).json({ success: false, message: 'UserId is required.' });
    }
    const reel = await Reel.findById(id);
    if (!reel) {
      return res.status(404).json({ success: false, message: 'Reel not found.' });
    }

    const index = reel.likes.indexOf(userId);
    if (index === -1) {
      reel.likes.push(userId);
    } else {
      reel.likes.splice(index, 1);
    }

    await reel.save();
    return res.status(200).json({ success: true, likesCount: reel.likes.length, isLiked: index === -1 });
  } catch (err) {
    console.error('Error liking reel:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
});

// Comment on Reel
app.post('/api/community/reels/:id/comment', async (req, res) => {
  try {
    const { id } = req.params;
    const { userId, content } = req.body;
    if (!userId || !content) {
      return res.status(400).json({ success: false, message: 'UserId and content are required.' });
    }
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }
    const reel = await Reel.findById(id);
    if (!reel) {
      return res.status(404).json({ success: false, message: 'Reel not found.' });
    }

    reel.comments.push({
      userId,
      authorName: user.fullName,
      content,
    });

    await reel.save();
    return res.status(201).json({ success: true, comments: reel.comments });
  } catch (err) {
    console.error('Error commenting on reel:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
});

// --- COMMENT LIKING & REPLYING ENDPOINTS ---

// Toggle Comment Like (handles both posts and reels)
app.post('/api/community/:type/:id/comment/:commentId/like', async (req, res) => {
  try {
    const { type, id, commentId } = req.params;
    const { userId } = req.body;
    if (!userId) {
      return res.status(400).json({ success: false, message: 'UserId is required.' });
    }

    const Model = type === 'posts' ? Post : Reel;
    const doc = await Model.findById(id);
    if (!doc) {
      return res.status(404).json({ success: false, message: 'Document not found.' });
    }

    const comment = doc.comments.id(commentId);
    if (!comment) {
      return res.status(404).json({ success: false, message: 'Comment not found.' });
    }

    comment.likes = comment.likes || [];
    const index = comment.likes.indexOf(userId);
    if (index === -1) {
      comment.likes.push(userId);
    } else {
      comment.likes.splice(index, 1);
    }

    await doc.save();
    return res.status(200).json({ success: true, comments: doc.comments });
  } catch (err) {
    console.error('Error liking comment:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
});

// Reply to Comment (handles both posts and reels)
app.post('/api/community/:type/:id/comment/:commentId/reply', async (req, res) => {
  try {
    const { type, id, commentId } = req.params;
    const { userId, content } = req.body;
    if (!userId || !content) {
      return res.status(400).json({ success: false, message: 'UserId and content are required.' });
    }

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }

    const Model = type === 'posts' ? Post : Reel;
    const doc = await Model.findById(id);
    if (!doc) {
      return res.status(404).json({ success: false, message: 'Document not found.' });
    }

    const comment = doc.comments.id(commentId);
    if (!comment) {
      return res.status(404).json({ success: false, message: 'Comment not found.' });
    }

    comment.replies = comment.replies || [];
    comment.replies.push({
      userId,
      authorName: user.fullName,
      content: content.trim(),
    });

    await doc.save();
    return res.status(201).json({ success: true, comments: doc.comments });
  } catch (err) {
    console.error('Error replying to comment:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
});

// Increment Post Share Count
app.post('/api/community/posts/:id/share', async (req, res) => {
  try {
    const { id } = req.params;
    const post = await Post.findById(id);
    if (!post) {
      return res.status(404).json({ success: false, message: 'Post not found.' });
    }

    post.sharesCount = (post.sharesCount || 0) + 1;
    await post.save();
    return res.status(200).json({ success: true, sharesCount: post.sharesCount });
  } catch (err) {
    console.error('Error sharing post:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
});

// Increment Reel Share Count
app.post('/api/community/reels/:id/share', async (req, res) => {
  try {
    const { id } = req.params;
    const reel = await Reel.findById(id);
    if (!reel) {
      return res.status(404).json({ success: false, message: 'Reel not found.' });
    }

    reel.sharesCount = (reel.sharesCount || 0) + 1;
    await reel.save();
    return res.status(200).json({ success: true, sharesCount: reel.sharesCount });
  } catch (err) {
    console.error('Error sharing reel:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
});

app.get('/api/users/by-phone/:phone', async (req, res) => {
  try {
    const sanitizedPhone = req.params.phone.replace(/\\s+/g, '').trim();
    let user = await User.findOne({ phoneNumber: sanitizedPhone });
    if (!user) {
      const profile = await Profile.findOne({ phoneNumber: sanitizedPhone });
      if (profile) {
        user = await User.findById(profile.userId);
      }
    }
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    return res.status(200).json({ success: true, user });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

app.patch('/api/users/:id/role', async (req, res) => {
  try {
    const { role } = req.body;
    if (!['user', 'admin', 'organizer'].includes(role)) {
      return res.status(400).json({ success: false, message: 'Invalid role' });
    }
    const user = await User.findByIdAndUpdate(req.params.id, { role }, { new: true });
    return res.status(200).json({ success: true, user });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

// ==========================================
// 2. IMAGE UPLOAD APIS
// ==========================================

app.post('/api/upload/banner', (req, res) => {
  upload.single('banner')(req, res, (err) => {
    if (err instanceof multer.MulterError) {
      if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(400).json({ success: false, message: 'File size exceeds maximum 5MB limit.' });
      }
      return res.status(400).json({ success: false, message: `Upload error: ${err.message}` });
    } else if (err) {
      return res.status(400).json({ success: false, message: err.message });
    }

    if (!req.file) {
      return res.status(400).json({ success: false, message: 'No file uploaded. Please select an image.' });
    }

    const relativeUrl = `/uploads/campaigns/${req.file.filename}`;
    return res.status(200).json({
      success: true,
      url: relativeUrl,
      filename: req.file.filename,
    });
  });
});

// ==========================================
// 3. CATEGORY APIS
// ==========================================

app.get('/api/categories', async (req, res) => {
  try {
    const categories = await CampaignCategory.find({ isActive: true }).sort({ name: 1 });
    return res.status(200).json({ success: true, categories });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

app.post('/api/categories', async (req, res) => {
  try {
    const { name, icon, description } = req.body;
    if (!name) {
      return res.status(400).json({ success: false, message: 'Category name is required' });
    }
    const slug = name.toLowerCase().replace(/[^a-z0-9]+/g, '-');
    const category = new CampaignCategory({ name, slug, icon: icon || 'category', description: description || '' });
    await category.save();
    return res.status(201).json({ success: true, category });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

// ==========================================
// 4. CAMPAIGN MANAGEMENT APIS
// ==========================================

// Create Campaign (SCRUM-67, SCRUM-69)
app.post('/api/campaigns', async (req, res) => {
  try {
    const {
      title,
      description,
      category,
      bannerUrl,
      startDate,
      endDate,
      status,
      targetAmount,
      objective,
      contactInfo,
      additionalNotes,
      createdBy,
      dynamicFields,
    } = req.body;

    if (!title || !description || !category || !startDate || !endDate) {
      return res.status(400).json({
        success: false,
        message: 'Required fields missing: title, description, category, startDate, endDate.',
      });
    }

    const start = new Date(startDate);
    const end = new Date(endDate);

    if (isNaN(start.getTime()) || isNaN(end.getTime())) {
      return res.status(400).json({ success: false, message: 'Invalid start or end date.' });
    }

    if (end <= start) {
      return res.status(400).json({ success: false, message: 'Campaign end date must be after start date.' });
    }

    if (targetAmount && (isNaN(targetAmount) || targetAmount < 0)) {
      return res.status(400).json({ success: false, message: 'Target amount must be a positive number.' });
    }

    const campaign = new Campaign({
      title: title.trim(),
      description: description.trim(),
      category: category.trim(),
      bannerUrl: bannerUrl ? bannerUrl.trim() : '',
      startDate: start,
      endDate: end,
      status: status || 'Active',
      targetAmount: targetAmount || 0,
      objective: objective ? objective.trim() : '',
      contactInfo: contactInfo || {},
      additionalNotes: additionalNotes ? additionalNotes.trim() : '',
      createdBy: createdBy || null,
      dynamicFields: dynamicFields || [],
    });

    const savedCampaign = await campaign.save();

    // Create Broadcast Announcement Notification (SCRUM-74)
    await Notification.create({
      userId: null,
      title: `New Campaign: ${savedCampaign.title}`,
      message: `A new ${savedCampaign.category} campaign has been launched! Check details and register now.`,
      type: 'CAMPAIGN_ANNOUNCEMENT',
      referenceId: savedCampaign._id.toString(),
    });

    return res.status(201).json({ success: true, campaign: savedCampaign });
  } catch (error) {
    console.error('Error creating campaign:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
});

// Get Campaigns with Filter & Search (SCRUM-65, SCRUM-68, SCRUM-71)
app.get('/api/campaigns', async (req, res) => {
  try {
    const { category, status, search } = req.query;
    let query = {};

    if (category && category !== 'All') {
      query.category = category;
    }

    if (search) {
      query.$or = [
        { title: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
        { category: { $regex: search, $options: 'i' } },
      ];
    }

    let campaigns = await Campaign.find(query).sort({ createdAt: -1 });

    // Intelligently compute status & apply status filter
    const now = new Date();
    const processedCampaigns = campaigns.map((item) => {
      const doc = item.toObject();
      if (doc.status !== 'Cancelled' && doc.status !== 'Draft') {
        const start = new Date(doc.startDate);
        const end = new Date(doc.endDate);
        if (now < start) {
          doc.effectiveStatus = 'Upcoming';
        } else if (now > end) {
          doc.effectiveStatus = 'Completed';
        } else {
          doc.effectiveStatus = 'Active';
        }
      } else {
        doc.effectiveStatus = doc.status;
      }
      return doc;
    });

    let finalCampaigns = processedCampaigns;
    if (status && status !== 'All') {
      finalCampaigns = processedCampaigns.filter((c) => c.effectiveStatus === status || c.status === status);
    }

    return res.status(200).json({ success: true, count: finalCampaigns.length, campaigns: finalCampaigns });
  } catch (error) {
    console.error('Error fetching campaigns:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
});

// Get Campaign by ID (SCRUM-69)
app.get('/api/campaigns/:id', async (req, res) => {
  try {
    const campaign = await Campaign.findById(req.params.id).populate('createdBy', 'fullName phoneNumber profilePhoto');
    if (!campaign) {
      return res.status(404).json({ success: false, message: 'Campaign not found.' });
    }

    const doc = campaign.toObject();
    const now = new Date();
    if (doc.status !== 'Cancelled' && doc.status !== 'Draft') {
      const start = new Date(doc.startDate);
      const end = new Date(doc.endDate);
      if (now < start) doc.effectiveStatus = 'Upcoming';
      else if (now > end) doc.effectiveStatus = 'Completed';
      else doc.effectiveStatus = 'Active';
    } else {
      doc.effectiveStatus = doc.status;
    }

    const totalRegistrations = await CampaignRegistration.countDocuments({
      campaignId: campaign._id,
      registrationStatus: { $ne: 'Cancelled' },
    });

    doc.totalRegistrations = totalRegistrations;
    return res.status(200).json({ success: true, campaign: doc });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

// Update Campaign (SCRUM-69)
app.put('/api/campaigns/:id', async (req, res) => {
  try {
    const { startDate, endDate, targetAmount } = req.body;

    if (startDate && endDate) {
      const start = new Date(startDate);
      const end = new Date(endDate);
      if (end <= start) {
        return res.status(400).json({ success: false, message: 'End date must be after start date.' });
      }
    }

    if (targetAmount !== undefined && (isNaN(targetAmount) || targetAmount < 0)) {
      return res.status(400).json({ success: false, message: 'Target amount must be a positive number.' });
    }

    const updatedCampaign = await Campaign.findByIdAndUpdate(req.params.id, { $set: req.body }, { new: true, runValidators: true });

    if (!updatedCampaign) {
      return res.status(404).json({ success: false, message: 'Campaign not found.' });
    }

    return res.status(200).json({ success: true, campaign: updatedCampaign });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

// Delete/Cancel Campaign (SCRUM-69, SCRUM-73)
app.delete('/api/campaigns/:id', async (req, res) => {
  try {
    const campaign = await Campaign.findByIdAndUpdate(req.params.id, { status: 'Cancelled' }, { new: true });
    if (!campaign) {
      return res.status(404).json({ success: false, message: 'Campaign not found.' });
    }
    return res.status(200).json({ success: true, message: 'Campaign has been cancelled successfully.', campaign });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

// Update Campaign Status (SCRUM-73)
app.patch('/api/campaigns/:id/status', async (req, res) => {
  try {
    const { status } = req.body;
    if (!['Draft', 'Upcoming', 'Active', 'Completed', 'Cancelled'].includes(status)) {
      return res.status(400).json({ success: false, message: 'Invalid status value.' });
    }

    const campaign = await Campaign.findByIdAndUpdate(req.params.id, { status }, { new: true });
    if (!campaign) {
      return res.status(404).json({ success: false, message: 'Campaign not found.' });
    }

    // Trigger status change notification
    if (status === 'Active') {
      await Notification.create({
        userId: null,
        title: `Campaign Now Active: ${campaign.title}`,
        message: `The campaign "${campaign.title}" is now active and taking registrations!`,
        type: 'CAMPAIGN_ACTIVE',
        referenceId: campaign._id.toString(),
      });
    } else if (status === 'Completed') {
      await Notification.create({
        userId: null,
        title: `Campaign Completed: ${campaign.title}`,
        message: `The campaign "${campaign.title}" has successfully ended. Thank you for your support!`,
        type: 'CAMPAIGN_COMPLETED',
        referenceId: campaign._id.toString(),
      });
    }

    return res.status(200).json({ success: true, campaign });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

// Share Campaign (SCRUM-72)
app.post('/api/campaigns/:id/share', async (req, res) => {
  try {
    const campaign = await Campaign.findById(req.params.id);
    if (!campaign) {
      return res.status(404).json({ success: false, message: 'Campaign not found.' });
    }

    const shareText = `Join KutumbSetu Campaign: *${campaign.title}*\nCategory: ${campaign.category}\n\n${campaign.description}\n\nDownload KutumbSetu App to participate!`;
    return res.status(200).json({
      success: true,
      shareData: {
        title: campaign.title,
        text: shareText,
        url: `https://kutumbsetu.org/campaigns/${campaign._id}`,
      },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

// ==========================================
// 5. CAMPAIGN REGISTRATION APIS
// ==========================================

// Register for Campaign (SCRUM-75, 76, 77, 78, 80, 81)
app.post('/api/campaigns/:id/register', async (req, res) => {
  try {
    const campaignId = req.params.id;
    const { userId, submittedData } = req.body;

    if (!userId) {
      return res.status(400).json({ success: false, message: 'User ID is required for registration.' });
    }

    // Check if Campaign exists
    const campaign = await Campaign.findById(campaignId);
    if (!campaign) {
      return res.status(404).json({ success: false, message: 'Campaign not found.' });
    }

    // Check if user exists
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User profile not found. Please register user profile first.' });
    }

    // Check duplicate registration
    const existingReg = await CampaignRegistration.findOne({
      campaignId,
      userId,
      registrationStatus: { $ne: 'Cancelled' },
    });

    if (existingReg) {
      return res.status(400).json({
        success: false,
        message: `You are already registered for "${campaign.title}". Registration ID: ${existingReg.registrationNumber}`,
        registration: existingReg,
      });
    }

    // Server-side Validation for Dynamic Fields (SCRUM-77)
    if (campaign.dynamicFields && campaign.dynamicFields.length > 0) {
      for (const field of campaign.dynamicFields) {
        if (field.required) {
          const val = submittedData ? submittedData[field.fieldName] : undefined;
          if (val === undefined || val === null || val === '') {
            return res.status(400).json({
              success: false,
              message: `Missing required registration field: ${field.label}`,
            });
          }
        }
      }
    }

    const regNumber = generateRegistrationNumber();
    const registration = new CampaignRegistration({
      campaignId,
      userId,
      registrationNumber: regNumber,
      submittedData: submittedData || {},
      registrationStatus: 'Registered',
    });

    const savedRegistration = await registration.save();

    // Create Confirmation Notification for User (SCRUM-81)
    await Notification.create({
      userId: user._id,
      title: `Registration Successful: ${campaign.title}`,
      message: `You have successfully registered for ${campaign.title}. Your Registration ID is ${regNumber}.`,
      type: 'REGISTRATION_CONFIRMATION',
      referenceId: savedRegistration._id.toString(),
    });

    return res.status(201).json({
      success: true,
      message: 'Registration successful!',
      registration: savedRegistration,
      campaignTitle: campaign.title,
    });
  } catch (error) {
    console.error('Error registering for campaign:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
});

// Admin: Get Registered User List for Campaign (SCRUM-79)
app.get('/api/campaigns/:id/registrations', async (req, res) => {
  try {
    const { status, search } = req.query;
    let query = { campaignId: req.params.id };

    if (status && status !== 'All') {
      query.registrationStatus = status;
    }

    let registrations = await CampaignRegistration.find(query)
      .populate('userId', 'fullName phoneNumber email city gender profilePhoto occupation')
      .sort({ registeredAt: -1 });

    if (search) {
      const searchRegex = new RegExp(search, 'i');
      registrations = registrations.filter((reg) => {
        const u = reg.userId;
        return (
          (u && u.fullName && searchRegex.test(u.fullName)) ||
          (u && u.phoneNumber && searchRegex.test(u.phoneNumber)) ||
          reg.registrationNumber.includes(search)
        );
      });
    }

    return res.status(200).json({ success: true, count: registrations.length, registrations });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

// User: View Their Own Registrations (SCRUM-82)
app.get('/api/campaign-registrations/my', async (req, res) => {
  try {
    const userId = req.headers['x-user-id'] || req.query.userId;
    if (!userId) {
      return res.status(400).json({ success: false, message: 'Authentication required. User ID header missing.' });
    }

    const registrations = await CampaignRegistration.find({ userId })
      .populate('campaignId', 'title category bannerUrl startDate endDate status location targetAmount amountRaised')
      .sort({ registeredAt: -1 });

    return res.status(200).json({ success: true, count: registrations.length, registrations });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

// Get Single Registration by ID (SCRUM-80, 82)
app.get('/api/campaign-registrations/:id', async (req, res) => {
  try {
    const registration = await CampaignRegistration.findById(req.params.id)
      .populate('campaignId')
      .populate('userId', 'fullName phoneNumber email city gender profilePhoto');

    if (!registration) {
      return res.status(404).json({ success: false, message: 'Registration record not found.' });
    }
    return res.status(200).json({ success: true, registration });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

// Admin: Update Registration Status (SCRUM-79)
app.patch('/api/campaign-registrations/:id/status', async (req, res) => {
  try {
    const { registrationStatus } = req.body;
    if (!['Registered', 'Pending', 'Approved', 'Rejected', 'Cancelled', 'Attended'].includes(registrationStatus)) {
      return res.status(400).json({ success: false, message: 'Invalid registration status.' });
    }

    const registration = await CampaignRegistration.findByIdAndUpdate(
      req.params.id,
      { registrationStatus },
      { new: true }
    ).populate('campaignId', 'title');

    if (!registration) {
      return res.status(404).json({ success: false, message: 'Registration record not found.' });
    }

    return res.status(200).json({ success: true, registration });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

// User: Cancel Registration (SCRUM-83)
app.patch('/api/campaign-registrations/:id/cancel', async (req, res) => {
  try {
    const userId = req.headers['x-user-id'] || req.body.userId;
    const registration = await CampaignRegistration.findById(req.params.id).populate('campaignId');

    if (!registration) {
      return res.status(404).json({ success: false, message: 'Registration record not found.' });
    }

    // Verify ownership
    if (userId && registration.userId.toString() !== userId.toString()) {
      return res.status(403).json({ success: false, message: 'Unauthorized. You can only cancel your own registrations.' });
    }

    if (registration.registrationStatus === 'Cancelled') {
      return res.status(400).json({ success: false, message: 'Registration is already cancelled.' });
    }

    registration.registrationStatus = 'Cancelled';
    registration.cancellationTimestamp = new Date();
    await registration.save();

    // Create Notification
    await Notification.create({
      userId: registration.userId,
      title: `Registration Cancelled`,
      message: `Your registration (${registration.registrationNumber}) for "${registration.campaignId.title}" has been cancelled.`,
      type: 'REGISTRATION_CANCELLED',
      referenceId: registration._id.toString(),
    });

    return res.status(200).json({ success: true, message: 'Registration cancelled successfully.', registration });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

// ==========================================
// 6. NOTIFICATION APIS
// ==========================================

app.get('/api/notifications/my', async (req, res) => {
  try {
    const userId = req.headers['x-user-id'] || req.query.userId;
    const query = userId ? { $or: [{ userId }, { userId: null }] } : { userId: null };
    const notifications = await Notification.find(query).sort({ createdAt: -1 }).limit(30);
    return res.status(200).json({ success: true, count: notifications.length, notifications });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});

// Start Server after MongoDB connection completes
const PORT = process.env.PORT || 5000;

const startServer = async () => {
  await connectDB();
  await seedDefaultCategories();
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
};

startServer();

