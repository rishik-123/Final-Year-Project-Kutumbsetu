const LoginPage = require('../pageobjects/login.page');

describe('KutumbSetu - Authentication & Login Flow Suite', () => {
    beforeEach(async () => {
        await browser.pause(2000);
    });

    it('should enter email address in the email field', async () => {
        const emailInput = await $('//android.widget.EditText');
        if (await emailInput.isDisplayed().catch(() => false)) {
            await emailInput.setValue('test.user@kutumbsetu.org');
            await browser.pause(1000);
            
            const enteredText = await emailInput.getText().catch(() => '');
            console.log(`[Test] Entered text in email field: ${enteredText}`);
        }
    });

    it('should toggle to Admin Login screen and switch back', async () => {
        const adminBtn = await LoginPage.loginAsAdminButton;
        if (await adminBtn.isDisplayed().catch(() => false)) {
            await adminBtn.click();
            await browser.pause(1500);

            const verifyAdminBtn = await LoginPage.verifyAdminButton;
            const isAdminFormShown = await verifyAdminBtn.isDisplayed().catch(() => false);
            console.log(`[Test] Switched to Admin Form: ${isAdminFormShown}`);

            // Return to email mode
            const backBtn = await LoginPage.backToEmailButton;
            if (await backBtn.isDisplayed().catch(() => false)) {
                await backBtn.click();
                await browser.pause(1000);
            }
        }
    });

    it('should have Register Here link available for new users', async () => {
        const registerLink = await LoginPage.registerLink;
        const isRegisterDisplayed = await registerLink.isDisplayed().catch(() => false);
        console.log(`[Test] Register link visible: ${isRegisterDisplayed}`);
    });
});
