import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../main.dart';

class DataPersistenceService {
  static DataPersistenceService? _instance;
  static DataPersistenceService get instance {
    _instance ??= DataPersistenceService._();
    return _instance!;
  }
  
  DataPersistenceService._();

  // Enhanced data persistence for union incharge details
  Future<void> saveUnionInchargeDetails({
    required String unionId,
    required String buildingName,
    required Map<String, dynamic> userDetails,
  }) async {
    try {
      print('🔄 Starting comprehensive save for union incharge $unionId');
      
      // Add metadata for tracking
      userDetails['last_saved'] = DateTime.now().toIso8601String();
      userDetails['save_version'] = '2.0';
      userDetails['union_id'] = unionId;
      userDetails['building_name'] = buildingName;
      
      // 1. Save to backend first
      bool backendSaved = false;
      try {
        await _saveToBackend(unionId, userDetails);
        backendSaved = true;
        print('✅ Union incharge details saved to backend');
      } catch (e) {
        print('⚠️ Backend save failed: $e');
      }
      
      // 2. Save to local storage with multiple keys for different access patterns
      await _saveToLocalStorage(unionId, buildingName, userDetails);
      
      // 3. Create resident-accessible cache
      await _createResidentCache(buildingName, userDetails);
      
      // 4. Create persistent backup
      await _createPersistentBackup(unionId, userDetails);
      
      print('✅ Comprehensive save completed for union incharge $unionId');
      
    } catch (e) {
      print('❌ Error in comprehensive save: $e');
      throw Exception('Failed to save union incharge details: $e');
    }
  }

  // Enhanced data loading for union incharge details
  Future<Map<String, dynamic>?> loadUnionInchargeDetails({
    required String unionId,
    required String buildingName,
  }) async {
    try {
      print('🔄 Starting comprehensive load for union incharge $unionId');
      
      Map<String, dynamic>? details;
      
      // 1. Try loading from backend first
      try {
        details = await _loadFromBackend(unionId);
        if (details != null) {
          print('✅ Loaded union incharge details from backend');
          // Cache locally for future use
          await _saveToLocalStorage(unionId, buildingName, details);
          return details;
        }
      } catch (e) {
        print('⚠️ Backend load failed: $e');
      }
      
      // 2. Try loading from local storage
      details = await _loadFromLocalStorage(unionId, buildingName);
      if (details != null) {
        print('✅ Loaded union incharge details from local storage');
        return details;
      }
      
      // 3. Try loading from persistent backup
      details = await _loadFromPersistentBackup(unionId);
      if (details != null) {
        print('✅ Loaded union incharge details from persistent backup');
        // Restore to main storage
        await _saveToLocalStorage(unionId, buildingName, details);
        return details;
      }
      
      print('❌ No union incharge details found for $unionId');
      return null;
      
    } catch (e) {
      print('❌ Error in comprehensive load: $e');
      throw Exception('Failed to load union incharge details: $e');
    }
  }

  // Save bank details with enhanced persistence
  Future<void> saveBankDetails({
    required String buildingName,
    required String unionId,
    required Map<String, dynamic> bankDetails,
  }) async {
    try {
      print('🔄 Starting comprehensive bank details save for building: $buildingName');
      
      // Add metadata
      bankDetails['last_saved'] = DateTime.now().toIso8601String();
      bankDetails['save_version'] = '2.0';
      bankDetails['union_id'] = unionId;
      bankDetails['building_name'] = buildingName;
      
      // 1. Save to backend
      try {
        await _saveBankDetailsToBackend(buildingName, bankDetails);
        print('✅ Bank details saved to backend');
      } catch (e) {
        print('⚠️ Backend bank save failed: $e');
      }
      
      // 2. Save to local storage with multiple key patterns
      await _saveBankDetailsToLocal(buildingName, bankDetails);
      
      // 3. Create persistent backup
      await _createBankDetailsPersistentBackup(buildingName, bankDetails);
      
      print('✅ Comprehensive bank details save completed');
      
    } catch (e) {
      print('❌ Error saving bank details: $e');
      throw Exception('Failed to save bank details: $e');
    }
  }

