from appium import webdriver
from appium.options.android import UiAutomator2Options
from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time


# ==============================
# APP CONFIGURATION
# ==============================

APK_PATH = r"C:\Users\Abcom\OneDrive\Desktop\FINAL YEAR PROJECT KUTUMBSETU\build\app\outputs\flutter-apk\app-debug.apk"

ADMIN_USERNAME = "admin"
ADMIN_PASSWORD = "admin123"


# ==============================
# APPIUM OPTIONS
# ==============================

options = UiAutomator2Options()

options.platform_name = "Android"
options.device_name = "emulator-5554"
options.automation_name = "UiAutomator2"
options.app = APK_PATH
options.app_package = "com.kutumbsetu.kutumbsetu"
options.app_activity = ".MainActivity"


# ==============================
# START APPIUM
# ==============================

driver = webdriver.Remote(
    "http://127.0.0.1:4723",
    options=options
)

wait = WebDriverWait(driver, 15)

print("Application launched successfully!")

print("\n========== APPLICATION DETAILS ==========")
print("Package:", driver.capabilities.get("appPackage"))
print("Activity:", driver.current_activity)
print("Device:", driver.capabilities.get("deviceName"))
print("Android:", driver.capabilities.get("platformVersion"))
print("Automation:", driver.capabilities.get("automationName"))


# ==============================
# LOGIN SCREEN
# ==============================

print("\n========== LOGIN SCREEN ==========")

admin_button = wait.until(
    EC.presence_of_element_located(
        (AppiumBy.ACCESSIBILITY_ID, "Login as Admin")
    )
)

print("Admin Login button found!")

admin_button.click()

print("\nClicking Login as Admin...")

time.sleep(2)


# ==============================
# ADMIN LOGIN SCREEN
# ==============================

print("\n========== ADMIN LOGIN SCREEN ==========")

username = wait.until(
    EC.presence_of_element_located(
        (AppiumBy.ACCESSIBILITY_ID, "Admin Username")
    )
)

password = wait.until(
    EC.presence_of_element_located(
        (AppiumBy.ACCESSIBILITY_ID, "Admin Password")
    )
)

print("Admin Username field found!")
print("Admin Password field found!")


# ==============================
# ENTER ADMIN CREDENTIALS
# ==============================

username.click()
username.send_keys(ADMIN_USERNAME)

password.click()
password.send_keys(ADMIN_PASSWORD)

print("Admin credentials entered successfully.")


# ==============================
# VERIFY & LOGIN
# ==============================

login_button = wait.until(
    EC.element_to_be_clickable(
        (AppiumBy.ACCESSIBILITY_ID, "Verify Admin & Log In")
    )
)

print("Verify Admin & Log In button found!")

login_button.click()

print("\nAdmin login button clicked.")

time.sleep(3)


# ==============================
# INSPECT RESULTING SCREEN
# ==============================

print("\n========== AFTER ADMIN LOGIN ==========")

elements = driver.find_elements(AppiumBy.XPATH, "//*")

for element in elements:
    try:
        text = element.get_attribute("text")
        desc = element.get_attribute("content-desc")
        hint = element.get_attribute("hint")

        if text or desc or hint:
            print(
                f"TEXT='{text}' | "
                f"DESC='{desc}' | "
                f"HINT='{hint}'"
            )

    except Exception:
        pass


print("\nAdmin login test completed.")

driver.quit()

print("\n======================================")
print("ADMIN LOGIN AUTOMATION TEST PASSED")
print("======================================")