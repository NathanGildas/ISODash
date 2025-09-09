# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter application called "Project Monitor" that provides a monitoring dashboard for OpenProject instances. The app uses a CORS proxy server to connect to OpenProject APIs and displays project data, work packages, and analytics.

## Architecture

The application follows a standard Flutter architecture with Provider state management:

- **Models** (`lib/models/`): Data classes for API entities (Project)
- **Providers** (`lib/providers/`): State management using Provider pattern (ProjectProvider)
- **Services** (`lib/services/`): API communication layer (ApiService) 
- **Screens** (`lib/screens/`): UI screens (GuidedAuthScreen, DashboardScreen)
- **Proxy Server** (`lib/proxy_server.dart`): Standalone CORS proxy for OpenProject API

### Key Components

- **ApiService**: Handles all OpenProject API communication with Basic auth, supports projects, work packages, time entries, and versions endpoints
- **ProjectProvider**: Manages project state, loading, error handling with ChangeNotifier
- **CORS Proxy**: Standalone Dart server running on localhost:8080 that proxies requests to `https://forge2.ebindoo.com`

### Dependencies

- `provider: ^6.1.2` - State management
- `http: ^1.2.2` - HTTP requests  
- `fl_chart: ^0.68.0` - Charts and graphs
- `shared_preferences: ^2.3.2` - Local storage
- `url_launcher: ^6.2.1` - External links

## Common Development Commands

### Running the Application
```bash
# Install dependencies
flutter pub get

# Run the app in debug mode
flutter run

# Run on specific device
flutter run -d chrome
flutter run -d windows
```

### Building
```bash
# Build for web
flutter build web

# Build for Windows
flutter build windows

# Build APK for Android
flutter build apk
```

### Testing and Code Quality
```bash
# Run tests
flutter test

# Run static analysis
flutter analyze

# Format code
dart format .
```

### CORS Proxy Server
```bash
# Run the CORS proxy server (required for API access)
dart lib/proxy_server.dart
```

The proxy server must be running on localhost:8080 for the application to access the OpenProject API at `https://forge2.ebindoo.com`.

## Development Notes

- The app stores API credentials in SharedPreferences
- All API requests go through the CORS proxy server to avoid browser CORS restrictions
- French language is used in UI strings and comments
- The OpenProject API uses HAL+JSON format with `_embedded.elements` structure
- Error handling includes specific messages for authentication and network issues
- Uses Material Design 3 with blue primary color theme

## API Integration

The application integrates with OpenProject API v3 endpoints:
- `/projects` - List projects
- `/users/me` - Current user info  
- `/work_packages` - Work packages (tasks)
- `/time_entries` - Time tracking
- `/statuses` - Available statuses
- `/projects/{id}/versions` - Project versions/sprints

All API responses follow OpenProject's HAL+JSON format with data in `_embedded.elements`.