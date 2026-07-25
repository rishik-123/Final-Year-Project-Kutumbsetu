require('dotenv').config();
const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const connectDB = require('./config/db');
const OtpVerification = require('./models/OtpVerification');
const User = require('./models/User');

// Self-healing database sync to copy users between 'users' and 'directory' collections
const syncCollections = async () => {
  try {
    const dirUsers = await User.DirectoryUser.find({});
    for (const dirUser of dirUsers) {
      const exists = await User.findOne({ phoneNumber: dirUser.phoneNumber });
      if (!exists) {
        console.log(`Sync: Copying ${dirUser.fullName} to 'users' collection...`);
        const userObj = dirUser.toObject();
        const newUser = new User({
          fullName: userObj.fullName,
          surname: userObj.surname,
          fatherName: userObj.fatherName,
          phoneNumber: userObj.phoneNumber,
          gender: userObj.gender,
          dateOfBirth: userObj.dateOfBirth,
          nativePlace: userObj.nativePlace,
          address: userObj.address,
          city: userObj.city,
          state: userObj.state,
          maritalStatus: userObj.maritalStatus,
          occupation: userObj.occupation,
          education: userObj.education,
          bloodGroup: userObj.bloodGroup,
          profilePhoto: userObj.profilePhoto,
          familyId: userObj.familyId,
          familyName: userObj.familyName,
          relationshipToHead: userObj.relationshipToHead,
          motherName: userObj.motherName,
          spouseName: userObj.spouseName,
          familyHeadPhone: userObj.familyHeadPhone,
        });
        await newUser.save();
      }
    }

    const mainUsers = await User.find({});
    for (const mainUser of mainUsers) {
      const exists = await User.DirectoryUser.findOne({ phoneNumber: mainUser.phoneNumber });
      if (!exists) {
        console.log(`Sync: Copying ${mainUser.fullName} to 'directory' collection...`);
        const userObj = mainUser.toObject();
        const newDirUser = new User.DirectoryUser({
          fullName: userObj.fullName,
          surname: userObj.surname,
          fatherName: userObj.fatherName,
          phoneNumber: userObj.phoneNumber,
          gender: userObj.gender,
          dateOfBirth: userObj.dateOfBirth,
          nativePlace: userObj.nativePlace,
          address: userObj.address,
          city: userObj.city,
          state: userObj.state,
          maritalStatus: userObj.maritalStatus,
          occupation: userObj.occupation,
          education: userObj.education,
          bloodGroup: userObj.bloodGroup,
          profilePhoto: userObj.profilePhoto,
          familyId: userObj.familyId,
          familyName: userObj.familyName,
          relationshipToHead: userObj.relationshipToHead,
          motherName: userObj.motherName,
          spouseName: userObj.spouseName,
          familyHeadPhone: userObj.familyHeadPhone,
        });
        await newDirUser.save();
      }
    }
    console.log('Sync: Collections synchronization complete.');
  } catch (err) {
    console.error('Error in syncCollections:', err);
  }
};

mongoose.connection.once('open', () => {
  console.log('MongoDB connection open. Running collections sync...');
  syncCollections();
});

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
      education,
      bloodGroup,
      profilePhoto,
      familyId,
      familyName,
      relationshipToHead,
      motherName,
      spouseName,
      familyHeadPhone,
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
      education: education ? education.trim() : '',
      bloodGroup: bloodGroup ? bloodGroup.trim() : '',
      profilePhoto: profilePhoto ? profilePhoto.trim() : '',
      familyId: familyId ? familyId.trim() : '',
      familyName: familyName ? familyName.trim() : '',
      relationshipToHead: relationshipToHead ? relationshipToHead.trim() : '',
      motherName: motherName ? motherName.trim() : '',
      spouseName: spouseName ? spouseName.trim() : '',
      familyHeadPhone: familyHeadPhone ? familyHeadPhone.replace(/\s+/g, '').trim() : '',
    });

    const savedUser = await newUser.save();

    // Also save user to the 'directory' collection
    const newDirUser = new User.DirectoryUser({
      fullName: savedUser.fullName,
      surname: savedUser.surname,
      fatherName: savedUser.fatherName,
      phoneNumber: savedUser.phoneNumber,
      gender: savedUser.gender,
      dateOfBirth: savedUser.dateOfBirth,
      nativePlace: savedUser.nativePlace,
      address: savedUser.address,
      city: savedUser.city,
      state: savedUser.state,
      maritalStatus: savedUser.maritalStatus,
      occupation: savedUser.occupation,
      education: savedUser.education,
      bloodGroup: savedUser.bloodGroup,
      profilePhoto: savedUser.profilePhoto,
      familyId: savedUser.familyId,
      familyName: savedUser.familyName,
      relationshipToHead: savedUser.relationshipToHead,
      motherName: savedUser.motherName,
      spouseName: savedUser.spouseName,
      familyHeadPhone: savedUser.familyHeadPhone,
    });
    await newDirUser.save();

    console.log(`Successfully registered new user: ${savedUser.fullName} (${savedUser.phoneNumber}) across both collections`);

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
 * @route   GET /api/users/profile/:phoneNumber
 * @desc    Fetch a specific user profile by phone number from MongoDB
 * @access  Public
 */
