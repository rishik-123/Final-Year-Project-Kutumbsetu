const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const mongoose = require('mongoose');

const MatrimonialProfile = require('./models/MatrimonialProfile');
const { SuccessStory } = require('./models/MatrimonialCollections');
const User = require('./models/User');
const Member = require('./models/Member');
const Profile = require('./models/Profile');

const sampleProfessions = [
  { education: 'Chartered Accountant (CA)', occupation: 'Senior Financial Analyst', company: 'Deloitte India', income: 1600000 },
  { education: 'B.Tech / M.Tech Computer Science', occupation: 'Full Stack Software Engineer', company: 'Microsoft IDC', income: 2400000 },
  { education: 'M.B.B.S, M.D. General Medicine', occupation: 'Consultant Physician', company: 'Apollo Hospitals', income: 2200000 },
  { education: 'B.Arch (Architecture)', occupation: 'Senior Interior Designer & Architect', company: 'Studio Designscapes', income: 1400000 },
  { education: 'MBA in Marketing & Finance', occupation: 'Product Marketing Manager', company: 'Unilever India', income: 1900000 },
  { education: 'M.Sc. Biotechnology & Pharma', occupation: 'Clinical Research Scientist', company: 'Sun Pharma', income: 1200000 },
  { education: 'B.E. Civil & Structural Engineering', occupation: 'Infrastructure Project Lead', company: 'Larsen & Toubro', income: 1500000 },
  { education: 'B.Com / LLB (Corporate Law)', occupation: 'Legal Counsel & Associate', company: 'Shardul Amarchand', income: 1750000 },
  { education: 'B.Des Fashion Design (NIFT)', occupation: 'Creative Apparel Director', company: 'Ethnic Heritage Couture', income: 1100000 },
  { education: 'Ph.D / Assistant Professor', occupation: 'University Faculty Member', company: 'Gujarat Technological University', income: 1300000 },
  { education: 'Family Diamond & Textile Business', occupation: 'Entrepreneur & Business Director', company: 'Jariwala & Sons Export', income: 3500000 }
];

const sampleGujaratiVillages = [
  'Karamsad', 'Dharmaj', 'Vaso', 'Petlad', 'Ode', 'Piplav',
  'Narsanda', 'Bhalej', 'Borsad', 'Sojitra', 'Tarapur', 'Changa', 'Bakrol'
];

const sampleGujaratiCities = [
  'Surat', 'Ahmedabad', 'Vadodara', 'Mumbai', 'Rajkot', 'Anand', 'Navsari', 'Bharuch', 'Gandhinagar'
];

const malePhotos = [
  'avatar_male_1',
  'avatar_male_2',
  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
  'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
  'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400',
  'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=400',
  'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400'
];

const femalePhotos = [
  'avatar_female_1',
  'avatar_generic',
  'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400',
  'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400',
  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
  'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
  'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400'
];

const successStoriesData = [
  {
    coupleName: 'Priya ❤️ Rohan',
    marriageDate: new Date('2026-02-12'),
    photo: 'avatar_female_1',
    description: "We found each other through KutumbSetu Matrimonial in November 2025. With our families' blessings, we got married in February 2026. Thank you KutumbSetu!"
  },
  {
    coupleName: 'Nikita ❤️ Krupal',
    marriageDate: new Date('2025-11-23'),
    photo: 'avatar_generic',
    description: 'KutumbSetu helped us bridge the distance between Mumbai and Vadodara. Highly recommended for trusted community matchmaking.'
  },
  {
    coupleName: 'Ananya ❤️ Hardik',
    marriageDate: new Date('2026-01-18'),
    photo: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400',
    description: 'Our families connected through Vanshavali lineage verification on KutumbSetu. The transparency and cultural connection made our match effortless.'
  },
  {
    coupleName: 'Dhara ❤️ Manan',
    marriageDate: new Date('2025-12-05'),
    photo: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400',
    description: 'From finding a compatible education and value match to our grand wedding at Community Hall in Anand, KutumbSetu was with us every step.'
  },
  {
    coupleName: 'Pooja ❤️ Bhavin',
    marriageDate: new Date('2026-03-14'),
    photo: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
    description: 'We both work in the tech sector and wanted someone who understood our lifestyle while cherishing our Gujarati Darji Samaj values. Best platform ever!'
  },
  {
    coupleName: 'Rinkal ❤️ Jignesh',
    marriageDate: new Date('2025-05-20'),
    photo: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
    description: 'Participating in the Samuh Lagna Sammelan through the Matrimonial Events section gave us our dream community wedding.'
  },
  {
    coupleName: 'Bhumika ❤️ Yash',
    marriageDate: new Date('2025-10-28'),
    photo: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400',
    description: 'The verified candidate biodatas gave our parents complete peace of mind. Forever grateful to KutumbSetu!'
  },
  {
    coupleName: 'Kinjal ❤️ Parth',
    marriageDate: new Date('2026-01-30'),
    photo: 'avatar_female_1',
    description: 'Mutual respect, shared traditions, and instant connection! KutumbSetu truly unites samaj families.'
  }
];

