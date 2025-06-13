import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Add this import for Timer
import '../../main.dart'; // Import to access getBaseUrl function
import 'union_incharge_detail_screen.dart'; // Import the detail screen

class AdminApprovalScreen extends StatefulWidget {
  const AdminApprovalScreen({super.key});

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen> {
  List<Map<String, dynamic>> pendingUsers = [];
  bool isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    fetchPendingUsers();
    // Set up periodic refresh every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        fetchPendingUsers();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); // Cancel the timer when disposing
    super.dispose();
  }

  Future<void> fetchPendingUsers() async {
    if (!mounted) return;

    try {
      print("🔍 Attempting to fetch pending users...");
      
      // Try both endpoints to ensure we get data
      final baseUrl = getBaseUrl();
      final standardEndpoint = Uri.parse('$baseUrl/admin/pending_users');
      final debugEndpoint = Uri.parse('$baseUrl/debug/pending_users');
      
      // First try debug endpoint
      print("🔍 Trying debug endpoint: $debugEndpoint");
      final debugResponse = await http.get(debugEndpoint);
      
      if (debugResponse.statusCode == 200) {
        final debugData = jsonDecode(debugResponse.body);
        print("📊 Debug data: ${debugData['pending_users_count']} pending users found");
        
        // If there are pending users, proceed with standard endpoint
        if (debugData['pending_users_count'] > 0) {
          print("🔍 Trying standard endpoint: $standardEndpoint");
          final response = await http.get(standardEndpoint);
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            print("📝 Standard endpoint response: $data");
            
            setState(() {
              pendingUsers = List<Map<String, dynamic>>.from(data);
              isLoading = false;
            });
            
            return;
          }
        }
        
        // If we couldn't get data from standard endpoint or there are no pending users,
        // use the debug endpoint data
        setState(() {
          pendingUsers = List<Map<String, dynamic>>.from(debugData['pending_users'].map((user) => {
            'id': user['id'],
            'first_name': user['first_name'],
            'last_name': user['last_name'],
            'email': user['email'],
            'role': user['role'],
            'phone': 'Not provided', // Default value since debug endpoint might not have this
            'address': 'Not provided', // Default value
            'cnic_image_url': null, // Default value
          }));
          isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch pending users from debug endpoint: ${debugResponse.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;

      print('❌ Error fetching pending users: $e');
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch pending users: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _refreshList() async {
    setState(() {
      isLoading = true;
    });
    await fetchPendingUsers();
  }

  Future<void> _approveUser(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/admin/approve_user/$userId'),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User approved successfully')),
        );
        fetchPendingUsers();
      } else {
        throw Exception('Failed to approve user');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to approve user')),
      );
    }
  }

