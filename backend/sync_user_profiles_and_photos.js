require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');
const Profile = require('./models/Profile');
const Member = require('./models/Member');

async function syncData() {
  const uri = process.env.MONGODB_URI;
  await mongoose.connect(uri);
  console.log('Connected to DB for user profiles & photos sync...');

  // 1. Update/Clean up Payal Jariwala (Mother of Rishik)
  const payalEmails = ['23rishikjariwala7b@gmail.com', '23rishikjariwala54@gmail.com'];
  for (const email of payalEmails) {
    const user = await User.findOne({ email });
    if (user) {
      user.fullName = 'Payal Jariwala';
      await user.save();
      console.log(`Updated User (${email}) name to 'Payal Jariwala'`);

      let prof = await Profile.findOne({ userId: user._id });
      if (!prof) {
        prof = new Profile({ userId: user._id });
      }
      prof.memberId = 'MEM051';
      prof.gender = 'Female';
      prof.dateOfBirth = '1975-06-15';
      prof.bloodGroup = 'O+';
      prof.village = 'Surat';
      prof.city = 'Surat';
      prof.state = 'Gujarat';
      prof.address = 'Surat, Gujarat';
      prof.qualification = 'B.Com';
      prof.profession = 'Homemaker';
      prof.maidenName = 'Gandhi';
      prof.fatherId = 'MEM048';
      prof.fatherName = 'Dilip Gandhi';
      prof.motherId = 'MEM049';
      prof.motherName = 'Aruna Gandhi';
      prof.spouseId = 'MEM050';
      prof.spouseName = 'Alak Jariwala';
      prof.profilePhoto = 'avatar_female_1';
      await prof.save();
      console.log(`Updated Profile for Payal Jariwala (${email})`);
    }
  }

  // Update Payal's Member record
  let payalMember = await Member.findOne({ memberId: 'MEM051' });
  if (payalMember) {
    payalMember.fullName = 'Payal Jariwala';
    payalMember.gender = 'Female';
    payalMember.maidenName = 'Gandhi';
    payalMember.fatherId = 'MEM048';
    payalMember.fatherName = 'Dilip Gandhi';
    payalMember.motherId = 'MEM049';
    payalMember.motherName = 'Aruna Gandhi';
    payalMember.spouseId = 'MEM050';
    payalMember.spouseName = 'Alak Jariwala';
    payalMember.profilePhoto = 'avatar_female_1';
    await payalMember.save();
  }

  // Remove or clean up duplicate/junk Member record MEM068 if it was "R A J"
  const rajMember = await Member.findOne({ memberId: 'MEM068' });
  if (rajMember) {
    if (rajMember.fullName === 'R A J') {
      await Member.deleteOne({ memberId: 'MEM068' });
      console.log('Removed duplicate RAJ member MEM068');
    }
  }

  // 2. Ensure all Members have profilePhoto and correct gender avatars
  const allMembers = await Member.find({});
  for (const m of allMembers) {
    let changed = false;
    if (!m.profilePhoto || m.profilePhoto.trim() === '') {
      m.profilePhoto = m.gender === 'Female' ? 'avatar_female_1' : 'avatar_male_1';
      changed = true;
    }
    if (changed) {
      await m.save();
    }
  }
  console.log(`Verified photos for all ${allMembers.length} members.`);

  // 3. Ensure all Profiles have profilePhoto
  const allProfiles = await Profile.find({});
  for (const p of allProfiles) {
    let changed = false;
    if (!p.profilePhoto || p.profilePhoto.trim() === '') {
      p.profilePhoto = p.gender === 'Female' ? 'avatar_female_1' : 'avatar_male_1';
      changed = true;
    }
    if (changed) {
      await p.save();
    }
  }
  console.log(`Verified photos for all ${allProfiles.length} profiles.`);

  await mongoose.disconnect();
  console.log('Sync complete!');
}

syncData().catch(console.error);
