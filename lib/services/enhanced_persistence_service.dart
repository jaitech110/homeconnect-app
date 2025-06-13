import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enhanced persistence service to fix union incharge and bank details data loss
class EnhancedPersistenceService {
  static EnhancedPersistenceService? _instance;
  static EnhancedPersistenceService get instance {
    _instance ??= EnhancedPersistenceService._();
    return _instance!;
  }
  
  EnhancedPersistenceService._();

  /// Save union incharge details with multiple fallback strategies
  Future<bool> saveUnionInchargeDetails({
    required String unionId,
    required String buildingName,
    required Map<String, dynamic> userDetails,
  }) async {
    try {
      print('🔄 Enhanced save for union incharge $unionId, building: $buildingName');
      
      // Add tracking metadata
      userDetails['enhanced_save_timestamp'] = DateTime.now().toIso8601String();
      userDetails['union_id'] = unionId;
      userDetails['building_name'] = buildingName;
      
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(userDetails);
      
      // Strategy 1: Save with multiple key patterns
      final keys = [
        'enhanced_union_$unionId',
        'enhanced_union_building_$buildingName',
        'enhanced_union_building_${buildingName.replaceAll(' ', '_').toLowerCase()}',
        'persistent_union_$unionId',
        'backup_union_$unionId',
      ];
      
      bool allSaved = true;
      for (final key in keys) {
        final saved = await prefs.setString(key, jsonData);
        if (!saved) allSaved = false;
      }
      
      // Strategy 2: Save individual critical fields
      await prefs.setString('union_${unionId}_first_name', userDetails['first_name'] ?? '');
      await prefs.setString('union_${unionId}_last_name', userDetails['last_name'] ?? '');
      await prefs.setString('union_${unionId}_email', userDetails['email'] ?? '');
      await prefs.setString('union_${unionId}_phone', userDetails['phone'] ?? '');
      await prefs.setString('union_${unionId}_bank_name', userDetails['bank_name'] ?? '');
      await prefs.setString('union_${unionId}_account_number', userDetails['account_number'] ?? '');
      await prefs.setString('union_${unionId}_account_title', userDetails['account_title'] ?? '');
      
      // Strategy 3: Create building-specific resident cache
      final residentKeys = [
        'resident_access_union_${buildingName.replaceAll(' ', '_').toLowerCase()}',
        'union_for_building_$buildingName',
      ];
      
      for (final key in residentKeys) {
        await prefs.setString(key, jsonData);
      }
      
      print('✅ Enhanced save completed with ${keys.length + residentKeys.length} storage keys');
      return allSaved;
      
    } catch (e) {
      print('❌ Enhanced save failed: $e');
      return false;
    }
  }

  /// Load union incharge details with comprehensive fallback
  Future<Map<String, dynamic>?> loadUnionInchargeDetails({
    required String unionId,
    required String buildingName,
  }) async {
    try {
      print('🔄 Enhanced load for union incharge $unionId, building: $buildingName');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Strategy 1: Try all possible keys
      final keys = [
        'enhanced_union_$unionId',
        'enhanced_union_building_$buildingName',
        'enhanced_union_building_${buildingName.replaceAll(' ', '_').toLowerCase()}',
        'persistent_union_$unionId',
        'backup_union_$unionId',
        'union_incharge_$unionId',
        'union_incharge_building_$buildingName',
        'union_incharge_building_${buildingName.replaceAll(' ', '_').toLowerCase()}',
      ];
      
      for (final key in keys) {
        final data = prefs.getString(key);
        if (data != null && data.isNotEmpty) {
          try {
            final parsed = jsonDecode(data) as Map<String, dynamic>;
            print('✅ Loaded from key: $key');
            
            // Verify this is the correct union incharge
            if (parsed['union_id'] == unionId || parsed['building_name'] == buildingName) {
              return parsed;
            }
          } catch (e) {
            print('⚠️ Failed to parse data from key $key: $e');
          }
        }
      }
      
      // Strategy 2: Try to reconstruct from individual fields
      final firstName = prefs.getString('union_${unionId}_first_name');
      final lastName = prefs.getString('union_${unionId}_last_name');
      final email = prefs.getString('union_${unionId}_email');
      final phone = prefs.getString('union_${unionId}_phone');
      final bankName = prefs.getString('union_${unionId}_bank_name');
      final accountNumber = prefs.getString('union_${unionId}_account_number');
      final accountTitle = prefs.getString('union_${unionId}_account_title');
      
      if (firstName != null || lastName != null || email != null) {
        print('✅ Reconstructed from individual fields');
        final reconstructed = {
          'union_id': unionId,
          'building_name': buildingName,
          'first_name': firstName ?? '',
          'last_name': lastName ?? '',
          'email': email ?? '',
          'phone': phone ?? '',
          'bank_name': bankName ?? '',
          'account_number': accountNumber ?? '',
          'account_title': accountTitle ?? '',
          'reconstructed': true,
          'loaded_at': DateTime.now().toIso8601String(),
        };
        
        // Save the reconstructed data for future use
        await saveUnionInchargeDetails(
          unionId: unionId,
          buildingName: buildingName,
          userDetails: reconstructed,
        );
        
        return reconstructed;
      }
      
      print('❌ No union incharge data found for $unionId');
      return null;
      
    } catch (e) {
      print('❌ Enhanced load failed: $e');
      return null;
    }
  }