app.get('/api/users/profile/:phoneNumber', async (req, res) => {
  try {
    const { phoneNumber } = req.params;
    if (!phoneNumber) {
      return res.status(400).json({ success: false, message: 'Phone number is required.' });
    }
    const sanitizedPhone = phoneNumber.replace(/\s+/g, '').trim();
    const user = await User.findOne({ phoneNumber: sanitizedPhone });
    if (!user) {
      return res.status(404).json({ success: false, message: 'User profile not found.' });
    }
    return res.status(200).json({ success: true, user });
  } catch (error) {
    console.error('Error fetching user profile:', error);
    return res.status(500).json({ success: false, message: 'Server error fetching profile.' });
  }
});

/**
 * @route   GET /api/users/all
 * @desc    Fetch all registered users from MongoDB for directory syncing
 */
app.get('/api/users/all', async (req, res) => {
  try {
    const users = await User.find({});
    return res.status(200).json({ success: true, users });
  } catch (error) {
    console.error('Error fetching all users:', error);
    return res.status(500).json({ success: false, message: 'Server error fetching users list.' });
  }
});

/**
 * @route   GET /api/family/my-tree
 * @desc    Fetch family members of the authenticated user in a tree structure
 * @access  Protected (by custom x-user-phone header)
 */
app.get('/api/family/my-tree', async (req, res) => {
  try {
    const userPhone = req.headers['x-user-phone'];
    if (!userPhone) {
      return res.status(401).json({ success: false, message: 'Unauthorized. Phone number header missing.' });
    }

    const sanitizedPhone = userPhone.replace(/\s+/g, '').trim();
    const currentUser = await User.findOne({ phoneNumber: sanitizedPhone });
    if (!currentUser) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }

    const familyId = currentUser.familyId;
    if (!familyId) {
      return res.status(200).json({
        success: true,
        tree: null,
        message: 'No family tree found. Please update your profile with a Family ID.'
      });
    }

    // Fetch all family members sharing same familyId
    const familyMembers = await User.find({ familyId });

    // Helper to make a node matching tree data structure requirements
    const makeNode = (m) => {
      if (!m) return null;
      return {
        id: m._id.toString(),
        name: m.fullName + (m.surname ? ' ' + m.surname : ''),
        photo: m.profilePhoto || '',
        relation: m.relationshipToHead || 'Unknown',
        parentId: null,
        children: []
      };
    };

    // Group members by relation
    let gf = null, gm = null, father = null, mother = null, self = null, spouse = null;
    let fil = null, mil = null;
    const sons = [], daughters = [], uncles = [], aunts = [], cousins = [], siblings = [], sibsInLaw = [], nephews = [], nieces = [], guardians = [], unknowns = [];

    familyMembers.forEach(m => {
      const rel = (m.relationshipToHead || '').trim().toLowerCase();
      if (rel === 'grandfather') gf = m;
      else if (rel === 'grandmother') gm = m;
      else if (rel === 'father') father = m;
      else if (rel === 'mother') mother = m;
      else if (rel === 'self') self = m;
      else if (rel === 'wife' || rel === 'husband' || rel === 'spouse') spouse = m;
      else if (rel === 'father-in-law') fil = m;
      else if (rel === 'mother-in-law') mil = m;
      else if (rel === 'son') sons.push(m);
      else if (rel === 'daughter') daughters.push(m);
      else if (rel === 'uncle') uncles.push(m);
      else if (rel === 'aunt') aunts.push(m);
      else if (rel === 'cousin') cousins.push(m);
      else if (rel === 'brother' || rel === 'sister') siblings.push(m);
      else if (rel === 'brother-in-law' || rel === 'sister-in-law') sibsInLaw.push(m);
      else if (rel === 'nephew') nephews.push(m);
      else if (rel === 'niece') nieces.push(m);
      else if (rel === 'guardian') guardians.push(m);
      else unknowns.push(m);
    });

    // Create nodes for primary structural points
    const selfNode = makeNode(self);
    const spouseNode = makeNode(spouse);
    const fNode = makeNode(father);
    const mNode = makeNode(mother);
    const gfNode = makeNode(gf);
    const gmNode = makeNode(gm);
    const filNode = makeNode(fil);
    const milNode = makeNode(mil);

    // Map of nodes for quick reference
    const allNodesMap = {};
    if (selfNode) allNodesMap[selfNode.id] = selfNode;
    if (spouseNode) allNodesMap[spouseNode.id] = spouseNode;
    if (fNode) allNodesMap[fNode.id] = fNode;
    if (mNode) allNodesMap[mNode.id] = mNode;
    if (gfNode) allNodesMap[gfNode.id] = gfNode;
    if (gmNode) allNodesMap[gmNode.id] = gmNode;
    if (filNode) allNodesMap[filNode.id] = filNode;
    if (milNode) allNodesMap[milNode.id] = milNode;

    // Children of Self & Spouse (Sons, Daughters, Guardians, Unknowns)
    if (selfNode) {
      if (spouseNode) {
        selfNode.children.push(spouseNode);
        spouseNode.parentId = selfNode.id;
      }
      sons.forEach(s => {
        const n = makeNode(s);
        selfNode.children.push(n);
        n.parentId = selfNode.id;
        allNodesMap[n.id] = n;
      });
      daughters.forEach(d => {
        const n = makeNode(d);
        selfNode.children.push(n);
        n.parentId = selfNode.id;
        allNodesMap[n.id] = n;
      });
      guardians.forEach(g => {
        const n = makeNode(g);
        selfNode.children.push(n);
        n.parentId = selfNode.id;
        allNodesMap[n.id] = n;
      });
      unknowns.forEach(u => {
        const n = makeNode(u);
        selfNode.children.push(n);
        n.parentId = selfNode.id;
        allNodesMap[n.id] = n;
      });
    }

    // Siblings
    const sibNodes = siblings.map(s => {
      const n = makeNode(s);
      allNodesMap[n.id] = n;
      return n;
    });

    if (sibNodes.length > 0) {
      const mainSib = sibNodes[0];
      nephews.forEach(nep => {
        const n = makeNode(nep);
        mainSib.children.push(n);
        n.parentId = mainSib.id;
        allNodesMap[n.id] = n;
      });
      nieces.forEach(nie => {
        const n = makeNode(nie);
        mainSib.children.push(n);
        n.parentId = mainSib.id;
        allNodesMap[n.id] = n;
      });
    }

    // Children of Father & Mother
    if (fNode) {
      if (mNode) {
        fNode.children.push(mNode);
        mNode.parentId = fNode.id;
      }
      if (selfNode) {
        fNode.children.push(selfNode);
        selfNode.parentId = fNode.id;
      }
      sibNodes.forEach(sib => {
        fNode.children.push(sib);
        sib.parentId = fNode.id;
      });
    } else if (mNode) {
      if (selfNode) {
        mNode.children.push(selfNode);
        selfNode.parentId = mNode.id;
      }
      sibNodes.forEach(sib => {
        mNode.children.push(sib);
        sib.parentId = mNode.id;
      });
    }

    // Children of Grandfather & Grandmother
    const uncleNodes = uncles.map(u => {
      const n = makeNode(u);
      allNodesMap[n.id] = n;
      return n;
    });
    const auntNodes = aunts.map(a => {
      const n = makeNode(a);
      allNodesMap[n.id] = n;
      return n;
    });

    if (uncleNodes.length > 0) {
      const mainUncle = uncleNodes[0];
      if (auntNodes.length > 0) {
        mainUncle.children.push(auntNodes[0]);
        auntNodes[0].parentId = mainUncle.id;
      }
      cousins.forEach(c => {
        const n = makeNode(c);
        mainUncle.children.push(n);
        n.parentId = mainUncle.id;
        allNodesMap[n.id] = n;
      });
    }

    if (gfNode) {
      if (gmNode) {
        gfNode.children.push(gmNode);
        gmNode.parentId = gfNode.id;
      }
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

    // Father-in-law & Mother-in-law children
    const sibsInLawNodes = sibsInLaw.map(s => {
      const n = makeNode(s);
      allNodesMap[n.id] = n;
      return n;
    });

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

    // Select the root of the hierarchy
    let root = null;
    if (gfNode) root = gfNode;
    else if (gmNode) root = gmNode;
    else if (filNode) root = filNode;
    else if (milNode) root = milNode;
    else if (fNode) root = fNode;
    else if (mNode) root = mNode;
    else if (selfNode) root = selfNode;
    else if (spouseNode) root = spouseNode;
    else if (uncleNodes.length > 0) root = uncleNodes[0];
    else if (sibNodes.length > 0) root = sibNodes[0];
    else if (familyMembers.length > 0) {
      root = makeNode(familyMembers[0]);
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

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
