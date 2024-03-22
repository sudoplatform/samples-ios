//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

final class VirtualCardsExampleUITests: XCTestCase {

    static let staticApp = XCUIApplication()
    static var staticSetupComplete = false
    static var registered = false
    static var verified = false
    static var supportedFundingSourcesKnown = false
    static var stripeCardSupported = false
    static var checkoutCardSupported = false
    static var checkoutBankAccountSupported = false

    class func deregister() {
        if (staticApp.navigationBars.buttons["Deregister"].exists) {
            staticApp.navigationBars.buttons["Deregister"].tap()
            if (!staticApp.alerts.buttons["Deregister"].waitForExistence(timeout: 1.0)) {
                return
            }
            
            staticApp.alerts.buttons["Deregister"].tap()
            if (!staticApp.staticTexts["Register / Login"].waitForExistence(timeout: 25.0)) {
                return
            }
        }
    }

    override class func setUp() {
        // UI tests must launch the application that they test.
        staticApp.launch()
        deregister()
        staticSetupComplete = true
    }

    override class func tearDown() {
        staticSetupComplete = false
        deregister()
    }

    let app: XCUIApplication = staticApp

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCTAssertTrue(VirtualCardsExampleUITests.staticSetupComplete, "Static setup should be complete")
    }

    override func tearDownWithError() throws {
        if (VirtualCardsExampleUITests.registered) {
            try returnToMainMenu()
        }
    }
    
    /// Register if not already registered
    func register() throws {
        if (!VirtualCardsExampleUITests.registered) {
            if !app.navigationBars.buttons["Deregister"].exists {
                XCTAssertTrue(app/*@START_MENU_TOKEN@*/.staticTexts["Register / Login"]/*[[".buttons[\"Register \/ Login\"].staticTexts[\"Register \/ Login\"]",".staticTexts[\"Register \/ Login\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.exists, "Register can only be attempted from register view")
                app.staticTexts["Register / Login"].tap()
                XCTAssertTrue(app.navigationBars.buttons["Deregister"].waitForExistence(timeout: 25.0), "Registration should complete within 25s")
            }
            VirtualCardsExampleUITests.registered = true
        }

        XCTAssertTrue(VirtualCardsExampleUITests.registered, "App should be registered after calling register")
    }

    /// In registered state, return app to main menu be repeatedly going back until Deregister nav button is visible
    func returnToMainMenu() throws {
        XCTAssertTrue(VirtualCardsExampleUITests.registered, "Can only return to main menu if already registered")
        let maxBackAttempts = 4
        var backAttempts = 0
        while (!app.navigationBars.buttons["Deregister"].exists) {
            XCTAssertLessThanOrEqual(backAttempts, maxBackAttempts, "Exceeded max attempts (\(maxBackAttempts)) to return to main menu")
            XCTAssertTrue(app.navigationBars.buttons.element(boundBy: 0).exists, "Back button must exist as first element")
            app.navigationBars.buttons.element(boundBy: 0).tap()
            backAttempts += 1
        }
    }

    /// If identity not already verified, verify identity
    func verify() throws {
        if (!VirtualCardsExampleUITests.verified) {
            try returnToMainMenu()
            XCTAssertTrue(app.staticTexts["Secure ID Verification"].exists)
            app.staticTexts["Secure ID Verification"].tap()
            XCTAssertTrue(app.staticTexts["Status"].waitForExistence(timeout: 25.0))
            
            let verifiedExists = NSPredicate { _, _ in self.app.staticTexts["Verified"].exists}
            let notVerifiedExists = NSPredicate { _, _ in self.app.staticTexts["Not verified"].exists}
            let statusDisplayed = NSCompoundPredicate(
                orPredicateWithSubpredicates: [
                    verifiedExists,
                    notVerifiedExists
                ]
            )
            let checkingStatusDismissed = NSPredicate { _, _ in !self.app.alerts["Checking status"].exists}
            
            wait(for: [
                    expectation(for: statusDisplayed, evaluatedWith: nil, handler: nil),
                    expectation(for: checkingStatusDismissed, evaluatedWith: nil, handler: nil)],
                 timeout: 25
            )

            if (app.staticTexts["Not verified"].exists) {
                app.navigationBars.buttons["Verify"].tap()
                XCTAssertTrue(app.alerts.buttons["OK"].waitForExistence(timeout: 25.0))
                app.alerts.buttons["OK"].tap()
            }
            else {
                XCTAssertTrue(app.staticTexts["Verified"].exists, "Status must be 'Verified' if it isn't 'Not verified'")
            }
            try returnToMainMenu()

            VirtualCardsExampleUITests.verified = true
        }

        XCTAssertTrue(VirtualCardsExampleUITests.verified, "App should be verified")
    }

    /// Type each character in string individually on active keyboard
    func typeOnKeyboard(_ s: String) {
        s.forEach { c in
            app.keys[String(c)].tap()
        }
    }
    
    /// If not already done, determine which funding source types are supported
    /// in the environment against which we are running. App will be returned to
    /// main menu
    func discoverSupportedFundingSources() throws {
        XCTAssertTrue(VirtualCardsExampleUITests.registered, "Registration must be complete before discoverSupportedFundingSources is called")
        XCTAssertTrue(app.navigationBars.buttons["Deregister"].exists, "App must already be at main menu before discoverSupportedFundingSources is called")

        if (!VirtualCardsExampleUITests.supportedFundingSourcesKnown) {
            app/*@START_MENU_TOKEN@*/.staticTexts["Funding Sources"]/*[[".cells.staticTexts[\"Funding Sources\"]",".staticTexts[\"Funding Sources\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
            app/*@START_MENU_TOKEN@*/.staticTexts["Create Funding Source"]/*[[".cells.staticTexts[\"Create Funding Source\"]",".staticTexts[\"Create Funding Source\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
            
            let finishedLoadingFundingSourceConfigration = NSPredicate { _, _ in !self.app.alerts.staticTexts["Loading funding source configuration"].exists}
            let addStripeCardAppeared = NSPredicate { _, _ in self.app.staticTexts["Add Stripe Credit Card"].exists}
            let addCheckoutCardAppeared = NSPredicate { _, _ in self.app.staticTexts["Add Checkout Credit Card"].exists}
            let addCheckoutBankAccountAppeared = NSPredicate { _, _ in self.app.staticTexts["Add Checkout Bank Account"].exists}
            
            let fundingSourceTypesDisplayed = NSCompoundPredicate(
                orPredicateWithSubpredicates: [
                    addStripeCardAppeared,
                    addCheckoutCardAppeared,
                    addCheckoutBankAccountAppeared
                ]
            )
            
            wait(for: [
                expectation(for: finishedLoadingFundingSourceConfigration, evaluatedWith: nil, handler: nil),
                expectation(for: fundingSourceTypesDisplayed, evaluatedWith: nil, handler: nil)],
                 timeout: 25)
            
            VirtualCardsExampleUITests.stripeCardSupported = self.app.staticTexts["Add Stripe Credit Card"].exists
            VirtualCardsExampleUITests.checkoutCardSupported = self.app.staticTexts["Add Checkout Credit Card"].exists
            VirtualCardsExampleUITests.checkoutBankAccountSupported = self.app.staticTexts["Add Checkout Bank Account"].exists

            VirtualCardsExampleUITests.supportedFundingSourcesKnown = true
            
            try returnToMainMenu()
        }

        XCTAssertTrue(VirtualCardsExampleUITests.supportedFundingSourcesKnown, "support funding sources must be known on exit from here")

        XCTAssertTrue(VirtualCardsExampleUITests.stripeCardSupported || VirtualCardsExampleUITests.checkoutCardSupported || VirtualCardsExampleUITests.checkoutBankAccountSupported, "At least one of stripe card (\(VirtualCardsExampleUITests.stripeCardSupported)), checkout card (\(VirtualCardsExampleUITests.checkoutCardSupported)) or checkout bank account (\(VirtualCardsExampleUITests.checkoutBankAccountSupported)) must be supported")
    }

    /// Fill Checkout.com payment form with specified card details. Expiry is entered as 4 years from current month
    func enterCheckoutCardDetails(cardNumber: String, securityCode: String) {
        // Element hierarchy determined by recording

        let cardNumberInput = app.scrollViews.otherElements.otherElements["CardNumberInput"].children(matching: .other).element.children(matching: .other).element(boundBy: 2).children(matching: .other).element(boundBy: 1).children(matching: .other).element

        let expiryDateInput = app.scrollViews.otherElements.otherElements["ExpiryDateInput"].children(matching: .other).element.children(matching: .other).element(boundBy: 2).children(matching: .other).element.children(matching: .other).element

        let securityCodeInput = app.scrollViews.otherElements.otherElements["CardSecurityCodeInput"].children(matching: .other).element.children(matching: .other).element(boundBy: 2).children(matching: .other).element.children(matching: .other).element

        let doneButton = app.toolbars["Toolbar"].buttons["Done"]

        // When entering the card details, we type on the key board
        // since the input fields are addressable as the text fields
        // and cannot be filled

        cardNumberInput.tap()
        typeOnKeyboard(cardNumber)
        doneButton.tap()
        
        let calendar = Calendar(identifier: .gregorian)
        let expiry = Date(timeIntervalSinceNow: 3600*24*365*4)
        let expiryComponents = calendar.dateComponents([.year,.month], from: expiry)
        
        expiryDateInput.tap()
        typeOnKeyboard(String(format: "%02d", expiryComponents.month!))
        typeOnKeyboard(String(format: "%02d", expiryComponents.year! % 100))
        doneButton.tap()

        securityCodeInput.tap()
        typeOnKeyboard(securityCode)
        doneButton.tap()
    }

    /// Complete Checkout.com 3DS authentication challenge
    func performCheckout3DSAuthentication() {
        // Element hierarchy determined by recording
        let webViewsQuery = app.webViews.webViews.webViews
        let hintCheckout1SecureTextField = webViewsQuery/*@START_MENU_TOKEN@*/.secureTextFields["Hint: Checkout1!"]/*[[".otherElements[\"3DS2 Challenge\"]",".otherElements[\"cko-3ds2-iframe\"].secureTextFields[\"Hint: Checkout1!\"]",".secureTextFields[\"Hint: Checkout1!\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/
        XCTAssertTrue(hintCheckout1SecureTextField.waitForExistence(timeout: 30))
        hintCheckout1SecureTextField.tap()
        hintCheckout1SecureTextField.tap()
        hintCheckout1SecureTextField.typeText("Checkout1!")
        webViewsQuery/*@START_MENU_TOKEN@*/.buttons["Continue"]/*[[".otherElements[\"3DS2 Challenge\"]",".otherElements[\"cko-3ds2-iframe\"].buttons[\"Continue\"]",".buttons[\"Continue\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.tap()
    }

    func test_registrationSucceeds() throws {
        try register()
    }
    
    func test_verificationSucceeds() throws {
        try register()
        try verify()
    }
    
    func test_createCheckoutCardNo3DSFundingSource() throws {
        try register()
        try verify()

        try discoverSupportedFundingSources()
        try XCTSkipIf(!VirtualCardsExampleUITests.checkoutCardSupported, "Checkout card not supported")

        app/*@START_MENU_TOKEN@*/.staticTexts["Funding Sources"]/*[[".cells.staticTexts[\"Funding Sources\"]",".staticTexts[\"Funding Sources\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.staticTexts["Create Funding Source"]/*[[".cells.staticTexts[\"Create Funding Source\"]",".staticTexts[\"Create Funding Source\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

        let checkingStatusWaiter = XCTWaiter()
        checkingStatusWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == 0"), object: app.alerts.staticTexts["Loading funding source configuration"])], timeout: 25)

        app/*@START_MENU_TOKEN@*/.staticTexts["Add Checkout Credit Card"]/*[[".cells.staticTexts[\"Add Checkout Credit Card\"]",".staticTexts[\"Add Checkout Credit Card\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        enterCheckoutCardDetails(
            cardNumber: "4532432452900131",
            securityCode: "257"
        )

        app.buttons["Create funding source"].tap()
        XCTAssertTrue(app.staticTexts["••••0131 (CREDIT)"].waitForExistence(timeout: 60))
    }

    func test_createCheckoutCard3DSFundingSource() throws {
        try register()
        try verify()

        try discoverSupportedFundingSources()
        try XCTSkipIf(!VirtualCardsExampleUITests.checkoutCardSupported, "Checkout card not supported")

        app/*@START_MENU_TOKEN@*/.staticTexts["Funding Sources"]/*[[".cells.staticTexts[\"Funding Sources\"]",".staticTexts[\"Funding Sources\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.staticTexts["Create Funding Source"]/*[[".cells.staticTexts[\"Create Funding Source\"]",".staticTexts[\"Create Funding Source\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

        let checkingStatusWaiter = XCTWaiter()
        checkingStatusWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == 0"), object: app.alerts.staticTexts["Loading funding source configuration"])], timeout: 25)

        app/*@START_MENU_TOKEN@*/.staticTexts["Add Checkout Credit Card"]/*[[".cells.staticTexts[\"Add Checkout Credit Card\"]",".staticTexts[\"Add Checkout Credit Card\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        enterCheckoutCardDetails(
            cardNumber: "4242424242424242",
            securityCode: "100"
        )

        app.buttons["Create funding source"].tap()

        performCheckout3DSAuthentication()
        
        XCTAssertTrue(app.staticTexts["••••4242 (CREDIT)"].waitForExistence(timeout: 60))
    }
}
