const mongoose = require('mongoose');
const Counter = require('../models/Counter');
const Member = require('../models/Member');
const User = require('../models/User');
const Profile = require('../models/Profile');
const MatrimonialProfile = require('../models/MatrimonialProfile');

/**
 * Escape regular expression special characters
 */
function escapeRegex(text) {
  if (!text) return '';
  return text.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&');
}

/**
 * Atomically generate the next sequential unique Member ID (e.g. MEM001, MEM002, ...)
 */
async function getNextMemberId() {
  const counter = await Counter.findOneAndUpdate(
    { id: 'memberId' },
    { $inc: { seq: 1 } },
    { new: true, upsert: true }
  );
  const seqStr = String(counter.seq).padStart(3, '0');
  return `MEM${seqStr}`;
}

/**
 * Split a full name into firstName, middleName, lastName
 */
function splitFullName(fullName) {
  const clean = (fullName || '').trim();
  if (!clean) return { firstName: '', middleName: '', lastName: '' };
  const parts = clean.split(/\s+/);
  if (parts.length === 1) {
    return { firstName: parts[0], middleName: '', lastName: '' };
  } else if (parts.length === 2) {
    return { firstName: parts[0], middleName: '', lastName: parts[1] };
  } else {
    return {
      firstName: parts[0],
      middleName: parts.slice(1, -1).join(' '),
      lastName: parts[parts.length - 1],
    };
  }
}

function normalizePhone(p) {
  if (!p) return '';
  const digits = String(p).replace(/\D/g, '');
  return digits.length >= 10 ? digits.slice(-10) : digits;
}

function areNamesEquivalent(nameA, nameB) {
  if (!nameA || !nameB) return false;
  const a = nameA.toLowerCase().trim().replace(/[^a-z0-9\s]/g, '').split(/\s+/).filter(Boolean);
  const b = nameB.toLowerCase().trim().replace(/[^a-z0-9\s]/g, '').split(/\s+/).filter(Boolean);
  if (a.length === 0 || b.length === 0) return false;
  if (a.join(' ') === b.join(' ')) return true;
  // Match single-word first name with full name (e.g. "Rishik" and "Rishik Jariwala")
  if (a.length === 1 && b.length >= 2 && a[0] === b[0]) return true;
  if (b.length === 1 && a.length >= 2 && b[0] === a[0]) return true;
  // Match first name and last name (e.g. "Rishik Jariwala" and "Rishik Alak Jariwala")
  if (a.length >= 2 && b.length >= 2) {
    if (a[0] === b[0] && a[a.length - 1] === b[b.length - 1]) return true;
  }
  return false;
}

/**
 * Resolve an existing member or create a new one with strict duplicate prevention
 */
async function resolveOrCreateMember({
  knownId,
  name,
  gender,
  maidenName,
  city,
  village,
  phoneNumber,
  email,
  familyId,
  userId,
  isDeceased,
}) {
  const cleanName = (name || '').trim();
  if (!cleanName && !knownId && !userId) return null;

  // 1. If knownId is provided, look up by memberId
  if (knownId && knownId.trim()) {
    const existing = await Member.findOne({ memberId: knownId.trim() });
    if (existing) {
      if (userId && !existing.userId) {
        existing.userId = userId;
        await existing.save();
      }
      return existing;
    }
  }

  // 2. If userId is provided, look up by userId
  if (userId) {
    const existingByUser = await Member.findOne({ userId });
    if (existingByUser) return existingByUser;
  }

  // 3. If phoneNumber is provided, look up by normalized 10-digit phone
  const cleanPhone = (phoneNumber || '').replace(/\s+/g, '').trim();
  const normPhone = normalizePhone(cleanPhone);
  if (normPhone && normPhone.length >= 10) {
    const phoneRegex = new RegExp(`${normPhone}$`);
    const existingByPhone = await Member.findOne({ phoneNumber: phoneRegex });
    if (existingByPhone) {
      if (userId && !existingByPhone.userId) {
        existingByPhone.userId = userId;
      }
      if (email && !existingByPhone.email) {
        existingByPhone.email = (email || '').toLowerCase().trim();
      }
      await existingByPhone.save();
      return existingByPhone;
    }
  }

  // 4. If email is provided, look up by email
  const cleanEmail = (email || '').toLowerCase().trim();
  if (cleanEmail && !cleanEmail.includes('_demo_')) {
    const existingByEmail = await Member.findOne({ email: cleanEmail });
    if (existingByEmail) {
      if (userId && !existingByEmail.userId) {
        existingByEmail.userId = userId;
      }
      if (cleanPhone && !existingByEmail.phoneNumber) {
        existingByEmail.phoneNumber = cleanPhone;
      }
      await existingByEmail.save();
      return existingByEmail;
    }
  }

  // 5. Name-based match check (prevent creating duplicate if name already exists)
  if (cleanName) {
    const allMembers = await Member.find({});
    for (const m of allMembers) {
      if (areNamesEquivalent(m.fullName, cleanName)) {
        if (gender && m.gender && gender !== m.gender) continue;
        if (userId && !m.userId) {
          m.userId = userId;
        }
        if (cleanPhone && !m.phoneNumber) {
          m.phoneNumber = cleanPhone;
        }
        if (cleanEmail && !m.email) {
          m.email = cleanEmail;
        }
        await m.save();
        return m;
      }
    }
  }

  // 6. No existing member found: create a new one with a dynamic sequential Member ID
  const newMemberId = await getNextMemberId();
  const nameParts = splitFullName(cleanName);

  const newMember = new Member({
    memberId: newMemberId,
    userId: userId || null,
    fullName: cleanName,
    firstName: nameParts.firstName,
    middleName: nameParts.middleName,
    lastName: nameParts.lastName,
    maidenName: (maidenName || '').trim(),
    gender: gender || 'Male',
    dateOfBirth: '',
    phoneNumber: cleanPhone,
    email: cleanEmail,
    city: (city || '').trim(),
    village: (village || '').trim(),
    familyId: (familyId || '').trim(),
    isDeceased: isDeceased || false,
  });

  await newMember.save();
  console.log(`[MemberService] Created new member: ${newMember.fullName} (ID: ${newMember.memberId})`);
  return newMember;
}

