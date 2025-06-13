import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart'; // For getBaseUrl function

class ApprovedServiceProviderScreen extends StatefulWidget {
  const ApprovedServiceProviderScreen({Key? key}) : super(key: key);

  @override
  State<ApprovedServiceProviderScreen> createState() => _ApprovedServiceProviderScreenState();
}

class _ApprovedServiceProviderScreenState extends State<ApprovedServiceProviderScreen> {
  List<Map<String, dynamic>> approvedProviders = [];
  bool isLoading = true;
  String searchQuery = '';
  String selectedServiceType = 'All';

  final List<String> serviceTypes = [
    'All', 'Home & Utility Service', 'Food & Catering', 'Transport & Mobility'
  ];

  @override
  void initState() {
    super.initState();
    fetchApprovedProviders();
  }

  Future<void> fetchApprovedProviders() async {
    setState(() {
      isLoading = true;
    });

    try {
      final baseUrl = getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/approved-service-providers'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        setState(() {
          approvedProviders = data.map((item) => {
            'id': item['id'] ?? '',
            'name': item['name'] ?? 'Unknown',
            'email': item['email'] ?? '',
            'phone': item['phone'] ?? '',
            'business_name': item['business_name'] ?? '',
            'address': item['address'] ?? '',
            'category': item['category'] ?? 'Service Provider',
            'approved_at': item['approved_at'] ?? '',
            'cnic_image_url': item['cnic_image_url'] ?? '',
            'status': item['status'] ?? 'approved',
          }).toList();
          isLoading = false;
        });
        
        print('✅ Fetched ${approvedProviders.length} approved service providers');
      } else {
        print('❌ Failed to fetch approved service providers: ${response.statusCode}');
        setState(() {
          approvedProviders = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching approved service providers: $e');
      setState(() {
        approvedProviders = [];
        isLoading = false;
      });
    }
  }

  Future<void> removeProvider(String providerId) async {
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Remove Service Provider', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Are you sure you want to remove this service provider? This action cannot be undone.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final baseUrl = getBaseUrl();
        final response = await http.delete(
          Uri.parse('$baseUrl/admin/service-provider/$providerId'),
        );
        
        if (response.statusCode == 200) {
          final providerToRemove = approvedProviders.firstWhere((provider) => provider['id'] == providerId);
          
          setState(() {
            approvedProviders.removeWhere((provider) => provider['id'] == providerId);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Service Provider ${providerToRemove['name']} removed successfully'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to remove service provider'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing provider: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get filteredProviders {
    var filtered = approvedProviders;
    
    // Filter by service type
    if (selectedServiceType != 'All') {
      filtered = filtered.where((provider) {
        final category = provider['category']?.toString().toLowerCase() ?? '';
        final selectedType = selectedServiceType.toLowerCase();
        
        // Flexible matching for categories
        if (selectedType.contains('home') && category.contains('home')) {
          return true;
        } else if (selectedType.contains('food') && category.contains('food')) {
          return true;
        } else if (selectedType.contains('transport') && category.contains('transport')) {
          return true;
        } else {
          return provider['category'] == selectedServiceType; // Exact match fallback
        }
      }).toList();
    }
    
    // Filter by search query
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((provider) {
        return provider['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
               provider['category'].toLowerCase().contains(searchQuery.toLowerCase()) ||
               provider['business_name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
               provider['email'].toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approved Service Providers'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isWebLayout ? _getMaxWidth(screenWidth) : double.infinity,
          ),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildSearchAndFilter(),
                    _buildStatsCard(),
                    Expanded(child: _buildProvidersList()),
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

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search providers by name, business, category...',
              hintStyle: const TextStyle(color: Colors.white60),
              prefixIcon: const Icon(Icons.search, color: Colors.white60),
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),
          // Service type filter
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedServiceType,
                dropdownColor: const Color(0xFF1E1E1E),
                iconEnabledColor: Colors.white60,
                style: const TextStyle(color: Colors.white),
                items: serviceTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedServiceType = value!;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getProviderCountByCategory(List<Map<String, dynamic>> providers, String categoryPattern) {
    return providers.where((provider) {
      final category = provider['category']?.toString().toLowerCase() ?? '';
      return category.contains(categoryPattern);
    }).length;
  }

  Widget _buildStatsCard() {
    final filtered = filteredProviders;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        color: const Color(0xFF1E1E1E),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', '${filtered.length}', Colors.deepPurpleAccent),
              _buildStatItem('Home & Utility', '${_getProviderCountByCategory(filtered, 'home & utility')}', Colors.blue),
              _buildStatItem('Food & Catering', '${_getProviderCountByCategory(filtered, 'food & catering')}', Colors.orange),
              _buildStatItem('Transport', '${_getProviderCountByCategory(filtered, 'transport & mobility')}', Colors.green),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
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

  Widget _buildProvidersList() {
    final filtered = filteredProviders;
    
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          searchQuery.isEmpty && selectedServiceType == 'All' 
              ? 'No approved service providers found' 
              : 'No providers match your filters',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final provider = filtered[index];
        return _buildProviderCard(provider);
      },
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                CircleAvatar(
                  radius: 25,
                  backgroundColor: _getServiceTypeColor(provider['category']),
                  child: Icon(
                    _getServiceTypeIcon(provider['category']),
                    color: Colors.white,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        provider['category'],
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
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Business Name', provider['business_name']),
            _buildInfoRow('Email', provider['email']),
            _buildInfoRow('Phone', provider['phone']),
            _buildInfoRow('Address', provider['address']),
            _buildInfoRow('Category', provider['category']),
            _buildInfoRow('Approved Date', provider['approved_at'].toString().split('T')[0]),
            
            const SizedBox(height: 16),
            // Remove Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => removeProvider(provider['id']),
                icon: const Icon(Icons.delete),
                label: const Text('Remove Service Provider'),
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
          ],
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

  Color _getServiceTypeColor(String? serviceType) {
    if (serviceType == null) return Colors.deepPurpleAccent;
    
    switch (serviceType.toLowerCase()) {
      case 'home & utility services':
        return Colors.blue;
      case 'food & catering':
        return Colors.orange;
      case 'transport & mobility':
        return Colors.green;
      default:
        return Colors.deepPurpleAccent;
    }
  }

  IconData _getServiceTypeIcon(String? serviceType) {
    if (serviceType == null) return Icons.work;
    
    switch (serviceType.toLowerCase()) {
      case 'home & utility services':
        return Icons.home_repair_service;
      case 'food & catering':
        return Icons.restaurant;
      case 'transport & mobility':
        return Icons.directions_car;
      default:
        return Icons.work;
    }
  }
} 