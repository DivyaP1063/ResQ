# ResQ Flutter Frontend - Emergency Detection Mobile App

## 🌟 Overview

The ResQ Flutter frontend is a cross-platform mobile application that provides emergency detection through audio monitoring. It offers native mobile features while connecting to the same backend API as the React web version.

## 🏗️ Architecture

### Technology Stack
- **Flutter 3.0+** with Dart
- **Provider** for state management
- **Dio** for HTTP requests
- **WebSocket Channel** for real-time communication
- **Flutter Sound** for audio recording
- **Permission Handler** for device permissions
- **Shared Preferences** for local storage

### Project Structure
```
lib/
├── main.dart              # Application entry point
├── models/                # Data models
│   ├── user.dart             # User model with JSON serialization
│   ├── recording.dart        # Audio recording model
│   └── emergency_analysis.dart # Emergency detection results
├── services/              # External service integrations
│   ├── api_service.dart      # Backend API communication
│   ├── websocket_service.dart # Real-time WebSocket handling
│   └── audio_service.dart    # Audio recording and permissions
├── providers/             # State management
│   ├── auth_provider.dart    # Authentication state
│   ├── recording_provider.dart # Recording management
│   └── websocket_provider.dart # WebSocket state
├── screens/               # Application screens
│   ├── splash_screen.dart    # App initialization screen
│   ├── auth/                 # Authentication screens
│   │   ├── login_screen.dart    # User login
│   │   └── register_screen.dart # User registration
│   ├── main_screen.dart      # Main navigation container
│   ├── home/                 # Home dashboard
│   │   └── home_screen.dart     # Dashboard with stats
│   ├── emergency/            # Emergency detection
│   │   └── emergency_screen.dart # Audio recording interface
│   └── profile/              # User profile
│       └── profile_screen.dart  # User settings and logout
├── widgets/               # Reusable UI components
│   ├── recording_card.dart   # Display individual recordings
│   ├── quick_stats_card.dart # Statistics display widget
│   ├── audio_visualizer.dart # Real-time audio visualization
│   └── recording_controls.dart # Recording control buttons
└── utils/                 # Utilities and constants
    ├── constants.dart        # App-wide constants
    └── theme.dart           # Custom theme configuration
```

## 🚀 Setup Instructions

### Prerequisites
- Flutter SDK (3.0+)
- Dart SDK (included with Flutter)
- Android Studio / Xcode for device testing
- ResQ backend server running

### 1. Install Flutter SDK
```bash
# Download Flutter from https://flutter.dev/docs/get-started/install
# Add Flutter to your PATH
flutter doctor  # Verify installation
```

### 2. Clone and Setup Project
```bash
cd flutter_frontend
flutter pub get  # Install dependencies
```

### 3. Configure Backend Connection
Edit `lib/utils/constants.dart`:
```dart
class AppConstants {
  static const String baseUrl = 'http://your-backend-url:5000';
  static const String wsUrl = 'ws://your-backend-url:5000';
  // For local development:
  // static const String baseUrl = 'http://10.0.2.2:5000'; // Android emulator
  // static const String baseUrl = 'http://localhost:5000'; // iOS simulator
}
```

### 4. Run the Application

#### For Development
```bash
# Web version (no device needed)
flutter run -d web

# Android device/emulator
flutter run -d android

# iOS device/simulator (macOS only)
flutter run -d ios
```

#### For Release
```bash
# Android APK
flutter build apk --release

# iOS (requires Xcode and developer account)
flutter build ios --release
```

## 🎯 Core Features

### 1. Authentication System
- **User Registration**: Create accounts with validation
- **Secure Login**: JWT token-based authentication
- **Persistent Sessions**: Remember user login state
- **Automatic Token Refresh**: Seamless session management

### 2. Cross-Platform Audio Recording
- **Native Audio Access**: Platform-specific audio APIs
- **Real-time Monitoring**: Continuous audio level detection
- **Permission Management**: Handle microphone permissions
- **Audio Format Handling**: Cross-platform audio compatibility

