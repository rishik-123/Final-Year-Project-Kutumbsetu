const BasePage = require('./base.page');

class LoginPage extends BasePage {
    // Selectors
    get appTitle() {
        return $('//*[@text="KutumbSetu" or contains(@text, "KutumbSetu") or @content-desc="KutumbSetu"]');
    }

    get appSubtitleHindi() {
        return $('//*[@text="कुटुम्बसेतु" or contains(@text, "कुटुम्बसेतु")]');
    }

    get signInHeading() {
        return $('//*[@text="Sign In" or contains(@text, "Sign In")]');
    }

    get emailInput() {
        return $('//android.widget.EditText[contains(@text, "Email") or @hint="Email Address" or index=0]');
    }

    get sendOtpButton() {
        return $('//*[@text="Send OTP Code" or contains(@text, "Send OTP")]');
    }

    get loginAsAdminButton() {
        return $('//*[@text="Login as Admin" or contains(@text, "Login as Admin")]');
    }

    get otpInput() {
        return $('//android.widget.EditText[contains(@text, "OTP") or @hint="Enter 6-Digit Email OTP"]');
    }

    get verifyLoginButton() {
        return $('//*[@text="Verify & Log In" or contains(@text, "Verify & Log In")]');
    }

    get adminUsernameInput() {
        return $('//android.widget.EditText[contains(@text, "Admin Username") or @hint="Admin Username"]');
    }

    get adminPasswordInput() {
        return $('//android.widget.EditText[contains(@text, "Admin Password") or @hint="Admin Password"]');
    }

    get verifyAdminButton() {
        return $('//*[@text="Verify Admin & Log In" or contains(@text, "Verify Admin")]');
    }

    get backToEmailButton() {
        return $('//*[@text="Back to Email Login" or contains(@text, "Back to Email Login")]');
    }

    get registerLink() {
        return $('//*[@text="Register Here" or contains(@text, "Register")]');
    }

    // Actions
    async enterEmail(email) {
        const input = await this.emailInput;
        await this.enterText(input, email);
    }

    async clickSendOtp() {
        const btn = await this.sendOtpButton;
        await this.clickElement(btn);
    }

    async switchToAdminLogin() {
        const btn = await this.loginAsAdminButton;
        await this.clickElement(btn);
    }

    async enterAdminCredentials(username, password) {
        const userInput = await this.adminUsernameInput;
        await this.enterText(userInput, username);

        const passInput = await this.adminPasswordInput;
        await this.enterText(passInput, password);
    }

    async clickBackToEmail() {
        const btn = await this.backToEmailButton;
        await this.clickElement(btn);
    }

    async clickRegister() {
        const link = await this.registerLink;
        await this.clickElement(link);
    }
}

module.exports = new LoginPage();
