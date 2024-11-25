//
//  AccountViewModel.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 19.11.24.
//

import Foundation
import UIKit.UIApplication

final class AccountViewModel: BaseViewModel {
    // MARK: - Properties
    @Published private(set) var isSignedIn = false
    @Published private(set) var userName: String? = nil
    @Published private(set) var settings: [Setting] = []
    @Published private(set) var isGoogleAuthInProgress = false
    @Published private(set) var isTwitterAuthInProgress = false
    
    private let firebaseAuthService: FirebaseAuthService
    private let googleSignInService: GoogleSignInService
    private let twitterSignInService: TwitterSignInService
    
    // MARK: - Initializers
    convenience init() {
        self.init(
            firebaseAuthService: FirebaseAuthServiceImpl(),
            googleSignInService: GoogleSignInServiceImpl(),
            twitterSignInService: TwitterSignInServiceImpl()
        )
    }
    
    init(
        firebaseAuthService: FirebaseAuthService,
        googleSignInService: GoogleSignInService,
        twitterSignInService: TwitterSignInService
    ) {
        self.firebaseAuthService = firebaseAuthService
        self.googleSignInService = googleSignInService
        self.twitterSignInService = twitterSignInService
        super.init()
    }
    
    // MARK: - Authentication
    func signInWithGoogle() {
        guard
            let clientID = firebaseAuthService.clientID,
            let rootViewController = UIApplication.rootViewController
        else {
            return
        }
        
        googleSignInService.configure(clientID: clientID)
        
        isGoogleAuthInProgress = true
        
        googleSignInService.signIn(withPresenting: rootViewController) { [weak self] result, error in
            guard
                let self,
                let user = result?.user,
                let idToken = user.idToken?.tokenString,
                error == nil
            else {
                self?.isGoogleAuthInProgress = false
                return
            }
            
            let credential = googleSignInService.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            
            firebaseAuthService.signIn(with: credential) { authResult, error in
                if let error {
                    self.setErrorMessage(error)
                } else {
                    self.isSignedIn = true
                    self.userName = user.profile?.name
                }
                self.isGoogleAuthInProgress = false
            }
        }
    }
    
    func signInWithTwitter() {
        isTwitterAuthInProgress = true
        
        twitterSignInService.signIn { [weak self] credential, error in
            guard
                let self,
                let credential,
                error == nil
            else {
                self?.isTwitterAuthInProgress = false
                return
            }
            
            firebaseAuthService.signIn(with: credential) { authResult, error in
                if let error {
                    self.setErrorMessage(error)
                } else {
                    self.isSignedIn = true
                    self.userName = authResult?.user.displayName
                }
                self.isTwitterAuthInProgress = false
            }
        }
    }
    
    func signOut() {
        do {
            try firebaseAuthService.signOut()
            isSignedIn = false
            userName = nil
        } catch {
            setErrorMessage(error)
        }
    }
    
    func fetchAuthState() {
        if let user = firebaseAuthService.currentUser {
            isSignedIn = true
            userName = user.displayName ?? user.email
        } else {
            isSignedIn = false
        }
    }
    
    // MARK: - Settings
    func fetchSettings() {
        settings = [
            Setting(type: .language, selectedOption: getSavedSetting(of: .language)),
            Setting(type: .currency, selectedOption: getSavedSetting(of: .currency)),
            Setting(type: .privacyPolicy)
        ]
        
        if isSignedIn {
            settings.append(Setting(type: .signOut))
        }
    }
    
    func setting(of type: Setting.SettingType) -> Setting? {
        settings.first(where: { $0.type == type })
    }
    
    func updateSetting(of type: Setting.SettingType, with value: String) {
        if let index = settings.firstIndex(where: { $0.type == type }) {
            settings[index].selectedOption = value
            setSetting(value, of: settings[index].type)
        }
    }
    
    // MARK: - Private Methods
    private func getSavedSetting(of type: Setting.SettingType) -> String? {
        do {
            return try userDefaultsManager.getObject(forKey: type.rawValue, objectType: String.self)
        } catch {
            setErrorMessage(error)
            return nil
        }
    }
    
    private func setSetting(_ setting: String, of type: Setting.SettingType) {
        do {
            try userDefaultsManager.setObject(setting, forKey: type.rawValue)
        } catch {
            setErrorMessage(error)
        }
    }
}

struct Setting: Identifiable, Hashable {
    enum SettingType: String, CaseIterable {
        case language
        case currency
        case privacyPolicy
        case signOut
        
        var title: String {
            switch self {
            case .language: return "Language"
            case .currency: return "Currency"
            case .privacyPolicy: return "Privacy Policy"
            case .signOut: return "Sign Out"
            }
        }
        
        var icon: String {
            switch self {
            case .language: return "globe"
            case .currency: return "dollarsign.circle"
            case .privacyPolicy: return "doc.text"
            case .signOut: return "rectangle.portrait.and.arrow.right"
            }
        }
        
        var options: [(name: String, isEnabled: Bool)] {
            switch self {
            case .language:
                return [
                    ("English", true),
                    ("Spanish", false),
                    ("German", false),
                    ("French", false)
                ]
            case .currency:
                return [
                    ("USD", true),
                    ("EUR", false),
                    ("GBP", false),
                    ("JPY", false)
                ]
            case .privacyPolicy, .signOut:
                return []
            }
        }
    }
    
    var id = UUID()
    let type: SettingType
    var selectedOption: String? = nil
}
