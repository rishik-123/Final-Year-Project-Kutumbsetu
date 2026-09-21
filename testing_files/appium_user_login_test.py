import os
import sys
import time
from appium import webdriver
from appium.options.android import UiAutomator2Options
from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# Optional pymongo for 100% autonomous OTP fetching
try:
    from pymongo import MongoClient
    HAS_PYMONGO = True
except ImportError:
    HAS_PYMONGO = False

# ==============================
# CONFIGURATION
# ==============================
USER_EMAIL = "rishikjariwala54@gmail.com"
MONGO_URI = "mongodb+srv://admin:adminpass123@kutumbsetu.zd2txth.mongodb.net/kutumbsetu?retryWrites=true&w=majority&appName=KutumbSetu"

project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APK_PATH = os.path.join(project_root, "build", "app", "outputs", "flutter-apk", "app-debug.apk")
if not os.path.exists(APK_PATH):
    APK_PATH = r"C:\Users\Abcom\OneDrive\Desktop\FINAL YEAR PROJECT KUTUMBSETU\build\app\outputs\flutter-apk\app-debug.apk"

# ==============================
# HELPER: FETCH REAL-TIME OTP
# ==============================
def get_latest_otp(email, max_retries=10):
    """Fetches the newest generated OTP directly from MongoDB or falls back to prompt."""
    if HAS_PYMONGO:
        try:
            print(f"\n[OTP Service] Fetching latest OTP for {email} from Database...")
            client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000)
            db = client["kutumbsetu"]
            otp_coll = db["otpverifications"]

            for i in range(max_retries):
                doc = otp_coll.find_one({"email": email.lower().trim()})
                if doc and doc.get("otp"):
                    otp_code = str(doc["otp"]).strip()
                    print(f"[OTP Service] Successfully retrieved OTP: {otp_code}")
                    return otp_code
                time.sleep(1)
        except Exception as e:
            print(f"[OTP Service] MongoDB query notice: {e}")

    # Fallback if DB client is unreachable
    print("\n" + "="*50)
    entered = input(f"Enter the 6-digit OTP received on {email}: ").strip()
    print("="*50 + "\n")
    return entered

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

options.set_capability("appium:adbExecTimeout", 60000)
options.set_capability("appium:uiautomator2ServerInstallTimeout", 60000)
options.set_capability("appium:androidInstallTimeout", 90000)
options.set_capability("appium:appWaitActivity", "*")

print("======================================")
print("     KUTUMBSETU USER LOGIN TEST")
print("======================================")
print(f"Target User Email: {USER_EMAIL}")
print("Connecting to Appium server on http://127.0.0.1:4723 ...")

driver = webdriver.Remote("http://127.0.0.1:4723", options=options)
wait = WebDriverWait(driver, 25)

try:
    print("\nApplication launched successfully!")
    time.sleep(3)  # Allow initial Flutter render

    # -------------------------------------------------------------
    # Step 1: Locate & Enter User Email
    # -------------------------------------------------------------
    print("\n[Step 1] Locating Email Input field...")
    email_field = wait.until(
        lambda d: d.find_element(AppiumBy.CLASS_NAME, "android.widget.EditText")
    )
    email_field.click()
    time.sleep(0.5)
    email_field.clear()
    email_field.send_keys(USER_EMAIL)
    print(f"Entered User Email: '{USER_EMAIL}'")

    # -------------------------------------------------------------
    # Step 2: Click "Send OTP Code"
    # -------------------------------------------------------------
    print("\n[Step 2] Clicking 'Send OTP Code' button...")
    send_otp_btn = wait.until(
        EC.element_to_be_clickable((
            AppiumBy.XPATH,
            "//*[@content-desc='Send OTP Code' or @text='Send OTP Code']"
        ))
    )
    send_otp_btn.click()
    print("Clicked 'Send OTP Code' successfully! Waiting for OTP generation...")

    time.sleep(3)

    # -------------------------------------------------------------
    # Step 3: Fetch the generated OTP
    # -------------------------------------------------------------
    otp_code = get_latest_otp(USER_EMAIL)
    print(f"\n[Step 3] Using OTP: '{otp_code}'")

    # -------------------------------------------------------------
    # Step 4: Locate OTP Input field and Enter OTP
    # -------------------------------------------------------------
    print("\n[Step 4] Entering OTP into app...")
    otp_field = wait.until(
        lambda d: d.find_element(AppiumBy.CLASS_NAME, "android.widget.EditText")
    )
    otp_field.click()
    time.sleep(0.5)
    otp_field.clear()
    otp_field.send_keys(otp_code)
    print(f"Entered OTP: '{otp_code}' successfully.")

    # -------------------------------------------------------------
    # Step 5: Click "Verify & Log In"
    # -------------------------------------------------------------
    print("\n[Step 5] Clicking 'Verify & Log In' button...")
    verify_btn = wait.until(
        EC.element_to_be_clickable((
            AppiumBy.XPATH,
            "//*[@content-desc='Verify & Log In' or @text='Verify & Log In']"
        ))
    )
    verify_btn.click()
    print("Clicked 'Verify & Log In' button!")

    time.sleep(4)

    # -------------------------------------------------------------
    # Step 6: Verify User Home Screen is Loaded
    # -------------------------------------------------------------
    print("\n[Step 6] Verifying User Home Screen...")
    home_indicator = wait.until(
        EC.presence_of_element_located((
            AppiumBy.XPATH,
            "//*[contains(@content-desc, 'Jay Shree Krishna') or "
            "contains(@content-desc, 'Quick actions') or "
            "contains(@content-desc, 'Family Tree') or "
            "contains(@content-desc, 'Directory') or "
            "contains(@content-desc, 'Matrimony') or "
            "contains(@content-desc, 'Events') or "
            "contains(@content-desc, 'Community Feed')]"
        ))
    )
    indicator_text = home_indicator.get_attribute("content-desc") or home_indicator.get_attribute("text")
    print(f"\nHome Screen Verified Successfully! Detected: '{indicator_text}'")

    print("\n======================================")
    print("   USER LOGIN AUTOMATION TEST PASSED!  ")
    print("======================================")

except Exception as e:
    print(f"\nTEST FAILED with error: {e}")
    sys.exit(1)

finally:
    time.sleep(2)
    driver.quit()
    print("Appium session ended.")
