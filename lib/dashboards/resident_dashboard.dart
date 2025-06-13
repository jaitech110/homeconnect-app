import 'package:flutter/material.dart';
import 'resident_screens/complaint_screen.dart';
import 'resident_screens/resident_elections_screen.dart';
import 'resident_screens/service_screen.dart';
import 'resident_screens/notices_screen.dart';
import 'resident_screens/resident_view_complaints_screen.dart';
import 'resident_screens/maintenance_screen.dart';
import 'resident_screens/union_incharge_details_screen.dart';
import '../main.dart'; // ✅ Import LoginPage

class ResidentDashboard extends StatelessWidget {
  final String userName;
  final String userId;
  final String? buildingName;
  final String? unionId;

  const ResidentDashboard({
    super.key, 
    required this.userName, 
    required this.userId,
    this.buildingName,
    this.unionId,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 800;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Custom header with gradient
          _buildGradientHeader(context),
          // Main content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Wallet-style card
                  _buildWelcomeCard(context),
                  SizedBox(height: isLargeScreen ? 30 : 20),
                  // Services grid
                  _buildServicesGrid(context),
                  SizedBox(height: isLargeScreen ? 40 : 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientHeader(BuildContext context) {
    return Container(
      height: 120,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF6B35), // Orange
            Color(0xFFF7931E), // Lighter orange
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
              // Logout icon only
              GestureDetector(
                onTap: () {
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
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth > 1200 ? 800.0 : screenWidth > 800 ? 600.0 : screenWidth;
    final horizontalPadding = screenWidth > 600 ? 40.0 : 20.0;
    
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10),
        padding: const EdgeInsets.all(20),
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
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  Icons.home,
                  color: Colors.green[600],
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              userName.isNotEmpty ? userName : 'Resident',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              buildingName ?? 'Society Name',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesGrid(BuildContext context) {
    final List<Map<String, dynamic>> services = [
      {
        'icon': Icons.how_to_vote_outlined,
        'label': 'Voting',
        'color': Colors.blue[600],
      },
      {
        'icon': Icons.report_problem_outlined,
        'label': 'Complaint',
        'color': Colors.red[600],
      },
      {
        'icon': Icons.design_services_outlined,
        'label': 'Services',
        'color': Colors.purple[600],
      },
      {
        'icon': Icons.build_outlined,
        'label': 'Maintenance',
        'color': Colors.orange[600],
      },
      {
        'icon': Icons.announcement_outlined,
        'label': 'Notices',
        'color': Colors.teal[600],
      },
      {
        'icon': Icons.supervisor_account_outlined,
        'label': 'Union Incharge Details',
        'color': Colors.indigo[600],
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine grid layout based on screen width
        final screenWidth = MediaQuery.of(context).size.width;
        int crossAxisCount;
        double maxWidth;
        double iconSize;
        double fontSize;
        double itemPadding;
        
        if (screenWidth > 1200) {
          // Large desktop screens
          crossAxisCount = 5;
          maxWidth = 800;
          iconSize = 28;
          fontSize = 12;
          itemPadding = 16;
        } else if (screenWidth > 800) {
          // Medium screens (tablets, small desktop)
          crossAxisCount = 4;
          maxWidth = 600;
          iconSize = 30;
          fontSize = 12;
          itemPadding = 14;
        } else if (screenWidth > 600) {
          // Small tablets
          crossAxisCount = 3;
          maxWidth = 500;
          iconSize = 32;
          fontSize = 13;
          itemPadding = 12;
        } else {
          // Mobile phones
          crossAxisCount = 3;
          maxWidth = screenWidth;
          iconSize = 32;
          fontSize = 13;
          itemPadding = 12;
        }

        return Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth > 600 ? 40 : 20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: screenWidth > 600 ? 20 : 15,
                  mainAxisSpacing: screenWidth > 600 ? 20 : 15,
                  childAspectRatio: 0.9,
                ),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  return GestureDetector(
                    onTap: () => _handleServiceTap(context, service['label']),
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
                            padding: EdgeInsets.all(itemPadding),
                            decoration: BoxDecoration(
                              color: service['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              service['icon'],
                              size: iconSize,
                              color: service['color'],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            service['label'],
                            style: TextStyle(
                              fontSize: fontSize,
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
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleServiceTap(BuildContext context, String label) {
    switch (label) {
      case 'Complaint':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResidentViewComplaintsScreen(userId: userId),
          ),
        );
        break;
      case 'Voting':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResidentElectionsScreen(residentId: userId),
          ),
        );
        break;
      case 'Services':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceScreen(userId: userId),
          ),
        );
        break;
      case 'Maintenance':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MaintenanceScreen(
              userId: userId,
              userName: userName,
              buildingName: buildingName,
              unionId: unionId,
            ),
          ),
        );
        break;
      case 'Notices':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NoticesScreen(
              userId: userId,
              buildingName: buildingName,
            ),
          ),
        );
        break;
      case 'Union Incharge Details':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UnionInchargeDetailsScreen(
              userId: userId,
              buildingName: buildingName,
              unionId: unionId,
            ),
          ),
        );
        break;
    }
  }
}
