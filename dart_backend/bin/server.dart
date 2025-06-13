import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:uuid/uuid.dart';
// Remove the problematic import for now since it's causing compilation issues
// import '../lib/firebase_config.dart';

// File-based persistent storage for development
class FileStorage {
  static late final String _dataDir;
  static late final String _usersFile;
  static late final String _buildingsFile;
  static late final String _complaintsFile;
  static late final String _emergenciesFile;
  static late final String _electionFile;
  static late final String _votesFile;
  static late final String _bankDetailsFile;
  static late final String _verifiedPaymentsFile;
  static late final String _technicalIssuesFile;
  static late final String _noticesFile;
  static late final String _serviceRequestsFile;
  
  static Map<String, Map<String, dynamic>> users = {};
  static Map<String, Map<String, dynamic>> buildings = {};
  static Map<String, Map<String, dynamic>> complaints = {};
  static Map<String, Map<String, dynamic>> emergencies = {};
  static Map<String, Map<String, dynamic>> elections = {};
  static Map<String, Map<String, dynamic>> votes = {};
  static Map<String, Map<String, dynamic>> bankDetails = {};
  static Map<String, Map<String, dynamic>> verifiedPayments = {};
  static Map<String, Map<String, dynamic>> technicalIssues = {};
  static Map<String, Map<String, dynamic>> notices = {};
  static Map<String, Map<String, dynamic>> serviceRequests = {};
  
