# 📱 KutumbSetu Appium Test Automation Suite

Comprehensive Mobile Test Automation Framework for **KutumbSetu Android Application** using **Appium** and **WebdriverIO (WDIO)**.

---

## 📁 Automation Folder Structure

```
automation/
├── config/
│   ├── capabilities.js        # Android device & app capabilities configuration
│   ├── wdio.android.conf.js   # WebdriverIO test runner configuration
│   └── test-runner.js         # Standalone direct Node.js Appium test runner
├── test/
│   ├── pageobjects/
│   │   ├── base.page.js       # Base page with reusable UI & driver actions
│   │   └── login.page.js      # Login screen page object model
│   └── specs/
│       ├── app_launch.spec.js # App launch and sanity test suite
│       └── login_flow.spec.js # Login, OTP, Admin switch & navigation specs
├── package.json               # Test execution scripts and dependencies
└── README.md                  # Instructions & setup guide
```

---

## 🛠️ Prerequisites

1. **Node.js**: v18 or higher installed
2. **Appium 2.x**:
   ```bash
   npm install -g appium
   appium driver install uiautomator2
   ```
3. **Android SDK & ADB**:
   - Ensure `ANDROID_HOME` / `ANDROID_SDK_ROOT` is set in your environment variables.
   - Connected physical device (USB debugging enabled) or running Android Emulator:
     ```bash
     adb devices
     ```
4. **App APK**:
   - The default configuration points directly to:
     `../../build/app/outputs/flutter-apk/app-debug.apk`
   - To rebuild the Flutter APK anytime:
     ```bash
     flutter build apk --debug
     ```

---

## 🚀 How to Run the Tests

### Step 1: Start Appium Server
In a separate terminal, start the Appium server:
```bash
appium
```
*(Runs on `http://127.0.0.1:4723`)*

---

### Step 2: Run Tests

Navigate to the `automation` directory:
```bash
cd automation
```

#### Option A: Run Full WebdriverIO Test Suite
```bash
npm test
```

#### Option B: Run Standalone Direct Runner Script
Fast standalone smoke test script that verifies screen elements, typing, and admin switch without needing Mocha runner:
```bash
npm run test:standalone
```
*or directly with node:*
```bash
node config/test-runner.js
```

#### Option C: Run Specific Test Specs
- **Login Flow Test:**
  ```bash
  npm run test:login
  ```
- **App Launch / Sanity Test:**
  ```bash
  npm run test:launch
  ```

---

## ⚙️ Environment Variables (Optional Customization)

You can customize device name or APK path without modifying code:

| Variable | Description | Default |
|---|---|---|
| `DEVICE_NAME` | Target emulator or device name | `Android Emulator` |
| `PLATFORM_VERSION` | Android OS version | Auto-detected |
| `APP_PATH` | Path to customized `.apk` file | `build/app/outputs/flutter-apk/app-debug.apk` |

**Example:**
```powershell
$env:DEVICE_NAME="Pixel_7_Pro"
npm test
```
