import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart';

class AdminSendNoticesScreen extends StatefulWidget {
  const AdminSendNoticesScreen({super.key});

  @override
  State<AdminSendNoticesScreen> createState() => _AdminSendNoticesScreenState();
}

class _AdminSendNoticesScreenState extends State<AdminSendNoticesScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String? selectedHousingType;
  String? selectedProperty;
  bool isLoading = false;
  bool _isLoading = false;
  String _selectedRecipient = 'all';
  List<Map<String, dynamic>> properties = [];
  List<Map<String, dynamic>> notices = [];

  @override
  void initState() {
    super.initState();
    fetchSentNotices();
  }

  Future<void> fetchProperties(String housingType) async {
    setState(() {
      isLoading = true;
      selectedProperty = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${getBaseUrl()}/admin/properties?type=$housingType'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          properties = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        setState(() {
          properties = [];
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load properties: ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() {
        properties = [];
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> fetchSentNotices() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('${getBaseUrl()}/admin/notices'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          notices = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        setState(() {
          notices = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        notices = [];
        isLoading = false;
      });
    }
  }

  Future<void> _sendNotice() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and message are required')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/admin/send_notice'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'message': message,
          'recipient_type': _selectedRecipient,
        }),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 201) {
        _titleController.clear();
        _messageController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notice sent successfully')),
        );

        // Refresh the sent notices list
        fetchSentNotices();
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Failed to send notice')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Notices'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isWebLayout ? _getMaxWidth(screenWidth) : double.infinity,
          ),
          child: Padding(
            padding: EdgeInsets.all(isWebLayout ? 24 : 16),
            child: Column(
              children: [
                // Notice type selection card
                Card(
                  color: const Color(0xFF1E1E1E),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: EdgeInsets.all(isWebLayout ? 24 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Recipients',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isWebLayout ? 20 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: isWebLayout ? 20 : 16),
                        _buildRecipientOption('All Users', 'Send to all registered users', Icons.group, 'all', isWebLayout),
                        _buildRecipientOption('Residents Only', 'Send to residents only', Icons.home, 'residents', isWebLayout),
                        _buildRecipientOption('Service Providers', 'Send to service providers only', Icons.work, 'service_providers', isWebLayout),
                        _buildRecipientOption('Union Incharge', 'Send to union incharge only', Icons.admin_panel_settings, 'union_incharge', isWebLayout),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isWebLayout ? 24 : 16),
                // Message composition card
                Expanded(
                  child: Card(
                    color: const Color(0xFF1E1E1E),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: EdgeInsets.all(isWebLayout ? 24 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Compose Notice',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isWebLayout ? 20 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: isWebLayout ? 20 : 16),
                          // Title field
                          TextField(
                            controller: _titleController,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isWebLayout ? 16 : 14,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Notice Title',
                              labelStyle: TextStyle(
                                color: Colors.white70,
                                fontSize: isWebLayout ? 16 : 14,
                              ),
                              filled: true,
                              fillColor: const Color(0xFF2A2A2A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          SizedBox(height: isWebLayout ? 20 : 16),
                          // Message field
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isWebLayout ? 16 : 14,
                              ),
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              decoration: InputDecoration(
                                labelText: 'Notice Message',
                                labelStyle: TextStyle(
                                  color: Colors.white70,
                                  fontSize: isWebLayout ? 16 : 14,
                                ),
                                alignLabelWithHint: true,
                                filled: true,
                                fillColor: const Color(0xFF2A2A2A),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isWebLayout ? 24 : 16),
                          // Send button
                          SizedBox(
                            width: double.infinity,
                            height: isWebLayout ? 56 : 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _sendNotice,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                      'Send Notice',
                                      style: TextStyle(
                                        fontSize: isWebLayout ? 18 : 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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

  Widget _buildRecipientOption(String title, String subtitle, IconData icon, String value, bool isWebLayout) {
    final isSelected = _selectedRecipient == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRecipient = value;
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: isWebLayout ? 12 : 8),
        padding: EdgeInsets.all(isWebLayout ? 16 : 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple.withOpacity(0.3) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.deepPurple : Colors.white70,
              size: isWebLayout ? 28 : 24,
            ),
            SizedBox(width: isWebLayout ? 16 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: isWebLayout ? 16 : 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: isWebLayout ? 14 : 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Colors.deepPurple,
                size: isWebLayout ? 24 : 20,
              ),
          ],
        ),
      ),
    );
  }
}
