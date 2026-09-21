import os
import sys
import time
from appium import webdriver
from appium.options.android import UiAutomator2Options
from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# ==============================
# CONFIGURATION
# ==============================
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APK_PATH = os.path.join(project_root, "build", "app", "outputs", "flutter-apk", "app-debug.apk")
if not os.path.exists(APK_PATH):
    APK_PATH = r"C:\Users\Abcom\OneDrive\Desktop\FINAL YEAR PROJECT KUTUMBSETU\build\app\outputs\flutter-apk\app-debug.apk"

ADMIN_USERNAME = "admin"
ADMIN_PASSWORD = "admin123"

# ==============================
# APPIUM OPTIONS
# ==============================
options = UiAutomator2Options()
options.platform_name = "Android"
options.automation_name = "UiAutomator2"
options.device_name = "emulator-5554"
options.app = APK_PATH
options.auto_grant_permissions = True
options.no_reset = True

# Increase timeouts to prevent ADB drops
options.set_capability("appium:adbExecTimeout", 60000)
options.set_capability("appium:uiautomator2ServerInstallTimeout", 60000)
options.set_capability("appium:androidInstallTimeout", 90000)
options.set_capability("appium:appWaitActivity", "*")

print("======================================")
print("       KUTUMBSETU APPIUM TEST")
print("======================================")
print("Connecting to Appium server on http://127.0.0.1:4723 ...")

driver = webdriver.Remote("http://127.0.0.1:4723", options=options)
wait = WebDriverWait(driver, 20)

    # 3. Direct Accessibility ID fallback
    return WebDriverWait(driver, 5).until(
        EC.presence_of_element_located((AppiumBy.ACCESSIBILITY_ID, identifier_text))
    )

try:
    print("\nApplication launched successfully!")
    time.sleep(3)  # Allow Flutter initial render

    # -------------------------------------------------------------
    # Step 1: Click "Login as Admin"
    # -------------------------------------------------------------
    print("\n[Step 1] Locating 'Login as Admin' button...")
    admin_btn = find_flutter_element("Login as Admin")
    admin_btn.click()
    print("Clicked 'Login as Admin' button successfully!")

    time.sleep(2)

    # -------------------------------------------------------------
    # Step 2: Locate and Fill Admin Username & Password
    # -------------------------------------------------------------
    print("\n[Step 2] Locating Admin Username & Password fields...")
    
    # In Flutter, input fields can be targeted by ClassName or Text/Hint
    username_field = find_flutter_element("Admin Username")
    username_field.click()
    username_field.send_keys(ADMIN_USERNAME)
    print(f"Entered Username: '{ADMIN_USERNAME}'")

    password_field = find_flutter_element("Admin Password")
    password_field.click()
    password_field.send_keys(ADMIN_PASSWORD)
    print("Entered Password successfully.")

    # -------------------------------------------------------------
    # Step 3: Click "Verify Admin & Log In"
    # -------------------------------------------------------------
    print("\n[Step 3] Submitting login...")
    login_btn = find_flutter_element("Verify Admin & Log In")
    login_btn.click()
    print("Clicked 'Verify Admin & Log In' button!")

    time.sleep(4)

    # -------------------------------------------------------------
    # Step 4: Verify Result
    # -------------------------------------------------------------
    print("\n========== TEST RESULT ==========")
    print("SUCCESS: Admin Login flow executed without errors!")

except Exception as e:
    print(f"\nTEST FAILED with error: {e}")
    # Print available page source snippets for debugging
    try:
        print("\n--- Current Visible Elements ---")
        for el in driver.find_elements(AppiumBy.XPATH, "//*[@text or @content-desc]"):
            t = el.get_attribute("text")
            d = el.get_attribute("content-desc")
            if t or d:
                print(f"  [Found Element] text='{t}' | desc='{d}'")
    except Exception:
        pass
    sys.exit(1)

finally:
    driver.quit()
    print("Appium session ended.")