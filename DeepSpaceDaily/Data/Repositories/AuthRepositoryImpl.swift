//
//  AuthRepositoryImpl.swift
//  DeepSpaceDaily
//
//  Created by admin on 28/02/25.
//

import Foundation
import Combine
import UserNotifications
import Auth0
import JWTDecode

class AuthRepositoryImpl: AuthRepository {
    private let userDefaults = UserDefaults.standard
    private let userKey = "currentUser"
    private let isLoggedInKey = "isLoggedIn"
    private let sessionTimerKey = "sessionTimer"
    
    private var sessionTimer: Timer?
    private let sessionTimeout: TimeInterval = 600 // 10 minutes
    private var sessionExpirationDate: Date?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
    }
    
    // MARK: - Auth Methods
    
    func login(credentials: Credentials? = nil) -> AnyPublisher<User, AuthError> {
        
        if let credentials = credentials {
            let idToken = credentials.idToken
            
            if let user = User(from: idToken) {
                
                if let userData = try? JSONEncoder().encode(user) {
                    userDefaults.set(userData, forKey: userKey)
                    userDefaults.set(true, forKey: isLoggedInKey)
                } else {
                }
                
                startSessionTimer()
                
                return Just(user)
                    .setFailureType(to: AuthError.self)
                    .eraseToAnyPublisher()
            } else {
                return Fail(error: AuthError.loginFailed)
                    .eraseToAnyPublisher()
            }
        }
        
        let user = User(id: "guest", name: "Guest", email: "guest@guest.com", emailVerified: "true", picture: nil, updatedAt: nil)
        
        if let userData = try? JSONEncoder().encode(user) {
            userDefaults.set(userData, forKey: userKey)
            userDefaults.set(true, forKey: isLoggedInKey)
        } else {
            print("[AuthRepository] Failed to encode guest user data")
        }
        
        startSessionTimer()
        
        return Just(user)
            .setFailureType(to: AuthError.self)
            .eraseToAnyPublisher()
    }
        
    func logout() -> AnyPublisher<Void, AuthError> {
        
        userDefaults.removeObject(forKey: userKey)
        userDefaults.set(false, forKey: isLoggedInKey)
        
        stopSessionTimer()
        
        return Just(())
            .setFailureType(to: AuthError.self)
            .eraseToAnyPublisher()
    }
    
    func getCurrentUser() -> User {
        if let userData = userDefaults.data(forKey: userKey),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            return user
        }
        return User.guest
    }
    
    func isLoggedIn() -> Bool {
        let isLoggedIn = userDefaults.bool(forKey: isLoggedInKey)
        return isLoggedIn
    }
    
    // MARK: - Session Management
    
    func startSessionTimer() {
        stopSessionTimer()
        
        let expirationDate = Date().addingTimeInterval(sessionTimeout)
        userDefaults.set(expirationDate.timeIntervalSince1970, forKey: sessionTimerKey)
        sessionExpirationDate = expirationDate
        
        sessionTimer = Timer.scheduledTimer(withTimeInterval: sessionTimeout, repeats: false) { [weak self] _ in
            self?.handleSessionExpiration()
        }
    }
    
    func resetSessionTimer() {
        startSessionTimer()
    }
    
    func stopSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        userDefaults.removeObject(forKey: sessionTimerKey)
        sessionExpirationDate = nil
    }
    
    private func handleSessionExpiration() {
        _ = logout()
            .sink(receiveCompletion: { completion in
                print("[AuthRepository] Logout completion: \(completion)")
            }, receiveValue: { _ in
                print("[AuthRepository] User logged out due to session expiration")
            })
            .store(in: &cancellables)
    }
    
    // MARK: - App Lifecycle
    
    func checkSessionOnAppLaunch() {
        if let expirationTimeInterval = userDefaults.object(forKey: sessionTimerKey) as? TimeInterval {
            let expirationDate = Date(timeIntervalSince1970: expirationTimeInterval)
            
            if Date() >= expirationDate {
                handleSessionExpiration()
            } else {
                let remainingTime = expirationDate.timeIntervalSinceNow
                sessionExpirationDate = expirationDate
                
                sessionTimer = Timer.scheduledTimer(withTimeInterval: remainingTime, repeats: false) { [weak self] _ in
                    self?.handleSessionExpiration()
                }
            }
        } else {
            print("[AuthRepository] No session timer found")
        }
    }
}
