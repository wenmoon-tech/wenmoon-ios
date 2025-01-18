//
//  AccountViewModelTests.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 02.12.24.
//

import XCTest
import FirebaseAuth
@testable import WenMoon

class AccountViewModelTests: XCTestCase {
    // MARK: - Properties
    var viewModel: AccountViewModel!
    
    var googleSignInService: GoogleSignInServiceMock!
    var twitterSignInService: TwitterSignInServiceMock!
    var firebaseAuthService: FirebaseAuthServiceMock!
    var userDefaultsManager: UserDefaultsManagerMock!
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        googleSignInService = GoogleSignInServiceMock()
        twitterSignInService = TwitterSignInServiceMock()
        firebaseAuthService = FirebaseAuthServiceMock()
        userDefaultsManager = UserDefaultsManagerMock()
        
        viewModel = AccountViewModel(
            googleSignInService: googleSignInService,
            twitterSignInService: twitterSignInService,
            firebaseAuthService: firebaseAuthService,
            userDefaultsManager: userDefaultsManager
        )
    }
    
    override func tearDown() {
        viewModel = nil
        googleSignInService = nil
        twitterSignInService = nil
        firebaseAuthService = nil
        userDefaultsManager = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func testSignOut_success() async {
        // Setup
        firebaseAuthService.signOutResult = .success(())
        viewModel.loginState = .signedIn()
        
        // Action
        viewModel.signOut()
        
        // Assertions
        XCTAssertTrue(viewModel.loginState == .signedOut)
    }

    func testSignOut_failure() async {
        // Setup
        let expectedUserID = "expectedUserID"
        viewModel.loginState = .signedIn(expectedUserID)
        let error = NSError(domain: "TestErrorDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to sign out"])
        firebaseAuthService.signOutResult = .failure(error)
        
        // Action
        viewModel.signOut()
        
        // Assertions
        switch viewModel.loginState {
        case .signedIn(let userID):
            XCTAssertEqual(userID, expectedUserID)
        case .signedOut:
            XCTFail("User should not be signed out on sign out failure")
        }
        
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "An unknown error occurred: \(error.localizedDescription)")
    }

    func testFetchAuthStateWhenUserIsSignedIn() async {
        // Action
        let expectedUserID = "expectedUserID"
        viewModel.fetchAuthState()
        
        // Assertions
        switch viewModel.loginState {
        case .signedIn(let userID):
            XCTAssertEqual(userID, expectedUserID)
        case .signedOut:
            XCTFail("User should be signed in after fetchAuthState")
        }
    }
    
    func testFetchSettings() {
        // Setup
        let selectedStartScreenOption = 0
        let selectedLanguageOption = 1
        let selectedCurrencyOption = 2
        userDefaultsManager.getObjectReturnValue = [
            .setting(ofType: .startScreen): selectedStartScreenOption,
            .setting(ofType: .language): selectedLanguageOption,
            .setting(ofType: .currency): selectedCurrencyOption
        ]
        let expectedSettings: [Setting] = [
            Setting(type: .startScreen, selectedOption: selectedStartScreenOption),
            Setting(type: .language, selectedOption: selectedLanguageOption),
            Setting(type: .currency, selectedOption: selectedCurrencyOption),
            Setting(type: .privacyPolicy)
        ]
        
        // Action
        viewModel.fetchSettings()
        
        // Assertions
        XCTAssertEqual(viewModel.settings.count, expectedSettings.count)
        for (index, setting) in viewModel.settings.enumerated() {
            XCTAssertEqual(setting.type, expectedSettings[index].type)
            XCTAssertEqual(setting.selectedOption, expectedSettings[index].selectedOption)
        }
    }
    
    func testUpdateSetting() {
        // Setup
        let languageSetting = Setting(type: .language, selectedOption: 0)
        viewModel.settings = [languageSetting]
        
        // Action
        let newLanguageSettingValue = 1
        viewModel.updateSetting(of: .language, with: newLanguageSettingValue)
        
        // Assertions
        let updatedSetting = viewModel.getSetting(of: .language)!
        XCTAssertEqual(updatedSetting.selectedOption, newLanguageSettingValue)
        XCTAssertTrue(userDefaultsManager.setObjectCalled)
        XCTAssertEqual(userDefaultsManager.setObjectValue[.setting(ofType: languageSetting.type)] as! Int, newLanguageSettingValue)
    }
    
    func testGetSetting() {
        // Setup
        let startScreenSetting = Setting(type: .startScreen, selectedOption: 0)
        let languageSetting = Setting(type: .language, selectedOption: 1)
        let currencySetting = Setting(type: .currency, selectedOption: 2)
        viewModel.settings = [startScreenSetting, languageSetting, currencySetting]
        
        // Assertions
        let fetchedStartScreenSetting = viewModel.getSetting(of: .startScreen)
        XCTAssertEqual(fetchedStartScreenSetting, startScreenSetting)
        
        let fetchedLanguageSetting = viewModel.getSetting(of: .language)
        XCTAssertEqual(fetchedLanguageSetting, languageSetting)
        
        let fetchedCurrencySetting = viewModel.getSetting(of: .currency)
        XCTAssertEqual(fetchedCurrencySetting, currencySetting)
        
        let nonExistentSetting = viewModel.getSetting(of: .privacyPolicy)
        XCTAssertNil(nonExistentSetting)
    }
}
