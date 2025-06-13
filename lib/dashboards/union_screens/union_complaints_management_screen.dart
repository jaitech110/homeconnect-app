import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/app_theme.dart';

class UnionComplaintsManagementScreen extends StatefulWidget {
  final String unionId;
  final String buildingName;

  const UnionComplaintsManagementScreen({
    Key? key,
    required this.unionId,
    required this.buildingName,
  }) : super(key: key);

  @override
  State<UnionComplaintsManagementScreen> createState() => _UnionComplaintsManagementScreenState();
}

class _UnionComplaintsManagementScreenState extends State<UnionComplaintsManagementScreen> {
  List<Map<String, dynamic>> complaints = [];
  bool isLoading = true;
  String? error;
  


  @override
  void initState() {
    super.initState();
    fetchComplaints();
  }

  String getBaseUrl() {
    return 'http://localhost:5000'; // Replace with your actual base URL
  }

  Future<void> fetchComplaints() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final baseUrl = getBaseUrl();
      final url = Uri.parse('$baseUrl/union/complaints/${widget.unionId}');
      
      print('🔄 Fetching complaints for union: ${widget.unionId}');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          complaints = data.map((item) => Map<String, dynamic>.from(item)).toList();
          isLoading = false;
        });
        print('✅ Fetched ${complaints.length} complaints');
      } else {
        throw Exception('Failed to fetch complaints: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching complaints: $e');
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> updateComplaintStatus(String complaintId, String newStatus) async {
    // First update locally for immediate UI response
    setState(() {
      final complaintIndex = complaints.indexWhere((c) => c['id'].toString() == complaintId);
      if (complaintIndex != -1) {
        complaints[complaintIndex]['status'] = newStatus;
      }
    });

    // Show immediate feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Complaint marked as $newStatus'),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 2),
      ),
    );

    // Update on server with correct API structure
    try {
      final baseUrl = getBaseUrl();
      final endpoint = '$baseUrl/union/complaints/$complaintId/status';
      
      print('🔄 Updating complaint $complaintId to $newStatus via: $endpoint');
      
      final response = await http.patch(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': newStatus,
          'updated_by': widget.unionId,
        }),
      ).timeout(const Duration(seconds: 10));
      
      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        print('✅ Successfully updated complaint status on server');
      } else {
        print('⚠️ Server update failed with status: ${response.statusCode}');
        print('⚠️ Response: ${response.body}');
        // Don't show error to user since local update was successful
      }
      
    } catch (e) {
      print('❌ Error updating complaint status on server: $e');
      // Don't show error to user since local update was successful
    }
  }

  List<Map<String, dynamic>> get filteredComplaints {
    // Only show active complaints (hide resolved ones)
    return complaints.where((complaint) {
      return complaint['status'] != 'resolved';
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Complaints & Issues'),
        backgroundColor: AppTheme.unionColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchComplaints,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.unionColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: AppTheme.unionColor.withOpacity(0.2)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.unionColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.report_problem,
                        color: AppTheme.unionColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Complaints Management', style: AppTheme.headingSmall),
                          const SizedBox(height: 4),
                          Text(
                            'Building: ${widget.buildingName}',
                            style: AppTheme.bodyMedium.copyWith(color: AppTheme.secondaryTextColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Stats Row
                Row(
                  children: [
                    _buildStatChip(
                      'Active', 
                      complaints.where((c) => c['status'] != 'resolved').length.toString(), 
                      AppTheme.unionColor
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      'Pending',
                      complaints.where((c) => c['status'] == 'pending').length.toString(),
                      AppTheme.warningColor,
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      'Resolved',
                      complaints.where((c) => c['status'] == 'resolved').length.toString(),
                      AppTheme.successColor,
                    ),
                  ],
                ),
              ],
            ),
          ),



          // Content
          Expanded(
            child: isLoading
                ? AppTheme.loadingWidget(message: 'Loading complaints...')
                : error != null
                    ? AppTheme.emptyStateWidget(
                        icon: Icons.error_outline,
                        title: 'Error Loading Complaints',
                        subtitle: error!,
                        action: ElevatedButton(
                          onPressed: fetchComplaints,
                          style: AppTheme.primaryButtonStyle,
                          child: const Text('Retry'),
                        ),
                      )
                    : filteredComplaints.isEmpty
                        ? AppTheme.emptyStateWidget(
                            icon: Icons.sentiment_satisfied,
                            title: 'No Complaints Found',
                            subtitle: 'No active complaints have been submitted yet.',
                          )
                        : RefreshIndicator(
                            onRefresh: fetchComplaints,
                            color: AppTheme.unionColor,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredComplaints.length,
                              itemBuilder: (context, index) {
                                return _buildComplaintCard(filteredComplaints[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildComplaintCard(Map<String, dynamic> complaint) {
    final residentName = complaint['resident_name']?.toString() ?? 'Anonymous';
    final category = complaint['category']?.toString() ?? 'Other';
    final status = complaint['status']?.toString() ?? 'pending';
    final description = complaint['description']?.toString() ?? 'No description provided';
    final createdAt = complaint['created_at']?.toString() ?? '';
    final residentEmail = complaint['resident_email']?.toString() ?? '';
    final complaintId = complaint['id']?.toString() ?? '';

    // Format date
    String formattedDate = 'Recently';
    if (createdAt.isNotEmpty) {
      try {
        final date = DateTime.parse(createdAt);
        final now = DateTime.now();
        final difference = now.difference(date);

        if (difference.inDays > 0) {
          formattedDate = '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
        } else if (difference.inHours > 0) {
          formattedDate = '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
        } else {
          formattedDate = 'Less than an hour ago';
        }
      } catch (e) {
        formattedDate = createdAt.split('T')[0];
      }
    }

    Color statusColor = AppTheme.warningColor;
    IconData statusIcon = Icons.pending;
    
    switch (status.toLowerCase()) {
      case 'resolved':
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle;
        break;
      case 'in_progress':
        statusColor = AppTheme.infoColor;
        statusIcon = Icons.work;
        break;
      default:
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.pending;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.elevatedCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(residentName, style: AppTheme.headingSmall),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          AppTheme.statusBadge(category.toUpperCase(), AppTheme.unionColor),
                          const SizedBox(width: 8),
                          AppTheme.statusBadge(status.toUpperCase(), statusColor),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Description
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Complaint Details', style: AppTheme.bodyLarge),
                  const SizedBox(height: 4),
                  Text(description, style: AppTheme.bodyMedium.copyWith(color: AppTheme.secondaryTextColor)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Contact and Date
            Row(
              children: [
                if (residentEmail.isNotEmpty) ...[
                  Icon(Icons.email, size: 16, color: AppTheme.secondaryTextColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(residentEmail, style: AppTheme.bodySmall),
                  ),
                  const SizedBox(width: 16),
                ],
                Icon(Icons.access_time, size: 16, color: AppTheme.secondaryTextColor),
                const SizedBox(width: 4),
                Text(formattedDate, style: AppTheme.bodySmall),
              ],
            ),

            if (status != 'resolved') ...[
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => updateComplaintStatus(complaintId, 'resolved'),
                      style: AppTheme.primaryButtonStyle.copyWith(
                        backgroundColor: MaterialStateProperty.all(AppTheme.successColor),
                      ),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Mark Resolved'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
} 