  /// Save bank details with enhanced persistence
  Future<bool> saveBankDetails({
    required String buildingName,
    required Map<String, dynamic> bankDetails,
  }) async {
    try {
      print('🔄 Enhanced bank save for building: $buildingName');
      
      // Add tracking metadata
      bankDetails['enhanced_save_timestamp'] = DateTime.now().toIso8601String();
      bankDetails['building_name'] = buildingName;
      
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(bankDetails);
      final cleanKey = buildingName.replaceAll(' ', '_').toLowerCase();
      
      // Strategy 1: Save with multiple comprehensive keys
      final keys = [
        'enhanced_bank_$cleanKey',
        'enhanced_bank_$buildingName',
        'persistent_bank_$cleanKey',
        'backup_bank_$cleanKey',
        'bank_details_$cleanKey',
        'building_bank_details_$buildingName',
      ];
      
      bool allSaved = true;
      for (final key in keys) {
        final saved = await prefs.setString(key, jsonData);
        if (!saved) allSaved = false;
      }
      
      // Strategy 2: Save individual fields for backward compatibility
      await prefs.setString('building_bank_name_$cleanKey', bankDetails['bank_name'] ?? '');
      await prefs.setString('building_iban_$cleanKey', bankDetails['iban'] ?? bankDetails['account_number'] ?? '');
      await prefs.setString('building_account_title_$cleanKey', bankDetails['account_title'] ?? bankDetails['account_holder_name'] ?? '');
      
      // Strategy 3: Create additional lookup keys
      await prefs.setString('bank_lookup_$buildingName', cleanKey);
      await prefs.setString('bank_timestamp_$cleanKey', DateTime.now().millisecondsSinceEpoch.toString());
      
      print('✅ Enhanced bank save completed with ${keys.length} storage keys');
      return allSaved;
      
    } catch (e) {
      print('❌ Enhanced bank save failed: $e');
      return false;
    }
  }

  /// Load bank details with comprehensive fallback
  Future<Map<String, dynamic>?> loadBankDetails({
    required String buildingName,
  }) async {
    try {
      print('🔄 Enhanced bank load for building: $buildingName');
      
      final prefs = await SharedPreferences.getInstance();
      final cleanKey = buildingName.replaceAll(' ', '_').toLowerCase();
      
      // Strategy 1: Try all possible complete keys
      final keys = [
        'enhanced_bank_$cleanKey',
        'enhanced_bank_$buildingName',
        'persistent_bank_$cleanKey',
        'backup_bank_$cleanKey',
        'bank_details_$cleanKey',
        'building_bank_details_$buildingName',
      ];
      
      for (final key in keys) {
        final data = prefs.getString(key);
        if (data != null && data.isNotEmpty) {
          try {
            final parsed = jsonDecode(data) as Map<String, dynamic>;
            print('✅ Loaded bank details from key: $key');
            return parsed;
          } catch (e) {
            print('⚠️ Failed to parse bank data from key $key: $e');
          }
        }
      }
      
      // Strategy 2: Try to reconstruct from individual fields
      final bankName = prefs.getString('building_bank_name_$cleanKey');
      final iban = prefs.getString('building_iban_$cleanKey');
      final accountTitle = prefs.getString('building_account_title_$cleanKey');
      
      if (bankName != null || iban != null || accountTitle != null) {
        print('✅ Reconstructed bank details from individual fields');
        final reconstructed = {
          'building_name': buildingName,
          'bank_name': bankName ?? '',
          'iban': iban ?? '',
          'account_number': iban ?? '',
          'account_title': accountTitle ?? '',
          'account_holder_name': accountTitle ?? '',
          'reconstructed': true,
          'loaded_at': DateTime.now().toIso8601String(),
        };
        
        // Save the reconstructed data
        await saveBankDetails(
          buildingName: buildingName,
          bankDetails: reconstructed,
        );
        
        return reconstructed;
      }
      
      print('❌ No bank details found for building: $buildingName');
      return null;
      
    } catch (e) {
      print('❌ Enhanced bank load failed: $e');
      return null;
    }
  }

  /// Get storage health report for debugging
  Future<Map<String, dynamic>> getStorageHealthReport() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      
      final enhancedKeys = allKeys.where((k) => k.startsWith('enhanced_')).toList();
      final persistentKeys = allKeys.where((k) => k.startsWith('persistent_')).toList();
      final backupKeys = allKeys.where((k) => k.startsWith('backup_')).toList();
      final bankKeys = allKeys.where((k) => k.contains('bank')).toList();
      final unionKeys = allKeys.where((k) => k.contains('union')).toList();
      
      return {
        'total_keys': allKeys.length,
        'enhanced_keys': enhancedKeys.length,
        'persistent_keys': persistentKeys.length,
        'backup_keys': backupKeys.length,
        'bank_keys': bankKeys.length,
        'union_keys': unionKeys.length,
        'timestamp': DateTime.now().toIso8601String(),
        'sample_enhanced_keys': enhancedKeys.take(5).toList(),
        'sample_bank_keys': bankKeys.take(5).toList(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
