# 🪷 KutumbSetu (કુટુંબસેતુ)
### *Next-Generation Community Management, Family Tree & Matrimonial Portal*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Node.js](https://img.shields.io/badge/Node.js-18+-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)](https://nodejs.org)
[![Express.js](https://img.shields.io/badge/Express.js-4.x-000000?style=for-the-badge&logo=express&logoColor=white)](https://expressjs.com)
[![MongoDB](https://img.shields.io/badge/MongoDB-Database-47A248?style=for-the-badge&logo=mongodb&logoColor=white)](https://www.mongodb.com)
[![Riverpod](https://img.shields.io/badge/State_Management-Riverpod-2E7D32?style=for-the-badge)](https://riverpod.dev)

---

## 📌 Project Overview

**KutumbSetu (કુટુંબસેતુ)** is a full-stack, enterprise-grade community management mobile and web application. It connects dispersed community members across generations, preserves cultural heritage, builds interactive family genealogies (Vanshavali), streamlines community social media & announcements, manages community campaigns, and provides a verified, private matrimonial biodata matchmaking portal.

Built as an advanced **Final Year Engineering Project**, KutumbSetu bridges modern cloud architecture with community needs.

---

## ✨ Key Features & Modules

### 1. 🔐 Authentication & Onboarding
- **Comprehensive Registration**: Captures Profile Photo (Camera/Gallery), First/Middle/Last Name, Date of Birth, Age auto-computation, Gender (`Male`, `Female`, `Other`), Mobile number, Email, and Address.
- **Secure Email OTP Verification**: Automated 6-digit One-Time Password delivery powered by Nodemailer.
- **Role-Based Access Control (RBAC)**: Support for `user`, `admin`, and `organizer` accounts.
- **Admin Approval Queue**: Newly registered members remain pending until verified by community administrators.

### 2. 👥 Interactive Community Directory
- Real-time search across thousands of community members.
- Dynamic filtering by **Surname, Native Village (ગામ), Current City, Blood Group, and Occupation**.
- In-app direct calling, WhatsApp messaging, and detailed member profile views.

### 3. 🌳 Interactive Family Tree (કુટુંબ વૃક્ષ / Vanshavali)
- Multi-generational hierarchical visual family tree visualization.
- Dual lineage tracking: **Paternal (પિતૃ પક્ષ)** and **Maternal (માતૃ પક્ષ)**.
- Node expansion, automatic relational linking (Grandparents, Parents, Spouses, Children), and cross-linking to directory profiles.

### 4. 💍 Matrimonial Portal (લગ્ન સેવા)
- Privacy-first biodata creation with verification badges.
- Detailed preferences: Education, Profession, Height, Diet, Gotra/Subcaste, Kundali/Horoscope, and Multiple Photo Galleries.
- In-app profile visibility toggles (Private, Community-only, or Verified Members).

### 5. 📢 Social Feed, Broadcasts & Reels
- Community feed for **General Posts, Announcements, Marriage Notices, Birthday Wishes, and Achievements**.
- Short video **Reels** player with micro-interactions.
- Community broadcast announcements sent directly from the Admin console.

### 6. 🎪 Campaigns & Event Management
- Create and host community events, AGM assemblies, Blood Donation Drives, and Youth Fests.
- Member RSVP, volunteer signups, and participation tracking.
- Campaign media banner uploads and broadcast notifications.

### 7. 🛡️ Admin Command Center
- Member registration approvals & user role modifications.
- Feed post moderation queue and content governance.
- Community analytics and database synchronization tools.

### 8. 🌐 Bilingual & Modern UI/UX
- Seamless language toggle between **English** and **Gujarati (ગુજરાતી)**.
- Dynamic **Dark Mode** and **Light Mode** themes.
- Rich Indian Saffron (`#E67E22`) and Deep Navy (`#1B4F72`) design tokens.

---

## 🛠️ Technology Stack

| Layer | Technologies |
|---|---|
| **Mobile Frontend** | Flutter (Dart SDK 3.x), Material Design 3, Google Fonts (`Poppins`, `Inter`) |
| **State Management** | Flutter Riverpod (`StateNotifierProvider`, `StateProvider`) |
| **Routing** | GoRouter 14.x (Deep linking & stateful shell navigation) |
| **Backend API** | Node.js, Express.js (RESTful architecture) |
| **Database** | MongoDB & Mongoose ODM (with local MongoDB / Atlas / In-memory fallback) |
| **Email Service** | Nodemailer (SMTP / Gmail App Password) |
| **Media Handling** | Multer, Base64 image codecs, Image Picker (`image_picker`) |
| **Media Player** | Video Player (`video_player`) |

---

## 📂 Project Architecture & Directory Structure

```text
FINAL YEAR PROJECT KUTUMBSETU/
├── android/                    # Android native configuration & Gradle scripts
├── assets/                     # JSON mock data & local image assets
├── backend/                    # Node.js Express REST Backend Server
│   ├── models/                 # Mongoose Schemas (User, Member, Profile, Campaign, etc.)
│   ├── services/               # Member linking & family tree generation logic
│   ├── uploads/                # Uploaded photos, campaign banners, and videos
│   ├── .env.example            # Backend environment variables template
│   ├── package.json            # Backend dependencies & scripts
│   └── server.js               # Main Express entry point & REST API routes
├── lib/                        # Flutter Application Source Code
│   ├── community/              # Community feed & post management
│   ├── constants/              # App strings, translations & assets
│   ├── models/                 # Dart domain models (UserModel, MemberModel, etc.)
│   ├── providers/              # Riverpod State Notifiers & Providers
│   ├── repository/             # Data fetchers & HTTP client wrappers
│   ├── routes/                 # GoRouter route definitions & auth guards
│   ├── screens/                # UI Screens (Register, Directory, Tree, Matrimonial, Admin)
│   │   ├── matrimonial/        # Matrimonial biodata & search screens
│   │   ├── admin_dashboard_screen.dart
│   │   ├── family_tree_screen.dart
│   │   ├── member_directory_screen.dart
│   │   └── register_screen.dart
│   ├── theme/                  # Color palettes, dark/light themes & typography
│   ├── api_config.dart         # Dynamic IP & Base URL configuration
│   └── main.dart               # Flutter entry point
├── pubspec.yaml                # Flutter packages & asset declarations
└── README.md                   # Project documentation
```

---

## 🚀 Getting Started

### Prerequisites
1. **Flutter SDK** (`>= 3.12.0`) — [Install Flutter](https://docs.flutter.dev/get-started/install)
2. **Node.js** (`>= 18.x`) & **npm** — [Install Node.js](https://nodejs.org/)
3. **MongoDB** (Local instance or [MongoDB Atlas URI](https://www.mongodb.com/cloud/atlas))
4. **Android Studio / VS Code** with Flutter & Dart extensions

---

### ⚙️ Step 1: Backend Setup

1. Open terminal and navigate to `backend/`:
   ```bash
   cd backend
   npm install
   ```

2. Configure environment variables:
   Create a `.env` file in the `backend/` directory based on `.env.example`:
   ```env
   PORT=5000
   MONGO_URI=mongodb://127.0.0.1:27017/kutumbsetu
   SMTP_HOST=smtp.gmail.com
   SMTP_PORT=587
   SMTP_SECURE=false
   SMTP_USER=your-email@gmail.com
   SMTP_PASS=your-gmail-app-password
   SMTP_FROM=KutumbSetu Portal <your-email@gmail.com>
   ```

3. Start the backend server:
   ```bash
   npm run dev
   # Server runs at http://localhost:5000 (or http://10.0.2.2:5000 for Android Emulator)
   ```

---

### 📱 Step 2: Frontend Setup

1. From the project root, fetch Flutter dependencies:
   ```bash
   flutter pub get
   ```

2. Configure the API endpoint in `lib/api_config.dart` (if testing on physical device):
   ```dart
   // Use 10.0.2.2 for Android Emulator, or your local LAN IP (e.g., 192.168.1.X) for physical devices
   static const String baseUrl = 'http://10.0.2.2:5000/api';
   ```

3. (Optional) If running on a physical Android device connected via USB:
   ```bash
   adb reverse tcp:5000 tcp:5000
   ```

4. Launch the Flutter application:
   ```bash
   flutter run
   ```

---

## 📡 REST API Overview

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/auth/send-email-otp` | Sends a 6-digit verification code to the user's email |
| `POST` | `/api/users/register` | Registers a new member with profile picture & demographics |
| `GET` | `/api/users/profile/:identifier` | Fetches member profile by email or phone |
| `GET` | `/api/members/search` | Searches community directory with query & filters |
| `GET` | `/api/members/family-tree/:memberId`| Resolves multi-generation family tree hierarchy |
| `POST` | `/api/matrimonial/profiles` | Creates / updates matrimonial biodata |
| `GET` | `/api/matrimonial/profiles` | Queries matrimonial candidates with filters |
| `GET` | `/api/posts` | Fetches community feed posts and announcements |
| `POST` | `/api/posts` | Submits a new post or broadcast request |
| `GET` | `/api/campaigns` | Lists active community events and campaigns |
| `POST` | `/api/campaigns/:id/register` | Registers member for a campaign / event |
| `GET` | `/api/admin/pending-users` | Retrieves pending user registration approvals |
| `PATCH`| `/api/admin/approve-user/:id` | Approves user and grants portal access |

---

## 🧪 Testing & Code Quality

Run Flutter lint and static analysis:
```bash
flutter analyze
```

Run test suite:
```bash
flutter test
```

Test backend endpoints:
```bash
cd backend
node test_backend.js
node test_registration_flow.js
node test_family_tree.js
```

---

## 📜 License & Academic Notice

This project is developed as a **Final Year Capstone Project**. All rights reserved.
For academic inquiries and demo requests, please contact the project maintainers.