  // Load bank details with enhanced fallback
  Future<Map<String, dynamic>?> loadBankDetails({
    required String buildingName,
  }) async {
    try {
      print('🔄 Starting comprehensive bank details load for building: $buildingName');
      
      Map<String, dynamic>? details;
      
      // 1. Try loading from backend
      try {
        details = await _loadBankDetailsFromBackend(buildingName);
        if (details != null) {
          print('✅ Loaded bank details from backend');
          await _saveBankDetailsToLocal(buildingName, details);
          return details;
        }
      } catch (e) {
        print('⚠️ Backend bank load failed: $e');
      }
      
      // 2. Try loading from local storage
      details = await _loadBankDetailsFromLocal(buildingName);
      if (details != null) {
        print('✅ Loaded bank details from local storage');
        return details;
      }
      
      // 3. Try loading from persistent backup
      details = await _loadBankDetailsFromPersistentBackup(buildingName);
      if (details != null) {
        print('✅ Loaded bank details from persistent backup');
        await _saveBankDetailsToLocal(buildingName, details);
        return details;
      }
      
      print('❌ No bank details found for building: $buildingName');
      return null;
      
    } catch (e) {
      print('❌ Error loading bank details: $e');
      throw Exception('Failed to load bank details: $e');
    }
  }

  // Backend operations
  Future<void> _saveToBackend(String unionId, Map<String, dynamic> details) async {
    final response = await http.put(
      Uri.parse('${getBaseUrl()}/union/profile/$unionId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(details),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Backend save failed: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>?> _loadFromBackend(String unionId) async {
    final response = await http.get(
      Uri.parse('${getBaseUrl()}/union/profile/$unionId'),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['user'] ?? data;
    }
    return null;
  }

  Future<void> _saveBankDetailsToBackend(String buildingName, Map<String, dynamic> bankDetails) async {
    final encodedName = Uri.encodeComponent(buildingName);
    final response = await http.post(
      Uri.parse('${getBaseUrl()}/bank-details/$encodedName'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(bankDetails),
    );
    
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Backend bank save failed: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>?> _loadBankDetailsFromBackend(String buildingName) async {
    final encodedName = Uri.encodeComponent(buildingName);
    final response = await http.get(
      Uri.parse('${getBaseUrl()}/bank-details/$encodedName'),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // Local storage operations with multiple key patterns
  Future<void> _saveToLocalStorage(String unionId, String buildingName, Map<String, dynamic> details) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = jsonEncode(details);
    
    // Save with multiple keys for different access patterns
    final keys = [
      'union_incharge_$unionId',
      'union_incharge_building_$buildingName',
      'union_incharge_building_${buildingName.replaceAll(' ', '_').toLowerCase()}',
    ];
    
    for (final key in keys) {
      await prefs.setString(key, jsonData);
    }
    
    print('💾 Saved union incharge details to local storage with ${keys.length} keys');
  }

  Future<Map<String, dynamic>?> _loadFromLocalStorage(String unionId, String buildingName) async {
    final prefs = await SharedPreferences.getInstance();
    
    final keys = [
      'union_incharge_$unionId',
      'union_incharge_building_$buildingName',
      'union_incharge_building_${buildingName.replaceAll(' ', '_').toLowerCase()}',
    ];
    
    for (final key in keys) {
      final data = prefs.getString(key);
      if (data != null) {
        print('✅ Found union incharge data with key: $key');
        return jsonDecode(data);
      }
    }
    
    return null;
  }

  Future<void> _saveBankDetailsToLocal(String buildingName, Map<String, dynamic> bankDetails) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = jsonEncode(bankDetails);
    
    final cleanBuildingKey = buildingName.replaceAll(' ', '_').toLowerCase();
    final keys = [
      'bank_details_$cleanBuildingKey',
      'building_bank_details_$buildingName',
      'building_bank_name_$cleanBuildingKey',
      'building_iban_$cleanBuildingKey',
      'building_account_title_$cleanBuildingKey',
    ];
    
    // Save complete bank details
    for (final key in keys.take(2)) {
      await prefs.setString(key, jsonData);
    }
    
    // Save individual fields for backward compatibility
    await prefs.setString('building_bank_name_$cleanBuildingKey', bankDetails['bank_name'] ?? '');
    await prefs.setString('building_iban_$cleanBuildingKey', bankDetails['iban'] ?? bankDetails['account_number'] ?? '');
    await prefs.setString('building_account_title_$cleanBuildingKey', bankDetails['account_title'] ?? bankDetails['account_holder_name'] ?? '');
    
    print('💾 Saved bank details to local storage with ${keys.length} keys');
  }

  Future<Map<String, dynamic>?> _loadBankDetailsFromLocal(String buildingName) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanBuildingKey = buildingName.replaceAll(' ', '_').toLowerCase();
    
    // Try loading complete bank details first
    final keys = [
      'bank_details_$cleanBuildingKey',
      'building_bank_details_$buildingName',
    ];
    
    for (final key in keys) {
      final data = prefs.getString(key);
      if (data != null) {
        print('✅ Found bank details with key: $key');
        return jsonDecode(data);
      }
    }
    
    // Try loading individual fields for backward compatibility
    final bankName = prefs.getString('building_bank_name_$cleanBuildingKey');
    final iban = prefs.getString('building_iban_$cleanBuildingKey');
    final accountTitle = prefs.getString('building_account_title_$cleanBuildingKey');
    
    if (bankName != null || iban != null || accountTitle != null) {
      print('✅ Found bank details from individual fields');
      return {
        'bank_name': bankName ?? '',
        'iban': iban ?? '',
        'account_number': iban ?? '',
        'account_title': accountTitle ?? '',
        'account_holder_name': accountTitle ?? '',
        'building_name': buildingName,
      };
    }
    
    return null;
  }

  // Persistent backup operations
  Future<void> _createPersistentBackup(String unionId, Map<String, dynamic> details) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // Create timestamped backup
    await prefs.setString('backup_union_${unionId}_$timestamp', jsonEncode(details));
    
    // Create persistent backup that's less likely to be cleared
    await prefs.setString('persistent_union_$unionId', jsonEncode(details));
    
    print('🛡️ Created persistent backup for union incharge $unionId');
  }

  Future<Map<String, dynamic>?> _loadFromPersistentBackup(String unionId) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Try persistent backup first
    final persistentData = prefs.getString('persistent_union_$unionId');
    if (persistentData != null) {
      print('✅ Restored from persistent backup');
      return jsonDecode(persistentData);
    }
    
    // Try timestamped backups
    final allKeys = prefs.getKeys();
    final backupKeys = allKeys.where((key) => key.startsWith('backup_union_$unionId')).toList();
    
    if (backupKeys.isNotEmpty) {
      // Get the most recent backup
      backupKeys.sort();
      final recentBackup = backupKeys.last;
      final data = prefs.getString(recentBackup);
      if (data != null) {
        print('✅ Restored from timestamped backup: $recentBackup');
        return jsonDecode(data);
      }
    }
    
    return null;
  }

  Future<void> _createBankDetailsPersistentBackup(String buildingName, Map<String, dynamic> bankDetails) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanBuildingKey = buildingName.replaceAll(' ', '_').toLowerCase();
    
    // Create timestamped backup
    await prefs.setString('backup_bank_${cleanBuildingKey}_$timestamp', jsonEncode(bankDetails));
    
    // Create persistent backup
    await prefs.setString('persistent_bank_$cleanBuildingKey', jsonEncode(bankDetails));
    
    print('🛡️ Created persistent bank backup for building: $buildingName');
  }

