// lib/shared/services/api_service.dart - MINIMAL CHANGE
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  // ONLY CHANGE THIS LINE - Point to your Go backend
  static const String baseUrl = 'http://localhost:8080/api/v1';
  // For production: 'https://your-go-backend-domain.com/api/v1'
  
  static const Duration timeoutDuration = Duration(seconds: 30);
  
  // Everything else remains exactly the same
  static Future<Map<String, String>> _getAuthHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    final token = await user.getIdToken();
    
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
  
  // All other methods remain unchanged...
  static Future<dynamic> get(String endpoint, {bool requireAuth = true}) async {
    final headers = requireAuth ? await _getAuthHeaders() : {'Content-Type': 'application/json'};
    
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    ).timeout(timeoutDuration);
    
    return _handleResponse(response);
  }
  
  static Future<dynamic> post(String endpoint, {dynamic body, bool requireAuth = true}) async {
    final headers = requireAuth ? await _getAuthHeaders() : {'Content-Type': 'application/json'};
    
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? json.encode(body) : null,
    ).timeout(timeoutDuration);
    
    return _handleResponse(response);
  }
  
  static Future<dynamic> put(String endpoint, {dynamic body, bool requireAuth = true}) async {
    final headers = requireAuth ? await _getAuthHeaders() : {'Content-Type': 'application/json'};
    
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? json.encode(body) : null,
    ).timeout(timeoutDuration);
    
    return _handleResponse(response);
  }
  
  static Future<dynamic> delete(String endpoint, {bool requireAuth = true}) async {
    final headers = requireAuth ? await _getAuthHeaders() : {'Content-Type': 'application/json'};
    
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    ).timeout(timeoutDuration);
    
    return _handleResponse(response);
  }
  
  static Future<String> uploadFile(File file, String fileType) async {
    final headers = await _getAuthHeaders();
    headers.remove('Content-Type');
    
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
    request.headers.addAll(headers);
    
    request.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );
    request.fields['type'] = fileType;
    
    final streamedResponse = await request.send().timeout(Duration(minutes: 5));
    final response = await http.Response.fromStream(streamedResponse);
    
    final data = _handleResponse(response);
    return data['url'] as String;
  }
  
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else {
      final errorBody = response.body.isNotEmpty ? json.decode(response.body) : {};
      final errorMessage = errorBody['error'] ?? 'Unknown error occurred';
      throw ApiException(errorMessage, response.statusCode);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  
  ApiException(this.message, this.statusCode);
  
  @override
  String toString() => 'ApiException($statusCode): $message';
}