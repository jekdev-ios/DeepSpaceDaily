//
//  HomeScreen.swift
//  DeepSpaceDaily
//
//  Created by admin on 28/02/25.
//

import SwiftUI

struct HomeScreen: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedTab = 0
    @State private var showSettings = false
    @Environment(\.colorScheme) private var colorScheme
    
    // Dark mode settings
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("lastDarkModeToggleTime") private var lastDarkModeToggleTime: Double = 0
    @AppStorage("keepManualModeSettings") private var keepManualModeSettings = false
    @AppStorage("useAutomaticModeSwitch") private var useAutomaticModeSwitch = true
    @AppStorage("userHasSetMode") private var userHasSetMode = false
    
    // Timer for checking time-based mode switching
    @State private var modeCheckTimer: Timer? = nil
    
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
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Hero Section with User Greeting
                        heroSection
                        
                        // Featured Article Carousel
                        if let articles = viewModel.contentByType[.articles],
                           !articles.isEmpty,
                           articles.contains(where: { $0.featured ?? false }) {
                            featuredArticlesCarousel
                        }
                        
                        // Category Sections (vertical layout as in the image)
                        ForEach(ContentType.allCases, id: \.self) { type in
                            categorySection(type: type)
                        }
                        
                        // API Call Statistics
                        if viewModel.showAPIStats {
                            apiCallStatisticsView
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal)
                }
                .refreshable {
                    viewModel.loadArticles()
                }
                
                // API Stats Toggle Button
