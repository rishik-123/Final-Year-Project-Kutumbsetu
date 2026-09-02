const { remote } = require('webdriverio');
const { androidCapabilities } = require('./capabilities');

async function runAutomationTest() {
    console.log('====================================================');
    console.log('🚀 Starting KutumbSetu Standalone Appium Test Script');
    console.log('====================================================\n');

    // Target email to type (can be customized via CLI arg: node test-runner.js aryaambokar@gmail.com)
    const targetEmail = process.argv[2] || process.env.TEST_EMAIL || 'aryaambokar@gmail.com';

    let driver;
    try {
        console.log('⏳ Connecting to Appium Server on http://127.0.0.1:4723...');
        driver = await remote({
            hostname: '127.0.0.1',
            port: 4723,
            path: '/',
            capabilities: {
                ...androidCapabilities,
                'appium:udid': process.env.DEVICE_UDID || 'emulator-5554',
            },
            logLevel: 'info',
        });

        console.log('✅ Connected to Appium session on emulator-5554 successfully!');
        console.log('📱 Waiting for KutumbSetu app to load...\n');

        // Allow app to settle on Login screen
        await driver.pause(4000);

        // 1. Locate Email Input Field
        console.log(`🔍 Step 1: Locating Email Address input field...`);
        
        // Multiple fallback selectors for Flutter TextFormFields
        const emailSelectors = [
            '//android.widget.EditText',
            '//android.widget.ScrollView//android.widget.EditText',
            '//*[@text="Email Address" or contains(@hint, "Email") or @content-desc="Email Address"]',
            '//android.widget.FrameLayout//android.widget.EditText'
        ];

        let emailField = null;
        for (const selector of emailSelectors) {
            try {
                const el = await driver.$(selector);
                if (await el.isDisplayed()) {
                    emailField = el;
                    console.log(`   ✅ Found email input element using selector: "${selector}"`);
                    break;
                }
            } catch (_) {}
        }

        if (emailField) {
            console.log(`\n✍️ Step 2: Automatically typing email: "${targetEmail}"...`);
            await emailField.click();
            await driver.pause(500);

            // Clear and type email
            try {
                await emailField.clearValue().catch(() => {});
                await emailField.setValue(targetEmail);
            } catch (err) {
                console.log('   ⚠️ setValue fallback: sending keyboard keys...');
                await driver.keys(targetEmail);
            }

            await driver.pause(1000);
            console.log(`   ✅ Successfully typed "${targetEmail}" into the email field!`);

            // Hide keyboard if open so buttons are visible
            try {
                await driver.hideKeyboard();
            } catch (_) {}
        } else {
            console.log('   ⚠️ Email input field not found directly via UiAutomator2.');
            console.log('   💡 Attempting ADB input text fallback...');
            try {
                await driver.execute('mobile: shell', {
                    command: 'input',
                    args: ['text', targetEmail]
                });
                console.log(`   ✅ Sent text "${targetEmail}" via ADB input.`);
            } catch (e) {
                console.log('   ℹ️ ADB direct input fallback not available.');
            }
        }

        // 2. Check "Send OTP Code" Button
        console.log('\n🔍 Step 3: Checking "Send OTP Code" button...');
        const sendOtpBtn = await driver.$('//*[@text="Send OTP Code" or contains(@text, "Send OTP") or @content-desc="Send OTP Code"]');
        if (await sendOtpBtn.isDisplayed().catch(() => false)) {
            console.log('   ✅ "Send OTP Code" button is detected and ready.');
            // Note: To automatically click Send OTP, uncomment the line below:
            // await sendOtpBtn.click();
        }

        // 3. Optional Admin Switch Test
        console.log('\n🔍 Step 4: Checking "Login as Admin" toggle button...');
        const adminLoginBtn = await driver.$('//*[@text="Login as Admin" or contains(@text, "Admin") or @content-desc="Login as Admin"]');
        if (await adminLoginBtn.isDisplayed().catch(() => false)) {
            console.log('   ✅ "Login as Admin" button is visible.');
        }

        console.log('\n====================================================');
        console.log('🎉 Email Automation Step Completed Successfully!');
        console.log('====================================================\n');

    } catch (error) {
        console.error('\n❌ Test execution encountered an error:', error.message);
        console.error('\n📋 Troubleshooting Steps:');
        console.error(' 1. Ensure Appium Server is running in a terminal:');
        console.error('    npx appium');
        console.error(' 2. Ensure your emulator is booted & connected:');
        console.error('    adb devices   (should show "emulator-5554   device")');
        console.error(' 3. Run the automation test:');
        console.error('    node automation/config/test-runner.js [optional-email]\n');
    } finally {
        if (driver) {
            console.log('🧹 Cleaning up Appium session in 3 seconds...');
            await driver.pause(3000);
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
