import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      receiveTimeout:
          const Duration(seconds: 60), // Increased for audio processing
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
      print('ApiService: Sending registration request with data: $userData');
      final response = await _dio.post(
        AppConstants.registerEndpoint,
        data: userData,
      );

      print('ApiService: Registration response status: ${response.statusCode}');
      print('ApiService: Registration response data: ${response.data}');

      final token = response.data['token'];
      if (token != null) {
        setToken(token);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, token);
      }

      return response.data;
    } on DioException catch (e) {
      print('ApiService: Registration DioException: $e');
      print('ApiService: Registration error response: ${e.response?.data}');
      throw _handleError(e);
    } catch (e) {
      print('ApiService: Registration unexpected error: $e');
      rethrow;
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

  Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> userData) async {
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
  Future<Map<String, dynamic>> uploadRecording(
      String filePath, String filename) async {
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

  Future<Map<String, dynamic>> getRecordings(
      {int page = 1, int limit = 10}) async {
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

  // Emergency Email API Methods
  Future<List<String>> getEmergencyEmails() async {
    try {
      final response = await _dio.get('/auth/emergency-emails');
      return List<String>.from(response.data['emergencyEmails'] ?? []);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateEmergencyEmails(List<String> emails) async {
    try {
      await _dio.put(
        '/auth/emergency-emails',
        data: {'emergencyEmails': emails},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    print(
        'ApiService: Handling error - Type: ${error.type}, Status: ${error.response?.statusCode}');
    print('ApiService: Error response data: ${error.response?.data}');

    if (error.response?.data != null) {
      // Try to extract error message from response
      try {
        if (error.response!.data is Map &&
            error.response!.data['error'] != null) {
          return error.response!.data['error'];
        } else if (error.response!.data is String) {
          return error.response!.data;
        }
      } catch (e) {
        print('ApiService: Error parsing error response: $e');
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.receiveTimeout:
        return 'Server is taking too long to respond.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to server. Please check your internet connection.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        switch (statusCode) {
          case 400:
            return 'Bad request. Please check your input.';
          case 401:
            return 'Authentication failed. Please check your credentials.';
          case 403:
            return 'Access denied. You do not have permission.';
          case 404:
            return 'Service not found. Please try again later.';
          case 500:
            return 'Internal server error. Please try again later.';
          case 503:
            return 'Service temporarily unavailable. Please try again later.';
          default:
            return 'Server error (${statusCode}). Please try again later.';
        }
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}
