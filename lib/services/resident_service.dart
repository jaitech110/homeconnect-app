import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ResidentService {
  static const String _cacheKey = 'cached_resident_count_';
  
  static String getBaseUrl() {
    return 'http://localhost:5000';
  }

  /// Get the total count of approved residents for a specific building
  static Future<int> getApprovedResidentCount(String? buildingName) async {
    if (buildingName == null || buildingName.isEmpty) {
      return 0;
    }

    try {
      // Try to fetch from backend API first
      final count = await _fetchFromAPI(buildingName);
      if (count >= 0) {
        // Cache the result for offline use
        await _cacheCount(buildingName, count);
        return count;
      }
    } catch (e) {
      print('🔄 API failed, falling back to cached data: $e');
    }

    // Fallback to cached data if API fails
    final cachedCount = await _getCachedCount(buildingName);
    return cachedCount;
  }

  /// Fetch resident count from backend API
  static Future<int> _fetchFromAPI(String buildingName) async {
    try {
      final baseUrl = getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/union/approved-residents?building_name=${Uri.encodeComponent(buildingName)}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final count = data.length;
        print('📊 Fetched ${count} approved residents for $buildingName from API');
        return count;
      } else {
        throw Exception('API returned status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Failed to fetch from API: $e');
      return -1; // Indicate API failure
    }
  }

  /// Cache resident count locally
  static Future<void> _cacheCount(String buildingName, int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKey${buildingName.toLowerCase().replaceAll(' ', '_')}';
      await prefs.setInt(cacheKey, count);
      await prefs.setString('${cacheKey}_timestamp', DateTime.now().toIso8601String());
      print('💾 Cached resident count: $count for $buildingName');
    } catch (e) {
      print('❌ Failed to cache count: $e');
    }
  }

  /// Get cached resident count
  static Future<int> _getCachedCount(String buildingName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKey${buildingName.toLowerCase().replaceAll(' ', '_')}';
      final count = prefs.getInt(cacheKey) ?? 0;
      final timestamp = prefs.getString('${cacheKey}_timestamp');
      
      if (timestamp != null) {
        final cacheTime = DateTime.parse(timestamp);
        final age = DateTime.now().difference(cacheTime);
        print('📱 Using cached count: $count (${age.inMinutes} minutes old) for $buildingName');
      } else {
        print('📱 Using cached count: $count (no timestamp) for $buildingName');
      }
      
      return count;
    } catch (e) {
      print('❌ Failed to get cached count: $e');
      return 0;
    }
  }

  /// Update cached count (for when residents are approved/removed locally)
  static Future<void> updateCachedCount(String? buildingName, int newCount) async {
    if (buildingName == null || buildingName.isEmpty) return;
    
    await _cacheCount(buildingName, newCount);
    print('🔄 Updated cached resident count to $newCount for $buildingName');
  }

  /// Increment cached count (when a resident is approved)
  static Future<void> incrementCount(String? buildingName) async {
    if (buildingName == null || buildingName.isEmpty) return;
    
    final currentCount = await _getCachedCount(buildingName);
    await updateCachedCount(buildingName, currentCount + 1);
  }

  /// Decrement cached count (when a resident is removed)
  static Future<void> decrementCount(String? buildingName) async {
    if (buildingName == null || buildingName.isEmpty) return;
    
    final currentCount = await _getCachedCount(buildingName);
    final newCount = (currentCount - 1).clamp(0, double.infinity).toInt();
    await updateCachedCount(buildingName, newCount);
  }
} 