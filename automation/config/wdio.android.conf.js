const path = require('path');
const { androidCapabilities } = require('./capabilities');

exports.config = {
    // ====================
    // Runner Configuration
    // ====================
    runner: 'local',
    port: 4723,
    path: '/',

    // ==================
    // Specify Test Files
    // ==================
    specs: [
        path.resolve(__dirname, '../test/specs/**/*.spec.js')
    ],
    exclude: [],

    // ============
    // Capabilities
    // ============
    maxInstances: 1,
    capabilities: [androidCapabilities],

    // ===================
    // Test Configurations
    // ===================
    logLevel: 'info',
    bail: 0,
    waitforTimeout: 20000,
    connectionRetryTimeout: 120000,
    connectionRetryCount: 3,
    services: [], // Set to ['appium'] if using @wdio/appium-service, or start appium CLI independently
    framework: 'mocha',
    reporters: ['spec'],

    // Options to be passed to Mocha.
    mochaOpts: {
        ui: 'bdd',
        timeout: 90000
    },

    // =====
    // Hooks
    // =====
    beforeSession: function () {
        console.log('🚀 Initializing Appium automation session for KutumbSetu...');
    },

    before: async function () {
        console.log('📱 App session started on target Android device/emulator.');
    },

    afterTest: async function (test, context, { error, result, duration, passed }) {
        if (!passed) {
            const timestamp = new Date().toISOString().replace(/:/g, '-');
            const sanitizedTitle = test.title.replace(/[^a-zA-Z0-9_-]/g, '_');
            const screenshotPath = path.resolve(__dirname, `../screenshots/error_${sanitizedTitle}_${timestamp}.png`);
            
            try {
                const fs = require('fs');
                const screenshotDir = path.resolve(__dirname, '../screenshots');
                if (!fs.existsSync(screenshotDir)) {
                    fs.mkdirSync(screenshotDir, { recursive: true });
                }
                await browser.saveScreenshot(screenshotPath);
                console.log(`📸 Screenshot saved on failure: ${screenshotPath}`);
            } catch (err) {
                console.error('Failed to capture screenshot:', err.message);
            }
        }
    },

    afterSession: async function () {
        console.log('✅ Appium automation session completed.');
    }
};
