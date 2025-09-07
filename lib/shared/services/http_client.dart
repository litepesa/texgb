// lib/shared/services/http_client.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class HttpClientService {
  // Updated base URL to work with Android emulator
  static String get _baseUrl {
    if (kDebugMode) {
      // For development - check if we can reach localhost first
      // If not, fall back to production server
      return 'http://144.126.252.66:8080/api/v1'; // Use production for now
      
      // Alternative: Use localhost only for iOS simulator
      // if (Platform.isIOS) {
      //   return 'http://localhost:8080/api/v1';
      // } else {
      //   return 'http://64.227.142.38:8080/api/v1';
      // }
    } else {
      return 'http://144.126.252.66:8080/api/v1';
    }
  }
  
  static const Duration _timeout = Duration(seconds: 300);

  // Singleton pattern
  static final HttpClientService _instance = HttpClientService._internal();
  factory HttpClientService() => _instance;
  HttpClientService._internal();

  // Get Firebase ID token for authentication
  Future<String?> _getAuthToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        debugPrint('Auth token retrieved: ${token?.substring(0, 20)}...');
        return token;
      } else {
        debugPrint('No authenticated user found');
      }
    } catch (e) {
      debugPrint('Failed to get auth token: $e');
    }
    return null;
  }

  // Get default headers with authentication
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
      debugPrint('Authorization header added');
    } else {
      debugPrint('No auth token available - request will be unauthenticated');
    }
    
    return headers;
  }

  // Test connection to the Go backend
  Future<bool> testConnection() async {
    try {
      final baseUrlWithoutApi = _baseUrl.replaceAll('/api/v1', '');
      debugPrint('Testing connection to: $baseUrlWithoutApi/health');
      
      final response = await http.get(
        Uri.parse('$baseUrlWithoutApi/health')
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Backend health check: ${data.toString()}');
        return data['status'] == 'healthy';
      }
      debugPrint('Health check failed with status: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('Connection test failed: $e');
      return false;
    }
  }

  // GET request
  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders();

    try {
      debugPrint('GET: $url');
      debugPrint('Headers: $headers');
      final response = await http.get(url, headers: headers).timeout(_timeout);
      debugPrint('Response: ${response.statusCode} - ${response.body}');
      return response;
    } catch (e) {
      debugPrint('GET request failed: $e');
      throw HttpException('GET request failed: $e');
    }
  }

  // POST request
  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders();

    try {
      debugPrint('POST: $url');
      debugPrint('Headers: $headers');
      if (body != null) debugPrint('Body: ${jsonEncode(body)}');
      
      final response = await http.post(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(_timeout);
      
      debugPrint('Response: ${response.statusCode} - ${response.body}');
      return response;
    } catch (e) {
      debugPrint('POST request failed: $e');
      throw HttpException('POST request failed: $e');
    }
  }

  // PUT request
  Future<http.Response> put(String endpoint, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders();

    try {
      debugPrint('PUT: $url');
      debugPrint('Headers: $headers');
      final response = await http.put(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(_timeout);
      debugPrint('Response: ${response.statusCode} - ${response.body}');
      return response;
    } catch (e) {
      debugPrint('PUT request failed: $e');
      throw HttpException('PUT request failed: $e');
    }
  }

  // DELETE request
  Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders();

    try {
      debugPrint('DELETE: $url');
      debugPrint('Headers: $headers');
      final response = await http.delete(url, headers: headers).timeout(_timeout);
      debugPrint('Response: ${response.statusCode} - ${response.body}');
      return response;
    } catch (e) {
      debugPrint('DELETE request failed: $e');
      throw HttpException('DELETE request failed: $e');
    }
  }

  // Multipart request for file uploads
  Future<http.Response> uploadFile(
    String endpoint,
    File file,
    String fieldName, {
    Map<String, String>? additionalFields,
  }) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final token = await _getAuthToken();

    try {
      debugPrint('UPLOAD: $url');
      final request = http.MultipartRequest('POST', url);
      
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
        debugPrint('Authorization header added to upload request');
      }

      // Add file
      final multipartFile = await http.MultipartFile.fromPath(fieldName, file.path);
      request.files.add(multipartFile);

      // Add additional fields
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      debugPrint('Upload response: ${response.statusCode} - ${response.body}');
      return response;
    } catch (e) {
      debugPrint('File upload failed: $e');
      throw HttpException('File upload failed: $e');
    }
  }

  // Handle API response and extract data
  T handleResponse<T>(http.Response response, T Function(Map<String, dynamic>) fromJson) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return fromJson(data);
    } else {
      _throwHttpException(response);
      throw const HttpException('Response handling failed'); // This will never execute but satisfies return type
    }
  }

  // Handle API response for lists
  List<T> handleListResponse<T>(http.Response response, T Function(Map<String, dynamic>) fromJson) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => fromJson(item as Map<String, dynamic>)).toList();
    } else {
      _throwHttpException(response);
      return <T>[]; // This will never execute but satisfies return type
    }
  }

  // Handle simple success response
  void handleSimpleResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwHttpException(response);
    }
  }

  // Throw appropriate exception based on response
  Never _throwHttpException(http.Response response) {
    String message = 'Unknown error occurred';
    
    try {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      message = errorData['error'] ?? errorData['message'] ?? message;
    } catch (e) {
      message = 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
    }

    debugPrint('HTTP Exception: ${response.statusCode} - $message');

    switch (response.statusCode) {
      case 400:
        throw BadRequestException(message);
      case 401:
        throw UnauthorizedException(message);
      case 403:
        throw ForbiddenException(message);
      case 404:
        throw NotFoundException(message);
      case 409:
        throw ConflictException(message);
      case 500:
        throw InternalServerException(message);
      default:
        throw HttpException('HTTP ${response.statusCode}: $message');
    }
  }
}

// Custom HTTP exceptions
class HttpException implements Exception {
  final String message;
  const HttpException(this.message);
  @override
  String toString() => 'HttpException: $message';
}

class BadRequestException extends HttpException {
  const BadRequestException(String message) : super(message);
  @override
  String toString() => 'BadRequestException: $message';
}

class UnauthorizedException extends HttpException {
  const UnauthorizedException(String message) : super(message);
  @override
  String toString() => 'UnauthorizedException: $message';
}

class ForbiddenException extends HttpException {
  const ForbiddenException(String message) : super(message);
  @override
  String toString() => 'ForbiddenException: $message';
}

class NotFoundException extends HttpException {
  const NotFoundException(String message) : super(message);
  @override
  String toString() => 'NotFoundException: $message';
}

class ConflictException extends HttpException {
  const ConflictException(String message) : super(message);
}

class InternalServerException extends HttpException {
  const InternalServerException(String message) : super(message);
  @override
  String toString() => 'InternalServerException: $message';
}