//                VStack {
//                    Spacer()
//                    HStack {
//                        Spacer()
//                        Button(action: viewModel.toggleAPIStats) {
//                            Image(systemName: viewModel.showAPIStats ? "network.badge.shield.half.filled" : "network")
//                                .font(.system(size: 20))
//                                .padding()
//                                .background(primaryColor)
//                                .foregroundColor(.white)
//                                .clipShape(Circle())
//                                .shadow(radius: 4)
//                        }
//                        .padding(.trailing, 16)
//                        .padding(.bottom, 16)
//                    }
//                }
            }
            .navigationTitle("Deep Space Daily")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        // Toggle dark mode
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isDarkMode.toggle()
                        }
                        // Record that user has manually set the mode
                        userHasSetMode = true
                        // Record the time of the toggle
                        lastDarkModeToggleTime = Date().timeIntervalSince1970
                        // Play haptic feedback
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    }) {
                        Image(systemName: isDarkMode ? "moon.stars.fill" : "sun.max.fill")
                            .font(.system(size: 16))
                            .foregroundColor(isDarkMode ? .yellow : primaryColor)
                            .symbolRenderingMode(.hierarchical)
                            .padding(6)
                            .background(
                                Circle()
                                    .fill(isDarkMode ? 
                                          Color.yellow.opacity(0.2) : 
                                          primaryColor.opacity(0.1))
                            )
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gear")
                            .foregroundColor(primaryColor)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SearchScreen()) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(primaryColor)
                    }
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .onAppear {
                viewModel.loadArticles()
                checkAndUpdateColorScheme()
                
                // Set up timer to check for automatic mode switching
                modeCheckTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
                    checkAndUpdateColorScheme()
                }
            }
            .onDisappear {
                // Clean up timer when view disappears
                modeCheckTimer?.invalidate()
                modeCheckTimer = nil
            }
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showSettings) {
                SettingsScreen()
            }
        }
    }
    
    // MARK: - Dark Mode Management
    
    /// Checks if the color scheme should be updated based on time and user preferences
    private func checkAndUpdateColorScheme() {
        // If automatic mode switching is disabled, respect the current setting
        guard useAutomaticModeSwitch else { return }
        
        // If user has manually set the mode and wants to keep it, respect that
        if userHasSetMode && keepManualModeSettings {
            return
        }
        
        // If user has manually set the mode within the last 12 hours, respect that
        let twelveHoursInSeconds: TimeInterval = 12 * 60 * 60
        let currentTime = Date().timeIntervalSince1970
        let timeSinceLastToggle = currentTime - lastDarkModeToggleTime
        
        if userHasSetMode && timeSinceLastToggle < twelveHoursInSeconds {
            return
        }
        
        // Otherwise, set mode based on time of day
        let hour = Calendar.current.component(.hour, from: Date())
        let shouldBeDarkMode = hour < 6 || hour >= 18 // Dark mode from 6 PM to 6 AM
        
        // Only update if the mode needs to change
        if isDarkMode != shouldBeDarkMode {
            withAnimation(.easeInOut(duration: 0.5)) {
                isDarkMode = shouldBeDarkMode
            }
            
            // If this was an automatic change, don't count it as user-set
            if userHasSetMode && timeSinceLastToggle >= twelveHoursInSeconds {
                userHasSetMode = false
            }
        }
    }
    
    // MARK: - UI Components
    
    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // User greeting
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.greeting)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(viewModel.authViewModel.currentUser.name)
                    .font(.title)
                    .fontWeight(.heavy)
                    .foregroundColor(primaryColor)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var featuredArticlesCarousel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Featured")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
            }
            .padding(.horizontal)
            
            TabView {
                if let articles = viewModel.contentByType[.articles] {
                    ForEach(articles.filter { $0.featured ?? false }.prefix(5)) { article in
                        NavigationLink(destination: ArticleDetailScreen(article: article)) {
                            FeaturedArticleCard(article: article)
                                .padding(.bottom, 20) // For pagination dots
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .frame(height: 240)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        }
    }
    
    private func categorySection(type: ContentType) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(type.displayName)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                NavigationLink(destination: ArticleListScreen(type: type)) {
                    Text("see more")
                        .font(.subheadline)
                        .foregroundColor(primaryColor)
                }
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    if let articles = viewModel.contentByType[type], !articles.isEmpty {
                        ForEach(articles.prefix(9)) { article in
                            NavigationLink(destination: ArticleDetailScreen(article: article)) {
                                CompactArticleCard(article: article)
                                    .frame(width: 160, height: 160)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    } else {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 12)
                                .fill(secondaryBackgroundColor)
                                .frame(width: 160, height: 160)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - API Call Statistics View
    
    private var apiCallStatisticsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("API Call Statistics")
                    .font(.headline)
                    .foregroundColor(primaryColor)
                
                Spacer()
                
                Button(action: viewModel.resetAPICallCount) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(primaryColor)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total API Calls:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.apiCallCount)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(primaryColor)
                }
                
                Spacer()
                
                // Visual indicator
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: min(CGFloat(viewModel.apiCallCount) / 100.0, 1.0))
                        .stroke(primaryColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(min(viewModel.apiCallCount * 100 / 100, 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .background(secondaryBackgroundColor)
        .cornerRadius(12)
    }
}

// MARK: - HomeScreenToolbar
struct HomeScreenToolbar: ToolbarContent {
    let primaryColor: Color
    let secondaryBackgroundColor: Color
    let viewModel: HomeViewModel
    @Binding var showError: Bool
    @Binding var errorMessage: String
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            HStack(spacing: 4) {
                Image(systemName: "globe")
                    .font(.title3)
                    .foregroundColor(primaryColor)
                
                Text("DeepSpace")
                    .font(.headline)
                    .foregroundColor(primaryColor)
                
                Text("Daily")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            NavigationLink(destination: SearchScreen()) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(8)
                    .background(secondaryBackgroundColor)
                    .clipShape(Circle())
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            if viewModel.authViewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else if viewModel.authViewModel.isAuthenticated {
                Menu {
                    Button(action: {
                        Task {
                            await viewModel.authViewModel.logout()
                        }
                    }) {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(primaryColor)
                        .padding(8)
                        .background(secondaryBackgroundColor)
                        .clipShape(Circle())
                }
            } else {
                Button(action: {
                    Task {
                        do {
                            let success = try await viewModel.authViewModel.login()
                            if !success {
                                await MainActor.run {
                                    errorMessage = "Login failed"
                                    showError = true
                                }
                            }
                        } catch {
                            await MainActor.run {
                                errorMessage = error.localizedDescription
                                showError = true
                            }
                        }
                    }
                }) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(secondaryBackgroundColor)
                        .clipShape(Circle())
                }
            }
        }
    }
} 
