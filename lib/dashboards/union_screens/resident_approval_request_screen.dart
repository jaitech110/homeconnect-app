import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart';

class ResidentApprovalRequestScreen extends StatefulWidget {
  final String unionId;
  final String buildingName;

  const ResidentApprovalRequestScreen({
    Key? key,
    required this.unionId,
    required this.buildingName,
  }) : super(key: key);

  @override
  State<ResidentApprovalRequestScreen> createState() => _ResidentApprovalRequestScreenState();
}

class _ResidentApprovalRequestScreenState extends State<ResidentApprovalRequestScreen> {
  List<Map<String, dynamic>> pendingResidents = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchPendingResidents();
  }

  Future<void> fetchPendingResidents() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final baseUrl = getBaseUrl();
      // Get all users with role 'resident' and is_approved = false for this building
      final response = await http.get(
        Uri.parse('$baseUrl/union/pending-residents?building_name=${Uri.encodeComponent(widget.buildingName)}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          pendingResidents = data.map((item) => Map<String, dynamic>.from(item)).toList();
          isLoading = false;
        });
        print('✅ Loaded ${pendingResidents.length} pending residents for ${widget.buildingName}');
      } else {
        throw Exception('Failed to load pending residents: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching pending residents: $e');
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> approveResident(String residentId, String residentName) async {
    try {
      final baseUrl = getBaseUrl();
      final response = await http.put(
        Uri.parse('$baseUrl/union/approve-resident/$residentId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'union_id': widget.unionId,
          'building_name': widget.buildingName,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $residentName approved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        fetchPendingResidents(); // Refresh the list
      } else {
        throw Exception('Failed to approve resident');
      }
    } catch (e) {
      print('❌ Error approving resident: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to approve $residentName'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> rejectResident(String residentId, String residentName) async {
    try {
      final baseUrl = getBaseUrl();
      final response = await http.put(
        Uri.parse('$baseUrl/union/reject-resident/$residentId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'union_id': widget.unionId,
          'building_name': widget.buildingName,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $residentName rejected'),
            backgroundColor: Colors.orange,
          ),
        );
        fetchPendingResidents(); // Refresh the list
      } else {
        throw Exception('Failed to reject resident');
      }
    } catch (e) {
      print('❌ Error rejecting resident: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to reject $residentName'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showResidentDetails(Map<String, dynamic> resident) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildResidentDetailsModal(resident),
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
    final cnicImageUrl = resident['cnic_image_url']?.toString() ?? '';
    final submittedAt = resident['created_at']?.toString() ?? '';

    // Format submitted date
    String formattedDate = 'Unknown';
    if (submittedAt.isNotEmpty) {
      try {
        final date = DateTime.parse(submittedAt);
        formattedDate = '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        formattedDate = submittedAt.split('T')[0];
      }
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
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
                    const Icon(Icons.person_add, color: Colors.blue, size: 24),
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

                      // Application Info
                      _buildDetailSection(
                        'Application Information',
                        Icons.info,
                        [
                          _buildDetailRow('Building', widget.buildingName),
                          _buildDetailRow('Submitted Date', formattedDate),
                          _buildDetailRow('Status', 'Pending Approval'),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // CNIC Image
                      if (cnicImageUrl.isNotEmpty) ...[
                        _buildDetailSection(
                          'CNIC Document',
                          Icons.credit_card,
                          [],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: cnicImageUrl.startsWith('data:')
                                ? Image.memory(
                                    base64Decode(cnicImageUrl.split(',')[1]),
                                    fit: BoxFit.contain,
                                  )
                                : Image.network(
                                    cnicImageUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.broken_image, color: Colors.white54, size: 48),
                                            SizedBox(height: 8),
                                            Text('Failed to load CNIC image', style: TextStyle(color: Colors.white54)),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                rejectResident(resident['id'], '$firstName $lastName');
                              },
                              icon: const Icon(Icons.close),
                              label: const Text('Reject'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                approveResident(resident['id'], '$firstName $lastName');
                              },
                              icon: const Icon(Icons.check),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
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
            Icon(icon, color: Colors.blue, size: 20),
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
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(color: Colors.white70)),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resident Approval Requests'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: fetchPendingResidents,
            icon: const Icon(Icons.refresh),
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
          child: _buildBody(),
        ),
      ),
    );
  }

  double _getMaxWidth(double screenWidth) {
    if (screenWidth <= 800) return 500;
    if (screenWidth <= 1200) return 600;
    return 800;
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading pending residents...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading residents',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: fetchPendingResidents,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (pendingResidents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text(
              'No Pending Requests',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All resident requests for ${widget.buildingName} have been processed.',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: fetchPendingResidents,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header info
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.apartment, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    widget.buildingName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${pendingResidents.length} resident request${pendingResidents.length == 1 ? '' : 's'} pending approval',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),

        // Residents list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: pendingResidents.length,
            itemBuilder: (context, index) {
              final resident = pendingResidents[index];
              return _buildResidentCard(resident);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResidentCard(Map<String, dynamic> resident) {
    final firstName = resident['first_name']?.toString() ?? '';
    final lastName = resident['last_name']?.toString() ?? '';
    final email = resident['email']?.toString() ?? '';
    final username = resident['username']?.toString() ?? '';
    final residentType = resident['resident_type']?.toString() ?? '';
    final phone = resident['phone']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1E1E1E),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showResidentDetails(resident),
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
                    backgroundColor: Colors.blue.withOpacity(0.2),
                    child: Text(
                      firstName.isNotEmpty ? firstName[0].toUpperCase() : 'R',
                      style: const TextStyle(
                        color: Colors.blue,
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
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Pending',
                      style: TextStyle(
                        color: Colors.orange,
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => rejectResident(resident['id'], '$firstName $lastName'),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => approveResident(resident['id'], '$firstName $lastName'),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
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
} 