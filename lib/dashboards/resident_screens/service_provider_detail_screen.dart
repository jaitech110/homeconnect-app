import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';

class ServiceProviderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> serviceProvider;

  const ServiceProviderDetailScreen({
    Key? key,
    required this.serviceProvider,
  }) : super(key: key);

  @override
  State<ServiceProviderDetailScreen> createState() => _ServiceProviderDetailScreenState();
}

class _ServiceProviderDetailScreenState extends State<ServiceProviderDetailScreen> {
  bool _isRequestingService = false;

  @override
  Widget build(BuildContext context) {
    final name = widget.serviceProvider['name']?.toString() ?? 'Unknown Provider';
    final businessName = widget.serviceProvider['business_name']?.toString() ?? '';
    final category = widget.serviceProvider['category']?.toString() ?? '';
    final email = widget.serviceProvider['email']?.toString() ?? '';
    final phone = widget.serviceProvider['phone']?.toString() ?? '';
    final address = widget.serviceProvider['address']?.toString() ?? '';
    final servicesCompleted = widget.serviceProvider['services_completed']?.toString() ?? '0';
    final description = widget.serviceProvider['description']?.toString() ?? 'Professional service provider';
    
    // Format approval date
    final approvedAt = widget.serviceProvider['approved_at']?.toString() ?? '';
    final formattedApprovedDate = approvedAt.isNotEmpty ? 
      DateTime.tryParse(approvedAt)?.toString().split(' ')[0] ?? 'Unknown' : 'Unknown';

    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 800;
    final maxWidth = screenWidth > 1200 ? 800.0 : screenWidth > 800 ? 600.0 : screenWidth;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple, Colors.deepPurple.shade300],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isLargeScreen ? 32 : 24),
                    child: Column(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: isLargeScreen ? 60 : 50,
                          backgroundColor: Colors.white,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'S',
                            style: TextStyle(
                              fontSize: isLargeScreen ? 42 : 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ),
                        SizedBox(height: isLargeScreen ? 20 : 16),
                        
                        // Name and Business
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: isLargeScreen ? 28 : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (businessName.isNotEmpty) ...[
                          SizedBox(height: isLargeScreen ? 12 : 8),
                          Text(
                            businessName,
                            style: TextStyle(
                              fontSize: isLargeScreen ? 20 : 18,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        SizedBox(height: isLargeScreen ? 12 : 8),
                        
                        // Category Badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isLargeScreen ? 20 : 16, 
                            vertical: isLargeScreen ? 8 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: isLargeScreen ? 16 : 14,
                            ),
                          ),
                        ),
                        SizedBox(height: isLargeScreen ? 20 : 16),
                        
                        // Services and Status (rating removed)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem(
                              icon: Icons.check_circle,
                              value: servicesCompleted,
                              label: 'Completed',
                            ),
                            _buildStatItem(
                              icon: Icons.verified,
                              value: 'Verified',
                              label: 'Status',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Details Section
                Padding(
                  padding: EdgeInsets.all(isLargeScreen ? 24 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      _buildSectionCard(
                        'About',
                        Icons.info,
                        [
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: isLargeScreen ? 18 : 16,
                              height: 1.5,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: isLargeScreen ? 20 : 16),
                      
                      // Contact Information
                      _buildSectionCard(
                        'Contact Information',
                        Icons.contact_phone,
                        [
                          if (phone.isNotEmpty)
                            _buildContactRow(
                              icon: Icons.phone,
                              label: 'Phone',
                              value: phone,
                              onTap: () => _launchPhone(phone),
                            ),
                          if (email.isNotEmpty)
                            _buildContactRow(
                              icon: Icons.email,
                              label: 'Email',
                              value: email,
                              onTap: () => _launchEmail(email),
                            ),
                          if (address.isNotEmpty)
                            _buildContactRow(
                              icon: Icons.location_on,
                              label: 'Address',
                              value: address,
                              onTap: null,
                            ),
                        ],
                      ),
                      
                      SizedBox(height: isLargeScreen ? 20 : 16),
                      
                      // Service Details
                      _buildSectionCard(
                        'Service Details',
                        Icons.business,
                        [
                          _buildDetailRow('Category', category),
                          _buildDetailRow('Services Completed', servicesCompleted),
                          _buildDetailRow('Member Since', formattedApprovedDate),
                          _buildDetailRow('Status', 'Verified & Approved'),
                        ],
                      ),
                      
                      SizedBox(height: isLargeScreen ? 32 : 24),
                      
                      // Action Buttons
                      isLargeScreen 
                        ? Row(
                            children: [
                              if (phone.isNotEmpty)
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _launchPhone(phone),
                                    icon: const Icon(Icons.call),
                                    label: const Text('Call Now'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                  ),
                                ),
                              if (phone.isNotEmpty && email.isNotEmpty)
                                const SizedBox(width: 16),
                              if (email.isNotEmpty)
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _launchEmail(email),
                                    icon: const Icon(Icons.email),
                                    label: const Text('Send Email'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : Column(
                            children: [
                              if (phone.isNotEmpty)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _launchPhone(phone),
                                    icon: const Icon(Icons.call),
                                    label: const Text('Call Now'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              if (phone.isNotEmpty && email.isNotEmpty)
                                const SizedBox(height: 12),
                              if (email.isNotEmpty)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _launchEmail(email),
                                    icon: const Icon(Icons.email),
                                    label: const Text('Send Email'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                      
                      SizedBox(height: isLargeScreen ? 20 : 16),
                      
                      // Request Service Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isRequestingService ? null : () => _requestService(context),
                          icon: _isRequestingService 
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.build),
                          label: Text(_isRequestingService ? 'Sending Request...' : 'Request Service'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isRequestingService ? Colors.grey : Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
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

  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.deepPurple, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      color: onTap != null ? Colors.deepPurple : Colors.white,
                      decoration: onTap != null ? TextDecoration.underline : null,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.open_in_new, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _requestService(BuildContext context) async {
    final TextEditingController descriptionController = TextEditingController();
    
    // Show description dialog first
    final description = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Service'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request service from ${widget.serviceProvider['name']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Describe your requirements (optional):'),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g., Need plumbing repair in bathroom...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, descriptionController.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
    
    if (description == null) return; // User cancelled
    
    setState(() {
      _isRequestingService = true;
    });
    
    try {
      // Get current user from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      
      if (userData == null) {
        throw Exception('User not logged in');
      }
      
      final user = jsonDecode(userData);
      final userId = user['id'];
      final providerId = widget.serviceProvider['id'];
      final category = widget.serviceProvider['category'];
      
      // Send request to backend
      final baseUrl = getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/resident/service-requests'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'resident_id': userId,
          'provider_id': providerId,
          'category': category,
          'description': description.isNotEmpty ? description : 'Service request from ${user['first_name']} ${user['last_name']}',
          'priority': 'normal',
        }),
      );
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Service request sent to ${widget.serviceProvider['name']}!'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        throw Exception('Failed to send service request: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error sending service request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Failed to send service request: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingService = false;
        });
      }
    }
  }
} 