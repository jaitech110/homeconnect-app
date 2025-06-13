import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ComplaintsService {
  static const String _cacheKey = 'cached_pending_issues_';
  
  static String getBaseUrl() {
    return 'http://localhost:5000';
  }

  /// Get the count of pending complaints/issues for a specific building
  static Future<int> getPendingIssuesCount(String? unionId, String? buildingName) async {
    if (unionId == null || buildingName == null || unionId.isEmpty || buildingName.isEmpty) {
      return 0;
    }

    try {
      // Try to fetch from backend API first
      final count = await _fetchFromAPI(unionId, buildingName);
      if (count >= 0) {
        // Cache the result for offline use
        await _cacheCount(buildingName, count);
        return count;
      }
    } catch (e) {
      print('🔄 Complaints API failed, falling back to cached data: $e');
    }

    // Fallback to cached data if API fails
    final cachedCount = await _getCachedCount(buildingName);
    return cachedCount;
  }

  /// Fetch pending complaints count from backend API
  static Future<int> _fetchFromAPI(String unionId, String buildingName) async {
    try {
      final baseUrl = getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/union/complaints/$unionId?building=${Uri.encodeComponent(buildingName)}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        // Count only pending complaints
        final pendingCount = data.where((complaint) => 
          complaint['status']?.toString().toLowerCase() == 'pending'
        ).length;
        
        print('📊 Fetched ${pendingCount} pending complaints for $buildingName from API');
        return pendingCount;
      } else {
        throw Exception('API returned status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Failed to fetch complaints from API: $e');
      return -1; // Indicate API failure
    }
  }

  /// Cache pending issues count locally
  static Future<void> _cacheCount(String buildingName, int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKey${buildingName.toLowerCase().replaceAll(' ', '_')}';
      await prefs.setInt(cacheKey, count);
      await prefs.setString('${cacheKey}_timestamp', DateTime.now().toIso8601String());
      print('💾 Cached pending issues count: $count for $buildingName');
    } catch (e) {
      print('❌ Failed to cache pending issues count: $e');
    }
  }

  /// Get cached pending issues count
  static Future<int> _getCachedCount(String buildingName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKey${buildingName.toLowerCase().replaceAll(' ', '_')}';
      final count = prefs.getInt(cacheKey) ?? 0;
      final timestamp = prefs.getString('${cacheKey}_timestamp');
      
      if (timestamp != null) {
        final cacheTime = DateTime.parse(timestamp);
        final age = DateTime.now().difference(cacheTime);
        print('📱 Using cached pending issues count: $count (${age.inMinutes} minutes old) for $buildingName');
      } else {
        print('📱 Using cached pending issues count: $count (no timestamp) for $buildingName');
      }
      
      return count;
    } catch (e) {
      print('❌ Failed to get cached pending issues count: $e');
      return 0;
    }
  }

  /// Update cached count (for when complaints are resolved/closed locally)
  static Future<void> updateCachedCount(String? buildingName, int newCount) async {
    if (buildingName == null || buildingName.isEmpty) return;
    
    await _cacheCount(buildingName, newCount);
    print('🔄 Updated cached pending issues count to $newCount for $buildingName');
  }

  /// Increment cached count (when a new complaint is submitted)
  static Future<void> incrementCount(String? buildingName) async {
    if (buildingName == null || buildingName.isEmpty) return;
    
    final currentCount = await _getCachedCount(buildingName);
    await updateCachedCount(buildingName, currentCount + 1);
  }

  /// Decrement cached count (when a complaint is resolved/closed)
  static Future<void> decrementCount(String? buildingName) async {
    if (buildingName == null || buildingName.isEmpty) return;
    
    final currentCount = await _getCachedCount(buildingName);
    final newCount = (currentCount - 1).clamp(0, double.infinity).toInt();
    await updateCachedCount(buildingName, newCount);
  }
} 