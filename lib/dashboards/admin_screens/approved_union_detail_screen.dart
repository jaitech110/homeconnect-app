import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart';

class ApprovedUnionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const ApprovedUnionDetailScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<ApprovedUnionDetailScreen> createState() => _ApprovedUnionDetailScreenState();
}

class _ApprovedUnionDetailScreenState extends State<ApprovedUnionDetailScreen> {
  bool isRemoving = false;

  @override
  Widget build(BuildContext context) {
    final userName = widget.user['name']?.toString() ?? 'Unknown User';
    final userEmail = widget.user['email']?.toString() ?? '';
    final userPhone = widget.user['phone']?.toString() ?? '';
    final buildingName = widget.user['building_name']?.toString() ?? '';
    final userAddress = widget.user['address']?.toString() ?? '';
    final category = widget.user['category']?.toString() ?? '';
    final approvedAt = widget.user['approved_at']?.toString() ?? '';
    final userId = widget.user['id']?.toString() ?? '';

    // Get first letter for avatar
    final firstLetter = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    // Format approved date
    String formattedDate = 'Unknown';
    if (approvedAt.isNotEmpty) {
      try {
        final date = DateTime.parse(approvedAt);
        formattedDate = '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        formattedDate = approvedAt.split('T')[0];
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Approved Union Details'),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF121212),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Card
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Text(
                        firstLetter,
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Approved Union Incharge',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Personal Information Section
                  _buildSectionCard(
                    'Personal Information',
                    Icons.person,
                    [
                      _buildDetailRow('Full Name', userName),
                      _buildDetailRow('Email', userEmail),
                      _buildDetailRow('Phone', userPhone),
                      _buildDetailRow('Role', 'Union Incharge'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Building Information Section
                  _buildSectionCard(
                    'Building Information',
                    Icons.apartment,
                    [
                      _buildDetailRow('Building Name', buildingName.isNotEmpty ? buildingName : 'Not specified'),
                      _buildDetailRow('Address', userAddress.isNotEmpty ? userAddress : 'Not provided'),
                      _buildDetailRow('Category', category.isNotEmpty ? category : 'Not specified'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Approval Information Section
                  _buildSectionCard(
                    'Approval Information',
                    Icons.check_circle,
                    [
                      _buildDetailRow('Status', 'Approved ✅'),
                      _buildDetailRow('Approved Date', formattedDate),
                      _buildDetailRow('User ID', userId),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Privacy Notice Section
                  _buildPrivacyNoticeSection(),

                  const SizedBox(height: 24),

                  // Test Data Generation Button
                  _buildTestDataButton(),

                  const SizedBox(height: 16),

                  // Remove Button
                  _buildRemoveButton(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.green, size: 24),
                const SizedBox(width: 12),
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

  Widget _buildPrivacyNoticeSection() {
    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.privacy_tip, color: Colors.green, size: 24),
                SizedBox(width: 12),
                Text(
                  'Privacy Notice',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'CNIC images are sensitive and should only be shown during the approval process. They should not be shared or displayed after approval for privacy/security reasons.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestDataButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: isRemoving ? null : _generateUnionTestData,
        icon: const Icon(Icons.science),
        label: const Text('Generate Comprehensive Test Data'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.blue,
          side: const BorderSide(color: Colors.blue),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildRemoveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isRemoving ? null : _showRemoveConfirmation,
        icon: isRemoving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.delete),
        label: Text(isRemoving ? 'Removing...' : 'Remove Union Incharge'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _showRemoveConfirmation() async {
    final userName = widget.user['name']?.toString() ?? 'this user';
    final buildingName = widget.user['building_name']?.toString() ?? 'their building';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text(
                'Remove Union Incharge',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to remove $userName as a union incharge?',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.delete_forever, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'This will permanently delete:',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('• ALL residents in $buildingName', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text('• ALL complaints from these residents', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text('• ALL votes cast by these residents', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text('• ALL elections created by this union incharge', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text('• ALL notices for this building', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text('• ALL technical issues from residents', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text('• ALL payment records and proofs', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text('• Bank details for this building', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text('• ALL data associated with this building', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text(
                'This action cannot be undone!',
                style: const TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Remove & Delete All Building Data'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _removeUnionIncharge();
    }
  }

  Future<void> _removeUnionIncharge() async {
    setState(() {
      isRemoving = true;
    });

    try {
      final userId = widget.user['id']?.toString() ?? '';
      final baseUrl = getBaseUrl();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/union-incharge/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final unionData = responseData['union_incharge'] as Map<String, dynamic>?;
        final deletionReport = responseData['deletion_report'] as Map<String, dynamic>?;
        final totalDeleted = responseData['total_items_deleted'] as int? ?? 0;
        
        final userName = unionData?['name'] ?? widget.user['name']?.toString() ?? 'User';
        final buildingName = unionData?['building_name'] ?? 'the building';
        
        // Show detailed deletion report
        String reportMessage = '✅ $userName removed successfully';
        reportMessage += '\n🏢 Building: $buildingName';
        
        if (totalDeleted > 0) {
          reportMessage += '\n\nComprehensive cleanup completed:';
          if (deletionReport != null) {
            if (deletionReport['residents_removed'] > 0) {
              reportMessage += '\n• ${deletionReport['residents_removed']} resident(s)';
            }
            if (deletionReport['complaints_removed'] > 0) {
              reportMessage += '\n• ${deletionReport['complaints_removed']} complaint(s)';
            }
            if (deletionReport['votes_removed'] > 0) {
              reportMessage += '\n• ${deletionReport['votes_removed']} vote(s)';
            }
            if (deletionReport['elections_removed'] > 0) {
              reportMessage += '\n• ${deletionReport['elections_removed']} election(s)';
            }
            if (deletionReport['notices_removed'] > 0) {
              reportMessage += '\n• ${deletionReport['notices_removed']} notice(s)';
            }
            if (deletionReport['technical_issues_removed'] > 0) {
              reportMessage += '\n• ${deletionReport['technical_issues_removed']} technical issue(s)';
            }
            if (deletionReport['service_requests_removed'] > 0) {
              reportMessage += '\n• ${deletionReport['service_requests_removed']} service request(s)';
            }
            if (deletionReport['verified_payments_removed'] > 0) {
              reportMessage += '\n• ${deletionReport['verified_payments_removed']} payment record(s)';
            }
            if (deletionReport['bank_details_removed'] > 0) {
              reportMessage += '\n• ${deletionReport['bank_details_removed']} bank detail(s)';
            }
            if (deletionReport['election_acknowledgments_removed'] > 0) {
              reportMessage += '\n• ${deletionReport['election_acknowledgments_removed']} acknowledgment(s)';
            }
          }
          reportMessage += '\n\nTotal: $totalDeleted items removed from the entire building';
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(reportMessage),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 8),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
          
          // Go back to approved unions screen
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to remove union incharge'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isRemoving = false;
        });
      }
    }
  }

  // Generate comprehensive test data for this union incharge
  Future<void> _generateUnionTestData() async {
    try {
      final userId = widget.user['id']?.toString() ?? '';
      final baseUrl = getBaseUrl();
      
      final response = await http.post(
        Uri.parse('$baseUrl/debug/generate-union-test-data'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'union_id': userId}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final unionName = responseData['union_name'];
        final buildingName = responseData['building_name'];
        final itemsCreated = responseData['items_created'] as int? ?? 0;
        final testData = responseData['test_data'] as Map<String, dynamic>?;
        
        String message = '🧪 Comprehensive test data generated for $unionName\n🏢 Building: $buildingName\n\nCreated:';
        if (testData != null) {
          message += '\n• ${testData['residents']} test residents';
          message += '\n• ${testData['complaints']} complaints';
          message += '\n• ${testData['elections']} elections';
          message += '\n• ${testData['notices']} notices';
          message += '\n• ${testData['bank_details']} bank detail record';
          message += '\n• ${testData['technical_issues']} technical issues';
          message += '\n• ${testData['verified_payments']} payment records';
          message += '\n• ${testData['total_votes']} votes across elections';
        }
        message += '\n\nTotal: $itemsCreated items\n\nNow you can test the comprehensive cascade deletion by removing this union incharge. All data will be cleaned up!';
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 10),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      } else {
        throw Exception('Failed to generate test data');
      }
    } catch (e) {
      print('❌ Error generating union test data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to generate test data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 