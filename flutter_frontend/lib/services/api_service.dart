import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../utils/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  String? _token;

  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60), // Increased for audio processing
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add request interceptor to include auth token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Token expired, clear it
          _clearToken();
        }
        handler.next(error);
      },
    ));
  }

  void setToken(String token) {
    _token = token;
  }

  void _clearToken() {
    _token = null;
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove(AppConstants.tokenKey);
    });
  }

  // Auth API Methods
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        AppConstants.loginEndpoint,
        data: {
          'email': email,
          'password': password,
        },
      );
      
      final token = response.data['token'];
      if (token != null) {
        setToken(token);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, token);
      }
      
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await _dio.post(
        AppConstants.registerEndpoint,
        data: userData,
      );
      
      final token = response.data['token'];
      if (token != null) {
        setToken(token);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, token);
      }
      
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get(AppConstants.profileEndpoint);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> userData) async {
    try {
      final response = await _dio.put(
        AppConstants.profileEndpoint,
        data: userData,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Recording API Methods
  Future<Map<String, dynamic>> uploadRecording(String filePath, String filename) async {
    try {
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(filePath, filename: filename),
      });

      final response = await _dio.post(
        AppConstants.uploadRecordingEndpoint,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
          // Extended timeout for audio processing
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 60),
        ),
      );

      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getRecordings({int page = 1, int limit = 10}) async {
    try {
      final response = await _dio.get(
        AppConstants.recordingsEndpoint,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getEmergencyRecordings() async {
    try {
      final response = await _dio.get(AppConstants.emergencyRecordingsEndpoint);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteRecording(String recordingId) async {
    try {
      await _dio.delete('${AppConstants.recordingsEndpoint}/$recordingId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    if (error.response?.data != null && error.response?.data['error'] != null) {
      return error.response!.data['error'];
    }
    
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.receiveTimeout:
        return 'Server is taking too long to respond.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to server. Please check your internet connection.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}