import 'package:flutter/material.dart';
import 'admin_screens/admin_approval_screen.dart';
import 'admin_screens/admin_query_inbox_screen.dart';
import 'admin_screens/admin_resolved_complaints.dart';
import 'admin_screens/payment_status_screen.dart';
import 'admin_screens/union_approval_screen.dart';
import 'admin_screens/service_provider_approval_screen.dart';
import 'admin_screens/approved_union_screen.dart';
import 'admin_screens/approved_service_provider_screen.dart';
import '/main.dart';
import 'admin_screens/admin_users_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 600;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Custom header with gradient
          _buildGradientHeader(context),
          // Main content
          Expanded(
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isWebLayout ? _getMaxWidth(screenWidth) : double.infinity,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWebLayout ? 40 : 0,
                  ),
                  child: Column(
                    children: [
                      // Welcome card
                      _buildWelcomeCard(context),
                      const SizedBox(height: 20),
                      // Services grid
                      _buildServicesGrid(context),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxWidth(double screenWidth) {
    if (screenWidth <= 800) return 500;
    if (screenWidth <= 1200) return 600;
    return 800;
  }

  int _getCrossAxisCount(double screenWidth) {
    if (screenWidth <= 600) return 3;
    if (screenWidth <= 800) return 3;
    if (screenWidth <= 1200) return 4;
    return 5;
  }

  double _getIconSize(double screenWidth) {
    if (screenWidth <= 600) return 32;
    if (screenWidth <= 800) return 32;
    if (screenWidth <= 1200) return 30;
    return 28;
  }

  double _getFontSize(double screenWidth) {
    if (screenWidth <= 600) return 13;
    if (screenWidth <= 800) return 13;
    if (screenWidth <= 1200) return 14;
    return 15;
  }

  Widget _buildGradientHeader(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 600;
    
    return Container(
      height: isWebLayout ? 100 : 120,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6A1B9A), // Dark Purple
            Color(0xFF8E24AA), // Light Purple
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isWebLayout ? 40 : 20,
            vertical: 10,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Empty space for balance
              const SizedBox(width: 28),
              // HomeConnect title
              Text(
                'HomeConnect',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isWebLayout ? 28 : 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Logout icon
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => LoginPage()),
                  );
                },
                child: Icon(
                  Icons.logout,
                  color: Colors.white,
                  size: isWebLayout ? 28 : 24,
                ),
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
        horizontal: isWebLayout ? 0 : 20,
        vertical: 10,
      ),
      padding: EdgeInsets.all(isWebLayout ? 30 : 20),
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
                Icons.admin_panel_settings,
                color: Colors.purple[600],
                size: isWebLayout ? 28 : 24,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Admin',
            style: TextStyle(
              fontSize: isWebLayout ? 36 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage approvals and society operations',
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

  Widget _buildServicesGrid(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 600;
    
    final List<Map<String, dynamic>> services = [
      {
        'icon': Icons.group_outlined,
        'label': 'Union Approval',
        'color': Colors.blue[600],
        'screen': () => const UnionApprovalScreen(),
      },
      {
        'icon': Icons.work_outline,
        'label': 'Service Provider Approval',
        'color': Colors.purple[600],
        'screen': () => const ServiceProviderApprovalScreen(),
      },
      {
        'icon': Icons.verified_user_outlined,
        'label': 'Approved Union',
        'color': Colors.green[600],
        'screen': () => const ApprovedUnionScreen(),
      },
      {
        'icon': Icons.check_circle_outline,
        'label': 'Approved Service Provider',
        'color': Colors.teal[600],
        'screen': () => const ApprovedServiceProviderScreen(),
      },
      {
        'icon': Icons.question_answer_outlined,
        'label': 'Query Inbox',
        'color': Colors.orange[600],
        'screen': () => const AdminQueryInboxScreen(),
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isWebLayout ? 0 : 20,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(screenWidth),
          crossAxisSpacing: isWebLayout ? 20 : 15,
          mainAxisSpacing: isWebLayout ? 20 : 15,
          childAspectRatio: isWebLayout ? 1.0 : 0.85,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => service['screen']()),
              );
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
                      size: _getIconSize(screenWidth),
                      color: service['color'],
                    ),
                  ),
                  SizedBox(height: isWebLayout ? 16 : 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      service['label'],
                      style: TextStyle(
                        fontSize: _getFontSize(screenWidth),
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
