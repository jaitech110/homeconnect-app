import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart'; // Import for getBaseUrl function

class ResidentViewComplaintsScreen extends StatefulWidget {
  final String userId;

  const ResidentViewComplaintsScreen({super.key, required this.userId});

  @override
  State<ResidentViewComplaintsScreen> createState() => _ResidentViewComplaintsScreenState();
}

class _ResidentViewComplaintsScreenState extends State<ResidentViewComplaintsScreen> {
  bool isSubmitting = false;
  
  // Form fields for new complaint
  final _formKey = GlobalKey<FormState>();
  String selectedCategory = 'Water';
  final complaintController = TextEditingController();
  final flatNumberController = TextEditingController();
  bool showComplaintForm = false;

  @override
  void initState() {
    super.initState();
  }



  Future<void> submitComplaint() async {
    setState(() {
      isSubmitting = true;
    });

    final url = Uri.parse('${getBaseUrl()}/submit_complaint');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'category': selectedCategory,
          'description': complaintController.text,
          'flat_number': flatNumberController.text,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Clear form and hide it
        complaintController.clear();
        flatNumberController.clear();
        setState(() {
          selectedCategory = 'Water';
          showComplaintForm = false;
        });

      } else {
        throw Exception('Failed to submit complaint');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Complaints',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: Colors.deepPurple.shade50,
        child: Column(
          children: [
            // New Complaint Section
                        Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                // Submit New Complaint Button
                if (!showComplaintForm) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          showComplaintForm = true;
                        });
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'Submit New Complaint',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
                ],
                
                // Complaint Form
                if (showComplaintForm) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Icon(
                                Icons.report_problem,
                                color: Colors.deepPurple,
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Submit New Complaint',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple.shade700,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    showComplaintForm = false;
                                    complaintController.clear();
                                    flatNumberController.clear();
                                  });
                                },
                                icon: const Icon(Icons.close),
                                color: Colors.grey.shade600,
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Category Selection
                          Text(
                            'Category',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.deepPurple.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: selectedCategory,
                              items: [
                                'Water',
                                'Electricity', 
                                'Security',
                                'Maintenance',
                                'Noise',
                                'Parking',
                                'Garbage Collection',
                                'Other'
                              ].map((label) {
                                return DropdownMenuItem(
                                  value: label,
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getCategoryIcon(label),
                                        color: Colors.deepPurple,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        label, 
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade800,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => selectedCategory = val!),
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: InputBorder.none,
                              ),
                              dropdownColor: Colors.white,
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 15),
                          
                          // Flat/House Number Field
                          Text(
                            'Flat/House No.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.deepPurple.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: flatNumberController,
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'e.g., A-101, B-205, House 25',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                              ),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your flat/house number';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 15),
                          
                          // Complaint Message Box
                          Text(
                            'Describe your complaint',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.deepPurple.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: complaintController,
                            maxLines: 4,
                            maxLength: 300,
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Please provide details about your complaint...',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                              ),
                              contentPadding: const EdgeInsets.all(12),
                              counterStyle: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter complaint details';
                              }
                              if (value.trim().length < 10) {
                                return 'Please provide more details (at least 10 characters)';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 15),
                          
                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 45,
                            child: ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        submitComplaint();
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: isSubmitting
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Submitting...',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    )
                                  : const Text(
                                      'Submit Complaint',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ), // Column
          ), // SingleChildScrollView  
        ), // Expanded
              ], // Column children
      ), // Column
    ), // Container
  ); // Scaffold

}

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Water':
        return Icons.water_drop;
      case 'Electricity':
        return Icons.electrical_services;
      case 'Security':
        return Icons.security;
      case 'Maintenance':
        return Icons.build;
      case 'Noise':
        return Icons.volume_up;
      case 'Parking':
        return Icons.local_parking;
      case 'Garbage Collection':
        return Icons.delete;
      default:
        return Icons.help_outline;
    }
  }

  @override
  void dispose() {
    complaintController.dispose();
    flatNumberController.dispose();
    super.dispose();
  }
}
