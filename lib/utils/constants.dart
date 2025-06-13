// This file re-exports shared constants and utility functions used across the app

import 'package:flutter/material.dart' show Color;  // Import Color class
import '../../main.dart';

// Re-export the getBaseUrl function
export '../../main.dart' show getBaseUrl;

// App-wide configuration constants
const String APP_NAME = 'HomeConnect';
const String APP_VERSION = '1.0.0';

// API endpoints - reference to centralize endpoint URLs
class ApiEndpoints {
  static const String LOGIN = '/login';
  static const String SIGNUP = '/signup';
  static const String BANK_ACCOUNT = '/union/bank_account';
  static const String PENDING_PAYMENTS = '/union/pending_payments';
  static const String REVIEW_PAYMENT = '/union/review_payment/';
}

// UI-related constants
class AppColors {
  static const Color primaryColor = Color(0xFF673AB7); // Deep Purple
  static const Color accentColor = Color(0xFFFF9800);  // Orange
  static const Color errorColor = Color(0xFFF44336);   // Red
  static const Color successColor = Color(0xFF4CAF50); // Green
}

// Timeout durations
class AppTimeouts {
  static const Duration apiTimeout = Duration(seconds: 10);
  static const Duration splashDelay = Duration(seconds: 3);
} 