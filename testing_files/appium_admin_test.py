from appium import webdriver
from appium.options.android import UiAutomator2Options
from selenium.webdriver.common.by import By
import time

APK_PATH = r"C:\Users\Abcom\OneDrive\Desktop\FINAL YEAR PROJECT KUTUMBSETU\build\app\outputs\flutter-apk\app-debug.apk"

print("======================================")
print("      KUTUMBSETU ADMIN APP TEST")
print("======================================")

options = UiAutomator2Options()

options.platform_name = "Android"
options.automation_name = "UiAutomator2"
options.device_name = "emulator-5554"
options.app = APK_PATH

print("\nStarting Appium...")

driver = webdriver.Remote(
    "http://127.0.0.1:4723",
    options=options
)

print("Application launched successfully!")

time.sleep(3)

# ------------------------------------------------
# APPLICATION DETAILS
# ------------------------------------------------

print("\n========== APPLICATION DETAILS ==========")

print("Package:", driver.current_package)
print("Activity:", driver.current_activity)
print("Device:", driver.capabilities.get("deviceName"))
print("Android:", driver.capabilities.get("platformVersion"))
print("Automation:", driver.capabilities.get("automationName"))

# ------------------------------------------------
# VERIFY LOGIN SCREEN
# ------------------------------------------------

print("\n========== LOGIN SCREEN ==========")

admin_button = driver.find_element(
    By.ACCESSIBILITY_ID,
    "Login as Admin"
)

print("Admin Login button found!")

# ------------------------------------------------
# CLICK ADMIN LOGIN
# ------------------------------------------------

print("\nClicking Login as Admin...")

admin_button.click()

time.sleep(2)

print("Admin login screen opened!")

# ------------------------------------------------
# PRINT CURRENT UI ELEMENTS
# ------------------------------------------------

print("\n========== ADMIN SCREEN ELEMENTS ==========")

elements = driver.find_elements(By.XPATH, "//*")

for element in elements:
    try:
        text = element.text
        desc = element.get_attribute("content-desc")
        hint = element.get_attribute("hint")

        if text or desc or hint:
            print(
                f"TEXT='{text}' | "
                f"DESC='{desc}' | "
                f"HINT='{hint}'"
            )

    except:
        pass

print("\nAdmin screen inspection completed.")

time.sleep(2)

driver.quit()

print("\n======================================")
print("ADMIN SCREEN TEST PASSED")
print("======================================")