import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart';

class ReceiveNoticesScreen extends StatefulWidget {
  const ReceiveNoticesScreen({Key? key}) : super(key: key);

  @override
  State<ReceiveNoticesScreen> createState() => _ReceiveNoticesScreenState();
}

class _ReceiveNoticesScreenState extends State<ReceiveNoticesScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> notices = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchNotices();
  }

  Future<void> fetchNotices() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${getBaseUrl()}/union/notices'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          notices = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load notices: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notices from Admin'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchNotices,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: fetchNotices,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : notices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('No notices received yet'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: fetchNotices,
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: notices.length,
                      itemBuilder: (context, index) {
                        final notice = notices[index];
                        
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () => _showNoticeDetails(notice),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notice['title'] ?? 'No Title',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.deepPurple.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'From Admin',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.deepPurple.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    notice['message'] ?? 'No message',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (notice['is_read'] == true)
                                        const Text(
                                          'Read',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 12,
                                          ),
                                        )
                                      else
                                        const Text(
                                          'New',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      Text(
                                        notice['created_at'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  void _showNoticeDetails(Map<String, dynamic> notice) {
    // Mark notice as read
    if (notice['is_read'] != true) {
      _markAsRead(notice['id']);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notice['title'] ?? 'No Title'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(notice['message'] ?? 'No message'),
              const SizedBox(height: 16),
              Text(
                'Sent: ${notice['created_at'] ?? 'Unknown date'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsRead(int noticeId) async {
    try {
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/union/notices/$noticeId/read'),
      );

      if (response.statusCode == 200) {
        // Update local state
        setState(() {
          for (var notice in notices) {
            if (notice['id'] == noticeId) {
              notice['is_read'] = true;
              break;
            }
          }
        });
      }
    } catch (e) {
      // Silent error, not critical functionality
      print('Error marking notice as read: $e');
    }
  }
} 