### 3. Emergency Detection
- **AI Integration**: Backend AssemblyAI processing
- **Real-time Analysis**: Immediate emergency detection
- **Visual Alerts**: Emergency modal with detailed information
- **WebSocket Notifications**: Real-time emergency broadcasts

### 4. Mobile-Optimized UI
- **Material Design**: Native Android feel
- **iOS Design**: Native iOS interface elements
- **Responsive Layout**: Adapts to different screen sizes
- **Touch-Friendly**: Optimized for mobile interactions

## 🧩 Component Details

### State Management with Provider

#### AuthProvider
Manages user authentication throughout the app:
```dart
class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;

  // Getters
  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;

  // Methods
  Future<void> login(String email, String password);
  Future<void> register(String name, String email, String phone, String password);
  Future<void> logout();
  Future<void> checkAuthStatus();
}
```

#### RecordingProvider
Handles audio recording and file management:
```dart
class RecordingProvider extends ChangeNotifier {
  List<Recording> _recordings = [];
  bool _isLoading = false;

  // Getters
  List<Recording> get recordings => _recordings;
  bool get isLoading => _isLoading;

  // Methods
  Future<void> fetchRecordings();
  Future<void> uploadRecording(String filePath);
  void addRecording(Recording recording);
}
```

#### WebSocketProvider
Manages real-time communication:
```dart
class WebSocketProvider extends ChangeNotifier {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  EmergencyAnalysis? _lastEmergencyAlert;

  // Getters
  bool get isConnected => _isConnected;
  EmergencyAnalysis? get lastEmergencyAlert => _lastEmergencyAlert;

  // Methods
  void connect();
  void disconnect();
  void sendMessage(Map<String, dynamic> message);
  void clearEmergencyAlert();
}
```

### Service Layer

#### ApiService
Handles all backend communication:
```dart
class ApiService {
  static const String baseUrl = AppConstants.baseUrl;
  late Dio _dio;

  // Authentication endpoints
  Future<Map<String, dynamic>> login(String email, String password);
  Future<Map<String, dynamic>> register(String name, String email, String phone, String password);
  Future<Map<String, dynamic>> getProfile(String token);

  // Recording endpoints
  Future<Map<String, dynamic>> uploadRecording(String token, String filePath);
  Future<List<Recording>> getRecordings(String token);
}
```

#### AudioService
Manages audio recording and permissions:
```dart
class AudioService {
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  String? _currentRecordingPath;

  // Permission and setup
  Future<bool> requestPermission();
  Future<void> initializeRecorder();

  // Recording controls
  Future<void> startRecording();
  Future<String?> stopRecording();
  Future<void> playRecording(String path);
}
```

### Screen Components

#### SplashScreen
App initialization and routing logic:
```dart
class SplashScreen extends StatefulWidget {
  // Features:
  // - App logo and branding
  // - Authentication status check
  // - Automatic navigation
  // - Loading animations
}
```

#### Emergency Screen
Main audio recording interface:
```dart
class EmergencyScreen extends StatefulWidget {
  // Features:
  // - Real-time audio visualization
  // - Recording controls
  // - Status indicators
  // - Emergency detection feedback
}
```

#### Home Screen
Dashboard with user statistics:
```dart
class HomeScreen extends StatefulWidget {
  // Features:
  // - User welcome message
  // - Recording statistics
  // - Recent recordings list
  // - Quick action buttons
}
```

## 🎨 UI/UX Design

### Theme Configuration
Custom theme with consistent branding:
```dart
class AppTheme {
  static const Color primaryColor = Color(0xFF2563EB);
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
  );

  static ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.blue,
    useMaterial3: true,
    // Custom theme configuration
  );
}
```

### Design Principles
- **Material Design**: Follow Google's design guidelines
- **Consistent Branding**: ResQ blue color scheme
- **Accessibility**: WCAG compliant components
- **Touch Targets**: Minimum 44px tap targets
- **Loading States**: Clear feedback for async operations

