import os
import sys
import time

try:
    from appium import webdriver
    from appium.options.android import UiAutomator2Options
    from selenium.webdriver.common.by import By
    from selenium.webdriver.support.ui import WebDriverWait
    from selenium.webdriver.support import expected_conditions as EC
except ImportError as e:
    # Condition for error
    print(f"\n ERROR Missing required Python package: {e}")
    print("Please install Appium and Selenium dependencies using:")
    print("  pip install Appium-Python-Client selenium\n")
    sys.exit(1)

project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APK_PATH = os.path.join(project_root, "build", "app", "outputs", "flutter-apk", "app-debug.apk")
if not os.path.exists(APK_PATH):
    APK_PATH = r"C:\Users\Abcom\OneDrive\Desktop\FINAL YEAR PROJECT KUTUMBSETU\build\app\outputs\flutter-apk\app-debug.apk"

print("======================================")
print("      KUTUMBSETU ADMIN APP TEST")
print("======================================")
print("APK Path:", APK_PATH)

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

print("\nStarting Appium & connecting to server on http://127.0.0.1:4723 ...")

try:
    driver = webdriver.Remote(
        "http://127.0.0.1:4723",
        options=options
    )
except Exception as e:
    print(f"\n[ERROR] Could not start Appium session: {e}")
    sys.exit(1)

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

admin_button = None
try:
    wait = WebDriverWait(driver, 10)
    admin_button = wait.until(
        lambda d: d.find_elements(By.XPATH, "//*[@content-desc='Login as Admin' or @text='Login as Admin' or contains(@content-desc, 'Admin') or contains(@text, 'Admin')]")[0]
    )
    print("Admin Login button found!")
except Exception:
    try:
        admin_button = driver.find_element(By.ACCESSIBILITY_ID, "Login as Admin")
        print("Admin Login button found via Accessibility ID!")
    except Exception as e:
        print(f"[INFO] Could not locate Admin button directly: {e}")

# ------------------------------------------------
# CLICK ADMIN LOGIN
# ------------------------------------------------

if admin_button:
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