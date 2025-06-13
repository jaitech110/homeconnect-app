import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/payment_proof_service.dart';

class ManageResidentsScreen extends StatefulWidget {
  final String unionId;
  final String buildingName;

  const ManageResidentsScreen({
    Key? key,
    required this.unionId,
    required this.buildingName,
  }) : super(key: key);

  @override
  State<ManageResidentsScreen> createState() => _ManageResidentsScreenState();
}

class _ManageResidentsScreenState extends State<ManageResidentsScreen> {
  List<Map<String, dynamic>> approvedResidents = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchApprovedResidents();
  }

  String getBaseUrl() {
    return 'http://localhost:5000'; // Update this to your backend URL
  }

  Future<void> fetchApprovedResidents() async {
    try {
      setState(() {
        isLoading = true;
      });

      final baseUrl = getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/union/approved-residents?building_name=${widget.buildingName}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          approvedResidents = data.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load approved residents');
      }
    } catch (e) {
      print('❌ Error fetching approved residents: $e');
      setState(() {
        isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to load residents: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get filteredResidents {
    if (searchQuery.isEmpty) {
      return approvedResidents;
    }
    
    return approvedResidents.where((resident) {
      final firstName = resident['first_name']?.toString().toLowerCase() ?? '';
      final lastName = resident['last_name']?.toString().toLowerCase() ?? '';
      final email = resident['email']?.toString().toLowerCase() ?? '';
      final username = resident['username']?.toString().toLowerCase() ?? '';
      final phone = resident['phone']?.toString().toLowerCase() ?? '';
      
      final query = searchQuery.toLowerCase();
      
      return firstName.contains(query) ||
             lastName.contains(query) ||
             email.contains(query) ||
             username.contains(query) ||
             phone.contains(query);
    }).toList();
  }

  Future<void> showResidentDetails(Map<String, dynamic> resident) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildResidentDetailsModal(resident),
    );
  }

  Future<void> removeResident(String residentId, String residentName) async {
    // Show enhanced confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Remove Resident', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to remove $residentName from the building?',
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
                  Text('• All complaints submitted by this resident', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text('• All votes cast in building elections', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text('• All technical issues reported', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text('• All service requests made', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text('• All payment records and proofs', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text('• All app data associated with this resident', style: TextStyle(color: Colors.white70, fontSize: 14)),
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
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove & Delete All Data'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final baseUrl = getBaseUrl();
      final response = await http.delete(
        Uri.parse('$baseUrl/union/remove-resident/$residentId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'union_id': widget.unionId,
          'building_name': widget.buildingName,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final deletionReport = responseData['deletion_report'] as Map<String, dynamic>?;
        final totalDeleted = responseData['total_items_deleted'] as int? ?? 0;
        
        // Show detailed deletion report
        String reportMessage = '✅ $residentName removed successfully';
        if (totalDeleted > 0) {
          reportMessage += '\n\nData cleaned up:';
          if (deletionReport != null) {
            if (deletionReport['complaints'] > 0) {
              reportMessage += '\n• ${deletionReport['complaints']} complaint(s)';
            }
            if (deletionReport['votes'] > 0) {
              reportMessage += '\n• ${deletionReport['votes']} vote(s)';
            }
            if (deletionReport['technical_issues'] > 0) {
              reportMessage += '\n• ${deletionReport['technical_issues']} technical issue(s)';
            }
            if (deletionReport['service_requests'] > 0) {
              reportMessage += '\n• ${deletionReport['service_requests']} service request(s)';
            }
            if (deletionReport['verified_payments'] > 0) {
              reportMessage += '\n• ${deletionReport['verified_payments']} payment record(s)';
            }
            if (deletionReport['election_acknowledgments'] > 0) {
              reportMessage += '\n• ${deletionReport['election_acknowledgments']} election acknowledgment(s)';
            }
          }
          reportMessage += '\n\nTotal: $totalDeleted items removed';
        }
        
        // Also clean up local payment proof data
        await _cleanupLocalResidentData(response.body);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(reportMessage),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
        fetchApprovedResidents(); // Refresh the list
      } else {
        throw Exception('Failed to remove resident');
      }
    } catch (e) {
      print('❌ Error removing resident: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to remove $residentName'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Clean up local payment proof data for the removed resident
  Future<void> _cleanupLocalResidentData(String responseBody) async {
    try {
      final responseData = jsonDecode(responseBody);
      final residentData = responseData['resident'] as Map<String, dynamic>?;
      final residentId = residentData?['id']?.toString();
      
      if (residentId == null) return;
      
      print('🧹 Cleaning up local data for removed resident: $residentId');
      
      // Initialize PaymentProofService to clean up payment data
      final paymentService = PaymentProofService.instance;
      await paymentService.initialize();
      
      // Get all payment proofs to filter out the ones from removed resident
      final allProofs = await paymentService.getAllPaymentProofs();
      final proofsToRemove = allProofs.where((proof) => 
        proof['user_id'] == residentId || 
        proof['resident_id'] == residentId
      ).toList();
      
      // Get all verified payments to filter out the ones from removed resident  
      final allVerified = await paymentService.getVerifiedPayments();
      final verifiedToRemove = allVerified.where((payment) => 
        payment['user_id'] == residentId || 
        payment['resident_id'] == residentId
      ).toList();
      
      int localItemsRemoved = 0;
      
      // Remove payment proofs from local cache
      if (proofsToRemove.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final proofStrings = prefs.getStringList('payment_proofs') ?? [];
        
        final filteredProofs = proofStrings.where((proofString) {
          try {
            final proof = jsonDecode(proofString);
            return proof['user_id'] != residentId && proof['resident_id'] != residentId;
          } catch (e) {
            return true; // Keep if we can't parse
          }
        }).toList();
        
        if (filteredProofs.length != proofStrings.length) {
          await prefs.setStringList('payment_proofs', filteredProofs);
          localItemsRemoved += proofStrings.length - filteredProofs.length;
        }
      }
      
      // Remove verified payments from local cache  
      if (verifiedToRemove.isNotEmpty) {
        // Note: PaymentProofService might not have a direct remove verified method
        // so we'll clean this up through SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final verifiedStrings = prefs.getStringList('verified_payments') ?? [];
        
        final filteredVerified = verifiedStrings.where((verifiedString) {
          try {
            final payment = jsonDecode(verifiedString);
            return payment['user_id'] != residentId && payment['resident_id'] != residentId;
          } catch (e) {
            return true; // Keep if we can't parse
          }
        }).toList();
        
        if (filteredVerified.length != verifiedStrings.length) {
          await prefs.setStringList('verified_payments', filteredVerified);
          localItemsRemoved += verifiedStrings.length - filteredVerified.length;
        }
      }
      
      // Clean up any other resident-specific local data
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final residentKeys = allKeys.where((key) => 
        key.contains(residentId) || 
        key.endsWith('_$residentId') ||
        key.startsWith('${residentId}_')
      ).toList();
      
      for (final key in residentKeys) {
        await prefs.remove(key);
        localItemsRemoved++;
      }
      
      if (localItemsRemoved > 0) {
        print('🧹 Cleaned up $localItemsRemoved local items for resident $residentId');
      }
      
    } catch (e) {
      print('⚠️ Error cleaning up local resident data: $e');
      // Don't throw error as this is cleanup, main removal was successful
    }
  }

  // Generate test data for a resident to test cascade deletion
  Future<void> _generateTestData(String residentId, String residentName) async {
    try {
      final baseUrl = getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/debug/generate-test-data'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'resident_id': residentId}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final itemsCreated = responseData['items_created'] as int? ?? 0;
        final testData = responseData['test_data'] as Map<String, dynamic>?;
        
        String message = '🧪 Test data generated for $residentName\n\nCreated:';
        if (testData != null) {
          message += '\n• ${testData['complaints']} complaints';
          message += '\n• ${testData['technical_issues']} technical issues';
          message += '\n• ${testData['service_requests']} service requests';
          message += '\n• ${testData['verified_payments']} payment records';
          message += '\n• ${testData['election_votes']} election vote';
        }
        message += '\n\nTotal: $itemsCreated items\n\nNow you can test the cascade deletion by removing this resident.';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.blue,
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
      } else {
        throw Exception('Failed to generate test data');
      }
    } catch (e) {
      print('❌ Error generating test data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to generate test data for $residentName'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Residents'),
        backgroundColor: Colors.green,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchApprovedResidents,
            tooltip: 'Refresh',
          ),
        ],
      ),
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isWebLayout ? _getMaxWidth(screenWidth) : double.infinity,
          ),
          child: Column(
            children: [
              // Header card
              Container(
                width: double.infinity,
                margin: EdgeInsets.all(isWebLayout ? 24 : 16),
                padding: EdgeInsets.all(isWebLayout ? 24 : 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.apartment, 
                          color: Colors.green,
                          size: isWebLayout ? 28 : 24,
                        ),
                        SizedBox(width: isWebLayout ? 12 : 8),
                        Text(
                          widget.buildingName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isWebLayout ? 20 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isWebLayout ? 12 : 8),
                    Text(
                      '${filteredResidents.length} approved resident${filteredResidents.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isWebLayout ? 16 : 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isWebLayout ? 24 : 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: TextField(
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isWebLayout ? 16 : 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search residents...',
                      hintStyle: TextStyle(
                        color: Colors.white54,
                        fontSize: isWebLayout ? 16 : 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search, 
                        color: Colors.white54,
                        size: isWebLayout ? 28 : 24,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(isWebLayout ? 20 : 16),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
              ),

              SizedBox(height: isWebLayout ? 20 : 16),

              // Residents list
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.green),
                      )
                    : filteredResidents.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: isWebLayout ? 24 : 16),
                            itemCount: filteredResidents.length,
                            itemBuilder: (context, index) {
                              final resident = filteredResidents[index];
                              return _buildResidentCard(resident);
                            },
                          ),
              ),
            ],
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            searchQuery.isNotEmpty ? Icons.search_off : Icons.people_outline,
            size: 64,
            color: Colors.white24,
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isNotEmpty 
                ? 'No residents found matching "$searchQuery"'
                : 'No approved residents found',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          if (searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  searchQuery = '';
                });
              },
              child: const Text('Clear search'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResidentCard(Map<String, dynamic> resident) {
    final firstName = resident['first_name']?.toString() ?? '';
    final lastName = resident['last_name']?.toString() ?? '';
    final email = resident['email']?.toString() ?? '';
    final username = resident['username']?.toString() ?? '';
    final residentType = resident['resident_type']?.toString() ?? '';
    final phone = resident['phone']?.toString() ?? '';
    final approvedAt = resident['approved_at']?.toString() ?? '';

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
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1E1E1E),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => showResidentDetails(resident),
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
                    backgroundColor: Colors.green.withOpacity(0.2),
                    child: Text(
                      firstName.isNotEmpty ? firstName[0].toUpperCase() : 'R',
                      style: const TextStyle(
                        color: Colors.green,
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
                          '$firstName $lastName',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
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
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Approved',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(Icons.home, username.isNotEmpty ? username : 'N/A'),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.person, residentType.isNotEmpty ? residentType : 'N/A'),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _buildInfoChip(Icons.phone, phone),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildInfoChip(Icons.calendar_today, 'Approved: $formattedDate'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => showResidentDetails(resident),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _generateTestData(resident['id'], '$firstName $lastName'),
                      icon: const Icon(Icons.science, size: 16),
                      label: const Text('Test Data'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => removeResident(resident['id'], '$firstName $lastName'),
                      icon: const Icon(Icons.remove_circle_outline, size: 16),
                      label: const Text('Remove'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResidentDetailsModal(Map<String, dynamic> resident) {
    final firstName = resident['first_name']?.toString() ?? '';
    final lastName = resident['last_name']?.toString() ?? '';
    final email = resident['email']?.toString() ?? '';
    final phone = resident['phone']?.toString() ?? '';
    final address = resident['address']?.toString() ?? '';
    final username = resident['username']?.toString() ?? '';
    final residentType = resident['resident_type']?.toString() ?? '';
    final approvedAt = resident['approved_at']?.toString() ?? '';

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

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF121212),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white54,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.green, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Resident Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile section
                      _buildDetailSection(
                        'Personal Information',
                        Icons.person,
                        [
                          _buildDetailRow('Full Name', '$firstName $lastName'),
                          _buildDetailRow('Email', email),
                          _buildDetailRow('Phone', phone),
                          _buildDetailRow('Address', address),
                          _buildDetailRow('Flat/House No.', username),
                          _buildDetailRow('Resident Type', residentType),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Building Info
                      _buildDetailSection(
                        'Building Information',
                        Icons.apartment,
                        [
                          _buildDetailRow('Building', widget.buildingName),
                          _buildDetailRow('Approved Date', formattedDate),
                          _buildDetailRow('Status', 'Active Resident'),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Action buttons
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _generateTestData(resident['id'], '$firstName $lastName');
                                  },
                                  icon: const Icon(Icons.science),
                                  label: const Text('Generate Test Data'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                    side: const BorderSide(color: Colors.blue),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    removeResident(resident['id'], '$firstName $lastName');
                                  },
                                  icon: const Icon(Icons.remove_circle_outline),
                                  label: const Text('Remove Resident'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Not provided',
              style: TextStyle(
                color: value.isNotEmpty ? Colors.white : Colors.white54,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