### Key UI Components

#### Audio Visualizer
Real-time visual feedback during recording:
```dart
class AudioVisualizer extends StatefulWidget {
  // Features:
  // - Animated waveform display
  // - Real-time audio level indication
  // - Smooth animations
  // - Color-coded intensity levels
}
```

#### Recording Controls
Intuitive recording interface:
```dart
class RecordingControls extends StatelessWidget {
  // Features:
  // - Large, accessible buttons
  // - Visual state feedback
  // - Pulse animations during recording
  // - Clear action labels
}
```

## 🔄 Application Flow

### 1. App Initialization Flow
```
App Launch →
Splash Screen →
Check Stored Auth Token →
If Valid: Navigate to Main Screen
If Invalid: Navigate to Login Screen
```

### 2. Authentication Flow
```
User Opens App →
Show Login Screen →
User Enters Credentials →
Validate with Backend →
Store JWT Token →
Connect WebSocket →
Navigate to Dashboard
```

### 3. Audio Recording Flow
```
User Taps Record Button →
Request Microphone Permission →
Initialize Audio Recorder →
Start Recording with Visual Feedback →
User Stops Recording →
Save Audio File →
Upload to Backend →
Display Processing Status →
Show Results (Emergency/Normal)
```

### 4. Emergency Detection Flow
```
Audio Analysis Complete →
Backend Detects Emergency →
WebSocket Alert Sent →
Show Emergency Modal →
Display Transcription & Details →
Provide Emergency Actions →
Log Emergency Event
```

## 📱 Platform-Specific Features

### Android
- **Material Design 3**: Latest design system
- **Native Audio API**: Android MediaRecorder
- **Background Processing**: Service-based recording
- **Notification Support**: Emergency alerts
- **File System Access**: Local storage management

### iOS
- **Human Interface Guidelines**: Native iOS feel
- **AVAudioRecorder**: iOS audio recording
- **Background Audio**: Continued recording capability
- **Push Notifications**: Emergency alerts
- **App Transport Security**: Secure network calls

### Web (Flutter Web)
- **Responsive Design**: Desktop and mobile web
- **WebRTC Integration**: Browser audio access
- **Progressive Web App**: Installable web app
- **Cross-Browser Support**: Chrome, Firefox, Safari

## 🔌 Backend Integration

### API Endpoints Used
```dart
// Authentication
POST /api/auth/register
POST /api/auth/login
GET /api/auth/profile

// Recordings
POST /api/recordings/upload
GET /api/recordings

// WebSocket
WS /api/websocket
```

### Data Models

#### User Model
```dart
class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final DateTime createdAt;

  // JSON serialization methods
  factory User.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

#### Recording Model
```dart
class Recording {
  final String id;
  final String userId;
  final String filename;
  final String? transcription;
  final EmergencyAnalysis? emergencyAnalysis;
  final DateTime createdAt;

