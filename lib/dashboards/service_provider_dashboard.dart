import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';
import '../utils/token_utility.dart';
import '../utils/api_utils.dart';
import 'service_provider_screens/technical_issues_screen.dart';
import 'service_provider_screens/my_profile_screen.dart';
import 'service_provider_screens/new_requests.dart';
import 'service_provider_screens/my_requests.dart';

class ServiceProviderDashboard extends StatefulWidget {
  final String providerName;
  final String providerId;

  const ServiceProviderDashboard({
    Key? key,
    required this.providerName,
    required this.providerId,
  }) : super(key: key);

  @override
  State<ServiceProviderDashboard> createState() => _ServiceProviderDashboardState();
}

class _ServiceProviderDashboardState extends State<ServiceProviderDashboard> {
  Map<String, dynamic>? providerStats;
  bool isLoadingStats = true;
  String? businessCategory;

  @override
  void initState() {
    super.initState();
    print('🏠 Service Provider Dashboard initialized');
    print('   Provider Name: ${widget.providerName}');
    print('   Provider ID: ${widget.providerId}');
    fetchProviderStats();
  }

  Future<void> fetchProviderStats() async {
    try {
      final baseUrl = getBaseUrl();
      final url = Uri.parse('$baseUrl/provider/profile/${widget.providerId}');
      
      print('📊 Fetching provider stats for: ${widget.providerId}');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Also get pending requests count
        final pendingUrl = Uri.parse('$baseUrl/provider/service-requests/${widget.providerId}');
        final pendingResponse = await http.get(pendingUrl);
        
        int pendingCount = 0;
        
        if (pendingResponse.statusCode == 200) {
          final pendingData = jsonDecode(pendingResponse.body);
          pendingCount = (pendingData as List).length;
        }
        
        setState(() {
          providerStats = {
            'services_completed': data['profile']['services_completed'] ?? 0,
            'pending_requests': pendingCount,
          };
          // Extract business category from profile
          businessCategory = data['profile']['category']?.toString() ?? 
                           data['profile']['business_category']?.toString() ??
                           data['profile']['service_categories']?.toString();
          isLoadingStats = false;
        });
        
        print('✅ Provider stats loaded successfully:');
        print('   Completed: ${providerStats!['services_completed']}');
        print('   Pending: ${providerStats!['pending_requests']}');
        
      } else {
        throw Exception('Failed to load provider stats: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching provider stats: $e');
      setState(() {
        providerStats = {
          'services_completed': 0,
          'pending_requests': 0,
        };
        isLoadingStats = false;
      });
    }
  }

