import 'package:flutter/material.dart';
import '../main.dart';
import 'union_screens/manage_residents_screen.dart';
import 'union_screens/service_requests_screen.dart';
import 'union_screens/create_notices_screen.dart';
import 'union_screens/handle_complaints_screen.dart';
import 'union_screens/voting_control_screen.dart';
import 'union_screens/approve_residents_screen.dart';
import 'union_screens/resident_detail_screen.dart';
import 'union_screens/bank_account_details_screen.dart';
import 'union_screens/maintenance_approval_screen.dart';

class UnionDashboard extends StatelessWidget {
  final int userId;
  final String? buildingName;
  
  const UnionDashboard({
    super.key, 
    required this.userId,
    this.buildingName,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> features = [
      {'icon': Icons.people, 'label': 'Manage Residents'},
      {'icon': Icons.verified_user, 'label': 'Approve Residents'},
      {'icon': Icons.assignment, 'label': 'Service Requests'},
      {'icon': Icons.announcement, 'label': 'Create Notices'},
      {'icon': Icons.account_balance, 'label': 'Bank Account Details'},
      {'icon': Icons.payment, 'label': 'Maintenance Approval'},
      {'icon': Icons.report_problem, 'label': 'Handle Complaints'},
      {'icon': Icons.how_to_vote, 'label': 'Voting Control'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Union Incharge Dashboard'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginPage()),
              );
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: features.map((item) {
                return GestureDetector(
                  onTap: () {
                    if (item['label'] == 'Manage Residents') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ManageResidentsScreen(
                            unionId: userId.toString(),
                            buildingName: buildingName ?? 'Unknown Building',
                          ),
                        ),
                      );
                    } else if (item['label'] == 'Approve Residents') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ApproveResidentsScreen(),
                        ),
                      );
                    } else if (item['label'] == 'Service Requests') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ServiceRequestsScreen(),
                        ),
                      );
                    } else if (item['label'] == 'Create Notices') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateNoticesScreen(userId: userId),
                        ),
                      );
                    } else if (item['label'] == 'Bank Account Details') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BankAccountDetailsScreen(userId: userId),
                        ),
                      );
                    } else if (item['label'] == 'Handle Complaints') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HandleComplaintsScreen(),
                        ),
                      );
                    } else if (item['label'] == 'Voting Control') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VotingControlScreen(
                            unionInchargeId: userId.toString(),
                          ),
                        ),
                      );
                    } else if (item['label'] == 'Maintenance Approval') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MaintenanceApprovalScreen(userId: userId),
                        ),
                      );
                    }
                  },
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item['icon'], size: 40, color: Colors.deepPurple),
                        const SizedBox(height: 8),
                        Text(
                          item['label'],
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.deepPurple, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Colors.deepPurple),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Welcome, Union Incharge!',
                    style: TextStyle(color: Colors.white, fontSize: 18)),
                SizedBox(height: 4),
                Text('Overview of society activity',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
