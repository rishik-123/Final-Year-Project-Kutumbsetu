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
const connectDB = require('./config/db');
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

const app = express();

// Connect to MongoDB
connectDB();

// Middleware
app.use(cors());
app.use(express.json({ limit: '100mb' }));
app.use(express.urlencoded({ limit: '100mb', extended: true }));

// Logger middleware for debugging request inputs
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  if (req.body && Object.keys(req.body).length) {
    console.log('Body:', JSON.stringify(req.body, null, 2));
  }
  next();
});

// Nodemailer configuration
const isGmail = (process.env.SMTP_HOST || '').includes('gmail.com');
const transportConfig = isGmail
  ? {
      host: 'smtp.gmail.com',
      port: 587,
      secure: false,
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
      },
      tls: {
        rejectUnauthorized: false,
        minVersion: 'TLSv1.2',
      },
    }
  : {
      host: process.env.SMTP_HOST || 'smtp.ethereal.email',
      port: parseInt(process.env.SMTP_PORT || '587'),
      secure: process.env.SMTP_SECURE === 'true',
      auth: {
        user: process.env.SMTP_USER || 'test@ethereal.email',
        pass: process.env.SMTP_PASS || 'testpassword',
      },
    };

const transporter = nodemailer.createTransport(transportConfig);

// Helper: Send OTP Email
const sendOtpEmail = (email, name, otp) => {
  const mailOptions = {
    from: '"KutumbSetu Portal" <no-reply@kutumbsetu.org>',
    to: email.toLowerCase().trim(),
    subject: 'KutumbSetu - Your Email Verification OTP',
    html: `
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
    `,
  };

  transporter.sendMail(mailOptions, (error, info) => {
    if (error) {
      console.error(`[Nodemailer ERROR] Failed to send OTP to ${email}:`, error);
    } else {
      console.log(`[Nodemailer SUCCESS] OTP email sent to ${email}: ${info.messageId}`);
    }
  });
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
    });
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

    // Look up if user is already registered
    const user = await User.findOne({ email: targetEmail });

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
 * @desc    Register a new user (FullName and Email only)
 * @access  Public
 */
app.post('/api/users/register', async (req, res) => {
  try {
    const { fullName, email, phoneNumber } = req.body;

    if (!fullName || !email) {
      return res.status(400).json({
        success: false,
        message: 'Required registration fields (fullName, email) are missing.',
      });
    }

    const targetEmail = email.toLowerCase().trim();

    // Check duplicate email
    const existingUser = await User.findOne({ email: targetEmail });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'Email address already registered. Please proceed to login.',
      });
    }

    let sanitizedPhone = '';
    if (phoneNumber) {
      sanitizedPhone = phoneNumber.replace(/\s+/g, '').trim();
      // Check duplicate phone number in active profiles
      const Profile = require('./models/Profile');
      const existingProfile = await Profile.findOne({ phoneNumber: sanitizedPhone });
      if (existingProfile) {
        return res.status(400).json({
          success: false,
          message: 'Phone number already registered. Please login or use a different number.',
        });
      }
    }

    // Create and save new user record
    const newUser = new User({
      fullName: fullName.trim(),
      email: targetEmail,
    });

    const savedUser = await newUser.save();

    console.log(`Successfully registered new user: ${savedUser.fullName} (${savedUser.email})`);

    // If phone number is provided, check if it matches a directory member
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
        const Profile = require('./models/Profile');
        const newProfile = new Profile({
          userId: savedUser._id,
          gender: directoryMember.gender || 'Male',
          dateOfBirth: directoryMember.dateOfBirth || '',
          phoneNumber: directoryMember.phoneNumber || sanitizedPhone,
          profilePhoto: directoryMember.profilePhoto || '',
          bloodGroup: directoryMember.bloodGroup || '',
          village: directoryMember.nativePlace || directoryMember.village || '',
          city: directoryMember.city || '',
          state: directoryMember.state || '',
          address: directoryMember.address || '',
          qualification: directoryMember.education || directoryMember.qualification || '',
          profession: directoryMember.occupation || directoryMember.profession || '',
          fatherName: directoryMember.fatherName || '',
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
        console.log(`Successfully created linked profile for ${savedUser.fullName}`);
      }
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
      isDeceased
    } = req.body;

    if (!userId || !gender || !dateOfBirth || !phoneNumber || !city) {
      return res.status(400).json({
        success: false,
        message: 'Required profile completion fields (userId, gender, dateOfBirth, phoneNumber, city) are missing.',
      });
    }

    const validUserId = await getValidUserId(userId);
    let profile = await Profile.findOne({ userId: validUserId });

    let finalFamilyId = familyId || '';
    if (!finalFamilyId) {
      if (profile && profile.familyId) {
        finalFamilyId = profile.familyId;
      } else {
        const user = await User.findById(validUserId);
        const name = user ? user.fullName : '';
        finalFamilyId = generateFamilyId(name, dateOfBirth);
      }
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
        bloodGroup: p.bloodGroup,
        profilePhoto: p.profilePhoto,
        familyId: p.familyId,
        relationshipToHead: p.relationshipToHead,
        motherName: p.motherName,
        spouseName: p.spouseName,
        familyHeadPhone: p.familyHeadPhone,
        fatherName: p.fatherName,
        isDeceased: p.isDeceased || false,
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

// 2. Fetch Matrimonial Profile by User ID (applies masking based on visibility settings)
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

    // Mask fields if not own profile and visibility settings are disabled
    const isOwnProfile = requesterId && requesterId.toString() === userId.toString();
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
      requesterId, page = 1, limit = 10
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

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
