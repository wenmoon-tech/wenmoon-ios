//
//  FirebaseAuthService.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 25.11.24.
//

import FirebaseAuth

protocol FirebaseAuthService {
    var clientID: String? { get }
    var userID: String? { get }
    
    func signIn(with credential: AuthCredential) async throws -> AuthDataResult
    func signOut() throws
    func getIDToken() async throws -> String
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
    
    var userID: String? {
        auth.currentUser?.uid
    }
    
    func signIn(with credential: AuthCredential) async throws -> AuthDataResult {
        try await withCheckedThrowingContinuation { continuation in
            auth.signIn(with: credential) { result, error in
                guard (error == nil) else {
                    continuation.resume(throwing: error!)
                    return
                }
                guard let result else {
                    continuation.resume(throwing: AuthError.failedToSignIn())
                    return
                }
                continuation.resume(returning: result)
            }
        }
    }
    
    func signOut() throws {
        try auth.signOut()
    }
    
    func getIDToken() async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.userNotSignedIn
        }
        return try await withCheckedThrowingContinuation { continuation in
            user.getIDToken { token, error in
                guard (error == nil) else {
                    continuation.resume(throwing: error!)
                    return
                }
                guard let token else {
                    continuation.resume(throwing: AuthError.failedToFetchFirebaseToken)
                    return
                }
                continuation.resume(returning: token)
            }
        }
    }
}
