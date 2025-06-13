import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../main.dart';

class BankAccountDetailsScreen extends StatefulWidget {
  final int userId;
  
  const BankAccountDetailsScreen({super.key, required this.userId});

  @override
  State<BankAccountDetailsScreen> createState() => _BankAccountDetailsScreenState();
}

class _BankAccountDetailsScreenState extends State<BankAccountDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final bankNameController = TextEditingController();
  final messageController = TextEditingController();
  bool isLoading = false;
  bool messageSubmitted = false;
  String? errorMessage;

  Future<void> submitBankDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      messageSubmitted = false;
      errorMessage = null;
    });

    try {
      print('📧 Dispatching mail with user ID: ${widget.userId}');
      
      final url = Uri.parse('${getBaseUrl()}/union/create_notice?user_id=${widget.userId}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': bankNameController.text,
          'body': messageController.text,
        }),
      );

      final responseData = jsonDecode(response.body);
      print('📧 Mail dispatch API response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201) {
        setState(() {
          messageSubmitted = true;
          isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bank account details dispatched successfully and will be visible to your residents')),
        );
        
        bankNameController.clear();
        messageController.clear();
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
          SnackBar(content: Text('Failed to dispatch bank details: $error')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to dispatch bank details: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    bankNameController.dispose();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Account Details'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (messageSubmitted)
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
                          'Bank Details Sent Successfully!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your bank account details have been sent and will be visible to all residents of your properties.',
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
                          'Error Sending Bank Details',
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
                      'Provide bank account details for your residents',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: bankNameController,
                      decoration: const InputDecoration(
                        labelText: 'Bank Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_balance),
                      ),
                      validator: (value) => value!.isEmpty ? 'Bank name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: messageController,
                      decoration: const InputDecoration(
                        labelText: 'Account Details',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.payment),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 8,
                      validator: (value) => value!.isEmpty ? 'Account details are required' : null,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : submitBankDetails,
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
                      label: Text(isLoading ? 'Sending...' : 'Send Bank Details'),
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