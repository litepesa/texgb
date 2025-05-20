// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:textgb/models/user_model.dart';

class ApiService {
  static const String baseUrl = 'https://your-api-domain.com/api';
  
  // Get Firebase ID token
  static Future<String?> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return await user.getIdToken();
  }
  
  // Verify token and check if user exists
  static Future<Map<String, dynamic>> verifyToken() async {
    final token = await _getIdToken();
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token}),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      // User not found, but token is valid
      final data = jsonDecode(response.body);
      return {'exists': false, 'status': data['status']};
    } else {
      throw Exception('Failed to verify token: ${response.body}');
    }
  }
  
  // Register new user
  static Future<UserModel> registerUser({
    required String name,
    required String aboutMe,
    File? imageFile,
  }) async {
    final token = await _getIdToken();
    
    // Create request body
    final Map<String, dynamic> body = {
      'token': token,
      'name': name,
      'about_me': aboutMe,
    };
    
    // Add image if provided
    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      body['image'] = base64Image;
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return UserModel.fromMap(data['data']);
    } else {
      throw Exception('Failed to register user: ${response.body}');
    }
  }
}