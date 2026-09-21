import os
import sys
import time

try:
    from appium import webdriver
    from appium.options.android import UiAutomator2Options
except ImportError as e:
    print(f"\n[ERROR] Missing required Python package: {e}")
    print("Please install Appium and Selenium dependencies using:")
    print("  pip install Appium-Python-Client selenium\n")
    sys.exit(1)

# Dynamically resolve APK Path
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APK_PATH = os.path.join(project_root, "build", "app", "outputs", "flutter-apk", "app-debug.apk")
if not os.path.exists(APK_PATH):
    APK_PATH = r"C:\Users\Abcom\OneDrive\Desktop\FINAL YEAR PROJECT KUTUMBSETU\build\app\outputs\flutter-apk\app-debug.apk"

# Configure Android UiAutomator2 Options
options = UiAutomator2Options()
options.platform_name = "Android"
options.automation_name = "UiAutomator2"
options.device_name = "emulator-5554"
options.app = APK_PATH
options.no_reset = True
options.auto_grant_permissions = True

# Extended timeouts to prevent adbExec timeouts on emulator
options.set_capability("appium:adbExecTimeout", 60000)
options.set_capability("appium:uiautomator2ServerInstallTimeout", 60000)
options.set_capability("appium:androidInstallTimeout", 90000)
options.set_capability("appium:appWaitActivity", "*")

print("======================================")
print("       KUTUMBSETU APPIUM TEST")
print("======================================")
print("APK Path:", APK_PATH)
print("Connecting to Appium server on http://127.0.0.1:4723 ...")

try:
    driver = webdriver.Remote(
        "http://127.0.0.1:4723",
        options=options
    )

    print("\nApplication launched successfully!")

    # Application information
    print("\n========== APPLICATION DETAILS ==========")
    print("Package:", driver.current_package)
    print("Activity:", driver.current_activity)
    print("Device:", driver.capabilities.get("deviceName"))
    print("Platform:", driver.capabilities.get("platformName"))
    print("Platform Version:", driver.capabilities.get("platformVersion"))
    print("Automation:", driver.capabilities.get("automationName"))

    print("\n========== TEST RESULT ==========")
    print("TEST PASSED")

    time.sleep(3)
    driver.quit()

except Exception as e:
    print(f"\n[ERROR] Test execution failed: {e}")
    sys.exit(1)