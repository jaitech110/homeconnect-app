import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/api_utils.dart';
import '../../utils/app_theme.dart';

class MyRequestsScreen extends StatefulWidget {
  final String providerId;

  const MyRequestsScreen({Key? key, required this.providerId}) : super(key: key);

  @override
  _MyRequestsScreenState createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  List<dynamic> acceptedRequests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCompletedRequests();
  }

  Future<void> fetchCompletedRequests() async {
    setState(() {
      isLoading = true;
    });

    try {
      final baseUrl = getBaseUrl();
      final url = Uri.parse('$baseUrl/provider/service-requests/${widget.providerId}?status=completed');
      
              print('🔄 Fetching completed requests for provider: ${widget.providerId}');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          acceptedRequests = data is List ? data : [];
          isLoading = false;
        });
        print('✅ Fetched ${acceptedRequests.length} completed requests');
      } else {
        throw Exception('Failed to fetch completed requests: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching completed requests: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading requests: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> completeRequest(String requestId) async {
    try {
      final baseUrl = getBaseUrl();
      final url = Uri.parse('$baseUrl/provider/service-requests/$requestId/complete');
      
      print('✅ Marking service request as completed: $requestId');
      
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'provider_id': widget.providerId,
          'completion_notes': 'Job completed successfully',
        }),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final updatedStats = responseData['updated_provider_stats'];
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.done_all, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Job marked as completed!'),
                        if (updatedStats != null)
                          Text(
                            'Total completed: ${updatedStats['services_completed']}',
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        fetchCompletedRequests(); // Refresh the list
      } else {
        throw Exception('Failed to complete request: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error completing service request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing request: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
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
      appBar: AppBar(
        title: Text(
          'My Service Requests',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isWebLayout ? 22 : 20,
          ),
        ),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: EdgeInsets.all(isWebLayout ? 24 : 16),
            child: Column(
              children: [
                // Header Info Card
                Container(
                  padding: EdgeInsets.all(isWebLayout ? 24 : 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.purple[600]!,
                        Colors.purple[800]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isWebLayout ? 16 : 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.assignment,
                          color: Colors.white,
                          size: isWebLayout ? 32 : 28,
                        ),
                      ),
                      SizedBox(width: isWebLayout ? 20 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Completed Jobs',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isWebLayout ? 20 : 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: isWebLayout ? 8 : 4),
                            Text(
                              'View your completed service requests',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: isWebLayout ? 16 : 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: isWebLayout ? 24 : 20),
                
                // Requests List
                Expanded(
                  child: _buildRequestsList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestsList() {
    return isLoading
        ? AppTheme.loadingWidget(message: 'Loading your requests...')
        : acceptedRequests.isEmpty
            ? AppTheme.emptyStateWidget(
                icon: Icons.assignment_turned_in_outlined,
                title: 'No active requests',
                subtitle: 'When you accept service requests, they will appear here for you to manage and complete.',
                action: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  style: AppTheme.primaryButtonStyle,
                  icon: const Icon(Icons.search),
                  label: const Text('Find New Requests'),
                ),
              )
            : RefreshIndicator(
                onRefresh: fetchCompletedRequests,
                color: AppTheme.serviceProviderColor,
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: acceptedRequests.length,
                  itemBuilder: (context, index) {
                    final request = acceptedRequests[index];
                    return _buildRequestCard(request);
                  },
                ),
              );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 600;
    
    final status = request['status']?.toString() ?? 'completed';
    final residentName = request['resident_name']?.toString() ?? 'Unknown Resident';
    final serviceType = request['service_type']?.toString() ?? request['category']?.toString() ?? 'Service';
    final description = request['description']?.toString() ?? 'No description provided';
    final residentAddress = request['resident_address']?.toString() ?? 'No address provided';
    final requestDate = request['created_at']?.toString() ?? request['requested_at']?.toString() ?? '';
    
    // All requests in this screen are completed, so always show as "Job Completed"
    Color statusColor = Colors.green;
    IconData statusIcon = Icons.check_circle;
    String statusText = 'Job Completed';
    
    return Card(
      margin: EdgeInsets.only(bottom: isWebLayout ? 20 : 16),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey[50]!,
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isWebLayout ? 24 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isWebLayout ? 12 : 10),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.handyman,
                      color: Colors.purple[600],
                      size: isWebLayout ? 28 : 24,
                    ),
                  ),
                  SizedBox(width: isWebLayout ? 16 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          serviceType,
                          style: TextStyle(
                            fontSize: isWebLayout ? 20 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: isWebLayout ? 6 : 4),
                        Text(
                          'Client: $residentName',
                          style: TextStyle(
                            fontSize: isWebLayout ? 16 : 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWebLayout ? 12 : 10,
                      vertical: isWebLayout ? 8 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          color: statusColor,
                          size: isWebLayout ? 16 : 14,
                        ),
                        SizedBox(width: isWebLayout ? 6 : 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: isWebLayout ? 14 : 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: isWebLayout ? 20 : 16),
              
              // Description
              Container(
                padding: EdgeInsets.all(isWebLayout ? 16 : 14),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service Description',
                      style: TextStyle(
                        fontSize: isWebLayout ? 16 : 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: isWebLayout ? 8 : 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: isWebLayout ? 15 : 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: isWebLayout ? 16 : 12),
              
              // Details Row
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      Icons.location_on,
                      'Location',
                      residentAddress,
                      Colors.red[600]!,
                      isWebLayout,
                    ),
                  ),
                  SizedBox(width: isWebLayout ? 16 : 12),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.access_time,
                      'Completed',
                      _formatDate(requestDate),
                      Colors.green[600]!,
                      isWebLayout,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: isWebLayout ? 12 : 10),
              
              // Contact Information Row
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      Icons.email,
                      'Email',
                      request['resident_email']?.toString() ?? 'Email not provided',
                      Colors.blue[600]!,
                      isWebLayout,
                    ),
                  ),
                  SizedBox(width: isWebLayout ? 16 : 12),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.phone,
                      'Phone',
                      request['resident_phone']?.toString() ?? 'Phone not provided',
                      Colors.purple[600]!,
                      isWebLayout,
                    ),
                  ),
                ],
              ),
              
              // No action buttons needed - all requests are already completed
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, Color color, bool isWebLayout) {
    return Container(
      padding: EdgeInsets.all(isWebLayout ? 16 : 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: isWebLayout ? 24 : 20,
          ),
          SizedBox(height: isWebLayout ? 8 : 6),
          Text(
            label,
            style: TextStyle(
              fontSize: isWebLayout ? 14 : 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: isWebLayout ? 4 : 2),
          Text(
            value,
            style: TextStyle(
              fontSize: isWebLayout ? 13 : 12,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'No date provided';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateStr.split('T')[0];
    }
  }

  Future<void> _markAsCompleted(String requestId) async {
    try {
      await completeRequest(requestId);
    } catch (e) {
      print('❌ Error marking request as completed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing request: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 