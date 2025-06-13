import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart';
import 'union_incharge_detail_screen.dart';

class UnionApprovalScreen extends StatefulWidget {
  const UnionApprovalScreen({Key? key}) : super(key: key);

  @override
  State<UnionApprovalScreen> createState() => _UnionApprovalScreenState();
}

class _UnionApprovalScreenState extends State<UnionApprovalScreen> {
  List<Map<String, dynamic>> pendingUnionApprovals = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUnionApprovals();
  }

  Future<void> fetchUnionApprovals() async {
    setState(() {
      isLoading = true;
    });

    try {
      final baseUrl = getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/union-approvals'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        print('📦 Received ${data.length} union approval records from API');
        for (var item in data) {
          print('👤 User: ${item['name']} (ID: ${item['id']}) - Status: ${item['status'] ?? 'no status'}');
        }
        
        setState(() {
          pendingUnionApprovals = data.map((item) => {
            'id': item['id'] ?? '',
            'name': item['name'] ?? 'Unknown',
            // Split name for detail screen compatibility
            'first_name': item['first_name'] ?? (item['name']?.split(' ').first ?? 'Unknown'),
            'last_name': item['last_name'] ?? (item['name']?.split(' ').length > 1 ? item['name']?.split(' ').skip(1).join(' ') : ''),
            'email': item['email'] ?? '',
            'phone': item['phone'] ?? '',
            'building_name': item['building_name'] ?? '',
            'address': item['address'] ?? '',
            'category': item['category'] ?? 'Apartment',
            'cnic_image_url': item['cnic_image_url'] ?? '',
            'submitted_at': item['submitted_at'] ?? '',
            'role': item['role'] ?? 'Union Incharge',
          }).toList();
          isLoading = false;
        });
        
        print('✅ Fetched ${pendingUnionApprovals.length} pending union approvals');
      } else {
        print('❌ Failed to fetch union approvals: ${response.statusCode}');
        setState(() {
          pendingUnionApprovals = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching union approvals: $e');
      setState(() {
        pendingUnionApprovals = [];
        isLoading = false;
      });
    }
  }

  void _navigateToDetailScreen(Map<String, dynamic> user) async {
    print('🚀 Navigating to detail screen for user: ${user['name']} (ID: ${user['id']})');
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnionInchargeDetailScreen(user: user),
      ),
    );
    
    print('📋 Received result from detail screen: $result');
    
    // If user was approved or rejected, refresh the list
    if (result == 'approved' || result == 'rejected') {
      print('🔄 Refreshing union approvals list after $result');
      await fetchUnionApprovals();
      print('✅ List refresh completed');
    } else {
      print('ℹ️ No refresh needed, result was: $result');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 600;
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Union Approval'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchUnionApprovals,
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isWebLayout ? _getMaxWidth(screenWidth) : double.infinity,
          ),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(context),
        ),
      ),
    );
  }

  double _getMaxWidth(double screenWidth) {
    if (screenWidth <= 800) return 500;
    if (screenWidth <= 1200) return 600;
    return 800;
  }

  Widget _buildContent(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 600;
    
    if (pendingUnionApprovals.isEmpty) {
      return Container(
        margin: EdgeInsets.all(isWebLayout ? 40 : 20),
        padding: EdgeInsets.all(isWebLayout ? 40 : 30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.withOpacity(0.8),
              Colors.purple.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: isWebLayout ? 80 : 60,
              color: Colors.white,
            ),
            SizedBox(height: isWebLayout ? 20 : 12),
            Text(
              'All Caught Up!',
              style: TextStyle(
                color: Colors.white,
                fontSize: isWebLayout ? 28 : 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isWebLayout ? 12 : 8),
            Text(
              'All union incharge requests have been processed',
              style: TextStyle(
                color: Colors.white60,
                fontSize: isWebLayout ? 16 : 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(isWebLayout ? 24 : 16),
      itemCount: pendingUnionApprovals.length,
      itemBuilder: (context, index) {
        final user = pendingUnionApprovals[index];
        return _buildUnionCard(user);
      },
    );
  }

  Widget _buildUnionCard(Map<String, dynamic> user) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 600;
    
    // Safely get values with null checks
    final userName = user['name']?.toString() ?? 'Unknown User';
    final userEmail = user['email']?.toString() ?? '';
    final userPhone = user['phone']?.toString() ?? '';
    final buildingName = user['building_name']?.toString() ?? '';
    final userAddress = user['address']?.toString() ?? '';
    final submittedAt = user['submitted_at']?.toString() ?? '';
    final userId = user['id']?.toString() ?? '';
    
    // Get first letter for avatar, with fallback
    final firstLetter = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
    
    // Format submitted date
    String formattedDate = 'Unknown';
    if (submittedAt.isNotEmpty) {
      try {
        final date = DateTime.parse(submittedAt);
        formattedDate = '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        formattedDate = submittedAt.split('T')[0];
      }
    }
    
    return Card(
      margin: EdgeInsets.only(bottom: isWebLayout ? 20 : 16),
      color: const Color(0xFF1E1E1E),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToDetailScreen(user),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isWebLayout ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: isWebLayout ? 30 : 25,
                    backgroundColor: Colors.deepPurpleAccent,
                    child: Text(
                      firstLetter,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isWebLayout ? 22 : 18,
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
                          userName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isWebLayout ? 18 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          buildingName.isNotEmpty ? buildingName : 'No building specified',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: isWebLayout ? 16 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isWebLayout ? 12 : 8,
                          vertical: isWebLayout ? 6 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Pending',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isWebLayout ? 14 : 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: isWebLayout ? 6 : 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white60,
                        size: isWebLayout ? 18 : 16,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: isWebLayout ? 16 : 12),
              _buildInfoRow('Email', userEmail.isNotEmpty ? userEmail : null, isWebLayout),
              _buildInfoRow('Phone', userPhone.isNotEmpty ? userPhone : null, isWebLayout),
              _buildInfoRow('Address', userAddress.isNotEmpty ? userAddress : null, isWebLayout),
              _buildInfoRow('Category', user['category']?.toString() ?? 'Not specified', isWebLayout),
              _buildInfoRow('Submitted', formattedDate, isWebLayout),
              SizedBox(height: isWebLayout ? 16 : 12),
              Container(
                padding: EdgeInsets.all(isWebLayout ? 16 : 12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.touch_app,
                      color: Colors.deepPurpleAccent,
                      size: isWebLayout ? 24 : 20,
                    ),
                    SizedBox(width: isWebLayout ? 12 : 8),
                    Text(
                      'Tap to view details and approve/reject',
                      style: TextStyle(
                        color: Colors.deepPurpleAccent,
                        fontSize: isWebLayout ? 16 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value, bool isWebLayout) {
    final displayValue = value?.toString() ?? 'Not provided';
    
    return Padding(
      padding: EdgeInsets.only(bottom: isWebLayout ? 6 : 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isWebLayout ? 100 : 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.white60,
                fontSize: isWebLayout ? 16 : 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: TextStyle(
                color: Colors.white,
                fontSize: isWebLayout ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 