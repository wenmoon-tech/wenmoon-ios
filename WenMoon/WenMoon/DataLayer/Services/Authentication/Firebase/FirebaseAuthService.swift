//
//  FirebaseAuthService.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 25.11.24.
//

import FirebaseAuth

protocol FirebaseAuthService {
    var clientID: String? { get }
    var currentUser: User? { get }
    
    func signIn(with credential: AuthCredential, completion: @escaping (AuthDataResult?, Error?) -> Void)
    func signOut() throws
}

final class FirebaseAuthServiceImpl: FirebaseAuthService {
    // MARK: - Properties
    private let auth: Auth
    
    // MARK: - Initializers
    convenience init() {
        self.init(auth: .auth())
    }
    
    init(auth: Auth) {
        self.auth = auth
    }
    
    // MARK: - FirebaseAuthService
    var clientID: String? {
        auth.app?.options.clientID
    }
    
    var currentUser: User? {
        auth.currentUser
    }
    
    func signIn(with credential: AuthCredential, completion: @escaping (AuthDataResult?, Error?) -> Void) {
        auth.signIn(with: credential, completion: completion)
    }
    
    func signOut() throws {
        try auth.signOut()
    }
}