  Future<Map<String, dynamic>?> _loadBankDetailsFromPersistentBackup(String buildingName) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanBuildingKey = buildingName.replaceAll(' ', '_').toLowerCase();
    
    // Try persistent backup first
    final persistentData = prefs.getString('persistent_bank_$cleanBuildingKey');
    if (persistentData != null) {
      print('✅ Restored bank details from persistent backup');
      return jsonDecode(persistentData);
    }
    
    // Try timestamped backups
    final allKeys = prefs.getKeys();
    final backupKeys = allKeys.where((key) => key.startsWith('backup_bank_$cleanBuildingKey')).toList();
    
    if (backupKeys.isNotEmpty) {
      backupKeys.sort();
      final recentBackup = backupKeys.last;
      final data = prefs.getString(recentBackup);
      if (data != null) {
        print('✅ Restored bank details from timestamped backup: $recentBackup');
        return jsonDecode(data);
      }
    }
    
    return null;
  }

  // Create resident-accessible cache
  Future<void> _createResidentCache(String buildingName, Map<String, dynamic> userDetails) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Create cache that residents can access
    final residentCacheKey = 'resident_cache_union_${buildingName.replaceAll(' ', '_').toLowerCase()}';
    await prefs.setString(residentCacheKey, jsonEncode(userDetails));
    
    print('👥 Created resident-accessible cache for building: $buildingName');
  }

  // Cleanup old backups (call periodically)
  Future<void> cleanupOldBackups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final now = DateTime.now().millisecondsSinceEpoch;
      final thirtyDaysAgo = now - (30 * 24 * 60 * 60 * 1000); // 30 days in ms
      
      final backupKeys = allKeys.where((key) => key.startsWith('backup_')).toList();
      int removedCount = 0;
      
      for (final key in backupKeys) {
        final parts = key.split('_');
        if (parts.length >= 3) {
          final timestampStr = parts.last;
          final timestamp = int.tryParse(timestampStr);
          if (timestamp != null && timestamp < thirtyDaysAgo) {
            await prefs.remove(key);
            removedCount++;
          }
        }
      }
      
      print('🧹 Cleaned up $removedCount old backup entries');
    } catch (e) {
      print('❌ Error cleaning up backups: $e');
    }
  }
} 