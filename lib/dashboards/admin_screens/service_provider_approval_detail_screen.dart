import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import '../../main.dart';

class ServiceProviderApprovalDetailScreen extends StatefulWidget {
  final Map<String, dynamic> serviceProvider;

  const ServiceProviderApprovalDetailScreen({
    Key? key,
    required this.serviceProvider,
  }) : super(key: key);

  @override
  State<ServiceProviderApprovalDetailScreen> createState() => _ServiceProviderApprovalDetailScreenState();
}

class _ServiceProviderApprovalDetailScreenState extends State<ServiceProviderApprovalDetailScreen> {
  bool isApproving = false;
  bool isRejecting = false;

  @override
  Widget build(BuildContext context) {
    final providerName = widget.serviceProvider['name']?.toString() ?? 'Unknown Provider';
    final providerEmail = widget.serviceProvider['email']?.toString() ?? '';
    final providerPhone = widget.serviceProvider['phone']?.toString() ?? '';
    final businessName = widget.serviceProvider['business_name']?.toString() ?? 
                      widget.serviceProvider['username']?.toString() ?? '';
    final providerAddress = widget.serviceProvider['address']?.toString() ?? 
                           widget.serviceProvider['business_address']?.toString() ?? '';
    final category = widget.serviceProvider['category']?.toString() ?? '';
    final submittedAt = widget.serviceProvider['submitted_at']?.toString() ?? '';
    final cnicImageUrl = widget.serviceProvider['cnic_image_url']?.toString() ?? '';

    // Get first letter for avatar
    final firstLetter = providerName.isNotEmpty ? providerName[0].toUpperCase() : 'S';

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
        title: const Text('Service Provider Approval'),
        backgroundColor: Colors.deepPurple,
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
                  colors: [Color(0xFF7B1FA2), Color(0xFF9C27B0)],
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
                          color: Colors.deepPurple,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      providerName,
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
                      child: Text(
                        category.isNotEmpty ? category : 'Service Provider',
                        style: const TextStyle(
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
                      _buildDetailRow('Full Name', providerName),
                      _buildDetailRow('Email', providerEmail),
                      _buildDetailRow('Phone', providerPhone),
                      _buildDetailRow('Role', 'Service Provider'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Business Information Section
                  _buildSectionCard(
                    'Business Information',
                    Icons.business,
                    [
                      _buildDetailRow('Business Name', businessName.isNotEmpty ? businessName : 'Not specified'),
                      _buildDetailRow('Category', category.isNotEmpty ? category : 'Not specified'),
                      _buildDetailRow('Address', providerAddress.isNotEmpty ? providerAddress : 'Not provided'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Submission Information Section
                  _buildSectionCard(
                    'Submission Information',
                    Icons.info,
                    [
                      _buildDetailRow('Status', 'Pending Approval ⏳'),
                      _buildDetailRow('Submitted Date', formattedDate),
                      _buildDetailRow('Provider ID', widget.serviceProvider['id']?.toString() ?? ''),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // CNIC Information Section
                  _buildCnicSection(cnicImageUrl),

                  const SizedBox(height: 24),

                  // Action Buttons
                  _buildActionButtons(),

                  const SizedBox(height: 16),
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
                Icon(icon, color: Colors.deepPurple, size: 24),
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
                const Icon(Icons.badge, color: Colors.deepPurple, size: 24),
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
                  child: _buildCnicImage(cnicImageUrl),
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

  Widget _buildCnicImage(String cnicImageUrl) {
    if (cnicImageUrl.startsWith('data:image')) {
      // Handle base64 data URL
      try {
        final base64String = cnicImageUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildCnicError('Error loading image');
          },
        );
      } catch (e) {
        return _buildCnicError('Invalid image data');
      }
    } else {
      // Handle regular URL
      return Image.network(
        cnicImageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.deepPurple,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildCnicError('Failed to load image');
        },
      );
    }
  }

  Widget _buildCnicError(String message) {
    return Container(
      color: Colors.grey[800],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            color: Colors.white60,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isApproving || isRejecting ? null : _approveServiceProvider,
            icon: isApproving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.check),
            label: Text(isApproving ? 'Approving...' : 'Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isApproving || isRejecting ? null : _rejectServiceProvider,
            icon: isRejecting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.close),
            label: Text(isRejecting ? 'Rejecting...' : 'Reject'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _approveServiceProvider() async {
    setState(() {
      isApproving = true;
    });

    try {
      final providerId = widget.serviceProvider['id']?.toString() ?? '';
      final baseUrl = getBaseUrl();
      
      final response = await http.put(
        Uri.parse('$baseUrl/admin/service-provider-approvals/$providerId/approve'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final providerName = widget.serviceProvider['name']?.toString() ?? 'Service Provider';
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$providerName has been approved successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Go back to approval screen with result
          Navigator.of(context).pop('approved');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to approve service provider'),
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
          isApproving = false;
        });
      }
    }
  }

  Future<void> _rejectServiceProvider() async {
    setState(() {
      isRejecting = true;
    });

    try {
      final providerId = widget.serviceProvider['id']?.toString() ?? '';
      final baseUrl = getBaseUrl();
      
      final response = await http.put(
        Uri.parse('$baseUrl/admin/service-provider-approvals/$providerId/reject'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final providerName = widget.serviceProvider['name']?.toString() ?? 'Service Provider';
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$providerName has been rejected'),
              backgroundColor: Colors.orange,
            ),
          );
          
          // Go back to approval screen with result
          Navigator.of(context).pop('rejected');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to reject service provider'),
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
          isRejecting = false;
        });
      }
    }
  }
} 