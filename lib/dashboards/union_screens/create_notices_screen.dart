import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../main.dart';

class CreateNoticesScreen extends StatefulWidget {
  final int userId;
  
  const CreateNoticesScreen({super.key, required this.userId});

  @override
  State<CreateNoticesScreen> createState() => _CreateNoticesScreenState();
}

class _CreateNoticesScreenState extends State<CreateNoticesScreen> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final bodyController = TextEditingController();
  bool isLoading = false;
  bool noticeCreated = false;
  String? errorMessage;

  Future<void> submitNotice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      noticeCreated = false;
      errorMessage = null;
    });

    try {
      print('📝 Sending notice with user ID: ${widget.userId}');
      
      final url = Uri.parse('${getBaseUrl()}/union/create_notice?user_id=${widget.userId}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': titleController.text,
          'body': bodyController.text,
        }),
      );

      final responseData = jsonDecode(response.body);
      print('📝 Notice API response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201) {
        setState(() {
          noticeCreated = true;
          isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notice posted successfully and will be visible to your residents')),
        );
        
        titleController.clear();
        bodyController.clear();
      } else {
        String error = responseData['error'] ?? 'Unknown error occurred';
        
        // Handle specific error scenarios
        if (error.contains('No properties found')) {
          error = 'No properties are assigned to you. Please contact the admin to assign properties.';
        }
        
        setState(() {
          isLoading = false;
          errorMessage = error;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post notice: $error')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post notice: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Notice'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (noticeCreated)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Notice Created Successfully!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your notice has been created and will be visible to all residents of your properties.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            if (errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Error Creating Notice',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const Text(
                      'Create a notice for your residents',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Notice Title',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) => value!.isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: bodyController,
                      decoration: const InputDecoration(
                        labelText: 'Notice Content',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.message),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 8,
                      validator: (value) => value!.isEmpty ? 'Content is required' : null,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : submitNotice,
                      icon: isLoading 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send),
                      label: Text(isLoading ? 'Sending...' : 'Send Notice'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
