const path = require('path');

// Default APK path calculated dynamically relative to workspace
const DEFAULT_APK_PATH = path.resolve(
    __dirname,
    '../../build/app/outputs/flutter-apk/app-debug.apk'
);

const androidCapabilities = {
    platformName: 'Android',
    'appium:automationName': 'UiAutomator2',
    'appium:deviceName': process.env.DEVICE_NAME || 'emulator-5554',
    'appium:platformVersion': process.env.PLATFORM_VERSION || '',
    'appium:app': process.env.APP_PATH || DEFAULT_APK_PATH,
    'appium:appPackage': 'com.kutumbsetu.kutumbsetu',
    'appium:appActivity': '.MainActivity',
    'appium:appWaitActivity': '*',
    'appium:noReset': true,
    'appium:fullReset': false,
    'appium:autoGrantPermissions': true,
    'appium:newCommandTimeout': 300,
    'appium:adbExecTimeout': 120000,
    'appium:uiautomator2ServerLaunchTimeout': 60000,
    'appium:uiautomator2ServerInstallTimeout': 60000,
    'appium:ensureWebviewsHavePages': true,
    'appium:nativeWebScreenshot': true,
};

module.exports = {
    androidCapabilities,
    capabilities: androidCapabilities,
    DEFAULT_APK_PATH,
};