import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart'; // Import for getBaseUrl function
import '../../utils/app_theme.dart';
import 'service_provider_detail_screen.dart';

class ServiceScreen extends StatefulWidget {
  final String userId;
  const ServiceScreen({super.key, required this.userId});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedServiceType;
  List<Map<String, dynamic>> serviceProviders = [];
  bool isLoadingProviders = false;
  
  final List<String> serviceTypes = [
    'Home & Utility Service',
    'Food & Catering',
    'Transport & Mobility'
  ];

  Future<void> _fetchServiceProviders(String category) async {
    setState(() {
      isLoadingProviders = true;
      serviceProviders = [];
    });

    try {
      final baseUrl = getBaseUrl();
      final url = '$baseUrl/resident/service-providers?category=${Uri.encodeComponent(category)}';
      
      print('🔗 Fetching service providers for category: $category');
      print('🔗 URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        setState(() {
          serviceProviders = data.map((item) => {
            'id': item['id'] ?? '',
            'name': item['name'] ?? 'Unknown Provider',
            'business_name': item['business_name'] ?? '',
            'category': item['category'] ?? '',
            'email': item['email'] ?? '',
            'phone': item['phone'] ?? '',
            'address': item['address'] ?? '',
            'services_completed': item['services_completed'] ?? 0,
            'description': item['description'] ?? 'Professional service provider',
            'approved_at': item['approved_at'] ?? '',
          }).toList();
          isLoadingProviders = false;
        });
        
        print('✅ Fetched ${serviceProviders.length} service providers');
      } else {
        throw Exception('Failed to fetch service providers: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching service providers: $e');
      setState(() {
        serviceProviders = [];
        isLoadingProviders = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading service providers: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 800;
    final maxWidth = screenWidth > 1200 ? 1000.0 : screenWidth > 800 ? 700.0 : screenWidth;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Request a Service'),
        backgroundColor: AppTheme.residentColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isLargeScreen ? 40 : 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    padding: EdgeInsets.all(isLargeScreen ? 24 : 20),
                    decoration: AppTheme.elevatedCardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.residentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.home_repair_service,
                                color: AppTheme.residentColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Find Service Providers', style: AppTheme.headingSmall),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Connect with trusted professionals in your area',
                                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.secondaryTextColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: isLargeScreen ? 32 : 24),
                  
                  // Service Type Category Dropdown
                  Container(
                    padding: EdgeInsets.all(isLargeScreen ? 24 : 20),
                    decoration: AppTheme.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Select Service Category', style: AppTheme.headingSmall),
                        const SizedBox(height: 16),
                        Theme(
                          data: Theme.of(context).copyWith(
                            canvasColor: Colors.white, // Sets dropdown background to white
                            textTheme: Theme.of(context).textTheme.copyWith(
                              bodyLarge: AppTheme.bodyMedium, // Ensures dropdown text uses readable color
                            ),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: selectedServiceType,
                            decoration: AppTheme.inputDecoration('Choose your service type', prefixIcon: Icons.category),
                            style: AppTheme.bodyMedium, // Style for selected item
                            dropdownColor: Colors.white, // Explicit white background for dropdown
                            items: serviceTypes.map((serviceType) {
                              return DropdownMenuItem(
                                value: serviceType, 
                                child: Text(
                                  serviceType, 
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.primaryTextColor, // Explicit readable color
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                selectedServiceType = val;
                              });
                              if (val != null) {
                                _fetchServiceProviders(val);
                              }
                            },
                            validator: (value) => value == null ? 'Please select a service type' : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: isLargeScreen ? 32 : 24),
                  
                  // Service Providers Section or Info Card
                  if (selectedServiceType != null) ...[
                    _buildServiceProvidersSection(),
                  ] else ...[
                    // Info Card when no category selected
                    AppTheme.infoCard(
                      icon: Icons.info_outline,
                      title: 'How it works',
                      subtitle: '1. Select your service category\n2. Browse available providers\n3. View profiles and contact details\n4. Connect directly for your needs',
                      iconColor: AppTheme.infoColor,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceProvidersSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 800;
    final crossAxisCount = screenWidth > 1200 ? 2 : 1;
    final childAspectRatio = screenWidth > 1200 ? 4.0 : 3.5;
    
    return Container(
      padding: EdgeInsets.all(isLargeScreen ? 24 : 20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Icon(Icons.people_outline, color: AppTheme.residentColor),
              const SizedBox(width: 8),
              Text('Available Service Providers', style: AppTheme.headingSmall),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Found ${serviceProviders.length} provider${serviceProviders.length == 1 ? '' : 's'} for $selectedServiceType',
            style: AppTheme.bodySmall,
          ),
          SizedBox(height: isLargeScreen ? 24 : 20),
          
          // Loading or Providers List
          if (isLoadingProviders) ...[
            AppTheme.loadingWidget(message: 'Finding service providers...'),
          ] else if (serviceProviders.isEmpty) ...[
            AppTheme.emptyStateWidget(
              icon: Icons.search_off,
              title: 'No providers found',
              subtitle: 'No service providers available for this category at the moment. Please try again later.',
            ),
          ] else ...[
            // Providers Grid - Responsive
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                mainAxisSpacing: isLargeScreen ? 16 : 12,
                crossAxisSpacing: isLargeScreen ? 16 : 0,
              ),
              itemCount: serviceProviders.length,
              itemBuilder: (context, index) {
                return _buildProviderCard(serviceProviders[index]);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> provider) {
    final name = provider['name'] ?? 'Unknown Provider';
    final businessName = provider['business_name'] ?? '';
    final servicesCompleted = provider['services_completed'] ?? 0;
    
    return Container(
      decoration: AppTheme.cardDecoration.copyWith(
        border: Border.all(color: AppTheme.residentColor.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServiceProviderDetailScreen(
                  serviceProvider: provider,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Provider Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.residentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'P',
                      style: AppTheme.headingSmall.copyWith(color: AppTheme.residentColor),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Provider Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(name, style: AppTheme.bodyLarge),
                      if (businessName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          businessName,
                          style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryTextColor),
                        ),
                      ],
                      const SizedBox(height: 4),
                      // Services completed only (rating removed)
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppTheme.successColor, size: 16),
                          const SizedBox(width: 4),
                          Text('$servicesCompleted jobs completed', style: AppTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.secondaryTextColor,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
