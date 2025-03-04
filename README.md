# DeepSpaceDaily

A modern SwiftUI application that provides the latest news and information about space exploration, missions, and discoveries. Built with a clean architecture approach, this app showcases best practices in iOS development.

![DeepSpaceDaily App](https://github.com/jekdev-ios/DeepSpaceDaily/raw/main/screenshots/app_preview.png)

## Features

- **Latest Space News**: Browse articles, blogs, and reports from various space news sources
- **Content Categories**: Explore different types of content (articles, blogs, reports)
- **Search Functionality**: Find specific space-related content
- **Offline Support**: Access previously loaded content when offline
- **Dark Mode**: Automatic time-based switching between light and dark modes
- **SSL Configuration**: Multiple security levels for different environments
- **Authentication**: User authentication with Auth0
- **Responsive UI**: Beautiful and responsive interface built with SwiftUI

## Architecture

DeepSpaceDaily follows a clean architecture approach with clear separation of concerns:

### Layers

- **Presentation Layer**: SwiftUI views, view models, and UI components
- **Domain Layer**: Business logic, use cases, and entity models
- **Data Layer**: Repositories, data sources, and data models

### Key Components

- **Core**: Dependency injection, error handling, and utilities
- **Data**: Repositories, storage, models, and data sources
- **Domain**: Entities, use cases, and repository interfaces
- **Presentation**: Screens, components, and view models

## Technical Details

### Networking

- Combine-based API service with error handling
- Support for request batching to optimize network usage
- Response caching to reduce API calls
- SSL pinning for enhanced security

### Storage

- Multi-level caching strategy (in-memory and persistent)
- `UserDefaultsAdapter` for simple data persistence
- `StorageWrapper` for metadata-enhanced storage
- Comprehensive error handling with `StorageError` types

### Dependency Injection

- Swinject-based dependency container
- Protocol-oriented design for testability
- Mock implementations for testing

### UI/UX

- Dark mode with smart time-based switching
- Custom UI components for consistent design
- Lazy loading of images for performance
- Responsive layouts for different device sizes

## Building the Project

### Auth0 Configuration

To use the authentication features, you need to set up Auth0:

1. Copy the `DeepSpaceDaily/Configuration/Auth0.plist.example` file to `DeepSpaceDaily/Configuration/Auth0.plist`
2. Replace the placeholder values with your Auth0 credentials:
   - `Domain`: Your Auth0 tenant domain
   - `ClientId`: Your Auth0 application client ID
   - `ClientSecret`: Your Auth0 application client secret

> Note: The `Auth0.plist` file is excluded from version control to protect sensitive credentials.

### Using the Build Script

The project includes a build script that simplifies the build process:

```bash
./build.sh
```

### Using Make

The project also includes a Makefile for easier build management:

```bash
# Build the project
make build

# Clean the build directory
make clean

# Build and run in the simulator
make run

# Show available commands
make help
```

### Manual Build

Alternatively, you can build the project manually:

```bash
xcodebuild -scheme DeepSpaceDaily -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15' -verbose
```

## SSL Configuration

The application includes an SSL configuration system with different validation modes:

- **Strict**: Uses certificate pinning for maximum security
- **Standard**: Uses the system's trust store for certificate validation
- **Disabled**: Bypasses SSL validation (for development/testing only)

These settings can be configured through the Settings screen in the application.

## Dark Mode

The app features a smart dark mode system:

- Automatically switches between light and dark mode based on time of day
- Remembers user preferences for 12 hours when manually set
- Settings to keep manual mode indefinitely or disable automatic switching

## Contributing

We welcome contributions to DeepSpaceDaily! Here's how you can help:

### Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR-USERNAME/DeepSpaceDaily.git`
3. Create a feature branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Test your changes thoroughly
6. Commit your changes with meaningful commit messages
7. Push to your branch: `git push origin feature/your-feature-name`
8. Create a pull request

### Coding Guidelines

- Follow Swift style guidelines
- Write clean, maintainable code
- Include comments for complex logic
- Write unit tests for new features
- Update documentation as needed

### Reporting Issues

If you find a bug or have a feature request, please create an issue on GitHub with:

- A clear description of the issue or feature
- Steps to reproduce (for bugs)
- Expected behavior
- Screenshots if applicable
- Any relevant code snippets

## Requirements

- iOS 16.0+
- Xcode 14.0+
- Swift 5.7+

## Dependencies

- **Swinject**: For dependency injection
- **Auth0**: For authentication
- **Combine**: For reactive programming
- **SwiftUI**: For the user interface

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [Spaceflight News API](https://spaceflightnewsapi.net/) for providing the space news data
- [Auth0](https://auth0.com/) for authentication services 