import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart';
import '../../utils/app_theme.dart';

class ComplaintScreen extends StatefulWidget {
  final String userId;

  const ComplaintScreen({super.key, required this.userId});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? selectedCategory;
  String? selectedPriority;
  bool isSubmitting = false;

  final List<String> categories = [
    'Maintenance',
    'Security',
    'Noise',
    'Cleanliness',
    'Parking',
    'Water Supply',
    'Electricity',
    'Other',
  ];

  final List<String> priorities = [
    'Low',
    'Medium',
    'High',
    'Urgent',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      final baseUrl = getBaseUrl();
      final url = Uri.parse('$baseUrl/resident/complaints');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'title': _titleController.text.trim(),
          'category': selectedCategory,
          'priority': selectedPriority,
          'description': _descriptionController.text.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Complaint submitted successfully! You will receive updates on the status.'),
                  ),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              duration: const Duration(seconds: 4),
            ),
          );
          
          // Clear form
          _titleController.clear();
          _descriptionController.clear();
          setState(() {
            selectedCategory = null;
            selectedPriority = null;
          });
        }
      } else {
        throw Exception('Failed to submit complaint: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error submitting complaint: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting complaint: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 800;
    final maxWidth = screenWidth > 1200 ? 900.0 : screenWidth > 800 ? 700.0 : screenWidth;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Submit Complaint'),
        backgroundColor: AppTheme.residentColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isLargeScreen ? 40 : 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    padding: EdgeInsets.all(isLargeScreen ? 24 : 20),
                    decoration: AppTheme.elevatedCardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.residentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.report_problem,
                                color: AppTheme.residentColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Submit a Complaint', style: AppTheme.headingSmall),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Help us improve your living experience by reporting issues',
                                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.secondaryTextColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isLargeScreen ? 32 : 24),

                  // Info Card
                  AppTheme.infoCard(
                    icon: Icons.info_outline,
                    title: 'How it works',
                    subtitle: 'Your complaint will be forwarded to the building management team. You\'ll receive updates on the resolution status.',
                    iconColor: AppTheme.infoColor,
                  ),

                  SizedBox(height: isLargeScreen ? 32 : 24),

                  // Form Section
                  Container(
                    padding: EdgeInsets.all(isLargeScreen ? 24 : 20),
                    decoration: AppTheme.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Complaint Details', style: AppTheme.headingSmall),
                        SizedBox(height: isLargeScreen ? 24 : 20),

                        // Title Field
                        TextFormField(
                          controller: _titleController,
                          decoration: AppTheme.inputDecoration('Complaint Title', prefixIcon: Icons.title),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a complaint title';
                            }
                            if (value.trim().length < 5) {
                              return 'Title must be at least 5 characters long';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: isLargeScreen ? 20 : 16),

                        // Category and Priority in row for large screens
                        isLargeScreen 
                          ? Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: selectedCategory,
                                    decoration: AppTheme.inputDecoration('Category', prefixIcon: Icons.category),
                                    items: categories.map((category) {
                                      return DropdownMenuItem(
                                        value: category,
                                        child: Text(category, style: AppTheme.bodyMedium),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedCategory = value;
                                      });
                                    },
                                    validator: (value) => value == null ? 'Please select a category' : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: selectedPriority,
                                    decoration: AppTheme.inputDecoration('Priority Level', prefixIcon: Icons.priority_high),
                                    items: priorities.map((priority) {
                                      IconData priorityIcon;
                                      Color priorityColor;
                                      
                                      switch (priority) {
                                        case 'Low':
                                          priorityIcon = Icons.arrow_downward;
                                          priorityColor = AppTheme.successColor;
                                          break;
                                        case 'Medium':
                                          priorityIcon = Icons.remove;
                                          priorityColor = AppTheme.warningColor;
                                          break;
                                        case 'High':
                                          priorityIcon = Icons.arrow_upward;
                                          priorityColor = Colors.orange;
                                          break;
                                        case 'Urgent':
                                          priorityIcon = Icons.warning;
                                          priorityColor = AppTheme.errorColor;
                                          break;
                                        default:
                                          priorityIcon = Icons.help;
                                          priorityColor = AppTheme.secondaryTextColor;
                                      }
                                      
                                      return DropdownMenuItem(
                                        value: priority,
                                        child: Row(
                                          children: [
                                            Icon(priorityIcon, color: priorityColor, size: 16),
                                            const SizedBox(width: 8),
                                            Text(priority, style: AppTheme.bodyMedium),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedPriority = value;
                                      });
                                    },
                                    validator: (value) => value == null ? 'Please select priority level' : null,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                // Category Dropdown
                                DropdownButtonFormField<String>(
                                  value: selectedCategory,
                                  decoration: AppTheme.inputDecoration('Category', prefixIcon: Icons.category),
                                  items: categories.map((category) {
                                    return DropdownMenuItem(
                                      value: category,
                                      child: Text(category, style: AppTheme.bodyMedium),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedCategory = value;
                                    });
                                  },
                                  validator: (value) => value == null ? 'Please select a category' : null,
                                ),

                                const SizedBox(height: 16),

                                // Priority Dropdown
                                DropdownButtonFormField<String>(
                                  value: selectedPriority,
                                  decoration: AppTheme.inputDecoration('Priority Level', prefixIcon: Icons.priority_high),
                                  items: priorities.map((priority) {
                                    IconData priorityIcon;
                                    Color priorityColor;
                                    
                                    switch (priority) {
                                      case 'Low':
                                        priorityIcon = Icons.arrow_downward;
                                        priorityColor = AppTheme.successColor;
                                        break;
                                      case 'Medium':
                                        priorityIcon = Icons.remove;
                                        priorityColor = AppTheme.warningColor;
                                        break;
                                      case 'High':
                                        priorityIcon = Icons.arrow_upward;
                                        priorityColor = Colors.orange;
                                        break;
                                      case 'Urgent':
                                        priorityIcon = Icons.warning;
                                        priorityColor = AppTheme.errorColor;
                                        break;
                                      default:
                                        priorityIcon = Icons.help;
                                        priorityColor = AppTheme.secondaryTextColor;
                                    }
                                    
                                    return DropdownMenuItem(
                                      value: priority,
                                      child: Row(
                                        children: [
                                          Icon(priorityIcon, color: priorityColor, size: 16),
                                          const SizedBox(width: 8),
                                          Text(priority, style: AppTheme.bodyMedium),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedPriority = value;
                                    });
                                  },
                                  validator: (value) => value == null ? 'Please select priority level' : null,
                                ),
                              ],
                            ),

                        SizedBox(height: isLargeScreen ? 20 : 16),

                        // Description Field
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 5,
                          decoration: AppTheme.inputDecoration('Detailed Description', prefixIcon: Icons.description).copyWith(
                            hintText: 'Please provide detailed information about the issue, including location if applicable...',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please provide a detailed description';
                            }
                            if (value.trim().length < 20) {
                              return 'Description must be at least 20 characters long';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isSubmitting ? null : _submitComplaint,
                            style: AppTheme.primaryButtonStyle,
                            icon: isSubmitting 
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.send),
                            label: Text(isSubmitting ? 'Submitting...' : 'Submit Complaint'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Contact Information Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.successColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.support_agent, color: AppTheme.successColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Need immediate help?',
                                style: AppTheme.bodyLarge.copyWith(color: AppTheme.successColor),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'For urgent matters, contact your building management directly or call emergency services.',
                                style: AppTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
