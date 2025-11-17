class AppConstants {
  static const String appName = 'ResQ Emergency Detection';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String baseUrl =
      'https://resq-qbiz.onrender.com/api'; // Your local server IP on port 5000
  // For Android emulator, use: 'http://10.0.2.2:5000/api'
  // For localhost testing: 'http://localhost:5000/api'
  // Remote server: 'https://resq-qbiz.onrender.com/api'
  static const String wsUrl =
      'wss://resq-qbiz.onrender.com'; // Your local WebSocket IP on port 5000

  //   static const String baseUrl = 'https://resq-qbiz.onrender.com/api'; // Android emulator
  // // For physical device, use: 'http://YOUR_LOCAL_IP:5000/api'
  // static const String wsUrl = 'wss://resq-qbiz.onrender.com'; // WebSocket URL

  // Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String profileEndpoint = '/auth/profile';
  static const String uploadRecordingEndpoint = '/recordings/upload';
  static const String recordingsEndpoint = '/recordings';
  static const String emergencyRecordingsEndpoint = '/recordings/emergencies';

  // Storage Keys
  static const String tokenKey = 'resq_token';
  static const String userKey = 'resq_user';

  // Recording Settings
  static const int maxRecordingDuration = 30; // seconds
  static const int sampleRate = 44100;
  static const String audioFormat = 'wav';

  // Emergency Settings
  static const double emergencyThreshold = 0.6;
  static const List<String> emergencyKeywords = [
    'help',
    'emergency',
    'fire',
    'police',
    'ambulance',
    'accident',
    'attack',
    'danger',
    'urgent',
    'crisis'
  ];

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
}