  // JSON serialization methods
  factory Recording.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

#### Emergency Analysis Model
```dart
class EmergencyAnalysis {
  final bool isEmergency;
  final double confidence;
  final String description;
  final List<String> keywords;
  final String riskLevel;

  // JSON serialization methods
  factory EmergencyAnalysis.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

## 🔧 Configuration

### Dependencies (pubspec.yaml)
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1          # State management
  dio: ^5.3.2              # HTTP requests
  web_socket_channel: ^2.4.0 # WebSocket communication
  record: ^5.0.4           # Audio recording
  permission_handler: ^11.0.1 # Device permissions
  shared_preferences: ^2.2.2 # Local storage
  path_provider: ^2.1.1    # File system access

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0    # Code analysis
```

### Permissions

#### Android (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.INTERNET" />
```

#### iOS (ios/Runner/Info.plist)
```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record audio for emergency detection</string>
```

## 🧪 Testing

### Testing Strategy
```bash
# Unit tests
flutter test

# Widget tests
flutter test test/widget_test.dart

# Integration tests
flutter test integration_test/
```

### Test Structure
```
test/
├── unit/
│   ├── models/          # Model tests
│   ├── services/        # Service tests
│   └── providers/       # Provider tests
├── widget/              # Widget tests
└── integration/         # End-to-end tests
```

## 🚀 Deployment

### Android Deployment
```bash
# Generate keystore
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Build release APK
flutter build apk --release

# Build App Bundle for Play Store
flutter build appbundle --release
```

### iOS Deployment
```bash
# Build for iOS
flutter build ios --release

# Archive in Xcode for App Store
# Follow Xcode distribution process
```

### Web Deployment
```bash
# Build web version
flutter build web --release

# Deploy to hosting service
# (Vercel, Netlify, Firebase Hosting, etc.)
```

## 🔐 Security Considerations

### Security Measures
- **Token Storage**: Secure storage using FlutterSecureStorage
- **Network Security**: Certificate pinning for API calls
- **Audio Privacy**: Local audio processing before upload
- **Permission Handling**: Runtime permission requests
- **Data Encryption**: Encrypt sensitive local data

### Best Practices
```dart
// Secure token storage
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();
  
  static Future<void> storeToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }
  
  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }
}
```

## 🐛 Troubleshooting

### Common Issues

#### Audio Permission Denied
```dart
// Handle permission denial gracefully
Future<bool> requestAudioPermission() async {
  final status = await Permission.microphone.request();
  if (status.isDenied) {
    // Show instructions to user
    showPermissionDialog();
    return false;
  }
  return status.isGranted;
}
```

#### Network Connection Issues
```dart
// Implement retry logic with exponential backoff
Future<T> retryRequest<T>(Future<T> Function() request, {int maxRetries = 3}) async {
  int attempts = 0;
  while (attempts < maxRetries) {
    try {
      return await request();
    } catch (e) {
      attempts++;
      if (attempts >= maxRetries) rethrow;
      await Future.delayed(Duration(seconds: pow(2, attempts).toInt()));
    }
  }
  throw Exception('Max retries exceeded');
}
```

#### WebSocket Disconnection
```dart
// Auto-reconnection logic
void _handleWebSocketDisconnection() {
  Timer.periodic(Duration(seconds: 5), (timer) {
    if (!_isConnected) {
      _attemptReconnection();
    } else {
      timer.cancel();
    }
  });
}
```

## 📈 Performance Optimization

### Key Optimizations
- **Lazy Loading**: Load screens and data on demand
- **Image Optimization**: Compressed assets and caching
- **Memory Management**: Proper disposal of controllers
- **Network Efficiency**: Request batching and caching
- **Animation Performance**: 60fps animations with proper builders

### Performance Monitoring
```dart
// Monitor app performance
import 'package:flutter/foundation.dart';

void logPerformance(String operation, Function() action) {
  if (kDebugMode) {
    final stopwatch = Stopwatch()..start();
    action();
    stopwatch.stop();
    print('$operation took ${stopwatch.elapsedMilliseconds}ms');
  } else {
    action();
  }
}
```

## 📚 Additional Resources

### Learning Resources
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Guide](https://dart.dev/guides)
- [Provider State Management](https://pub.dev/packages/provider)
- [Material Design Guidelines](https://material.io/design)

### Development Tools
- **Flutter Inspector**: UI debugging tool
- **Dart DevTools**: Performance profiling
- **Firebase Crashlytics**: Crash reporting
- **Firebase Analytics**: User behavior tracking

## 🔄 Updates and Maintenance

### Regular Maintenance Tasks
- Update Flutter SDK and dependencies
- Test on new device OS versions
- Monitor crash reports and fix issues
- Review and update security practices
- Optimize performance based on user feedback

### Version Management
```bash
# Check Flutter version
flutter --version

# Upgrade Flutter
flutter upgrade

# Update dependencies
flutter pub upgrade
```

This Flutter frontend provides a comprehensive, native mobile experience for the ResQ emergency detection system with cross-platform compatibility and robust real-time features.