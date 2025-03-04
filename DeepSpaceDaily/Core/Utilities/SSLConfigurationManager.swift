//
//  SSLConfigurationManager.swift
//  DeepSpaceDaily
//
//  Created by admin on 04/03/25.
//

import Foundation
import SwiftUI
import Combine

/// A utility class to manage SSL configuration globally
class SSLConfigurationManager: ObservableObject {
    static let shared = SSLConfigurationManager()
    
    /// The current SSL validation mode
    @Published var currentMode: SSLValidationMode
    
    /// Whether SSL validation is in strict mode
    var isStrictMode: Bool { currentMode == .strict }
    
    /// Whether SSL validation is in standard mode
    var isStandardMode: Bool { currentMode == .standard }
    
    /// Whether SSL validation is disabled
    var isDisabled: Bool { currentMode == .disabled }
    
    private init() {
        // Load saved mode from UserDefaults or use strict as default
        if let savedMode = UserDefaults.standard.string(forKey: "SSLValidationMode"),
           let mode = SSLValidationMode(rawValue: savedMode) {
            self.currentMode = mode
        } else {
            self.currentMode = .strict
        }
        
        // Apply the configuration
        applyConfiguration()
    }
    
    /// Set the SSL validation mode
    /// - Parameter mode: The SSL validation mode to use
    func setMode(_ mode: SSLValidationMode) {
        self.currentMode = mode
        
        // Save to UserDefaults
        UserDefaults.standard.set(mode.rawValue, forKey: "SSLValidationMode")
        
        // Apply the configuration
        applyConfiguration()
        
        // Show warning if SSL validation is disabled
        if mode == .disabled {
            showInsecureWarning()
        }
    }
    
    /// Apply the current SSL configuration to the app
    private func applyConfiguration() {
        // Update the DependencyInjection container
        DependencyInjection.shared.configureSSL(mode: currentMode)
    }
    
    /// Get a description for the given SSL validation mode
    /// - Parameter mode: The SSL validation mode
    /// - Returns: A human-readable description
    func descriptionForMode(_ mode: SSLValidationMode) -> String {
        switch mode {
        case .strict:
            return "Strict (Pinned Certificate)"
        case .standard:
            return "Standard (System Trust)"
        case .disabled:
            return "Disabled (Insecure)"
        }
    }
    
    /// Show a warning for insecure SSL mode
    private func showInsecureWarning() {
        #if DEBUG
        print("⚠️ WARNING: SSL validation is disabled. This makes your app vulnerable to man-in-the-middle attacks.")
        print("⚠️ This setting should only be used for development and testing purposes.")
        #endif
    }
}

// MARK: - SwiftUI View Extension

/// A view that allows configuring SSL validation mode
struct SSLConfigurationView: View {
    @ObservedObject private var sslManager = SSLConfigurationManager.shared
    @State private var showWarning = false
    
    var body: some View {
        Form {
            Section(header: Text("SSL Validation Mode")) {
                Picker("Mode", selection: Binding(
                    get: { self.sslManager.currentMode },
                    set: { newValue in
                        if newValue == .disabled {
                            showWarning = true
                        } else {
                            self.sslManager.setMode(newValue)
                        }
                    }
                )) {
                    ForEach(SSLValidationMode.allCases, id: \.self) { mode in
                        Text(sslManager.descriptionForMode(mode)).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Text(sslManager.descriptionForMode(sslManager.currentMode))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .alert(isPresented: $showWarning) {
            Alert(
                title: Text("Security Warning"),
                message: Text("Disabling SSL validation makes your app vulnerable to man-in-the-middle attacks. Only use this setting for development and testing purposes."),
                primaryButton: .destructive(Text("Disable Anyway")) {
                    sslManager.setMode(.disabled)
                },
                secondaryButton: .cancel()
            )
        }
    }
} 
