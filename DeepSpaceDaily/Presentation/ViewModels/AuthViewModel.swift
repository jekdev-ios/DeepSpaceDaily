//
//  AuthViewModel.swift
//  DeepSpaceDaily
//
//  Created by admin on 28/02/25.
//

import Foundation
import Combine
import Auth0
import UserNotifications

class AuthViewModel: ObservableObject {
    // MARK: - Dependencies
    private let loginUseCase: LoginUseCase
    private let logoutUseCase: LogoutUseCase
    private let getCurrentUserUseCase: GetCurrentUserUseCase
    private let manageSessionUseCase: ManageSessionUseCase
    
    // MARK: - Published Properties
    @Published var currentUser: User = User.guest
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published var isAuthenticated: Bool = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(
        loginUseCase: LoginUseCase = DependencyInjection.shared.loginUseCase,
        logoutUseCase: LogoutUseCase = DependencyInjection.shared.logoutUseCase,
        getCurrentUserUseCase: GetCurrentUserUseCase = DependencyInjection.shared.getCurrentUserUseCase,
        manageSessionUseCase: ManageSessionUseCase = DependencyInjection.shared.manageSessionUseCase
    ) {
        self.loginUseCase = loginUseCase
        self.logoutUseCase = logoutUseCase
        self.getCurrentUserUseCase = getCurrentUserUseCase
        self.manageSessionUseCase = manageSessionUseCase
        
        loadUser()
    }
    
    // MARK: - Public Methods
    func login() async throws -> Bool {
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            // Load Auth0 configuration
            guard let path = Bundle.main.path(forResource: "Auth0", ofType: "plist"),
                  let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
                  let domain = dict["Domain"] as? String,
                  let clientId = dict["ClientId"] as? String else {
                throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Auth0 configuration not found"])
            }
            
            // Perform Auth0 authentication
            let credentials = try await authenticateWithAuth0(clientId: clientId, domain: domain)
            
            // Process credentials with LoginUseCase
            return try await processCredentials(credentials)
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.error = error.localizedDescription
            }
            throw error
        }
    }
    
    func logout() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            // Step 1: Clear Auth0 session and ensure it succeeds
            try await clearAuth0Session()
            
            // Step 2: Perform local logout and ensure it succeeds
            try await performLogout()
            
            // Step 3: Send logout notification only after previous steps succeed
            try await sendLogoutNotification()
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.error = error.localizedDescription
            }
        }
    }
    
    func resetSession() {
        manageSessionUseCase.resetSession()
    }
    
    // MARK: - Private Authentication Methods
    
    private func authenticateWithAuth0(clientId: String, domain: String) async throws -> Credentials {
        return try await withCheckedThrowingContinuation { continuation in
            Auth0
                .webAuth(clientId: clientId, domain: domain)
                .scope("openid profile email")
                .audience("https://\(domain)/api/v2/")
                .start { result in
                    switch result {
                    case .success(let credentials):
                        continuation.resume(returning: credentials)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
    
    private func processCredentials(_ credentials: Credentials) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            loginUseCase.execute(credentials: credentials)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] result in
                        self?.isLoading = false
                        
                        switch result {
                        case .failure(let error):
                            self?.error = error.localizedDescription
                            continuation.resume(throwing: error)
                        case .finished:
                            break
                        }
                    },
                    receiveValue: { [weak self] user in
                        guard let self = self else {
                            continuation.resume(throwing: NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Self is nil"]))
                            return
                        }
                        
                        self.currentUser = user
                        self.isAuthenticated = true
                        self.manageSessionUseCase.startSession()
                        continuation.resume(returning: true)
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    private func performLogout() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            logoutUseCase.execute()
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] result in
                        self?.isLoading = false
                        
                        switch result {
                        case .failure(let error):
                            self?.error = error.localizedDescription
                            continuation.resume(throwing: error)
                        case .finished:
                            continuation.resume(returning: ())
                        }
                    },
                    receiveValue: { [weak self] _ in
                        guard let self = self else {
                            return
                        }
                        
                        self.currentUser = User.guest
                        self.isAuthenticated = false
                        self.manageSessionUseCase.stopSession()
                        self.isLoading = false
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    private func sendLogoutNotification() async throws {
        let content = UNMutableNotificationContent()
        content.title = "Logged Out"
        content.body = "Your session has expired and you have been logged out"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        try await UNUserNotificationCenter.current().add(request)
    }
    
    private func clearAuth0Session() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            Auth0.webAuth().clearSession { result in
                switch result {
                case .success:
                    continuation.resume(returning: ())
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    private func loadUser() {
        currentUser = getCurrentUserUseCase.execute()
        isAuthenticated = currentUser.id != "guest"
    }
} 
