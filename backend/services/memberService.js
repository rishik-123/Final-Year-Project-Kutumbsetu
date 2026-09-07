const mongoose = require('mongoose');
const Counter = require('../models/Counter');
const Member = require('../models/Member');
const User = require('../models/User');
const Profile = require('../models/Profile');

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
        { email: 'rishikjariwala689@gmail.com' },
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
    const allPayalUsers = await User.find({
      $or: [
        { email: '23rishikjariwala7b@gmail.com' },
        { email: '23rishikjariwala54@gmail.com' },
        { fullName: /payal(\s+jariwala)?/i }
      ]
    });

    for (const u of allPayalUsers) {
      u.fullName = 'Payal Jariwala';
      await u.save();

      payalMember.userId = u._id;
      payalMember.email = u.email;
      payalMember.fullName = 'Payal Jariwala';
      payalMember.gender = 'Female';
      payalMember.profilePhoto = 'avatar_female_1';
      await payalMember.save();

      const prof = await Profile.findOne({ userId: u._id });
      if (prof) {
        prof.memberId = payalMember.memberId;
        prof.gender = 'Female';
        prof.maidenName = 'Gandhi';
        prof.fatherId = dilipMember.memberId;
        prof.fatherName = dilipMember.fullName;
        prof.motherId = arunaMember.memberId;
        prof.motherName = arunaMember.fullName;
        prof.spouseId = alakMember.memberId;
        prof.spouseName = alakMember.fullName;
        if (!prof.profilePhoto) prof.profilePhoto = 'avatar_female_1';
        await prof.save();
      }
    }

    console.log(`[MemberService] Synced Rishik's family hierarchy: Rishik (${rishikMember.memberId}) -> Alak (${alakMember.memberId}) & Payal (${payalMember.memberId}) -> Dinesh (${dineshMember.memberId}), Urmi (${urmiMember.memberId}), Dilip (${dilipMember.memberId}), Aruna (${arunaMember.memberId})`);
    console.log('[MemberService] Sync and ID backfill completed successfully.');
  } catch (err) {
    console.error('[MemberService] Error in syncMembersAndBackfill:', err);
  }
}

/**
 * Check if the user has filled in essential build profile fields
 */
function isProfileComplete(profile) {
  if (!profile) return false;
  const fn = (profile.fatherName || '').trim();
  const mn = (profile.motherName || '').trim();
  const dob = (profile.dateOfBirth || '').trim();
  const city = (profile.city || profile.village || '').trim();
  return Boolean(fn && mn && dob && city);
}

/**
 * Builds the Family Tree data structure for any user based on their ID-linked relationships.
 * Any family member (Mother, Father, Son, Daughter, Grandparents) will see their unified shared family tree.
 */
