import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart';

class AdminRemoveUsersScreen extends StatefulWidget {
  const AdminRemoveUsersScreen({super.key});

  @override
  State<AdminRemoveUsersScreen> createState() => _AdminRemoveUsersScreenState();
}

class _AdminRemoveUsersScreenState extends State<AdminRemoveUsersScreen> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchApprovedUsers();
  }

  Future<void> fetchApprovedUsers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${getBaseUrl()}/admin/approved_users'),
      );

      if (response.statusCode == 200) {
        // Safely parse response
        final List<dynamic> data = List<dynamic>.from(
          jsonDecode(response.body) is List ? jsonDecode(response.body) : []
        );
        
        // Log the received data for debugging
        print('Received approved users data: $data');
        
        // Transform to map with null safety and filter out the test user
        setState(() {
          users = data
            .where((item) => item is Map && item['email'] != 'union@test.com')
            .map((item) {
              if (item is Map) {
                return Map<String, dynamic>.from(item);
              }
              return <String, dynamic>{}; // Empty map instead of dummy data
            }).toList();
          
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load users: ${response.statusCode}';
          isLoading = false;
          users = [];
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
        users = [];
      });
    }
  }

  void _navigateToUserDetails(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailScreen(
          user: user,
          onRemoveUser: () async {
            await _removeUser(user['id'], _getUserFullName(user));
            Navigator.pop(context); // Return to the list screen after removing
          },
        ),
      ),
    );
  }

  Future<void> _removeUser(dynamic userId, String userName) async {
    // Ensure userId is valid
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Invalid user ID')),
      );
      return;
    }

    // Convert userId to an integer if it's not already
    int userIdInt;
    try {
      userIdInt = userId is int ? userId : int.parse(userId.toString());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Invalid user ID format - $e')),
      );
      return;
    }

    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Removal'),
        content: Text(
          'Are you sure you want to remove "$userName"? This action cannot be undone, and the user will need to sign up again to access the system.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);

    try {
      final response = await http.delete(
        Uri.parse('${getBaseUrl()}/admin/remove_user/$userIdInt'),
      );

      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$userName has been removed')),
        );
        fetchApprovedUsers(); // Refresh the list
      } else {
        Map<String, dynamic> data = {};
        try {
          data = jsonDecode(response.body);
        } catch (e) {
          // If response body is not valid JSON
          throw Exception('Failed to remove user: ${response.statusCode}');
        }
        throw Exception(data['message'] ?? 'Failed to remove user');
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Helper method to safely get user initials
  String _getInitials(Map<String, dynamic> user) {
    String firstInitial = '';
    String lastInitial = '';
    
    if (user['first_name'] != null && user['first_name'].toString().isNotEmpty) {
      firstInitial = user['first_name'].toString()[0];
    }
    
    if (user['last_name'] != null && user['last_name'].toString().isNotEmpty) {
      lastInitial = user['last_name'].toString()[0];
    }
    
    return firstInitial + lastInitial;
  }
  
  // Helper method to safely get user full name
  String _getUserFullName(Map<String, dynamic> user) {
    String firstName = user['first_name']?.toString() ?? '';
    String lastName = user['last_name']?.toString() ?? '';
    
    if (firstName.isEmpty && lastName.isEmpty) {
      return 'No Name Provided';
    }
    
    return '$firstName $lastName'.trim();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Manage Union Incharge'),
          backgroundColor: Colors.deepPurple,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Manage Union Incharge'),
          backgroundColor: Colors.deepPurple,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchApprovedUsers,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Union Incharge'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchApprovedUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: users.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No approved Union Incharge users found.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: fetchApprovedUsers,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final String userName = _getUserFullName(user);
                final String propertyName = user['building_name']?.toString() ?? 'Not assigned';
                
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(
                      userName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Property: $propertyName'),
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple,
                      child: Text(
                        _getInitials(user),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _navigateToUserDetails(user),
                  ),
                );
              },
            ),
    );
  }
}

class UserDetailScreen extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onRemoveUser;

  const UserDetailScreen({
    Key? key,
    required this.user,
    required this.onRemoveUser,
  }) : super(key: key);

  String _getUserFullName() {
    // Use the first_name and last_name directly from the user data
    String firstName = user['first_name']?.toString() ?? '';
    String lastName = user['last_name']?.toString() ?? '';
    
    if (firstName.isEmpty && lastName.isEmpty) {
      return 'No Name Provided';
    }
    
    return '$firstName $lastName'.trim();
  }

  void _openFullImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('CNIC Image'),
            backgroundColor: Colors.deepPurple,
          ),
          body: Container(
            color: Colors.black,
            child: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String userName = _getUserFullName();
    final String initials = userName.split(' ').map((name) => name.isNotEmpty ? name[0] : '').join('');
    
    // Debug print to see what data we're working with
    print('User detail data: $user');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile: $userName'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User profile header
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.deepPurple.shade100,
                      child: Text(
                        initials.isNotEmpty ? initials : 'UI',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Union Incharge',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Contact Information
              const Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const Divider(color: Colors.deepPurple),
              _buildInfoRow('Email', user['email']?.toString() ?? 'Not provided'),
              _buildInfoRow('Phone', user['phone']?.toString() ?? 'Not provided'),
              // Username field removed as requested
              
              const SizedBox(height: 24),
              
              // Property Information
              const Text(
                'Property Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const Divider(color: Colors.deepPurple),
              _buildInfoRow('Building', user['building_name']?.toString() ?? 'Not specified'),
              _buildInfoRow('Address', user['address']?.toString() ?? 'Not provided'),
              _buildInfoRow('Category', user['category']?.toString() ?? 'Not provided'),
              
              const SizedBox(height: 24),
              
              // CNIC Image
              const Text(
                'Identity Verification (CNIC)',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const Divider(color: Colors.deepPurple),
              const SizedBox(height: 8),
              
              if (user['cnic_image_url'] != null && user['cnic_image_url'].toString().isNotEmpty)
                InkWell(
                  onTap: () => _openFullImage(context, user['cnic_image_url']),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            user['cnic_image_url'],
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Text('Failed to load CNIC image'),
                            ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap to view full image',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Text('No CNIC image available'),
                
              const SizedBox(height: 32),
              
              // Remove User Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRemoveUser,
                  icon: const Icon(Icons.delete),
                  label: const Text('Remove User'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