  Future<void> _rejectUser(int userId) async {
    try {
      // Show confirmation dialog
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm Rejection'),
            content: const Text('Are you sure you want to reject this user?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text('Reject'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (confirm == true) {
        final response = await http.delete(
          Uri.parse('${getBaseUrl()}/admin/remove_user/$userId'),
        );
        if (response.statusCode == 200) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User rejected successfully')),
          );
          fetchPendingUsers();
        } else {
          throw Exception('Failed to reject user');
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to reject user')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Approvals'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshList,
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Debug Users',
            onPressed: _checkDebugEndpoint,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle),
            tooltip: 'Create Test User',
            onPressed: _createTestUser,
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isWebLayout ? _getMaxWidth(screenWidth) : double.infinity,
          ),
          child: RefreshIndicator(
            onRefresh: _refreshList,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : pendingUsers.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No pending approvals',
                    style: TextStyle(
                      fontSize: isWebLayout ? 18 : 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshList,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.all(isWebLayout ? 24 : 16),
              itemCount: pendingUsers.length,
              itemBuilder: (context, index) {
                final user = pendingUsers[index];
                return InkWell(
                  onTap: () => _openUserDetails(user),
                  child: Card(
                    elevation: 3,
                    margin: EdgeInsets.symmetric(vertical: isWebLayout ? 12 : 10),
                    child: Padding(
                      padding: EdgeInsets.all(isWebLayout ? 24 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Name: ${user['first_name']} ${user['last_name']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isWebLayout ? 16 : 14,
                            ),
                          ),
                          SizedBox(height: isWebLayout ? 8 : 4),
                          Text(
                            'Role: ${user['role']}',
                            style: TextStyle(fontSize: isWebLayout ? 15 : 14),
                          ),
                          Text(
                            'Email: ${user['email']}',
                            style: TextStyle(fontSize: isWebLayout ? 15 : 14),
                          ),
                          Text(
                            'Phone: ${user['phone'] ?? 'Not provided'}',
                            style: TextStyle(fontSize: isWebLayout ? 15 : 14),
                          ),
                          if (user['role'] == 'Union Incharge')
                            Text(
                              'Property: ${user['building_name'] ?? 'Not specified'}',
                              style: TextStyle(fontSize: isWebLayout ? 15 : 14),
                            ),
                          SizedBox(height: isWebLayout ? 12 : 8),
                          if (user['cnic_image_url'] != null)
                            Container(
                              height: isWebLayout ? 120 : 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      'CNIC Image (Preview)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                        fontSize: isWebLayout ? 15 : 14,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(8),
                                          bottomRight: Radius.circular(8)
                                      ),
                                      child: Image.network(
                                        user['cnic_image_url'],
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                        const Center(child: Text('Tap to view')),
                                        height: isWebLayout ? 120 : 100,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Text(
                              'No CNIC image provided',
                              style: TextStyle(fontSize: isWebLayout ? 15 : 14),
                            ),
                          SizedBox(height: isWebLayout ? 12 : 8),
                          Text(
                            'Tap for details and approval options',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontStyle: FontStyle.italic,
                              fontSize: isWebLayout ? 14 : 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  double _getMaxWidth(double screenWidth) {
    if (screenWidth <= 800) return 500;
    if (screenWidth <= 1200) return 600;
    return 800;
  }

  Future<void> _checkDebugEndpoint() async {
    try {
      setState(() => isLoading = true);
      
      final response = await http.get(
        Uri.parse('${getBaseUrl()}/debug/pending_users'),
      );
      
      setState(() => isLoading = false);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Show the debug information in a dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('User Debug Info'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Users: ${data['total_users']}'),
                  Text('Pending Users: ${data['pending_users_count']}'),
                  const Divider(),
                  const Text('Users by Role:', style: TextStyle(fontWeight: FontWeight.bold)),
                  for (var entry in data['users_by_role'].entries)
                    Text('${entry.key}: ${entry.value}'),
                  const Divider(),
                  const Text('Pending Users:', style: TextStyle(fontWeight: FontWeight.bold)),
                  for (var user in data['pending_users'])
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${user['first_name']} ${user['last_name']} (${user['role']})'),
                          Text('Email: ${user['email']}'),
                          Text('ID: ${user['id']}'),
                        ],
                      ),
                    ),
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Debug endpoint error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Debug endpoint error: $e')),
      );
    }
  }

  Future<void> _createTestUser() async {
    try {
      setState(() => isLoading = true);
      
      final response = await http.get(
        Uri.parse('${getBaseUrl()}/admin/create_test_user'),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'])),
        );
        
        // Refresh the list to show the new user
        await fetchPendingUsers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create test user: ${response.statusCode}')),
        );
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating test user: $e')),
      );
    }
  }

  Future<void> _openUserDetails(Map<String, dynamic> user) async {
    if (user['role'] != 'Union Incharge') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Detailed view only available for Union Incharge users')),
      );
      return;
    }
    
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => UnionInchargeDetailScreen(user: user),
      ),
    );
    
    // If the result is true, the user was either approved or rejected,
    // so we need to refresh the list
    if (result == true) {
      _refreshList();
    }
  }
}
