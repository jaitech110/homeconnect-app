import 'package:flutter/material.dart';
import 'union_screens/union_technical_issues_screen.dart';
import 'union_screens/resident_approval_request_screen.dart';
import 'union_screens/manage_residents_screen.dart';
import 'union_screens/manage_voting_screen.dart';
import 'union_screens/union_complaints_management_screen.dart';
import 'union_incharge_screens/maintenance_request_screen.dart';
import 'union_incharge_screens/send_notices_screen.dart';
import 'union_incharge_screens/my_details_screen.dart';
import '../services/resident_service.dart';
import '../services/complaints_service.dart';
import '../main.dart';

class UnionInchargeDashboard extends StatefulWidget {
  final Map<String, dynamic> user;

  const UnionInchargeDashboard({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<UnionInchargeDashboard> createState() => _UnionInchargeDashboardState();
}

class _UnionInchargeDashboardState extends State<UnionInchargeDashboard> {
  int totalResidents = 0;
  int pendingIssues = 0;
  bool isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      isLoadingStats = true;
    });

    try {
      final buildingName = widget.user['building_name'];
      final unionId = widget.user['id'];
      
      // Load both resident count and pending issues count concurrently
      final residentCountFuture = ResidentService.getApprovedResidentCount(buildingName);
      final pendingIssuesFuture = ComplaintsService.getPendingIssuesCount(unionId, buildingName);
      
      final results = await Future.wait([residentCountFuture, pendingIssuesFuture]);
      
      setState(() {
        totalResidents = results[0];
        pendingIssues = results[1];
        isLoadingStats = false;
      });
    } catch (e) {
      print('❌ Error loading stats: $e');
      setState(() {
        totalResidents = 0;
        pendingIssues = 0;
        isLoadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 600;
    final userName = widget.user['first_name'] ?? 'Union Incharge';
    final buildingName = widget.user['building_name'] ?? 'Building';
    
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
                      _buildWelcomeCard(context, userName, buildingName),
                      const SizedBox(height: 20),
                      // Stats cards
                      _buildStatsRow(),
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
            Color(0xFF2E7D32), // Dark Green
            Color(0xFF4CAF50), // Light Green
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
              // Right side icons
              Row(
                children: [
                  GestureDetector(
                    onTap: _loadStats,
                    child: Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: isWebLayout ? 28 : 24,
                    ),
                  ),
                  SizedBox(width: isWebLayout ? 20 : 15),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, String userName, String buildingName) {
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
                Icons.account_balance,
                color: Colors.green[600],
                size: isWebLayout ? 28 : 24,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            userName,
            style: TextStyle(
              fontSize: isWebLayout ? 36 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Managing $buildingName',
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
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWebLayout ? 0 : 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Residents',
              isLoadingStats ? '...' : totalResidents.toString(),
              Icons.people_outlined,
              Colors.blue[600]!,
            ),
          ),
          SizedBox(width: isWebLayout ? 20 : 15),
          Expanded(
            child: _buildStatCard(
              'Pending Issues',
              isLoadingStats ? '...' : pendingIssues.toString(),
              Icons.warning_outlined,
              Colors.orange[600]!,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 600;
    
    return Container(
      padding: EdgeInsets.all(isWebLayout ? 24 : 16),
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
            padding: EdgeInsets.all(isWebLayout ? 16 : 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon, 
              color: color, 
              size: isWebLayout ? 32 : 24,
            ),
          ),
          SizedBox(height: isWebLayout ? 16 : 12),
          Text(
            value,
            style: TextStyle(
              fontSize: isWebLayout ? 28 : 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: isWebLayout ? 6 : 4),
          Text(
            title,
            style: TextStyle(
              fontSize: isWebLayout ? 14 : 12,
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
    
    final List<Map<String, dynamic>> services = [
      {
        'icon': Icons.group_add_outlined,
        'label': 'Resident Approval',
        'color': Colors.blue[600],
        'screen': () => ResidentApprovalRequestScreen(
          unionId: widget.user['id'] ?? '',
          buildingName: widget.user['building_name'] ?? '',
        ),
      },
      {
        'icon': Icons.people_outlined,
        'label': 'Manage Residents',
        'color': Colors.green[600],
        'screen': () => ManageResidentsScreen(
          buildingName: widget.user['building_name'] ?? '',
          unionId: widget.user['id'] ?? '',
        ),
      },
      {
        'icon': Icons.how_to_vote_outlined,
        'label': 'Manage Voting',
        'color': Colors.purple[600],
        'screen': () => ManageVotingScreen(
          unionId: widget.user['id'] ?? '',
          buildingName: widget.user['building_name'] ?? '',
        ),
      },
      {
        'icon': Icons.report_problem_outlined,
        'label': 'Complaints',
        'color': Colors.red[600],
        'screen': () => UnionComplaintsManagementScreen(
          unionId: widget.user['id'] ?? '',
          buildingName: widget.user['building_name'] ?? '',
        ),
      },
      {
        'icon': Icons.build_outlined,
        'label': 'Maintenance',
        'color': Colors.orange[600],
        'screen': () => MaintenanceRequestScreen(
          unionId: widget.user['id'] ?? '',
          buildingName: widget.user['building_name'] ?? '',
        ),
      },
      {
        'icon': Icons.announcement_outlined,
        'label': 'Send Notices',
        'color': Colors.teal[600],
        'screen': () => SendNoticesScreen(
          unionId: widget.user['id'] ?? '',
          buildingName: widget.user['building_name'] ?? '',
        ),
      },
      {
        'icon': Icons.bug_report_outlined,
        'label': 'Technical Issues',
        'color': Colors.red[500],
        'screen': () => UnionTechnicalIssuesScreen(
          unionId: widget.user['id'] ?? '',
          unionName: '${widget.user['first_name'] ?? ''} ${widget.user['last_name'] ?? ''}'.trim(),
          buildingName: widget.user['building_name'] ?? '',
          category: widget.user['category'] ?? '',
        ),
      },
      {
        'icon': Icons.account_circle_outlined,
        'label': 'My Details',
        'color': Colors.indigo[600],
        'screen': () => MyDetailsScreen(
          unionId: widget.user['id'] ?? '',
          buildingName: widget.user['building_name'] ?? '',
          userData: widget.user,
        ),
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