require('dotenv').config();
const express = require('express');
const cors = require('cors');
const connectDB = require('./config/db');
const OtpVerification = require('./models/OtpVerification');
const User = require('./models/User');

const app = express();

// Connect to MongoDB
connectDB();

// Middleware
app.use(cors());
app.use(express.json());

// Logger middleware for debugging request inputs
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  if (req.body && Object.keys(req.body).length) {
    console.log('Body:', JSON.stringify(req.body, null, 2));
  }
  next();
});

// Helper: Generate a random 6-digit OTP
const generateRandomOtp = () => {
  const digits = '0123456789';
  let otp = '';
  for (let i = 0; i < 6; i++) {
    otp += digits[Math.floor(Math.random() * 10)];
  }
  return otp;
};

/**
 * @route   POST /api/auth/send-otp
 * @desc    Generate and save a 6-digit temporary OTP for a phone number
 * @access  Public
 */
app.post('/api/auth/send-otp', async (req, res) => {
  try {
    const { phone } = req.body;

    if (!phone) {
      return res.status(400).json({ success: false, message: 'Phone number is required.' });
    }

    const sanitizedPhone = phone.replace(/\s+/g, '').trim();
    const otp = generateRandomOtp();
    
    // OTP Expiry duration: 5 minutes
    const createdAt = new Date();
    const expiresAt = new Date(createdAt.getTime() + 5 * 60 * 1000);

    // Save temporary OTP record to MongoDB
    const otpDoc = new OtpVerification({
      phone: sanitizedPhone,
      otp,
      createdAt,
      expiresAt,
    });

    await otpDoc.save();

    console.log(`Saved OTP ${otp} for phone ${sanitizedPhone}. Expires at ${expiresAt}`);

    return res.status(200).json({
      success: true,
      otp,
    });
  } catch (error) {
    console.error('Error in send-otp:', error);
    return res.status(500).json({ success: false, message: 'Server error. Failed to generate OTP.' });
  }
});

/**
 * @route   POST /api/auth/verify-otp
 * @desc    Verify the 6-digit OTP matches and has not expired
 * @access  Public
 */
app.post('/api/auth/verify-otp', async (req, res) => {
  try {
    const { phone, otp } = req.body;

    if (!phone || !otp) {
      return res.status(400).json({ success: false, message: 'Phone number and OTP code are required.' });
    }

    const sanitizedPhone = phone.replace(/\s+/g, '').trim();

    // Fetch the latest OTP document for this phone number
    const latestOtpDoc = await OtpVerification.findOne({ phone: sanitizedPhone }).sort({ createdAt: -1 });

    if (!latestOtpDoc) {
      return res.status(400).json({ success: false, message: 'Invalid OTP' });
    }

    // Verify OTP matches
    if (latestOtpDoc.otp !== otp.trim()) {
      return res.status(400).json({ success: false, message: 'Invalid OTP' });
    }

    // Verify OTP has not expired
    const currentTime = new Date();
    if (currentTime > latestOtpDoc.expiresAt) {
      return res.status(400).json({ success: false, message: 'OTP expired. Please request again.' });
    }

    // Delete the verification doc after successful verify to prevent reuse
    await OtpVerification.deleteOne({ _id: latestOtpDoc._id });

    return res.status(200).json({
      success: true,
    });
  } catch (error) {
    console.error('Error in verify-otp:', error);
    return res.status(500).json({ success: false, message: 'Server error. Failed to verify OTP.' });
  }
});

/**
 * @route   POST /api/users/register
 * @desc    Register a new user and save details in MongoDB
 * @access  Public
 */
app.post('/api/users/register', async (req, res) => {
  try {
    const {
      fullName,
      surname,
      fatherName,
      phoneNumber,
      gender,
      dateOfBirth,
      nativePlace,
      address,
      city,
      state,
      maritalStatus,
      occupation,
      profilePhoto,
    } = req.body;

    if (!fullName || !phoneNumber || !gender || !dateOfBirth || !city) {
      return res.status(400).json({
        success: false,
        message: 'Required registration fields (fullName, phoneNumber, gender, dateOfBirth, city) are missing.',
      });
    }

    const sanitizedPhone = phoneNumber.replace(/\s+/g, '').trim();

    // Check if user already exists
    const existingUser = await User.findOne({ phoneNumber: sanitizedPhone });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'Phone number already registered. Please proceed to login.',
      });
    }

    // Create and save new user record
    const newUser = new User({
      fullName: fullName.trim(),
      surname: surname ? surname.trim() : '',
      fatherName: fatherName ? fatherName.trim() : '',
      phoneNumber: sanitizedPhone,
      gender: gender.trim(),
      dateOfBirth: dateOfBirth.trim(),
      nativePlace: nativePlace ? nativePlace.trim() : '',
      address: address ? address.trim() : (nativePlace ? nativePlace.trim() : ''),
      city: city.trim(),
      state: state ? state.trim() : '',
      maritalStatus: maritalStatus ? maritalStatus.trim() : '',
      occupation: occupation ? occupation.trim() : '',
      profilePhoto: profilePhoto ? profilePhoto.trim() : '',
    });

    const savedUser = await newUser.save();

    console.log(`Successfully registered new user: ${savedUser.fullName} (${savedUser.phoneNumber})`);

    return res.status(201).json({
      success: true,
      user: savedUser,
    });
  } catch (error) {
    console.error('Error in register:', error);
    return res.status(500).json({ success: false, message: 'Server error. User registration failed.' });
  }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
