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

try:
    print("\nApplication launched successfully!")
    time.sleep(3)  # Allow initial Flutter build

    # -------------------------------------------------------------
    # Step 1: Click "Login as Admin"
    # -------------------------------------------------------------
    print("\n[Step 1] Locating 'Login as Admin' button...")
    admin_btn = wait.until(
        EC.presence_of_element_located((
            AppiumBy.XPATH,
            "//*[@content-desc='Login as Admin' or @text='Login as Admin']"
        ))
    )
    admin_btn.click()
    print("Clicked 'Login as Admin' button successfully!")

    time.sleep(2)

    # -------------------------------------------------------------
    # Step 2: Locate EditText fields for Username and Password
    # -------------------------------------------------------------
    print("\n[Step 2] Locating Admin Username & Password fields...")
    
    edit_fields = wait.until(
        lambda d: d.find_elements(AppiumBy.CLASS_NAME, "android.widget.EditText")
    )

    if len(edit_fields) < 2:
        raise Exception(f"Expected at least 2 input fields, found {len(edit_fields)}")

    username_field = edit_fields[0]
    password_field = edit_fields[1]

    # Enter Username
    username_field.click()
    time.sleep(0.5)
    username_field.send_keys(ADMIN_USERNAME)
    print(f"Entered Username: '{ADMIN_USERNAME}'")

    # Enter Password
    password_field.click()
    time.sleep(0.5)
    password_field.send_keys(ADMIN_PASSWORD)
    print("Entered Password successfully.")

    # -------------------------------------------------------------
    # Step 3: Click "Verify Admin & Log In"
    # -------------------------------------------------------------
    print("\n[Step 3] Submitting login...")
    login_btn = wait.until(
        EC.element_to_be_clickable((
            AppiumBy.XPATH,
            "//*[@content-desc='Verify Admin & Log In' or @text='Verify Admin & Log In']"
        ))
    )
    login_btn.click()
    print("Clicked 'Verify Admin & Log In' button!")

    time.sleep(3)

    # -------------------------------------------------------------
    # Step 4: Verify Admin Dashboard Loaded
    # -------------------------------------------------------------
    print("\n[Step 4] Verifying Admin Dashboard...")
    admin_dashboard_element = wait.until(
        EC.presence_of_element_located((
            AppiumBy.XPATH,
            "//*[contains(@content-desc, 'Logged in as System Admin') or contains(@content-desc, 'KutumbSetu Admin')]"
        ))
    )
    dashboard_desc = admin_dashboard_element.get_attribute("content-desc")
    print(f"\nDashboard Header Verified:\n{dashboard_desc}")

    print("\n======================================")
    print("  ADMIN LOGIN AUTOMATION TEST PASSED! ")
    print("======================================")

except Exception as e:
    print(f"\nTEST FAILED with error: {e}")
    sys.exit(1)

finally:
    time.sleep(2)
    driver.quit()
    print("Appium session ended.")