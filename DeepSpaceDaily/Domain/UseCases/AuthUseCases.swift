//
//  AuthUseCases.swift
//  DeepSpaceDaily
//
//  Created by admin on 28/02/25.
//

import Foundation
import Combine
import Auth0

protocol LoginUseCase {
    func execute(credentials: Credentials?) -> AnyPublisher<User, AuthError>
}

protocol LogoutUseCase {
    func execute() -> AnyPublisher<Void, AuthError>
}

protocol GetCurrentUserUseCase {
    func execute() -> User
}

protocol IsLoggedInUseCase {
    func execute() -> Bool
}

protocol ManageSessionUseCase {
    func startSession()
    func resetSession()
    func stopSession()
}

// Implementations

class LoginUseCaseImpl: LoginUseCase {
    private let repository: AuthRepository
    
    init(repository: AuthRepository) {
        self.repository = repository
    }
    
    func execute(credentials: Credentials? = nil) -> AnyPublisher<User, AuthError> {
        return repository.login(credentials: credentials)
    }
}

class LogoutUseCaseImpl: LogoutUseCase {
    private let repository: AuthRepository
    
    init(repository: AuthRepository) {
        self.repository = repository
    }
    
    func execute() -> AnyPublisher<Void, AuthError> {
        return repository.logout()
    }
}

class GetCurrentUserUseCaseImpl: GetCurrentUserUseCase {
    private let repository: AuthRepository
    
    init(repository: AuthRepository) {
        self.repository = repository
    }
    
    func execute() -> User {
        return repository.getCurrentUser()
    }
}

class IsLoggedInUseCaseImpl: IsLoggedInUseCase {
    private let repository: AuthRepository
    
    init(repository: AuthRepository) {
        self.repository = repository
    }
    
    func execute() -> Bool {
        return repository.isLoggedIn()
    }
}

class ManageSessionUseCaseImpl: ManageSessionUseCase {
    private let repository: AuthRepository
    
    init(repository: AuthRepository) {
        self.repository = repository
    }
    
    func startSession() {
        repository.startSessionTimer()
    }
    
    func resetSession() {
        repository.resetSessionTimer()
    }
    
    func stopSession() {
        repository.stopSessionTimer()
    }
} 
