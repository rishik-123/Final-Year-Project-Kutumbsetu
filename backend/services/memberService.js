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
 * Builds the Family Tree data structure for any user based on their ID-linked relationships
 */
async function buildFamilyTree(profile, userEmail, userPhone) {
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

  // Helper to make standard FamilyTreeNode
  const makeNode = (m, relation) => {
    if (!m) return null;
    return {
      id: m.memberId || (m._id ? m._id.toString() : `node-${Math.random()}`),
      name: m.fullName || '',
      photo: m.profilePhoto || '',
      relation: relation || m.relationshipToHead || 'Self',
      isDeceased: m.isDeceased || false,
      parentId: null,
      children: [],
    };
  };

  const makeVirtualNode = (id, name, relation) => ({
    id,
    name,
    photo: '',
    relation,
    isDeceased: false,
    parentId: null,
    children: [],
  });

  const selfNode = makeNode(
    member || {
      memberId: (profile && profile.memberId) || (profile && profile.userId ? profile.userId.toString() : 'self-id'),
      fullName: (profile && profile.userId && profile.userId.fullName) || 'Self',
      profilePhoto: (profile && profile.profilePhoto) || '',
      isDeceased: (profile && profile.isDeceased) || false,
    },
    'Self'
  );

  if (!selfNode) return null;

  // 2. Resolve Father & Mother
  let fNode = null;
  let mNode = null;

  const fatherId = (member && member.fatherId) || (profile && profile.fatherId);
  const motherId = (member && member.motherId) || (profile && profile.motherId);
  const fatherName = (member && member.fatherName) || (profile && profile.fatherName);
  const motherName = (member && member.motherName) || (profile && profile.motherName);

  if (fatherId) {
    const fMem = await Member.findOne({ memberId: fatherId });
    if (fMem) fNode = makeNode(fMem, 'Father');
  }
  if (!fNode && fatherName && fatherName.trim()) {
    const fMem = await Member.findOne({ fullName: new RegExp(`^${escapeRegex(fatherName.trim())}$`, 'i'), gender: 'Male' });
    if (fMem) fNode = makeNode(fMem, 'Father');
    else fNode = makeVirtualNode(`${selfNode.id}-virtual-father`, fatherName.trim(), 'Father');
  }

  if (motherId) {
    const mMem = await Member.findOne({ memberId: motherId });
    if (mMem) mNode = makeNode(mMem, 'Mother');
  }
  if (!mNode && motherName && motherName.trim()) {
    const mMem = await Member.findOne({
      $or: [
        { fullName: new RegExp(`^${escapeRegex(motherName.trim())}$`, 'i') },
        { maidenName: new RegExp(`^${escapeRegex(motherName.trim())}$`, 'i') }
      ],
      gender: 'Female'
    });
    if (mMem) mNode = makeNode(mMem, 'Mother');
    else mNode = makeVirtualNode(`${selfNode.id}-virtual-mother`, motherName.trim(), 'Mother');
  }

  // 3. Resolve Paternal Grandparents (Dinesh & Urmi)
  let gfNode = null;
  let gmNode = null;

  const gfId = (member && member.paternalGrandfatherId) || (profile && profile.paternalGrandfatherId);
  const gmId = (member && member.paternalGrandmotherId) || (profile && profile.paternalGrandmotherId);
  const gfName = (member && member.grandfather) || (profile && profile.grandfather);
  const gmName = (member && member.grandmother) || (profile && profile.grandmother);

  if (gfId) {
    const gfMem = await Member.findOne({ memberId: gfId });
    if (gfMem) gfNode = makeNode(gfMem, 'Grandfather');
  }
  if (!gfNode && gfName && gfName.trim()) {
    const gfMem = await Member.findOne({ fullName: new RegExp(`^${escapeRegex(gfName.trim())}$`, 'i'), gender: 'Male' });
    if (gfMem) gfNode = makeNode(gfMem, 'Grandfather');
    else gfNode = makeVirtualNode(`${selfNode.id}-virtual-grandfather`, gfName.trim(), 'Grandfather');
  }

  if (gmId) {
    const gmMem = await Member.findOne({ memberId: gmId });
    if (gmMem) gmNode = makeNode(gmMem, 'Grandmother');
  }
  if (!gmNode && gmName && gmName.trim()) {
    const gmMem = await Member.findOne({ fullName: new RegExp(`^${escapeRegex(gmName.trim())}$`, 'i'), gender: 'Female' });
    if (gmMem) gmNode = makeNode(gmMem, 'Grandmother');
    else gmNode = makeVirtualNode(`${selfNode.id}-virtual-grandmother`, gmName.trim(), 'Grandmother');
  }

  // 4. Resolve Maternal Grandparents (Nana & Nani / Dilip & Aruna)
  let nanaNode = null;
  let naniNode = null;

  const nanaId = (member && member.maternalGrandfatherId) || (profile && profile.maternalGrandfatherId);
  const naniId = (member && member.maternalGrandmotherId) || (profile && profile.maternalGrandmotherId);
  const nanaName = (member && member.nana) || (profile && profile.nana);
  const naniName = (member && member.nani) || (profile && profile.nani);

  if (nanaId) {
    const nanaMem = await Member.findOne({ memberId: nanaId });
    if (nanaMem) nanaNode = makeNode(nanaMem, 'Nana');
  }
  if (!nanaNode && nanaName && nanaName.trim()) {
    const nanaMem = await Member.findOne({ fullName: new RegExp(`^${escapeRegex(nanaName.trim())}$`, 'i'), gender: 'Male' });
    if (nanaMem) nanaNode = makeNode(nanaMem, 'Nana');
    else nanaNode = makeVirtualNode(`${selfNode.id}-virtual-nana`, nanaName.trim(), 'Nana');
  }

  if (naniId) {
    const naniMem = await Member.findOne({ memberId: naniId });
    if (naniMem) naniNode = makeNode(naniMem, 'Nani');
  }
  if (!naniNode && naniName && naniName.trim()) {
    const naniMem = await Member.findOne({ fullName: new RegExp(`^${escapeRegex(naniName.trim())}$`, 'i'), gender: 'Female' });
    if (naniMem) naniNode = makeNode(naniMem, 'Nani');
    else naniNode = makeVirtualNode(`${selfNode.id}-virtual-nani`, naniName.trim(), 'Nani');
  }

  // 5. Resolve Spouse
  let spouseNode = null;
  const spouseId = (member && member.spouseId) || (profile && profile.spouseId);
  const spouseName = (member && member.spouseName) || (profile && profile.spouseName);

  if (spouseId) {
    const sMem = await Member.findOne({ memberId: spouseId });
    if (sMem) spouseNode = makeNode(sMem, 'Spouse');
  }
  if (!spouseNode && spouseName && spouseName.trim()) {
    const sMem = await Member.findOne({ fullName: new RegExp(`^${escapeRegex(spouseName.trim())}$`, 'i') });
    if (sMem) spouseNode = makeNode(sMem, 'Spouse');
    else spouseNode = makeVirtualNode(`${selfNode.id}-virtual-spouse`, spouseName.trim(), 'Spouse');
  }

  // 6. Resolve Children
  const sonNodes = [];
  const daughterNodes = [];
  if (member && member.memberId) {
    const children = await Member.find({
      $or: [
        { fatherId: member.memberId },
        { motherId: member.memberId },
      ]
    });
    for (const c of children) {
      if (c.gender === 'Female') daughterNodes.push(makeNode(c, 'Daughter'));
      else sonNodes.push(makeNode(c, 'Son'));
    }
  }

  // 7. Resolve Siblings
  const siblingNodes = [];
  if (fatherId) {
    const siblings = await Member.find({
      fatherId: fatherId,
      memberId: { $ne: (member && member.memberId) || '' },
    });
    for (const sib of siblings) {
      siblingNodes.push(makeNode(sib, sib.gender === 'Female' ? 'Sister' : 'Brother'));
    }
  }

  // Process any custom addedMembers from profile
  const addedMembers = (profile && profile.addedMembers) || [];
  addedMembers.forEach((m, idx) => {
    const n = makeVirtualNode(`${selfNode.id}-added-${idx}`, m.name, m.relation);
    const rel = (m.relation || '').toLowerCase().trim();
    if (rel === 'son') sonNodes.push(n);
    else if (rel === 'daughter') daughterNodes.push(n);
    else if (rel === 'brother' || rel === 'sister') siblingNodes.push(n);
    else if (rel === 'father' && !fNode) fNode = n;
    else if (rel === 'mother' && !mNode) mNode = n;
    else if (rel === 'grandfather' && !gfNode) gfNode = n;
    else if (rel === 'grandmother' && !gmNode) gmNode = n;
    else if (rel === 'nana' && !nanaNode) nanaNode = n;
    else if (rel === 'nani' && !naniNode) naniNode = n;
    else if ((rel === 'spouse' || rel === 'wife' || rel === 'husband') && !spouseNode) spouseNode = n;
  });

  // 8. Connect relationship hierarchy lines
  // Spouse pairs (Connected side-by-side)
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

  // Paternal Grandparents -> Father
  if (gfNode && fNode) {
    gfNode.children.push(fNode);
    fNode.parentId = gfNode.id;
  } else if (gmNode && fNode) {
    gmNode.children.push(fNode);
    fNode.parentId = gmNode.id;
  }

  // Maternal Grandparents -> Mother
  if (nanaNode && mNode) {
    nanaNode.children.push(mNode);
    mNode.parentId = nanaNode.id;
  } else if (naniNode && mNode) {
    naniNode.children.push(mNode);
    mNode.parentId = naniNode.id;
  }

  // Parents -> Self & Siblings
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

  // Self -> Children
  sonNodes.forEach(s => {
    selfNode.children.push(s);
    s.parentId = selfNode.id;
  });
  daughterNodes.forEach(d => {
    selfNode.children.push(d);
    d.parentId = selfNode.id;
  });

  // 9. Select Root Node
  let root = null;
  if (gfNode || gmNode || nanaNode || naniNode) {
    // Symmetrical ancestral root for paternal + maternal grandparents
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

  return root;
}

module.exports = {
  getNextMemberId,
  splitFullName,
  resolveOrCreateMember,
  searchMembers,
  syncMembersAndBackfill,
  buildFamilyTree,
};