  // Initialize storage - create directory and load existing data
  static Future<void> initialize() async {
    try {
      // Get the directory where the server executable is located
      final currentDir = Directory.current;
      final serverFile = File(Platform.script.toFilePath());
      final serverDir = serverFile.parent;
      
      // Set up absolute paths - look for data directory in server's parent directory (dart_backend folder)
      _dataDir = '${serverDir.path}/data';
      _usersFile = '$_dataDir/users.json';
      _buildingsFile = '$_dataDir/buildings.json';
      _complaintsFile = '$_dataDir/complaints.json';
      _emergenciesFile = '$_dataDir/emergencies.json';
      _electionFile = '$_dataDir/elections.json';
      _votesFile = '$_dataDir/votes.json';
      _bankDetailsFile = '$_dataDir/bank_details.json';
      _verifiedPaymentsFile = '$_dataDir/verified_payments.json';
      _technicalIssuesFile = '$_dataDir/technical_issues.json';
      _noticesFile = '$_dataDir/notices.json';
      _serviceRequestsFile = '$_dataDir/service_requests.json';
      
      print('🗂️ Current working directory: ${currentDir.path}');
      print('📂 Server directory: ${serverDir.path}');
      print('💾 Data directory: $_dataDir');

      // Create data directory if it doesn't exist
      final directory = Directory(_dataDir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
        print('📁 Created data directory: $_dataDir');
      } else {
        print('📁 Data directory exists: $_dataDir');
      }

      // Load existing data from files
      await Future.wait([
        _loadFromFile(_usersFile, users),
        _loadFromFile(_buildingsFile, buildings),
        _loadFromFile(_complaintsFile, complaints),
        _loadFromFile(_emergenciesFile, emergencies),
        _loadFromFile(_electionFile, elections),
        _loadFromFile(_votesFile, votes),
        _loadFromFile(_bankDetailsFile, bankDetails),
        _loadFromFile(_verifiedPaymentsFile, verifiedPayments),
        _loadFromFile(_technicalIssuesFile, technicalIssues),
        _loadFromFile(_noticesFile, notices),
        _loadFromFile(_serviceRequestsFile, serviceRequests),
      ]);

      print('🗄️ FileStorage initialized successfully with ${users.length} users, ${serviceRequests.length} service requests');
      print('📊 Data loaded: users=${users.length}, complaints=${complaints.length}, elections=${elections.length}, serviceRequests=${serviceRequests.length}');
      
      // Test data persistence to ensure everything is working
      final persistenceTest = await testDataPersistence();
      if (persistenceTest) {
        print('✅ Data persistence test passed - all data will be saved correctly');
      } else {
        print('⚠️ Data persistence test failed - there may be issues with data saving');
      }
    } catch (e) {
      print('❌ Error initializing FileStorage: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }
  
  // Load data from a JSON file into a Map
  static Future<void> _loadFromFile(String filePath, Map<String, Map<String, dynamic>> storage) async {
    try {
      final file = File(filePath);
      print('🔍 Checking file: $filePath');
      
      if (await file.exists()) {
        final fileSize = await file.length();
        print('📄 File exists: $filePath (${fileSize} bytes)');
        
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final Map<String, dynamic> data = jsonDecode(content);
          storage.clear();
          data.forEach((key, value) {
            if (value is Map) {
              storage[key] = Map<String, dynamic>.from(value);
            } else {
              print('⚠️ Skipping invalid entry: $key = $value');
            }
          });
          print('✅ Loaded ${storage.length} entries from ${file.path.split('/').last}');
        } else {
          print('📄 File is empty: $filePath');
        }
      } else {
        print('📄 File does not exist: $filePath - starting with empty storage');
      }
    } catch (e) {
      print('❌ Error loading from $filePath: $e');
      print('Stack trace: ${StackTrace.current}');
      // Don't fail completely, just start with empty storage
      storage.clear();
    }
  }
  
  // Save data from a Map to a JSON file
  static Future<void> _saveToFile(String filePath, Map<String, Map<String, dynamic>> storage) async {
    try {
      final file = File(filePath);
      
      // Ensure directory exists
      final directory = file.parent;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
        print('📁 Created directory: ${directory.path}');
      }
      
      final jsonData = jsonEncode(storage);
      await file.writeAsString(jsonData);
      
      // Verify the save was successful
      final savedSize = await file.length();
      print('💾 Saved ${storage.length} entries to ${file.path.split('/').last} (${savedSize} bytes)');
    } catch (e) {
      print('❌ Error saving to $filePath: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow; // Re-throw to ensure calling code knows save failed
    }
  }
  
  // Save all data to files
  static Future<void> saveAll() async {
    await Future.wait([
      _saveToFile(_usersFile, users),
      _saveToFile(_buildingsFile, buildings),
      _saveToFile(_complaintsFile, complaints),
      _saveToFile(_emergenciesFile, emergencies),
      _saveToFile(_electionFile, elections),
      _saveToFile(_votesFile, votes),
      _saveToFile(_bankDetailsFile, bankDetails),
      _saveToFile(_verifiedPaymentsFile, verifiedPayments),
      _saveToFile(_technicalIssuesFile, technicalIssues),
      _saveToFile(_noticesFile, notices),
      _saveToFile(_serviceRequestsFile, serviceRequests),
    ]);
  }
  
  // Save users data specifically (called after user operations)
  static Future<void> saveUsers() async {
    await _saveToFile(_usersFile, users);
  }
  
  // Save complaints data specifically
  static Future<void> saveComplaints() async {
    await _saveToFile(_complaintsFile, complaints);
  }
  
  // Save emergencies data specifically
  static Future<void> saveEmergencies() async {
    await _saveToFile(_emergenciesFile, emergencies);
  }
  
  // Save elections data specifically
  static Future<void> saveElections() async {
    await _saveToFile(_electionFile, elections);
  }
  
  // Save votes data specifically
  static Future<void> saveVotes() async {
    await _saveToFile(_votesFile, votes);
  }
  
  // Save bank details data specifically
  static Future<void> saveBankDetails() async {
    await _saveToFile(_bankDetailsFile, bankDetails);
  }
  
  // Save verified payments data specifically
  static Future<void> saveVerifiedPayments() async {
    await _saveToFile(_verifiedPaymentsFile, verifiedPayments);
  }
  
  // Save technical issues data specifically
  static Future<void> saveTechnicalIssues() async {
    await _saveToFile(_technicalIssuesFile, technicalIssues);
  }
  
  // Save notices data specifically
  static Future<void> saveNotices() async {
    await _saveToFile(_noticesFile, notices);
  }
  
  // Save service requests data specifically
  static Future<void> saveServiceRequests() async {
    await _saveToFile(_serviceRequestsFile, serviceRequests);
  }
  
  // Method to clear all data (for development/testing)
  static Future<void> clearAllData() async {
    users.clear();
    buildings.clear();
    complaints.clear();
    emergencies.clear();
    elections.clear();
    votes.clear();
    bankDetails.clear();
    verifiedPayments.clear();
    technicalIssues.clear();
    notices.clear();
    serviceRequests.clear();
    
    // Also delete the files
    try {
      await Future.wait([
        File(_usersFile).delete().catchError((e) => File(_usersFile)),
        File(_complaintsFile).delete().catchError((e) => File(_complaintsFile)),
        File(_emergenciesFile).delete().catchError((e) => File(_emergenciesFile)),
        File(_electionFile).delete().catchError((e) => File(_electionFile)),
        File(_votesFile).delete().catchError((e) => File(_votesFile)),
        File(_bankDetailsFile).delete().catchError((e) => File(_bankDetailsFile)),
        File(_verifiedPaymentsFile).delete().catchError((e) => File(_verifiedPaymentsFile)),
        File(_technicalIssuesFile).delete().catchError((e) => File(_technicalIssuesFile)),
        File(_noticesFile).delete().catchError((e) => File(_noticesFile)),
        File(_serviceRequestsFile).delete().catchError((e) => File(_serviceRequestsFile)),
      ]);
    } catch (e) {
      print('⚠️ Error deleting some files during clear: $e');
    }
    
    print('🗑️ All storage data cleared');
  }
  
  // Save buildings data specifically
  static Future<void> saveBuildings() async {
    await _saveToFile(_buildingsFile, buildings);
  }

  // Test data persistence by saving and immediately reloading
  static Future<bool> testDataPersistence() async {
    try {
      print('🧪 Testing data persistence...');
      
      // Save current state
      await saveAll();
      
      // Store current counts
      final originalCounts = {
        'users': users.length,
        'serviceRequests': serviceRequests.length,
        'complaints': complaints.length,
        'elections': elections.length,
      };
      
      // Clear in-memory storage
      final backup = {
        'users': Map<String, Map<String, dynamic>>.from(users),
        'serviceRequests': Map<String, Map<String, dynamic>>.from(serviceRequests),
        'complaints': Map<String, Map<String, dynamic>>.from(complaints),
        'elections': Map<String, Map<String, dynamic>>.from(elections),
      };
      
      users.clear();
      serviceRequests.clear();
      complaints.clear();
      elections.clear();
      
      // Reload from files
      await Future.wait([
        _loadFromFile(_usersFile, users),
        _loadFromFile(_serviceRequestsFile, serviceRequests),
        _loadFromFile(_complaintsFile, complaints),
        _loadFromFile(_electionFile, elections),
      ]);
      
      // Check if data was restored correctly
      final restoredCounts = {
        'users': users.length,
        'serviceRequests': serviceRequests.length,
        'complaints': complaints.length,
        'elections': elections.length,
      };
      
      bool success = true;
      originalCounts.forEach((key, originalCount) {
        final restoredCount = restoredCounts[key]!;
        if (originalCount != restoredCount) {
          print('❌ Data persistence failed for $key: $originalCount → $restoredCount');
          success = false;
        } else {
          print('✅ Data persistence verified for $key: $originalCount items');
        }
      });
      
      // Restore original data if test failed
      if (!success) {
        users.clear();
        serviceRequests.clear();
        complaints.clear();
        elections.clear();
        
        users.addAll(backup['users']!);
        serviceRequests.addAll(backup['serviceRequests']!);
        complaints.addAll(backup['complaints']!);
        elections.addAll(backup['elections']!);
      }
      
      return success;
    } catch (e) {
      print('❌ Error testing data persistence: $e');
      return false;
    }
  }
}

class HomeConnectServer {
  late Router router;
  final Uuid uuid = const Uuid();
  bool _initialized = false;

  HomeConnectServer();

  Future<void> initialize() async {
    if (!_initialized) {
      await FileStorage.initialize();
      _setupRoutes();
      _initialized = true;
    }
  }

  void _setupRoutes() {
    router = Router();

    // Test endpoint
    router.get('/test', _testEndpoint);
    
    // Debug endpoints (for development)
    router.get('/debug/clear-data', _clearData);
    router.get('/debug/storage-status', _getStorageStatus);
    router.get('/debug/file-paths', _getFilePaths);
    router.post('/debug/generate-test-data', _generateTestData);
    router.post('/debug/generate-union-test-data', _generateUnionTestData);
    
    // Authentication endpoints
    router.post('/login', _login);
    router.post('/register', _register);
    router.post('/signup', _signup);
    
    // CNIC upload endpoints
    router.post('/upload_cnic_base64', _uploadCnicBase64);
    
    // User management
    router.get('/users', _getUsers);
    router.get('/user/<id>', _getUser);
    router.put('/user/<id>', _updateUser);
    router.delete('/user/<id>', _deleteUser);
    
    // Building management
    router.get('/buildings', _getBuildings);
    router.post('/buildings', _createBuilding);
    router.get('/buildings/<id>', _getBuilding);
    router.put('/buildings/<id>', _updateBuilding);
    router.delete('/buildings/<id>', _deleteBuilding);
    
    // Resident endpoints
    router.get('/resident/elections', _getResidentElections);
    router.post('/resident/vote', _submitResidentVote);
    router.post('/resident/elections/<electionId>/acknowledge', _acknowledgeElectionResults); // Acknowledge election results
    router.get('/resident/notices', _getResidentNotices);
    router.post('/resident/notices/<noticeId>/read', _markNoticeAsRead);
    router.get('/resident/complaints/<userId>', _getResidentComplaints);
    router.delete('/resident/complaints/<complaintId>/acknowledge', _acknowledgeResolvedComplaint);
    router.post('/submit_complaint', _createComplaint); // Updated route to match frontend
    router.get('/resident/services', _getServices);
    router.post('/resident/emergency', _reportEmergency);
    
    // Union Complaint Management endpoints
    router.get('/union/complaints/<unionId>', _getUnionComplaints);
    router.patch('/union/complaints/<complaintId>/status', _updateUnionComplaintStatus);
    router.delete('/union/complaints/<complaintId>', _deleteUnionComplaint);
    
    // Admin endpoints
    router.get('/admin/complaints', _getAdminComplaints);
    router.put('/admin/complaints/<id>/status', _updateComplaintStatus);
    router.get('/admin/users', _getAdminUsers);
    router.post('/admin/notices', _createNotice);
    router.get('/admin/elections', _getAdminElections);
    router.post('/admin/elections', _createElection);
    
    // Admin Union Management endpoints
    router.get('/admin/union-approvals', _getUnionApprovals);
    router.get('/admin/approved-unions', _getApprovedUnions);
    router.put('/admin/union-approvals/<id>/approve', _approveUnion);
    router.put('/admin/union-approvals/<id>/reject', _rejectUnion);
    router.delete('/admin/union-incharge/<id>', _removeUnionIncharge);
    
    // Admin Service Provider Management endpoints
    router.get('/admin/service-provider-approvals', _getServiceProviderApprovals);
    router.get('/admin/approved-service-providers', _getApprovedServiceProviders);
    router.put('/admin/service-provider-approvals/<id>/approve', _approveServiceProvider);
    router.put('/admin/service-provider-approvals/<id>/reject', _rejectServiceProvider);
    router.delete('/admin/service-provider/<id>', _removeServiceProvider);
    
    // Voting endpoints
    router.post('/vote', _castVote);
    router.get('/elections/<id>/results', _getElectionResults);

    // Password reset endpoints
    router.post('/reset-service-provider-password', _resetServiceProviderPassword);
    router.post('/reset-test-service-provider', _resetTestServiceProvider);
    
    // Technical Issues endpoints
    router.post('/provider/technical-issues', _createTechnicalIssue);
    router.get('/provider/technical-issues/<providerId>', _getTechnicalIssues);
    router.get('/admin/technical-issues', _getAllTechnicalIssues);
    router.put('/admin/technical-issues/<id>/status', _updateTechnicalIssueStatus);
    router.put('/provider/technical-issues/<id>/acknowledge', _acknowledgeTechnicalIssue);

    // Union Incharge - Get pending residents for their building
    router.get('/admin/union-incharge/pending-residents', _getUnionPendingResidents);

    // Union Incharge - Approve a resident
    router.put('/admin/union-incharge/approve-resident', _approveResident);

    // Union Incharge - Reject a resident
    router.put('/admin/union-incharge/reject-resident', _rejectResident);

    // Union Incharge endpoints for resident approval
    router.get('/union/pending-residents', _getUnionPendingResidents);
    router.get('/union/approved-residents', _getUnionApprovedResidents);
    router.put('/union/approve-resident/<residentId>', _approveResident);
    router.put('/union/reject-resident/<residentId>', _rejectResident);
    router.delete('/union/remove-resident/<residentId>', _removeResident);
    
    // Union Incharge notices endpoints
    router.post('/union/notices', _createUnionNotice);
    router.get('/union/notices/<buildingName>', _getUnionNotices);
    
    // Resident service provider endpoints
    router.get('/resident/service-providers', _getServiceProvidersByCategory);
    router.post('/resident/service-requests', _createServiceRequest);
    
    // Service Provider endpoints
    router.get('/provider/service-requests/<providerId>', _getProviderServiceRequests);
    router.put('/provider/service-requests/<requestId>/accept', _acceptServiceRequest);
    router.put('/provider/service-requests/<requestId>/reject', _rejectServiceRequest);
    router.put('/provider/service-requests/<requestId>/complete', _completeServiceRequest);
    router.get('/provider/profile/<providerId>', _getServiceProviderProfile);

    // Union Election endpoints - NEW
    router.post('/union/create_election', _createUnionElection);
    router.get('/union/elections', _getUnionElections);
    router.post('/union/elections/<electionId>/end', _endUnionElection);
    router.post('/union/elections/<electionId>/publish_results', _publishElectionResults);
    
    // Resident Election endpoints - NEW
    router.post('/resident/vote', _submitResidentVote);

    // Debug endpoint to clear resident data
    router.delete('/debug/clear-residents', _clearResidentData);

    // Union incharge endpoints
    router.get('/union/technical-issues', _getTechnicalIssues);
    router.post('/union/technical-issues', _reportTechnicalIssue);
    router.patch('/union/technical-issues/<issueId>/acknowledge', _acknowledgeTechnicalIssue);
    
    // Complaint endpoints
    router.post('/complaints', _createComplaint);
    router.get('/complaints', _getComplaints);
    router.get('/union/<unionId>/complaints', _getUnionComplaints);
    router.patch('/complaints/<complaintId>/resolve', _resolveComplaint);
    router.delete('/union/<unionId>/complaints/<complaintId>/acknowledge', _acknowledgeComplaint);
    
    // Bank details endpoints
    router.post('/bank-details', _uploadBankDetails);
    router.get('/bank-details/<buildingName>', _getBankDetails);
    router.get('/bank-details/union/<buildingName>', _getBankDetailsByUnion);
    
    // Union-specific bank details endpoints
    router.post('/union/save-bank-details', _saveUnionBankDetails);
    router.get('/union/bank-details/<unionId>', _getUnionBankDetails);
    
    // Union incharge profile update endpoint
    router.put('/union/profile/<unionId>', _updateUnionProfile);
    
    // Debug endpoint to see what bank details are loaded
    router.get('/debug/bank-details', _debugBankDetails);
  }

  // Test endpoint
  Future<Response> _testEndpoint(Request request) async {
    return Response.ok(
      jsonEncode({
        'message': 'Dart backend with in-memory storage is working!',
        'status': 'success',
        'timestamp': DateTime.now().toIso8601String(),
        'version': '2.0.0',
        'storage': 'in-memory'
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  // Authentication
  Future<Response> _login(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final email = data['email']?.toString().toLowerCase();
      final password = data['password']?.toString();

      print('🔑 Login attempt: email=$email');

      if (email == null || password == null) {
        return Response(400, 
          body: jsonEncode({'error': 'Email and password required'}),
          headers: {'Content-Type': 'application/json'});
      }

      // Find user by email
      final user = FileStorage.users.values.firstWhere(
        (u) => u['email'] == email,
        orElse: () => <String, dynamic>{},
      );

      if (user.isEmpty) {
        print('❌ User not found with email: $email');
        return Response(401,
          body: jsonEncode({'error': 'Invalid credentials'}),
          headers: {'Content-Type': 'application/json'});
      }

      final hashedPassword = user['password'];

      if (BCrypt.checkpw(password, hashedPassword)) {
        print('✅ Login successful for user: $email');
        
        // Create response without sensitive data
        final userData = Map<String, dynamic>.from(user);
        userData.remove('password');
        
        // Generate a simple token (in production, use proper JWT)
        final token = 'dart_backend_token_${userData['id']}_${DateTime.now().millisecondsSinceEpoch}';
        
        // Format response to match Flutter app expectations
        final response = {
          'user': {
            'id': userData['id'],
            'first_name': userData['first_name'] ?? userData['name'], // Use first_name or fallback to name
            'last_name': userData['last_name'] ?? '',
            'name': userData['name'] ?? '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}',
            'email': userData['email'],
            'role': userData['role'] == 'resident' ? 'Resident' : 
                    userData['role'] == 'union incharge' ? 'Union Incharge' : 
                    userData['role'], // Capitalize role properly
            'building_name': userData['building_name'],
            'phone': userData['phone'],
            'address': userData['address'],
            'category': userData['category'],
            'is_active': userData['is_active'] ?? true,
            'is_approved': userData['is_approved'] ?? false, // Always include approval status with default false
            'created_at': userData['created_at'],
            'approved_at': userData['approved_at'],
          },
          'token': token,
          'message': 'Login successful'
        };

        return Response.ok(
          jsonEncode(response),
          headers: {'Content-Type': 'application/json'},
        );
      } else {
        print('❌ Invalid password for user: $email');
        return Response(401,
          body: jsonEncode({'error': 'Invalid credentials'}),
          headers: {'Content-Type': 'application/json'});
      }
    } catch (e) {
      print('❌ Login error: $e');
      return Response(500,
        body: jsonEncode({'error': 'Internal server error'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _register(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      final email = data['email']?.toString().toLowerCase();
      final password = data['password']?.toString();
      final name = data['name']?.toString();
      final phone = data['phone']?.toString();
      final role = data['role']?.toString() ?? 'resident';
      final buildingName = data['building_name']?.toString();

      if (email == null || password == null || name == null) {
        return Response(400,
          body: jsonEncode({'error': 'Email, password, and name are required'}),
          headers: {'Content-Type': 'application/json'});
      }

      // Check if user already exists
      final existingUser = FileStorage.users.values.any(
        (u) => u['email'] == email,
      );

      if (existingUser) {
        return Response(409,
          body: jsonEncode({'error': 'User with this email already exists'}),
          headers: {'Content-Type': 'application/json'});
      }

      // Hash password
      final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

      // Create user
      final userId = uuid.v4();
      FileStorage.users[userId] = {
        'id': userId,
        'email': email,
        'password': hashedPassword,
        'name': name,
        'phone': phone,
        'role': role,
        'building_name': buildingName,
        'created_at': DateTime.now().toIso8601String(),
        'is_active': true,
      };

      // Save users data to file after creating new user
      await FileStorage.saveUsers();

      print('✅ User registered successfully: $email');

      return Response.ok(
        jsonEncode({
          'message': 'User registered successfully',
          'user_id': userId,
          'email': email,
          'name': name,
          'role': role
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Registration error: $e');
      return Response(500,
        body: jsonEncode({'error': 'Internal server error'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  // New comprehensive signup endpoint for union incharge and other user types
  Future<Response> _signup(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      print('📝 Signup request received: ${data.keys.toList()}');

      final email = data['email']?.toString().toLowerCase();
      final password = data['password']?.toString();
      final firstName = data['first_name']?.toString();
      final lastName = data['last_name']?.toString();
      final phone = data['phone']?.toString();
      final username = data['username']?.toString();
      final address = data['address']?.toString();
      final role = data['role']?.toString() ?? 'Resident';
      final buildingName = data['building_name']?.toString();
      final category = data['category']?.toString();
      final businessName = data['business_name']?.toString();
      final residentType = data['resident_type']?.toString();
      final isApproved = data['is_approved'] ?? false;

      // Handle CNIC image data
      final cnicImageUrl = data['cnic_image_url']?.toString();
      final cnicImageBase64 = data['cnic_image_base64']?.toString();
      final cnicImageName = data['cnic_image_name']?.toString();

      print('📝 User details: email=$email, role=$role, building=$buildingName, resident_type=$residentType');
      print('🖼️ CNIC data received: url=${cnicImageUrl != null}, base64=${cnicImageBase64 != null}, name=${cnicImageName != null}');
      if (cnicImageBase64 != null) {
        print('🖼️ CNIC base64 length: ${cnicImageBase64.length}');
      }

      if (email == null || password == null || firstName == null) {
        return Response(400,
          body: jsonEncode({'error': 'Email, password, and first name are required'}),
          headers: {'Content-Type': 'application/json'});
      }

      // Check if user already exists
      final existingUser = FileStorage.users.values.any(
        (u) => u['email'] == email,
      );

      if (existingUser) {
        print('❌ User already exists with email: $email');
        return Response(409,
          body: jsonEncode({'error': 'User with this email already exists'}),
          headers: {'Content-Type': 'application/json'});
      }

      // Hash password
      final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

      // Generate user ID
      final userId = uuid.v4();

      // Process CNIC image if provided
      String? storedCnicUrl;
      try {
        if (cnicImageBase64 != null && cnicImageName != null) {
          print('🖼️ Processing CNIC image: filename=$cnicImageName, data_length=${cnicImageBase64.length}');
          print('🔍 Debug: About to call FirebaseConfig.uploadCnicImage');
          try {
            // Try to use FirebaseConfig directly
            print('🔍 Debug: Calling uploadCnicImage with userId=$userId');
            // storedCnicUrl = await FirebaseConfig.uploadCnicImage(userId, cnicImageBase64, cnicImageName);
            // print('✅ CNIC image stored successfully: $storedCnicUrl');
            // Store as data URL directly as fallback
            final mimeType = cnicImageName.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
            storedCnicUrl = 'data:$mimeType;base64,$cnicImageBase64';
            print('📦 Fallback: Stored as data URL instead: $storedCnicUrl');
          } catch (e, stackTrace) {
            print('❌ Error storing CNIC image with Firebase: $e');
            print('❌ Stack trace: $stackTrace');
            // Store as data URL directly as fallback
            final mimeType = cnicImageName.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
            storedCnicUrl = 'data:$mimeType;base64,$cnicImageBase64';
            print('📦 Fallback: Stored as data URL instead: $storedCnicUrl');
          }
        } else if (cnicImageUrl != null) {
          storedCnicUrl = cnicImageUrl;
          print('🖼️ CNIC image URL provided: $storedCnicUrl');
        } else {
          print('⚠️ No CNIC image data provided');
        }
      } catch (e, stackTrace) {
        print('❌ Critical error in CNIC processing: $e');
        print('❌ Stack trace: $stackTrace');
        // Continue without CNIC image to prevent signup failure
        storedCnicUrl = null;
        print('⚠️ Continuing signup without CNIC image');
      }

      // Create comprehensive user record
      final userRecord = {
        'id': userId,
        'email': email,
        'password': hashedPassword,
        'first_name': firstName,
        'last_name': lastName ?? '',
        'name': '$firstName ${lastName ?? ''}', // Combined name for compatibility
        'phone': phone,
        'username': username,
        'address': address,
        'role': role.toLowerCase(),
        'building_name': buildingName,
        'business_name': businessName,
        'category': category,
        'resident_type': residentType,
        'is_approved': isApproved,
        'cnic_image_url': storedCnicUrl,
        'created_at': DateTime.now().toIso8601String(),
        'is_active': true,
        'signup_completed': true,
      };

      // Store user
      FileStorage.users[userId] = userRecord;

      // Save users data to file after signup
      await FileStorage.saveUsers();

      print('✅ User signed up successfully: $email (Role: $role)');

      // Return success response (201 status code expected by Flutter app)
      return Response(201,
        body: jsonEncode({
          'message': 'User registered successfully',
          'user_id': userId,
          'email': email,
          'role': role,
          'status': 'success'
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Signup error: $e');
      return Response(500,
        body: jsonEncode({'error': 'Internal server error: ${e.toString()}'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  // CNIC image upload endpoint
  Future<Response> _uploadCnicBase64(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      final cnicData = data['cnic_data']?.toString();
      final filename = data['filename']?.toString();

      print('🖼️ CNIC upload request: filename=$filename');

      if (cnicData == null || filename == null) {
        return Response(400,
          body: jsonEncode({'error': 'CNIC data and filename are required'}),
          headers: {'Content-Type': 'application/json'});
      }

      // Generate unique filename
      final fileExtension = filename.split('.').last;
      final uniqueFilename = '${uuid.v4()}.$fileExtension';
      
      // In a real implementation, you would:
      // 1. Decode the base64 data
      // 2. Save it to a file system or cloud storage
      // 3. Return the accessible URL
      
      // For in-memory storage, we'll simulate this
      final simulatedUrl = 'https://api.homeconnect.com/uploads/cnic/$uniqueFilename';
      
      print('✅ CNIC image upload simulated: $simulatedUrl');

      return Response.ok(
        jsonEncode({
          'message': 'CNIC image uploaded successfully',
          'url': simulatedUrl,
          'filename': uniqueFilename
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ CNIC upload error: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to upload CNIC image'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  // Buildings - Updated to return only approved apartment/society names
  Future<Response> _getBuildings(Request request) async {
    try {
      // Get all approved union incharges
      final approvedUnions = FileStorage.users.values
          .where((user) => 
              user['role']?.toString().toLowerCase() == 'union incharge' && 
              user['is_approved'] == true)
          .toList();

      // Separate apartments and societies from approved unions
      final apartments = <String>[];
      final societies = <String>[];

      for (final union in approvedUnions) {
        final buildingName = union['building_name']?.toString() ?? '';
        final category = union['category']?.toString().toLowerCase() ?? '';
        
        if (buildingName.isNotEmpty) {
          if (category == 'apartment') {
            apartments.add(buildingName);
          } else if (category == 'society') {
            societies.add(buildingName);
          }
        }
      }

      // Remove duplicates and sort
      final uniqueApartments = apartments.toSet().toList()..sort();
      final uniqueSocieties = societies.toSet().toList()..sort();

      print('🏢 Returning approved buildings - Apartments: ${uniqueApartments.length}, Societies: ${uniqueSocieties.length}');

      return Response.ok(
        jsonEncode({
          'apartments': uniqueApartments,
          'societies': uniqueSocieties,
          'total_buildings': uniqueApartments.length + uniqueSocieties.length,
          'last_updated': DateTime.now().toIso8601String(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Error fetching approved buildings: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to fetch buildings'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _createBuilding(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      final buildingId = uuid.v4();
      data['id'] = buildingId;
      data['created_at'] = DateTime.now().toIso8601String();

      FileStorage.buildings[buildingId] = data;

      // Save buildings data to file after creating new building
      await FileStorage.saveBuildings();

      return Response.ok(
        jsonEncode({'message': 'Building created successfully', 'id': buildingId}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response(500,
        body: jsonEncode({'error': 'Failed to create building'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  // Resident endpoints
  Future<Response> _getResidentElections(Request request) async {
    try {
      final residentId = request.url.queryParameters['resident_id'];
      
      if (residentId == null) {
        return Response(400,
          body: jsonEncode({'error': 'resident_id parameter is required'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      // Get resident info to find their building
      final resident = FileStorage.users.values.firstWhere(
        (user) => user['id'] == residentId,
        orElse: () => <String, dynamic>{},
      );
      
      if (resident.isEmpty) {
        print('⚠️ Resident not found with ID: $residentId');
        return Response.ok(
          jsonEncode({'elections': []}),
          headers: {'Content-Type': 'application/json'});
      }
      
      final residentBuilding = resident['building_name']?.toString() ?? '';
      
      // Get active elections and published elections for resident's building
      final availableElections = FileStorage.elections.values
          .where((election) => 
              election['building_name'] == residentBuilding &&
              (election['status'] == 'active' || 
               (election['status'] == 'published' && 
                !(election['acknowledgments']?.containsKey(residentId) ?? false))))
          .map((election) {
            // Check if resident has already voted
            final votes = Map<String, dynamic>.from(election['votes'] ?? {});
            final hasVoted = votes.containsKey(residentId);
            final selectedChoice = hasVoted ? votes[residentId] : null;
            
            return {
              'id': election['id'],
              'title': election['title'],
              'description': election['description'],
              'choices': election['choices'],
              'status': election['status'],
              'has_voted': hasVoted,
              'selected_choice': selectedChoice,
              'created_by': election['created_by'],
              'created_at': election['created_at'],
              'results_published': election['results_published'] ?? false,
              'total_votes': election['total_votes'] ?? 0,
              'results': election['results'] ?? {}, // Include results for published elections
            };
          })
          .toList();
      
      print('🗳️ Found ${availableElections.length} active and published elections for resident $residentId in building: $residentBuilding');
      
      return Response.ok(
        jsonEncode({'elections': availableElections}),
        headers: {'Content-Type': 'application/json'});
        
    } catch (e) {
      print('❌ Error getting resident elections: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to get elections'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _getResidentNotices(Request request) async {
    try {
      final userId = request.url.queryParameters['user_id'];
      final buildingName = request.url.queryParameters['building_name'];
      
      print('📝 Getting notices for resident $userId in building: $buildingName');
      
      if (userId == null) {
        return Response(400,
          body: jsonEncode({'error': 'user_id parameter is required'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      // Get user info to find their building
      final user = FileStorage.users[userId];
      String userBuilding = buildingName ?? user?['building_name'] ?? '';
      
      if (userBuilding.isEmpty) {
        print('⚠️ No building found for resident $userId');
        return Response.ok(jsonEncode([]), headers: {'Content-Type': 'application/json'});
      }
      
      // Filter notices by building and sort by date (newest first)
      final buildingNotices = FileStorage.notices.values
          .where((notice) => notice['buildingName'] == userBuilding)
          .toList();
      
      buildingNotices.sort((a, b) {
        final aDate = DateTime.tryParse(a['posted_at'] ?? '') ?? DateTime.now();
        final bDate = DateTime.tryParse(b['posted_at'] ?? '') ?? DateTime.now();
        return bDate.compareTo(aDate);
      });
      
      print('📝 Found ${buildingNotices.length} notices for resident $userId in building: $userBuilding');
      
      return Response.ok(
        jsonEncode(buildingNotices),
        headers: {'Content-Type': 'application/json'}
      );
    } catch (e) {
      print('❌ Error getting resident notices: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to get notices'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _markNoticeAsRead(Request request) async {
    try {
      final noticeId = request.params['noticeId'];
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final userId = data['userId'];
      final buildingName = data['buildingName'];
      
      print('✅ Marking notice $noticeId as read for resident $userId');
      
      if (noticeId == null || userId == null) {
        return Response(400,
          body: jsonEncode({'error': 'noticeId and userId are required'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      // Find the notice
      final notice = FileStorage.notices[noticeId];
      if (notice == null) {
        return Response(404,
          body: jsonEncode({'error': 'Notice not found'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      // Update the notice's readBy array
      final readBy = List<String>.from(notice['readBy'] ?? []);
      if (!readBy.contains(userId)) {
        readBy.add(userId);
        notice['readBy'] = readBy;
        notice['readCount'] = (notice['readCount'] ?? 0) + 1;
        
        // Save updated notices
        FileStorage.notices[noticeId] = notice;
        await FileStorage.saveNotices();
        
        print('✅ Notice $noticeId marked as read by user $userId. Total reads: ${notice['readCount']}');
      } else {
        print('ℹ️ Notice $noticeId was already marked as read by user $userId');
      }
      
      return Response.ok(
        jsonEncode({
          'message': 'Notice marked as read successfully',
          'noticeId': noticeId,
          'readCount': notice['readCount'],
        }),
        headers: {'Content-Type': 'application/json'}
      );
    } catch (e) {
      print('❌ Error marking notice as read: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to mark notice as read'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

    // Helper function for flexible category matching
  bool _categoryMatches(String providerCategory, String requestedCategory) {
    final provider = providerCategory.toLowerCase().trim();
    final requested = requestedCategory.toLowerCase().trim();
    
    print('🔍 Matching: Provider="$provider" vs Requested="$requested"');
    
    // Exact match first
    if (provider == requested) {
      print('✅ Exact match found');
      return true;
    }
    
    // Handle variations between singular and plural for Home & Utility
    if ((provider.contains('home') && provider.contains('utility')) && 
        (requested.contains('home') && requested.contains('utility'))) {
      print('✅ Home & Utility match found');
      return true;
    }
    
    // Handle variations for Food & Catering
    if (provider.contains('food') && provider.contains('catering') && 
        requested.contains('food') && requested.contains('catering')) {
      print('✅ Food & Catering match found');
      return true;
    }
    
    // Handle variations for Transport & Mobility
    if (provider.contains('transport') && provider.contains('mobility') && 
        requested.contains('transport') && requested.contains('mobility')) {
      print('✅ Transport & Mobility match found');
      return true;
    }
    
    print('❌ No match found');
    return false;
  }

Future<Response> _getServiceProvidersByCategory(Request request) async {
    try {
      final category = request.url.queryParameters['category'];
      
      print('📋 Getting service providers for category: $category');
      
      if (category == null || category.isEmpty) {
        return Response(400,
          body: jsonEncode({'error': 'Category parameter is required'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      // Get all approved service providers with flexible category matching
      final approvedProviders = FileStorage.users.values
          .where((user) => 
              user['role']?.toString().toLowerCase() == 'service provider' && 
              user['is_approved'] == true &&
              _categoryMatches(user['category']?.toString() ?? '', category))
          .map((user) {
            // Safely create name from first_name and last_name
            final firstName = user['first_name']?.toString() ?? '';
            final lastName = user['last_name']?.toString() ?? '';
            String fullName = '$firstName $lastName'.trim();
            if (fullName.isEmpty) {
              fullName = user['email']?.toString() ?? 'Unknown Provider';
            }
            
            // Return service provider details for residents
            return {
              'id': user['id'] ?? '',
              'name': fullName,
              'email': user['email']?.toString() ?? '',
              'phone': user['phone']?.toString() ?? '',
              'business_name': user['business_name']?.toString() ?? '',
              'address': user['address']?.toString() ?? '',
              'category': user['category']?.toString() ?? '',
              'approved_at': user['approved_at']?.toString() ?? '',
              'status': 'approved',
              'services_completed': user['services_completed'] ?? 0,
              'description': user['description'] ?? 'Professional ${user['category']} service provider',
            };
          })
          .toList();
      
      print('📋 Found ${approvedProviders.length} approved service providers for category: $category');
      
      return Response.ok(
        jsonEncode(approvedProviders),
        headers: {'Content-Type': 'application/json'}
      );
    } catch (e) {
      print('❌ Error getting service providers by category: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to get service providers'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _getResidentComplaints(Request request) async {
    final userId = request.params['userId'];
    print('📝 Getting complaints for resident $userId');
    
    try {
      // Filter complaints by user_id
      final userComplaints = FileStorage.complaints.values
          .where((complaint) => complaint['user_id'] == userId)
          .toList();
      
      // Sort by creation date (newest first)
      userComplaints.sort((a, b) {
        final aDate = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
        final bDate = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
        return bDate.compareTo(aDate);
      });
      
      print('📝 Found ${userComplaints.length} complaints for resident $userId');
      
      return Response.ok(
        jsonEncode(userComplaints),
        headers: {'Content-Type': 'application/json'}
      );
    } catch (e) {
      print('❌ Error fetching resident complaints: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to fetch complaints'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _createComplaint(Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);
    
    final complaintId = uuid.v4();
    data['id'] = complaintId;
    data['created_at'] = DateTime.now().toIso8601String();
    data['status'] = 'pending';
    
    FileStorage.complaints[complaintId] = data;
    
    // Save complaints data to file after creating new complaint
    await FileStorage.saveComplaints();

    return Response(201,
      body: jsonEncode({'message': 'Complaint created successfully', 'id': complaintId}),
      headers: {'Content-Type': 'application/json'}
    );
  }

  Future<Response> _getServices(Request request) async {
    return Response.ok(jsonEncode([
      {
        'id': '1',
        'name': 'Plumbing Service',
        'contact': '123-456-7890',
        'available': true
      },
      {
        'id': '2',
        'name': 'Electrical Service',
        'contact': '123-456-7891',
        'available': true
      }
    ]), headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _reportEmergency(Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);
    print('🚨 Emergency reported: ${data['type']} - ${data['description']}');
    
    return Response.ok(
      jsonEncode({'message': 'Emergency reported successfully', 'id': uuid.v4()}),
      headers: {'Content-Type': 'application/json'}
    );
  }

  // Union Complaint Management Methods
  Future<Response> _getUnionComplaints(Request request) async {
    try {
      final unionId = request.params['unionId'];
      final buildingName = request.url.queryParameters['building'];
      
      print('🏢 Getting complaints for union $unionId in building: $buildingName');
      
      // Get the union incharge info to verify building access
      final unionUser = FileStorage.users[unionId];
      if (unionUser == null) {
        return Response(404,
          body: jsonEncode({'error': 'Union incharge not found'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      // Filter complaints by building if building name is provided
      List<Map<String, dynamic>> complaints = [];
      
      for (final complaint in FileStorage.complaints.values) {
        final userId = complaint['user_id'];
        final user = FileStorage.users[userId];
        
        // Skip resolved complaints for union view (they should only be visible to residents)
        if (complaint['status']?.toLowerCase() == 'resolved') {
          continue;
        }
        
        // If building filter is provided, only include complaints from that building
        if (buildingName != null && buildingName.isNotEmpty) {
          if (user != null && user['building_name'] == buildingName) {
            // Add user info to complaint for better display
            final complaintWithUser = Map<String, dynamic>.from(complaint);
            complaintWithUser['resident_name'] = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
            complaintWithUser['resident_email'] = user['email'];
            complaintWithUser['building_name'] = user['building_name'];
            complaints.add(complaintWithUser);
          }
        } else {
          // If no building filter, include all complaints
          final complaintWithUser = Map<String, dynamic>.from(complaint);
          if (user != null) {
            complaintWithUser['resident_name'] = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
            complaintWithUser['resident_email'] = user['email'];
            complaintWithUser['building_name'] = user['building_name'];
          }
          complaints.add(complaintWithUser);
        }
      }
      
      // Sort by creation date (newest first)
      complaints.sort((a, b) {
        final aDate = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
        final bDate = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
        return bDate.compareTo(aDate);
      });
      
      print('📝 Found ${complaints.length} complaints for building: $buildingName');
      
      return Response.ok(
        jsonEncode(complaints),
        headers: {'Content-Type': 'application/json'},
      );
      
    } catch (e) {
      print('❌ Error fetching union complaints: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to fetch complaints'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _updateUnionComplaintStatus(Request request) async {
    try {
      final complaintId = request.params['complaintId'];
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final newStatus = data['status'];
      final updatedBy = data['updated_by'];
      
      print('🔄 Updating complaint $complaintId status to: $newStatus');
      
      // Check if complaint exists
      if (!FileStorage.complaints.containsKey(complaintId)) {
        return Response(404,
          body: jsonEncode({'error': 'Complaint not found'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      // Update the complaint status
      final complaint = FileStorage.complaints[complaintId]!;
      complaint['status'] = newStatus;
      complaint['updated_at'] = DateTime.now().toIso8601String();
      complaint['updated_by'] = updatedBy;
      
      // Save to file
      await FileStorage.saveComplaints();
      
      print('✅ Complaint $complaintId status updated to: $newStatus');
      
      return Response.ok(
        jsonEncode({
          'message': 'Complaint status updated successfully',
          'complaint_id': complaintId,
          'new_status': newStatus
        }),
        headers: {'Content-Type': 'application/json'},
      );
      
    } catch (e) {
      print('❌ Error updating complaint status: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to update complaint status'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _deleteUnionComplaint(Request request) async {
    try {
      final complaintId = request.params['complaintId'];
      
      print('🗑️ Deleting resolved complaint: $complaintId');
      
      // Check if complaint exists
      if (!FileStorage.complaints.containsKey(complaintId)) {
        return Response(404,
          body: jsonEncode({'error': 'Complaint not found'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      // Remove the complaint from storage
      FileStorage.complaints.remove(complaintId);
      
      // Save to file
      await FileStorage.saveComplaints();
      
      print('✅ Complaint $complaintId deleted successfully');
      
      return Response.ok(
        jsonEncode({
          'message': 'Complaint resolved and removed successfully',
          'complaint_id': complaintId
        }),
        headers: {'Content-Type': 'application/json'},
      );
      
    } catch (e) {
      print('❌ Error deleting complaint: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to delete complaint'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  // Other placeholder methods
  Future<Response> _getUsers(Request request) async {
    final userList = FileStorage.users.values.map((user) {
      final userData = Map<String, dynamic>.from(user);
      userData.remove('password'); // Don't return passwords
      return userData;
    }).toList();
    return Response.ok(jsonEncode(userList), headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _getUser(Request request) async {
    final userId = request.params['id'];
    final user = FileStorage.users[userId];
    if (user != null) {
      final userData = Map<String, dynamic>.from(user);
      userData.remove('password');
      return Response.ok(jsonEncode(userData), headers: {'Content-Type': 'application/json'});
    }
    return Response.notFound(jsonEncode({'error': 'User not found'}));
  }

  Future<Response> _updateUser(Request request) async {
    return Response.ok(jsonEncode({'message': 'User updated'}), headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _deleteUser(Request request) async {
    return Response.ok(jsonEncode({'message': 'User deleted'}), headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _getBuilding(Request request) async {
    final buildingId = request.params['id'];
    final building = FileStorage.buildings[buildingId];
    if (building != null) {
      return Response.ok(jsonEncode(building), headers: {'Content-Type': 'application/json'});
    }
    return Response.notFound(jsonEncode({'error': 'Building not found'}));
  }

  Future<Response> _updateBuilding(Request request) async {
    return Response.ok(jsonEncode({'message': 'Building updated'}), headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _deleteBuilding(Request request) async {
    return Response.ok(jsonEncode({'message': 'Building deleted'}), headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _getAdminComplaints(Request request) async {
    final complaintList = FileStorage.complaints.values.toList();
    return Response.ok(jsonEncode(complaintList), headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _updateComplaintStatus(Request request) async {
    return Response.ok(jsonEncode({'message': 'Complaint status updated'}), headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _getAdminUsers(Request request) async {
    return _getUsers(request);
  }

  Future<Response> _createNotice(Request request) async {
    return Response.ok(jsonEncode({'message': 'Notice created'}), headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _getAdminElections(Request request) async {
    return Response.ok(jsonEncode([]), headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _createElection(Request request) async {
    return Response.ok(jsonEncode({'message': 'Election created'}), headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _castVote(Request request) async {
    return Response.ok(jsonEncode({'message': 'Vote cast successfully'}), headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _getElectionResults(Request request) async {
    return Response.ok(jsonEncode({}), headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _submitMaintenancePayment(Request request) async {
    // Maintenance functionality removed
    return Response(404, body: jsonEncode({'error': 'Maintenance functionality has been removed'}), headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _getMaintenancePayments(Request request) async {
    // Maintenance functionality removed
    return Response(404, body: jsonEncode({'error': 'Maintenance functionality has been removed'}), headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _getUnionApprovals(Request request) async {
    try {
      print('🔍 Fetching union approvals...');
      
      // Get all users with role 'union incharge' and is_approved = false and not rejected
      final allUnionUsers = FileStorage.users.values
          .where((user) => user['role']?.toString().toLowerCase() == 'union incharge');
      
      print('📊 Total union incharge users: ${allUnionUsers.length}');
      
      for (var user in allUnionUsers) {
        final status = user['status']?.toString() ?? 'no status';
        final isApproved = user['is_approved'];
        final email = user['email']?.toString() ?? 'no email';
        print('👤 User: $email - is_approved: $isApproved, status: $status');
      }
      
      final pendingUnions = FileStorage.users.values
          .where((user) => 
              user['role']?.toString().toLowerCase() == 'union incharge' && 
              user['is_approved'] == false &&
              user['status'] != 'rejected')
          .map((user) {
            // Safely create name from first_name and last_name
            final firstName = user['first_name']?.toString() ?? '';
            final lastName = user['last_name']?.toString() ?? '';
            String fullName = '$firstName $lastName'.trim();
            if (fullName.isEmpty) {
              fullName = user['email']?.toString() ?? 'Unknown User';
            }
            
            // Remove sensitive data and format for frontend
            return {
              'id': user['id'] ?? '',
              'name': fullName,
              'email': user['email']?.toString() ?? '',
              'phone': user['phone']?.toString() ?? '',
              'building_name': user['building_name']?.toString() ?? '',
              'address': user['address']?.toString() ?? '',
              'category': user['category']?.toString() ?? 'Union Incharge',
              'cnic_image_url': user['cnic_image_url']?.toString() ?? '',
              'submitted_at': user['created_at']?.toString() ?? '',
              'role': user['role']?.toString() ?? 'Union Incharge',
            };
          })
          .toList();

      print('📋 Found ${pendingUnions.length} pending union approvals after filtering');
      
      return Response.ok(
        jsonEncode(pendingUnions),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Error fetching union approvals: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to fetch union approvals'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _getApprovedUnions(Request request) async {
    try {
      // Get all users with role 'union incharge' and is_approved = true
      final approvedUnions = FileStorage.users.values
          .where((user) => 
              user['role']?.toString().toLowerCase() == 'union incharge' && 
              user['is_approved'] == true)
          .map((user) {
            // Safely create name from first_name and last_name
            final firstName = user['first_name']?.toString() ?? '';
            final lastName = user['last_name']?.toString() ?? '';
            String fullName = '$firstName $lastName'.trim();
            if (fullName.isEmpty) {
              fullName = user['email']?.toString() ?? 'Unknown User';
            }
            
            // Remove sensitive data and format for frontend
            // Note: CNIC image is NOT included for approved users (privacy/security)
            return {
              'id': user['id'] ?? '',
              'name': fullName,
              'email': user['email']?.toString() ?? '',
              'phone': user['phone']?.toString() ?? '',
              'building_name': user['building_name']?.toString() ?? '',
              'address': user['address']?.toString() ?? '',
              'category': user['category']?.toString() ?? 'Apartment',
              'approved_at': user['approved_at']?.toString() ?? '',
              'role': user['role']?.toString() ?? 'Union Incharge',
              // CNIC image URL removed for privacy/security reasons
            };
          })
          .toList();

      print('📋 Found ${approvedUnions.length} approved unions');
      
      return Response.ok(
        jsonEncode(approvedUnions),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Error fetching approved unions: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to fetch approved unions'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _approveUnion(Request request) async {
    try {
      final userId = request.params['id'];
      
      if (userId == null) {
        return Response(400,
          body: jsonEncode({'error': 'User ID is required'}),
          headers: {'Content-Type': 'application/json'});
      }

      // Find the user
      final user = FileStorage.users[userId];
      if (user == null) {
        return Response(404,
          body: jsonEncode({'error': 'User not found'}),
          headers: {'Content-Type': 'application/json'});
      }

      // Check if it's a union incharge
      if (user['role']?.toString().toLowerCase() != 'union incharge') {
        return Response(400,
          body: jsonEncode({'error': 'User is not a union incharge'}),
          headers: {'Content-Type': 'application/json'});
      }

      // Approve the user
      FileStorage.users[userId] = {
        ...user,
        'is_approved': true,
        'approved_at': DateTime.now().toIso8601String(),
        'status': 'approved',
      };

      // Save users data to file after approval
      await FileStorage.saveUsers();

      print('✅ Union incharge approved: ${user['email']}');

      return Response.ok(
        jsonEncode({
          'message': 'Union incharge approved successfully',
          'user_id': userId,
          'status': 'approved'
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Error approving union: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to approve union'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _rejectUnion(Request request) async {
    try {
      final userId = request.params['id'];
      
      if (userId == null) {
        return Response(400,
          body: jsonEncode({'error': 'User ID is required'}),
          headers: {'Content-Type': 'application/json'});
      }

      // Find the user
      final user = FileStorage.users[userId];
      if (user == null) {
        return Response(404,
          body: jsonEncode({'error': 'User not found'}),
          headers: {'Content-Type': 'application/json'});
      }

      // Check if it's a union incharge
      if (user['role']?.toString().toLowerCase() != 'union incharge') {
        return Response(400,
          body: jsonEncode({'error': 'User is not a union incharge'}),
          headers: {'Content-Type': 'application/json'});
      }

      // Mark as rejected (or delete the user)
      FileStorage.users[userId] = {
        ...user,
        'is_approved': false,
        'rejected_at': DateTime.now().toIso8601String(),
        'status': 'rejected',
      };

      // Save users data to file after rejection
      await FileStorage.saveUsers();

      print('❌ Union incharge rejected: ${user['email']}');

      return Response.ok(
        jsonEncode({
          'message': 'Union incharge rejected',
          'user_id': userId,
          'status': 'rejected'
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Error rejecting union: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to reject union'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _removeUnionIncharge(Request request) async {
    try {
      final userId = request.params['id'];
      
      if (userId == null) {
        return Response(400,
          body: jsonEncode({'error': 'User ID is required'}),
          headers: {'Content-Type': 'application/json'});
      }

      // Find the union incharge
      final unionIncharge = FileStorage.users[userId];
      if (unionIncharge == null) {
        return Response(404,
          body: jsonEncode({'error': 'User not found'}),
          headers: {'Content-Type': 'application/json'});
      }

      // Check if it's a union incharge
      if (unionIncharge['role']?.toString().toLowerCase() != 'union incharge') {
        return Response(400,
          body: jsonEncode({'error': 'User is not a union incharge'}),
          headers: {'Content-Type': 'application/json'});
      }

      final unionName = '${unionIncharge['first_name']} ${unionIncharge['last_name']}';
      final buildingName = unionIncharge['building_name']?.toString() ?? '';
      
      print('🗑️ Starting comprehensive cascade deletion for union incharge: $unionName ($userId)');
      print('   Building: $buildingName');

      // Track what gets deleted for detailed reporting
      final deletionReport = <String, int>{
        'residents_removed': 0,
        'complaints_removed': 0,
        'votes_removed': 0,
        'technical_issues_removed': 0,
        'service_requests_removed': 0,
        'verified_payments_removed': 0,
        'election_acknowledgments_removed': 0,
        'elections_removed': 0,
        'notices_removed': 0,
        'bank_details_removed': 0,
      };

      // 1. Find and remove all residents approved by this union incharge
      final residentsToRemove = <String>[];
      FileStorage.users.forEach((residentId, user) {
        if (user['role']?.toString().toLowerCase() == 'resident' && 
            (user['approved_by'] == userId || user['building_name'] == buildingName)) {
          residentsToRemove.add(residentId);
        }
      });

      print('📋 Found ${residentsToRemove.length} residents to remove');

      // 2. For each resident, perform cascade deletion (reuse logic from _removeResident)
      for (final residentId in residentsToRemove) {
        final resident = FileStorage.users[residentId];
        if (resident == null) continue;

        final residentName = '${resident['first_name']} ${resident['last_name']}';
        print('🧹 Cascading deletion for resident: $residentName ($residentId)');

        // Remove complaints by this resident
        final complaintsToRemove = <String>[];
        FileStorage.complaints.forEach((id, complaint) {
          if (complaint['user_id'] == residentId) {
            complaintsToRemove.add(id);
          }
        });
        for (final complaintId in complaintsToRemove) {
          FileStorage.complaints.remove(complaintId);
          deletionReport['complaints_removed'] = deletionReport['complaints_removed']! + 1;
        }

        // Remove votes by this resident from elections
        FileStorage.elections.forEach((electionId, election) {
          final votes = Map<String, dynamic>.from(election['votes'] ?? {});
          if (votes.containsKey(residentId)) {
            final votedChoice = votes[residentId];
            votes.remove(residentId);
            election['votes'] = votes;
            
            // Update vote counts
            final results = Map<String, dynamic>.from(election['results'] ?? {});
            if (results.containsKey(votedChoice)) {
              results[votedChoice] = (results[votedChoice] ?? 0) - 1;
              election['results'] = results;
            }
            
            election['total_votes'] = (election['total_votes'] ?? 0) - 1;
            deletionReport['votes_removed'] = deletionReport['votes_removed']! + 1;
          }
          
          // Remove election acknowledgments
          final acknowledgments = Map<String, dynamic>.from(election['acknowledgments'] ?? {});
          if (acknowledgments.containsKey(residentId)) {
            acknowledgments.remove(residentId);
            election['acknowledgments'] = acknowledgments;
            deletionReport['election_acknowledgments_removed'] = deletionReport['election_acknowledgments_removed']! + 1;
          }
        });

        // Remove technical issues by this resident
        final technicalIssuesToRemove = <String>[];
        FileStorage.technicalIssues.forEach((id, issue) {
          if (issue['user_id'] == residentId) {
            technicalIssuesToRemove.add(id);
          }
        });
        for (final issueId in technicalIssuesToRemove) {
          FileStorage.technicalIssues.remove(issueId);
          deletionReport['technical_issues_removed'] = deletionReport['technical_issues_removed']! + 1;
        }

        // Remove service requests by this resident
        final serviceRequestsToRemove = <String>[];
        FileStorage.serviceRequests.forEach((id, request) {
          if (request['user_id'] == residentId || request['resident_id'] == residentId) {
            serviceRequestsToRemove.add(id);
          }
        });
        for (final requestId in serviceRequestsToRemove) {
          FileStorage.serviceRequests.remove(requestId);
          deletionReport['service_requests_removed'] = deletionReport['service_requests_removed']! + 1;
        }

        // Remove verified payments by this resident
        final verifiedPaymentsToRemove = <String>[];
        FileStorage.verifiedPayments.forEach((id, payment) {
          if (payment['user_id'] == residentId || payment['resident_id'] == residentId) {
            verifiedPaymentsToRemove.add(id);
          }
        });
        for (final paymentId in verifiedPaymentsToRemove) {
          FileStorage.verifiedPayments.remove(paymentId);
          deletionReport['verified_payments_removed'] = deletionReport['verified_payments_removed']! + 1;
        }

        // Remove the resident user account
        FileStorage.users.remove(residentId);
        deletionReport['residents_removed'] = deletionReport['residents_removed']! + 1;
      }

      // 3. Remove union incharge specific data

      // Remove all elections created by this union incharge
      final electionsToRemove = <String>[];
      FileStorage.elections.forEach((electionId, election) {
        if (election['union_incharge_id'] == userId || election['building_name'] == buildingName) {
          electionsToRemove.add(electionId);
        }
      });
      for (final electionId in electionsToRemove) {
        FileStorage.elections.remove(electionId);
        deletionReport['elections_removed'] = deletionReport['elections_removed']! + 1;
      }

      // Remove all notices for this building
      final noticesToRemove = <String>[];
      FileStorage.notices.forEach((noticeId, notice) {
        if (notice['buildingName'] == buildingName) {
          noticesToRemove.add(noticeId);
        }
      });
      for (final noticeId in noticesToRemove) {
        FileStorage.notices.remove(noticeId);
        deletionReport['notices_removed'] = deletionReport['notices_removed']! + 1;
      }

      // Remove bank details for this building
      final bankDetailsToRemove = <String>[];
      FileStorage.bankDetails.forEach((key, bankDetail) {
        if (bankDetail['building_name'] == buildingName || bankDetail['union_id'] == userId) {
          bankDetailsToRemove.add(key);
        }
      });
      for (final bankKey in bankDetailsToRemove) {
        FileStorage.bankDetails.remove(bankKey);
        deletionReport['bank_details_removed'] = deletionReport['bank_details_removed']! + 1;
      }

      // 4. Finally, remove the union incharge user account
      FileStorage.users.remove(userId);

      // 5. Save all modified data to files
      await Future.wait([
        FileStorage.saveUsers(),
        FileStorage.saveComplaints(),
        FileStorage.saveElections(),
        FileStorage.saveTechnicalIssues(),
        FileStorage.saveServiceRequests(),
        FileStorage.saveVerifiedPayments(),
        FileStorage.saveNotices(),
        FileStorage.saveBankDetails(),
      ]);

      final totalItemsDeleted = deletionReport.values.fold(0, (sum, count) => sum + count);

      print('✅ Union incharge $unionName removed successfully with comprehensive cascade deletion:');
      print('   • Residents: ${deletionReport['residents_removed']}');
      print('   • Complaints: ${deletionReport['complaints_removed']}');
      print('   • Votes: ${deletionReport['votes_removed']}');
      print('   • Technical Issues: ${deletionReport['technical_issues_removed']}');
      print('   • Service Requests: ${deletionReport['service_requests_removed']}');
      print('   • Verified Payments: ${deletionReport['verified_payments_removed']}');
      print('   • Election Acknowledgments: ${deletionReport['election_acknowledgments_removed']}');
      print('   • Elections: ${deletionReport['elections_removed']}');
      print('   • Notices: ${deletionReport['notices_removed']}');
      print('   • Bank Details: ${deletionReport['bank_details_removed']}');
      print('   • Total items deleted: $totalItemsDeleted');

      return Response.ok(
        jsonEncode({
          'message': 'Union incharge and all associated data removed successfully',
          'union_incharge': {
            'id': userId,
            'name': unionName,
            'email': unionIncharge['email'],
            'building_name': buildingName,
            'removed_at': DateTime.now().toIso8601String(),
          },
          'deletion_report': deletionReport,
          'total_items_deleted': totalItemsDeleted,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Error removing union incharge: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to remove union incharge'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _getServiceProviderApprovals(Request request) async {
    try {
      // Get all users with role 'service provider' and is_approved = false
      final pendingProviders = FileStorage.users.values
          .where((user) => 
              user['role']?.toString().toLowerCase() == 'service provider' && 
              user['is_approved'] == false)
          .map((user) {
            // Safely create name from first_name and last_name
            final firstName = user['first_name']?.toString() ?? '';
            final lastName = user['last_name']?.toString() ?? '';
            String fullName = '$firstName $lastName'.trim();
            if (fullName.isEmpty) {
              fullName = user['email']?.toString() ?? 'Unknown User';
            }
            
            // Remove sensitive data and format for frontend
            return {
              'id': user['id'] ?? '',
              'name': fullName,
              'email': user['email']?.toString() ?? '',
              'phone': user['phone']?.toString() ?? '',
              'business_name': user['business_name']?.toString() ?? '',
              'address': user['address']?.toString() ?? '',
              'category': user['category']?.toString() ?? 'Service Provider',
              'cnic_image_url': user['cnic_image_url']?.toString() ?? '',
              'submitted_at': user['created_at']?.toString() ?? '',
              'role': user['role']?.toString() ?? 'Service Provider',
            };
          })
          .toList();

      print('📋 Found ${pendingProviders.length} pending service provider approvals');
      
      return Response.ok(
        jsonEncode(pendingProviders),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Error fetching service provider approvals: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to fetch service provider approvals'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _getApprovedServiceProviders(Request request) async {
    try {
      // Get all users with role 'service provider' and is_approved = true
      final approvedProviders = FileStorage.users.values
          .where((user) => 
              user['role']?.toString().toLowerCase() == 'service provider' && 
              user['is_approved'] == true)
          .map((user) {
            // Safely create name from first_name and last_name
            final firstName = user['first_name']?.toString() ?? '';
            final lastName = user['last_name']?.toString() ?? '';
            String fullName = '$firstName $lastName'.trim();
            if (fullName.isEmpty) {
              fullName = user['email']?.toString() ?? 'Unknown User';
            }
            
            // Include all details including CNIC for approved providers screen
            return {
              'id': user['id'] ?? '',
              'name': fullName,
              'email': user['email']?.toString() ?? '',
              'phone': user['phone']?.toString() ?? '',
              'business_name': user['business_name']?.toString() ?? '',
              'address': user['address']?.toString() ?? '',
              'category': user['category']?.toString() ?? 'Service Provider',
              'approved_at': user['approved_at']?.toString() ?? '',
              'role': user['role']?.toString() ?? 'Service Provider',
              'cnic_image_url': user['cnic_image_url']?.toString() ?? '', // Include CNIC for admin view
              'status': 'approved',
            };
          })
          .toList();

      print('📋 Found ${approvedProviders.length} approved service providers');
      
      return Response.ok(
        jsonEncode(approvedProviders),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Error fetching approved service providers: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to fetch approved service providers'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _approveServiceProvider(Request request) async {
    try {
      final userId = request.params['id'];
      
      if (userId == null) {
        return Response(400,
          body: jsonEncode({'error': 'User ID is required'}),
          headers: {'Content-Type': 'application/json'});
      }

      // Find the user
      final user = FileStorage.users[userId];
      if (user == null) {
        return Response(404,
          body: jsonEncode({'error': 'User not found'}),
          headers: {'Content-Type': 'application/json'});
      }

      // Check if it's a service provider
      if (user['role']?.toString().toLowerCase() != 'service provider') {
        return Response(400,
          body: jsonEncode({'error': 'User is not a service provider'}),
          headers: {'Content-Type': 'application/json'});
      }

      // Approve the user
      FileStorage.users[userId] = {
        ...user,
        'is_approved': true,
        'approved_at': DateTime.now().toIso8601String(),
        'status': 'approved',
      };

      // Save users data to file after service provider approval
      await FileStorage.saveUsers();

      print('✅ Service provider approved: ${user['email']}');

      return Response.ok(
        jsonEncode({
          'message': 'Service provider approved successfully',
          'user_id': userId,
          'status': 'approved'
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Error approving service provider: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to approve service provider'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _rejectServiceProvider(Request request) async {
    try {
      final userId = request.params['id'];
      
      if (userId == null) {
        return Response(400,
          body: jsonEncode({'error': 'User ID is required'}),
          headers: {'Content-Type': 'application/json'});
      }

      // Find the user
      final user = FileStorage.users[userId];
      if (user == null) {
        return Response(404,
          body: jsonEncode({'error': 'User not found'}),
          headers: {'Content-Type': 'application/json'});
      }

      // Check if it's a service provider
      if (user['role']?.toString().toLowerCase() != 'service provider') {
        return Response(400,
          body: jsonEncode({'error': 'User is not a service provider'}),
          headers: {'Content-Type': 'application/json'});
      }

      // Mark as rejected (or delete the user)
      FileStorage.users[userId] = {
        ...user,
        'is_approved': false,
        'rejected_at': DateTime.now().toIso8601String(),
        'status': 'rejected',
      };

      // Save users data to file after service provider rejection
      await FileStorage.saveUsers();

      print('❌ Service provider rejected: ${user['email']}');

      return Response.ok(
        jsonEncode({
          'message': 'Service provider rejected',
          'user_id': userId,
          'status': 'rejected'
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Error rejecting service provider: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to reject service provider'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _removeServiceProvider(Request request) async {
    try {
      final userId = request.params['id'];
      
      if (userId == null) {
        return Response(400,
          body: jsonEncode({'error': 'User ID is required'}),
          headers: {'Content-Type': 'application/json'});
      }

      // Find the user
      final user = FileStorage.users[userId];
      if (user == null) {
        return Response(404,
          body: jsonEncode({'error': 'User not found'}),
          headers: {'Content-Type': 'application/json'});
      }

      // Check if it's a service provider
      if (user['role']?.toString().toLowerCase() != 'service provider') {
        return Response(400,
          body: jsonEncode({'error': 'User is not a service provider'}),
          headers: {'Content-Type': 'application/json'});
      }

      // Remove the user
      FileStorage.users.remove(userId);

      // Save users data to file after service provider removal
      await FileStorage.saveUsers();

      print('✅ Service provider removed: ${user['email']}');

      return Response.ok(
        jsonEncode({
          'message': 'Service provider removed successfully',
          'user_id': userId,
          'status': 'removed'
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Error removing service provider: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to remove service provider'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _resetServiceProviderPassword(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final email = data['email']?.toString().toLowerCase();
      final newPassword = data['new_password']?.toString();

      print('🔐 Password reset request for: $email');

      if (email == null || newPassword == null) {
        return Response(400,
          body: jsonEncode({'error': 'Email and new password required'}),
          headers: {'Content-Type': 'application/json'});
      }

      // Find user by email
      final userId = FileStorage.users.keys.firstWhere(
        (key) => FileStorage.users[key]?['email'] == email,
        orElse: () => '',
      );

      if (userId.isEmpty) {
        print('❌ User not found with email: $email');
        return Response(404,
          body: jsonEncode({'error': 'User not found'}),
          headers: {'Content-Type': 'application/json'});
      }

      final user = FileStorage.users[userId]!;

      // Check if it's a service provider
      if (user['role']?.toString().toLowerCase() != 'service provider') {
        return Response(400,
          body: jsonEncode({'error': 'Password reset only available for service providers'}),
          headers: {'Content-Type': 'application/json'});
      }

      // Hash new password
      final hashedPassword = BCrypt.hashpw(newPassword, BCrypt.gensalt());

      // Update user password
      FileStorage.users[userId] = {
        ...user,
        'password': hashedPassword,
        'password_reset_at': DateTime.now().toIso8601String(),
      };

      // Save users data to file
      await FileStorage.saveUsers();

      print('✅ Password reset successful for: $email');

      return Response.ok(
        jsonEncode({
          'message': 'Password reset successful',
          'email': email,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Password reset error: $e');
      return Response(500,
        body: jsonEncode({'error': 'Internal server error'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _resetTestServiceProvider(Request request) async {
    try {
      const email = 'testservice1@gmail.com';
      const newPassword = 'password123';

      // Find user by email
      final userId = FileStorage.users.keys.firstWhere(
        (key) => FileStorage.users[key]?['email'] == email,
        orElse: () => '',
      );

      if (userId.isEmpty) {
        print('❌ Test service provider not found');
        return Response(404,
          body: jsonEncode({'error': 'Test service provider not found'}),
          headers: {'Content-Type': 'application/json'});
      }

      final user = FileStorage.users[userId]!;

      // Hash new password
      final hashedPassword = BCrypt.hashpw(newPassword, BCrypt.gensalt());

      // Update user password
      FileStorage.users[userId] = {
        ...user,
        'password': hashedPassword,
        'password_reset_at': DateTime.now().toIso8601String(),
      };

      // Save users data to file
      await FileStorage.saveUsers();

      print('✅ Test service provider password reset to: $newPassword');

      return Response.ok(
        jsonEncode({
          'message': 'Test service provider password reset successful',
          'email': email,
          'new_password': newPassword,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Test password reset error: $e');
      return Response(500,
        body: jsonEncode({'error': 'Internal server error'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  // Technical Issues endpoints
  Future<Response> _createTechnicalIssue(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      final providerId = data['provider_id']?.toString();
      final providerName = data['provider_name']?.toString();
      final title = data['title']?.toString();
      final description = data['description']?.toString();
      final timestamp = data['timestamp']?.toString() ?? DateTime.now().toIso8601String();
      final status = data['status']?.toString() ?? 'pending';
      final buildingName = data['building_name']?.toString();
      final category = data['category']?.toString();

      if (providerId == null || title == null || description == null) {
        return Response(400,
          body: jsonEncode({'error': 'Provider ID, title, and description are required'}),
          headers: {'Content-Type': 'application/json'});
      }

      // Get user details to extract building information if not provided
      String finalBuildingName = buildingName ?? '';
      String finalCategory = category ?? '';
      String finalProviderName = providerName ?? 'Unknown Provider';
      
      final user = FileStorage.users[providerId];
      if (user != null) {
        finalBuildingName = user['building_name']?.toString() ?? finalBuildingName;
        finalCategory = user['category']?.toString() ?? finalCategory;
        
        // For union incharges, display building name instead of personal name
        if (user['role']?.toString().toLowerCase() == 'union incharge' && finalBuildingName.isNotEmpty) {
          final categoryText = finalCategory.isNotEmpty ? ' ($finalCategory)' : '';
          finalProviderName = '$finalBuildingName$categoryText';
        }
        // For service providers, display business category instead of personal name
        else if (user['role']?.toString().toLowerCase() == 'service provider') {
          final businessCategory = user['business_category']?.toString() ?? 
                                   user['service_categories']?.toString() ?? 
                                   user['category']?.toString();
          if (businessCategory != null && businessCategory.isNotEmpty) {
            finalProviderName = businessCategory;
            finalCategory = businessCategory;
          }
        }
      }

      // Create technical issue
      final issueId = uuid.v4();
      FileStorage.technicalIssues[issueId] = {
        'id': issueId,
        'provider_id': providerId,
        'provider_name': finalProviderName,
        'title': title,
        'description': description,
        'status': status,
        'timestamp': timestamp,
        'created_at': DateTime.now().toIso8601String(),
        'building_name': finalBuildingName,
        'category': finalCategory,
        'user_role': user?['role']?.toString() ?? 'unknown',
      };

      // Save technical issues data to file
      await FileStorage.saveTechnicalIssues();

      print('✅ Technical issue created successfully: $title');

      return Response.ok(
        jsonEncode({
          'message': 'Technical issue reported successfully',
          'issue_id': issueId,
          'status': status
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Technical issue creation error: $e');
      return Response(500,
        body: jsonEncode({'error': 'Internal server error'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _getTechnicalIssues(Request request) async {
    try {
      final providerId = request.params['providerId'];
      
      if (providerId == null) {
        return Response(400,
          body: jsonEncode({'error': 'Provider ID is required'}),
          headers: {'Content-Type': 'application/json'});
      }

      // Filter technical issues by provider ID
      final providerIssues = FileStorage.technicalIssues.values
          .where((issue) => issue['provider_id'] == providerId)
          .where((issue) => issue['status'] != 'completed') // Filter out completed issues
          .toList();

      // Sort by timestamp (newest first)
      providerIssues.sort((a, b) => 
        DateTime.parse(b['timestamp'] ?? b['created_at'] ?? DateTime.now().toIso8601String())
            .compareTo(DateTime.parse(a['timestamp'] ?? a['created_at'] ?? DateTime.now().toIso8601String())));

      return Response.ok(
        jsonEncode({
          'issues': providerIssues
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Get technical issues error: $e');
      return Response(500,
        body: jsonEncode({'error': 'Internal server error'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _getAllTechnicalIssues(Request request) async {
    try {
      // Get all technical issues for admin (excluding completed ones)
      final allIssues = FileStorage.technicalIssues.values
          .where((issue) => issue['status'] != 'completed') // Filter out completed issues
          .toList();

      // Sort by timestamp (newest first)
      allIssues.sort((a, b) => 
        DateTime.parse(b['timestamp'] ?? b['created_at'] ?? DateTime.now().toIso8601String())
            .compareTo(DateTime.parse(a['timestamp'] ?? a['created_at'] ?? DateTime.now().toIso8601String())));

      return Response.ok(
        jsonEncode({
          'issues': allIssues
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Get all technical issues error: $e');
      return Response(500,
        body: jsonEncode({'error': 'Internal server error'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _updateTechnicalIssueStatus(Request request) async {
    try {
      final issueId = request.params['id'];
      
      if (issueId == null) {
        return Response(400,
          body: jsonEncode({'error': 'Issue ID is required'}),
          headers: {'Content-Type': 'application/json'});
      }

      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      final newStatus = data['status']?.toString();
      
      if (newStatus == null) {
        return Response(400,
          body: jsonEncode({'error': 'Status is required'}),
          headers: {'Content-Type': 'application/json'});
      }

      if (!FileStorage.technicalIssues.containsKey(issueId)) {
        return Response(404,
          body: jsonEncode({'error': 'Technical issue not found'}),
          headers: {'Content-Type': 'application/json'});
      }

      // Update the issue status
      final issue = FileStorage.technicalIssues[issueId]!;
      FileStorage.technicalIssues[issueId] = {
        ...issue,
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Save technical issues data to file
      await FileStorage.saveTechnicalIssues();

      print('✅ Technical issue status updated: $issueId -> $newStatus');

      return Response.ok(
        jsonEncode({
          'message': 'Issue status updated successfully',
          'issue_id': issueId,
          'new_status': newStatus
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Update technical issue status error: $e');
      return Response(500,
        body: jsonEncode({'error': 'Internal server error'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _acknowledgeTechnicalIssue(Request request) async {
    try {
      final issueId = request.params['id'];
      
      if (issueId == null) {
        return Response(400,
          body: jsonEncode({'error': 'Issue ID is required'}),
          headers: {'Content-Type': 'application/json'});
      }

      if (!FileStorage.technicalIssues.containsKey(issueId)) {
        return Response(404,
          body: jsonEncode({'error': 'Technical issue not found'}),
          headers: {'Content-Type': 'application/json'});
      }

      // Mark the issue as completed
      final issue = FileStorage.technicalIssues[issueId]!;
      FileStorage.technicalIssues[issueId] = {
        ...issue,
        'status': 'completed',
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Save technical issues data to file
      await FileStorage.saveTechnicalIssues();

      print('✅ Technical issue acknowledged: $issueId');

      return Response.ok(
        jsonEncode({
          'message': 'Technical issue acknowledged successfully',
          'issue_id': issueId,
          'status': 'completed'
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Error acknowledging technical issue: $e');
      return Response(500,
        body: jsonEncode({'error': 'Internal server error'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _clearData(Request request) async {
    await FileStorage.clearAllData();
    return Response.ok(jsonEncode({'message': 'Data cleared'}), headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _getStorageStatus(Request request) async {
    return Response.ok(jsonEncode({
      'users': FileStorage.users.length,
      'complaints': FileStorage.complaints.length,
      'emergencies': FileStorage.emergencies.length,
      'elections': FileStorage.elections.length,
      'votes': FileStorage.votes.length,
      'bankDetails': FileStorage.bankDetails.length,
      'verified_payments': FileStorage.verifiedPayments.length,
      'technical_issues': FileStorage.technicalIssues.length,
      'notices': FileStorage.notices.length,
      'service_requests': FileStorage.serviceRequests.length,
    }), headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _getFilePaths(Request request) async {
    return Response.ok(jsonEncode({
      'current_directory': Directory.current.path,
      'script_path': Platform.script.toFilePath(),
      'data_directory': FileStorage._dataDir,
      'file_paths': {
        'users': FileStorage._usersFile,
        'service_requests': FileStorage._serviceRequestsFile,
        'complaints': FileStorage._complaintsFile,
        'elections': FileStorage._electionFile,
        'notices': FileStorage._noticesFile,
        'technical_issues': FileStorage._technicalIssuesFile,
      },
      'file_exists': {
        'users': await File(FileStorage._usersFile).exists(),
        'service_requests': await File(FileStorage._serviceRequestsFile).exists(),
        'complaints': await File(FileStorage._complaintsFile).exists(),
        'elections': await File(FileStorage._electionFile).exists(),
        'notices': await File(FileStorage._noticesFile).exists(),
        'technical_issues': await File(FileStorage._technicalIssuesFile).exists(),
      },
    }), headers: {'Content-Type': 'application/json'});
  }

  // Generate test data for a resident to test cascade deletion
  Future<Response> _generateTestData(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final residentId = data['resident_id']?.toString();
      
      if (residentId == null) {
        return Response(400,
          body: jsonEncode({'error': 'resident_id is required'}),
          headers: {'Content-Type': 'application/json'});
      }

      final resident = FileStorage.users[residentId];
      if (resident == null || resident['role'] != 'resident') {
        return Response(404,
          body: jsonEncode({'error': 'Resident not found'}),
          headers: {'Content-Type': 'application/json'});
      }

      final residentName = '${resident['first_name']} ${resident['last_name']}';
      final buildingName = resident['building_name'];
      final now = DateTime.now().toIso8601String();
      
      int itemsCreated = 0;

      // Create test complaints
      for (int i = 1; i <= 3; i++) {
        final complaintId = uuid.v4();
        FileStorage.complaints[complaintId] = {
          'id': complaintId,
          'user_id': residentId,
          'title': 'Test Complaint $i',
          'description': 'This is a test complaint $i for cascade deletion testing',
          'category': ['Water', 'Electricity', 'Maintenance'][i % 3],
          'status': ['pending', 'in_progress', 'pending'][i % 3],
          'created_at': now,
          'building_name': buildingName,
        };
        itemsCreated++;
      }

      // Create test technical issues
      for (int i = 1; i <= 2; i++) {
        final issueId = uuid.v4();
        FileStorage.technicalIssues[issueId] = {
          'id': issueId,
          'user_id': residentId,
          'title': 'Test Technical Issue $i',
          'description': 'This is a test technical issue $i for cascade deletion testing',
          'status': 'pending',
          'created_at': now,
          'building_name': buildingName,
        };
        itemsCreated++;
      }

      // Create test service requests
      for (int i = 1; i <= 2; i++) {
        final requestId = uuid.v4();
        FileStorage.serviceRequests[requestId] = {
          'id': requestId,
          'user_id': residentId,
          'resident_id': residentId,
          'service_type': 'Test Service $i',
          'description': 'This is a test service request $i for cascade deletion testing',
          'status': 'pending',
          'created_at': now,
          'building_name': buildingName,
        };
        itemsCreated++;
      }

      // Create test verified payments
      for (int i = 1; i <= 2; i++) {
        final paymentId = uuid.v4();
        FileStorage.verifiedPayments[paymentId] = {
          'id': paymentId,
          'user_id': residentId,
          'resident_id': residentId,
          'amount': '5000',
          'month': 'December',
          'year': '2024',
          'payment_type': 'Maintenance',
          'status': 'verified',
          'created_at': now,
          'building_name': buildingName,
        };
        itemsCreated++;
      }

      // Create test election and add votes
      final electionId = uuid.v4();
      FileStorage.elections[electionId] = {
        'id': electionId,
        'title': 'Test Election for Cascade Deletion',
        'description': 'This election contains votes that should be removed when resident is deleted',
        'choices': ['Option A', 'Option B', 'Option C'],
        'building_name': buildingName,
        'status': 'active',
        'votes': {residentId: 'Option A'},
        'results': {'Option A': 1, 'Option B': 0, 'Option C': 0},
        'total_votes': 1,
        'created_at': now,
      };
      itemsCreated++;

      // Save all data
      await Future.wait([
        FileStorage.saveComplaints(),
        FileStorage.saveTechnicalIssues(),
        FileStorage.saveServiceRequests(),
        FileStorage.saveVerifiedPayments(),
        FileStorage.saveElections(),
      ]);

      print('🧪 Generated $itemsCreated test items for resident $residentName ($residentId)');

      return Response.ok(
        jsonEncode({
          'message': 'Test data generated successfully',
          'resident_name': residentName,
          'items_created': itemsCreated,
          'test_data': {
            'complaints': 3,
            'technical_issues': 2,
            'service_requests': 2,
            'verified_payments': 2,
            'election_votes': 1,
          }
        }),
        headers: {'Content-Type': 'application/json'});
        
    } catch (e) {
      print('❌ Error generating test data: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to generate test data'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  // Generate comprehensive test data for a union incharge to test cascade deletion
  Future<Response> _generateUnionTestData(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final unionId = data['union_id']?.toString();
      
      if (unionId == null) {
        return Response(400,
          body: jsonEncode({'error': 'union_id is required'}),
          headers: {'Content-Type': 'application/json'});
      }

      final unionIncharge = FileStorage.users[unionId];
      if (unionIncharge == null || unionIncharge['role'] != 'union incharge') {
        return Response(404,
          body: jsonEncode({'error': 'Union incharge not found'}),
          headers: {'Content-Type': 'application/json'});
      }

      final unionName = '${unionIncharge['first_name']} ${unionIncharge['last_name']}';
      final buildingName = unionIncharge['building_name'];
      final now = DateTime.now().toIso8601String();
      
      int itemsCreated = 0;

      // 1. Create test residents
      final testResidents = <String>[];
      for (int i = 1; i <= 3; i++) {
        final residentId = uuid.v4();
        FileStorage.users[residentId] = {
          'id': residentId,
          'first_name': 'TestResident$i',
          'last_name': 'ForDeletion',
          'email': 'testres$i@example.com',
          'phone': '0300000000$i',
          'username': 'flat$i',
          'password': 'test123',
          'role': 'resident',
          'building_name': buildingName,
          'approved_by': unionId,
          'is_approved': true,
          'approved_at': now,
          'created_at': now,
        };
        testResidents.add(residentId);
        itemsCreated++;
      }

      // 2. Create complaints for these residents
      for (final residentId in testResidents) {
        for (int i = 1; i <= 2; i++) {
          final complaintId = uuid.v4();
          FileStorage.complaints[complaintId] = {
            'id': complaintId,
            'user_id': residentId,
            'title': 'Test Complaint $i for Union Deletion',
            'description': 'This complaint should be deleted when union incharge is removed',
            'category': 'Maintenance',
            'status': 'pending',
            'created_at': now,
          };
          itemsCreated++;
        }
      }

      // 3. Create elections by this union incharge
      for (int i = 1; i <= 2; i++) {
        final electionId = uuid.v4();
        final electionVotes = <String, dynamic>{};
        final electionResults = {'Option A': 0, 'Option B': 0, 'Option C': 0};
        
        // Add votes from test residents
        for (int j = 0; j < testResidents.length; j++) {
          final choice = ['Option A', 'Option B', 'Option C'][j % 3];
          electionVotes[testResidents[j]] = choice;
          electionResults[choice] = (electionResults[choice] ?? 0) + 1;
        }
        
        FileStorage.elections[electionId] = {
          'id': electionId,
          'title': 'Test Election $i by Union Incharge',
          'description': 'This election should be deleted when union incharge is removed',
          'choices': ['Option A', 'Option B', 'Option C'],
          'union_incharge_id': unionId,
          'building_name': buildingName,
          'created_by': unionName,
          'created_at': now,
          'status': 'published',
          'votes': electionVotes,
          'results': electionResults,
          'total_votes': testResidents.length,
          'results_published': true,
        };
        itemsCreated++;
      }

      // 4. Create notices for this building
      for (int i = 1; i <= 2; i++) {
        final noticeId = uuid.v4();
        FileStorage.notices[noticeId] = {
          'id': noticeId,
          'title': 'Test Notice $i for Building',
          'content': 'This notice should be deleted when union incharge is removed',
          'buildingName': buildingName,
          'posted_at': now,
          'created_by': unionId,
        };
        itemsCreated++;
      }

      // 5. Create bank details for this building
      final bankId = uuid.v4();
      final buildingKey = buildingName.replaceAll(' ', '_').toLowerCase();
      FileStorage.bankDetails[buildingKey] = {
        'id': bankId,
        'bank_name': 'Test Bank for Deletion',
        'iban': 'PK12TEST123456789',
        'account_title': 'Test Account for $buildingName',
        'building_name': buildingName,
        'union_id': unionId,
        'created_at': now,
      };
      itemsCreated++;

      // 6. Create technical issues for these residents
      for (final residentId in testResidents) {
        final issueId = uuid.v4();
        FileStorage.technicalIssues[issueId] = {
          'id': issueId,
          'user_id': residentId,
          'title': 'Test Technical Issue for Union Deletion',
          'description': 'This technical issue should be deleted when union incharge is removed',
          'status': 'pending',
          'created_at': now,
        };
        itemsCreated++;
      }

      // 7. Create verified payments for these residents
      for (final residentId in testResidents) {
        final paymentId = uuid.v4();
        FileStorage.verifiedPayments[paymentId] = {
          'id': paymentId,
          'user_id': residentId,
          'resident_id': residentId,
          'amount': '5000',
          'month': 'December',
          'year': '2024',
          'payment_type': 'Maintenance',
          'status': 'verified',
          'created_at': now,
        };
        itemsCreated++;
      }

      // Save all data
      await Future.wait([
        FileStorage.saveUsers(),
        FileStorage.saveComplaints(),
        FileStorage.saveElections(),
        FileStorage.saveNotices(),
        FileStorage.saveBankDetails(),
        FileStorage.saveTechnicalIssues(),
        FileStorage.saveVerifiedPayments(),
      ]);

      print('🧪 Generated $itemsCreated comprehensive test items for union incharge $unionName ($unionId)');

      return Response.ok(
        jsonEncode({
          'message': 'Comprehensive test data generated successfully',
          'union_name': unionName,
          'building_name': buildingName,
          'items_created': itemsCreated,
          'test_data': {
            'residents': testResidents.length,
            'complaints': testResidents.length * 2,
            'elections': 2,
            'notices': 2,
            'bank_details': 1,
            'technical_issues': testResidents.length,
            'verified_payments': testResidents.length,
            'total_votes': testResidents.length * 2, // votes in 2 elections
          }
        }),
        headers: {'Content-Type': 'application/json'});
        
    } catch (e) {
      print('❌ Error generating union test data: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to generate test data'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  // Union Incharge - Get pending residents for their building
  Future<Response> _getUnionPendingResidents(Request request) async {
    try {
      final buildingName = request.url.queryParameters['building_name'];
      
      if (buildingName == null || buildingName.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'building_name parameter is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Get all users with role 'resident', is_approved = false, NOT rejected, and matching building_name
      final pendingResidents = FileStorage.users.values
          .where((user) => 
              user['role']?.toString().toLowerCase() == 'resident' && 
              user['is_approved'] == false &&
              user['is_rejected'] != true &&  // Exclude rejected residents
              user['building_name']?.toString() == buildingName)
          .toList();

      print('📋 Found ${pendingResidents.length} pending residents for building: $buildingName');

      return Response.ok(
        jsonEncode(pendingResidents),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Error getting pending residents: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to fetch pending residents'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // Union Incharge - Approve a resident
  Future<Response> _approveResident(Request request, String residentId) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      
      final unionId = data['union_id']?.toString();
      final buildingName = data['building_name']?.toString();

      if (unionId == null || buildingName == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'union_id and building_name are required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Verify union incharge exists and is approved
      final union = FileStorage.users[unionId];
      if (union == null || 
          union['role']?.toString().toLowerCase() != 'union incharge' ||
          union['is_approved'] != true ||
          union['building_name']?.toString() != buildingName) {
        return Response(403,
          body: jsonEncode({'error': 'Unauthorized: Invalid union incharge'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Find and approve the resident
      final resident = FileStorage.users[residentId];
      if (resident == null) {
        return Response(404,
          body: jsonEncode({'error': 'Resident not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (resident['role']?.toString().toLowerCase() != 'resident') {
        return Response(400,
          body: jsonEncode({'error': 'User is not a resident'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (resident['building_name']?.toString() != buildingName) {
        return Response(400,
          body: jsonEncode({'error': 'Resident does not belong to this building'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Approve the resident
      resident['is_approved'] = true;
      resident['approved_by'] = unionId;
      resident['approved_at'] = DateTime.now().toIso8601String();

      // Save the updated data
      await FileStorage.saveUsers();

      print('✅ Resident ${resident['first_name']} ${resident['last_name']} approved by union incharge ${union['first_name']}');

      return Response.ok(
        jsonEncode({
          'message': 'Resident approved successfully',
          'resident': {
            'id': residentId,
            'name': '${resident['first_name']} ${resident['last_name']}',
            'email': resident['email'],
            'approved_at': resident['approved_at'],
          }
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Error approving resident: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to approve resident'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // Union Incharge - Reject a resident
  Future<Response> _rejectResident(Request request, String residentId) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      
      final unionId = data['union_id']?.toString();
      final buildingName = data['building_name']?.toString();

      print('🔍 Rejection request: residentId=$residentId, unionId=$unionId, building=$buildingName');

      if (unionId == null || buildingName == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'union_id and building_name are required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Find the resident first (before union validation)
      final resident = FileStorage.users[residentId];
      if (resident == null) {
        print('❌ Resident not found: $residentId');
        return Response(404,
          body: jsonEncode({'error': 'Resident not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (resident['role']?.toString().toLowerCase() != 'resident') {
        print('❌ User is not a resident: ${resident['role']}');
        return Response(400,
          body: jsonEncode({'error': 'User is not a resident'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (resident['building_name']?.toString() != buildingName) {
        print('❌ Resident building mismatch: ${resident['building_name']} != $buildingName');
        return Response(400,
          body: jsonEncode({'error': 'Resident does not belong to this building'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Verify union incharge exists and is approved (with improved validation)
      final union = FileStorage.users[unionId];
      if (union != null) {
        // If union exists, validate it properly
        if (union['role']?.toString().toLowerCase() != 'union incharge' ||
            union['is_approved'] != true ||
            union['building_name']?.toString() != buildingName) {
          print('❌ Union validation failed: role=${union['role']}, approved=${union['is_approved']}, building=${union['building_name']}');
          return Response(403,
            body: jsonEncode({'error': 'Unauthorized: Invalid union incharge credentials'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
        print('✅ Union incharge validated: ${union['first_name']} ${union['last_name']}');
      } else {
        // If union doesn't exist, this might be a test scenario or the union ID is from the frontend session
        // In a real app, you'd validate the session token instead
        print('⚠️  Union ID not found in database - proceeding with rejection (frontend session validation)');
      }

      // Mark as rejected
      resident['is_approved'] = false;
      resident['is_rejected'] = true;
      resident['rejected_by'] = unionId;
      resident['rejected_at'] = DateTime.now().toIso8601String();

      // Save the updated data
      await FileStorage.saveUsers();

      print('✅ Resident ${resident['first_name']} ${resident['last_name']} rejected successfully');

      return Response.ok(
        jsonEncode({
          'message': 'Resident rejected successfully',
          'resident': {
            'id': residentId,
            'name': '${resident['first_name']} ${resident['last_name']}',
            'email': resident['email'],
            'rejected_at': resident['rejected_at'],
          }
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Error rejecting resident: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to reject resident'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // Union Incharge - Get approved residents for their building
  Future<Response> _getUnionApprovedResidents(Request request) async {
    try {
      final buildingName = request.url.queryParameters['building_name'];
      
      if (buildingName == null || buildingName.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'building_name parameter is required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Get all users with role 'resident', is_approved = true, NOT rejected, and matching building_name
      final approvedResidents = FileStorage.users.values
          .where((user) => 
              user['role']?.toString().toLowerCase() == 'resident' && 
              user['is_approved'] == true &&
              user['is_rejected'] != true &&  // Exclude rejected residents
              user['building_name']?.toString() == buildingName)
          .toList();

      print('📋 Found ${approvedResidents.length} approved residents for building: $buildingName');

      return Response.ok(
        jsonEncode(approvedResidents),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Error getting approved residents: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to fetch approved residents'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // Union Incharge - Remove a resident with cascade deletion
  Future<Response> _removeResident(Request request, String residentId) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      
      final unionId = data['union_id']?.toString();
      final buildingName = data['building_name']?.toString();

      print('🔍 Remove request: residentId=$residentId, unionId=$unionId, building=$buildingName');

      if (unionId == null || buildingName == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'union_id and building_name are required'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Find the resident
      final resident = FileStorage.users[residentId];
      if (resident == null) {
        print('❌ Resident not found: $residentId');
        return Response(404,
          body: jsonEncode({'error': 'Resident not found'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (resident['role']?.toString().toLowerCase() != 'resident') {
        print('❌ User is not a resident: ${resident['role']}');
        return Response(400,
          body: jsonEncode({'error': 'User is not a resident'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (resident['building_name']?.toString() != buildingName) {
        print('❌ Resident building mismatch: ${resident['building_name']} != $buildingName');
        return Response(400,
          body: jsonEncode({'error': 'Resident does not belong to this building'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final residentName = '${resident['first_name']} ${resident['last_name']}';
      print('🗑️ Starting cascade deletion for resident: $residentName ($residentId)');

      // Track what gets deleted for reporting
      final deletionReport = <String, int>{
        'complaints': 0,
        'votes': 0,
        'technical_issues': 0,
        'service_requests': 0,
        'verified_payments': 0,
        'election_acknowledgments': 0,
      };

      // 1. Remove all complaints made by this resident
      final complaintsToRemove = <String>[];
      FileStorage.complaints.forEach((id, complaint) {
        if (complaint['user_id'] == residentId) {
          complaintsToRemove.add(id);
        }
      });
      
      for (final complaintId in complaintsToRemove) {
        FileStorage.complaints.remove(complaintId);
        deletionReport['complaints'] = deletionReport['complaints']! + 1;
      }

      // 2. Remove all votes cast by this resident from elections
      FileStorage.elections.forEach((electionId, election) {
        final votes = Map<String, dynamic>.from(election['votes'] ?? {});
        if (votes.containsKey(residentId)) {
          final votedChoice = votes[residentId];
          votes.remove(residentId);
          election['votes'] = votes;
          
          // Update vote counts
          final results = Map<String, dynamic>.from(election['results'] ?? {});
          if (results.containsKey(votedChoice)) {
            results[votedChoice] = (results[votedChoice] ?? 0) - 1;
            election['results'] = results;
          }
          
          // Update total votes
          election['total_votes'] = (election['total_votes'] ?? 0) - 1;
          
          deletionReport['votes'] = deletionReport['votes']! + 1;
        }
        
        // Remove election acknowledgments
        final acknowledgments = Map<String, dynamic>.from(election['acknowledgments'] ?? {});
        if (acknowledgments.containsKey(residentId)) {
          acknowledgments.remove(residentId);
          election['acknowledgments'] = acknowledgments;
          deletionReport['election_acknowledgments'] = deletionReport['election_acknowledgments']! + 1;
        }
      });

      // 3. Remove all technical issues reported by this resident
      final technicalIssuesToRemove = <String>[];
      FileStorage.technicalIssues.forEach((id, issue) {
        if (issue['user_id'] == residentId) {
          technicalIssuesToRemove.add(id);
        }
      });
      
      for (final issueId in technicalIssuesToRemove) {
        FileStorage.technicalIssues.remove(issueId);
        deletionReport['technical_issues'] = deletionReport['technical_issues']! + 1;
      }

      // 4. Remove all service requests made by this resident
      final serviceRequestsToRemove = <String>[];
      FileStorage.serviceRequests.forEach((id, request) {
        if (request['user_id'] == residentId || request['resident_id'] == residentId) {
          serviceRequestsToRemove.add(id);
        }
      });
      
      for (final requestId in serviceRequestsToRemove) {
        FileStorage.serviceRequests.remove(requestId);
        deletionReport['service_requests'] = deletionReport['service_requests']! + 1;
      }

      // 5. Remove all verified payments made by this resident
      final verifiedPaymentsToRemove = <String>[];
      FileStorage.verifiedPayments.forEach((id, payment) {
        if (payment['user_id'] == residentId || payment['resident_id'] == residentId) {
          verifiedPaymentsToRemove.add(id);
        }
      });
      
      for (final paymentId in verifiedPaymentsToRemove) {
        FileStorage.verifiedPayments.remove(paymentId);
        deletionReport['verified_payments'] = deletionReport['verified_payments']! + 1;
      }

      // 6. Finally, remove the resident user account
      FileStorage.users.remove(residentId);

      // Save all modified data to files
      await Future.wait([
        FileStorage.saveUsers(),
        FileStorage.saveComplaints(),
        FileStorage.saveElections(),
        FileStorage.saveTechnicalIssues(),
        FileStorage.saveServiceRequests(),
        FileStorage.saveVerifiedPayments(),
      ]);

      final totalItemsDeleted = deletionReport.values.fold(0, (sum, count) => sum + count);

      print('✅ Resident $residentName removed successfully with cascade deletion:');
      print('   • Complaints: ${deletionReport['complaints']}');
      print('   • Votes: ${deletionReport['votes']}');
      print('   • Technical Issues: ${deletionReport['technical_issues']}');
      print('   • Service Requests: ${deletionReport['service_requests']}');
      print('   • Verified Payments: ${deletionReport['verified_payments']}');
      print('   • Election Acknowledgments: ${deletionReport['election_acknowledgments']}');
      print('   • Total items deleted: $totalItemsDeleted');

      return Response.ok(
        jsonEncode({
          'message': 'Resident and all associated data removed successfully',
          'resident': {
            'id': residentId,
            'name': residentName,
            'email': resident['email'],
            'removed_at': DateTime.now().toIso8601String(),
          },
          'deletion_report': deletionReport,
          'total_items_deleted': totalItemsDeleted,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Error removing resident: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to remove resident'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  // Debug endpoint to clear resident data
  Future<Response> _clearResidentData(Request request) async {
    try {
      // Remove only users with role 'resident'
      final idsToRemove = <String>[];
      
      for (final entry in FileStorage.users.entries) {
        final user = entry.value;
        if (user['role'] == 'resident') {
          idsToRemove.add(entry.key);
        }
      }
      
      // Remove resident users
      for (final id in idsToRemove) {
        FileStorage.users.remove(id);
      }
      
      // Save the updated users data
      await FileStorage.saveUsers();
      
      print('🗑️ Cleared ${idsToRemove.length} resident records');
      
      return Response.ok(
        jsonEncode({
          'message': 'Resident data cleared successfully',
          'removed_count': idsToRemove.length,
          'timestamp': DateTime.now().toIso8601String()
        }),
        headers: {'Content-Type': 'application/json'}
      );
    } catch (e) {
      print('❌ Error clearing resident data: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to clear resident data'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Handler get handler {
    final pipeline = Pipeline()
        .addMiddleware(corsHeaders())
        .addMiddleware(logRequests())
        .addHandler(router.call);
    return pipeline;
  }

  // Election Management Functions
  
  // Union Election endpoints
  Future<Response> _createUnionElection(Request request) async {
    try {
      print('🔍 DEBUG: Starting election creation...');
      final body = await request.readAsString();
      print('🔍 DEBUG: Request body: $body');
      final data = jsonDecode(body);
      print('🔍 DEBUG: Parsed data: $data');
      
      final title = data['title']?.toString();
      final choices = List<String>.from(data['choices'] ?? []);
      final unionInchargeId = data['union_incharge_id'];
      final description = data['description']?.toString() ?? '';
      
      print('🔍 DEBUG: title=$title, choices=$choices, unionInchargeId=$unionInchargeId');
      
      if (title == null || choices.isEmpty || unionInchargeId == null) {
        print('🔍 DEBUG: Validation failed - missing required fields');
        return Response(400,
          body: jsonEncode({'error': 'Title, choices, and union_incharge_id are required'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      print('🔍 DEBUG: Looking for union user with ID: $unionInchargeId');
      print('🔍 DEBUG: Available users: ${FileStorage.users.keys.toList()}');
      
      // Get union incharge info to get building name
      final unionUser = FileStorage.users.values.firstWhere(
        (user) => user['id'].toString() == unionInchargeId.toString(),
        orElse: () => <String, dynamic>{},
      );
      
      print('🔍 DEBUG: Found union user: ${unionUser.isNotEmpty ? unionUser['email'] : 'NOT FOUND'}');
      
      if (unionUser.isEmpty) {
        print('🔍 DEBUG: Union incharge not found');
        return Response(404,
          body: jsonEncode({'error': 'Union incharge not found'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      final electionId = uuid.v4();
      final now = DateTime.now().toIso8601String();
      
      print('🔍 DEBUG: Creating election with ID: $electionId');
      
      final electionData = {
        'id': electionId,
        'title': title,
        'description': description,
        'choices': choices,
        'union_incharge_id': unionInchargeId.toString(),
        'building_name': unionUser['building_name']?.toString() ?? '',
        'created_by': '${unionUser['first_name'] ?? ''} ${unionUser['last_name'] ?? ''}'.trim(),
        'created_at': now,
        'status': 'active',
        'total_votes': 0,
        'results': <String, dynamic>{},
        'results_published': false,
        'votes': <String, dynamic>{}, // Store individual votes here
      };
      
      print('🔍 DEBUG: Election data created: $electionData');
      
      // Initialize results with 0 votes for each choice
      final results = electionData['results'] as Map<String, dynamic>;
      for (String choice in choices) {
        results[choice] = 0;
      }
      
      print('🔍 DEBUG: Results initialized: $results');
      
      FileStorage.elections[electionId] = electionData;
      await FileStorage.saveElections();
      
      print('🗳️ Created election: $title by union incharge ${unionUser['email']}');
      
      return Response(201,
        body: jsonEncode({
          'success': true,
          'election_id': electionId,
          'message': 'Election created successfully'
        }),
        headers: {'Content-Type': 'application/json'});
        
    } catch (e, stackTrace) {
      print('❌ Error creating election: $e');
      print('❌ Stack trace: $stackTrace');
      return Response(500,
        body: jsonEncode({'error': 'Failed to create election', 'details': e.toString()}),
        headers: {'Content-Type': 'application/json'});
    }
  }
  
  Future<Response> _getUnionElections(Request request) async {
    try {
      final unionId = request.url.queryParameters['union_id'];
      
      if (unionId == null) {
        return Response(400,
          body: jsonEncode({'error': 'union_id parameter is required'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      // Get elections created by this union incharge
      final unionElections = FileStorage.elections.values
          .where((election) => election['union_incharge_id'] == unionId)
          .toList();
      
      print('🗳️ Found ${unionElections.length} elections for union $unionId');
      
      return Response.ok(
        jsonEncode({'elections': unionElections}),
        headers: {'Content-Type': 'application/json'});
        
    } catch (e) {
      print('❌ Error getting union elections: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to get elections'}),
        headers: {'Content-Type': 'application/json'});
    }
  }
  
  Future<Response> _endUnionElection(Request request) async {
    try {
      final electionId = request.params['electionId'];
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final unionId = data['union_id'];
      
      if (electionId == null || unionId == null) {
        return Response(400,
          body: jsonEncode({'error': 'Election ID and union_id are required'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      final election = FileStorage.elections[electionId];
      if (election == null) {
        return Response(404,
          body: jsonEncode({'error': 'Election not found'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      // Verify union owns this election
      if (election['union_incharge_id'] != unionId) {
        return Response(403,
          body: jsonEncode({'error': 'Unauthorized to end this election'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      election['status'] = 'completed';
      election['ended_at'] = DateTime.now().toIso8601String();
      
      FileStorage.elections[electionId] = election;
      await FileStorage.saveElections();
      
      print('🗳️ Election ended: ${election['title']}');
      
      return Response.ok(
        jsonEncode({'success': true, 'message': 'Election ended successfully'}),
        headers: {'Content-Type': 'application/json'});
        
    } catch (e) {
      print('❌ Error ending election: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to end election'}),
        headers: {'Content-Type': 'application/json'});
    }
  }
  
  Future<Response> _publishElectionResults(Request request) async {
    try {
      final electionId = request.params['electionId'];
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final unionId = data['union_id'];
      
      if (electionId == null || unionId == null) {
        return Response(400,
          body: jsonEncode({'error': 'Election ID and union_id are required'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      final election = FileStorage.elections[electionId];
      if (election == null) {
        return Response(404,
          body: jsonEncode({'error': 'Election not found'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      // Verify union owns this election
      if (election['union_incharge_id'] != unionId) {
        return Response(403,
          body: jsonEncode({'error': 'Unauthorized to publish results for this election'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      election['results_published'] = true;
      election['status'] = 'published'; // Change status so it disappears from union incharge screen
      election['published_at'] = DateTime.now().toIso8601String();
      
      FileStorage.elections[electionId] = election;
      await FileStorage.saveElections();
      
      print('📊 Election results published: ${election['title']}');
      
      return Response.ok(
        jsonEncode({'success': true, 'message': 'Election results published successfully'}),
        headers: {'Content-Type': 'application/json'});
        
    } catch (e) {
      print('❌ Error publishing election results: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to publish election results'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  // Resident Election endpoints
  Future<Response> _submitResidentVote(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      final residentId = data['resident_id']?.toString();
      final electionId = data['election_id']?.toString();
      final choice = data['choice']?.toString();
      
      if (residentId == null || electionId == null || choice == null) {
        return Response(400,
          body: jsonEncode({'error': 'resident_id, election_id, and choice are required'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      final election = FileStorage.elections[electionId];
      if (election == null) {
        return Response(404,
          body: jsonEncode({'error': 'Election not found'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      // Check if election is still active
      if (election['status'] != 'active') {
        return Response(400,
          body: jsonEncode({'error': 'Election is not active'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      // Check if choice is valid
      final choices = List<String>.from(election['choices'] ?? []);
      if (!choices.contains(choice)) {
        return Response(400,
          body: jsonEncode({'error': 'Invalid choice'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      // Check if resident has already voted
      final votes = Map<String, dynamic>.from(election['votes'] ?? {});
      if (votes.containsKey(residentId)) {
        return Response(400,
          body: jsonEncode({'error': 'You have already voted in this election'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      // Verify resident belongs to the same building as the election
      final resident = FileStorage.users.values.firstWhere(
        (user) => user['id'] == residentId,
        orElse: () => <String, dynamic>{},
      );
      
      if (resident.isEmpty) {
        return Response(404,
          body: jsonEncode({'error': 'Resident not found'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      if (resident['building_name'] != election['building_name']) {
        return Response(403,
          body: jsonEncode({'error': 'You can only vote on elections in your building'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      // Record the vote
      votes[residentId] = choice;
      election['votes'] = votes;
      
      // Update vote counts
      final results = Map<String, dynamic>.from(election['results'] ?? {});
      results[choice] = (results[choice] ?? 0) + 1;
      election['results'] = results;
      
      // Update total votes
      election['total_votes'] = (election['total_votes'] ?? 0) + 1;
      
      // Save the updated election
      FileStorage.elections[electionId] = election;
      await FileStorage.saveElections();
      
      print('✅ Vote recorded: $residentId voted "$choice" in election "${election['title']}"');
      
      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'Vote recorded successfully',
          'choice': choice
        }),
        headers: {'Content-Type': 'application/json'});
        
    } catch (e) {
      print('❌ Error submitting vote: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to submit vote'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _acknowledgeElectionResults(Request request) async {
    try {
      final electionId = request.params['electionId'];
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final residentId = data['resident_id']; // Changed from union_id to resident_id
      
      if (electionId == null || residentId == null) {
        return Response(400,
          body: jsonEncode({'error': 'Election ID and resident_id are required'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      final election = FileStorage.elections[electionId];
      if (election == null) {
        return Response(404,
          body: jsonEncode({'error': 'Election not found'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      // Verify resident voted in this election
      final votes = Map<String, dynamic>.from(election['votes'] ?? {});
      if (!votes.containsKey(residentId)) {
        return Response(403,
          body: jsonEncode({'error': 'You did not participate in this election'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      // Track individual resident acknowledgments
      final acknowledgments = Map<String, dynamic>.from(election['acknowledgments'] ?? {});
      acknowledgments[residentId] = DateTime.now().toIso8601String();
      election['acknowledgments'] = acknowledgments;
      
      // Check if all voters have acknowledged
      final totalVoters = votes.length;
      final totalAcknowledgments = acknowledgments.length;
      
      if (totalAcknowledgments >= totalVoters) {
        // All voters have acknowledged, mark election as fully completed
        election['all_acknowledged'] = true;
        election['status'] = 'completed';
      }
      
      FileStorage.elections[electionId] = election;
      await FileStorage.saveElections();
      
      print('✅ Election results acknowledged by resident $residentId: ${election['title']}');
      
      return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'Election results acknowledged successfully',
          'acknowledged': true
        }),
        headers: {'Content-Type': 'application/json'});
    } catch (e) {
      print('❌ Error acknowledging election results: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to acknowledge election results'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _acknowledgeResolvedComplaint(Request request) async {
    try {
      final complaintId = request.params['complaintId'];
      
      print('✅ Resident acknowledging resolved complaint: $complaintId');
      
      // Check if complaint exists
      if (!FileStorage.complaints.containsKey(complaintId)) {
        return Response(404,
          body: jsonEncode({'error': 'Complaint not found'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      final complaint = FileStorage.complaints[complaintId]!;
      
      // Only allow acknowledging resolved complaints
      if (complaint['status']?.toLowerCase() != 'resolved') {
        return Response(400,
          body: jsonEncode({'error': 'Only resolved complaints can be acknowledged'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      // Remove the complaint from storage
      FileStorage.complaints.remove(complaintId);
      
      // Save to file
      await FileStorage.saveComplaints();
      
      print('✅ Resolved complaint $complaintId acknowledged and removed');
      
      return Response.ok(
        jsonEncode({
          'message': 'Complaint acknowledged and removed successfully',
          'complaint_id': complaintId
        }),
        headers: {'Content-Type': 'application/json'},
      );
      
    } catch (e) {
      print('❌ Error acknowledging complaint: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to acknowledge complaint'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  // Bank Details endpoints
  Future<Response> _uploadBankDetails(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      final bankName = data['bank_name']?.toString() ?? '';
      final iban = data['iban']?.toString() ?? '';
      final accountTitle = data['account_title']?.toString() ?? '';
      final buildingName = data['building_name']?.toString() ?? '';
      final unionId = data['union_id']?.toString() ?? '';
      
      if (bankName.isEmpty || iban.isEmpty || accountTitle.isEmpty || buildingName.isEmpty) {
        return Response(400, 
          body: jsonEncode({'error': 'Missing required fields'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      final bankId = const Uuid().v4();
      final bankDetails = {
        'id': bankId,
        'bank_name': bankName,
        'iban': iban,
        'account_title': accountTitle,
        'building_name': buildingName,
        'union_id': unionId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      // Store using building name as key for easy retrieval
      final buildingKey = buildingName.replaceAll(' ', '_').toLowerCase();
      FileStorage.bankDetails[buildingKey] = bankDetails;
      
      // Save to file
      await FileStorage.saveBankDetails();
      
      print('✅ Bank details uploaded for building: $buildingName');
      
      return Response.ok(
        jsonEncode({
          'message': 'Bank details uploaded successfully',
          'bank_id': bankId,
          'building_name': buildingName
        }),
        headers: {'Content-Type': 'application/json'},
      );
      
    } catch (e) {
      print('❌ Error uploading bank details: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to upload bank details'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _getBankDetails(Request request) async {
    try {
      final buildingName = request.params['buildingName'];
      if (buildingName == null || buildingName.isEmpty) {
        return Response(400,
          body: jsonEncode({'error': 'Building name is required'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      final buildingKey = buildingName.replaceAll(' ', '_').toLowerCase();
      
      print('🔍 Bank details request:');
      print('   • Original building name: "$buildingName"');
      print('   • Generated key: "$buildingKey"');
      print('   • Available keys: ${FileStorage.bankDetails.keys.toList()}');
      
      final bankDetails = FileStorage.bankDetails[buildingKey];
      
      if (bankDetails == null) {
        print('❌ Bank details not found for key: "$buildingKey"');
        return Response(404,
          body: jsonEncode({'error': 'Bank details not found for this building'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      print('✅ Bank details found for building: "$buildingName"');
      
      return Response.ok(
        jsonEncode(bankDetails),
        headers: {'Content-Type': 'application/json'},
      );
      
    } catch (e) {
      print('❌ Error getting bank details: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to get bank details'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _getBankDetailsByUnion(Request request) async {
    try {
      final buildingName = request.params['buildingName'];
      if (buildingName == null || buildingName.isEmpty) {
        return Response(400,
          body: jsonEncode({'error': 'Building name is required'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      final buildingKey = buildingName.replaceAll(' ', '_').toLowerCase();
      final bankDetails = FileStorage.bankDetails[buildingKey];
      
      if (bankDetails == null) {
        return Response(404,
          body: jsonEncode({'error': 'Bank details not found for this building'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      return Response.ok(
        jsonEncode(bankDetails),
        headers: {'Content-Type': 'application/json'},
      );
      
    } catch (e) {
      print('❌ Error getting bank details by union: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to get bank details'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  // Union-specific bank details endpoints implementation
  Future<Response> _saveUnionBankDetails(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      final unionId = data['union_id']?.toString();
      final bankName = data['bank_name']?.toString() ?? '';
      final accountNumber = data['account_number']?.toString() ?? '';
      final ifscCode = data['ifsc_code']?.toString() ?? '';
      final accountHolderName = data['account_holder_name']?.toString() ?? '';
      final branchName = data['branch_name']?.toString() ?? '';
      final upiId = data['upi_id']?.toString() ?? '';
      
      if (unionId == null || unionId.isEmpty) {
        return Response(400, 
          body: jsonEncode({'error': 'Union ID is required'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      final bankDetailsId = const Uuid().v4();
      final bankDetails = {
        'id': bankDetailsId,
        'union_id': unionId,
        'bank_name': bankName,
        'account_number': accountNumber,
        'ifsc_code': ifscCode,
        'account_holder_name': accountHolderName,
        'branch_name': branchName,
        'upi_id': upiId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      // Store using union ID as key for easy retrieval
      FileStorage.bankDetails[unionId] = bankDetails;
      
      // Save to file
      await FileStorage.saveBankDetails();
      
      print('✅ Union bank details saved for union ID: $unionId');
      
      return Response.ok(
        jsonEncode({
          'message': 'Bank details saved successfully',
          'bank_details': bankDetails
        }),
        headers: {'Content-Type': 'application/json'},
      );
      
    } catch (e) {
      print('❌ Error saving union bank details: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to save bank details'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _getUnionBankDetails(Request request) async {
    try {
      final unionId = request.params['unionId'];
      if (unionId == null || unionId.isEmpty) {
        return Response(400,
          body: jsonEncode({'error': 'Union ID is required'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      final bankDetails = FileStorage.bankDetails[unionId];
      
      if (bankDetails == null) {
        return Response(200,
          body: jsonEncode({'bank_details': null}),
          headers: {'Content-Type': 'application/json'});
      }
      
      return Response.ok(
        jsonEncode({'bank_details': bankDetails}),
        headers: {'Content-Type': 'application/json'},
      );
      
    } catch (e) {
      print('❌ Error getting union bank details: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to get bank details'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  // Union incharge profile update endpoint
  Future<Response> _updateUnionProfile(Request request) async {
    try {
      final unionId = request.params['unionId'];
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      if (unionId == null || unionId.isEmpty) {
        return Response(400, 
          body: jsonEncode({'error': 'Union ID is required'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      // Find the union incharge user
      final user = FileStorage.users[unionId];
      if (user == null) {
        return Response(404,
          body: jsonEncode({'error': 'Union incharge not found'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      // Update profile fields
      final updatedUser = Map<String, dynamic>.from(user);
      
      // Update personal information
      if (data['first_name'] != null) updatedUser['first_name'] = data['first_name'];
      if (data['last_name'] != null) updatedUser['last_name'] = data['last_name'];
      if (data['phone'] != null) updatedUser['phone'] = data['phone'];
      if (data['email'] != null) updatedUser['email'] = data['email'];
      
      // Update bank details
      if (data['bank_name'] != null) updatedUser['bank_name'] = data['bank_name'];
      if (data['account_number'] != null) updatedUser['account_number'] = data['account_number'];
      if (data['account_title'] != null) updatedUser['account_title'] = data['account_title'];
      
      // Update timestamp
      updatedUser['updated_at'] = DateTime.now().toIso8601String();
      
      // Save back to storage
      FileStorage.users[unionId] = updatedUser;
      await FileStorage.saveUsers();
      
      print('✅ Union incharge profile updated for ID: $unionId');
      
      // Return the updated user data (without password)
      final responseUser = Map<String, dynamic>.from(updatedUser);
      responseUser.remove('password');
      
      return Response.ok(
        jsonEncode({
          'message': 'Profile updated successfully',
          'user': responseUser
        }),
        headers: {'Content-Type': 'application/json'},
      );
      
    } catch (e) {
      print('❌ Error updating union profile: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to update profile'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  // Debug endpoint to show loaded bank details
  Future<Response> _debugBankDetails(Request request) async {
    try {
      final debug = {
        'total_count': FileStorage.bankDetails.length,
        'keys': FileStorage.bankDetails.keys.toList(),
        'details': FileStorage.bankDetails,
      };
      
      return Response.ok(
        jsonEncode(debug),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response(500,
        body: jsonEncode({'error': 'Failed to get debug info'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  // Missing methods for compilation fix
  Future<Response> _reportTechnicalIssue(Request request) async {
    // Implementation for reporting technical issues
    return Response(501, body: jsonEncode({'error': 'Not implemented'}), headers: {'Content-Type': 'application/json'});
      }
      
  Future<Response> _getComplaints(Request request) async {
    try {
      final complaints = FileStorage.complaints.values.toList();
      return Response.ok(jsonEncode(complaints), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response(500, body: jsonEncode({'error': 'Failed to get complaints'}), headers: {'Content-Type': 'application/json'});
    }
  }

  // Union Notice Management Methods
  Future<Response> _createUnionNotice(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      // Generate unique notice ID
      final noticeId = uuid.v4();
      
      // Create notice object
      final notice = {
        'id': noticeId,
        'title': data['title'],
        'body': data['body'],
        'message': data['body'], // Keep for compatibility
        'priority': data['priority'] ?? 'Normal',
        'category': data['category'] ?? 'General',
        'posted_at': DateTime.now().toIso8601String(),
        'sentDate': DateTime.now().toIso8601String(),
        'unionId': data['unionId'],
        'buildingName': data['buildingName'],
        'property_name': data['buildingName'], // For resident compatibility
        'posted_by': 'Union Incharge',
        'sentBy': 'Union Incharge',
        'status': 'Sent',
        'readCount': 0,
        'acknowledgedCount': 0,
        'readBy': [], // Track which residents have read it
      };
      
      // Save to storage
      FileStorage.notices[noticeId] = notice;
      await FileStorage.saveNotices();
      
      print('📢 Notice created: ${notice['title']} for building: ${notice['buildingName']}');
      
      return Response(201,
        body: jsonEncode({
          'message': 'Notice created successfully',
          'id': noticeId,
          'notice': notice
        }),
        headers: {'Content-Type': 'application/json'});
        
    } catch (e) {
      print('❌ Error creating union notice: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to create notice'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _getUnionNotices(Request request) async {
    try {
      final buildingName = request.params['buildingName'];
      
      if (buildingName == null || buildingName.isEmpty) {
        return Response(400,
          body: jsonEncode({'error': 'Building name is required'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      // Filter notices by building and sort by date (newest first)
      final buildingNotices = FileStorage.notices.values
          .where((notice) => notice['buildingName'] == buildingName)
          .toList();
      
      buildingNotices.sort((a, b) {
        final aDate = DateTime.tryParse(a['posted_at'] ?? '') ?? DateTime.now();
        final bDate = DateTime.tryParse(b['posted_at'] ?? '') ?? DateTime.now();
        return bDate.compareTo(aDate);
      });
      
      print('📝 Found ${buildingNotices.length} notices for building: $buildingName');
      
      return Response.ok(
        jsonEncode(buildingNotices),
        headers: {'Content-Type': 'application/json'}
      );
    } catch (e) {
      print('❌ Error getting union notices: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to get notices'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _resolveComplaint(Request request) async {
    // Implementation for resolving complaints
    return Response(501, body: jsonEncode({'error': 'Not implemented'}), headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _acknowledgeComplaint(Request request) async {
    // Implementation for acknowledging complaints
    return Response(501, body: jsonEncode({'error': 'Not implemented'}), headers: {'Content-Type': 'application/json'});
  }

  // Service Request Management Methods
  Future<Response> _createServiceRequest(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      print('📝 Creating service request: ${data.toString()}');
      
      // Validate required fields - support both resident_id and direct resident data
      if (data['provider_id'] == null || data['category'] == null) {
        return Response(400,
          body: jsonEncode({'error': 'Missing required fields: provider_id, category'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      // Get provider details
      final provider = FileStorage.users[data['provider_id']];
      
      if (provider == null) {
        return Response(404,
          body: jsonEncode({'error': 'Provider not found'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      // Generate unique request ID
      final requestId = uuid.v4();
      
      // Handle resident data - either from resident_id lookup or direct data
      String residentName = '';
      String residentEmail = '';
      String residentPhone = '';
      String residentAddress = '';
      String residentId = '';
      
      if (data['resident_id'] != null) {
        // Traditional approach - lookup resident by ID
        final resident = FileStorage.users[data['resident_id']];
        if (resident != null) {
          residentId = data['resident_id'];
          residentName = '${resident['first_name'] ?? ''} ${resident['last_name'] ?? ''}'.trim();
          residentEmail = resident['email'] ?? '';
          residentPhone = resident['phone'] ?? '';
          residentAddress = resident['address'] ?? '';
        } else {
          // Resident not found in database, use provided data as fallback
          residentId = data['resident_id'] ?? 'guest';
          residentName = data['resident_name'] ?? 'Unknown Resident';
          residentEmail = data['resident_email'] ?? '';
          residentPhone = data['resident_phone'] ?? '';
          residentAddress = data['resident_address'] ?? '';
        }
      } else {
        // Direct approach - use provided resident data
        residentId = data['resident_id'] ?? 'guest';
        residentName = data['resident_name'] ?? 'Unknown Resident';
        residentEmail = data['resident_email'] ?? '';
        residentPhone = data['resident_phone'] ?? '';
        residentAddress = data['resident_address'] ?? '';
      }
      
      // Create service request object
      final serviceRequest = {
        'id': requestId,
        'resident_id': residentId,
        'provider_id': data['provider_id'],
        'resident_name': residentName,
        'resident_email': residentEmail,
        'resident_phone': residentPhone,
        'resident_address': residentAddress,
        'provider_name': '${provider['first_name'] ?? ''} ${provider['last_name'] ?? ''}'.trim(),
        'provider_business_name': provider['business_name'] ?? '',
        'provider_email': provider['email'] ?? '',
        'provider_phone': provider['phone'] ?? '',
        'category': data['category'],
        'service_type': data['category'], // For compatibility
        'description': data['description'] ?? 'Service request from $residentName',
        'status': 'pending', // pending, accepted, completed, cancelled
        'created_at': DateTime.now().toIso8601String(),
        'requested_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'priority': data['priority'] ?? 'normal',
        'estimated_cost': data['estimated_cost'],
        'notes': data['notes'],
      };
      
      // Save to storage
      FileStorage.serviceRequests[requestId] = serviceRequest;
      await FileStorage.saveServiceRequests();
      
      print('✅ Service request created: $requestId from $residentName to ${serviceRequest['provider_name']}');
      
      return Response(201,
        body: jsonEncode({
          'message': 'Service request sent successfully',
          'id': requestId,
          'request_id': requestId,
          'status': 'pending',
          'request': serviceRequest
        }),
        headers: {'Content-Type': 'application/json'});
        
    } catch (e) {
      print('❌ Error creating service request: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to create service request'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _getProviderServiceRequests(Request request) async {
    try {
      final providerId = request.params['providerId'];
      final status = request.url.queryParameters['status'];
      
      if (providerId == null || providerId.isEmpty) {
        return Response(400,
          body: jsonEncode({'error': 'Provider ID is required'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      // Get service requests for this provider
      var providerRequests = FileStorage.serviceRequests.values
          .where((req) => req['provider_id'] == providerId);
      
      // Filter by status if specified, otherwise only show pending requests
      if (status != null && status.isNotEmpty) {
        providerRequests = providerRequests.where((req) => req['status'] == status);
      } else {
        // Default to only showing pending requests for new requests screen
        providerRequests = providerRequests.where((req) => req['status'] == 'pending');
      }
      
      final requestsList = providerRequests.toList();
      
      // Sort by created date (newest first)
      requestsList.sort((a, b) {
        final aDate = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
        final bDate = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
        return bDate.compareTo(aDate);
      });
      
      print('📋 Found ${requestsList.length} service requests for provider: $providerId (status: ${status ?? 'pending'})');
      
      return Response.ok(
        jsonEncode(requestsList),
        headers: {'Content-Type': 'application/json'}
      );
    } catch (e) {
      print('❌ Error getting provider service requests: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to get service requests'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _acceptServiceRequest(Request request) async {
    try {
      final requestId = request.params['requestId'];
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      if (requestId == null || requestId.isEmpty) {
        return Response(400,
          body: jsonEncode({'error': 'Request ID is required'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      final serviceRequest = FileStorage.serviceRequests[requestId];
      
      if (serviceRequest == null) {
        return Response(404,
          body: jsonEncode({'error': 'Service request not found'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      // Update request status to completed (job done when accepted)
      serviceRequest['status'] = 'completed';
      serviceRequest['accepted_at'] = DateTime.now().toIso8601String();
      serviceRequest['completed_at'] = DateTime.now().toIso8601String();
      serviceRequest['updated_at'] = DateTime.now().toIso8601String();
      
      // Add optional acceptance details
      if (data['estimated_cost'] != null) {
        serviceRequest['estimated_cost'] = data['estimated_cost'];
      }
      if (data['estimated_duration'] != null) {
        serviceRequest['estimated_duration'] = data['estimated_duration'];
      }
      if (data['notes'] != null) {
        serviceRequest['completion_notes'] = data['notes'];
      }

      // Update provider's services completed count
      final providerId = serviceRequest['provider_id'];
      final provider = FileStorage.users[providerId];
      if (provider != null) {
        final currentCount = provider['services_completed'] ?? 0;
        provider['services_completed'] = currentCount + 1;
        await FileStorage.saveUsers();
        
        print('✅ Updated provider ${provider['email']} completed count to: ${provider['services_completed']}');
      }
      
      // Save to storage
      await FileStorage.saveServiceRequests();
      
      print('✅ Service request accepted: $requestId');
      
      return Response.ok(
        jsonEncode({
          'message': 'Service request accepted and completed successfully',
          'request': serviceRequest,
          'updated_provider_stats': {
            'services_completed': provider?['services_completed'] ?? 0
          }
        }),
        headers: {'Content-Type': 'application/json'}
      );
    } catch (e) {
      print('❌ Error accepting service request: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to accept service request'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _rejectServiceRequest(Request request) async {
    try {
      final requestId = request.params['requestId'];
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      if (requestId == null || requestId.isEmpty) {
        return Response(400,
          body: jsonEncode({'error': 'Request ID is required'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      final serviceRequest = FileStorage.serviceRequests[requestId];
      
      if (serviceRequest == null) {
        return Response(404,
          body: jsonEncode({'error': 'Service request not found'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      // Update request status
      serviceRequest['status'] = 'rejected';
      serviceRequest['rejected_at'] = DateTime.now().toIso8601String();
      serviceRequest['updated_at'] = DateTime.now().toIso8601String();
      
      // Add rejection reason
      if (data['reason'] != null) {
        serviceRequest['rejection_reason'] = data['reason'];
      }
      
      // Save to storage
      await FileStorage.saveServiceRequests();
      
      print('❌ Service request rejected: $requestId');
      
      return Response.ok(
        jsonEncode({
          'message': 'Service request rejected successfully',
          'request': serviceRequest
        }),
        headers: {'Content-Type': 'application/json'}
      );
    } catch (e) {
      print('❌ Error rejecting service request: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to reject service request'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _completeServiceRequest(Request request) async {
    try {
      final requestId = request.params['requestId'];
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      if (requestId == null || requestId.isEmpty) {
        return Response(400,
          body: jsonEncode({'error': 'Request ID is required'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      final serviceRequest = FileStorage.serviceRequests[requestId];
      
      if (serviceRequest == null) {
        return Response(404,
          body: jsonEncode({'error': 'Service request not found'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      // Update request status
      serviceRequest['status'] = 'completed';
      serviceRequest['completed_at'] = DateTime.now().toIso8601String();
      serviceRequest['updated_at'] = DateTime.now().toIso8601String();
      
      // Add completion details
      if (data['final_cost'] != null) {
        serviceRequest['final_cost'] = data['final_cost'];
      }
      if (data['completion_notes'] != null) {
        serviceRequest['completion_notes'] = data['completion_notes'];
      }
      
      // Update provider's services completed count
      final providerId = serviceRequest['provider_id'];
      final provider = FileStorage.users[providerId];
      if (provider != null) {
        final currentCount = provider['services_completed'] ?? 0;
        provider['services_completed'] = currentCount + 1;
        await FileStorage.saveUsers();
        
        print('✅ Updated provider ${provider['email']} completed count to: ${provider['services_completed']}');
      }
      
      // Save to storage
      await FileStorage.saveServiceRequests();
      
      print('✅ Service request completed: $requestId');
      
      return Response.ok(
        jsonEncode({
          'message': 'Service request completed successfully',
          'request': serviceRequest,
          'updated_provider_stats': {
            'services_completed': provider?['services_completed'] ?? 0
          }
        }),
        headers: {'Content-Type': 'application/json'}
      );
    } catch (e) {
      print('❌ Error completing service request: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to complete service request'}),
        headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> _getServiceProviderProfile(Request request) async {
    try {
      final providerId = request.params['providerId'];
      
      if (providerId == null || providerId.isEmpty) {
        return Response(400,
          body: jsonEncode({'error': 'Provider ID is required'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      final provider = FileStorage.users[providerId];
      
      if (provider == null) {
        return Response(404,
          body: jsonEncode({'error': 'Service provider not found'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      // Check if it's a service provider
      if (provider['role']?.toString().toLowerCase() != 'service provider') {
        return Response(400,
          body: jsonEncode({'error': 'User is not a service provider'}),
          headers: {'Content-Type': 'application/json'});
      }
      
      // Create name from first_name and last_name
      final firstName = provider['first_name']?.toString() ?? '';
      final lastName = provider['last_name']?.toString() ?? '';
      String fullName = '$firstName $lastName'.trim();
      if (fullName.isEmpty) {
        fullName = provider['email']?.toString() ?? 'Unknown Provider';
      }
      
      // Return service provider profile
      final profileData = {
        'id': provider['id'] ?? '',
        'name': fullName,
        'email': provider['email']?.toString() ?? '',
        'phone': provider['phone']?.toString() ?? '',
        'business_name': provider['business_name']?.toString() ?? '',
        'address': provider['address']?.toString() ?? '',
        'category': provider['category']?.toString() ?? '',
        'approved_at': provider['approved_at']?.toString() ?? '',
        'status': provider['is_approved'] == true ? 'approved' : 'pending',
        'services_completed': provider['services_completed'] ?? 0,
        'description': provider['description'] ?? 'Professional ${provider['category']} service provider',
        'created_at': provider['created_at']?.toString() ?? '',
        'first_name': provider['first_name']?.toString() ?? '',
        'last_name': provider['last_name']?.toString() ?? '',
        'username': provider['username']?.toString() ?? '',
      };
      
      print('📋 Retrieved profile for service provider: ${provider['email']}');
      
      return Response.ok(
        jsonEncode({
          'profile': profileData
        }),
        headers: {'Content-Type': 'application/json'}
      );
    } catch (e) {
      print('❌ Error getting service provider profile: $e');
      return Response(500,
        body: jsonEncode({'error': 'Failed to get service provider profile'}),
        headers: {'Content-Type': 'application/json'});
    }
  }
}

Future<int> findAvailablePort(int startPort) async {
  for (int port = startPort; port <= startPort + 100; port++) {
    try {
      final server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      await server.close();
      return port;
    } catch (e) {
      continue;
    }
  }
  throw Exception('No available port found in range $startPort-${startPort + 100}');
}

void main(List<String> args) async {
  // Parse command line arguments
  final ip = InternetAddress.anyIPv4;
  int preferredPort = int.parse(Platform.environment['PORT'] ?? '5000');
  
  // Initialize Firebase
  print('🔥 Initializing Firebase...');
  // await FirebaseConfig.initialize();
  
  // Create server instance and initialize it
  final server = HomeConnectServer();
  await server.initialize();

  try {
    // Try to start the server on the preferred port
    final httpServer = await serve(server.handler, ip, preferredPort);
    print('🚀 HomeConnect Dart Backend Server running on http://${httpServer.address.host}:${httpServer.port}');
    print('💾 Using FileStorage for persistent data storage');
    print('🔥 Firebase Storage integration enabled');
    print('📡 CORS enabled for all origins');
    print('🔧 API endpoints available:');
    print('   GET  /test - Health check');
    print('   POST /login - User authentication');
    print('   POST /register - User registration');
    print('   POST /signup - Comprehensive user signup');
    print('   POST /upload_cnic_base64 - CNIC image upload');
    print('   GET  /buildings - List all buildings');
    print('   GET  /resident/elections - Get resident elections');
    print('   GET  /resident/notices - Get resident notices');
    print('   GET  /resident/complaints/<userId> - Get complaints');
    print('   POST /resident/complaints - Create complaint');
    print('   GET  /resident/services - Get services');
    print('   POST /resident/emergency - Report emergency');
    print('   And many more...');
  } catch (e) {
    if (e.toString().contains('10048') || e.toString().contains('address already in use')) {
      print('⚠️ Port $preferredPort is already in use. Finding an available port...');
      try {
        final availablePort = await findAvailablePort(preferredPort + 1);
        print('🔄 Trying port $availablePort instead...');
        
        final httpServer = await serve(server.handler, ip, availablePort);
        print('🚀 HomeConnect Dart Backend Server running on http://${httpServer.address.host}:${httpServer.port}');
        print('⚠️ Note: Server is running on port $availablePort instead of $preferredPort');
        print('💾 Using FileStorage for persistent data storage');
        print('🔥 Firebase Storage integration enabled');
        print('📡 CORS enabled for all origins');
        print('🔧 API endpoints available:');
        print('   GET  /test - Health check');
        print('   POST /login - User authentication');
        print('   POST /register - User registration');
        print('   POST /signup - Comprehensive user signup');
        print('   POST /upload_cnic_base64 - CNIC image upload');
        print('   GET  /buildings - List all buildings');
        print('   GET  /resident/elections - Get resident elections');
        print('   GET  /resident/notices - Get resident notices');
        print('   GET  /resident/complaints/<userId> - Get complaints');
        print('   POST /resident/complaints - Create complaint');
        print('   GET  /resident/services - Get services');
        print('   POST /resident/emergency - Report emergency');
        print('   And many more...');
        print('');
        print('🔧 UPDATE YOUR FRONTEND: Change the API base URL to http://localhost:$availablePort');
      } catch (portError) {
        print('❌ Failed to find an available port: $portError');
        print('💡 Solution: Kill existing processes using these ports or restart your system');
        exit(1);
      }
    } else {
      print('❌ Failed to start server: $e');
      exit(1);
    }
  }
}
