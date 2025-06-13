import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart';

class SendNoticesScreen extends StatefulWidget {
  final String? unionId;
  final String? buildingName;
  
  const SendNoticesScreen({
    super.key,
    this.unionId,
    this.buildingName,
  });

  @override
  State<SendNoticesScreen> createState() => _SendNoticesScreenState();
}

class _SendNoticesScreenState extends State<SendNoticesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  
  String _priority = 'Normal';
  String _category = 'General';
  bool _isUrgent = false;
  bool _requiresAcknowledgment = false;
  bool _isLoading = false;
  
  final List<String> _priorities = ['Low', 'Normal', 'High', 'Critical'];
  final List<String> _categories = [
    'General',
    'Maintenance',
    'Payment',
    'Meeting',
    'Emergency',
    'Rules & Regulations',
    'Events',
    'Security'
  ];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _saveNoticeToBackend(Map<String, dynamic> notice) async {
    try {
      final baseUrl = getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/union/notices'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': notice['title'],
          'body': notice['body'],
          'priority': notice['priority'],
          'category': notice['category'],
          'unionId': notice['unionId'],
          'buildingName': notice['buildingName'],
        }),
      );

      if (response.statusCode == 201) {
        print('✅ Notice saved to backend successfully');
      } else {
        print('⚠️ Backend save failed with status: ${response.statusCode}');
        throw Exception('Backend save failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error saving notice to backend: $e');
      throw e;
    }
  }

  Future<void> _saveNoticeForResidents(Map<String, dynamic> notice) async {
    try {
      // Try to save to backend first (primary storage)
      try {
        await _saveNoticeToBackend(notice);
        print('✅ Notice saved to backend successfully');
      } catch (backendError) {
        print('⚠️ Backend save failed, continuing with local storage: $backendError');
        // Continue with local storage even if backend fails
      }
      
      // Always save to local storage (for offline access and as backup)
      final prefs = await SharedPreferences.getInstance();
      final String buildingKey = (widget.buildingName ?? 'unknown')
          .replaceAll(' ', '_')
          .toLowerCase();
      
      // Also save with original building name for resident compatibility
      final String originalBuildingKey = widget.buildingName ?? 'unknown';
      
      // Get existing notices for this building
      final existingNoticesData = prefs.getString('building_notices_$buildingKey') ?? '[]';
      final List<dynamic> existingNotices = jsonDecode(existingNoticesData);
      
      // Add new notice to the beginning of the list
      existingNotices.insert(0, notice);
      
      // Save back to storage (both formats for compatibility)
      await prefs.setString('building_notices_$buildingKey', jsonEncode(existingNotices));
      await prefs.setString('building_notices_$originalBuildingKey', jsonEncode(existingNotices));
      
      print('📢 Notice saved locally for building: $buildingKey and $originalBuildingKey');
      print('📊 Total notices for building: ${existingNotices.length}');
    } catch (e) {
      print('❌ Error saving notice for residents: $e');
      throw e;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendNotice() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final notice = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'title': _titleController.text.trim(),
        'body': _messageController.text.trim(), // Using 'body' to match resident screen format
        'message': _messageController.text.trim(), // Keep for compatibility
        'priority': _priority,
        'category': _category,
        'isUrgent': _isUrgent,
        'requiresAcknowledgment': _requiresAcknowledgment,
        'posted_at': DateTime.now().toIso8601String(),
        'sentDate': DateTime.now().toIso8601String(),
        'unionId': widget.unionId,
        'buildingName': widget.buildingName,
        'property_name': widget.buildingName, // Using property_name for resident screen compatibility
        'posted_by': 'Union Incharge',
        'sentBy': 'Union Incharge',
        'status': 'Sent',
        'readCount': 0,
        'acknowledgedCount': 0,
        'readBy': [], // Track which residents have read it
      };

      // Save notice for residents to see
      await _saveNoticeForResidents(notice);

      // Clear form
      _titleController.clear();
      _messageController.clear();
      setState(() {
        _priority = 'Normal';
        _category = 'General';
        _isUrgent = false;
        _requiresAcknowledgment = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Notice sent successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send notice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Critical':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Normal':
        return Colors.blue;
      case 'Low':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Maintenance':
        return Icons.build;
      case 'Payment':
        return Icons.payment;
      case 'Meeting':
        return Icons.event;
      case 'Emergency':
        return Icons.emergency;
      case 'Rules & Regulations':
        return Icons.gavel;
      case 'Events':
        return Icons.celebration;
      case 'Security':
        return Icons.security;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Notices'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isWebLayout ? _getMaxWidth(screenWidth) : double.infinity,
          ),
          child: _buildCreateNoticeTab(),
        ),
      ),
    );
  }

  double _getMaxWidth(double screenWidth) {
    if (screenWidth <= 800) return 500;
    if (screenWidth <= 1200) return 600;
    return 800;
  }

  Widget _buildCreateNoticeTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 600;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(isWebLayout ? 24 : 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(isWebLayout ? 20 : 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info, 
                      color: Colors.blue[700],
                      size: isWebLayout ? 28 : 24,
                    ),
                    SizedBox(width: isWebLayout ? 16 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sending notice to: ${widget.buildingName ?? "All Residents"}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                              fontSize: isWebLayout ? 16 : 14,
                            ),
                          ),
                          SizedBox(height: isWebLayout ? 6 : 4),
                          Text(
                            'All residents in your building will receive this notice',
                            style: TextStyle(
                              fontSize: isWebLayout ? 14 : 12,
                              color: Colors.blue[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: isWebLayout ? 28 : 20),
            
            // Title Field
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Notice Title *',
                labelStyle: TextStyle(
                  color: Colors.black87,
                  fontSize: isWebLayout ? 16 : 14,
                ),
                hintText: 'Enter a clear and concise title',
                hintStyle: TextStyle(
                  color: Colors.black54,
                  fontSize: isWebLayout ? 16 : 14,
                ),
                prefixIcon: Icon(
                  Icons.title, 
                  color: Colors.black87,
                  size: isWebLayout ? 28 : 24,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: EdgeInsets.symmetric(
                  vertical: isWebLayout ? 20 : 16,
                  horizontal: isWebLayout ? 16 : 12,
                ),
              ),
              style: TextStyle(
                color: Colors.black87,
                fontSize: isWebLayout ? 16 : 14,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                if (value.trim().length < 5) {
                  return 'Title must be at least 5 characters';
                }
                return null;
              },
              maxLength: 100,
            ),
            
            SizedBox(height: isWebLayout ? 20 : 16),
            
            // Category Field
            DropdownButtonFormField<String>(
              value: _category,
              dropdownColor: Colors.white,
              decoration: InputDecoration(
                labelText: 'Category',
                labelStyle: TextStyle(
                  color: Colors.black87,
                  fontSize: isWebLayout ? 16 : 14,
                ),
                prefixIcon: Icon(
                  _getCategoryIcon(_category), 
                  color: Colors.black87,
                  size: isWebLayout ? 28 : 24,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: EdgeInsets.symmetric(
                  vertical: isWebLayout ? 20 : 16,
                  horizontal: isWebLayout ? 16 : 12,
                ),
              ),
              style: TextStyle(
                color: Colors.black87,
                fontSize: isWebLayout ? 16 : 14,
              ),
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.black87,
                size: isWebLayout ? 28 : 24,
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(
                    category,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: isWebLayout ? 16 : 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _category = value!;
                });
              },
            ),
            
            SizedBox(height: isWebLayout ? 20 : 16),
            
            // Priority Field
            DropdownButtonFormField<String>(
              value: _priority,
              dropdownColor: Colors.white,
              decoration: InputDecoration(
                labelText: 'Priority',
                labelStyle: TextStyle(
                  color: Colors.black87,
                  fontSize: isWebLayout ? 16 : 14,
                ),
                prefixIcon: Icon(
                  Icons.flag,
                  color: _getPriorityColor(_priority),
                  size: isWebLayout ? 28 : 24,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: EdgeInsets.symmetric(
                  vertical: isWebLayout ? 20 : 16,
                  horizontal: isWebLayout ? 16 : 12,
                ),
              ),
              style: TextStyle(
                color: Colors.black87,
                fontSize: isWebLayout ? 16 : 14,
              ),
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.black87,
                size: isWebLayout ? 28 : 24,
              ),
              items: _priorities.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Text(
                    priority,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: isWebLayout ? 16 : 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _priority = value!;
                });
              },
            ),
            
            SizedBox(height: isWebLayout ? 20 : 16),
            
            // Message Field
            TextFormField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'Notice Message *',
                labelStyle: TextStyle(
                  color: Colors.black87,
                  fontSize: isWebLayout ? 16 : 14,
                ),
                hintText: 'Write your notice message here...',
                hintStyle: TextStyle(
                  color: Colors.black54,
                  fontSize: isWebLayout ? 16 : 14,
                ),
                prefixIcon: Icon(
                  Icons.message, 
                  color: Colors.black87,
                  size: isWebLayout ? 28 : 24,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                alignLabelWithHint: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: isWebLayout ? 20 : 16,
                  horizontal: isWebLayout ? 16 : 12,
                ),
              ),
              style: TextStyle(
                color: Colors.black87,
                fontSize: isWebLayout ? 16 : 14,
              ),
              maxLines: isWebLayout ? 8 : 6,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a message';
                }
                if (value.trim().length < 10) {
                  return 'Message must be at least 10 characters';
                }
                return null;
              },
              maxLength: 1000,
            ),
            
            SizedBox(height: isWebLayout ? 32 : 24),
            
            // Send Button
            SizedBox(
              width: double.infinity,
              height: isWebLayout ? 56 : 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendNotice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.send, 
                            size: isWebLayout ? 24 : 20,
                          ),
                          SizedBox(width: isWebLayout ? 12 : 8),
                          Text(
                            'Send Notice',
                            style: TextStyle(
                              fontSize: isWebLayout ? 18 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 