/**
 * Primary Name-based fuzzy and token search across all members
 */
async function searchMembers({ query, gender, limit = 20 }) {
  if (!query || !query.trim()) {
    return [];
  }

  const queryStr = query.trim();
  const tokens = queryStr.split(/\s+/).filter(Boolean);
  const tokenRegexes = tokens.map(t => new RegExp(escapeRegex(t), 'i'));

  // Match if every token appears in at least one of the searchable fields
  const andConditions = tokenRegexes.map(r => ({
    $or: [
      { fullName: r },
      { firstName: r },
      { middleName: r },
      { lastName: r },
      { maidenName: r },
      { memberId: r },
      { phoneNumber: r },
      { city: r },
      { village: r },
    ]
  }));

  const filter = { $and: andConditions };
  if (gender && ['Male', 'Female', 'Other'].includes(gender)) {
    filter.gender = gender;
  }

  const members = await Member.find(filter).limit(Number(limit)).lean();
  return members;
}

/**
 * Self-healing sync on server startup:
 * 1. Consolidates any duplicate Member records.
 * 2. Backfills unique Member IDs for all existing Users/Profiles.
 * 3. Establishes the initial populated benchmark family relationships for Rishik Jariwala
 *    (Rishik, Father: Alak Jariwala, Mother: Payal Jariwala, Paternal Grandparents: Dinesh & Urmi,
 *     Maternal Grandparents: Dilip & Aruna Gandhi).
 */
