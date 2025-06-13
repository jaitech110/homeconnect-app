// API utilities for HomeConnect app
// This file provides centralized API configuration and utility functions

// Re-export the getBaseUrl function from main.dart
export '../../main.dart' show getBaseUrl;

// Additional API utility functions can be added here as needed
class ApiUtils {
  // Standard headers for API requests
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
  };

  // Common timeout duration for API requests
  static const Duration timeout = Duration(seconds: 10);
} 