import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart';

class AdminQueryInboxScreen extends StatefulWidget {
  const AdminQueryInboxScreen({super.key});

  @override
  State<AdminQueryInboxScreen> createState() => _AdminQueryInboxScreenState();
}

class _AdminQueryInboxScreenState extends State<AdminQueryInboxScreen> {
  List<Map<String, dynamic>> queries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQueries();
  }

  Future<void> _loadQueries() async {
    setState(() => _isLoading = true);
    
    try {
      // Load technical issues from backend
      final baseUrl = getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/technical-issues'),
        headers: {'Content-Type': 'application/json'},
      );

      List<Map<String, dynamic>> technicalIssues = [];
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final issues = List<Map<String, dynamic>>.from(data['issues'] ?? []);
        
        // Convert technical issues to query format
        technicalIssues = issues.map((issue) {
          return {
            'id': issue['id'],
            'from': '${issue['provider_name'] ?? 'Unknown Provider'}',
            'message': '${issue['title']}: ${issue['description']}',
            'timestamp': _formatTimestamp(issue['timestamp'] ?? issue['created_at']),
            'resolved': issue['status'] == 'resolved',
            'type': 'technical_issue',
            'status': issue['status'] ?? 'pending',
            'title': issue['title'] ?? 'Technical Issue',
            'description': issue['description'] ?? '',
            'business_category': issue['business_category'] ?? issue['category'] ?? 'Unknown',
          };
        }).where((issue) => issue['status'] != 'completed').toList();
      }

      // Sort by timestamp (newest first)
      technicalIssues.sort((a, b) {
        try {
          final aTime = DateTime.parse(a['timestamp'].toString().replaceAll(' ', 'T'));
          final bTime = DateTime.parse(b['timestamp'].toString().replaceAll(' ', 'T'));
          return bTime.compareTo(aTime);
        } catch (e) {
          return 0;
        }
      });

      setState(() {
        queries = technicalIssues;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading technical issues: $e');
      // Show empty list if API fails
      setState(() {
        queries = [];
        _isLoading = false;
      });
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final date = DateTime.parse(timestamp);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  void _markResolved(int index) async {
    final query = queries[index];
    
    if (query['type'] == 'technical_issue') {
      // Update technical issue status via API
      try {
        final baseUrl = getBaseUrl();
        final response = await http.put(
          Uri.parse('$baseUrl/admin/technical-issues/${query['id']}/status'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'status': 'resolved'}),
        );

        if (response.statusCode == 200) {
          setState(() {
            queries[index]['resolved'] = true;
            queries[index]['status'] = 'resolved';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Technical issue marked as resolved')),
          );
        } else {
          throw Exception('Failed to update status');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Technical Issues Inbox'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQueries,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isWebLayout ? _getMaxWidth(screenWidth) : double.infinity,
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : queries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox,
                            size: isWebLayout ? 80 : 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: isWebLayout ? 20 : 16),
                          Text(
                            'No technical issues found',
                            style: TextStyle(
                              fontSize: isWebLayout ? 20 : 18, 
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: isWebLayout ? 12 : 8),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isWebLayout ? 60 : 40,
                            ),
                            child: Text(
                              'Issues submitted by service providers and union incharge will appear here',
                              style: TextStyle(
                                fontSize: isWebLayout ? 16 : 14, 
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadQueries,
                      child: ListView.builder(
                        padding: EdgeInsets.all(isWebLayout ? 24 : 16),
                        itemCount: queries.length,
                        itemBuilder: (context, index) {
                          final query = queries[index];
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: isWebLayout ? 10 : 8),
                            elevation: 3,
                            child: ListTile(
                              contentPadding: EdgeInsets.all(isWebLayout ? 20 : 16),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(query['business_category']).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getCategoryIcon(query['business_category']),
                                  color: _getCategoryColor(query['business_category']),
                                  size: isWebLayout ? 28 : 24,
                                ),
                              ),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    query['business_category'] ?? 'Unknown Category',
                                    style: TextStyle(
                                      fontSize: isWebLayout ? 12 : 10,
                                      color: _getCategoryColor(query['business_category']),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    query['from'], 
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isWebLayout ? 18 : 16,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: isWebLayout ? 6 : 4),
                                  Text(
                                    query['title'] ?? 'Technical Issue',
                                    style: TextStyle(
                                      fontSize: isWebLayout ? 16 : 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    query['description'] ?? 'No description',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: isWebLayout ? 14 : 12),
                                  ),
                                  SizedBox(height: isWebLayout ? 8 : 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Received: ${query['timestamp']}', 
                                          style: TextStyle(fontSize: isWebLayout ? 12 : 11, color: Colors.grey[600]),
                                        ),
                                      ),
                                      SizedBox(width: isWebLayout ? 12 : 8),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isWebLayout ? 8 : 6, 
                                          vertical: isWebLayout ? 4 : 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(query['status']),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          query['status']?.toString().toUpperCase() ?? 'PENDING',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isWebLayout ? 12 : 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: query['resolved']
                                  ? Icon(
                                      Icons.check_circle, 
                                      color: Colors.green,
                                      size: isWebLayout ? 32 : 28,
                                    )
                                  : IconButton(
                                icon: Icon(
                                  Icons.done, 
                                  color: Colors.orange,
                                  size: isWebLayout ? 28 : 24,
                                ),
                                onPressed: () => _markResolved(index),
                              ),
                              isThreeLine: true,
                              onTap: () => _showTechnicalIssueDetails(query),
                            ),
                          );
                        },
                      ),
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

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'pending':
      default:
        return Colors.grey;
    }
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'Home & Utility Services':
        return Colors.red[600]!;
      case 'Food & Catering':
        return Colors.green[600]!;
      case 'Transport & Mobility':
        return Colors.blue[600]!;
      case 'Union Incharge':
        return Colors.purple[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'Home & Utility Services':
        return Icons.home_repair_service;
      case 'Food & Catering':
        return Icons.restaurant;
      case 'Transport & Mobility':
        return Icons.directions_car;
      case 'Union Incharge':
        return Icons.admin_panel_settings;
      default:
        return Icons.bug_report;
    }
  }

  void _showTechnicalIssueDetails(Map<String, dynamic> issue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getCategoryColor(issue['business_category']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getCategoryIcon(issue['business_category']),
                color: _getCategoryColor(issue['business_category']),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    issue['business_category'] ?? 'Unknown Category',
                    style: TextStyle(
                      fontSize: 12,
                      color: _getCategoryColor(issue['business_category']),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    issue['title'] ?? 'Technical Issue',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'From: ${issue['from']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Category: ${issue['business_category'] ?? 'Unknown'}',
                style: TextStyle(
                  color: _getCategoryColor(issue['business_category']),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Status: ${issue['status']?.toString().toUpperCase() ?? 'PENDING'}',
                style: TextStyle(
                  color: _getStatusColor(issue['status']),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Received: ${issue['timestamp']}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(issue['description'] ?? 'No description provided'),
            ],
          ),
        ),
        actions: [
          if (!issue['resolved']) ...[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                final index = queries.indexOf(issue);
                if (index != -1) {
                  _markResolved(index);
                }
              },
              child: const Text('Mark as Resolved'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
