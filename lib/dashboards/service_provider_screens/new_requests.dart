import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../main.dart';

class NewRequestsScreen extends StatefulWidget {
  final String providerId;
  const NewRequestsScreen({super.key, required this.providerId});

  @override
  State<NewRequestsScreen> createState() => _NewRequestsScreenState();
}

class _NewRequestsScreenState extends State<NewRequestsScreen> with WidgetsBindingObserver {
  List<dynamic> requests = [];
  bool isLoading = true;
  bool isAutoRefreshEnabled = true;
  Timer? _refreshTimer;
  DateTime? _lastRefresh;
  int _requestCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchRequests();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground, refresh immediately
      fetchRequests();
    }
  }

  void _startAutoRefresh() {
    if (isAutoRefreshEnabled) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        if (mounted) {
          _silentRefresh();
        }
      });
    }
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    setState(() {
      isAutoRefreshEnabled = false;
    });
  }

  void _resumeAutoRefresh() {
    setState(() {
      isAutoRefreshEnabled = true;
    });
    _startAutoRefresh();
  }

  Future<void> fetchRequests() async {
    try {
      setState(() => isLoading = true);
      
      final baseUrl = getBaseUrl();
      final url = Uri.parse('$baseUrl/provider/service-requests/${widget.providerId}');
      
      print('🔗 Fetching service requests for provider: ${widget.providerId}');
      print('🔗 URL: $url');
      
      final response = await http.get(url);
      
      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        // Check if there are new requests
        final previousCount = _requestCount;
        final newCount = data.length;
        
        setState(() {
          requests = data;
          isLoading = false;
          _lastRefresh = DateTime.now();
          _requestCount = newCount;
        });
        
        // Show notification if new requests arrived
        if (newCount > previousCount && previousCount > 0) {
          final newRequestsCount = newCount - previousCount;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.notification_important, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('$newRequestsCount new service request${newRequestsCount == 1 ? '' : 's'} received!'),
                  ],
                ),
                backgroundColor: Colors.deepPurple,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'View',
                  textColor: Colors.white,
                  onPressed: () {
                    // Scroll to top to show new requests
                    if (mounted) {
                      Scrollable.ensureVisible(context);
                    }
                  },
                ),
              ),
            );
          }
        }
        
        print('✅ Fetched ${requests.length} service requests');
      } else {
        throw Exception('Failed to load requests: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching service requests: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading requests: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _silentRefresh() async {
    try {
      final baseUrl = getBaseUrl();
      final url = Uri.parse('$baseUrl/provider/service-requests/${widget.providerId}');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        // Check if there are new requests
        final previousCount = _requestCount;
        final newCount = data.length;
        
        setState(() {
          requests = data;
          _lastRefresh = DateTime.now();
          _requestCount = newCount;
        });
        
        // Show notification if new requests arrived
        if (newCount > previousCount && previousCount > 0) {
          final newRequestsCount = newCount - previousCount;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.notification_important, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('$newRequestsCount new service request${newRequestsCount == 1 ? '' : 's'} received!'),
                  ],
                ),
                backgroundColor: Colors.deepPurple,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'View',
                  textColor: Colors.white,
                  onPressed: () {
                    // Scroll to top to show new requests
                    if (mounted) {
                      Scrollable.ensureVisible(context);
                    }
                  },
                ),
              ),
            );
          }
        }
        
        print('🔄 Silent refresh completed: ${requests.length} requests');
      }
    } catch (e) {
      print('⚠️ Silent refresh failed: $e');
      // Don't show error for silent refresh failures
    }
  }

  Future<void> acceptRequest(String requestId) async {
    try {
      final baseUrl = getBaseUrl();
      final url = Uri.parse('$baseUrl/provider/service-requests/$requestId/accept');
      
      print('✅ Accepting service request: $requestId');
      
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'provider_id': widget.providerId,
          'notes': 'Request accepted by service provider',
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
                        const Text('Request accepted & completed!'),
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
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        fetchRequests(); // Refresh the list to remove accepted request
      } else {
        throw Exception('Failed to accept request: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error accepting service request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting request: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> rejectRequest(String requestId) async {
    try {
      final baseUrl = getBaseUrl();
      final url = Uri.parse('$baseUrl/provider/service-requests/$requestId/reject');
      
      print('❌ Rejecting service request: $requestId');
      
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'provider_id': widget.providerId,
          'reason': 'Request rejected by service provider',
        }),
      );
      
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.cancel, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Request rejected successfully.'),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        fetchRequests(); // Refresh the list to remove rejected request
      } else {
        throw Exception('Failed to reject request: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error rejecting service request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting request: ${e.toString()}'),
            backgroundColor: Colors.red,
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
          'New Service Requests',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isWebLayout ? 22 : 20,
          ),
        ),
        backgroundColor: Colors.blue[600],
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
                        Colors.blue[600]!,
                        Colors.blue[800]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
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
                          Icons.new_releases,
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
                              'New Requests Available',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isWebLayout ? 20 : 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: isWebLayout ? 8 : 4),
                            Text(
                              'Accept requests that match your expertise',
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
      ? const Center(child: CircularProgressIndicator())
      : requests.isEmpty
      ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No service requests yet',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'When residents request your services,\nthey will appear here automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_mode, size: 16, color: Colors.deepPurple),
                  SizedBox(width: 4),
                  Text(
                    'Auto-refresh every 10 seconds',
                    style: TextStyle(color: Colors.deepPurple, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        )
      : RefreshIndicator(
          onRefresh: fetchRequests,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _buildRequestCard(request);
            },
          ),
        );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 600;
    
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
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.build,
                      color: Colors.blue[600],
                      size: isWebLayout ? 28 : 24,
                    ),
                  ),
                  SizedBox(width: isWebLayout ? 16 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request['service_type'] ?? 'Service Request',
                          style: TextStyle(
                            fontSize: isWebLayout ? 20 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: isWebLayout ? 6 : 4),
                        Text(
                          'Requested by: ${request['resident_name'] ?? 'Resident'}',
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
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Pending',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: isWebLayout ? 14 : 12,
                        fontWeight: FontWeight.bold,
                      ),
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
                      'Description',
                      style: TextStyle(
                        fontSize: isWebLayout ? 16 : 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: isWebLayout ? 8 : 6),
                    Text(
                      request['description'] ?? 'No description provided',
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
                      request['resident_address']?.toString() ?? 'Address not provided',
                      Colors.red[600]!,
                      isWebLayout,
                    ),
                  ),
                  SizedBox(width: isWebLayout ? 16 : 12),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.access_time,
                      'Requested',
                      _formatDate(request['created_at']?.toString() ?? ''),
                      Colors.purple[600]!,
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
                      Colors.green[600]!,
                      isWebLayout,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: isWebLayout ? 24 : 20),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptRequest(request['id']),
                      icon: Icon(
                        Icons.check_circle,
                        size: isWebLayout ? 20 : 18,
                      ),
                      label: Text(
                        'Accept Request',
                        style: TextStyle(
                          fontSize: isWebLayout ? 16 : 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isWebLayout ? 16 : 14,
                          horizontal: isWebLayout ? 24 : 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                  SizedBox(width: isWebLayout ? 16 : 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectRequest(request['id']),
                      icon: Icon(
                        Icons.cancel,
                        size: isWebLayout ? 20 : 18,
                        color: Colors.red[600],
                      ),
                      label: Text(
                        'Reject Request',
                        style: TextStyle(
                          fontSize: isWebLayout ? 16 : 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[600],
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: isWebLayout ? 16 : 14,
                          horizontal: isWebLayout ? 24 : 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.red[600]!),
                      ),
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

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'No date provided';
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
      // Safe fallback for invalid date strings
      return dateStr.contains('T') ? dateStr.split('T')[0] : dateStr;
    }
  }

  Future<void> _acceptRequest(String requestId) async {
    try {
      await acceptRequest(requestId);
    } catch (e) {
      print('❌ Error accepting request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting request: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reject Service Request'),
          content: const Text(
            'Are you sure you want to reject this service request? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await rejectRequest(requestId);
      } catch (e) {
        print('❌ Error rejecting request: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error rejecting request: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
