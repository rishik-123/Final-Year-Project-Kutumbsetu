/**
 * Base Page Object containing common selectors and helper methods
 */
class BasePage {
    /**
     * Find element by Android UIAutomator text selector
     */
    async findByText(text, exact = false) {
        if (exact) {
            return $(`android=new UiSelector().text("${text}")`);
        }
        return $(`android=new UiSelector().textContains("${text}")`);
    }

    /**
     * Find element by accessibility ID / content description
     */
    async findByAccessibilityId(id) {
        return $(`~${id}`);
    }

    /**
     * Find element by XPath
     */
    async findByXPath(xpath) {
        return $(xpath);
    }

    /**
     * Wait for element to be displayed with custom timeout
     */
    async waitForElement(element, timeout = 15000) {
        await element.waitForDisplayed({ timeout });
        return element;
    }

    /**
     * Safe click with wait
     */
    async clickElement(element, timeout = 15000) {
        await this.waitForElement(element, timeout);
        await element.click();
    }

    /**
     * Clear and enter text in input field
     */
    async enterText(element, text) {
        await this.waitForElement(element);
        await element.click();
        await element.clearValue();
        await element.setValue(text);
    }

    /**
     * Pause execution in milliseconds
     */
    async pause(ms = 1000) {
        await browser.pause(ms);
    }
}

module.exports = BasePage;
