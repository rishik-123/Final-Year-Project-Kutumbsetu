from appium import webdriver
from appium.options.android import UiAutomator2Options
import time

import os

# Dynamically resolve the APK path relative to this script directory or fallback to absolute path
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
apk_path = os.path.join(project_root, "build", "app", "outputs", "flutter-apk", "app-debug.apk")
if not os.path.exists(apk_path):
    apk_path = r"C:\Users\Abcom\OneDrive\Desktop\FINAL YEAR PROJECT KUTUMBSETU\build\app\outputs\flutter-apk\app-debug.apk"

options = UiAutomator2Options()

options.platform_name = "Android"
options.automation_name = "UiAutomator2"
options.device_name = "emulator-5554"
options.app = apk_path

driver = webdriver.Remote(
    "http://127.0.0.1:4723",
    options=options
)

print("KutumbSetu application launched successfully")

time.sleep(5)

driver.quit()

print("TEST PASSED")