async function syncMatrimonialAndDirectory() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    console.error('❌ MONGODB_URI not found in backend/.env');
    process.exit(1);
  }

  console.log('Connecting to MongoDB Atlas...');
  await mongoose.connect(uri);
  console.log('Connected to DB:', mongoose.connection.name);

  // 1. Sync All Success Stories
  console.log('\n--- Syncing Success Stories ---');
  await SuccessStory.deleteMany({});
  for (const s of successStoriesData) {
    await SuccessStory.create(s);
  }
  const storyCount = await SuccessStory.countDocuments({});
  console.log(`✓ Seeded ${storyCount} rich matrimonial success stories.`);

  // 2. Fetch all Users and Members
  const users = await User.find({});
  const members = await Member.find({});
  const profiles = await Profile.find({});

  const profileByUserId = new Map();
  profiles.forEach(p => {
    if (p.userId) profileByUserId.set(p.userId.toString(), p);
  });

  console.log(`\nFound ${users.length} Users, ${members.length} Members in directory.`);

  let createdCount = 0;
  let updatedCount = 0;

  // 3. Process every user
  for (let i = 0; i < users.length; i++) {
    const user = users[i];
    const uProfile = profileByUserId.get(user._id.toString());
    const member = members.find(m => m.userId && m.userId.toString() === user._id.toString());

    // Determine gender
    let gender = (uProfile && uProfile.gender) || (member && member.gender) || 'Male';
    const nameLower = user.fullName.toLowerCase();
    if (nameLower.includes('ben') || nameLower.includes('priya') || nameLower.includes('nikita') ||
        nameLower.includes('suman') || nameLower.includes('nehal') || nameLower.includes('mira') ||
        nameLower.includes('alpa') || nameLower.includes('geeta') || nameLower.includes('deepa') ||
        nameLower.includes('pooja') || nameLower.includes('kinjal') || nameLower.includes('bhumika')) {
      gender = 'Female';
    }

    // Determine DOB
    let dob = new Date(1996, 0, 15);
    if (uProfile && uProfile.dateOfBirth) {
      const parsed = new Date(uProfile.dateOfBirth);
      if (!isNaN(parsed.getTime())) dob = parsed;
    } else {
      const age = 22 + (i % 12);
      dob = new Date(new Date().getFullYear() - age, (i % 12), (1 + (i * 3) % 28));
    }

    const job = sampleProfessions[i % sampleProfessions.length];
    const village = (uProfile && uProfile.village) || (member && member.village) || sampleGujaratiVillages[i % sampleGujaratiVillages.length];
    const city = (uProfile && uProfile.city) || (member && member.city) || sampleGujaratiCities[i % sampleGujaratiCities.length];
    const heightCm = gender === 'Male' ? 168 + (i % 14) : 155 + (i % 12);
    const weightKg = gender === 'Male' ? 62 + (i % 20) : 48 + (i % 18);
    const photos = gender === 'Male' ? malePhotos : femalePhotos;
    const photoUrl = (uProfile && uProfile.profilePhoto) || (member && member.profilePhoto) || photos[i % photos.length];

    let mat = await MatrimonialProfile.findOne({ userId: user._id });
    if (!mat) {
      mat = new MatrimonialProfile({
        userId: user._id,
        memberId: (member && member.memberId) || (uProfile && uProfile.memberId) || `MEM-MAT-${i + 100}`,
        name: user.fullName,
        gender: gender,
        dob: dob,
        heightCm: heightCm,
        weightKg: weightKg,
        bloodGroup: (uProfile && uProfile.bloodGroup) || 'B+',
        maritalStatus: 'Never Married',
        education: (uProfile && uProfile.qualification) || job.education,
        occupation: (uProfile && uProfile.profession) || job.occupation,
        company: job.company,
        annualIncome: job.income,
        village: village,
        city: city,
        workingCountry: 'India',
        description: `Dedicated ${gender === 'Male' ? 'groom' : 'bride'} from a respectable Gujarati Darji Samaj family residing in ${city}. Looking for a partner with aligned moral values and mutual respect.`,
        partnerExpectations: `Seeking an educated, family-oriented partner from the Samaj with progressive outlook and traditional family values.`,
        partnerExpectationsHobbies: ['Reading', 'Traveling', 'Music', 'Cooking'],
        profilePhoto: photoUrl,
        introductionVideo: '',
        familyInformation: {
          fatherName: (uProfile && uProfile.fatherName) || (member && member.fatherName) || 'Dineshbhai ' + (user.fullName.split(' ').pop() || 'Jariwala'),
          motherName: (uProfile && uProfile.motherName) || (member && member.motherName) || 'Savitaben ' + (user.fullName.split(' ').pop() || 'Jariwala'),
          grandfather: (uProfile && uProfile.grandfather) || 'Manilalbhai Jariwala',
          grandmother: (uProfile && uProfile.grandmother) || 'Maniben Jariwala',
          nana: (uProfile && uProfile.nana) || 'Ramanbhai Patel',
          nani: (uProfile && uProfile.nani) || 'Kamlaben Patel',
          familyOccupation: 'Business & Professional'
        },
        lifestyle: {
          languages: ['Gujarati', 'Hindi', 'English'],
          hobbies: ['Music', 'Fitness', 'Traveling', 'Community Service'],
          diet: 'Vegetarian',
          smoking: 'No',
          drinking: 'No'
        },
        partnerPreferences: {
          ageMin: gender === 'Male' ? 20 : 23,
          ageMax: gender === 'Male' ? 32 : 36,
          heightMin: gender === 'Male' ? 150 : 165,
          heightMax: gender === 'Male' ? 175 : 192,
          education: 'Graduate / Post Graduate',
          occupation: 'Any Professional',
          city: city,
          village: village
        },
        visibilitySettings: {
          showPhone: true,
          showAddress: true,
          showEmail: false
        },
        hasMatrimonialProfile: true,
        visibility: true,
        profileStatus: 'Approved'
      });
      await mat.save();
      createdCount++;
    } else {
      mat.hasMatrimonialProfile = true;
      mat.visibility = true;
      mat.profileStatus = 'Approved';
      if (!mat.dob || isNaN(new Date(mat.dob).getTime())) mat.dob = dob;
      if (!mat.heightCm) mat.heightCm = heightCm;
      if (!mat.weightKg) mat.weightKg = weightKg;
      if (!mat.profilePhoto) mat.profilePhoto = photoUrl;
      if (!mat.city) mat.city = city;
      if (!mat.village) mat.village = village;
      if (!mat.education) mat.education = job.education;
      if (!mat.occupation) mat.occupation = job.occupation;
      await mat.save();
      updatedCount++;
    }

    // Ensure User, Profile, Member also reflect hasMatrimonialProfile: true
    await User.findByIdAndUpdate(user._id, { hasMatrimonialProfile: true });
    if (uProfile) {
      await Profile.findByIdAndUpdate(uProfile._id, { hasMatrimonialProfile: true, matrimonialVisibility: true });
    }
    if (member) {
      await Member.findByIdAndUpdate(member._id, { hasMatrimonialProfile: true, matrimonialVisibility: true });
    }
  }

  // 4. Ensure we have a balanced representation of both Grooms & Brides for browsing
  const femaleCount = await MatrimonialProfile.countDocuments({ gender: 'Female', profileStatus: 'Approved' });
  const maleCount = await MatrimonialProfile.countDocuments({ gender: 'Male', profileStatus: 'Approved' });
  console.log(`\nCurrent Profiles in DB -> Brides (Female): ${femaleCount}, Grooms (Male): ${maleCount}`);

  // If female count is lower than 15, seed dedicated female candidates so users searching for brides see extensive options
  if (femaleCount < 15) {
    const additionalBrides = [
      { name: 'Dr. Riddhi Jariwala', village: 'Surat', city: 'Surat', age: 26, edu: 'M.B.B.S, D.G.O (Gynecology)', occ: 'Resident Doctor', comp: 'Civil Hospital Surat', income: 1400000, photo: 'https://images.unsplash.com/photo-1594824813587-0b196859dd6c?w=400' },
      { name: 'Aayushi Patel', village: 'Karamsad', city: 'Ahmedabad', age: 25, edu: 'M.S. Data Science', occ: 'Senior AI Specialist', comp: 'Amazon AWS', income: 2600000, photo: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400' },
      { name: 'Khushboo Chauhan', village: 'Dharmaj', city: 'Vadodara', age: 27, edu: 'Chartered Accountant (CA)', occ: 'Financial Risk Advisor', comp: 'PwC India', income: 1850000, photo: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400' },
      { name: 'Janvi Shah', village: 'Vaso', city: 'Mumbai', age: 24, edu: 'B.Des (Fashion & Styling)', occ: 'Fashion Brand Consultant', comp: 'Vogue Studio', income: 1200000, photo: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400' },
      { name: 'Bansari Parekh', village: 'Petlad', city: 'Rajkot', age: 28, edu: 'M.Pharm (Pharmacology)', occ: 'Quality Assurance Manager', comp: 'Zydus Cadila', income: 1350000, photo: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400' },
      { name: 'Ishita Mehta', village: 'Ode', city: 'Anand', age: 26, edu: 'B.E. Computer Science', occ: 'iOS App Developer', comp: 'InfoSys Ltd', income: 1600000, photo: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400' },
      { name: 'Tanvi Jariwala', village: 'Navsari', city: 'Surat', age: 25, edu: 'B.Arch (Architecture)', occ: 'Sustainable Interior Architect', comp: 'Studio Vastu', income: 1100000, photo: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400' },
      { name: 'Drashti Chauhan', village: 'Narsanda', city: 'Gandhinagar', age: 27, edu: 'M.Sc Clinical Psychology', occ: 'Corporate Wellness Consultant', comp: 'TCS Health', income: 1250000, photo: 'avatar_female_1' },
      { name: 'Mansi Joshi', village: 'Piplav', city: 'Ahmedabad', age: 24, edu: 'MBA International Business', occ: 'Supply Chain Analyst', comp: 'Adani Logistics', income: 1500000, photo: 'avatar_generic' }
    ];

    for (const b of additionalBrides) {
      // Create a virtual user id
      const dummyUserId = new mongoose.Types.ObjectId();
      const dobB = new Date();
      dobB.setFullYear(dobB.getFullYear() - b.age);

      await MatrimonialProfile.create({
        userId: dummyUserId,
        memberId: `MEM-BRIDE-${Math.floor(1000 + Math.random() * 9000)}`,
        name: b.name,
        gender: 'Female',
        dob: dobB,
        heightCm: 160 + (b.age % 6),
        weightKg: 50 + (b.age % 10),
        bloodGroup: 'B+',
        maritalStatus: 'Never Married',
        education: b.edu,
        occupation: b.occ,
        company: b.comp,
        annualIncome: b.income,
        village: b.village,
        city: b.city,
        workingCountry: 'India',
        description: `Respectable, family-oriented ${b.occ} belonging to Gujarati Darji Samaj. Values cultural traditions, family integrity, and progressive aspirations.`,
        partnerExpectations: `Seeking an educated, supportive groom from our Samaj with shared family values.`,
        partnerExpectationsHobbies: ['Reading', 'Yoga', 'Cooking', 'Traveling'],
        profilePhoto: b.photo,
        familyInformation: {
          fatherName: 'Pravinbhai Jariwala',
          motherName: 'Varshaben Jariwala',
          grandfather: 'Dahyabhai Jariwala',
          grandmother: 'Maniben Jariwala',
          nana: 'Ramanbhai Shah',
          nani: 'Kiranben Shah',
          familyOccupation: 'Business & Enterprise'
        },
        lifestyle: {
          languages: ['Gujarati', 'Hindi', 'English'],
          hobbies: ['Music', 'Fitness', 'Traveling'],
          diet: 'Vegetarian',
          smoking: 'No',
          drinking: 'No'
        },
        partnerPreferences: {
          ageMin: 25,
          ageMax: 32,
          heightMin: 168,
          heightMax: 190,
          education: 'Graduate / Engineer / CA / Doctor',
          occupation: 'Any Professional',
          city: b.city,
          village: b.village
        },
        visibilitySettings: {
          showPhone: true,
          showAddress: true,
          showEmail: false
        },
        hasMatrimonialProfile: true,
        visibility: true,
        profileStatus: 'Approved'
      });
      createdCount++;
    }
    console.log(`✓ Added ${additionalBrides.length} verified candidate profiles for brides.`);
  }

  const finalTotal = await MatrimonialProfile.countDocuments({ profileStatus: 'Approved' });
  const finalF = await MatrimonialProfile.countDocuments({ gender: 'Female', profileStatus: 'Approved' });
  const finalM = await MatrimonialProfile.countDocuments({ gender: 'Male', profileStatus: 'Approved' });

  console.log('\n======================================================');
  console.log('       MATRIMONIAL SYNC REPORT SUMMARY                ');
  console.log('======================================================');
  console.log(`✓ New profiles created: ${createdCount}`);
  console.log(`✓ Existing profiles updated & synced: ${updatedCount}`);
  console.log(`✓ Total Approved Matrimonial Profiles: ${finalTotal}`);
  console.log(`✓ Brides (Female): ${finalF}`);
  console.log(`✓ Grooms (Male): ${finalM}`);
  console.log(`✓ Total Success Stories: ${storyCount}`);
  console.log('======================================================\n');

  await mongoose.disconnect();
  console.log('Disconnected from MongoDB.');
}

syncMatrimonialAndDirectory().catch(err => {
  console.error('Fatal sync error:', err);
  process.exit(1);
});

