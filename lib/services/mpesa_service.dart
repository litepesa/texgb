import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class MpesaService {
  // M-Pesa Sandbox URLs (change to production when ready)
  static const String _baseUrl = 'https://sandbox.safaricom.co.ke';
  static const String _tokenUrl = '$_baseUrl/oauth/v1/generate?grant_type=client_credentials';
  static const String _stkPushUrl = '$_baseUrl/mpesa/stkpush/v1/processrequest';
  static const String _queryUrl = '$_baseUrl/mpesa/stkpushquery/v1/query';
  
  // Your M-Pesa credentials (get these from Safaricom Developer Portal)
  static const String _consumerKey = 'YOUR_CONSUMER_KEY';
  static const String _consumerSecret = 'YOUR_CONSUMER_SECRET';
  static const String _businessShortCode = 'YOUR_BUSINESS_SHORTCODE';
  static const String _passkey = 'YOUR_PASSKEY';
  static const String _callbackUrl = 'YOUR_CALLBACK_URL'; // Your server callback URL
  
  // Generate access token
  Future<String?> getAccessToken() async {
    try {
      final credentials = base64Encode(utf8.encode('$_consumerKey:$_consumerSecret'));
      
      final response = await http.get(
        Uri.parse(_tokenUrl),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['access_token'];
      }
    } catch (e) {
      print('Error getting access token: $e');
    }
    return null;
  }
  
  // Generate password for STK Push
  String _generatePassword() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(0, 14);
    final password = base64Encode(utf8.encode('$_businessShortCode$_passkey$timestamp'));
    return password;
  }
  
  // Get timestamp
  String _getTimestamp() {
    return DateTime.now().millisecondsSinceEpoch.toString().substring(0, 14);
  }
  
  // Initiate STK Push
  Future<Map<String, dynamic>?> initiateSTKPush({
    required String phoneNumber,
    required double amount,
    required String accountReference,
    required String transactionDesc,
  }) async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken == null) return null;
      
      // Format phone number (remove leading 0 and add 254)
      String formattedPhone = phoneNumber;
      if (phoneNumber.startsWith('0')) {
        formattedPhone = '254${phoneNumber.substring(1)}';
      } else if (!phoneNumber.startsWith('254')) {
        formattedPhone = '254$phoneNumber';
      }
      
      final password = _generatePassword();
      final timestamp = _getTimestamp();
      
      final requestBody = {
        'BusinessShortCode': _businessShortCode,
        'Password': password,
        'Timestamp': timestamp,
        'TransactionType': 'CustomerPayBillOnline',
        'Amount': amount.toInt(),
        'PartyA': formattedPhone,
        'PartyB': _businessShortCode,
        'PhoneNumber': formattedPhone,
        'CallBackURL': _callbackUrl,
        'AccountReference': accountReference,
        'TransactionDesc': transactionDesc,
      };
      
      final response = await http.post(
        Uri.parse(_stkPushUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('STK Push failed: ${response.body}');
      }
    } catch (e) {
      print('Error initiating STK Push: $e');
    }
    return null;
  }
  
  // Query STK Push status
  Future<Map<String, dynamic>?> querySTKPushStatus({
    required String checkoutRequestId,
  }) async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken == null) return null;
      
      final password = _generatePassword();
      final timestamp = _getTimestamp();
      
      final requestBody = {
        'BusinessShortCode': _businessShortCode,
        'Password': password,
        'Timestamp': timestamp,
        'CheckoutRequestID': checkoutRequestId,
      };
      
      final response = await http.post(
        Uri.parse(_queryUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Error querying STK Push status: $e');
    }
    return null;
  }
}
