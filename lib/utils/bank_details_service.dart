import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class BankDetailsService {
  static const String _bankDetailsKeyPrefix = 'bank_details_';
  
  static BankDetailsService? _instance;
  static BankDetailsService get instance {
    _instance ??= BankDetailsService._();
    return _instance!;
  }
  
  BankDetailsService._();

  // Generate building-specific storage keys
  String _getBankDetailsKey(String buildingName) {
    return '$_bankDetailsKeyPrefix${buildingName.toLowerCase().replaceAll(' ', '_')}';
  }

  // Save bank details with building-specific storage
  Future<bool> saveBankDetails({
    required String bankName,
    required String accountTitle,
    required String accountNumber,
    required String branchName,
    required String iban,
    required String unionId,
    required String buildingName,
  }) async {
    try {
      if (kDebugMode) {
        print('BankDetailsService: Attempting to save bank details for building: $buildingName');
      }
      
      final bankDetails = {
        'bankName': bankName,
        'accountTitle': accountTitle,
        'accountNumber': accountNumber,
        'branchName': branchName,
        'iban': iban,
        'unionId': unionId,
        'buildingName': buildingName,
        'updatedAt': DateTime.now().toIso8601String(),
        'isDefault': false,
        'version': '1.0',
        'savedAt': DateTime.now().millisecondsSinceEpoch,
      };
      
      final jsonString = jsonEncode(bankDetails);
      final bankDetailsKey = _getBankDetailsKey(buildingName);
      
      if (kDebugMode) {
        print('BankDetailsService: Using SharedPreferences key: $bankDetailsKey');
        print('BankDetailsService: Saving data: $jsonString');
      }
      
      // Use SharedPreferences with building-specific key
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(bankDetailsKey);
      final success = await prefs.setString(bankDetailsKey, jsonString);
          
          if (kDebugMode) {
        print('BankDetailsService: SharedPreferences save success: $success for building: $buildingName');
      }
      
      // Verify the data was saved
      await Future.delayed(const Duration(milliseconds: 200));
      
      final verificationData = await getBankDetails(buildingName);
      final isVerified = verificationData != null && 
                        verificationData['bankName'] == bankName &&
                        verificationData['accountNumber'] == accountNumber;
      
      if (kDebugMode) {
        print('BankDetailsService: Data verification: $isVerified for building: $buildingName');
      }
      
      return isVerified && success;
    } catch (e) {
      if (kDebugMode) {
        print('BankDetailsService: Error saving bank details: $e');
      }
      throw Exception('Failed to save bank details: $e');
    }
  }

  // Get bank details with building-specific storage
  Future<Map<String, dynamic>?> getBankDetails(String buildingName) async {
    try {
      if (kDebugMode) {
        print('BankDetailsService: Attempting to load bank details for building: $buildingName');
      }
      
      final bankDetailsKey = _getBankDetailsKey(buildingName);
      
      Map<String, dynamic>? bankDetails;
      
      // Method 1: Try SharedPreferences first
      try {
        final prefs = await SharedPreferences.getInstance();
        final hasKey = prefs.containsKey(bankDetailsKey);
        
        if (kDebugMode) {
          print('BankDetailsService: SharedPreferences key exists: $hasKey for building: $buildingName');
        }
        
        if (hasKey) {
          final bankDetailsJson = prefs.getString(bankDetailsKey);
          
          if (kDebugMode) {
            print('BankDetailsService: SharedPreferences data for $buildingName: $bankDetailsJson');
          }
          
          if (bankDetailsJson != null && bankDetailsJson.isNotEmpty) {
            bankDetails = jsonDecode(bankDetailsJson) as Map<String, dynamic>;
            
            if (kDebugMode) {
              print('BankDetailsService: Successfully loaded from SharedPreferences for building: $buildingName');
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('BankDetailsService: SharedPreferences load failed: $e');
        }
      }
      
      if (bankDetails != null) {
        // Validate the data structure and ensure it matches the building
        if (bankDetails['bankName'] != null && 
            bankDetails['accountNumber'] != null && 
            bankDetails['buildingName'] == buildingName &&
            bankDetails['isDefault'] != true) {
          
          if (kDebugMode) {
            print('BankDetailsService: Loaded valid bank details for building: $buildingName');
            print('BankDetailsService: Bank: ${bankDetails['bankName']}');
            print('BankDetailsService: Updated: ${bankDetails['updatedAt']}');
          }
          
          return bankDetails;
        } else {
          if (kDebugMode) {
            print('BankDetailsService: Invalid bank details structure or building mismatch, removing corrupted data for building: $buildingName');
          }
          
          // Clear corrupted data for this building
          await clearBankDetails(buildingName);
          return null;
        }
      }
      
      if (kDebugMode) {
        print('BankDetailsService: No valid saved data found for building: $buildingName');
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('BankDetailsService: Error loading bank details: $e');
      }
      throw Exception('Failed to load bank details: $e');
    }
  }

  // Get bank details with default fallback for a specific building
  Future<Map<String, dynamic>> getBankDetailsWithDefault(String buildingName) async {
    try {
      final savedDetails = await getBankDetails(buildingName);
      
      if (savedDetails != null) {
        if (kDebugMode) {
          print('BankDetailsService: Returning saved details for building: $buildingName');
        }
        return savedDetails;
      }
      
      if (kDebugMode) {
        print('BankDetailsService: Returning default data for building: $buildingName');
      }
      
      return {
        'bankName': 'Union Bank',
        'accountTitle': 'Housing Society Union',
        'accountNumber': '1234567890123',
        'branchName': 'Main Branch',
        'iban': 'PK36SCBL0000001123456702',
        'unionId': 'default',
        'buildingName': buildingName,
        'updatedAt': DateTime.now().toIso8601String(),
        'isDefault': true,
        'version': '1.0',
      };
    } catch (e) {
      if (kDebugMode) {
        print('BankDetailsService: Error loading bank details with default: $e');
      }
      throw Exception('Failed to load bank details: $e');
    }
  }

  // Check if bank details exist for a specific building
  Future<bool> hasBankDetails(String buildingName) async {
    try {
      final data = await getBankDetails(buildingName);
      final exists = data != null && data['isDefault'] != true;
      
      if (kDebugMode) {
        print('BankDetailsService: Bank details exist for building $buildingName: $exists');
      }
      
      return exists;
    } catch (e) {
      if (kDebugMode) {
        print('BankDetailsService: Error checking bank details existence: $e');
      }
      return false;
    }
  }

  // Clear bank details for a specific building
  Future<bool> clearBankDetails(String buildingName) async {
    try {
      if (kDebugMode) {
        print('BankDetailsService: Clearing bank details for building: $buildingName');
      }
      
      final bankDetailsKey = _getBankDetailsKey(buildingName);
      
      // Clear SharedPreferences
        final prefs = await SharedPreferences.getInstance();
      final success = await prefs.remove(bankDetailsKey);
      
      if (kDebugMode) {
        print('BankDetailsService: Clear operation success for building $buildingName: $success');
      }
      
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('BankDetailsService: Error clearing bank details: $e');
      }
      throw Exception('Failed to clear bank details: $e');
    }
  }

  // Get all storage information for debugging
  Future<Map<String, dynamic>> getStorageInfo(String buildingName) async {
    final bankDetailsKey = _getBankDetailsKey(buildingName);
    
    Map<String, dynamic> info = {
      'platform': kIsWeb ? 'web' : 'native',
      'building': buildingName,
      'keys': {
        'sharedPrefs': bankDetailsKey,
      },
      'sharedPrefs': {},
    };
    
    try {
      // Check SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final hasKey = prefs.containsKey(bankDetailsKey);
      final data = prefs.getString(bankDetailsKey);
      
      info['sharedPrefs'] = {
        'allKeys': keys.toList(),
        'hasBankKey': hasKey,
        'data': data,
        'dataLength': data?.length ?? 0,
      };
      
    } catch (e) {
      info['error'] = e.toString();
    }
    
    if (kDebugMode) {
      print('BankDetailsService: Storage info for building $buildingName: $info');
    }
    
    return info;
  }

  // Reload SharedPreferences instance
  Future<void> reloadPreferences() async {
    try {
      if (kDebugMode) {
        print('BankDetailsService: Reloading SharedPreferences...');
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      
      if (kDebugMode) {
        print('BankDetailsService: SharedPreferences reloaded');
      }
    } catch (e) {
      if (kDebugMode) {
        print('BankDetailsService: Error reloading preferences: $e');
      }
    }
  }
} 