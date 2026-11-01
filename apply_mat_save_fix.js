const fs = require('fs');
const path = require('path');

function normalize(s) {
  return s.replace(/\r\n/g, '\n');
}

const serverPath = path.join(__dirname, 'backend', 'server.js');
let content = fs.readFileSync(serverPath, 'utf8');
const isCRLF = content.includes('\r\n');
let norm = normalize(content);

const targetPost = `// 1. Create or Update Matrimonial Profile
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
        const base64Data = profilePhotoBase64.replace(/^data:image\\/\\w+;base64,/, "");
        const buffer = Buffer.from(base64Data, 'base64');
        const uploadsDir = path.join(__dirname, 'uploads');
        if (!fs.existsSync(uploadsDir)) {
          fs.mkdirSync(uploadsDir, { recursive: true });
        }
        const filename = \`matrimony-photo-\${userId}-\${Date.now()}.jpg\`;
        const filepath = path.join(uploadsDir, filename);
        fs.writeFileSync(filepath, buffer);
        finalProfilePhoto = \`/uploads/\${filename}\`;
        console.log(\`Saved matrimonial profile photo to: \${finalProfilePhoto}\`);
      } catch (err) {
        console.error('Error writing profile photo file:', err);
      }
    }

    let finalIntroductionVideo = introductionVideo;
    if (introductionVideoBase64 && introductionVideoBase64.trim().length > 0) {
      try {
        const base64Data = introductionVideoBase64.replace(/^data:video\\/\\w+;base64,/, "");
        const buffer = Buffer.from(base64Data, 'base64');
        const uploadsDir = path.join(__dirname, 'uploads');
        if (!fs.existsSync(uploadsDir)) {
          fs.mkdirSync(uploadsDir, { recursive: true });
        }
        const filename = \`matrimony-video-\${userId}-\${Date.now()}.mp4\`;
        const filepath = path.join(uploadsDir, filename);
        fs.writeFileSync(filepath, buffer);
        finalIntroductionVideo = \`/uploads/\${filename}\`;
        console.log(\`Saved matrimonial intro video to: \${finalIntroductionVideo}\`);
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
      console.log(\`Updated matrimonial profile for user ID: \${userId}\`);
    } else {
      profile = new MatrimonialProfile(profileData);
      await profile.save();
      console.log(\`Created matrimonial profile for user ID: \${userId}\`);
    }

    return res.status(200).json({ success: true, profile });
  } catch (error) {
    console.error('Error saving matrimonial profile:', error);
    return res.status(500).json({ success: false, message: 'Server error saving matrimonial profile.' });
  }
});`;

