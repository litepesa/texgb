# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**WemaChat** is a Flutter-based social media application with video sharing, messaging, live streaming, and e-commerce features. Built with Firebase authentication, go_router navigation, and Riverpod state management.

**Tech Stack:**
- Flutter SDK 3.27.4 / Dart 3.6.2
- Firebase (Auth, Core)
- Riverpod 2.6.1 (with code generation)
- go_router 16.1.0
- WebSocket for real-time features
- Video caching service for optimized playback

## Essential Commands

### Development
```bash
# Install dependencies
flutter pub get

# Run code generation (Riverpod providers, Freezed models, JSON serialization)
dart run build_runner build --delete-conflicting-outputs

# Watch mode for code generation (recommended during development)
dart run build_runner watch --delete-conflicting-outputs

# Run the app
flutter run

# Run with specific device
flutter run -d <device-id>

# List connected devices
flutter devices
```

### Testing & Analysis
```bash
# Analyze code for issues
flutter analyze

# Run tests
flutter test

# Run specific test
flutter test test/path/to/test.dart
```

### Build
```bash
# Build APK (Android)
flutter build apk

# Build App Bundle (Android - for Play Store)
flutter build appbundle

# Build iOS (requires macOS)
flutter build ios
```

### Clean
```bash
# Clean build artifacts
flutter clean

# Full clean (includes pub cache)
flutter clean && flutter pub get
```

## Architecture

### Feature-Based Structure

The codebase follows a feature-first architecture where each feature contains:
- `models/` - Data models (often with Freezed/JSON serialization)
- `providers/` - Riverpod state management (with code generation - `.g.dart` files)
- `repositories/` - Data layer / API calls
- `screens/` - UI screens
- `widgets/` - Reusable UI components specific to feature
- `services/` - Business logic and utilities

**Key Features:**
- `authentication/` - Phone auth, OTP, profile setup
- `videos/` - Video feed, upload, playback, caching
- `chat/` - Direct messaging, video reactions
- `users/` - Profile management, verification
- `contacts/` - Contact management, blocking
- `wallet/` - Virtual currency, transactions
- `live_streaming/` - Live video broadcasts
- `threads/` - Discussion threads and series
- `shops/` - E-commerce functionality
- `calls/` - Video/voice calling

### Core Infrastructure

**Router (`lib/core/router/`)**
- `app_router.dart` - go_router configuration with authentication guards
- `route_paths.dart` - Route path constants and route names
- `route_guards.dart` - Authentication middleware

Navigation uses context extensions:
```dart
context.goToUserProfile(userId);
context.pushToVideo(videoId);
context.goToHome();
```

**Shared (`lib/shared/`)**
- `theme/` - Theme management with dark/light modes, system UI handling
- `services/` - WebSocket service for real-time updates
- `widgets/` - Global reusable widgets
- `utilities/` - Helper functions, datetime utilities, assets manager
- `providers/` - Global providers (websocket_provider)

### State Management Pattern

Uses **Riverpod with code generation**. Providers are annotated with `@riverpod` and generate `.g.dart` files.

**Example provider structure:**
```dart
// authentication_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'authentication_provider.g.dart';

@riverpod
class Authentication extends _$Authentication {
  // Implementation
}
```

**Important:** After creating/modifying providers, always run:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Video Architecture

**Video Caching System:**
- `VideoCacheService` (`features/videos/services/video_cache_service.dart`) - Initialized in `main.dart`
- Pre-caches video segments for smooth playback
- Configurable memory/storage limits
- Supports concurrent downloads

**Video State Management:**
- Videos loaded during app initialization for instant feed display
- `authenticationProvider` handles video state globally
- Liked videos and followed users cached for offline access

### Authentication Flow

1. **Landing Screen** → Login with phone number
2. **OTP Verification** → Firebase phone auth
3. **Profile Setup** → Create backend profile
4. **Home Screen** → Main app interface

**Auth States:**
- `guest` - Browse videos only
- `authenticated` - Full access (Firebase + backend profile)
- `partial` - Firebase authenticated but no backend profile
- `loading` / `error` - Transition states

**Route Guards:**
- Automatically redirect based on auth state
- Protected routes require authentication
- Guest routes accessible without login

### Real-Time Features

**WebSocket Integration:**
- `WebSocketService` (`lib/shared/services/websocket_service.dart`)
- Events: messages, typing indicators, presence, reactions
- Auto-reconnection with exponential backoff
- Message queue for offline support

**Supported Events:**
```dart
WebSocketEvent.messageReceived
WebSocketEvent.userTyping
WebSocketEvent.userOnline
WebSocketEvent.reactionAdded
// etc.
```

## Important Patterns

### Model Generation

Uses **Freezed** for immutable models with **json_serializable**:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'model_name.freezed.dart';
part 'model_name.g.dart';

@freezed
class MyModel with _$MyModel {
  factory MyModel({
    required String id,
    required String name,
  }) = _MyModel;

  factory MyModel.fromJson(Map<String, dynamic> json) => _$MyModelFromJson(json);
}
```

### Theme Access

Theme uses custom extensions:
```dart
final modernTheme = Theme.of(context).extension<ModernThemeExtension>();
final primaryColor = modernTheme?.primaryColor;
```

### Navigation Patterns

**Standard navigation:**
```dart
context.goToUserProfile(userId);  // Replace route
context.pushToVideo(videoId);      // Push modal
```

**Clear stack navigation (after login/logout):**
```dart
AppNavigation.goToHomeAndClearStack(context);
AppNavigation.goToLandingAndClearStack(context);
```

### Error Handling

Uses custom error widgets and global error handling in `NavigationErrorHandler`.

## Firebase Configuration

Firebase options are auto-generated in `lib/firebase_options.dart`. Do not edit manually.

**To update Firebase config:**
```bash
flutterfire configure
```

## Constants

- `lib/constants.dart` - Route names, colors, API endpoints
- `lib/constants/kenya_locations.dart` - Location data
- `lib/constants/kenya_languages.dart` - Language data
- `lib/constants/social_constants.dart` - Social media related constants

## Assets

Located in `assets/`:
- `images/` - Image assets
- `lottie/` - Lottie animations

Reference via `assets/images/filename.png` in code.

## Code Generation Files

Generated files (`.g.dart`, `.freezed.dart`) are:
- Committed to git
- Auto-generated by build_runner
- Should not be manually edited

**If you see import errors for `.g.dart` files, run code generation:**
```bash
dart run build_runner build --delete-conflicting-outputs
```

## Git Workflow

**Recent commits indicate work on:**
- Authentication screens (landing, login)
- Profile screens
- Home screen with tabs
- Shop features (new directory)

**Modified files in current branch:**
```
M features/authentication/screens/landing_screen.dart
M features/authentication/screens/login_screen.dart
M features/users/screens/my_profile_screen.dart
M main.dart
M main_screen/home_screen.dart
?? features/shops/
```

## Performance Considerations

- Use `const` constructors wherever possible
- Video thumbnails are cached via `video_thumbnail_service.dart`
- Images cached with `cached_network_image`
- Keep-alive wrappers used for tab persistence in `HomeScreen`
- Video caching initialized at app startup with 600MB memory / 2GB storage limits

## Dependencies Note

Using `dependency_overrides` for path package (1.8.3) - required for compatibility.

## Platform Support

Configured for:
- Android ✓
- iOS ✓
- Web ✓
- Windows ✓
- Linux ✓
- macOS ✓

(Primary focus: Mobile)
