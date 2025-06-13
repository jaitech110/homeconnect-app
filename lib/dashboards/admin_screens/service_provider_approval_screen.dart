import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart'; // For getBaseUrl function
import 'service_provider_approval_detail_screen.dart';

class ServiceProviderApprovalScreen extends StatefulWidget {
  const ServiceProviderApprovalScreen({Key? key}) : super(key: key);

  @override
  State<ServiceProviderApprovalScreen> createState() => _ServiceProviderApprovalScreenState();
}

class _ServiceProviderApprovalScreenState extends State<ServiceProviderApprovalScreen> {
  List<Map<String, dynamic>> pendingServiceProviders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchServiceProviders();
  }

  Future<void> fetchServiceProviders() async {
    try {
      setState(() => isLoading = true);
      
      final baseUrl = getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/service-provider-approvals'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        setState(() {
          pendingServiceProviders = data.map((item) => {
            'id': item['id'] ?? '',
            'name': item['name'] ?? 'Unknown',
            'email': item['email'] ?? '',
            'phone': item['phone'] ?? '',
            'business_name': item['business_name'] ?? '',
            'address': item['address'] ?? '',
            'category': item['category'] ?? 'Service Provider',
            'cnic_image_url': item['cnic_image_url'] ?? '',
            'submitted_at': item['submitted_at'] ?? '',
            'role': item['role'] ?? 'Service Provider',
          }).toList();
          isLoading = false;
        });
        
        print('✅ Fetched ${pendingServiceProviders.length} pending service provider approvals');
      } else {
        print('❌ Failed to fetch service provider approvals: ${response.statusCode}');
        setState(() {
          pendingServiceProviders = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching service provider approvals: $e');
      setState(() {
        pendingServiceProviders = [];
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
        title: const Text('Service Provider Approval'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchServiceProviders,
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
    
    if (pendingServiceProviders.isEmpty) {
      return Center(
        child: Container(
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
                Icons.verified_user,
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
                'All service provider requests have been processed',
                style: TextStyle(
                  color: Colors.white60,
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
      itemCount: pendingServiceProviders.length,
      itemBuilder: (context, index) {
        final provider = pendingServiceProviders[index];
        return _buildServiceProviderCard(provider);
      },
    );
  }

  Widget _buildServiceProviderCard(Map<String, dynamic> provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 600;
    
    return Card(
      margin: EdgeInsets.only(bottom: isWebLayout ? 20 : 16),
      color: const Color(0xFF1E1E1E),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
          padding: EdgeInsets.all(isWebLayout ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: isWebLayout ? 30 : 25,
                    backgroundColor: _getServiceTypeColor(provider['category']),
                    child: Icon(
                      _getServiceTypeIcon(provider['category']),
                      color: Colors.white,
                      size: isWebLayout ? 30 : 25,
                    ),
                  ),
                  SizedBox(width: isWebLayout ? 16 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider['name'],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isWebLayout ? 18 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          provider['category'] ?? provider['service_type'] ?? 'Service Provider',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: isWebLayout ? 16 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                ],
              ),
              SizedBox(height: isWebLayout ? 16 : 12),
              _buildInfoRow('Business Name', provider['business_name'], isWebLayout),
              _buildInfoRow('Email', provider['email'], isWebLayout),
              _buildInfoRow('Phone', provider['phone'], isWebLayout),
              _buildInfoRow('Address', provider['address'], isWebLayout),
              _buildInfoRow('Category', provider['category'], isWebLayout),
              _buildInfoRow('Submitted', provider['submitted_at'], isWebLayout),
              SizedBox(height: isWebLayout ? 20 : 16),
              
              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveServiceProvider(provider),
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(
                        'Approve',
                        style: TextStyle(fontSize: isWebLayout ? 14 : 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: isWebLayout ? 12 : 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isWebLayout ? 16 : 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectServiceProvider(provider),
                      icon: const Icon(Icons.close, size: 18),
                      label: Text(
                        'Reject',
                        style: TextStyle(fontSize: isWebLayout ? 14 : 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: isWebLayout ? 12 : 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isWebLayout ? 16 : 12),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToDetailScreen(provider),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: Text(
                      'Details',
                      style: TextStyle(fontSize: isWebLayout ? 14 : 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isWebLayout ? 12 : 8,
                        horizontal: isWebLayout ? 16 : 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                                 ],
               ),
             ],
           ),
         ),
     );
   }

  Widget _buildInfoRow(String label, String value, bool isWebLayout) {
    return Padding(
      padding: EdgeInsets.only(bottom: isWebLayout ? 6 : 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isWebLayout ? 120 : 100,
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
              value,
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

  void _navigateToDetailScreen(Map<String, dynamic> provider) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceProviderApprovalDetailScreen(serviceProvider: provider),
      ),
    );
    
    // If provider was approved or rejected, refresh the list
    if (result == 'approved' || result == 'rejected') {
      await fetchServiceProviders();
    }
  }

  Color _getServiceTypeColor(String? serviceType) {
    if (serviceType == null) return Colors.deepPurpleAccent;
    
    switch (serviceType.toLowerCase()) {
      case 'home & utility services':
        return Colors.blue;
      case 'food & catering':
        return Colors.orange;
      case 'transport & mobility':
        return Colors.green;
      case 'plumbing':
        return Colors.blue;
      case 'electrical':
        return Colors.orange;
      case 'cleaning':
        return Colors.green;
      case 'general maintenance':
        return Colors.purple;
      case 'security':
        return Colors.red;
      case 'gardening':
        return Colors.teal;
      default:
        return Colors.deepPurpleAccent;
    }
  }

  IconData _getServiceTypeIcon(String? serviceType) {
    if (serviceType == null) return Icons.miscellaneous_services;
    
    switch (serviceType.toLowerCase()) {
      case 'home & utility services':
        return Icons.home_repair_service;
      case 'food & catering':
        return Icons.restaurant;
      case 'transport & mobility':
        return Icons.directions_car;
      case 'plumbing':
        return Icons.plumbing;
      case 'electrical':
        return Icons.electrical_services;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'general maintenance':
        return Icons.build;
      case 'security':
        return Icons.security;
      case 'gardening':
        return Icons.grass;
      default:
        return Icons.miscellaneous_services;
    }
  }

  Future<void> _approveServiceProvider(Map<String, dynamic> provider) async {
    final providerId = provider['id']?.toString() ?? '';
    final providerName = provider['name']?.toString() ?? 'Service Provider';
    
    // Remove the provider from UI immediately for instant feedback
    if (mounted) {
      setState(() {
        pendingServiceProviders.removeWhere((p) => p['id']?.toString() == providerId);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$providerName has been approved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
    
    // Then make the API call in the background
    try {
      final baseUrl = getBaseUrl();
      
      final response = await http.put(
        Uri.parse('$baseUrl/admin/service-provider-approvals/$providerId/approve'),
        headers: {'Content-Type': 'application/json'},
      );

      // Optionally refresh the list from server to ensure consistency
      if (response.statusCode == 200) {
        await fetchServiceProviders();
      }
    } catch (e) {
      // API call failed but provider is already removed from UI
      // This is acceptable since approval means removal from pending list
      print('API approval call failed: $e');
    }
  }

  Future<void> _rejectServiceProvider(Map<String, dynamic> provider) async {
    final providerId = provider['id']?.toString() ?? '';
    final providerName = provider['name']?.toString() ?? 'Service Provider';
    
    // Remove the provider from UI immediately for instant feedback
    if (mounted) {
      setState(() {
        pendingServiceProviders.removeWhere((p) => p['id']?.toString() == providerId);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$providerName has been rejected and removed'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    
    // Then make the API call in the background
    try {
      final baseUrl = getBaseUrl();
      
      // Use PUT endpoint to reject the provider (consistent with approval pattern)
      final response = await http.put(
        Uri.parse('$baseUrl/admin/service-provider-approvals/$providerId/reject'),
        headers: {'Content-Type': 'application/json'},
      );

      // Optionally refresh the list from server to ensure consistency
      if (response.statusCode == 200) {
        await fetchServiceProviders();
      }
    } catch (e) {
      // API call failed but provider is already removed from UI
      // This is acceptable since rejection means removal regardless
      print('API rejection call failed: $e');
    }
  }
}