async function syncMembersAndBackfill() {
  try {
    console.log('[MemberService] Starting sync and ID backfill...');

    // 0. Auto-consolidate Rishik Jariwala records into single permanent canonical ID MEM001
    const canonicalRishikId = 'MEM001';
    const duplicateRishikMembers = await Member.find({
      $or: [
        { fullName: /^rishik(\s+alak)?\s+jariwala$/i },
        { fullName: /^rishik$/i },
        { email: 'rishikjariwala54@gmail.com' },
        { email: 'rishikjariwala271@gmail.com' },
      ],
      fullName: { $not: /rishi ketan soni/i }
    });

    if (duplicateRishikMembers.length > 0) {
      let canonicalRishik = duplicateRishikMembers.find(m => m.memberId === canonicalRishikId) || duplicateRishikMembers[0];
      canonicalRishik.memberId = canonicalRishikId;
      canonicalRishik.fullName = 'Rishik Jariwala';
      canonicalRishik.firstName = 'Rishik';
      canonicalRishik.middleName = 'Alak';
      canonicalRishik.lastName = 'Jariwala';
      canonicalRishik.gender = 'Male';
      canonicalRishik.email = 'rishikjariwala54@gmail.com';
      canonicalRishik.phoneNumber = '+919136091620';
      canonicalRishik.city = 'Surat';
      canonicalRishik.village = 'Surat';
      canonicalRishik.familyId = 'JARIWALA-01';
      await canonicalRishik.save();

      const dupIds = duplicateRishikMembers
        .map(m => m.memberId)
        .filter(id => id !== canonicalRishikId);

      if (dupIds.length > 0) {
        await Member.deleteMany({ memberId: { $in: dupIds } });
        await Member.updateMany({ fatherId: { $in: dupIds } }, { $set: { fatherId: canonicalRishikId, fatherName: 'Rishik Jariwala' } });
        await Member.updateMany({ motherId: { $in: dupIds } }, { $set: { motherId: canonicalRishikId } });
        await Profile.updateMany({ fatherId: { $in: dupIds } }, { $set: { fatherId: canonicalRishikId, fatherName: 'Rishik Jariwala' } });
        await Profile.updateMany({ memberId: { $in: dupIds } }, { $set: { memberId: canonicalRishikId } });
      }
    }

    // 1. Backfill Member record for every existing registered User without creating duplicates
    const allUsers = await User.find({});
    for (const u of allUsers) {
      if (!u.fullName) continue;
      const profile = await Profile.findOne({ userId: u._id });
      const normPhone = normalizePhone(u.phoneNumber);

      let member = await Member.findOne({
        $or: [
          { userId: u._id },
          ...(normPhone ? [{ phoneNumber: new RegExp(`${normPhone}$`) }] : []),
          ...(u.email && !u.email.includes('_demo_') ? [{ email: u.email.toLowerCase().trim() }] : []),
          { fullName: new RegExp(`^${escapeRegex(u.fullName.trim())}$`, 'i') }
        ]
      });

      if (!member) {
        // Double check fuzzy name match
        const allM = await Member.find({});
        for (const m of allM) {
          if (areNamesEquivalent(m.fullName, u.fullName)) {
            member = m;
            break;
          }
        }
      }

      if (!member) {
        member = await resolveOrCreateMember({
          userId: u._id,
          name: u.fullName,
          gender: (profile && profile.gender) || 'Male',
          phoneNumber: u.phoneNumber || (profile && profile.phoneNumber) || '',
          email: u.email || '',
          city: (profile && profile.city) || '',
          village: (profile && profile.village) || '',
          familyId: (profile && profile.familyId) || '',
        });
      } else {
        if (!member.userId) {
          member.userId = u._id;
          await member.save();
        }
      }

      if (profile && (!profile.memberId || profile.memberId !== member.memberId)) {
        profile.memberId = member.memberId;
        await profile.save();
      }
    }

    // 2. Initial Populated Family Data (Rishik Jariwala's family)
    let rishikMember = await Member.findOne({ memberId: canonicalRishikId });
    if (!rishikMember) {
      rishikMember = await resolveOrCreateMember({
        knownId: canonicalRishikId,
        name: 'Rishik Jariwala',
        gender: 'Male',
        phoneNumber: '+919136091620',
        email: 'rishikjariwala54@gmail.com',
        city: 'Surat',
        village: 'Surat',
        familyId: 'JARIWALA-01',
      });
    }

    // Paternal Grandfather: Dinesh Jariwala
    const dineshMember = await resolveOrCreateMember({
      name: 'Dinesh Jariwala',
      gender: 'Male',
      city: 'Surat',
      village: 'Surat',
    });

    // Paternal Grandmother: Urmi Jariwala
    const urmiMember = await resolveOrCreateMember({
      name: 'Urmi Jariwala',
      gender: 'Female',
      city: 'Surat',
      village: 'Surat',
    });

    // Maternal Grandfather: Dilip Gandhi
    const dilipMember = await resolveOrCreateMember({
      name: 'Dilip Gandhi',
      gender: 'Male',
      city: 'Surat',
      village: 'Surat',
    });

    // Maternal Grandmother: Aruna Gandhi
    const arunaMember = await resolveOrCreateMember({
      name: 'Aruna Gandhi',
      gender: 'Female',
      city: 'Surat',
      village: 'Surat',
    });

    // Father: Alak Jariwala
    const alakMember = await resolveOrCreateMember({
      name: 'Alak Jariwala',
      gender: 'Male',
      city: 'Surat',
      village: 'Surat',
    });

    // Mother: Payal Jariwala (Maiden surname: Gandhi)
    const payalMember = await resolveOrCreateMember({
      name: 'Payal Jariwala',
      maidenName: 'Gandhi',
      gender: 'Female',
      city: 'Surat',
      village: 'Surat',
    });

    // Establish ID links on Alak
    alakMember.fatherId = dineshMember.memberId;
    alakMember.fatherName = dineshMember.fullName;
    alakMember.motherId = urmiMember.memberId;
    alakMember.motherName = urmiMember.fullName;
    alakMember.spouseId = payalMember.memberId;
    alakMember.spouseName = payalMember.fullName;
    await alakMember.save();

    // Establish ID links on Payal
    payalMember.fatherId = dilipMember.memberId;
    payalMember.fatherName = dilipMember.fullName;
    payalMember.motherId = arunaMember.memberId;
    payalMember.motherName = arunaMember.fullName;
    payalMember.spouseId = alakMember.memberId;
    payalMember.spouseName = alakMember.fullName;
    payalMember.maidenName = 'Gandhi';
    await payalMember.save();

    // Establish spouse links on Grandparents
    dineshMember.spouseId = urmiMember.memberId;
    dineshMember.spouseName = urmiMember.fullName;
    await dineshMember.save();

    urmiMember.spouseId = dineshMember.memberId;
    urmiMember.spouseName = dineshMember.fullName;
    await urmiMember.save();

    dilipMember.spouseId = arunaMember.memberId;
    dilipMember.spouseName = arunaMember.fullName;
    await dilipMember.save();

    arunaMember.spouseId = dilipMember.memberId;
    arunaMember.spouseName = dilipMember.fullName;
    await arunaMember.save();

    // Establish ID links on canonical Rishik
    rishikMember.fullName = 'Rishik Jariwala';
    rishikMember.fatherId = alakMember.memberId;
    rishikMember.fatherName = alakMember.fullName;
    rishikMember.motherId = payalMember.memberId;
    rishikMember.motherName = payalMember.fullName;
    rishikMember.paternalGrandfatherId = dineshMember.memberId;
    rishikMember.grandfather = dineshMember.fullName;
    rishikMember.paternalGrandmotherId = urmiMember.memberId;
    rishikMember.grandmother = urmiMember.fullName;
    rishikMember.maternalGrandfatherId = dilipMember.memberId;
    rishikMember.nana = dilipMember.fullName;
    rishikMember.maternalGrandmotherId = arunaMember.memberId;
    rishikMember.nani = arunaMember.fullName;
    await rishikMember.save();

    // Sync all of Rishik's Profile documents
    const allRishikUsers = await User.find({
      $or: [
        { email: 'rishikjariwala54@gmail.com' },
        { email: 'rishikjariwala271@gmail.com' },
        { email: 'rishikjariwala689@gmail.com' },
        { fullName: /^rishik(\s+alak)?\s+jariwala$/i },
        { fullName: /^rishik$/i }
      ],
      fullName: { $not: /rishi ketan soni/i }
    });

    for (const u of allRishikUsers) {
      const prof = await Profile.findOne({ userId: u._id });
      if (prof) {
        prof.memberId = rishikMember.memberId;
        prof.fatherId = alakMember.memberId;
        prof.fatherName = alakMember.fullName;
        prof.motherId = payalMember.memberId;
        prof.motherName = payalMember.fullName;
        prof.paternalGrandfatherId = dineshMember.memberId;
        prof.grandfather = dineshMember.fullName;
        prof.paternalGrandmotherId = urmiMember.memberId;
        prof.grandmother = urmiMember.fullName;
        prof.maternalGrandfatherId = dilipMember.memberId;
        prof.nana = dilipMember.fullName;
        prof.maternalGrandmotherId = arunaMember.memberId;
        prof.nani = arunaMember.fullName;
        if (!prof.profilePhoto) prof.profilePhoto = 'avatar_male_1';
        await prof.save();
      }
    }

    // Sync Payal's User and Profile documents
    // Sync Payal / Mr A's User and Profile documents
    payalMember.fullName = 'Payal Jariwala';
    payalMember.gender = 'Female';
    payalMember.maidenName = 'Gandhi';
    payalMember.fatherId = dilipMember.memberId;
    payalMember.fatherName = dilipMember.fullName;
    payalMember.motherId = arunaMember.memberId;
    payalMember.motherName = arunaMember.fullName;
    payalMember.spouseId = alakMember.memberId;
    payalMember.spouseName = alakMember.fullName;
    if (!payalMember.profilePhoto || payalMember.profilePhoto.includes('male')) {
      payalMember.profilePhoto = 'avatar_female_1';
    }
    await payalMember.save();

    // Ensure Alak has a Profile
    let alakProf = await Profile.findOne({ memberId: alakMember.memberId });
    if (!alakProf && alakMember.userId) {
      alakProf = await Profile.findOne({ userId: alakMember.userId });
    }
    if (!alakProf) {
      alakProf = new Profile({
        userId: alakMember.userId || new mongoose.Types.ObjectId(),
        memberId: alakMember.memberId,
        gender: 'Male',
        dateOfBirth: '1970-05-12',
        phoneNumber: alakMember.phoneNumber || '+919136091624',
        city: 'Surat',
        village: 'Surat',
        fatherId: dineshMember.memberId,
        fatherName: dineshMember.fullName,
        motherId: urmiMember.memberId,
        motherName: urmiMember.fullName,
        spouseId: payalMember.memberId,
        spouseName: payalMember.fullName,
        profilePhoto: 'avatar_male_1',
      });
      await alakProf.save();
    } else {
      alakProf.gender = 'Male';
      alakProf.fatherId = dineshMember.memberId;
      alakProf.fatherName = dineshMember.fullName;
      alakProf.motherId = urmiMember.memberId;
      alakProf.motherName = urmiMember.fullName;
      alakProf.spouseId = payalMember.memberId;
      alakProf.spouseName = payalMember.fullName;
      await alakProf.save();
    }

    // Ensure Payal has a Profile
    let payalProf = await Profile.findOne({ memberId: payalMember.memberId });
    if (!payalProf && payalMember.userId) {
      payalProf = await Profile.findOne({ userId: payalMember.userId });
    }
    if (!payalProf) {
      payalProf = new Profile({
        userId: payalMember.userId || new mongoose.Types.ObjectId(),
        memberId: payalMember.memberId,
        gender: 'Female',
        dateOfBirth: '1974-08-20',
        phoneNumber: payalMember.phoneNumber || '+919136091625',
        city: 'Surat',
        village: 'Surat',
        fatherId: dilipMember.memberId,
        fatherName: dilipMember.fullName,
        motherId: arunaMember.memberId,
        motherName: arunaMember.fullName,
        spouseId: alakMember.memberId,
        spouseName: alakMember.fullName,
        maidenName: 'Gandhi',
        profilePhoto: 'avatar_female_1',
      });
      await payalProf.save();
    } else {
      payalProf.gender = 'Female';
      payalProf.fatherId = dilipMember.memberId;
      payalProf.fatherName = dilipMember.fullName;
      payalProf.motherId = arunaMember.memberId;
      payalProf.motherName = arunaMember.fullName;
      payalProf.spouseId = alakMember.memberId;
      payalProf.spouseName = alakMember.fullName;
      payalProf.maidenName = 'Gandhi';
      await payalProf.save();
    }


    // Ensure Rishik also has an approved Matrimonial Profile
    for (const u of allRishikUsers) {
      let rishikMat = await MatrimonialProfile.findOne({ userId: u._id });
      if (!rishikMat) {
        rishikMat = new MatrimonialProfile({
          userId: u._id,
          name: u.fullName || 'Rishik Jariwala',
          gender: 'Male',
          dob: new Date('1997-08-20'),
          heightCm: 175,
          weightKg: 68,
          bloodGroup: 'O+',
          maritalStatus: 'Never Married',
          education: 'B.Tech in Computer Science',
          occupation: 'Software Development Engineer',
          company: 'Tech Innovations Ltd',
          annualIncome: 1800000,
          village: 'Surat',
          city: 'Surat',
          workingCountry: 'India',
          description: 'Passionate software engineer with interest in tech, sports, and community development.',
          partnerExpectations: 'Seeking an educated, kind-hearted partner who values family unity and personal growth.',
          profilePhoto: 'avatar_male_1',
          profileStatus: 'Approved',
          familyInformation: {
            fatherName: 'Alak Jariwala',
            motherName: 'Payal Jariwala',
            grandfather: 'Dinesh Jariwala',
            grandmother: 'Urmi Jariwala',
            familyOccupation: 'Business & Technology'
          },
          lifestyle: {
            diet: 'Vegetarian',
            smoking: 'No',
            drinking: 'No'
          },
          partnerPreferences: {
            ageMin: 22,
            ageMax: 29,
            heightMin: 155,
            heightMax: 175,
            education: 'Graduate / Post Graduate',
            maritalStatus: 'Never Married'
          }
        });
      } else {
        rishikMat.profileStatus = 'Approved';
        if (!rishikMat.profilePhoto) rishikMat.profilePhoto = 'avatar_male_1';
      }
      await rishikMat.save();
    }

    console.log(`[MemberService] Synced Rishik's family hierarchy: Rishik (${rishikMember.memberId}) -> Alak (${alakMember.memberId}) & Payal (${payalMember.memberId}) -> Dinesh (${dineshMember.memberId}), Urmi (${urmiMember.memberId}), Dilip (${dilipMember.memberId}), Aruna (${arunaMember.memberId})`);
    console.log('[MemberService] Synced Matrimonial Profiles for Payal and Rishik.');
    console.log('[MemberService] Sync and ID backfill completed successfully.');
  } catch (err) {
    console.error('[MemberService] Error in syncMembersAndBackfill:', err);
  }
}

