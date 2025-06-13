import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart';
import 'approved_union_detail_screen.dart';

class ApprovedUnionScreen extends StatefulWidget {
  const ApprovedUnionScreen({Key? key}) : super(key: key);

  @override
  State<ApprovedUnionScreen> createState() => _ApprovedUnionScreenState();
}

class _ApprovedUnionScreenState extends State<ApprovedUnionScreen> {
  List<Map<String, dynamic>> approvedUnions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchApprovedUnions();
  }

  Future<void> fetchApprovedUnions() async {
    setState(() {
      isLoading = true;
    });

    try {
      final baseUrl = getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/approved-unions'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        setState(() {
          approvedUnions = data.map((item) => {
            'id': item['id'] ?? '',
            'name': item['name'] ?? 'Unknown',
            'email': item['email'] ?? '',
            'phone': item['phone'] ?? '',
            'building_name': item['building_name'] ?? '',
            'address': item['address'] ?? '',
            'category': item['category'] ?? 'Apartment',
            'approved_at': item['approved_at'] ?? '',
            'role': item['role'] ?? 'Union Incharge',
          }).toList();
          isLoading = false;
        });
        
        print('✅ Fetched ${approvedUnions.length} approved unions');
      } else {
        print('❌ Failed to fetch approved unions: ${response.statusCode}');
        setState(() {
          approvedUnions = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching approved unions: $e');
      setState(() {
        approvedUnions = [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 600;
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Approved Unions'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchApprovedUnions,
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
              : _buildApprovedUnionsList(),
        ),
      ),
    );
  }

  double _getMaxWidth(double screenWidth) {
    if (screenWidth <= 800) return 500;
    if (screenWidth <= 1200) return 600;
    return 800;
  }

  Widget _buildApprovedUnionsList() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 600;
    
    if (approvedUnions.isEmpty) {
      return Center(
        child: Container(
          margin: EdgeInsets.all(isWebLayout ? 40 : 20),
          padding: EdgeInsets.all(isWebLayout ? 40 : 30),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.withOpacity(0.8),
                Colors.teal.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
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
                size: isWebLayout ? 80 : 64,
                color: Colors.white,
              ),
              SizedBox(height: isWebLayout ? 20 : 16),
              Text(
                'No approved unions yet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isWebLayout ? 24 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: isWebLayout ? 12 : 8),
              Text(
                'Union incharge approvals will appear here',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: isWebLayout ? 16 : 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(isWebLayout ? 24 : 16),
      itemCount: approvedUnions.length,
      itemBuilder: (context, index) {
        final union = approvedUnions[index];
        return _buildApprovedUnionCard(union);
      },
    );
  }

  Widget _buildApprovedUnionCard(Map<String, dynamic> union) {
    final userName = union['name']?.toString() ?? 'Unknown User';
    final userEmail = union['email']?.toString() ?? '';
    final userPhone = union['phone']?.toString() ?? '';
    final buildingName = union['building_name']?.toString() ?? '';
    final userAddress = union['address']?.toString() ?? '';
    final approvedAt = union['approved_at']?.toString() ?? '';
    
    // Get first letter for avatar
    final firstLetter = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
    
    // Format approved date
    String formattedDate = 'Unknown';
    if (approvedAt.isNotEmpty) {
      try {
        final date = DateTime.parse(approvedAt);
        formattedDate = '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        formattedDate = approvedAt.split('T')[0];
      }
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1E1E1E),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(union),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.green,
                    child: Text(
                      firstLetter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          buildingName.isNotEmpty ? buildingName : 'No building specified',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Approved',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white60,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow('Email', userEmail.isNotEmpty ? userEmail : 'Not provided'),
              _buildInfoRow('Phone', userPhone.isNotEmpty ? userPhone : 'Not provided'),
              _buildInfoRow('Address', userAddress.isNotEmpty ? userAddress : 'Not provided'),
              _buildInfoRow('Category', union['category']?.toString() ?? 'Not specified'),
              _buildInfoRow('Approved Date', formattedDate),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Tap to view details and manage this union incharge',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToDetail(Map<String, dynamic> union) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApprovedUnionDetailScreen(user: union),
      ),
    );
    
    // If user was removed, refresh the list
    if (result == true) {
      fetchApprovedUnions();
    }
  }
} 