const replacementPost = `// 1. Create or Update Matrimonial Profile
app.post('/api/matrimonial/profile', async (req, res) => {
  try {
    const {
      userId, name, gender, dob, heightCm, weightKg, bloodGroup,
      maritalStatus, education, occupation, company, annualIncome,
      village, city, familyInformation, lifestyle, partnerPreferences,
      visibilitySettings, profilePhoto, introductionVideo,
      profilePhotoBase64, introductionVideoBase64,
      workingCountry, description, partnerExpectations,
      partnerExpectationsHobbies, socialLinks, additionalPhotos,
      additionalPhotosBase64
    } = req.body;

    if (!userId || !name || !gender) {
      return res.status(400).json({ success: false, message: 'Missing required profile fields.' });
    }

    // Handle base64 uploads for profile photo
    let finalProfilePhoto = profilePhoto;
    if (profilePhotoBase64 && profilePhotoBase64.trim().length > 0) {
      try {
        const base64Data = profilePhotoBase64.replace(/^data:image\\/\\w+;base64,/, "");
        const buffer = Buffer.from(base64Data, 'base64');
        const uploadsDir = path.join(__dirname, 'uploads');
        if (!fs.existsSync(uploadsDir)) {
          fs.mkdirSync(uploadsDir, { recursive: true });
        }
        const filename = \`matrimony-photo-\${userId}-\${Date.now()}.jpg\`;
        const filepath = path.join(uploadsDir, filename);
        fs.writeFileSync(filepath, buffer);
        finalProfilePhoto = \`/uploads/\${filename}\`;
        console.log(\`Saved matrimonial profile photo to: \${finalProfilePhoto}\`);
      } catch (err) {
        console.error('Error writing profile photo file:', err);
      }
    }

    // Handle base64 uploads for intro video
    let finalIntroductionVideo = introductionVideo;
    if (introductionVideoBase64 && introductionVideoBase64.trim().length > 0) {
      try {
        const base64Data = introductionVideoBase64.replace(/^data:video\\/\\w+;base64,/, "");
        const buffer = Buffer.from(base64Data, 'base64');
        const uploadsDir = path.join(__dirname, 'uploads');
        if (!fs.existsSync(uploadsDir)) {
          fs.mkdirSync(uploadsDir, { recursive: true });
        }
        const filename = \`matrimony-video-\${userId}-\${Date.now()}.mp4\`;
        const filepath = path.join(uploadsDir, filename);
        fs.writeFileSync(filepath, buffer);
        finalIntroductionVideo = \`/uploads/\${filename}\`;
        console.log(\`Saved matrimonial intro video to: \${finalIntroductionVideo}\`);
      } catch (err) {
        console.error('Error writing introduction video file:', err);
      }
    }

    // Handle base64 uploads for additional photos
    let finalAdditionalPhotos = Array.isArray(additionalPhotos) ? [...additionalPhotos] : [];
    if (Array.isArray(additionalPhotosBase64) && additionalPhotosBase64.length > 0) {
      try {
        const uploadsDir = path.join(__dirname, 'uploads');
        if (!fs.existsSync(uploadsDir)) {
          fs.mkdirSync(uploadsDir, { recursive: true });
        }
        for (let i = 0; i < additionalPhotosBase64.length; i++) {
          const rawB64 = additionalPhotosBase64[i];
          if (!rawB64 || typeof rawB64 !== 'string') continue;
          const cleanB64 = rawB64.replace(/^data:image\\/\\w+;base64,/, "");
          const buffer = Buffer.from(cleanB64, 'base64');
          const filename = \`matrimony-addphoto-\${userId}-\${Date.now()}-\${i}.jpg\`;
          const filepath = path.join(uploadsDir, filename);
          fs.writeFileSync(filepath, buffer);
          finalAdditionalPhotos.push(\`/uploads/\${filename}\`);
        }
      } catch (err) {
        console.error('Error writing additional photos:', err);
      }
    }

    let parsedDob = dob ? new Date(dob) : null;
    if (!parsedDob || isNaN(parsedDob.getTime())) {
      parsedDob = new Date(1998, 0, 1);
    }

    const profileData = {
      userId,
      name,
      gender,
      dob: parsedDob,
      heightCm: Number(heightCm) || 165,
      weightKg: Number(weightKg) || 60,
      bloodGroup: bloodGroup || '',
      maritalStatus: maritalStatus || 'Never Married',
      education: education || '',
      occupation: occupation || '',
      company: company || '',
      annualIncome: Number(annualIncome) || 0,
      village: village || '',
      city: city || '',
      workingCountry: (workingCountry !== undefined && workingCountry !== null) ? workingCountry.toString().trim() : '',
      description: (description !== undefined && description !== null) ? description.toString().trim() : '',
      partnerExpectations: (partnerExpectations !== undefined && partnerExpectations !== null) ? partnerExpectations.toString().trim() : '',
      partnerExpectationsHobbies: Array.isArray(partnerExpectationsHobbies) ? partnerExpectationsHobbies : [],
      socialLinks: socialLinks || { showSocialLinks: false, instagramUrl: '', facebookUrl: '' },
      additionalPhotos: finalAdditionalPhotos,
      familyInformation: familyInformation || {},
      lifestyle: lifestyle || {},
      partnerPreferences: partnerPreferences || {},
      visibilitySettings: visibilitySettings || {},
      profilePhoto: finalProfilePhoto || '',
      introductionVideo: finalIntroductionVideo || '',
      hasMatrimonialProfile: true,
      visibility: true,
      profileStatus: 'Approved',
      updatedDate: new Date()
    };

    let profile = await MatrimonialProfile.findOne({ userId });
    if (profile) {
      profile = await MatrimonialProfile.findOneAndUpdate({ userId }, profileData, { new: true, runValidators: false });
      console.log(\`[Matrimony] Successfully updated biodata for user ID: \${userId}, description len: \${profileData.description.length}, country: "\${profileData.workingCountry}"\`);
    } else {
      profile = new MatrimonialProfile(profileData);
      await profile.save();
      console.log(\`[Matrimony] Successfully created biodata for user ID: \${userId}\`);
    }

    // Sync user flags
    await User.findByIdAndUpdate(userId, { hasMatrimonialProfile: true });
    await Profile.findOneAndUpdate({ userId }, { hasMatrimonialProfile: true, matrimonialVisibility: true });
    await Member.findOneAndUpdate({ userId }, { hasMatrimonialProfile: true, matrimonialVisibility: true });

    return res.status(200).json({ success: true, profile });
  } catch (error) {
    console.error('Error saving matrimonial profile:', error);
    return res.status(500).json({ success: false, message: 'Server error saving matrimonial profile.' });
  }
});`;

if (norm.includes(normalize(targetPost))) {
  norm = norm.replace(normalize(targetPost), normalize(replacementPost));
  console.log('OK: Replaced POST /api/matrimonial/profile with full field persistence in server.js');
} else {
  console.error('FAIL: targetPost not found in server.js');
}

if (isCRLF) {
  norm = norm.replace(/\n/g, '\r\n');
}

fs.writeFileSync(serverPath, norm, 'utf8');
console.log('SUCCESS: server.js updated.');
