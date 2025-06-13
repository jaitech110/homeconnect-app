import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart';

class UnionTechnicalIssuesScreen extends StatefulWidget {
  final String unionId;
  final String unionName;
  final String buildingName;
  final String category;

  const UnionTechnicalIssuesScreen({
    Key? key,
    required this.unionId,
    required this.unionName,
    required this.buildingName,
    required this.category,
  }) : super(key: key);

  @override
  State<UnionTechnicalIssuesScreen> createState() => _UnionTechnicalIssuesScreenState();
}

class _UnionTechnicalIssuesScreenState extends State<UnionTechnicalIssuesScreen> {
  final TextEditingController _issueController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _previousIssues = [];
  bool _isLoadingIssues = true;

  @override
  void initState() {
    super.initState();
    _loadPreviousIssues();
  }

  @override
  void dispose() {
    _issueController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadPreviousIssues() async {
    try {
      final baseUrl = getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/provider/technical-issues/${widget.unionId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _previousIssues = List<Map<String, dynamic>>.from(data['issues'] ?? [])
              .where((issue) => issue['status'] != 'completed') // Filter out completed issues
              .toList();
          _isLoadingIssues = false;
        });
      } else {
        setState(() {
          _previousIssues = [];
          _isLoadingIssues = false;
        });
      }
    } catch (e) {
      setState(() {
        _previousIssues = [];
        _isLoadingIssues = false;
      });
      print('Note: Technical issues endpoint not implemented yet');
    }
  }

  Future<void> _submitIssue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final baseUrl = getBaseUrl();
      final issueData = {
        'provider_id': widget.unionId,
        'provider_name': '${widget.buildingName} (${widget.category})',
        'building_name': widget.buildingName,
        'category': widget.category,
        'title': _titleController.text.trim(),
        'description': _issueController.text.trim(),
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'pending',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/provider/technical-issues'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(issueData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Technical issue reported successfully! Admin will be notified about ${widget.buildingName} issue.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Clear the form
        _titleController.clear();
        _issueController.clear();
        
        // Reload previous issues
        _loadPreviousIssues();
      } else {
        throw Exception('Failed to submit issue');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting issue: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 600;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Technical Issues - ${widget.buildingName}',
          style: TextStyle(
            fontSize: isWebLayout ? 20 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red[500],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isWebLayout ? 800 : double.infinity,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isWebLayout ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Card(
                  color: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                                child: Padding(
                    padding: EdgeInsets.all(isWebLayout ? 24 : 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.bug_report,
                            color: Colors.red[500],
                            size: isWebLayout ? 28 : 24,
                          ),
                        ),
                        SizedBox(width: isWebLayout ? 20 : 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Report Technical Issues',
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: isWebLayout ? 20 : 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: isWebLayout ? 8 : 6),
                              Text(
                                'Experiencing problems with app operations for ${widget.buildingName}? Let admin know!',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: isWebLayout ? 16 : 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
            ),
            
                            SizedBox(height: isWebLayout ? 24 : 20),
                
                // Issue Submission Form
                Card(
                  color: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
              child: Padding(
                padding: EdgeInsets.all(isWebLayout ? 24 : 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Submit New Issue',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: isWebLayout ? 18 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: isWebLayout ? 20 : 16),
                      
                      // Title Field
                      TextFormField(
                        controller: _titleController,
                        style: TextStyle(color: Colors.grey[800]),
                        decoration: InputDecoration(
                          labelText: 'Issue Title',
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          hintText: 'Brief description of the problem',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red[500]!, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          prefixIcon: Icon(Icons.title, color: Colors.grey[600]),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an issue title';
                          }
                          if (value.trim().length < 5) {
                            return 'Title must be at least 5 characters';
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: isWebLayout ? 20 : 16),
                      
                      // Description Field
                      TextFormField(
                        controller: _issueController,
                        style: TextStyle(color: Colors.grey[800]),
                        maxLines: isWebLayout ? 8 : 6,
                        decoration: InputDecoration(
                          labelText: 'Issue Description',
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          hintText: 'Please describe the technical issue in detail...\n\nInclude:\n• What you were trying to do\n• What happened instead\n• Any error messages\n• Steps to reproduce',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red[500]!, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please describe the technical issue';
                          }
                          if (value.trim().length < 10) {
                            return 'Description must be at least 10 characters';
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: isWebLayout ? 24 : 20),
                      
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitIssue,
                          icon: _isSubmitting
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.send),
                          label: Text(
                            _isSubmitting ? 'Submitting...' : 'Submit Issue',
                            style: TextStyle(fontSize: isWebLayout ? 16 : 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[500],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: isWebLayout ? 16 : 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            SizedBox(height: isWebLayout ? 24 : 20),
            
            // Previous Issues Section
            Card(
              color: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: EdgeInsets.all(isWebLayout ? 24 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.history,
                            color: Colors.blue[600],
                            size: isWebLayout ? 20 : 18,
                          ),
                        ),
                        SizedBox(width: isWebLayout ? 12 : 10),
                        Text(
                          'Previous Issues',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: isWebLayout ? 18 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    _isLoadingIssues
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : _previousIssues.isEmpty
                            ? Padding(
                                padding: EdgeInsets.all(isWebLayout ? 32 : 24),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.inbox,
                                        color: Colors.grey[400],
                                        size: isWebLayout ? 56 : 48,
                                      ),
                                      SizedBox(height: isWebLayout ? 12 : 8),
                                      Text(
                                        'No previous issues reported',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: isWebLayout ? 16 : 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Column(
                                children: _previousIssues.map((issue) => _buildIssueCard(issue)).toList(),
                              ),
                  ],
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

  Widget _buildIssueCard(Map<String, dynamic> issue) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = screenWidth > 600;
    
    return GestureDetector(
      onTap: () {
        if (issue['status'] == 'resolved') {
          _showResolutionAcknowledgment(issue);
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: isWebLayout ? 12 : 8),
        padding: EdgeInsets.all(isWebLayout ? 16 : 12),
        decoration: BoxDecoration(
          color: issue['status'] == 'resolved' 
              ? Colors.green[50]
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: issue['status'] == 'resolved' 
                ? Colors.green[200]!
                : Colors.grey[200]!,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    issue['title'] ?? 'Technical Issue',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: isWebLayout ? 16 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWebLayout ? 12 : 8, 
                    vertical: isWebLayout ? 6 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(issue['status']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    issue['status']?.toString().toUpperCase() ?? 'PENDING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isWebLayout ? 11 : 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isWebLayout ? 8 : 6),
            Text(
              issue['description'] ?? '',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: isWebLayout ? 14 : 12,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isWebLayout ? 8 : 6),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: Colors.grey[400],
                  size: isWebLayout ? 14 : 12,
                ),
                SizedBox(width: 4),
                Text(
                  'Submitted: ${_formatDate(issue['timestamp'])}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: isWebLayout ? 12 : 11,
                  ),
                ),
                if (issue['status'] == 'resolved') ...[
                  const Spacer(),
                  Icon(
                    Icons.touch_app,
                    color: Colors.green[600],
                    size: isWebLayout ? 16 : 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Tap to acknowledge',
                    style: TextStyle(
                      color: Colors.green[600],
                      fontSize: isWebLayout ? 12 : 10,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
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

  String _formatDate(String? timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final date = DateTime.parse(timestamp);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _showResolutionAcknowledgment(Map<String, dynamic> issue) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            const Text(
              'Issue Resolved',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your complaint is resolved!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Issue: ${issue['title'] ?? 'Technical Issue'}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This issue will be removed from your list after you acknowledge it.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Okay'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _acknowledgeTechnicalIssue(issue['id']);
    }
  }

  Future<void> _acknowledgeTechnicalIssue(String issueId) async {
    try {
      final baseUrl = getBaseUrl();
      final response = await http.put(
        Uri.parse('$baseUrl/provider/technical-issues/$issueId/acknowledge'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you! Issue has been acknowledged and removed.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload the issues list to remove the acknowledged issue
        _loadPreviousIssues();
      } else {
        throw Exception('Failed to acknowledge issue');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error acknowledging issue: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 