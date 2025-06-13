import 'dart:convert';

class FirebaseConfig {
  static bool _initialized = false;
  
  // In-memory storage for CNIC images (base64 data)
  static final Map<String, String> _storedImages = {};
  
  // Firebase configuration - replace with your actual Firebase config
  static const Map<String, dynamic> firebaseConfig = {
    'apiKey': 'your-api-key',
    'authDomain': 'homeconnect-project.firebaseapp.com',
    'projectId': 'homeconnect-project',
    'storageBucket': 'homeconnect-project.appspot.com',
    'messagingSenderId': '123456789',
    'appId': '1:123456789:web:abcdef123456',
  };

  static Future<void> initialize() async {
    try {
      // For now, we'll simulate Firebase initialization
      // In a real implementation, you would initialize Firebase SDK here
      _initialized = true;
      print('🔥 Firebase configuration loaded (simulated)');
      print('⚠️ Using in-memory base64 storage for development');
    } catch (e) {
      print('❌ Firebase initialization failed: $e');
      print('⚠️ Falling back to in-memory storage');
      _initialized = false;
    }
  }

  static bool get isInitialized => _initialized;

  // Upload CNIC image as base64 data URL
  static Future<String> uploadCnicImage(String userId, String base64Data, String filename) async {
    try {
      // Store the base64 data in memory
      final imageKey = '${userId}_cnic';
      _storedImages[imageKey] = base64Data;
      
      // Determine the MIME type from the filename
      String mimeType = 'image/jpeg'; // default
      final extension = filename.split('.').last.toLowerCase();
      switch (extension) {
        case 'png':
          mimeType = 'image/png';
          break;
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
      }
      
      // Return a data URL that can be directly displayed
      final dataUrl = 'data:$mimeType;base64,$base64Data';
      
      print('🗄️ CNIC image stored as base64 data URL for user: $userId');
      return dataUrl;
      
    } catch (e) {
      print('❌ Error storing CNIC image: $e');
      throw Exception('Failed to store CNIC image');
    }
  }

  // Get stored CNIC image
  static String? getCnicImage(String userId) {
    final imageKey = '${userId}_cnic';
    final base64Data = _storedImages[imageKey];
    if (base64Data != null) {
      return 'data:image/jpeg;base64,$base64Data';
    }
    return null;
  }

  // Delete CNIC image from storage
  static Future<bool> deleteCnicImage(String userId) async {
    try {
      final imageKey = '${userId}_cnic';
      _storedImages.remove(imageKey);
      print('🗑️ CNIC image deleted for user: $userId');
      return true;
    } catch (e) {
      print('❌ CNIC image deletion failed: $e');
      return false;
    }
  }
} 