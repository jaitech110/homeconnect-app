import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Initialize Supabase
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  // User Authentication & Management
  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    required String phone,
    String? building,
    String? flatNo,
    String? category,
    String? businessName,
  }) async {
    try {
      // Create auth user
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Insert user data into custom users table
        await _client.from('users').insert({
          'auth_user_id': response.user!.id,
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          'role': role,
          'phone': phone,
          'building': building ?? '',
          'flat_no': flatNo ?? '',
          'category': category ?? '',
          'business_name': businessName ?? '',
          'is_approved': role == 'admin', // Auto-approve admin
        });

        return {
          'success': true,
          'message': role == 'admin' 
              ? 'Admin account created successfully' 
              : 'Account created successfully. Waiting for approval.',
          'user_id': response.user!.id,
        };
      }
      return {'success': false, 'message': 'Failed to create account'};
    } catch (e) {
      print('Sign up error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Get user data from custom users table
        final userData = await _client
            .from('users')
            .select()
            .eq('auth_user_id', response.user!.id)
            .single();

        // Check if user is approved
        if (userData['is_approved'] != true && userData['role'] != 'admin') {
          await _client.auth.signOut();
          return {
            'success': false,
            'message': 'Your account is pending approval. Please contact admin.',
          };
        }

        return {
          'success': true,
          'message': 'Login successful',
          'user': userData,
        };
      }
      return {'success': false, 'message': 'Login failed'};
    } catch (e) {
      print('Sign in error: $e');
      return {'success': false, 'message': 'Invalid email or password'};
    }
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  static User? getCurrentAuthUser() {
    return _client.auth.currentUser;
  }

  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    final user = getCurrentAuthUser();
    if (user != null) {
      try {
        final userData = await _client
            .from('users')
            .select()
            .eq('auth_user_id', user.id)
            .single();
        return userData;
      } catch (e) {
        print('Error getting current user data: $e');
        return null;
      }
    }
    return null;
  }

  // Admin Functions
  static Future<List<Map<String, dynamic>>> getPendingApprovals() async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('is_approved', false)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting pending approvals: $e');
      return [];
    }
  }

  static Stream<List<Map<String, dynamic>>> streamPendingApprovals() {
    return _client
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('is_approved', false)
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  static Future<bool> approveUser(String userId) async {
    try {
      await _client
          .from('users')
          .update({
            'is_approved': true,
            'approved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      return true;
    } catch (e) {
      print('Error approving user: $e');
      return false;
    }
  }

  static Future<bool> rejectUser(String userId) async {
    try {
      // Get the auth_user_id before deleting from users table
      final userData = await _client
          .from('users')
          .select('auth_user_id')
          .eq('id', userId)
          .single();

      // Delete from users table first
      await _client.from('users').delete().eq('id', userId);

      // Delete from auth (this will cascade)
      await _client.auth.admin.deleteUser(userData['auth_user_id']);
      
      return true;
    } catch (e) {
      print('Error rejecting user: $e');
      return false;
    }
  }

  // Complaints Management
  static Future<String?> createComplaint({
    required String title,
    required String description,
    required String userId,
    String? category,
    String? priority,
  }) async {
    try {
      final response = await _client.from('complaints').insert({
        'title': title,
        'description': description,
        'user_id': userId,
        'category': category ?? 'General',
        'priority': priority ?? 'Medium',
      }).select().single();

      return response['id'];
    } catch (e) {
      print('Error creating complaint: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getComplaints({String? userId}) async {
    try {
      var query = _client
          .from('complaints')
          .select('*, users!inner(first_name, last_name, email)');
      
      if (userId != null) {
        query = query.eq('user_id', userId);
      }
      
      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting complaints: $e');
      return [];
    }
  }

  static Stream<List<Map<String, dynamic>>> streamComplaints({String? userId}) {
    if (userId != null) {
      return _client
          .from('complaints')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .map((data) => List<Map<String, dynamic>>.from(data));
    } else {
      return _client
          .from('complaints')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .map((data) => List<Map<String, dynamic>>.from(data));
    }
  }

  static Future<bool> updateComplaintStatus(String complaintId, String status, {String? adminResponse}) async {
    try {
      final updateData = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (adminResponse != null) {
        updateData['admin_response'] = adminResponse;
      }
      
      if (status == 'Resolved' || status == 'Closed') {
        updateData['resolved_at'] = DateTime.now().toIso8601String();
      }

      await _client
          .from('complaints')
          .update(updateData)
          .eq('id', complaintId);
      return true;
    } catch (e) {
      print('Error updating complaint status: $e');
      return false;
    }
  }

  // Buildings Management
  static Future<List<Map<String, dynamic>>> getBuildings() async {
    try {
      final response = await _client
          .from('buildings')
          .select('*, users!union_incharge_id(first_name, last_name, email)')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting buildings: $e');
      return [];
    }
  }

  static Future<String?> createBuilding({
    required String name,
    required String address,
    String? unionInchargeId,
    String? bankName,
    String? iban,
    String? accountTitle,
  }) async {
    try {
      final response = await _client.from('buildings').insert({
        'name': name,
        'address': address,
        'union_incharge_id': unionInchargeId,
        'bank_name': bankName,
        'iban': iban,
        'account_title': accountTitle,
      }).select().single();

      return response['id'];
    } catch (e) {
      print('Error creating building: $e');
      return null;
    }
  }

  // Elections Management
  static Future<String?> createElection({
    required String title,
    required String description,
    required List<String> candidates,
    required DateTime startDate,
    required DateTime endDate,
    required String createdBy,
  }) async {
    try {
      final response = await _client.from('elections').insert({
        'title': title,
        'description': description,
        'candidates': candidates,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'created_by': createdBy,
      }).select().single();

      return response['id'];
    } catch (e) {
      print('Error creating election: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getElections() async {
    try {
      final response = await _client
          .from('elections')
          .select('*, users!created_by(first_name, last_name)')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting elections: $e');
      return [];
    }
  }

  static Future<bool> castVote({
    required String electionId,
    required String userId,
    required String candidateId,
  }) async {
    try {
      // Insert vote (will fail if user already voted due to unique constraint)
      await _client.from('votes').insert({
        'election_id': electionId,
        'user_id': userId,
        'candidate_id': candidateId,
      });

      // Update election total votes count
      await _client.rpc('increment_election_votes', params: {
        'election_id': electionId,
      });

      return true;
    } catch (e) {
      print('Error casting vote: $e');
      return false;
    }
  }

  // Service Requests
  static Future<String?> createServiceRequest({
    required String title,
    required String description,
    required String category,
    required String userId,
  }) async {
    try {
      final response = await _client.from('service_requests').insert({
        'title': title,
        'description': description,
        'category': category,
        'user_id': userId,
      }).select().single();

      return response['id'];
    } catch (e) {
      print('Error creating service request: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getServiceRequests({
    String? userId,
    String? providerId,
    String? status,
  }) async {
    try {
      var query = _client
          .from('service_requests')
          .select('*, users!user_id(first_name, last_name, email, phone), providers:users!provider_id(first_name, last_name, email, phone)');
      
      if (userId != null) {
        query = query.eq('user_id', userId);
      }
      if (providerId != null) {
        query = query.eq('provider_id', providerId);
      }
      if (status != null) {
        query = query.eq('status', status);
      }
      
      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting service requests: $e');
      return [];
    }
  }

  // File Upload to Supabase Storage
  static Future<String?> uploadFile({
    required Uint8List fileBytes,
    required String fileName,
    required String bucket,
    String? folder,
  }) async {
    try {
      final path = folder != null ? '$folder/$fileName' : fileName;
      
      await _client.storage
          .from(bucket)
          .uploadBinary(path, fileBytes);

      final publicUrl = _client.storage
          .from(bucket)
          .getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  // Emergency Reports
  static Future<String?> reportEmergency({
    required String type,
    required String description,
    required String reportedBy,
    String? location,
    String? severity,
  }) async {
    try {
      final response = await _client.from('emergency_reports').insert({
        'type': type,
        'description': description,
        'reported_by': reportedBy,
        'location': location,
        'severity': severity ?? 'Medium',
      }).select().single();

      return response['id'];
    } catch (e) {
      print('Error reporting emergency: $e');
      return null;
    }
  }

  // Notices Management
  static Future<String?> createNotice({
    required String title,
    required String content,
    required String authorId,
    String? category,
    String? priority,
    String? buildingId,
    DateTime? publishDate,
    DateTime? expiryDate,
  }) async {
    try {
      final response = await _client.from('notices').insert({
        'title': title,
        'content': content,
        'author_id': authorId,
        'category': category ?? 'General',
        'priority': priority ?? 'Normal',
        'building_id': buildingId,
        'publish_date': publishDate?.toIso8601String(),
        'expiry_date': expiryDate?.toIso8601String(),
        'is_published': publishDate == null || publishDate.isBefore(DateTime.now()),
      }).select().single();

      return response['id'];
    } catch (e) {
      print('Error creating notice: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getNotices({String? buildingId}) async {
    try {
      var query = _client
          .from('notices')
          .select('*, users!author_id(first_name, last_name)')
          .eq('is_published', true);
      
      if (buildingId != null) {
        query = query.eq('building_id', buildingId);
      }
      
      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting notices: $e');
      return [];
    }
  }

  // Utility Functions
  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  static bool get isLoggedIn => _client.auth.currentUser != null;

  // Real-time subscriptions for live updates
  static RealtimeChannel subscribeToTable(String table, void Function(Map<String, dynamic>) onData) {
    return _client
        .channel('public:$table')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          callback: (payload) => onData(payload.newRecord),
        )
        .subscribe();
  }
} 