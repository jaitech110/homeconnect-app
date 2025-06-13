import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PaymentProofService {
  static PaymentProofService? _instance;
  static PaymentProofService get instance => _instance ??= PaymentProofService._internal();
  
  PaymentProofService._internal();

  // In-memory cache for payment proofs
  List<Map<String, dynamic>> _cachedProofs = [];
  List<Map<String, dynamic>> _cachedVerified = [];
  bool _initialized = false;

  Future<void> initialize() async {
    if (!_initialized) {
      print('🔧 Initializing PaymentProofService...');
      
      try {
        // Load payment proofs with retry mechanism
        int attempts = 0;
        while (attempts < 3) {
          attempts++;
          print('📂 Loading payment proofs (attempt $attempts/3)...');
          await _loadPaymentProofsFromStorage();
          
          // Verify we loaded something or this is the first run
          final prefs = await SharedPreferences.getInstance();
          final expectedCount = prefs.getInt('total_payment_count') ?? 0;
          
          if (_cachedProofs.length >= expectedCount || expectedCount == 0) {
            print('✅ Payment proofs loaded successfully');
            break;
          } else if (attempts < 3) {
            print('⚠️ Partial load detected, retrying...');
            await Future.delayed(Duration(milliseconds: 100));
          }
        }
        
        // Load verified payments with retry mechanism
        attempts = 0;
        while (attempts < 3) {
          attempts++;
          print('📂 Loading verified payments (attempt $attempts/3)...');
          await _loadVerifiedPaymentsFromStorage();
          break; // For now, don't retry verified payments
        }
        
        _initialized = true;
        
        print('✅ PaymentProofService initialized successfully');
        print('📊 Final state:');
        print('   • Payment proofs: ${_cachedProofs.length}');
        print('   • Verified payments: ${_cachedVerified.length}');
        
        // Debug: Show storage keys for troubleshooting
        final prefs = await SharedPreferences.getInstance();
        final allKeys = prefs.getKeys();
        final paymentKeys = allKeys.where((key) => 
          key.startsWith('payment_') || 
          key.startsWith('verified_') || 
          key.startsWith('total_') ||
          key.startsWith('last_') ||
          key.startsWith('individual_')
        ).toList();
        
        if (paymentKeys.isNotEmpty) {
          print('🔑 Payment-related storage keys found: ${paymentKeys.length}');
          for (final key in paymentKeys.take(5)) { // Show first 5 keys
            print('   • $key');
          }
          if (paymentKeys.length > 5) {
            print('   • ... and ${paymentKeys.length - 5} more');
          }
        } else {
          print('⚠️ No payment-related storage keys found - this might be the first run');
        }
        
      } catch (e) {
        print('❌ Error during PaymentProofService initialization: $e');
        _initialized = true; // Still mark as initialized to prevent infinite loops
      }
    } else {
      print('ℹ️ PaymentProofService already initialized (${_cachedProofs.length} proofs, ${_cachedVerified.length} verified)');
    }
  }

  // Upload payment proof
  Future<String> uploadPaymentProof({
    required String userId,
    required String userName,
    required String paymentType,
    required String amount,
    required String month,
    required String year,
    required String paymentFor,
    required Uint8List fileBytes,
    required String fileName,
    String? filePath,
    String? residentName,
    String? flatNumber,
    String? buildingName,
    String? unionId,
  }) async {
    try {
      await initialize();
      
      final paymentId = 'payment_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now().toIso8601String();
      
      // Map login userName to proper approved resident name with unique identification
      final properBuildingName = buildingName ?? 'Demo Building';
      final properFlatNumber = flatNumber ?? 'Unknown';
      final uniqueResidentInfo = await getUniqueResidentInfo(userId, userName, properBuildingName, properFlatNumber);
      
      print('👤 User ID: "$userId"');
      print('👤 Original userName: "$userName"');
      print('🔄 Unique resident info: ${uniqueResidentInfo['display_name']} (${uniqueResidentInfo['identifier']})');
      print('🏢 Building: "$properBuildingName"');
      print('🏠 Flat: "$properFlatNumber"');
      print('📝 Full resident name will be stored as: "${uniqueResidentInfo['display_name']}"');
      
      // Create payment proof data with unique resident identification
      final paymentProof = {
        'id': paymentId,
        'user_id': userId, // Keep original user ID for tracking
        'resident_name': uniqueResidentInfo['display_name'], // Display name for UI
        'resident_identifier': uniqueResidentInfo['identifier'], // Unique identifier
        'login_username': userName, // Original login name for reference
        'flat_number': properFlatNumber,
        'building_name': properBuildingName,
        'union_id': unionId ?? 'default_union',
        'payment_type': paymentType,
        'amount': amount,
        'month': month,
        'year': year,
        'payment_for': paymentFor,
        'upload_date': now,
        'status': 'pending',
        'admin_notes': '',
        'file_name': fileName,
        'file_size': fileBytes.length,
        'file_path': filePath,
        'image_data': base64Encode(fileBytes), // Store image as base64
        'hasRealFile': true,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      };

      // Add to cache
      _cachedProofs.add(paymentProof);
      
      // CRITICAL: Save immediately to prevent data loss
      print('🔒 Performing immediate save to prevent data loss...');
      await _savePaymentProofs();
      
      // Verify the save was successful
      await _validateDataPersistence();
      
      print('✅ Payment proof uploaded: $paymentId for resident: ${uniqueResidentInfo['display_name']} (${uniqueResidentInfo['identifier']}) in building: $properBuildingName');
      return paymentId;
      
    } catch (e) {
      print('❌ Error uploading payment proof: $e');
      rethrow;
    }
  }

  // Get all payment proofs
  Future<List<Map<String, dynamic>>> getAllPaymentProofs() async {
    await initialize();
    
    // Sort by upload date (newest first)
    final sortedProofs = List<Map<String, dynamic>>.from(_cachedProofs);
    sortedProofs.sort((a, b) {
      final dateA = DateTime.tryParse(a['upload_date'] ?? '') ?? DateTime.now();
      final dateB = DateTime.tryParse(b['upload_date'] ?? '') ?? DateTime.now();
      return dateB.compareTo(dateA);
    });
    
    print('📋 Retrieved ${sortedProofs.length} payment proofs');
    return sortedProofs;
  }

  // Get payment proofs by building
  Future<List<Map<String, dynamic>>> getPaymentProofsByBuilding(String buildingName) async {
    final allProofs = await getAllPaymentProofs();
    final filteredProofs = allProofs.where((proof) => 
      proof['building_name']?.toString().toLowerCase() == buildingName.toLowerCase()
    ).toList();
    
    print('🏢 Filtered ${filteredProofs.length} payment proofs for building: $buildingName');
    return filteredProofs;
  }

  // Get payment proofs by union ID
  Future<List<Map<String, dynamic>>> getPaymentProofsByUnionId(String unionId) async {
    final allProofs = await getAllPaymentProofs();
    final filteredProofs = allProofs.where((proof) => 
      proof['union_id']?.toString() == unionId
    ).toList();
    
    print('👥 Filtered ${filteredProofs.length} payment proofs for union ID: $unionId');
    return filteredProofs;
  }

  // Get payment proofs by building and union (most secure)
  Future<List<Map<String, dynamic>>> getPaymentProofsByBuildingAndUnion(String buildingName, String unionId) async {
    final allProofs = await getAllPaymentProofs();
    
    print('🔍 Filtering payment proofs:');
    print('   • Total proofs: ${allProofs.length}');
    print('   • Looking for building: "$buildingName"');
    print('   • Looking for union ID: "$unionId"');
    
    // Debug: Print all existing proofs to see what we have
    for (int i = 0; i < allProofs.length; i++) {
      final proof = allProofs[i];
      print('   • Proof ${i + 1}: building="${proof['building_name']}", union="${proof['union_id']}", resident="${proof['resident_name']}"');
    }
    
    final filteredProofs = allProofs.where((proof) {
      final proofBuilding = proof['building_name']?.toString().toLowerCase().trim();
      final proofUnion = proof['union_id']?.toString().trim();
      final targetBuilding = buildingName.toLowerCase().trim();
      final targetUnion = unionId.trim();
      
      final buildingMatch = proofBuilding == targetBuilding;
      final unionMatch = proofUnion == targetUnion;
      
      print('     - Checking proof: building match=$buildingMatch ("$proofBuilding" == "$targetBuilding"), union match=$unionMatch ("$proofUnion" == "$targetUnion")');
      
      return buildingMatch && unionMatch;
    }).toList();
    
    print('🔒 Filtered ${filteredProofs.length} payment proofs for building: $buildingName, union: $unionId');
    
    if (filteredProofs.isEmpty && allProofs.isNotEmpty) {
      print('⚠️ No matches found! This might indicate a data association problem.');
      print('💡 Trying fallback: filter by building name only...');
      
      // Fallback: try building name only
      final buildingOnlyProofs = allProofs.where((proof) => 
        proof['building_name']?.toString().toLowerCase().trim() == buildingName.toLowerCase().trim()
      ).toList();
      
      if (buildingOnlyProofs.isNotEmpty) {
        print('🏢 Found ${buildingOnlyProofs.length} proofs by building name only');
        return buildingOnlyProofs;
      } else {
        print('❌ No proofs found even by building name. Check if residents are uploading with correct building info.');
      }
    }
    
    return filteredProofs;
  }

  // Get payment proofs by user
  Future<List<Map<String, dynamic>>> getPaymentProofsByUser(String userId) async {
    final allProofs = await getAllPaymentProofs();
    return allProofs.where((proof) => proof['user_id'] == userId).toList();
  }

  // Update payment proof status
  Future<void> updatePaymentProofStatus(String paymentId, String status, {String? notes}) async {
    await initialize();
    
    try {
      // Update in cache
      final proofIndex = _cachedProofs.indexWhere((proof) => proof['id'] == paymentId);
      if (proofIndex != -1) {
        _cachedProofs[proofIndex]['status'] = status;
        _cachedProofs[proofIndex]['admin_notes'] = notes ?? '';
        _cachedProofs[proofIndex]['updated_date'] = DateTime.now().toIso8601String();
        
        // If verified, also add to verified list
        if (status.toLowerCase() == 'verified') {
          final verifiedPayment = Map<String, dynamic>.from(_cachedProofs[proofIndex]);
          verifiedPayment['verified_date'] = DateTime.now().toIso8601String();
          _cachedVerified.add(verifiedPayment);
          await _saveVerifiedPayments();
        }
        
        // CRITICAL: Save immediately after status update
        print('🔒 Performing immediate save after status update...');
        await _savePaymentProofs();
        
        // Verify the save was successful
        await _validateDataPersistence();
        
        print('✅ Updated payment proof $paymentId status to $status');
      } else {
        print('⚠️ Payment proof $paymentId not found');
      }
    } catch (e) {
      print('❌ Error updating payment proof status: $e');
      rethrow;
    }
  }

  // Get verified payments
  Future<List<Map<String, dynamic>>> getVerifiedPayments() async {
    await initialize();
    return List<Map<String, dynamic>>.from(_cachedVerified);
  }

  // Get approved payments (for union incharge resident records)
  Future<List<Map<String, dynamic>>> getApprovedPayments() async {
    await initialize();
    
    // Filter cached proofs for approved status
    final approvedProofs = _cachedProofs.where((proof) => 
      proof['status']?.toLowerCase() == 'approved'
    ).toList();
    
    // Sort by approval date (newest first)
    approvedProofs.sort((a, b) {
      final dateA = DateTime.tryParse(a['updated_date'] ?? a['upload_date'] ?? '') ?? DateTime.now();
      final dateB = DateTime.tryParse(b['updated_date'] ?? b['upload_date'] ?? '') ?? DateTime.now();
      return dateB.compareTo(dateA);
    });
    
    print('📋 Retrieved ${approvedProofs.length} approved payment records');
    return approvedProofs;
  }

  // Get approved resident names (simulating data from union incharge resident management)
  Future<List<String>> getApprovedResidentNames() async {
    await initialize();
    
    // For demo purposes, get unique resident names from payment proofs
    // In a real app, this would come from the approved residents database
    final allProofs = await getAllPaymentProofs();
    final residentNames = allProofs
        .map((proof) => proof['resident_name']?.toString() ?? '')
        .where((name) => name.isNotEmpty && name != 'Test Resident')
        .toSet()
        .toList();
    
    residentNames.sort(); // Sort alphabetically
    
    print('👥 Retrieved ${residentNames.length} approved resident names');
    return residentNames;
  }

  // Get approved residents with full details (simulating resident management data)
  Future<List<Map<String, dynamic>>> getApprovedResidents() async {
    await initialize();
    
    // For demo purposes, create approved residents based on unique payment proof submitters
    // In a real app, this would come from the resident management system
    final allProofs = await getAllPaymentProofs();
    final residentMap = <String, Map<String, dynamic>>{};
    
    for (final proof in allProofs) {
      final residentName = proof['resident_name']?.toString() ?? '';
      final flatNumber = proof['flat_number']?.toString() ?? '';
      final buildingName = proof['building_name']?.toString() ?? '';
      
      if (residentName.isNotEmpty && residentName != 'Test Resident') {
        final key = '${residentName}_${flatNumber}';
        
        if (!residentMap.containsKey(key)) {
          // Split name into first and last name for better display
          final nameParts = residentName.split(' ');
          final firstName = nameParts.isNotEmpty ? nameParts[0] : residentName;
          final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
          
          residentMap[key] = {
            'id': 'resident_${DateTime.now().millisecondsSinceEpoch}_${key.hashCode}',
            'first_name': firstName,
            'last_name': lastName,
            'full_name': residentName,
            'flat_number': flatNumber,
            'building_name': buildingName,
            'is_approved': true,
            'approval_date': DateTime.now().toIso8601String(),
          };
        }
      }
    }
    
    final approvedResidents = residentMap.values.toList();
    approvedResidents.sort((a, b) => a['full_name'].compareTo(b['full_name']));
    
    print('👥 Retrieved ${approvedResidents.length} approved residents with full details');
    return approvedResidents;
  }

  // Get approved resident names for dropdown (First Name Last Name format)
  Future<List<String>> getApprovedResidentNamesForDropdown() async {
    final approvedResidents = await getApprovedResidents();
    
    return approvedResidents.map((resident) {
      final firstName = resident['first_name']?.toString() ?? '';
      final lastName = resident['last_name']?.toString() ?? '';
      return lastName.isNotEmpty ? '$firstName $lastName' : firstName;
    }).toList();
  }

  // Get real approved residents from backend API (same as Manage Residents screen)
  Future<List<String>> getRealApprovedResidentNames(String buildingName) async {
    try {
      // Import getBaseUrl from main.dart for consistent server URL
      // Use dynamic import to avoid circular dependency
      String baseUrl;
      try {
        // Try to get the base URL from the main app
        baseUrl = 'http://localhost:5000'; // Default fallback
        // In a production app, you would import getBaseUrl from main.dart
      } catch (e) {
        baseUrl = 'http://localhost:5000'; // Fallback
      }
      
      print('🌐 Fetching approved residents from: $baseUrl');
      print('🏢 Building filter: $buildingName');
      
      final response = await http.get(
        Uri.parse('$baseUrl/union/approved-residents?building_name=$buildingName'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10)); // Add timeout

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final approvedResidents = data.cast<Map<String, dynamic>>();
        
        print('📊 Backend returned ${approvedResidents.length} approved residents');
        
        // Extract first name + last name for dropdown
        final residentNames = approvedResidents.map((resident) {
          final firstName = resident['first_name']?.toString() ?? '';
          final lastName = resident['last_name']?.toString() ?? '';
          final fullName = lastName.isNotEmpty ? '$firstName $lastName' : firstName;
          
          print('👤 Resident: $fullName (Building: ${resident['building_name']})');
          return fullName;
        }).where((name) => name.isNotEmpty).toList();
        
        residentNames.sort(); // Sort alphabetically
        
        print('✅ Retrieved ${residentNames.length} real approved residents from backend');
        return residentNames;
      } else {
        throw Exception('Failed to load approved residents: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
      print('❌ Error fetching real approved residents: $e');
      print('⚠️ Falling back to local data...');
      
      // Fallback to local data if backend is not available
      return await getApprovedResidentNamesForDropdown();
    }
  }

  // Get unique resident information to prevent name conflicts
  Future<Map<String, String>> getUniqueResidentInfo(String userId, String loginName, String buildingName, String flatNumber) async {
    try {
      // Get the real approved residents from backend
      String baseUrl = 'http://localhost:5000';
      
      final response = await http.get(
        Uri.parse('$baseUrl/union/approved-residents?building_name=$buildingName'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final approvedResidents = data.cast<Map<String, dynamic>>();
        
        print('🔍 Searching for unique resident match among ${approvedResidents.length} approved residents');
        
        // First, try to find exact match by user ID (most reliable)
        for (final resident in approvedResidents) {
          final residentUserId = resident['user_id']?.toString() ?? '';
          if (residentUserId == userId) {
            final firstName = resident['first_name']?.toString() ?? '';
            final lastName = resident['last_name']?.toString() ?? '';
            final residentFlatNumber = resident['flat_number']?.toString() ?? flatNumber;
            final fullName = lastName.isNotEmpty ? '$firstName $lastName' : firstName;
            final identifier = 'User#$userId-Flat#$residentFlatNumber';
            
            print('✅ Exact match found by user ID: $fullName ($identifier)');
            return {
              'display_name': fullName, // Just the full name, no extra formatting
              'identifier': identifier,
              'flat_number': residentFlatNumber,
            };
          }
        }
        
        // Second, try to find match by flat number and partial name matching
        for (final resident in approvedResidents) {
          final firstName = resident['first_name']?.toString() ?? '';
          final lastName = resident['last_name']?.toString() ?? '';
          final residentFlatNumber = resident['flat_number']?.toString() ?? '';
          final fullName = lastName.isNotEmpty ? '$firstName $lastName' : firstName;
          
          // Check flat number match and name similarity
          final flatMatches = residentFlatNumber == flatNumber || flatNumber == 'Unknown';
          final nameMatches = fullName.toLowerCase().contains(loginName.toLowerCase()) ||
                             loginName.toLowerCase().contains(firstName.toLowerCase());
          
          if (flatMatches && nameMatches) {
            final identifier = 'User#$userId-Flat#$residentFlatNumber';
            
            print('✅ Match found by flat and name: $fullName ($identifier)');
            return {
              'display_name': fullName, // Just the full name, no extra formatting
              'identifier': identifier,
              'flat_number': residentFlatNumber,
            };
          }
        }
        
        print('⚠️ No exact match found in approved residents');
      }
    } catch (e) {
      print('⚠️ Error fetching approved residents: $e');
    }
    
    // Fallback: create unique identifier using user ID and login info
    final fallbackFlat = flatNumber != 'Unknown' ? flatNumber : 'TBD';
    final identifier = 'User#$userId-Flat#$fallbackFlat';
    
    // Preserve the full login name as-is for fallback
    print('🔄 Fallback: Using login name as full name: "$loginName" ($identifier)');
    return {
      'display_name': loginName, // Use the full login name as provided
      'identifier': identifier,
      'flat_number': fallbackFlat,
    };
  }

  // Map login names to proper approved resident names (deprecated - use getUniqueResidentInfo instead)
  Future<String> getProperResidentName(String loginName, String buildingName) async {
    try {
      // Get the real approved residents from backend
      String baseUrl = 'http://localhost:5000';
      
      final response = await http.get(
        Uri.parse('$baseUrl/union/approved-residents?building_name=$buildingName'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final approvedResidents = data.cast<Map<String, dynamic>>();
        
        // Try to find a matching resident by partial name matching
        for (final resident in approvedResidents) {
          final firstName = resident['first_name']?.toString() ?? '';
          final lastName = resident['last_name']?.toString() ?? '';
          final fullName = lastName.isNotEmpty ? '$firstName $lastName' : firstName;
          
          // Check if login name is a partial match of the full name
          // e.g., "Test Resident" matches "Test Resident One"
          if (fullName.toLowerCase().contains(loginName.toLowerCase()) ||
              loginName.toLowerCase().contains(firstName.toLowerCase())) {
            print('🔄 Mapped login name "$loginName" → proper name "$fullName"');
            return fullName;
          }
        }
      }
    } catch (e) {
      print('⚠️ Error mapping resident name: $e');
    }
    
    // Fallback: return original name if no mapping found
    print('⚠️ No mapping found for "$loginName", using original name');
    return loginName;
  }

  // Private storage methods
  Future<void> _savePaymentProofs() async {
      try {
        final prefs = await SharedPreferences.getInstance();
      
      // Convert to JSON strings
      final proofStrings = _cachedProofs.map((proof) => jsonEncode(proof)).toList();
      
      print('💾 Attempting to save ${_cachedProofs.length} payment proofs...');
      
      // Save to SharedPreferences with error checking
      bool saved = await prefs.setStringList('payment_proofs', proofStrings);
      
      if (saved) {
        // Force commit and add timestamp
        await prefs.setInt('last_payment_update', DateTime.now().millisecondsSinceEpoch);
        await prefs.setInt('total_payment_count', _cachedProofs.length);
        
        // Force commit to disk/browser storage (critical for web)
        if (kIsWeb) {
          // For web, we need to ensure the data is immediately written
          await Future.delayed(Duration(milliseconds: 100)); // Give browser time to write
        }
        
        // Additional verification - try to read back immediately
        final verification = prefs.getStringList('payment_proofs') ?? [];
        if (verification.length == proofStrings.length) {
          print('✅ Successfully saved and verified ${_cachedProofs.length} payment proofs to storage');
          print('📊 Last update timestamp: ${DateTime.now().millisecondsSinceEpoch}');
          
          // Web-specific: Try to force localStorage persistence
      if (kIsWeb) {
            // Create a checkpoint to ensure data is written
            await prefs.setString('persistence_checkpoint', DateTime.now().toIso8601String());
            print('🌐 Web persistence checkpoint created');
          }
        } else {
          print('⚠️ Verification failed: Expected ${proofStrings.length}, got ${verification.length}');
        }
      } else {
        print('❌ Failed to save payment proofs to storage - SharedPreferences returned false');
      }
      
    } catch (e) {
      print('❌ Error saving payment proofs: $e');
      // Try alternative approach - save each proof individually
      try {
        final prefs = await SharedPreferences.getInstance();
        for (int i = 0; i < _cachedProofs.length; i++) {
          await prefs.setString('payment_proof_$i', jsonEncode(_cachedProofs[i]));
        }
        await prefs.setInt('individual_proof_count', _cachedProofs.length);
        await prefs.setString('fallback_timestamp', DateTime.now().toIso8601String());
        print('🔄 Fallback: Saved proofs individually');
      } catch (fallbackError) {
        print('❌ Fallback save also failed: $fallbackError');
      }
    }
  }

  Future<void> _loadPaymentProofsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      print('📂 Attempting to load payment proofs from storage...');
      
      // Web-specific: Check persistence checkpoint
      if (kIsWeb) {
        final checkpoint = prefs.getString('persistence_checkpoint');
        if (checkpoint != null) {
          print('🌐 Web persistence checkpoint found: $checkpoint');
        } else {
          print('⚠️ No web persistence checkpoint found');
        }
      }
      
      final proofStrings = prefs.getStringList('payment_proofs') ?? [];
      print('📊 Found ${proofStrings.length} stored proof strings');
      
      _cachedProofs.clear();
      
      if (proofStrings.isNotEmpty) {
        // Primary loading method
        for (final proofString in proofStrings) {
          try {
            final proof = Map<String, dynamic>.from(jsonDecode(proofString));
            _cachedProofs.add(proof);
          } catch (e) {
            print('⚠️ Error parsing stored payment proof: $e');
          }
        }
        print('✅ Loaded ${_cachedProofs.length} payment proofs from storage (primary method)');
      } else {
        // Fallback: try loading individual proofs
        print('🔄 No proofs found via primary method, trying fallback...');
        final individualCount = prefs.getInt('individual_proof_count') ?? 0;
        
        if (individualCount > 0) {
          print('🔄 Found $individualCount individual proofs to load...');
          for (int i = 0; i < individualCount; i++) {
            final proofString = prefs.getString('payment_proof_$i');
            if (proofString != null) {
              try {
                final proof = Map<String, dynamic>.from(jsonDecode(proofString));
                _cachedProofs.add(proof);
              } catch (e) {
                print('⚠️ Error parsing individual proof $i: $e');
              }
            }
          }
          print('🔄 Loaded ${_cachedProofs.length} payment proofs from individual storage');
          
          // If fallback was successful, migrate back to primary storage
          if (_cachedProofs.isNotEmpty) {
            print('🔄 Migrating fallback data back to primary storage...');
            await _savePaymentProofs();
          }
        }
      }
      
      // Verify data integrity
      final expectedCount = prefs.getInt('total_payment_count') ?? 0;
      if (expectedCount > 0 && _cachedProofs.length != expectedCount) {
        print('⚠️ Data integrity check: Expected $expectedCount proofs, loaded ${_cachedProofs.length}');
      }
      
      print('📊 Final result: ${_cachedProofs.length} payment proofs loaded into cache');
      
      // Debug: Show all available keys for troubleshooting
      final allKeys = prefs.getKeys();
      final relevantKeys = allKeys.where((key) => 
        key.startsWith('payment_') || 
        key.startsWith('building_') ||
        key.startsWith('total_') ||
        key.startsWith('last_') ||
        key.startsWith('individual_') ||
        key.startsWith('persistence_') ||
        key.startsWith('fallback_')
      ).toList();
      
      if (relevantKeys.isNotEmpty) {
        print('🔑 Found ${relevantKeys.length} relevant storage keys:');
        for (final key in relevantKeys.take(10)) {
          print('   • $key');
        }
        if (relevantKeys.length > 10) {
          print('   • ... and ${relevantKeys.length - 10} more');
        }
      }
      
    } catch (e) {
      print('❌ Error loading payment proofs from storage: $e');
    }
  }

  Future<void> _saveVerifiedPayments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert to JSON strings
      final verifiedStrings = _cachedVerified.map((payment) => jsonEncode(payment)).toList();
      
      print('💾 Attempting to save ${_cachedVerified.length} verified payments...');
      
      // Save to SharedPreferences
      bool saved = await prefs.setStringList('verified_payments', verifiedStrings);
      
      if (saved) {
        await prefs.setInt('verified_count', _cachedVerified.length);
        await prefs.setString('verified_timestamp', DateTime.now().toIso8601String());
        
        // Force commit for web
      if (kIsWeb) {
          await Future.delayed(Duration(milliseconds: 50));
        }
        
        print('✅ Successfully saved ${_cachedVerified.length} verified payments to storage');
      } else {
        print('❌ Failed to save verified payments to storage');
      }
      
    } catch (e) {
      print('❌ Error saving verified payments: $e');
    }
  }

  Future<void> _loadVerifiedPaymentsFromStorage() async {
      try {
        final prefs = await SharedPreferences.getInstance();
      final verifiedStrings = prefs.getStringList('verified_payments') ?? [];
      
      print('📂 Loading ${verifiedStrings.length} verified payments from storage...');
      
      _cachedVerified.clear();
      
      for (final verifiedString in verifiedStrings) {
        try {
          final payment = Map<String, dynamic>.from(jsonDecode(verifiedString));
          _cachedVerified.add(payment);
        } catch (e) {
          print('⚠️ Error parsing stored verified payment: $e');
        }
      }
      
      print('✅ Loaded ${_cachedVerified.length} verified payments from storage');
      
      // Verify data integrity
      final expectedCount = prefs.getInt('verified_count') ?? 0;
      if (expectedCount > 0 && _cachedVerified.length != expectedCount) {
        print('⚠️ Verified payments integrity check: Expected $expectedCount, loaded ${_cachedVerified.length}');
      }
      
    } catch (e) {
      print('❌ Error loading verified payments from storage: $e');
    }
  }

  // Debug methods
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('payment_proofs');
      await prefs.remove('verified_payments');
      await prefs.remove('last_payment_update');
      
      _cachedProofs.clear();
      _cachedVerified.clear();
      
      print('🗑️ Cleared all payment proof data');
      } catch (e) {
      print('❌ Error clearing payment proof data: $e');
    }
  }

  Future<Map<String, dynamic>> getStorageDebugInfo() async {
    await initialize();
    
    final prefs = await SharedPreferences.getInstance();
    final proofStrings = prefs.getStringList('payment_proofs') ?? [];
    final verifiedStrings = prefs.getStringList('verified_payments') ?? [];
    
    // Check bank details keys
    final allKeys = prefs.getKeys();
    final bankKeys = allKeys.where((key) => key.startsWith('building_bank')).toList();
    final paymentKeys = allKeys.where((key) => 
      key.startsWith('payment_') || 
      key.startsWith('verified_') || 
      key.startsWith('total_') ||
      key.startsWith('last_')
    ).toList();
    
    return {
      'cached_proofs_count': _cachedProofs.length,
      'cached_verified_count': _cachedVerified.length,
      'storage_proofs_count': proofStrings.length,
      'storage_verified_count': verifiedStrings.length,
      'last_update': prefs.getInt('last_payment_update') ?? 0,
      'total_payment_count': prefs.getInt('total_payment_count') ?? 0,
      'individual_proof_count': prefs.getInt('individual_proof_count') ?? 0,
      'initialized': _initialized,
      'bank_keys_count': bankKeys.length,
      'payment_keys_count': paymentKeys.length,
      'all_keys_count': allKeys.length,
      'bank_keys': bankKeys.take(10).toList(), // Show first 10 bank keys
      'storage_health': _cachedProofs.length == proofStrings.length ? 'HEALTHY' : 'MISMATCH',
    };
  }

  // Force save all data (for debugging)
  Future<void> forceSaveAllData() async {
    try {
      print('🔧 Force saving all data...');
      await _savePaymentProofs();
      await _saveVerifiedPayments();
      
      // Verify save
      final prefs = await SharedPreferences.getInstance();
      final savedProofs = prefs.getStringList('payment_proofs') ?? [];
      final savedVerified = prefs.getStringList('verified_payments') ?? [];
      
      print('✅ Force save completed:');
      print('   • Payment proofs: ${savedProofs.length} saved vs ${_cachedProofs.length} in cache');
      print('   • Verified payments: ${savedVerified.length} saved vs ${_cachedVerified.length} in cache');
      
    } catch (e) {
      print('❌ Error during force save: $e');
    }
  }

  // Validate that data is properly persisted
  Future<bool> _validateDataPersistence() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check payment proofs persistence
      final savedProofs = prefs.getStringList('payment_proofs') ?? [];
      final savedCount = prefs.getInt('total_payment_count') ?? 0;
      
      if (savedProofs.length != _cachedProofs.length || savedCount != _cachedProofs.length) {
        print('❌ Data persistence validation FAILED:');
        print('   • Cached proofs: ${_cachedProofs.length}');
        print('   • Saved proofs: ${savedProofs.length}');
        print('   • Saved count: $savedCount');
        return false;
      }
      
      // Check verified payments persistence
      final savedVerified = prefs.getStringList('verified_payments') ?? [];
      final verifiedCount = prefs.getInt('verified_count') ?? 0;
      
      if (savedVerified.length != _cachedVerified.length || verifiedCount != _cachedVerified.length) {
        print('❌ Verified payments persistence validation FAILED:');
        print('   • Cached verified: ${_cachedVerified.length}');
        print('   • Saved verified: ${savedVerified.length}');
        print('   • Verified count: $verifiedCount');
        return false;
      }
      
      print('✅ Data persistence validation PASSED');
      return true;
      
    } catch (e) {
      print('❌ Error validating data persistence: $e');
      return false;
    }
  }
} 