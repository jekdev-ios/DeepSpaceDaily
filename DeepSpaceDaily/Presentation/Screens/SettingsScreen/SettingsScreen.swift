import SwiftUI

struct SettingsScreen: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var sslManager = SSLConfigurationManager.shared
    @State private var showSSLWarning = false
    @Environment(\.colorScheme) private var colorScheme
    
    // Dark mode settings
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("lastDarkModeToggleTime") private var lastDarkModeToggleTime: Double = 0
    @AppStorage("keepManualModeSettings") private var keepManualModeSettings = false
    @AppStorage("useAutomaticModeSwitch") private var useAutomaticModeSwitch = true
    @AppStorage("userHasSetMode") private var userHasSetMode = false
    
    // Custom colors
    private var primaryColor: Color {
        colorScheme == .dark ? Color.indigo : Color.blue
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color(UIColor.systemBackground)
    }
    
    private var secondaryBackgroundColor: Color {
        colorScheme == .dark ? Color(UIColor.systemGray6) : Color(UIColor.systemGray6)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Appearance Section
                Section(header: Text("Appearance")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dark Mode")
                            .font(.headline)
                        
                        Toggle("Dark Mode", isOn: $isDarkMode)
                            .onChange(of: isDarkMode) { newValue in
                                // Record that user has manually set the mode
                                userHasSetMode = true
                                // Record the time of the toggle
                                lastDarkModeToggleTime = Date().timeIntervalSince1970
                            }
                        
                        Toggle("Keep current mode setting", isOn: $keepManualModeSettings)
                            .onChange(of: keepManualModeSettings) { newValue in
                                if newValue {
                                    // If user wants to keep settings, record that they've set the mode
                                    userHasSetMode = true
                                    // Update the toggle time to now
                                    lastDarkModeToggleTime = Date().timeIntervalSince1970
                                }
                            }
                        
                        Toggle("Automatic mode switching", isOn: $useAutomaticModeSwitch)
                        
                        Text(getAppearanceDescription())
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Security")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SSL Validation Mode")
                            .font(.headline)
                        
                        Picker("SSL Validation Mode", selection: Binding(
                            get: { self.sslManager.currentMode },
                            set: { newValue in
                                if newValue == .disabled {
                                    showSSLWarning = true
                                } else {
                                    self.sslManager.setMode(newValue)
                                }
                            }
                        )) {
                            ForEach(SSLValidationMode.allCases, id: \.self) { mode in
                                HStack {
                                    Text(sslManager.descriptionForMode(mode))
                                    if mode == .disabled {
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundColor(.orange)
                                    }
                                }
                                .tag(mode)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        Text(sslManager.descriptionForMode(sslManager.currentMode))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                            .foregroundColor(.secondary)
                    }
                }
                
                #if DEBUG
                Section(header: Text("Development")) {
                    Button("Reset API Call Count") {
                        APIService.resetAPICallCount()
                    }
                    .foregroundColor(primaryColor)
                }
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(primaryColor)
                    }
                }
            }
            .alert(isPresented: $showSSLWarning) {
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
    
    // Helper to get the description text for appearance settings
    private func getAppearanceDescription() -> String {
        if !useAutomaticModeSwitch {
            return "App will stay in \(isDarkMode ? "dark" : "light") mode until you change it."
        } else if keepManualModeSettings {
            return "App will stay in \(isDarkMode ? "dark" : "light") mode until you change it."
        } else {
            return "App will automatically switch to dark mode at night (6 PM - 6 AM) and light mode during the day. Manual settings are kept for 12 hours."
        }
    }
}

#Preview {
    SettingsScreen()
} 