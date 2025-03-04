//
//  AuthRepository.swift
//  DeepSpaceDaily
//
//  Created by admin on 28/02/25.
//

import Foundation
import Combine
import JWTDecode
import Auth0

// Import the User model
// Since User is in the same module, we don't need to import DeepSpaceDaily

enum AuthError: Error {
    case loginFailed
    case registrationFailed
    case logoutFailed
    case sessionExpired
    case unknown
}

protocol AuthRepository {
    func login(credentials: Credentials?) -> AnyPublisher<User, AuthError>
    func logout() -> AnyPublisher<Void, AuthError>
    func getCurrentUser() -> User
    func isLoggedIn() -> Bool
    func startSessionTimer()
    func resetSessionTimer()
    func stopSessionTimer()
}
