import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart';

class UnionApprovalDetailScreen extends StatefulWidget {
  final Map<String, dynamic> unionUser;

  const UnionApprovalDetailScreen({
    Key? key,
    required this.unionUser,
  }) : super(key: key);

  @override
  State<UnionApprovalDetailScreen> createState() => _UnionApprovalDetailScreenState();
}

class _UnionApprovalDetailScreenState extends State<UnionApprovalDetailScreen> {
  bool isProcessing = false;

  Future<void> approveUnion() async {
    setState(() {
      isProcessing = true;
    });

    try {
      final baseUrl = getBaseUrl();
      final userId = widget.unionUser['id']?.toString() ?? '';
      
      final response = await http.put(
        Uri.parse('$baseUrl/admin/union-approvals/$userId/approve'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Union Incharge ${widget.unionUser['name']} approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        print('✅ Union incharge approved: ${widget.unionUser['name']}');
        
        // Go back to the approval list
        Navigator.pop(context, 'approved');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to approve union');
      }
    } catch (e) {
      print('❌ Error approving union: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving union: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  Future<void> rejectUnion() async {
    setState(() {
      isProcessing = true;
    });

    try {
      final baseUrl = getBaseUrl();
      final userId = widget.unionUser['id']?.toString() ?? '';
      
      final response = await http.put(
        Uri.parse('$baseUrl/admin/union-approvals/$userId/reject'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Union Incharge ${widget.unionUser['name']} rejected'),
            backgroundColor: Colors.orange,
          ),
        );
        
        print('❌ Union incharge rejected: ${widget.unionUser['name']}');
        
        // Go back to the approval list
        Navigator.pop(context, 'rejected');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to reject union');
      }
    } catch (e) {
      print('❌ Error rejecting union: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting union: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = widget.unionUser['name']?.toString() ?? 'Unknown User';
    final userEmail = widget.unionUser['email']?.toString() ?? '';
    final userPhone = widget.unionUser['phone']?.toString() ?? '';
    final buildingName = widget.unionUser['building_name']?.toString() ?? '';
    final userAddress = widget.unionUser['address']?.toString() ?? '';
    final category = widget.unionUser['category']?.toString() ?? '';
    final submittedAt = widget.unionUser['submitted_at']?.toString() ?? '';
    final cnicImageUrl = widget.unionUser['cnic_image_url']?.toString() ?? '';
    
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Union Approval Details'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF121212),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            _buildProfileHeader(userName),
            const SizedBox(height: 24),
            
            // Personal Information
            _buildSectionCard(
              'Personal Information',
              Icons.person,
              [
                _buildDetailRow('Full Name', userName),
                _buildDetailRow('Email', userEmail),
                _buildDetailRow('Phone', userPhone),
                _buildDetailRow('Address', userAddress),
                _buildDetailRow('Category', category),
              ],
            ),
            const SizedBox(height: 16),
            
            // Building Information
            _buildSectionCard(
              'Building Information',
              Icons.apartment,
              [
                _buildDetailRow('Building Name', buildingName),
                _buildDetailRow('Role', 'Union Incharge'),
                _buildDetailRow('Submitted Date', formattedDate),
              ],
            ),
            const SizedBox(height: 16),
            
            // CNIC Information
            _buildCnicSection(cnicImageUrl),
            const SizedBox(height: 24),
            
            // Action Buttons
            _buildActionButtons(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String userName) {
    final firstLetter = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.deepPurpleAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Text(
              firstLetter,
              style: const TextStyle(
                color: Colors.deepPurple,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Pending Approval',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.deepPurpleAccent, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Not provided',
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

  Widget _buildCnicSection(String cnicImageUrl) {
    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.badge, color: Colors.deepPurpleAccent, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'CNIC Information',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (cnicImageUrl.isNotEmpty) ...[
              const Text(
                'CNIC Image:',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[600]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    cnicImageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[800],
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              color: Colors.white60,
                              size: 48,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'CNIC Image\n(Preview not available)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[600]!),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported,
                      color: Colors.white60,
                      size: 32,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No CNIC image provided',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isProcessing ? null : rejectUnion,
            icon: isProcessing 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.close),
            label: Text(isProcessing ? 'Processing...' : 'Reject'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isProcessing ? null : approveUnion,
            icon: isProcessing 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check),
            label: Text(isProcessing ? 'Processing...' : 'Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
} 