/**
 * Check if the user has filled in essential build profile fields
 * Handles missing spouse or parent information gracefully so the family tree is never broken.
 */
function isProfileComplete(profile, member) {
  if (!profile && !member) return false;
  const p = profile || {};
  const m = member || {};
  // If user has a canonical member ID or basic profile details, profile is valid
  if (p.memberId || m.memberId) return true;
  const dob = (p.dateOfBirth || m.dateOfBirth || '').trim();
  const city = (p.city || p.village || m.city || m.village || '').trim();
  if (dob && city) return true;
  if (p.fatherName || p.motherName || p.spouseName || m.fatherName || m.motherName || m.spouseName) return true;
  return false;
}

/**
 * Builds the Family Tree data structure for any user based on their stored ID-linked relationships.
 * Any family member (Mother, Father, Son, Daughter, Grandparents) will see their unified shared family tree.
 */
async function buildFamilyTree(profile, userEmail, userPhone) {
  // 1. Resolve user's Member record
  let member = null;
  if (profile && profile.memberId) {
    member = await Member.findOne({ memberId: profile.memberId });
  }
  if (!member && profile && profile.userId) {
    const uId = profile.userId._id || profile.userId;
    member = await Member.findOne({ userId: uId });
  }
  if (!member && userEmail) {
    member = await Member.findOne({ email: userEmail.toLowerCase().trim() });
  }
  if (!member && userPhone) {
    const cleanPhone = userPhone.replace(/\s+/g, '').trim();
    const normPhone = cleanPhone.slice(-10);
    member = await Member.findOne({
      $or: [
        { phoneNumber: cleanPhone },
        { phoneNumber: new RegExp(`${normPhone}$`) }
      ]
    });
  }
  if (!member && profile && profile.phoneNumber) {
    const cleanPhone = profile.phoneNumber.replace(/\s+/g, '').trim();
    const normPhone = cleanPhone.slice(-10);
    member = await Member.findOne({
      $or: [
        { phoneNumber: cleanPhone },
        { phoneNumber: new RegExp(`${normPhone}$`) }
      ]
    });
  }
  if (!member && profile && profile.userId && profile.userId.fullName) {
    member = await Member.findOne({ fullName: new RegExp(`^${escapeRegex(profile.userId.fullName.trim())}$`, 'i') });
  }

  // If profile is missing or lacks basic fields, synthesize from member
  if (!profile && member) {
    profile = {
      userId: member.userId || null,
      memberId: member.memberId,
      gender: member.gender || 'Male',
      dateOfBirth: member.dateOfBirth || '',
      phoneNumber: member.phoneNumber || '',
      city: member.city || '',
      village: member.village || '',
      fatherId: member.fatherId || '',
      fatherName: member.fatherName || '',
      motherId: member.motherId || '',
      motherName: member.motherName || '',
      spouseId: member.spouseId || '',
      spouseName: member.spouseName || '',
      paternalGrandfatherId: member.paternalGrandfatherId || '',
      grandfather: member.grandfather || '',
      paternalGrandmotherId: member.paternalGrandmotherId || '',
      grandmother: member.grandmother || '',
      maternalGrandfatherId: member.maternalGrandfatherId || '',
      nana: member.nana || '',
      maternalGrandmotherId: member.maternalGrandmotherId || '',
      nani: member.nani || '',
      profilePhoto: member.profilePhoto || '',
    };
  }

  // Check if profile is complete
  if (!isProfileComplete(profile, member)) {
    return { incomplete: true };
  }

  const currentMemberId = member ? member.memberId : (profile ? profile.memberId : null);

  // Helper to make standard FamilyTreeNode
  const makeNode = (m, relation, forcedSelf = false) => {
    if (!m) return null;
    let photo = m.profilePhoto || '';
    if (!photo) {
      photo = m.gender === 'Female' ? 'avatar_female_1' : 'avatar_male_1';
    }
    const isSelf = forcedSelf || Boolean(currentMemberId && m.memberId === currentMemberId);
    return {
      id: m.memberId || (m._id ? m._id.toString() : `node-${Math.random()}`),
      name: m.fullName || '',
      photo: photo,
      relation: relation || m.relationshipToHead || 'Self',
      isDeceased: m.isDeceased || false,
      isSelf: isSelf,
      parentId: null,
      children: [],
    };
  };

  const makeVirtualNode = (id, name, relation) => {
    const isFemale = ['mother', 'grandmother', 'nani', 'wife', 'daughter', 'sister'].includes((relation || '').toLowerCase());
    return {
      id,
      name,
      photo: isFemale ? 'avatar_female_1' : 'avatar_male_1',
      relation,
      isDeceased: false,
      isSelf: false,
      parentId: null,
      children: [],
    };
  };

  // 2. Discover family roles based on stored relationships
  let primaryChildMember = null;
  let siblingMembers = [];
  let fatherMember = null;
  let motherMember = null;
  let paternalGfMember = null;
  let paternalGmMember = null;
  let maternalGfMember = null;
  let maternalGmMember = null;

  // Check if current user is a parent (has direct children or spouse has children)
  let directChildren = [];
  if (member && member.memberId) {
    directChildren = await Member.find({
      $or: [
        { fatherId: member.memberId },
        { motherId: member.memberId },
      ]
    });
  }
  if (directChildren.length === 0 && member && member.spouseId) {
    directChildren = await Member.find({
      $or: [
        { fatherId: member.spouseId },
        { motherId: member.spouseId },
      ]
    });
  }
  if (directChildren.length === 0 && profile && profile.spouseId) {
    directChildren = await Member.find({
      $or: [
        { fatherId: profile.spouseId },
        { motherId: profile.spouseId },
      ]
    });
  }

  if (directChildren.length > 0) {
    primaryChildMember = directChildren[0];
    siblingMembers = directChildren.slice(1);

    if (member && member.gender === 'Female') {
      // Logged-in user is Mother
      motherMember = member;

      // Resolve Father (Mother's spouse)
      const spouseId = (member && member.spouseId) || (profile && profile.spouseId) || primaryChildMember.fatherId;
      if (spouseId) {
        fatherMember = await Member.findOne({ memberId: spouseId });
      }
      if (!fatherMember && (profile && profile.spouseName)) {
        fatherMember = await Member.findOne({
          fullName: new RegExp(`^${escapeRegex(profile.spouseName.trim())}$`, 'i'),
          gender: 'Male'
        });
      }
      if (!fatherMember && primaryChildMember.fatherName) {
        fatherMember = await Member.findOne({
          fullName: new RegExp(`^${escapeRegex(primaryChildMember.fatherName.trim())}$`, 'i'),
          gender: 'Male'
        });
      }
    } else {
      // Logged-in user is Father
      fatherMember = member;

      // Resolve Mother (Father's spouse)
      const spouseId = (member && member.spouseId) || (profile && profile.spouseId) || primaryChildMember.motherId;
      if (spouseId) {
        motherMember = await Member.findOne({ memberId: spouseId });
      }
      if (!motherMember && (profile && profile.spouseName)) {
        motherMember = await Member.findOne({
          $or: [
            { fullName: new RegExp(`^${escapeRegex(profile.spouseName.trim())}$`, 'i') },
            { maidenName: new RegExp(`^${escapeRegex(profile.spouseName.trim())}$`, 'i') }
          ],
          gender: 'Female'
        });
      }
      if (!motherMember && primaryChildMember.motherName) {
        motherMember = await Member.findOne({
          $or: [
            { fullName: new RegExp(`^${escapeRegex(primaryChildMember.motherName.trim())}$`, 'i') },
            { maidenName: new RegExp(`^${escapeRegex(primaryChildMember.motherName.trim())}$`, 'i') }
          ],
          gender: 'Female'
        });
      }
    }
  } else {
    // Current user has no direct children -> check if user is a child with parents
    const fId = (member && member.fatherId) || (profile && profile.fatherId);
    const mId = (member && member.motherId) || (profile && profile.motherId);
    const fName = (member && member.fatherName) || (profile && profile.fatherName);
    const mName = (member && member.motherName) || (profile && profile.motherName);

    if (fId || mId || fName || mName) {
      primaryChildMember = member;

      if (fId) {
        fatherMember = await Member.findOne({ memberId: fId });
      }
      if (!fatherMember && fName && fName.trim()) {
        fatherMember = await Member.findOne({
          fullName: new RegExp(`^${escapeRegex(fName.trim())}$`, 'i'),
          gender: 'Male'
        });
      }

      if (mId) {
        motherMember = await Member.findOne({ memberId: mId });
      }
      if (!motherMember && mName && mName.trim()) {
        motherMember = await Member.findOne({
          $or: [
            { fullName: new RegExp(`^${escapeRegex(mName.trim())}$`, 'i') },
            { maidenName: new RegExp(`^${escapeRegex(mName.trim())}$`, 'i') }
          ],
          gender: 'Female'
        });
      }

      // Resolve siblings
      const sibFilter = [];
      if (fId) sibFilter.push({ fatherId: fId });
      if (fatherMember) sibFilter.push({ fatherId: fatherMember.memberId });
      if (mId) sibFilter.push({ motherId: mId });
      if (motherMember) sibFilter.push({ motherId: motherMember.memberId });

      if (sibFilter.length > 0 && member) {
        siblingMembers = await Member.find({
          $or: sibFilter,
          memberId: { $ne: member.memberId }
        });
      }
    } else if (member) {
      // Adult user without children or parents in DB
      if (member.gender === 'Female') {
        motherMember = member;
        if (member.spouseId) {
          fatherMember = await Member.findOne({ memberId: member.spouseId });
        }
      } else {
        fatherMember = member;
        if (member.spouseId) {
          motherMember = await Member.findOne({ memberId: member.spouseId });
        }
      }
    }
  }

  // 3. Resolve Grandparents
  // Paternal Grandparents (Father's parents)
  const gfId = (fatherMember && fatherMember.fatherId) ||
               (primaryChildMember && primaryChildMember.paternalGrandfatherId) ||
               (profile && profile.paternalGrandfatherId) ||
               (fatherMember && fatherMember.paternalGrandfatherId);
  if (gfId) {
    paternalGfMember = await Member.findOne({ memberId: gfId });
  }
  if (!paternalGfMember && fatherMember && fatherMember.fatherName) {
    paternalGfMember = await Member.findOne({ fullName: new RegExp(`^${escapeRegex(fatherMember.fatherName.trim())}$`, 'i'), gender: 'Male' });
  }
  if (!paternalGfMember && profile && profile.grandfather && profile.grandfather.trim() && profile.grandfather.toLowerCase() !== 'none') {
    paternalGfMember = await Member.findOne({ fullName: new RegExp(`^${escapeRegex(profile.grandfather.trim())}$`, 'i'), gender: 'Male' });
  }

  const gmId = (fatherMember && fatherMember.motherId) ||
               (primaryChildMember && primaryChildMember.paternalGrandmotherId) ||
               (profile && profile.paternalGrandmotherId) ||
               (fatherMember && fatherMember.paternalGrandmotherId);
  if (gmId) {
    paternalGmMember = await Member.findOne({ memberId: gmId });
  }
  if (!paternalGmMember && fatherMember && fatherMember.motherName) {
    paternalGmMember = await Member.findOne({ fullName: new RegExp(`^${escapeRegex(fatherMember.motherName.trim())}$`, 'i'), gender: 'Female' });
  }
  if (!paternalGmMember && profile && profile.grandmother && profile.grandmother.trim() && profile.grandmother.toLowerCase() !== 'none') {
    paternalGmMember = await Member.findOne({ fullName: new RegExp(`^${escapeRegex(profile.grandmother.trim())}$`, 'i'), gender: 'Female' });
  }

  // Maternal Grandparents (Mother's parents)
  const nanaId = (motherMember && motherMember.fatherId) ||
                 (primaryChildMember && primaryChildMember.maternalGrandfatherId) ||
                 (profile && profile.maternalGrandfatherId) ||
                 (motherMember && motherMember.maternalGrandfatherId);
  if (nanaId) {
    maternalGfMember = await Member.findOne({ memberId: nanaId });
  }
  if (!maternalGfMember && motherMember && motherMember.fatherName) {
    maternalGfMember = await Member.findOne({ fullName: new RegExp(`^${escapeRegex(motherMember.fatherName.trim())}$`, 'i'), gender: 'Male' });
  }
  if (!maternalGfMember && profile && profile.nana && profile.nana.trim() && profile.nana.toLowerCase() !== 'none') {
    maternalGfMember = await Member.findOne({ fullName: new RegExp(`^${escapeRegex(profile.nana.trim())}$`, 'i'), gender: 'Male' });
  }

  const naniId = (motherMember && motherMember.motherId) ||
                 (primaryChildMember && primaryChildMember.maternalGrandmotherId) ||
                 (profile && profile.maternalGrandmotherId) ||
                 (motherMember && motherMember.maternalGrandmotherId);
  if (naniId) {
    maternalGmMember = await Member.findOne({ memberId: naniId });
  }
  if (!maternalGmMember && motherMember && motherMember.motherName) {
    maternalGmMember = await Member.findOne({ fullName: new RegExp(`^${escapeRegex(motherMember.motherName.trim())}$`, 'i'), gender: 'Female' });
  }
  if (!maternalGmMember && profile && profile.nani && profile.nani.trim() && profile.nani.toLowerCase() !== 'none') {
    maternalGmMember = await Member.findOne({ fullName: new RegExp(`^${escapeRegex(profile.nani.trim())}$`, 'i'), gender: 'Female' });
  }

  // Dynamic perspective mapping: ensure spouses and parent-child links are accurate
  const isFatherSelf = Boolean(fatherMember && currentMemberId && fatherMember.memberId === currentMemberId);
  const isMotherSelf = Boolean(motherMember && currentMemberId && motherMember.memberId === currentMemberId);
  const isChildSelf = Boolean(primaryChildMember && currentMemberId && primaryChildMember.memberId === currentMemberId);

  let fatherRel = 'Father';
  let motherRel = 'Mother';
  let childRel = primaryChildMember ? (primaryChildMember.gender === 'Female' ? 'Daughter' : 'Son') : 'Child';

  if (isFatherSelf) {
    fatherRel = 'Self';
    motherRel = 'Wife';
  } else if (isMotherSelf) {
    motherRel = 'Self';
    fatherRel = 'Husband';
  } else if (isChildSelf) {
    childRel = 'Self';
    fatherRel = 'Father';
    motherRel = 'Mother';
  }

  // Fallbacks using text from Profile if not found in Member collection
  let fNode = makeNode(fatherMember, fatherRel);
  if (!fNode && profile && profile.fatherName && profile.fatherName.trim()) {
    fNode = makeVirtualNode('virtual-father', profile.fatherName.trim(), fatherRel);
  }

  let mNode = makeNode(motherMember, motherRel);
  if (!mNode && profile && profile.motherName && profile.motherName.trim()) {
    mNode = makeVirtualNode('virtual-mother', profile.motherName.trim(), motherRel);
  }

  let gfNode = makeNode(paternalGfMember, 'Grandfather');
  if (!gfNode && profile && profile.grandfather && profile.grandfather.trim() && profile.grandfather.toLowerCase() !== 'none') {
    gfNode = makeVirtualNode('virtual-grandfather', profile.grandfather.trim(), 'Grandfather');
  }

  let gmNode = makeNode(paternalGmMember, 'Grandmother');
  if (!gmNode && profile && profile.grandmother && profile.grandmother.trim() && profile.grandmother.toLowerCase() !== 'none') {
    gmNode = makeVirtualNode('virtual-grandmother', profile.grandmother.trim(), 'Grandmother');
  }

  let nanaNode = makeNode(maternalGfMember, 'Nana');
  if (!nanaNode && profile && profile.nana && profile.nana.trim() && profile.nana.toLowerCase() !== 'none') {
    nanaNode = makeVirtualNode('virtual-nana', profile.nana.trim(), 'Nana');
  }

  let naniNode = makeNode(maternalGmMember, 'Nani');
  if (!naniNode && profile && profile.nani && profile.nani.trim() && profile.nani.toLowerCase() !== 'none') {
    naniNode = makeVirtualNode('virtual-nani', profile.nani.trim(), 'Nani');
  }

  let childNode = null;
  if (primaryChildMember) {
    childNode = makeNode(primaryChildMember, childRel);
  }

  const siblingNodes = (siblingMembers || []).map(sib => {
    const rel = sib.gender === 'Female' ? 'Daughter' : 'Son';
    return makeNode(sib, rel);
  });

  // 4. Build Clean, Consistent Family Hierarchy
  const rootAncestors = makeVirtualNode('virtual-ancestors', 'Ancestors', 'Ancestors');

  // Branch A: Paternal Grandparents -> Father
  if (gfNode) {
    rootAncestors.children.push(gfNode);
    gfNode.parentId = rootAncestors.id;
    if (gmNode) {
      gfNode.children.push(gmNode);
      gmNode.parentId = gfNode.id;
    }
    if (fNode) {
      gfNode.children.push(fNode);
      fNode.parentId = gfNode.id;
    }
  } else if (fNode) {
    rootAncestors.children.push(fNode);
    fNode.parentId = rootAncestors.id;
  }

  // Branch B: Maternal Grandparents -> Mother
  if (nanaNode) {
    rootAncestors.children.push(nanaNode);
    nanaNode.parentId = rootAncestors.id;
    if (naniNode) {
      nanaNode.children.push(naniNode);
      naniNode.parentId = nanaNode.id;
    }
    if (mNode) {
      nanaNode.children.push(mNode);
      mNode.parentId = nanaNode.id;
    }
  } else if (mNode) {
    rootAncestors.children.push(mNode);
    mNode.parentId = rootAncestors.id;
  }

  // Connect both Parents to the same Child & Siblings without duplicating profiles
  if (childNode) {
    if (fNode) {
      fNode.children.push(childNode);
      childNode.parentId = fNode.id;
      siblingNodes.forEach(sib => {
        fNode.children.push(sib);
        sib.parentId = fNode.id;
      });
    }
    if (mNode) {
      // Connect Mother to the same Child
      mNode.children.push(childNode);
      if (!childNode.parentId) {
        childNode.parentId = mNode.id;
      }
      siblingNodes.forEach(sib => {
        mNode.children.push(sib);
      });
    }
  } else {
    // If no child exists in this family, ensure user node is accessible
    if (!fNode && !mNode) {
      let selfName = (member && member.fullName) || (profile && profile.userId && profile.userId.fullName) || 'Self';
      let selfPhoto = (member && member.profilePhoto) || (profile && profile.profilePhoto) || 'avatar_male_1';
      const selfNode = {
        id: currentMemberId || 'self-node',
        name: selfName,
        photo: selfPhoto,
        relation: 'Self',
        isDeceased: false,
        isSelf: true,
        parentId: rootAncestors.id,
        children: [],
      };
      rootAncestors.children.push(selfNode);
    }
  }

  return rootAncestors;
}

module.exports = {
  getNextMemberId,
  splitFullName,
  resolveOrCreateMember,
  searchMembers,
  syncMembersAndBackfill,
  isProfileComplete,
  buildFamilyTree,
};
