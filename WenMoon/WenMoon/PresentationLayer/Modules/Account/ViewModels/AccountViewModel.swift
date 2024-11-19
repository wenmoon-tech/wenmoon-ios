//
//  AccountViewModel.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 19.11.24.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

final class AccountViewModel: BaseViewModel {
    // MARK: - Properties
    @Published private(set) var isSignedIn: Bool = false
    @Published private(set) var userName: String? = nil
    @Published private(set) var settings: [Setting] = []
    @Published private(set) var isGoogleAuthInProgress: Bool = false
    @Published private(set) var isTwitterAuthInProgress: Bool = false
    
    private let twitterProvider = OAuthProvider(providerID: "twitter.com")
    
    // MARK: - Initializers
    convenience init() {
        self.init(userDefaultsManager: UserDefaultsManagerImpl())
    }
    
    init(userDefaultsManager: UserDefaultsManager) {
        super.init(userDefaultsManager: userDefaultsManager)
    }
    
    // MARK: - Authentication
    func signInWithGoogle() {
        guard
            let clientID = FirebaseApp.app()?.options.clientID,
            let rootViewController = UIApplication.rootViewController
        else {
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        isGoogleAuthInProgress = true
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            guard
                let user = result?.user,
                let idToken = user.idToken?.tokenString,
                error == nil
            else {
                self?.isGoogleAuthInProgress = false
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error {
                    self?.setErrorMessage(error)
                } else {
                    self?.isSignedIn = true
                    self?.userName = user.profile?.name
                }
                self?.isGoogleAuthInProgress = false
            }
        }
    }
    
    func signInWithTwitter() {
        isTwitterAuthInProgress = true
        
        twitterProvider.getCredentialWith(nil) { [weak self] credential, error in
            guard let credential, error == nil else {
                self?.isTwitterAuthInProgress = false
                return
            }
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error {
                    self?.setErrorMessage(error)
                } else {
                    self?.isSignedIn = true
                    self?.userName = authResult?.user.displayName
                }
                self?.isTwitterAuthInProgress = false
            }
        }
    }
    
    func signOut() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            isSignedIn = false
            userName = nil
        } catch {
            setErrorMessage(error)
        }
    }
    
    func fetchAuthState() {
        if let user = Auth.auth().currentUser {
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
            return try userDefaultsManager?.getObject(forKey: type.rawValue, objectType: String.self)
        } catch {
            setErrorMessage(error)
            return nil
        }
    }
    
    private func setSetting(_ setting: String, of type: Setting.SettingType) {
        do {
            try userDefaultsManager?.setObject(setting, forKey: type.rawValue)
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
