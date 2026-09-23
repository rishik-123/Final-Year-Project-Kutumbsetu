import os
import sys
import time
import re
import imaplib
import email
from appium import webdriver
from appium.options.android import UiAutomator2Options
from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# Optional pymongo
try:
    from pymongo import MongoClient
    HAS_PYMONGO = True
except ImportError:
    HAS_PYMONGO = False

# ==============================
# CONFIGURATION
# ==============================
USER_EMAIL = "rishikjariwala54@gmail.com"
GMAIL_APP_PASS = "uauihfmvkxvlrmme"
MONGO_URI = "mongodb+srv://admin:adminpass123@kutumbsetu.zd2txth.mongodb.net/kutumbsetu?retryWrites=true&w=majority&appName=KutumbSetu"

project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APK_PATH = os.path.join(project_root, "build", "app", "outputs", "flutter-apk", "app-debug.apk")
if not os.path.exists(APK_PATH):
    APK_PATH = r"C:\Users\Abcom\OneDrive\Desktop\FINAL YEAR PROJECT KUTUMBSETU\build\app\outputs\flutter-apk\app-debug.apk"

# ==============================
# 1. AUTO-FETCH OTP FROM GMAIL
# ==============================
def fetch_otp_from_gmail(user_email, app_password, retries=8, delay=2):
    """Connects to Gmail via IMAP (no pip packages needed) and grabs the newest KutumbSetu OTP."""
    print(f"\n[Auto-OTP] Checking Gmail Inbox for new OTP email...")
    for attempt in range(1, retries + 1):
        try:
            mail = imaplib.IMAP4_SSL("imap.gmail.com")
            mail.login(user_email, app_password)
            mail.select("INBOX")

            # Search recent emails
            status, messages = mail.search(None, 'ALL')
            if status == "OK" and messages[0]:
                msg_ids = messages[0].split()
                # Check the latest 5 emails
                for msg_id in reversed(msg_ids[-5:]):
                    res, data = mail.fetch(msg_id, "(RFC822)")
                    if res != "OK":
                        continue
                    
                    msg = email.message_from_bytes(data[0][1])
                    subject = str(msg.get("Subject", ""))
                    
                    body = ""
                    if msg.is_multipart():
                        for part in msg.walk():
                            if part.get_content_type() in ["text/plain", "text/html"]:
                                try:
                                    payload = part.get_payload(decode=True)
                                    if payload:
                                        body += payload.decode(errors="ignore")
                                except Exception:
                                    pass
                    else:
                        payload = msg.get_payload(decode=True)
                        if payload:
                            body = payload.decode(errors="ignore")

                    if "KutumbSetu" in body or "KutumbSetu" in subject or "OTP" in body:
                        # Extract 6-digit OTP
                        matches = re.findall(r'\b\d{6}\b', body)
                        if matches:
                            mail.logout()
                            print(f"[Auto-OTP] Found OTP in Gmail: {matches[0]}")
                            return matches[0]

            mail.logout()
        except Exception as e:
            print(f"[Auto-OTP] Gmail check attempt {attempt} notice: {e}")

        time.sleep(delay)
    return None

# ==============================
# 2. AUTO-FETCH OTP FROM MONGODB
# ==============================
def fetch_otp_from_mongodb(email_addr):
    """Fetches latest OTP directly from MongoDB collection."""
    if not HAS_PYMONGO:
        return None
    try:
        print(f"[Auto-OTP] Checking MongoDB collection 'otpverifications'...")
        client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=4000)
        db = client["kutumbsetu"]
        doc = db["otpverifications"].find_one({"email": email_addr.lower().trim()})
        if doc and doc.get("otp"):
            otp_val = str(doc["otp"]).strip()
            print(f"[Auto-OTP] Found OTP in Database: {otp_val}")
            return otp_val
    except Exception as e:
        print(f"[Auto-OTP] MongoDB notice: {e}")
    return None

def get_latest_otp_automatic(target_email):
    """Combines Gmail IMAP and MongoDB to guarantee zero manual typing."""
    # 1. Try Gmail IMAP
    otp = fetch_otp_from_gmail(target_email, GMAIL_APP_PASS, retries=5, delay=2)
    if otp:
        return otp

    # 2. Try MongoDB
    otp = fetch_otp_from_mongodb(target_email)
    if otp:
        return otp

    # 3. Fallback prompt if both network queries fail
    print("\n" + "="*50)
    entered = input(f"Enter the 6-digit OTP received on {target_email}: ").strip()
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
    print("Clicked 'Send OTP Code' successfully! Waiting for OTP arrival...")

    time.sleep(3)

    # -------------------------------------------------------------
    # Step 3: Automatically Fetch the OTP (Zero manual entry)
    # -------------------------------------------------------------
    otp_code = get_latest_otp_automatic(USER_EMAIL)
    print(f"\n[Step 3] Auto-retrieved OTP: '{otp_code}'")

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
            "contains(@content-desc, 'Community Feed') or "
            "contains(@content-desc, 'Search families')]"
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