  // Method to refresh stats (can be called when returning from other screens)
  void refreshStats() {
    setState(() {
      isLoadingStats = true;
    });
    fetchProviderStats();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 600;
    final maxWidth = screenWidth > 1200 ? 800.0 : 
                     screenWidth > 800 ? 600.0 : 
                     screenWidth > 600 ? 500.0 : double.infinity;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            children: [
              // Custom header with gradient
              _buildGradientHeader(context),
              // Main content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWebLayout ? 24 : 20,
                    ),
                    child: Column(
                      children: [
                        // Welcome card
                        _buildWelcomeCard(context),
                        SizedBox(height: isWebLayout ? 24 : 20),
                        // Stats cards
                        _buildStatsRow(),
                        SizedBox(height: isWebLayout ? 24 : 20),
                        // Services grid
                        _buildServicesGrid(context),
                        SizedBox(height: isWebLayout ? 24 : 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientHeader(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 600;
    
    return Container(
      height: 120,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF7B1FA2), // Dark Purple
            Color(0xFF9C27B0), // Light Purple
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Empty space for balance
              const SizedBox(width: 28),
              // HomeConnect title
              const Text(
                'HomeConnect',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Right side icons
              Row(
                children: [
                  GestureDetector(
                    onTap: refreshStats,
                    child: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 15),
                  GestureDetector(
                    onTap: () {
                      TokenUtility.clearToken();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => LoginPage()),
                      );
                    },
                    child: const Icon(
                      Icons.logout,
                      color: Colors.white,
                      size: 24,
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

  Widget _buildWelcomeCard(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 600;
    
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: isWebLayout ? 16 : 10,
      ),
      padding: EdgeInsets.all(isWebLayout ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: isWebLayout ? 18 : 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                Icons.work_outline,
                color: Colors.purple[600],
                size: isWebLayout ? 28 : 24,
              ),
            ],
          ),
          SizedBox(height: isWebLayout ? 12 : 8),
          Text(
            widget.providerName.isNotEmpty ? widget.providerName : 'Service Provider',
            style: TextStyle(
              fontSize: isWebLayout ? 32 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isWebLayout ? 8 : 4),
          Text(
            'Manage your services and requests',
            style: TextStyle(
              fontSize: isWebLayout ? 18 : 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 600;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Completed Jobs',
            isLoadingStats ? '...' : (providerStats?['services_completed']?.toString() ?? '0'),
            Icons.check_circle_outline,
            Colors.green[600]!,
          ),
        ),
        SizedBox(width: isWebLayout ? 16 : 12),
        Expanded(
          child: _buildStatCard(
            'Pending',
            isLoadingStats ? '...' : (providerStats?['pending_requests']?.toString() ?? '0'),
            Icons.pending_outlined,
            Colors.orange[600]!,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 600;
    
    return Container(
      padding: EdgeInsets.all(isWebLayout ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isWebLayout ? 12 : 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon, 
              color: color, 
              size: isWebLayout ? 24 : 20,
            ),
          ),
          SizedBox(height: isWebLayout ? 12 : 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isWebLayout ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: isWebLayout ? 6 : 4),
          Text(
            title,
            style: TextStyle(
              fontSize: isWebLayout ? 13 : 11,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildServicesGrid(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 600;
    
    // Responsive grid configuration
    int crossAxisCount;
    double childAspectRatio;
    
    if (screenWidth <= 600) {
      // Mobile: 2 columns
      crossAxisCount = 2;
      childAspectRatio = 0.85;
    } else if (screenWidth <= 800) {
      // Tablet: 2 columns
      crossAxisCount = 2;
      childAspectRatio = 1.0;
    } else if (screenWidth <= 1200) {
      // Medium desktop: 3 columns
      crossAxisCount = 3;
      childAspectRatio = 1.1;
    } else {
      // Large desktop: 4 columns
      crossAxisCount = 4;
      childAspectRatio = 1.0;
    }
    
    final List<Map<String, dynamic>> services = [
      {
        'icon': Icons.new_releases_outlined,
        'label': 'New Requests',
        'color': Colors.blue[600],
        'screen': () => NewRequestsScreen(providerId: widget.providerId),
      },
      {
        'icon': Icons.assignment_outlined,
        'label': 'My Requests',
        'color': Colors.purple[600],
        'screen': () => MyRequestsScreen(providerId: widget.providerId),
      },
      {
        'icon': Icons.person_outline,
        'label': 'My Profile',
        'color': Colors.green[600],
        'screen': () => MyProfileScreen(
          providerId: widget.providerId,
        ),
      },
      {
        'icon': Icons.bug_report_outlined,
        'label': 'Technical Issues',
        'color': Colors.red[600],
        'screen': () => TechnicalIssuesScreen(
          providerId: widget.providerId,
          providerName: widget.providerName,
          businessCategory: businessCategory,
        ),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: isWebLayout ? 20 : 15,
        mainAxisSpacing: isWebLayout ? 20 : 15,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => service['screen']()),
            );
            // Refresh stats when returning from certain screens
            if (mounted && (service['label'] == 'My Requests' || service['label'] == 'New Requests')) {
              refreshStats();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(isWebLayout ? 16 : 12),
                  decoration: BoxDecoration(
                    color: service['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    service['icon'],
                    size: isWebLayout ? 36 : 32,
                    color: service['color'],
                  ),
                ),
                SizedBox(height: isWebLayout ? 16 : 12),
                Text(
                  service['label'],
                  style: TextStyle(
                    fontSize: isWebLayout ? 15 : 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

