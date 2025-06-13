import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart';

class TechnicalIssuesScreen extends StatefulWidget {
  final String providerId;
  final String providerName;
  final String? businessCategory;

  const TechnicalIssuesScreen({
    Key? key,
    required this.providerId,
    required this.providerName,
    this.businessCategory,
  }) : super(key: key);

  @override
  State<TechnicalIssuesScreen> createState() => _TechnicalIssuesScreenState();
}

class _TechnicalIssuesScreenState extends State<TechnicalIssuesScreen> {
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
        Uri.parse('$baseUrl/provider/technical-issues/${widget.providerId}'),
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
        // If endpoint doesn't exist yet, just show empty list
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
        'provider_id': widget.providerId,
        'provider_name': widget.businessCategory?.isNotEmpty == true 
            ? widget.businessCategory! 
            : widget.providerName,
        'business_category': widget.businessCategory,
        'category': widget.businessCategory,
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
            content: Text(widget.businessCategory?.isNotEmpty == true 
                ? 'Technical issue reported successfully! Admin will see this under ${widget.businessCategory}.'
                : 'Technical issue reported successfully!'),
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
    final maxWidth = screenWidth > 1200 ? 800.0 : 
                     screenWidth > 800 ? 600.0 : 
                     screenWidth > 600 ? 500.0 : double.infinity;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.businessCategory?.isNotEmpty == true 
              ? 'Technical Support - ${widget.businessCategory}'
              : 'Technical Support',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isWebLayout ? 22 : 20,
          ),
        ),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
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
                            Icons.support_agent,
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
                                widget.businessCategory?.isNotEmpty == true 
                                    ? 'Report app issues for ${widget.businessCategory} services - Admin will be notified'
                                    : 'Report app issues - Admin will be notified',
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
    
    return Card(
      margin: EdgeInsets.only(bottom: isWebLayout ? 12 : 8),
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isWebLayout ? 16 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(issue['status'] ?? 'pending').withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(issue['status'] ?? 'pending').withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _getStatusText(issue['status'] ?? 'pending'),
                    style: TextStyle(
                      color: _getStatusColor(issue['status'] ?? 'pending'),
                      fontSize: isWebLayout ? 12 : 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(issue['timestamp'] ?? ''),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: isWebLayout ? 12 : 11,
                  ),
                ),
              ],
            ),
            SizedBox(height: isWebLayout ? 12 : 10),
            Text(
              issue['title'] ?? 'No title',
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: isWebLayout ? 16 : 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isWebLayout ? 8 : 6),
            Text(
              issue['description'] ?? 'No description',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: isWebLayout ? 14 : 12,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  
  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'completed':
        return 'Completed';
      default:
        return 'Unknown';
    }
  }
  
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }
} 