import 'package:flutter/foundation.dart';

// A simple in-memory token storage for the app
// In a real app, you'd want to use secure storage or at minimum SharedPreferences
class TokenUtility {
  static String? _authToken;
  
  // Store the token
  static void setToken(String token) {
    _authToken = token;
    debugPrint('🔐 Authentication token stored');
  }
  
  // Retrieve the token
  static String? getToken() {
    debugPrint('🔐 Retrieving authentication token: ${_authToken != null ? 'Token exists' : 'No token'}');
    return _authToken;
  }
  
  // Clear the token (for logout)
  static void clearToken() {
    _authToken = null;
    debugPrint('🔐 Authentication token cleared');
  }
} 