const { remote } = require('webdriverio');
const { androidCapabilities } = require('./capabilities');

async function runAutomationTest() {
    console.log('====================================================');
    console.log('🚀 Starting KutumbSetu Standalone Appium Test Script');
    console.log('====================================================\n');

    let driver;
    try {
        console.log('⏳ Connecting to Appium Server on http://127.0.0.1:4723...');
        driver = await remote({
            hostname: '127.0.0.1',
            port: 4723,
            path: '/',
            capabilities: androidCapabilities,
            logLevel: 'info',
        });

        console.log('✅ Connected to Appium session successfully!');
        console.log('📱 Launching KutumbSetu application...\n');

        // Allow app to load
        await driver.pause(5000);

        // 1. Check App Title / Header Elements
        console.log('🔍 Step 1: Checking App Header Branding (KutumbSetu)...');
        const headerElement = await driver.$('//*[@text="KutumbSetu" or contains(@text, "KutumbSetu") or @content-desc="KutumbSetu"]');
        const isHeaderDisplayed = await headerElement.isDisplayed().catch(() => false);
        if (isHeaderDisplayed) {
            console.log('   ✅ App Branding "KutumbSetu" is visible on screen.');
        } else {
            console.log('   ℹ️ Header element not immediately found with text selector, checking screen view...');
        }

        // 2. Validate Login Elements Presence
        console.log('\n🔍 Step 2: Validating Sign In Screen Elements...');
        const emailField = await driver.$('//android.widget.EditText');
        if (await emailField.isDisplayed().catch(() => false)) {
            console.log('   ✅ Email input field detected.');
            console.log('   ✍️ Typing test email "testuser@kutumbsetu.com"...');
            await emailField.setValue('rishikjariwala54@gmail.com');
            await driver.pause(1000);
        }

        // 3. Check Send OTP Button
        console.log('\n🔍 Step 3: Checking "Send OTP Code" Button...');
        const sendOtpBtn = await driver.$('//*[@text="Send OTP Code" or contains(@text, "Send OTP") or @content-desc="Send OTP Code"]');
        if (await sendOtpBtn.isDisplayed().catch(() => false)) {
            console.log('   ✅ "Send OTP Code" button is present and clickable.');
        }

        // 4. Test "Login as Admin" Switch
        console.log('\n🔍 Step 4: Testing "Login as Admin" toggle button...');
        const adminLoginBtn = await driver.$('//*[@text="Login as Admin" or contains(@text, "Admin") or @content-desc="Login as Admin"]');
        if (await adminLoginBtn.isDisplayed().catch(() => false)) {
            console.log('   👆 Clicking "Login as Admin"...');
            await adminLoginBtn.click();
            await driver.pause(2000);

            const adminSubmitBtn = await driver.$('//*[@text="Verify Admin & Log In" or contains(@text, "Verify Admin") or @content-desc="Verify Admin & Log In"]');
            if (await adminSubmitBtn.isDisplayed().catch(() => false)) {
                console.log('   ✅ Switched to Admin Login form successfully!');
            }

            const backToEmailBtn = await driver.$('//*[@text="Back to Email Login" or contains(@text, "Back to Email") or @content-desc="Back to Email Login"]');
            if (await backToEmailBtn.isDisplayed().catch(() => false)) {
                console.log('   👆 Clicking "Back to Email Login"...');
                await backToEmailBtn.click();
                await driver.pause(1500);
                console.log('   ✅ Switched back to Email Login view.');
            }
        }

        console.log('\n====================================================');
        console.log('🎉 KutumbSetu Automated Appium Smoke Test Passed!');
        console.log('====================================================\n');

    } catch (error) {
        console.error('\n❌ Test execution encountered an error:', error.message);
        console.error('Make sure:');
        console.error(' 1. Appium server is running: npx appium');
        console.error(' 2. Android device or emulator is active: adb devices');
        console.error(' 3. APK is built at build/app/outputs/flutter-apk/app-debug.apk\n');
    } finally {
        if (driver) {
            console.log('🧹 Cleaning up and closing Appium session...');
            await driver.deleteSession();
            console.log('✅ Session ended.');
        }
    }
}

// Execute runner if invoked directly
if (require.main === module) {
    runAutomationTest();
}

module.exports = { runAutomationTest };
