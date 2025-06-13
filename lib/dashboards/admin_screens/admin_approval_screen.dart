import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Add this import for Timer
import '../../main.dart'; // Import to access getBaseUrl function
import '../../services/supabase_service.dart'; // Import SupabaseService
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
    // Set up periodic refresh every 30 seconds (reduced frequency for Supabase)
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
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
      print("🔍 Fetching pending users from Supabase...");
      
      final pendingApprovals = await SupabaseService.getPendingApprovals();
      
      if (mounted) {
        setState(() {
          pendingUsers = pendingApprovals;
          isLoading = false;
        });
        
        print("✅ Successfully fetched ${pendingApprovals.length} pending users from Supabase");
      }
    } catch (e) {
      if (!mounted) return;

      print('❌ Error fetching pending users from Supabase: $e');
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

  Future<void> _approveUser(String userId) async {
    try {
      print("🔄 Approving user with ID: $userId");
      
      final success = await SupabaseService.approveUser(userId);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User approved successfully'),
              backgroundColor: Colors.green,
            ),
          );
          fetchPendingUsers(); // Refresh the list
        }
        print("✅ User approved successfully");
      } else {
        throw Exception('Failed to approve user');
      }
    } catch (e) {
      print("❌ Error approving user: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectUser(String userId) async {
    try {
      // Show confirmation dialog
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm Rejection'),
            content: const Text(
              'Are you sure you want to reject this user? This will permanently delete their account.',
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Reject'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (confirm == true) {
        print("🔄 Rejecting user with ID: $userId");
        
        final success = await SupabaseService.rejectUser(userId);
        
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('User rejected successfully'),
                backgroundColor: Colors.orange,
              ),
            );
            fetchPendingUsers(); // Refresh the list
          }
          print("✅ User rejected successfully");
        } else {
          throw Exception('Failed to reject user');
        }
      }
    } catch (e) {
      print("❌ Error rejecting user: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
            tooltip: 'Refresh',
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
                  Icon(
                    Icons.check_circle_outline,
                    size: isWebLayout ? 80 : 64,
                    color: Colors.green,
                  ),
                  SizedBox(height: isWebLayout ? 24 : 16),
                  Text(
                    'No pending approvals',
                    style: TextStyle(
                      fontSize: isWebLayout ? 18 : 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: isWebLayout ? 16 : 12),
                  Text(
                    'All users have been processed',
                    style: TextStyle(
                      fontSize: isWebLayout ? 14 : 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: isWebLayout ? 24 : 16),
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
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.deepPurple,
                                child: Text(
                                  '${user['first_name']?[0] ?? ''}${user['last_name']?[0] ?? ''}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: isWebLayout ? 16 : 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: isWebLayout ? 16 : 14,
                                      ),
                                    ),
                                    Text(
                                      user['role'] ?? 'Unknown Role',
                                      style: TextStyle(
                                        fontSize: isWebLayout ? 14 : 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                ),
                                child: Text(
                                  'Pending',
                                  style: TextStyle(
                                    color: Colors.orange[700],
                                    fontSize: isWebLayout ? 12 : 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isWebLayout ? 16 : 12),
                          _buildInfoRow(Icons.email, user['email'] ?? 'No email', isWebLayout),
                          _buildInfoRow(Icons.phone, user['phone'] ?? 'No phone', isWebLayout),
                          if (user['role'] == 'Union Incharge')
                            _buildInfoRow(Icons.business, user['building_name'] ?? 'No building', isWebLayout),
                          if (user['address'] != null && user['address'].toString().isNotEmpty)
                            _buildInfoRow(Icons.location_on, user['address'], isWebLayout),
                          SizedBox(height: isWebLayout ? 16 : 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _approveUser(user['id'].toString()),
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text('Approve'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: isWebLayout ? 12 : 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _rejectUser(user['id'].toString()),
                                  icon: const Icon(Icons.close, size: 16),
                                  label: const Text('Reject'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isWebLayout ? 8 : 4),
                          Center(
                            child: Text(
                              'Tap for more details',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontStyle: FontStyle.italic,
                                fontSize: isWebLayout ? 12 : 10,
                              ),
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

  Widget _buildInfoRow(IconData icon, String text, bool isWebLayout) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isWebLayout ? 4 : 2),
      child: Row(
        children: [
          Icon(
            icon,
            size: isWebLayout ? 16 : 14,
            color: Colors.grey[600],
          ),
          SizedBox(width: isWebLayout ? 8 : 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isWebLayout ? 14 : 12,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxWidth(double screenWidth) {
    if (screenWidth <= 800) return 500;
    if (screenWidth <= 1200) return 600;
    return 800;
  }

  Future<void> _openUserDetails(Map<String, dynamic> user) async {
    if (user['role'] != 'Union Incharge') {
      // For non-union users, show a simple details dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${user['first_name']} ${user['last_name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Role: ${user['role']}'),
              Text('Email: ${user['email']}'),
              Text('Phone: ${user['phone'] ?? 'Not provided'}'),
              if (user['address'] != null)
                Text('Address: ${user['address']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _approveUser(user['id'].toString());
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Approve'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _rejectUser(user['id'].toString());
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reject'),
            ),
          ],
        ),
      );
      return;
    }
    
    // For Union Incharge users, navigate to detailed screen
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
