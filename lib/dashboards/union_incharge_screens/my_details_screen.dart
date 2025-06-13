import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart';
import '../../services/enhanced_persistence_service.dart';

class MyDetailsScreen extends StatefulWidget {
  final String? unionId;
  final String? buildingName;
  final Map<String, dynamic>? userData;
  
  const MyDetailsScreen({
    super.key,
    this.unionId,
    this.buildingName,
    this.userData,
  });

  @override
  State<MyDetailsScreen> createState() => _MyDetailsScreenState();
}

class _MyDetailsScreenState extends State<MyDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountTitleController = TextEditingController();
  
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isSaving = false;
  Map<String, dynamic>? _userDetails;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // STEP 1: Always try to load from local storage first (this has bank details)
      await _loadFromLocalStorage();
      
      // STEP 2: If we have login data, merge it but PRESERVE bank details
      if (widget.userData != null) {
        if (_userDetails != null) {
          // We have local data - preserve bank details and merge other info
          final localBankDetails = {
            'bank_name': _userDetails!['bank_name'],
            'account_number': _userDetails!['account_number'], 
            'account_title': _userDetails!['account_title'],
          };
          
          // Merge with login data but preserve bank details
          _userDetails = {
            ...widget.userData!,    // Use fresh login data
            ..._userDetails!,       // Override with local data
            ...localBankDetails,    // FORCE bank details to persist
          };
          print('🔄 Merged login data while preserving local bank details');
        } else {
          // No local data yet - use login data and save it
          _userDetails = Map<String, dynamic>.from(widget.userData!);
          await _saveToLocalStorage(_userDetails!);
          print('💾 Initial user data saved to local storage');
        }
      }
      
      // STEP 3: Try backend but NEVER overwrite bank details
      if (widget.unionId != null && _userDetails != null) {
        try {
          // Save current bank details before backend fetch
          final preservedBankDetails = {
            'bank_name': _userDetails!['bank_name'],
            'account_number': _userDetails!['account_number'],
            'account_title': _userDetails!['account_title'],
          };
          
          final currentDetails = Map<String, dynamic>.from(_userDetails!);
          await _fetchUserDetailsFromBackend();
          
          // If backend fetch succeeded, merge but preserve bank details
          if (_userDetails != null) {
            _userDetails = {
              ...currentDetails,      // Start with current data
              ..._userDetails!,       // Add backend data
              ...preservedBankDetails, // FORCE preserve bank details
            };
            print('🔄 Merged backend data while preserving bank details');
          } else {
            // Backend failed, restore current data
            _userDetails = currentDetails;
            print('⚠️ Backend fetch failed, keeping current data with bank details');
          }
        } catch (e) {
          print('⚠️ Backend fetch error, keeping local data: $e');
        }
      }
      
      // STEP 4: Ensure we have data and populate controllers
      if (_userDetails == null && widget.userData != null) {
        _userDetails = Map<String, dynamic>.from(widget.userData!);
      }
      
      // Always populate controllers with final data
      _populateControllers();
      
      // STEP 5: If we have bank details, ensure they're saved with all strategies
      if (_userDetails != null && 
          (_userDetails!['bank_name']?.toString().isNotEmpty == true ||
           _userDetails!['account_number']?.toString().isNotEmpty == true ||
           _userDetails!['account_title']?.toString().isNotEmpty == true)) {
        
        print('💾 Ensuring bank details are saved with all persistence strategies');
        await _saveToLocalStorage(_userDetails!);
      }
      
    } catch (e) {
      print('❌ Error loading user details: $e');
      // Use provided userData as fallback
      if (widget.userData != null) {
        _userDetails = Map<String, dynamic>.from(widget.userData!);
        _populateControllers();
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserDetailsFromBackend() async {
    try {
      final baseUrl = getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/union_incharges/${widget.unionId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _userDetails = data;
        });
        print('✅ User details loaded from backend');
      } else {
        print('⚠️ Failed to load user details from backend: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching user details from backend: $e');
    }
  }

  Future<void> _loadFromLocalStorage() async {
    try {
      // Use enhanced persistence service for better data recovery
      final enhancedService = EnhancedPersistenceService.instance;
      
      if (widget.unionId != null && widget.buildingName != null) {
        final details = await enhancedService.loadUnionInchargeDetails(
          unionId: widget.unionId!,
          buildingName: widget.buildingName!,
        );
        
        if (details != null) {
          // Check if we have bank details in the loaded data
          final hasBankDetails = (details['bank_name'] != null && details['bank_name'].toString().isNotEmpty) ||
                                (details['account_number'] != null && details['account_number'].toString().isNotEmpty) ||
                                (details['account_title'] != null && details['account_title'].toString().isNotEmpty);
          
          if (hasBankDetails) {
            setState(() {
              _userDetails = details;
            });
            print('✅ User details loaded with enhanced persistence (with bank details)');
            return;
          } else {
            print('⚠️ User details loaded but missing bank details, trying to recover bank info');
            
            // Try to recover bank details from separate storage
            Map<String, dynamic> recoveredBankDetails = {};
            
            final prefs = await SharedPreferences.getInstance();
            
            // Try multiple key patterns to recover bank details
            final bankKeys = [
              'union_${widget.unionId}_bank_name',
              'building_${widget.buildingName}_bank_name',
              'union_incharge_${widget.unionId}_bank_name',
            ];
            
            final accountKeys = [
              'union_${widget.unionId}_account_number',
              'building_${widget.buildingName}_account_number',
              'union_incharge_${widget.unionId}_account_number',
            ];
            
            final titleKeys = [
              'union_${widget.unionId}_account_title',
              'building_${widget.buildingName}_account_title',
              'union_incharge_${widget.unionId}_account_title',
            ];
            
            // Try to find bank name
            for (final key in bankKeys) {
              final value = prefs.getString(key);
              if (value != null && value.isNotEmpty) {
                recoveredBankDetails['bank_name'] = value;
                print('✅ Recovered bank name from key: $key');
                break;
              }
            }
            
            // Try to find account number
            for (final key in accountKeys) {
              final value = prefs.getString(key);
              if (value != null && value.isNotEmpty) {
                recoveredBankDetails['account_number'] = value;
                print('✅ Recovered account number from key: $key');
                break;
              }
            }
            
            // Try to find account title
            for (final key in titleKeys) {
              final value = prefs.getString(key);
              if (value != null && value.isNotEmpty) {
                recoveredBankDetails['account_title'] = value;
                print('✅ Recovered account title from key: $key');
                break;
              }
            }
            
            // Merge recovered bank details with existing details
            if (recoveredBankDetails.isNotEmpty) {
              final mergedDetails = {
                ...details,
                ...recoveredBankDetails,
                'bank_details_recovered': true,
                'recovery_timestamp': DateTime.now().toIso8601String(),
              };
              
              setState(() {
                _userDetails = mergedDetails;
              });
              
              // Save the merged data for future use
              await enhancedService.saveUnionInchargeDetails(
                unionId: widget.unionId!,
                buildingName: widget.buildingName!,
                userDetails: mergedDetails,
              );
              
              print('✅ Bank details recovered and merged with user details');
              return;
            } else {
              // Use the details we have, even without bank info
              setState(() {
                _userDetails = details;
              });
              print('⚠️ No bank details found in recovery, using other user details');
              return;
            }
          }
        }
      }
      
      // Fallback to original method
      final prefs = await SharedPreferences.getInstance();
      
      List<String> keysToTry = [
        'union_incharge_${widget.unionId}',
        'union_incharge_building_${widget.buildingName}',
      ];
      
      if (widget.buildingName != null) {
        final buildingKey = widget.buildingName!.replaceAll(' ', '_').toLowerCase();
        keysToTry.add('union_incharge_building_$buildingKey');
      }
      
      for (String key in keysToTry) {
        final userData = prefs.getString(key);
        if (userData != null) {
          final data = jsonDecode(userData);
          setState(() {
            _userDetails = data;
          });
          print('✅ User details loaded from local storage with key: $key');
          return;
        }
      }
      
      print('ℹ️ No user details found in local storage');
    } catch (e) {
      print('❌ Error loading from local storage: $e');
    }
  }

  void _populateControllers() {
    if (_userDetails != null) {
      final firstName = _userDetails!['first_name'] ?? '';
      final lastName = _userDetails!['last_name'] ?? '';
      _fullNameController.text = '$firstName $lastName'.trim();
      _emailController.text = _userDetails!['email'] ?? '';
      _phoneController.text = _userDetails!['phone'] ?? '';
      _bankNameController.text = _userDetails!['bank_name'] ?? '';
      _accountNumberController.text = _userDetails!['account_number'] ?? '';
      _accountTitleController.text = _userDetails!['account_title'] ?? '';
      
      print('📝 Populated controllers:');
      print('   Full Name: ${_fullNameController.text}');
      print('   Email: ${_emailController.text}');
      print('   Phone: ${_phoneController.text}');
      print('   Bank Name: ${_bankNameController.text}');
      print('   Account Number: ${_accountNumberController.text}');
      print('   Account Title: ${_accountTitleController.text}');
    } else {
      print('⚠️ No user details available to populate controllers');
    }
  }

  Future<void> _saveUserDetails() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Split full name into first and last name
      final fullNameParts = _fullNameController.text.trim().split(' ');
      final firstName = fullNameParts.isNotEmpty ? fullNameParts.first : '';
      final lastName = fullNameParts.length > 1 ? fullNameParts.sublist(1).join(' ') : '';
      
      final updatedDetails = {
        ..._userDetails!, // Keep all existing data
        'first_name': firstName,
        'last_name': lastName,
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'bank_name': _bankNameController.text.trim(),
        'account_number': _accountNumberController.text.trim(),
        'account_title': _accountTitleController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      print('💾 Saving updated details:');
      print('   Bank Name: ${updatedDetails['bank_name']}');
      print('   Account Number: ${updatedDetails['account_number']}');
      print('   Account Title: ${updatedDetails['account_title']}');

      // Try to save to backend first
      bool backendSuccess = false;
      String errorMessage = '';
      
      try {
        await _saveToBackend(updatedDetails);
        backendSuccess = true;
        print('✅ Backend save successful');
      } catch (e) {
        print('⚠️ Backend save failed: $e');
        errorMessage = e.toString();
      }

      // Always save to local storage as backup
      await _saveToLocalStorage(updatedDetails);

      // Always notify residents by refreshing their cache (regardless of backend status)
      await _notifyResidentsOfUpdate(updatedDetails);

      setState(() {
        _userDetails = updatedDetails;
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    backendSuccess 
                        ? 'Details saved to database successfully and shared with residents!' 
                        : 'Details saved locally and shared with residents!\nServer temporarily unavailable.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _saveToBackend(Map<String, dynamic> details) async {
    final baseUrl = getBaseUrl();
    
    print('🔄 Attempting to save to backend: ${jsonEncode(details)}');
    
    try {
      // Use the correct union profile update endpoint
      final response = await http.put(
        Uri.parse('$baseUrl/union/profile/${widget.unionId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'first_name': details['first_name'],
          'last_name': details['last_name'],
          'email': details['email'],
          'phone': details['phone'],
          'bank_name': details['bank_name'],
          'account_number': details['account_number'],
          'account_title': details['account_title'],
        }),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ User details saved to backend successfully: ${responseData['message']}');
        return;
      } else {
        print('❌ Backend save failed with status ${response.statusCode}');
        throw Exception('Backend save failed with status ${response.statusCode}');
      }
      
    } catch (e) {
      print('❌ Backend save error: $e');
      throw Exception('Backend save failed: $e');
    }
  }

  Future<void> _saveToLocalStorage(Map<String, dynamic> details) async {
    // Use enhanced persistence service for better data reliability
    final enhancedService = EnhancedPersistenceService.instance;
    
    print('💾 Saving with enhanced persistence service:');
    print('   Bank Name: ${details['bank_name']}');
    print('   Account Number: ${details['account_number']}');
    print('   Account Title: ${details['account_title']}');
    
    if (widget.unionId != null && widget.buildingName != null) {
      final saved = await enhancedService.saveUnionInchargeDetails(
        unionId: widget.unionId!,
        buildingName: widget.buildingName!,
        userDetails: details,
      );
      
      if (saved) {
        print('✅ User details saved with enhanced persistence');
        
        // IMPORTANT: Also save bank details separately for union incharge access
        // This ensures bank details persist specifically for the union incharge role
        final bankDetails = {
          'bank_name': details['bank_name'] ?? '',
          'account_number': details['account_number'] ?? '',
          'account_title': details['account_title'] ?? '',
          'building_name': widget.buildingName!,
          'union_id': widget.unionId!,
          'saved_from': 'union_incharge_my_details',
          'timestamp': DateTime.now().toIso8601String(),
        };
        
        // Save bank details with enhanced service
        await enhancedService.saveBankDetails(
          buildingName: widget.buildingName!,
          bankDetails: bankDetails,
        );
        
        // Also save using direct SharedPreferences for maximum compatibility
        final prefs = await SharedPreferences.getInstance();
        
        // Save individual bank fields with multiple key patterns for reliability
        final bankKeys = [
          'union_${widget.unionId}_bank_name',
          'building_${widget.buildingName}_bank_name',
          'union_incharge_${widget.unionId}_bank_name',
        ];
        
        final accountKeys = [
          'union_${widget.unionId}_account_number',
          'building_${widget.buildingName}_account_number',
          'union_incharge_${widget.unionId}_account_number',
        ];
        
        final titleKeys = [
          'union_${widget.unionId}_account_title',
          'building_${widget.buildingName}_account_title',
          'union_incharge_${widget.unionId}_account_title',
        ];
        
        // Save bank name with multiple keys
        for (final key in bankKeys) {
          await prefs.setString(key, details['bank_name'] ?? '');
        }
        
        // Save account number with multiple keys
        for (final key in accountKeys) {
          await prefs.setString(key, details['account_number'] ?? '');
        }
        
        // Save account title with multiple keys
        for (final key in titleKeys) {
          await prefs.setString(key, details['account_title'] ?? '');
        }
        
        print('✅ Bank details saved with multiple key patterns for persistence');
        
      } else {
        print('⚠️ Enhanced save had some issues, falling back to original method');
        // Fallback to original method
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('union_incharge_${widget.unionId}', jsonEncode(details));
        
        if (widget.buildingName != null && widget.buildingName!.isNotEmpty) {
          final buildingKey = widget.buildingName!.replaceAll(' ', '_').toLowerCase();
          await prefs.setString('union_incharge_building_$buildingKey', jsonEncode(details));
          await prefs.setString('union_incharge_building_${widget.buildingName}', jsonEncode(details));
        }
      }
    }
  }

  Future<void> _notifyResidentsOfUpdate(Map<String, dynamic> details) async {
    try {
      print('🔔 === UPDATING RESIDENT ACCESS TO BANK DETAILS ===');
      
      final prefs = await SharedPreferences.getInstance();
      
      if (widget.buildingName != null && widget.buildingName!.isNotEmpty) {
        final buildingKey = widget.buildingName!.replaceAll(' ', '_').toLowerCase();
        final jsonData = jsonEncode(details);
        
        print('🏢 Building: ${widget.buildingName}');
        print('🔑 Building Key: $buildingKey');
        print('💰 Bank Details: ${details['bank_name']} | ${details['account_number']} | ${details['account_title']}');
        
        // STRATEGY 1: Multiple resident-accessible keys for maximum reliability
        final residentKeys = [
          'union_incharge_building_$buildingKey',
          'union_incharge_building_${widget.buildingName}',
          'resident_cache_union_$buildingKey',
          'resident_access_union_$buildingKey',
          'building_union_details_$buildingKey',
          'bank_details_$buildingKey',
        ];
        
        // Save full details to all resident keys
        for (final key in residentKeys) {
          await prefs.setString(key, jsonData);
          print('📝 Saved to resident key: $key');
        }
        
        // STRATEGY 2: Save bank details specifically for backend lookup compatibility
        final bankKeys = <String>[]; // Initialize here to avoid scope issues
        
        if (details['bank_name']?.toString().isNotEmpty == true ||
            details['account_number']?.toString().isNotEmpty == true ||
            details['account_title']?.toString().isNotEmpty == true) {
          
          final bankOnlyDetails = {
            'bank_name': details['bank_name'] ?? '',
            'account_number': details['account_number'] ?? '',
            'account_title': details['account_title'] ?? '',
            'building_name': widget.buildingName,
            'union_id': widget.unionId,
            'updated_at': DateTime.now().toIso8601String(),
            'for_residents': true,
          };
          
          bankKeys.addAll([
            'bank_details_$buildingKey',
            'building_bank_details_${widget.buildingName}',
            'bank_info_$buildingKey',
            'union_bank_$buildingKey',
          ]);
          
          for (final key in bankKeys) {
            await prefs.setString(key, jsonEncode(bankOnlyDetails));
            print('🏦 Saved bank details to key: $key');
          }
          
          // STRATEGY 3: Save individual bank fields for maximum compatibility
          await prefs.setString('building_bank_name_$buildingKey', details['bank_name'] ?? '');
          await prefs.setString('building_account_number_$buildingKey', details['account_number'] ?? '');
          await prefs.setString('building_account_title_$buildingKey', details['account_title'] ?? '');
          await prefs.setString('building_iban_$buildingKey', details['account_number'] ?? ''); // For IBAN compatibility
          
          print('✅ Individual bank fields saved for building: $buildingKey');
        }
        
        // STRATEGY 4: Create timestamp and status tracking
        await prefs.setString('union_incharge_last_updated_${widget.unionId}', DateTime.now().toIso8601String());
        await prefs.setString('bank_details_last_updated_$buildingKey', DateTime.now().toIso8601String());
        await prefs.setBool('bank_details_available_$buildingKey', true);
        
        // STRATEGY 5: Use enhanced persistence service for additional backup
        final enhancedService = EnhancedPersistenceService.instance;
        
        // Save bank details with enhanced service
        if (details['bank_name']?.toString().isNotEmpty == true) {
          await enhancedService.saveBankDetails(
            buildingName: widget.buildingName!,
            bankDetails: {
              'bank_name': details['bank_name'] ?? '',
              'account_number': details['account_number'] ?? '',
              'account_title': details['account_title'] ?? '',
              'building_name': widget.buildingName,
              'union_id': widget.unionId,
              'saved_for_residents': true,
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
          print('🔧 Enhanced persistence service backup completed');
        }
        
        print('✅ RESIDENT ACCESS UPDATED - Bank details now available to all residents');
        print('🔔 Total storage keys created: ${residentKeys.length + bankKeys.length + 7}'); // +7 for individual fields and timestamps
      } else {
        print('⚠️ Building name missing - cannot update resident cache');
      }
    } catch (e) {
      print('❌ Error updating resident cache: $e');
    }
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
    });
    _populateControllers(); // Reset controllers to original values
  }

  Future<void> _showDebugInfo() async {
    try {
      print('🔍 === DEBUG INFO ANALYSIS ===');
      
      // Show current controller values
      print('📝 Current Controller Values:');
      print('   Bank Name: "${_bankNameController.text}"');
      print('   Account Number: "${_accountNumberController.text}"');
      print('   Account Title: "${_accountTitleController.text}"');
      
      // Show current _userDetails
      print('');
      print('👤 Current User Details:');
      if (_userDetails != null) {
        print('   Bank Name: "${_userDetails!['bank_name'] ?? 'NULL'}"');
        print('   Account Number: "${_userDetails!['account_number'] ?? 'NULL'}"');
        print('   Account Title: "${_userDetails!['account_title'] ?? 'NULL'}"');
        print('   First Name: "${_userDetails!['first_name'] ?? 'NULL'}"');
        print('   Last Name: "${_userDetails!['last_name'] ?? 'NULL'}"');
        print('   Email: "${_userDetails!['email'] ?? 'NULL'}"');
        print('   Phone: "${_userDetails!['phone'] ?? 'NULL'}"');
        print('   Building Name: "${_userDetails!['building_name'] ?? 'NULL'}"');
        print('   Union ID: "${_userDetails!['union_id'] ?? 'NULL'}"');
      } else {
        print('   _userDetails is NULL');
      }
      
      // Check SharedPreferences storage
      print('');
      print('💾 SharedPreferences Analysis:');
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      
      print('   Total keys: ${allKeys.length}');
      
      // Filter relevant keys
      final relevantKeys = allKeys.where((key) => 
        key.contains('union') ||
        key.contains('bank') ||
        key.contains('account') ||
        key.contains('enhanced') ||
        key.contains(widget.unionId ?? 'NO_UNION_ID') ||
        key.contains(widget.buildingName?.replaceAll(' ', '_').toLowerCase() ?? 'NO_BUILDING')
      ).toList();
      
      print('   Relevant keys found: ${relevantKeys.length}');
      
      for (final key in relevantKeys) {
        final value = prefs.getString(key);
        if (value != null) {
          print('   $key: ${value.length} chars');
          
          // Try to parse JSON values
          if (value.startsWith('{')) {
            try {
              final data = jsonDecode(value) as Map<String, dynamic>;
              final hasBank = data['bank_name'] != null || data['account_number'] != null;
              print('     -> Has bank details: $hasBank');
              if (hasBank) {
                print('     -> Bank: "${data['bank_name']}"');
                print('     -> Account: "${data['account_number']}"');
                print('     -> Title: "${data['account_title']}"');
              }
            } catch (e) {
              print('     -> Parse error: $e');
            }
          } else {
            print('     -> Value: "$value"');
          }
        }
      }
      
      // Try enhanced persistence service
      print('');
      print('🔧 Enhanced Persistence Service Test:');
      if (widget.unionId != null && widget.buildingName != null) {
        final enhancedService = EnhancedPersistenceService.instance;
        final enhancedData = await enhancedService.loadUnionInchargeDetails(
          unionId: widget.unionId!,
          buildingName: widget.buildingName!,
        );
        
        if (enhancedData != null) {
          print('   Enhanced service loaded data successfully');
          print('   Bank Name: "${enhancedData['bank_name'] ?? 'NULL'}"');
          print('   Account Number: "${enhancedData['account_number'] ?? 'NULL'}"');
          print('   Account Title: "${enhancedData['account_title'] ?? 'NULL'}"');
        } else {
          print('   Enhanced service returned NULL');
        }
        
        // Try enhanced bank details loading
        final bankData = await enhancedService.loadBankDetails(
          buildingName: widget.buildingName!,
        );
        
        if (bankData != null) {
          print('   Enhanced bank service loaded data successfully');
          print('   Bank Name: "${bankData['bank_name'] ?? 'NULL'}"');
          print('   Account Number: "${bankData['account_number'] ?? 'NULL'}"');
          print('   Account Title: "${bankData['account_title'] ?? 'NULL'}"');
        } else {
          print('   Enhanced bank service returned NULL');
        }
      } else {
        print('   Cannot test enhanced service - missing unionId or buildingName');
        print('   Union ID: ${widget.unionId}');
        print('   Building Name: ${widget.buildingName}');
      }
      
      print('');
      print('🎯 Widget Data:');
      print('   Union ID: ${widget.unionId}');
      print('   Building Name: ${widget.buildingName}');
      if (widget.userData != null) {
        print('   Widget userData has bank details: ${widget.userData!['bank_name'] != null}');
        print('   Widget userData bank_name: "${widget.userData!['bank_name'] ?? 'NULL'}"');
        print('   Widget userData account_number: "${widget.userData!['account_number'] ?? 'NULL'}"');
        print('   Widget userData account_title: "${widget.userData!['account_title'] ?? 'NULL'}"');
      } else {
        print('   Widget userData is NULL');
      }
      
      print('🔍 === END DEBUG INFO ===');
      
      // Show a dialog with summary
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Debug Info'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Controller Values:'),
                  Text('Bank: "${_bankNameController.text}"'),
                  Text('Account: "${_accountNumberController.text}"'),
                  Text('Title: "${_accountTitleController.text}"'),
                  const SizedBox(height: 10),
                  Text('Storage Keys Found: ${relevantKeys.length}'),
                  Text('Enhanced Service: ${widget.unionId != null ? 'Available' : 'Missing ID'}'),
                  const SizedBox(height: 10),
                  const Text('Check console for detailed logs'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
      
    } catch (e) {
      print('❌ Debug info error: $e');
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountTitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 600;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Custom header
          _buildHeader(context, isWebLayout),
          // Main content
          Expanded(
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isWebLayout ? 600 : double.infinity,
                ),
                child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: EdgeInsets.all(isWebLayout ? 30 : 20),
                        child: _buildDetailsForm(isWebLayout),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isWebLayout) {
    return Container(
      height: isWebLayout ? 100 : 120,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E7D32), // Dark Green
            Color(0xFF4CAF50), // Light Green
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isWebLayout ? 40 : 20,
            vertical: 10,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: isWebLayout ? 28 : 24,
                ),
              ),
              const SizedBox(width: 20),
              Text(
                'My Details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isWebLayout ? 28 : 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_isEditing) ...[
                GestureDetector(
                  onTap: _cancelEditing,
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: isWebLayout ? 28 : 24,
                  ),
                ),
                const SizedBox(width: 15),
                GestureDetector(
                  onTap: _isSaving ? null : _saveUserDetails,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ] else
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  child: Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: isWebLayout ? 28 : 24,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsForm(bool isWebLayout) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile section
          _buildProfileSection(isWebLayout),
          const SizedBox(height: 30),
          
          // Personal Information
          _buildSectionCard(
            'Personal Info',
            [
              _buildDetailRow('Full Name', _fullNameController, Icons.person_outline),
              _buildDetailRow('Phone Number', _phoneController, Icons.phone_outlined, 
                  keyboardType: TextInputType.phone),
              _buildDetailRow('Email', _emailController, Icons.email_outlined, 
                  keyboardType: TextInputType.emailAddress),
            ],
            isWebLayout,
          ),
          
          const SizedBox(height: 30),
          
          // Bank Details
          _buildBankDetailsSection(isWebLayout),
        ],
      ),
    );
  }

  Widget _buildProfileSection(bool isWebLayout) {
    final fullName = '${_userDetails?['first_name'] ?? ''} ${_userDetails?['last_name'] ?? ''}'.trim();
    
    return Container(
      padding: EdgeInsets.all(isWebLayout ? 30 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: isWebLayout ? 120 : 100,
            height: isWebLayout ? 120 : 100,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.person,
              size: isWebLayout ? 60 : 50,
              color: const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            fullName.isEmpty ? 'Union Incharge' : fullName,
            style: TextStyle(
              fontSize: isWebLayout ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _userDetails?['building_name'] ?? widget.buildingName ?? 'Building',
            style: TextStyle(
              fontSize: isWebLayout ? 16 : 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children, bool isWebLayout) {
    return Container(
      padding: EdgeInsets.all(isWebLayout ? 30 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isWebLayout ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildBankDetailsSection(bool isWebLayout) {
    return Container(
      padding: EdgeInsets.all(isWebLayout ? 30 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Bank Details',
                style: TextStyle(
                  fontSize: isWebLayout ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              // Debug button - only show when editing for testing
              if (_isEditing)
                IconButton(
                  icon: Icon(Icons.bug_report, color: Colors.orange[700]),
                  onPressed: _showDebugInfo,
                  tooltip: 'Debug Storage Info',
                ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow('Bank Name', _bankNameController, Icons.account_balance_outlined),
          _buildDetailRow('Account Number', _accountNumberController, Icons.credit_card_outlined, 
              keyboardType: TextInputType.number),
          _buildDetailRow('Account Title', _accountTitleController, Icons.account_circle_outlined),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, TextEditingController controller, IconData icon, 
      {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            enabled: _isEditing,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF4CAF50)),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              filled: true,
              fillColor: _isEditing ? Colors.white : Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label is required';
              }
              if (label == 'Email' && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              if (label == 'Phone Number' && !RegExp(r'^\+?[\d\s-()]+$').hasMatch(value)) {
                return 'Please enter a valid phone number';
              }
              if (label == 'Account Number' && !RegExp(r'^[\d]+$').hasMatch(value)) {
                return 'Please enter a valid account number (digits only)';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}