async function buildFamilyTree(profile, userEmail, userPhone) {
  // Check if profile is complete
  if (!isProfileComplete(profile)) {
    return { incomplete: true };
  }

  // 1. Resolve user's Member record
  let member = null;
  if (profile && profile.memberId) {
    member = await Member.findOne({ memberId: profile.memberId });
  }
  if (!member && profile && profile.userId) {
    member = await Member.findOne({ userId: profile.userId });
  }
  if (!member && userEmail) {
    member = await Member.findOne({ email: userEmail.toLowerCase().trim() });
  }
  if (!member && userPhone) {
    const cleanPhone = userPhone.replace(/\s+/g, '').trim();
    member = await Member.findOne({ phoneNumber: cleanPhone });
  }

  const currentMemberId = member ? member.memberId : (profile ? profile.memberId : null);

  // Helper to make standard FamilyTreeNode
  const makeNode = (m, relation) => {
    if (!m) return null;
    let photo = m.profilePhoto || '';
    if (!photo) {
      photo = m.gender === 'Female' ? 'avatar_female_1' : 'avatar_male_1';
    }
    const isSelf = Boolean(currentMemberId && m.memberId === currentMemberId);
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

  // 2. Discover canonical family unit anchor (e.g. child generation node like Rishik)
  let primaryChildMember = null;
  let fatherMember = null;
  let motherMember = null;
  let paternalGfMember = null;
  let paternalGmMember = null;
  let maternalGfMember = null;
  let maternalGmMember = null;

  if (member && member.memberId) {
    // Check if current user is a parent (has direct children)
    const directChildren = await Member.find({
      $or: [
        { fatherId: member.memberId },
        { motherId: member.memberId },
      ]
    });

    if (directChildren.length > 0) {
      primaryChildMember = directChildren.find(c => c.memberId === 'MEM001') || directChildren[0];
    } else {
      // Check if current user is a grandparent (child of user has children)
      const directChildrenOfGp = await Member.find({
        $or: [
          { fatherId: member.memberId },
          { motherId: member.memberId },
        ]
      });
      for (const p of directChildrenOfGp) {
        const grandChildren = await Member.find({
          $or: [
            { fatherId: p.memberId },
            { motherId: p.memberId },
          ]
        });
        if (grandChildren.length > 0) {
          primaryChildMember = grandChildren.find(c => c.memberId === 'MEM001') || grandChildren[0];
          break;
        }
      }
    }
  }

  // If not found via parent/grandparent traversal, check if the member themselves is the child node
  if (!primaryChildMember && member) {
    primaryChildMember = member;
  }

  // 3. Resolve all hierarchy nodes from canonical child node (or profile data)
  let childNode = null;
  const siblingNodes = [];

  if (primaryChildMember) {
    childNode = makeNode(primaryChildMember, primaryChildMember.gender === 'Female' ? 'Daughter' : 'Son');

    // Resolve Father
    const fId = primaryChildMember.fatherId || (profile && profile.fatherId);
    if (fId) {
      fatherMember = await Member.findOne({ memberId: fId });
    }
    if (!fatherMember && (profile && profile.fatherName)) {
      fatherMember = await Member.findOne({ fullName: new RegExp(`^${escapeRegex(profile.fatherName.trim())}$`, 'i'), gender: 'Male' });
    }

    // Resolve Mother
    const mId = primaryChildMember.motherId || (profile && profile.motherId);
    if (mId) {
      motherMember = await Member.findOne({ memberId: mId });
    }
    if (!motherMember && (profile && profile.motherName)) {
      motherMember = await Member.findOne({
        $or: [
          { fullName: new RegExp(`^${escapeRegex(profile.motherName.trim())}$`, 'i') },
          { maidenName: new RegExp(`^${escapeRegex(profile.motherName.trim())}$`, 'i') }
        ],
        gender: 'Female'
      });
    }

    // Resolve Paternal Grandparents (Dinesh & Urmi)
    const gfId = (fatherMember && fatherMember.fatherId) || primaryChildMember.paternalGrandfatherId || (profile && profile.paternalGrandfatherId);
    if (gfId) {
      paternalGfMember = await Member.findOne({ memberId: gfId });
    }
    const gmId = (fatherMember && fatherMember.motherId) || primaryChildMember.paternalGrandmotherId || (profile && profile.paternalGrandmotherId);
    if (gmId) {
      paternalGmMember = await Member.findOne({ memberId: gmId });
    }

    // Resolve Maternal Grandparents (Dilip & Aruna)
    const nanaId = (motherMember && motherMember.fatherId) || primaryChildMember.maternalGrandfatherId || (profile && profile.maternalGrandfatherId);
    if (nanaId) {
      maternalGfMember = await Member.findOne({ memberId: nanaId });
    }
    const naniId = (motherMember && motherMember.motherId) || primaryChildMember.maternalGrandmotherId || (profile && profile.maternalGrandmotherId);
    if (naniId) {
      maternalGmMember = await Member.findOne({ memberId: naniId });
    }

    // Resolve Siblings
    if (fId) {
      const sibs = await Member.find({
        fatherId: fId,
        memberId: { $ne: primaryChildMember.memberId },
      });
      for (const sib of sibs) {
        siblingNodes.push(makeNode(sib, sib.gender === 'Female' ? 'Daughter' : 'Son'));
      }
    }
  }

  // Fallbacks using text from Profile if not found in Member collection
  let fNode = makeNode(fatherMember, 'Father');
  if (!fNode && profile && profile.fatherName && profile.fatherName.trim()) {
    fNode = makeVirtualNode(`virtual-father`, profile.fatherName.trim(), 'Father');
  }

  let mNode = makeNode(motherMember, 'Mother');
  if (!mNode && profile && profile.motherName && profile.motherName.trim()) {
    mNode = makeVirtualNode(`virtual-mother`, profile.motherName.trim(), 'Mother');
  }

  let gfNode = makeNode(paternalGfMember, 'Grandfather');
  if (!gfNode && profile && profile.grandfather && profile.grandfather.trim() && profile.grandfather.toLowerCase() !== 'none') {
    gfNode = makeVirtualNode(`virtual-grandfather`, profile.grandfather.trim(), 'Grandfather');
  }

  let gmNode = makeNode(paternalGmMember, 'Grandmother');
  if (!gmNode && profile && profile.grandmother && profile.grandmother.trim() && profile.grandmother.toLowerCase() !== 'none') {
    gmNode = makeVirtualNode(`virtual-grandmother`, profile.grandmother.trim(), 'Grandmother');
  }

  let nanaNode = makeNode(maternalGfMember, 'Nana');
  if (!nanaNode && profile && profile.nana && profile.nana.trim() && profile.nana.toLowerCase() !== 'none') {
    nanaNode = makeVirtualNode(`virtual-nana`, profile.nana.trim(), 'Nana');
  }

  let naniNode = makeNode(maternalGmMember, 'Nani');
  if (!naniNode && profile && profile.nani && profile.nani.trim() && profile.nani.toLowerCase() !== 'none') {
    naniNode = makeVirtualNode(`virtual-nani`, profile.nani.trim(), 'Nani');
  }

  if (!childNode) {
    let selfName = (member && member.fullName) || (profile && profile.userId && profile.userId.fullName) || 'Self';
    let selfPhoto = (member && member.profilePhoto) || (profile && profile.profilePhoto) || 'avatar_male_1';
    childNode = {
      id: currentMemberId || 'self-node',
      name: selfName,
      photo: selfPhoto,
      relation: 'Self',
      isDeceased: false,
      isSelf: true,
      parentId: null,
      children: [],
    };
  }

  // 4. Build Symmetrical Family Hierarchy
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

  // Connect Father & Mother
  if (fNode && mNode) {
    fNode.children.push(mNode);
    mNode.parentId = fNode.id;
  }

  // Connect Parents -> Child & Siblings
  const primaryParentNode = fNode || mNode;
  if (primaryParentNode && childNode) {
    primaryParentNode.children.push(childNode);
    childNode.parentId = primaryParentNode.id;

    siblingNodes.forEach(sib => {
      primaryParentNode.children.push(sib);
      sib.parentId = primaryParentNode.id;
    });
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
