require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const multer = require('multer');
const connectDB = require('./config/db');

// Models
const OtpVerification = require('./models/OtpVerification');
const User = require('./models/User');
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
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Static route for uploaded images
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Logger middleware for debugging request inputs
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

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

app.post('/api/auth/send-otp', async (req, res) => {
  try {
    const { phone } = req.body;
    if (!phone) {
      return res.status(400).json({ success: false, message: 'Phone number is required.' });
    }
    const sanitizedPhone = phone.replace(/\s+/g, '').trim();
    const otp = generateRandomOtp();
    const createdAt = new Date();
    const expiresAt = new Date(createdAt.getTime() + 5 * 60 * 1000);

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
    console.error('Error in send-otp:', error);
    return res.status(500).json({ success: false, message: 'Server error. Failed to generate OTP.' });
  }
});

app.post('/api/auth/verify-otp', async (req, res) => {
  try {
    const { phone, otp } = req.body;
    if (!phone || !otp) {
      return res.status(400).json({ success: false, message: 'Phone number and OTP code are required.' });
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
    const user = await User.findOne({ phoneNumber: sanitizedPhone });

    return res.status(200).json({
      success: true,
      isExistingUser: !!user,
      user: user || null,
    });
  } catch (error) {
    console.error('Error in verify-otp:', error);
    return res.status(500).json({ success: false, message: 'Server error. Failed to verify OTP.' });
  }
});

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
      role,
    } = req.body;

    if (!fullName || !phoneNumber || !gender || !dateOfBirth || !city) {
      return res.status(400).json({
        success: false,
        message: 'Required registration fields are missing.',
      });
    }

    const sanitizedPhone = phoneNumber.replace(/\s+/g, '').trim();
    const existingUser = await User.findOne({ phoneNumber: sanitizedPhone });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'Phone number already registered. Please proceed to login.',
      });
    }

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
      role: role && ['admin', 'organizer', 'user'].includes(role) ? role : 'user',
    });

    const savedUser = await newUser.save();
    return res.status(201).json({ success: true, user: savedUser });
  } catch (error) {
    console.error('Error in register:', error);
    return res.status(500).json({ success: false, message: 'Server error. User registration failed.' });
  }
});

app.get('/api/users/by-phone/:phone', async (req, res) => {
  try {
    const sanitizedPhone = req.params.phone.replace(/\s+/g, '').trim();
    const user = await User.findOne({ phoneNumber: sanitizedPhone });
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

